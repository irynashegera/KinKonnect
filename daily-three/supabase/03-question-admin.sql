begin;
create schema if not exists kinnect_private;
revoke all on schema kinnect_private from public, anon, authenticated;
create table if not exists kinnect_private.admin_users(user_id uuid primary key references auth.users(id) on delete cascade);
insert into kinnect_private.admin_users select id from auth.users where lower(email)='mschoos@calpoly.edu' and email_confirmed_at is not null on conflict do nothing;
create table if not exists kinnect_private.backup_questions(id bigint generated always as identity primary key, question_text text not null, option_a text not null, option_b text not null, used_on date, created_at timestamptz not null default now());
create unique index if not exists backup_question_unique on kinnect_private.backup_questions(lower(trim(question_text)));
create table if not exists kinnect_private.generation_requests(user_id uuid not null, created_at timestamptz not null default now());
revoke all on all tables in schema kinnect_private from public, anon, authenticated;
create or replace function public.is_kinnect_admin() returns boolean language sql stable security definer set search_path='' as $$
 select public.is_calpoly_student() and exists(select 1 from kinnect_private.admin_users where user_id=auth.uid());
$$;
-- A student can only trigger the current day's approved fallback. No client-supplied date or text.
create or replace function public.ensure_daily_mix() returns void language plpgsql security definer set search_path='' as $$
declare d date := (now() at time zone 'America/Los_Angeles')::date; n integer; item record; slot integer;
begin
 if not public.is_calpoly_student() then raise exception 'Verified student sign-in required.'; end if;
 perform pg_advisory_xact_lock(716283, d - date '2020-01-01');
 select count(*) into n from public.questions where question_date=d;
 if n=3 then return; end if;
 -- Never alter an existing set, including a partially configured day.
 if n<>0 then return; end if;
 select count(*) into n from kinnect_private.backup_questions b where used_on is null and not exists(select 1 from public.questions q where lower(trim(q.question_text))=lower(trim(b.question_text)));
 if n<3 then return; end if;
 slot:=0;
 for item in select b.* from kinnect_private.backup_questions b where b.used_on is null and not exists(select 1 from public.questions q where lower(trim(q.question_text))=lower(trim(b.question_text))) order by b.id limit 3 for update loop
  slot:=slot+1;
  insert into public.questions(question_date,position,question_text,option_a,option_b) values(d,slot,item.question_text,item.option_a,item.option_b);
  update kinnect_private.backup_questions set used_on=d where id=item.id;
 end loop;
end;
$$;
create or replace function public.admin_question_dashboard() returns jsonb language plpgsql security definer set search_path='' as $$
begin
 if not public.is_kinnect_admin() then raise exception 'Admin access required.'; end if;
 return jsonb_build_object('scheduled',coalesce((select jsonb_agg(to_jsonb(q) order by q.question_date,q.position) from public.questions q where q.question_date between (now() at time zone 'America/Los_Angeles')::date and (now() at time zone 'America/Los_Angeles')::date+90),'[]'::jsonb), 'backups',coalesce((select jsonb_agg(to_jsonb(b) order by b.id) from kinnect_private.backup_questions b where b.used_on is null and not exists(select 1 from public.questions q where lower(trim(q.question_text))=lower(trim(b.question_text)))),'[]'::jsonb), 'recent',coalesce((select jsonb_agg(q.question_text) from public.questions q where q.question_date>=(now() at time zone 'America/Los_Angeles')::date-30),'[]'::jsonb));
