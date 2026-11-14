# Daily Three — Cal Poly

Mobile-friendly, buildless first prototype. Run `python3 -m http.server 4173 --directory dist` from this directory.

## Implemented

- Cal Poly email domain validation and short onboarding.
- Three rotating daily questions, one at a time, with two animated choices.
- Browser-local persistence, Pacific-time daily question selection, and completion tracking.
- Yesterday’s reveal with explicitly labeled illustrative campus percentages.
- Three fictional sample matches, pending reveal requests, and an explicitly labeled control to preview mutual acceptance.
- Animated profile reveal, optional social fields, explicit email sharing preference.
- Share preview, native sharing or clipboard fallback; optional inclusion of answers.
- Mobile layout, keyboard interaction, reduced-motion support, escaped profile text.

## Important boundaries

This is a front-end prototype. It does not verify email ownership, send messages, persist to a shared database, or match real students. Local data is not an authentication boundary. Sample contact details are not fabricated or linked to real accounts.

Before real student use: connect email magic-link authentication restricted to verified `calpoly.edu` identities, shared question/answer storage with one vote per question and student, final daily aggregates, similarity over co-answered questions, server-enforced mutual consent, and profile visibility rules. Seed fictional data only in explicitly labeled demonstration mode. Add moderation and account controls in a secondary menu.

The question bank is curated sample content, not scraped campus posts. Fonts load from Google Fonts, with system fallbacks.
