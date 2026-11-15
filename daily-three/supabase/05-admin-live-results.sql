begin;
-- Aggregate counts only. Normal student results retain their existing next-day gate.
create or replace function public.admin_live_results() returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare d date := (now() at time zone 'America/Los_Angeles')::date;
begin
 if not public.is_kinnect_admin() then raise exception 'Admin access required.'; end if;
 return jsonb_build_object('date',d,'questions',coalesce((
  select jsonb_agg(to_jsonb(r) order by r.position) from (
   select q.id as question_id,q.question_text,q.option_a,q.option_b,q.position,
    count(a.user_id) filter(where a.choice=0) as votes_a,
    count(a.user_id) filter(where a.choice=1) as votes_b,
    max(a.choice) filter(where a.user_id=auth.uid()) as my_choice
   from public.questions q left join public.answers a on a.question_id=q.id
   where q.question_date=d group by q.id
  ) r),'[]'::jsonb));
end;
$$;
revoke all on function public.admin_live_results() from public,anon;
grant execute on function public.admin_live_results() to authenticated;
notify pgrst,'reload schema';
commit;