end;
$$;
create or replace function public.admin_save_question_plan(p_days jsonb, p_backups jsonb default '[]'::jsonb) returns void language plpgsql security definer set search_path='' as $$
declare day_item jsonb; item jsonb; d date; i integer; t text; a text; b text; today date := (now() at time zone 'America/Los_Angeles')::date;
begin
 if not public.is_kinnect_admin() then raise exception 'Admin access required.'; end if;
 if jsonb_typeof(p_days) is distinct from 'array' or jsonb_array_length(p_days)>7 or jsonb_typeof(p_backups) is distinct from 'array' or jsonb_array_length(p_backups)>30 then raise exception 'Choose up to seven days and thirty backups.'; end if;
 if (select count(*) from jsonb_array_elements(p_days))<>(select count(distinct x->>'date') from jsonb_array_elements(p_days) x) then raise exception 'Duplicate dates.'; end if;
 -- Same lock order as automatic fallback, locking all dates before writing.
 for day_item in select value from jsonb_array_elements(p_days) order by value->>'date' loop
  d:=(day_item->>'date')::date;
  if d is null or d<=today or d>today+90 then raise exception 'Only future days within 90 days can be scheduled.'; end if;
  perform pg_advisory_xact_lock(716283,d-date '2020-01-01');
  if exists(select 1 from public.answers ans join public.questions q on q.id=ans.question_id where q.question_date=d) then raise exception 'Questions with answers cannot be changed.'; end if;
  if jsonb_typeof(day_item->'questions') is distinct from 'array' or jsonb_array_length(day_item->'questions')<>3 then raise exception 'Every day needs exactly three questions.'; end if;
  i:=0;
  for item in select value from jsonb_array_elements(day_item->'questions') loop
   t:=trim(item->>'question_text'); a:=trim(item->>'option_a'); b:=trim(item->>'option_b');
   if t is null or length(t) not between 8 and 180 or a is null or length(a) not between 1 and 60 or b is null or length(b) not between 1 and 60 or lower(a)=lower(b) then raise exception 'Each question needs clear text and two different choices.'; end if;
   if exists(select 1 from public.questions q where q.question_date<>d and lower(trim(q.question_text))=lower(t)) then raise exception 'A question has already been scheduled. Choose a new one.'; end if;
   if exists(select 1 from public.questions q where q.question_date=d and q.position<=i and lower(trim(q.question_text))=lower(t)) then raise exception 'Duplicate question in this daily mix.'; end if;
   i:=i+1;
   insert into public.questions(question_date,position,question_text,option_a,option_b) values(d,i,t,a,b) on conflict(question_date,position) do update set question_text=excluded.question_text,option_a=excluded.option_a,option_b=excluded.option_b;
  end loop;
 end loop;
 for item in select value from jsonb_array_elements(p_backups) loop
  t:=trim(item->>'question_text'); a:=trim(item->>'option_a'); b:=trim(item->>'option_b');
  if t is null or length(t) not between 8 and 180 or a is null or length(a) not between 1 and 60 or b is null or length(b) not between 1 and 60 or lower(a)=lower(b) then raise exception 'Check backup question text and choices.'; end if;
  if exists(select 1 from public.questions q where lower(trim(q.question_text))=lower(t)) then raise exception 'A backup question is already scheduled.'; end if;
  insert into kinnect_private.backup_questions(question_text,option_a,option_b) values(t,a,b) on conflict do nothing;
 end loop;
end;
$$;
create or replace function public.admin_claim_generation() returns void language plpgsql security definer set search_path='' as $$
begin
 if not public.is_kinnect_admin() then raise exception 'Admin access required.'; end if;
 perform pg_advisory_xact_lock(hashtext(auth.uid()::text));
 if exists(select 1 from kinnect_private.generation_requests where user_id=auth.uid() and created_at>now()-interval '10 seconds') or (select count(*) from kinnect_private.generation_requests where user_id=auth.uid() and created_at>now()-interval '1 hour')>=12 then raise exception 'Please wait before generating more questions (12 batches per hour).'; end if;
 delete from kinnect_private.generation_requests where created_at<now()-interval '1 day';
 insert into kinnect_private.generation_requests(user_id) values(auth.uid());
end;
$$;
revoke all on function public.is_kinnect_admin(),public.ensure_daily_mix(),public.admin_question_dashboard(),public.admin_save_question_plan(jsonb,jsonb),public.admin_claim_generation() from public,anon;
grant execute on function public.is_kinnect_admin(),public.ensure_daily_mix(),public.admin_question_dashboard(),public.admin_save_question_plan(jsonb,jsonb),public.admin_claim_generation() to authenticated;
notify pgrst, 'reload schema';
commit;
