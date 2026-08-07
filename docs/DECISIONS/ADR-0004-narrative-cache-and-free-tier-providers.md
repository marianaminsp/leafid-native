# ADR-0004: Shared species narrative cache, Groq as narrate-plant's primary provider

Date: 2026-08-07
Status: Accepted
Decision owners: Product/Engineering

## Context

Right after deploying `narrate-plant` ([ADR-0003](./ADR-0003-narrative-generation-server-side.md)), live
testing showed it returning empty content for every request. Diagnosis (via temporary debug output in
the function's response) found two independent bugs, not a config oversight:

1. `OPENROUTER_API_KEY` is dead — OpenRouter returns `401 "User not found"`, meaning the key itself
   doesn't authenticate, not a rate limit.
2. The code's OpenRouter model ID was never valid — `"model": "openrouter/free"` isn't a real OpenRouter
   model. Verified live against openrouter.ai/collections/free-models: genuine free, vision-capable
   models exist under real IDs (e.g. `google/gemma-4-26b-a4b-it:free`), just not the alias the code used.
3. `GEMINI_API_KEY`'s free-tier quota is also exhausted (`429`). Per Google's current docs, free-tier
   quotas are shared per Google Cloud project (not per key) and have been shrinking — this one key backs
   both `identify-plant` and `narrate-plant`, making it a single point of failure for two chains.

Separately, `GROQ_API_KEY` turned out to already be a live, configured Supabase secret — a leftover from
the project's earlier Next.js/Capacitor stack (per `docs/CHANGELOG.md`), unused in the current native
code. Groq's free tier is genuine (no credit card, ~30 RPM / 1K RPD per model), reliable for text.

Beyond fixing the broken providers, the deeper question was how to make "free tier only" hold at scale
rather than just adding more fallback depth to absorb rate limits. Since the cultural/historical
narrative content is entirely species-level (not photo-specific — "Lavandula angustifolia" gets the same
Botanical Spirit / Ethnobotany / Cultural Legacy regardless of who scans it or how many times), it's a
textbook case for a shared cache: the real botanical species catalog any user base will encounter is
small and slow-changing, so the marginal cost of serving the 1000th scan of a common houseplant should be
zero, not another model call.

## Decision

**1. Shared species-level cache.** New table `public.plant_narrative_cache`
(`supabase/migrations/20260807_0007_plant_narrative_cache.sql`), keyed by a normalized scientific name
(lowercase/trim/whitespace-collapse only — deliberately not fuzzy-matching or stripping taxonomic
authority suffixes, to avoid silently merging two different taxa; worst case of conservative
normalization is a lower hit rate, not wrong data). Public read (harmless botanical facts, not user
data); writes are service-role only, so no client request can pollute content every user reads.
`narrate-plant` is now a read-through/write-through cache: check the table first, and only call a
provider on a miss, writing successful results back for the next request to reuse.

**2. Groq as narrate-plant's new primary provider**, with Gemini-direct staying as the fallback if Groq
returns incomplete fields. OpenRouter's call path is shelved — kept in the file, removed from the active
chain, commented with why and what's needed to re-enable it (rotate the key, the model ID is already
fixed to a real `:free` ID in the shelved function so it's ready to go once the key works).

**3. `identify-plant` unchanged** (`Pl@ntNet → Gemini-direct`) — vision identification is inherently
per-photo, not cacheable the same way.

**4. Did not add a third provider (e.g. GitHub Models)** for extra cold-path coverage. It's real and free
and supports vision, but has a thin ceiling (50 req/day for capable models) and needs new account/token
setup — the cache does more for coverage than a third provider would, since it removes most cold-path
traffic entirely rather than adding a backstop under it. Cheap to revisit later if real usage shows the
2-provider chain + cache isn't enough.

## Consequences

### Positive

- After the cache warms up, the fraction of scans that ever call a rate-limited model shrinks toward
  zero — this is the primary lever for "free tier only" actually holding as usage grows, more so than
  provider count.
- Groq's key was already valid and required zero new setup, unlike the OpenRouter fix.
- No client-side changes — `BotanyService.swift` is unaware of caching or which provider answered.

### Negative

- `identify-plant` still only has 2 providers (Pl@ntNet, Gemini-direct) — Gemini's exhausted quota
  leaves it with a single working provider until the daily reset. Accepted for now (see Next Actions).
- Cache normalization is conservative on purpose, so minor scientific-name formatting differences
  between providers (e.g. trailing taxonomic authority) create separate cache rows instead of merging —
  a correctness-over-hit-rate tradeoff.

## Next Actions

1. ~~Apply the migration to the live project~~ **Done (2026-08-07).** Landed via the Supabase Dashboard
   SQL Editor, working around the CLI role-provisioning error (`supabase migration list`/`db push` still
   fail with `permission denied to alter role`; tracked separately, not a blocker since this migration is
   already applied).
2. ~~Verify cache hits end-to-end~~ **Done (2026-08-07).** Confirmed against the live `narrate-plant` v4
   with `Monstera deliciosa`: cache miss → Groq call → write-through (`source: "groq"`); repeat request →
   `_debug: ["cache: hit"]`, no provider call, ~0.5s; a request with mixed case/extra whitespace in the
   scientific name still hit the same row, confirming `normalizeScientificNameKey`; `hit_count`
   incremented per hit; `mode: "legacy_fact"` cached independently via the merge-duplicates upsert without
   clobbering the already-cached `botanical_spirit`/`ethnobotany`/`cultural_legacy` fields.
3. Re-check `identify-plant` after Gemini's quota resets (daily, midnight Pacific) — no code change
   needed, just confirmation.
4. Revisit OpenRouter (rotate `OPENROUTER_API_KEY`) or add a third narrate-plant provider only if real
   post-launch usage shows the current chain + cache isn't sufficient.
5. CLI role-provisioning error (`permission denied to alter role` on `cli_login_postgres`) — **diagnosed
   as a Supabase platform-side bug (2026-08-07), not fixable from this project.** `supabase migration
   list`/`db push` fail because the Management API recreates the ephemeral `cli_login_postgres` role
   under an owner that the project's `postgres` role isn't an `ADMIN OPTION` member of (Postgres 16+
   requires `CREATEROLE` *and* `ADMIN OPTION` on the specific target role, not just `CREATEROLE`
   generally, to alter it). Confirmed by dropping the role via the Dashboard SQL Editor (`DROP ROLE IF
   EXISTS cli_login_postgres;`, succeeded with no error) and immediately retrying `supabase migration
   list` — it failed with the identical error, meaning the role gets recreated with the same broken
   ownership on every attempt. Matches unresolved reports upstream (Supabase CLI
   [#5091](https://github.com/supabase/cli/issues/5091), Supabase
   [discussion #37471](https://github.com/orgs/supabase/discussions/37471)). No user-side or SQL Editor
   workaround exists; needs a Supabase support ticket against this project. Until resolved, apply
   migrations via the Dashboard SQL Editor (as done for `20260807_0007_plant_narrative_cache.sql`).
