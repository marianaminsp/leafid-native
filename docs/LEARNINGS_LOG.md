# Learnings Log

Purpose: capture high-signal learnings, validated assumptions, and failed experiments to accelerate execution.

## Entry Template

- Date:
- Area:
- Hypothesis:
- Action:
- Result:
- Decision:
- Follow-up:

## Entries

### 2026-04-10 - Platform/Deployment

- Hypothesis: Existing stack is ready for Expo EAS cloud path.
- Action: Audited repo structure, package dependencies, and build files.
- Result: Project is currently `Next.js + Capacitor`, not Expo.
- Decision: Treat Expo migration as strategic direction; avoid pretending EAS readiness until migration starts.
- Follow-up: Lock milestone path in P0 board.

### 2026-04-10 - Security

- Hypothesis: Secret handling is production-ready.
- Action: Audited `lib/supabase.ts` and edge function code.
- Result: Hardcoded credentials and incorrect env retrieval found.
- Decision: Move credentials to environment and rotate leaked keys.
- Follow-up: Complete key rotation and post-rotation validation.

### 2026-04-10 - Documentation Operations

- Hypothesis: A simple roadmap note is enough to keep execution aligned.
- Action: Introduced versioned docs, ADR, changelog, and learning log with operating rules.
- Result: Progress tracking is now explicit, auditable, and iterative.
- Decision: Keep all strategic and tactical updates versioned in `docs/`.
- Follow-up: Update execution board and changelog on each meaningful change.

### 2026-04-10 - Supabase Policy Baseline

- Hypothesis: Existing live policies can be translated into a safer migration baseline without breaking current behavior.
- Action: Used exported policy list to create idempotent RLS migration with targeted policy cleanup/recreation.
- Result: Public write risk on `trees` addressed in migration; ownership-based `scans` policies prepared with dynamic column detection.
- Decision: Apply migration only after confirming ownership column and existing table schema snapshots.
- Follow-up: Collect table/column inventory and validate migration on staging first.

### 2026-04-10 - Schema Reality Check

- Hypothesis: `scans` ownership policy can be enforced immediately.
- Action: Reviewed live schema snapshot for `public.scans`.
- Result: No ownership column exists (`user_id`/`profile_id` absent), so strict owner-based RLS would break current app writes.
- Decision: Keep transitional public insert/select for `scans` and `trees` while planning ownership migration.
- Follow-up: Add `scans.user_id` and shift insert path to authenticated or edge-function-controlled writes.

