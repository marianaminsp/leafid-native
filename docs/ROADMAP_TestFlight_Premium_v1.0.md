# Leaf ID Roadmap to Premium TestFlight v1.0

Date: 2026-04-10  
Owner: CTO Office  
Planning horizon: 4-6 weeks (quality-first, deadline-flexible)

## North Star

Deliver a TestFlight build that feels premium, resilient, and scalable, with architecture that supports social expansion.

## Phases

### Phase 0 - Foundation and Decision (2-3 days)

- Lock v1 scope and acceptance criteria.
- Confirm platform direction (recommended: Expo React Native migration path).
- Create architecture documents and execution board.

### Phase 1 - Security and Data Baseline (3-4 days)

- Remove hardcoded secrets.
- Rotate exposed credentials.
- Introduce typed environment configuration.
- Harden edge functions (validation, timeout, standard error responses).
- Add SQL migrations and RLS policies.

### Phase 2 - Core Premium UX (5-7 days)

- Rebuild core scan flow with native-level animation and gesture quality.
- Reduce blur overdraw and tune animation tokens.
- Implement robust loading/error/empty states for every critical step.

### Phase 3 - Product Completeness (4-5 days)

**Note (2026-04-10):** Arboretum (map), Druid (profile), and login are **pulled into Phase 1** for the current app. See `docs/EXECUTION_BOARD_P0_v1.0.md` → *Phase 1 — Product completion*. This roadmap phase remains for any **additional** completeness (e.g. Tree Lore depth, social flags) after that gate.

- Arboretum MVP, Druid profile, and auth are tracked on the execution board.
- Align permissions and fallback UX for denied access (location, etc.).
- Close dead tabs/unfinished states with coherent UX.

### Phase 4 - Social-Ready Architecture (2-3 days)

- Define and implement `re-collect` schema contracts.
- Add visibility and ownership rules.
- Keep behind feature flag until validated.

### Phase 5 - Release Hardening (3-4 days)

- QA matrix on older and newer iPhones.
- Crash/perf instrumentation.
- Beta checklist, release candidate, TestFlight upload.

## Quality Gates

- No hardcoded secrets.
- No critical lint/type errors.
- Every network operation has loading/error/retry.
- Permission prompts have clear, user-centered language.
- Core interaction frame time is stable on target devices.

## Roadmap Changelog

- v1.0 (2026-04-10): Initial quality-first roadmap.
