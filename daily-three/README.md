# Daily Three — Cal Poly

Responsive black-and-white website connected to Supabase project `ykuwpfxzqqjuzihuoptb`.

## Run locally

`python3 -m http.server 4173 --directory dist`

## Live setup

1. Apply the initial `profiles`, `questions`, `answers` schema and policies supplied in chat.
2. Run `supabase/02-live-results.sql` once in Supabase SQL Editor. It adds read-only aggregate/matching functions and schedules ten days of questions, preserving existing questions and answers.
3. Add the deployed website origin to Authentication → URL Configuration. Local auth testing also needs the localhost URL allowed.
4. Supabase's default email sender only delivers to authorized organization team addresses and has a small rate limit. Configure custom SMTP before inviting ordinary students.
5. Enter a verified team member's Cal Poly address on the website and follow the sign-in link. Fill out a real profile and answer today's questions.

## What is real

Email magic-link authentication, persisted profiles, one immutable vote per question/student, daily question dates in Pacific time, yesterday's vote counts, top-three similarity over co-answered questions, and match profiles. No sample students, percentages, or answer history are seeded. An empty database produces honest empty states.

Matching requires today's three answers and at least three co-answered questions with another student. Profiles explicitly agree to sharing. Raw individual answer rows remain restricted to their owner. The public publishable key is safe to ship; never add a service-role/secret key or database password to website files.

The website uses the official Supabase JS 2.119.0 UMD bundle in `dist/vendor/`. Its bundled license notices are retained. Questions are scheduled for ten days by the SQL update; schedule more dates before those run out. There is no automatic question generation.

## Testing boundaries

Email delivery and signed-in data paths need real account testing. No end-to-end email verification is claimed until a student has completed the real link flow. The Sites deployment is owner-private until access is explicitly changed; sharing with teammates requires a hosting access change or another public deployment.
