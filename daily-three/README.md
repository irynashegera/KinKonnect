# Kinnect — Cal Poly

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

## Reliable email verification

The app now supports entering an emailed OTP code in addition to existing magic links. To avoid Microsoft Safe Links / email prefetch consuming a one-time link, set both Authentication → Emails → Templates → **Confirm sign up** and **Magic link or OTP** bodies to `supabase/email-templates/sign-in.html`. Set the subject to `Your Kinnect sign-in code`. Keep `{{ .Token }}` exact, and omit `{{ .ConfirmationURL }}` so the email has no consumable auth link. This is a Supabase dashboard configuration, not something GitHub deployment applies automatically.

New and returning users both verify using `verifyOtp({ email, token, type: 'email' })`. Existing authenticated sessions remain valid. Codes are never stored in app storage or sent anywhere except Supabase Auth. Pending email and resend cooldown are kept in sessionStorage; no code is persisted. End-to-end delivery with the new template still requires testing with real Cal Poly inboxes.

## Question replay

Signed-in users can open **Preview questions** from their profile or completed daily results. This runs the current question set using separate in-memory answers; it never inserts or changes database answers, percentages, or matches. Preview completion shows a practice recap and **Run again**. Exiting returns to the real daily state. No fake history or student profiles are created.

## Welcome screen and Cal Poly-inspired theme

After verified sign-in, a brief welcome screen explains the daily questions, campus results, and matches before profile setup or daily play. It appears once per browser session/account and can be reopened via Profile → About Kinnect. This preference is local UI state, not a new database column. The palette uses Poly Green (#154734), gold (#BD8B13 / #F2C75C), black, and white; it does not imply university affiliation.

## Landscape welcome

The welcome screen now uses a full-screen green-and-gold SVG landscape with a sunrise, subtle stars, and animated connecting paths. It retains the short “3 questions a day” description and uses the broader “See what you have in common” copy. The background animation plays automatically. Motion settles in under five seconds and respects reduced-motion preferences. This design is scoped to the welcome screen; question screens and database behavior are unchanged.

## Scrollable introduction

The welcome screen now scrolls from the landscape hero into a concise campus-specific thesis, how-it-works section, and final call to action. All start buttons use the same verified-account onboarding/daily flow. Hero copy is “Three questions. One campus.” and “Answer every day. See how Cal Poly thinks.” Wordmark tracking is normal, the replay interaction/hint is removed, and the welcome layout uses restrained typography and pill buttons. No database schema changes are required.

## Minimal light homepage

The current homepage follows the supplied clean reference: off-white background, centered spaced wordmark, two-line headline, gray supporting copy, and black pill CTA. The scroll-down introduction remains. The Kinnect wordmark in the app header and homepage/footer opens the homepage. Signed-out visitors can view home and then continue to email verification; signed-in students continue to profile setup or their real daily state. Question screens retain their existing green-and-gold styling.

## Mission and shared campus palette

Homepage About content is now a short explanation of why Kinnect is being built. A bottom-left Our mission button opens a native, keyboard-accessible dialog; Close, Escape, and clicking the backdrop dismiss it. Homepage and result accents use the same green/gold palette as questions. Question-page styles and all database behavior remain unchanged.

## Question editor

Sign in to Kinnect, open **Profile → Question admin**. Access is checked in the database and on the generation endpoint. The owner can add verified existing students as question editors. Editors cannot manage team access.

- Review seven days, three questions per day, then **Approve & schedule week**.
- AI generation drafts 21 scheduled questions plus nine optional backups. It never publishes automatically. Requires server-only `OPENAI_API_KEY` and API quota.
- Free alternative: **Import questions from ChatGPT**. Copy the prompt, paste the resulting 21- or 30-item JSON array, review, and approve.
- **Review starter backups** offers 30 manually authored drafts. Select and approve extras to stock the bank. The bank must be replenished; the badge shows days remaining.
- Pacific dates control publication. On the first verified student visit to an unscheduled day, `ensure_daily_mix` atomically takes three unused approved backups. Concurrent visitors receive the same set. It never edits an existing set, and does not recycle used questions. Fewer than three backups leaves the day unscheduled; no invented votes or fake answers.
- Only future dates can be edited. Existing question IDs and student answers are preserved. Database transaction validation rejects incomplete and repeated questions.
- Apply `supabase/03-question-admin.sql`, then `04-team-editors.sql` once. These were applied to the current project during setup. Do not put secrets in SQL or browser files.

Build: `node scripts/build-worker.mjs`. Produces a Cloudflare Worker with the existing static assets bundled, plus protected `/api/admin/status` and `/api/admin/generate` endpoints. Test: `node tests/admin-worker.mjs`.
