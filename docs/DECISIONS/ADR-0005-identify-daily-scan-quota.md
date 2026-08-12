# ADR-0005: Per-user daily quota on identify-plant

Date: 2026-08-12
Status: Accepted
Decision owners: Product/Engineering

## Context

[ADR-0004](./ADR-0004-narrative-cache-and-free-tier-providers.md) made `narrate-plant` hold up under a
free-tier-only budget by caching species-level narrative content — after the cache warms, the
marginal cost of the 1000th scan of a common houseplant is zero. `identify-plant` can't use the same
trick: vision identification is inherently per-photo, not per-species, so every scan is a real call to
Pl@ntNet (principal) or Gemini-direct (fallback). ADR-0004 also documents that Gemini's free-tier quota
had already been exhausted once during our own testing, and it's shared per Google Cloud project, not
per key — a small number of users can exhaust it for everyone.

The concrete risk being anticipated: TestFlight beta launches concentrate load in days, not the weeks
real adoption would take, and a single enthusiastic tester scanning repeatedly can burn through
Pl@ntNet's or Gemini's shared daily free quota before other testers get to try the app at all. Today
nothing stops that — `identify-plant` has no per-user throttle, and the client already decodes
`provider_chain`/`diagnostic_code` from every response but only `print()`s them to the Xcode console,
so there'd be no warning before it happens.

## Decision

**1. Server-side daily quota, enforced in `identify-plant` before any provider call.** New columns
`daily_scan_count`/`daily_scan_reset_at` on `public.profiles`
(`supabase/migrations/20260812_0010_identify_daily_scan_quota.sql`), checked and incremented
atomically by `SECURITY DEFINER` function `check_and_increment_daily_scan_quota(p_daily_limit)`, which
reads `auth.uid()` from the caller's own JWT — never a client-supplied id, so one user can't be
attributed another's usage. `for update` row-locks the profile row for the duration of the call, so
concurrent requests from the same user can't both read count N and both increment to N+1.

**2. Client now forwards the user's real access token to `identify-plant`**, not the anon key — it
already does this for `scans` REST calls (`insertScanRowRest`, `fetchScansForCurrentUser`); this
extends the same pattern. Safe because `MainTabView` (and everything under it, including the scanner)
is only reachable once `authViewModel.isAuthenticated`, so a valid access token always exists at the
call site.

**3. Fails open, not closed.** If the quota RPC is unreachable, misconfigured, or errors for any
reason, `identify-plant` proceeds as if the check passed. A broken quota mechanism should cost the
free-tier budget, at worst — it should never be the reason a signed-in user can't identify a plant.
This mirrors the project's existing philosophy (`narrate-plant`'s cache writes are already
best-effort/fire-and-forget; `identify-plant` itself always returns HTTP 200 with a fallback body
rather than surfacing a hard failure).

**4. Distinct `quota_exceeded` field, not an HTTP error status.** Matches the existing response shape
(`fallback`, `diagnostic_code`, etc. are always present, never a non-2xx from this function). The
client throws a new `BotanyServiceError.dailyQuotaExceeded` with copy the scanner's existing error
banner already knows how to display, instead of quietly returning a low-confidence "Unknown specimen"
result — quota exhaustion should read as an expected, explained state, not a broken feature.

**5. No client-side change to caching.** The existing per-device, per-exact-photo cache
(`cachedIdentifyResult`) still short-circuits before this call, so re-analyzing the same photo never
counts against quota — only new photos do.

## Consequences

### Positive

- One tester can no longer exhaust Pl@ntNet's or Gemini's shared free-tier quota for every other
  tester on the same day — the actual anticipated beta-launch failure mode.
- No new provider or infrastructure dependency; reuses the `profiles` table and the same
  fetch-to-PostgREST style already used throughout both edge functions.
- Attribution is via verified JWT (`auth.uid()`), not a client-supplied id — can't be spoofed to grief
  another user's quota.

### Negative

- Adds real, visible friction: a tester who hits the limit will notice and may be confused or annoyed
  without in-app messaging beyond the error banner text.
- The limit is a single hardcoded default (`p_daily_limit`, currently 25) with no admin/allowlist
  override yet — a tester who legitimately needs more (e.g. for a demo) has no self-serve path around
  it.
- Doesn't address `identify-plant` still having only two providers, or give visibility into how close
  to the ceiling usage is before hitting it — that's the PostHog instrumentation gap called out
  alongside this decision, not yet done.

## Next Actions

1. Wire `provider_chain`/`diagnostic_code`/`quota_exceeded` into a PostHog event so quota pressure is
   visible before it becomes a support fire mid-beta (currently `print()`-only).
2. Get current Pl@ntNet/Gemini free-tier numbers (last confirmed via ADR-0004 testing, 2026-08-07) and
   size `p_daily_limit` against actual expected beta headcount rather than the placeholder default.
3. Apply the migration — same Dashboard SQL Editor workaround as ADR-0004 (`supabase migration
   list`/`db push` still blocked by the unresolved CLI role-provisioning bug tracked there).
