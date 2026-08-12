# Backlog

Newest/highest-priority items at the top. Each entry should have enough context to pick back up cold —
link to the ADR or file for full detail rather than duplicating it here.

---

## Decide: ship the identify daily scan quota in the first TestFlight build, or fast-follow?

Added: 2026-08-12 · Status: **built, not applied, decision pending**

**What exists:** A per-user daily cap on `identify-plant` calls, enforced server-side, so a handful of
beta testers can't burn through the shared free-tier provider quota (Pl@ntNet / Gemini-direct) for
everyone else on the same day. Fully implemented and building clean:

- `supabase/migrations/20260812_0010_identify_daily_scan_quota.sql` — new columns on `profiles` +
  `SECURITY DEFINER` function `check_and_increment_daily_scan_quota`.
- `supabase/functions/identify-plant/index.ts` — checks quota before any provider call; returns
  `quota_exceeded: true` rather than an HTTP error.
- `BotanyService.swift` / `ScannerView.swift` — client now forwards the real user JWT (was sending the
  anon key), throws `BotanyServiceError.dailyQuotaExceeded` with user-facing copy.
- Full writeup: [ADR-0005](DECISIONS/ADR-0005-identify-daily-scan-quota.md).

**The decision to make:** whether this rides in the same build as the TestFlight submission, or waits
for a fast-follow build once the core identify flow is confirmed stable with real testers. The problem
it solves (quota exhaustion) only shows up after a few days of real usage, not on day one, so there's
no forced deadline — but every day it's not live is a day beta testers could exhaust the free tier
undetected.

**Risk framing (full detail in conversation, summarized here):** designed to fail *open* — if the
migration isn't applied yet, or an old client build hits the new function, or the RPC errors for any
reason, `identify-plant` proceeds exactly as it does today (no quota enforcement), never breaks
scanning. Real residual risk is that it's untested against a live Supabase instance, and it touches the
single most critical path in the app right before launch.

**Before shipping either way:**
1. Apply the migration (Dashboard SQL Editor — CLI `db push` still blocked by the role-provisioning bug
   from ADR-0004).
2. One real manual pass: sign in, scan successfully, then manually bump `daily_scan_count` near the
   limit in the table and confirm the "come back tomorrow" message actually shows.
3. Replace the placeholder `p_daily_limit = 25` with a number sized against actual current
   Pl@ntNet/Gemini free-tier limits (not yet re-checked since ADR-0004, 2026-08-07).
4. Wire `provider_chain` / `diagnostic_code` / `quota_exceeded` into a PostHog event — currently
   `print()`-only, so there's no visibility into quota pressure before testers start seeing the message.

**Unrelated, discovered in passing:** the app currently fails to build for a reason unconnected to this
work — `DesignSystemGalleryView.swift:197`, "extra argument in call" in the design-gallery showcase
screen. Real blocker for archiving a TestFlight build regardless of the decision above; not investigated
further since it's outside this item's scope.
