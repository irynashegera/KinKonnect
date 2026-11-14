begin;

-- Real aggregate results. Individual answers stay private.
create or replace function public.campus_results(target_date date)
returns table(question_id uuid, question_text text, option_a text, option_b text,
  "position" smallint, votes_a bigint, votes_b bigint, my_choice smallint)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_calpoly_student() then
    raise exception 'Sign in with a verified Cal Poly email.';
  end if;
  if target_date >= (now() at time zone 'America/Los_Angeles')::date then
    raise exception 'Results are available after the day closes.';
  end if;
  return query
  select q.id, q.question_text, q.option_a, q.option_b, q.position,
    count(a.user_id) filter (where a.choice = 0),
    count(a.user_id) filter (where a.choice = 1),
    max(a.choice) filter (where a.user_id = auth.uid())
  from public.questions q
  left join public.answers a on a.question_id = q.id
  where q.question_date = target_date
  group by q.id
  order by q.position;
end;
$$;

-- Only returns the top three profiles after today's three answers.
create or replace function public.closest_matches()
returns table(user_id uuid, first_name text, last_name text, major text,
  year text, email text, instagram text, linkedin text,
  shared_answers bigint, same_answers bigint)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_calpoly_student() then
    raise exception 'Sign in with a verified Cal Poly email.';
  end if;
  if (select count(*) from public.answers a
      join public.questions q on q.id = a.question_id
      where a.user_id = auth.uid()
        and q.question_date = (now() at time zone 'America/Los_Angeles')::date) <> 3 then
    raise exception 'Finish today''s three questions first.';
  end if;
  return query
  with scores as (
    select other.user_id,
      count(*) as shared,
      count(*) filter (where mine.choice = other.choice) as same
    from public.answers mine
    join public.answers other on other.question_id = mine.question_id
      and other.user_id <> mine.user_id
    where mine.user_id = auth.uid()
    group by other.user_id
    having count(*) >= 3
  )
  select p.id, p.first_name, p.last_name, p.major, p.year,
    u.email::text, p.instagram, p.linkedin, s.shared, s.same
  from scores s
  join public.profiles p on p.id = s.user_id
  join auth.users u on u.id = p.id
  where p.sharing_agreed_at is not null
    and u.email_confirmed_at is not null
    and lower(u.email) like '%@calpoly.edu'
  order by s.same::numeric / s.shared desc, s.shared desc, p.id
  limit 3;
end;
$$;

revoke all on function public.campus_results(date) from public, anon;
revoke all on function public.closest_matches() from public, anon;
grant execute on function public.campus_results(date) to authenticated;
grant execute on function public.closest_matches() to authenticated;

-- Schedule ten days. Keeps today's existing questions and any saved answers.
with prompts(n, question_text, option_a, option_b) as (values
 (0,'Would you date someone in your major?','Absolutely','Too close to home'),
 (1,'An 8 a.m. class or a Friday evening class?','8 a.m. class','Friday evening class'),
 (2,'A free afternoon in SLO. Where are you?','Up a mountain','Down at the beach'),
 (3,'Your friend cancels plans. Your first thought?','Secretly relieved','We are rescheduling'),
 (4,'Group project. Who are you?','Make the shared doc','Wait for the shared doc'),
 (5,'Someone catches your eye in class. You…','Make the first move','Hope they do'),
 (6,'Your weekend plans are…','Already in the calendar','A future-me problem'),
 (7,'The group chat says hike at sunrise.','Alarm is set','Absolutely not'),
 (8,'You disagree with your friend. You…','Debate it over coffee','Agree to disagree'),
 (9,'A first date at the dining hall?','Honestly, yes','Aim higher'),
 (10,'One hour before an exam. You…','Study one last time','Protect my peace'),
 (11,'You get the aux cord. You play…','A crowd pleaser','My niche obsession'),
 (12,'Study soundtrack?','Total silence','Music on'),
 (13,'A friend wants to set you up.','I am listening','Please do not'),
 (14,'Sunday afternoon?','Get ahead on work','Keep the weekend going'),
 (15,'You get a long voice message.','Play immediately','Wish it was a text'),
 (16,'Going to an event alone?','I would','Only with a friend'),
 (17,'Your ideal living situation?','A lively house','A quiet apartment'),
 (18,'Dinner plans?','Try somewhere new','My usual spot'),
 (19,'A spontaneous road trip?','Give me ten minutes','Give me ten days'),
 (20,'Pick a study buddy.','Same major','Different major'),
 (21,'Your phone rings unexpectedly.','Answer it','Text back instead'),
 (22,'You discover a great song.','Share it with everyone','Keep it my little secret'),
 (23,'Meet your friends at the beach.','In the water','On the sand'),
 (24,'A club you know nothing about?','Try a meeting','Research it first'),
 (25,'Your roommate borrows your clothes.','Fine if they ask','Hard no'),
 (26,'The best conversation happens…','On a long walk','Over a meal'),
 (27,'A free ticket to a show you do not know?','I am going','Pass this time'),
 (28,'Your friend is running late.','I am early anyway','I am also running late'),
 (29,'Choose your semester energy.','Try something unfamiliar','Get really good at my thing')
)
insert into public.questions(question_date, position, question_text, option_a, option_b)
select (now() at time zone 'America/Los_Angeles')::date + (n / 3),
  (n % 3 + 1)::smallint, question_text, option_a, option_b
from prompts
on conflict (question_date, position) do nothing;

commit;
select question_date, count(*) as questions
from public.questions
group by question_date
order by question_date;
