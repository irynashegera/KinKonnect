begin;
alter table kinnect_private.admin_users add column if not exists is_owner boolean not null default false;
update kinnect_private.admin_users set is_owner=true where user_id in (select id from auth.users where lower(email)='mschoos@calpoly.edu' and email_confirmed_at is not null);
create or replace function public.admin_team_access() returns jsonb language plpgsql security definer set search_path='' as $$
begin
 if not public.is_kinnect_admin() then raise exception 'Admin access required.'; end if;
 return jsonb_build_object('can_manage',exists(select 1 from kinnect_private.admin_users a where a.user_id=auth.uid() and a.is_owner), 'members',coalesce((select jsonb_agg(jsonb_build_object('email',u.email,'is_owner',a.is_owner)) from kinnect_private.admin_users a join auth.users u on u.id=a.user_id),'[]'::jsonb));
end;
$$;
create or replace function public.admin_add_question_editor(p_email text) returns void language plpgsql security definer set search_path='' as $$
declare target_id uuid;
begin
 if not public.is_calpoly_student() or not exists(select 1 from kinnect_private.admin_users where user_id=auth.uid() and is_owner) then raise exception 'Only the owner can add editors.'; end if;
 if lower(trim(p_email)) not like '%@calpoly.edu' then raise exception 'Use their Cal Poly email.'; end if;
 select u.id into target_id from auth.users u join public.profiles p on p.id=u.id where lower(u.email)=lower(trim(p_email)) and u.email_confirmed_at is not null;
 if target_id is null then raise exception 'They must sign in to Kinnect and finish their profile first.'; end if;
 insert into kinnect_private.admin_users(user_id,is_owner) values(target_id,false) on conflict do nothing;
end;
$$;
revoke all on function public.admin_team_access(),public.admin_add_question_editor(text) from public,anon;
grant execute on function public.admin_team_access(),public.admin_add_question_editor(text) to authenticated;
notify pgrst,'reload schema';
commit;
