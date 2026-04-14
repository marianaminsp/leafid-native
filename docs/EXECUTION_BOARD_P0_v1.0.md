# P0 Execution Board v1.0

Date: 2026-04-10  
Owner: Engineering  
Goal: Remove critical blockers and establish production-safe baseline.

**Strategy:** Phase 1 (Next + Capacitor + Supabase) is **complete** for the current UI/auth/save baseline. **Phase 2** tracks the native SwiftUI rebirth; see backlog below.

---

## Phase 1 — Product completion — **100% COMPLETED** (2026-04-11)

**Objective (achieved for current stack):** Identify (Plant.id) → Preserve → Herbarium with signed-in `user_id`, **The Druid** (profile + Apple/email auth + password reset deep link), **The Arboretum** (full-screen dark Leaflet + dummy pins), Herbarium header visual standard shared across tabs, save path hardened (insert errors surfaced, `scans` ownership column configurable via env), migration docs for Swift handoff (`docs/SWIFT_MIGRATION_GUIDE.md`).

**Remaining product depth (moved to Phase 2 / ongoing ops, not blocking “Phase 1” closure):**

- Real map coordinates on `scans`, Druid live stats, production RLS tightening (remove public fallbacks when ready).

---

## Phase 2 — Native Swift Rebirth (backlog)

**Objective:** Rebuild the primary iOS client in SwiftUI while keeping Supabase, Storage, and `identify-plant` as the backend of record.

- [ ] SwiftUI app shell: tabs mirroring Identify / Herbarium / Arboretum / Druid.
- [ ] Supabase Swift (or REST) client: session persistence, cold start restore, sign-in with Apple + email flows.
- [ ] Implement Identify → Preserve → Herbarium using schema in `docs/SWIFT_MIGRATION_GUIDE.md` (including `user_id` / ownership column).
- [ ] Deep link: `com.marianaminafro.leafid://reset-password` for password recovery.
- [ ] Map: MapKit (or MapLibre) with dark styling; consume `latitude` / `longitude` on `scans` once migrated.
- [ ] Visual parity: apply HEX and liquid-glass specs from `docs/SWIFT_MIGRATION_GUIDE.md`.
- [ ] TestFlight pipeline independent of Capacitor WebView.

---

## P0 Workstreams

## W1 - Platform and Build Clarity

- [ ] Decide primary path for current milestone:
  - [ ] A: Stabilize Capacitor for near-term TestFlight.
  - [ ] B: Start Expo RN migration immediately.
- [x] Align identifiers and naming (`appId`, bundle id, product naming).
- [x] Define release build scripts and deterministic pipeline.

## W2 - Security and Secrets

- [x] Remove hardcoded Supabase credentials from client source.
- [x] Fix edge function secret retrieval by env variable name.
- [ ] Rotate exposed keys (Supabase, Groq) and verify old keys revoked.
- [ ] Add security checklist to PR/release process.

## W3 - Privacy and Permissions

- [x] Clean iOS permission strings to App Review quality.
- [ ] Add location permission only when location feature is implemented.
- [ ] Add in-app explanation screens for permission rationale.

## W4 - Data Governance

- [x] Add first migration set for core tables.
- [ ] Enforce RLS policies with least privilege.
- [x] Add typed domain contracts and validation layer.

## Current Sprint Log

- 2026-04-11: **Phase 1 marked 100% complete.** `scans` ownership via `getScansUserColumn()` + `SWIFT_MIGRATION_GUIDE.md`; Herbarium-standard headers (Arboretum, Druid, Herbarium); Phase 2 Swift backlog initialized.
- 2026-04-11: Backlog section added (Arboretum real pins, Druid stats, Herbarium sync). UI: Druid scroll + copy, Arboretum dark basemap + layout, Identify Latest Discovery post-save only, password reset flow.
- 2026-04-10: Documentation system created (audit, roadmap, changelog, learnings, ADR, board).
- 2026-04-10: Completed first W2 hardening pass (`lib/supabase.ts`, `supabase/functions/identify-plant/index.ts`, `.env.example`).
- 2026-04-10: Completed W1/W3 pass for identity and privacy copy (`capacitor.config.ts`, `ios/App/App/Info.plist`).
- 2026-04-10: Added first RLS migration baseline (`supabase/migrations/20260410_0001_rls_baseline.sql`) from live policy audit.
- 2026-04-10: Refined RLS baseline to match real schema (`scans` has no ownership column) with transitional public insert/select fallback.
- 2026-04-10: Added ownership migration (`20260410_0002_scans_ownership_baseline.sql`) and typed app service updates in `lib/botanyService.ts`.
- 2026-04-10: Added deterministic iOS build scripts and testing runbook/checklist for rapid UI iteration and validation.

## Blockers

- **Remote Supabase:** If production still errors with `column scans.user_id does not exist`, apply `20260410_0002_scans_ownership_baseline.sql` (documented in `docs/SWIFT_MIGRATION_GUIDE.md`).

## Next 3 Actions

1. **Apply `user_id` migration** on any Supabase project that has not run `20260410_0002_scans_ownership_baseline.sql`.
2. Plan **Phase 2** SwiftUI spike (auth + one vertical slice: Identify → Preserve).
3. Run TestFlight smoke checklist after `npm run build` + `cap copy` on Capacitor path.

## Board Changelog

- v1.3 (2026-04-11): **Phase 1 = 100% completed**; **Phase 2: Native Swift Rebirth** backlog added; Swift migration doc reference; blocker note for missing `user_id` on remote DB.
- v1.2 (2026-04-11): Added **Phase 1 — Backlog** (Arboretum real pins, Druid stats, Herbarium sync); refreshed code-gap notes and Next 3 Actions.
- v1.1 (2026-04-10): Added Phase 1 product plan (Druid profile, Arboretum map, login), acceptance criteria, implementation order, SwiftUI gate note.
- v1.0 (2026-04-10): Initial P0 board created and populated.
