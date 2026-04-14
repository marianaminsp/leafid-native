# Changelog

All notable engineering and product changes are documented here.

## [Unreleased]

### Added

- `docs/ui-screens/BotanicalCard.md` — front/back botanical detail spec and Plant.id field mapping on `Scan`.
- `docs/ui-screens/Herbarium.md` — Herbarium tab layout, `HerbariumSpecimenRowCard`, scroll-collapsing header, and save path from results.
- `HerbariumSpecimenRowCard` + Foundry section; `Scan.foundRelativePhrase()` for “Found … ago” list copy.
- Versioned documentation system:
  - `docs/AUDIT_ZeroComplacency_v1.0.md`
  - `docs/ROADMAP_TestFlight_Premium_v1.0.md`
  - `docs/EXECUTION_BOARD_P0_v1.0.md`
  - `docs/ENGINEERING_OPERATING_SYSTEM_v1.0.md`
  - `docs/LEARNINGS_LOG.md`
  - `docs/DECISIONS/ADR-0001-platform-direction.md`
- Added first Supabase migration: `supabase/migrations/20260410_0001_rls_baseline.sql` for RLS hardening baseline.
- Refined RLS migration to match live schema and prevent flow breakage when `scans` has no ownership column.
- Added ownership baseline migration: `supabase/migrations/20260410_0002_scans_ownership_baseline.sql` (`scans.user_id`, FK, indexes).
- Added release operations docs:
  - `docs/TESTING_AND_RELEASE_RUNBOOK_v1.0.md`
  - `docs/SMOKE_TEST_CHECKLIST_v1.0.md`

### Changed

- **BotanicalCardDetailView:** Front follows `botanicalcard-front/code.html` via `LeafIDTheme.botanical*` (56/24 close insets, 40/112 overlay, 36pt title, HTML tonal gradient, bottom flip FAB, rarity offsets, 48pt radius, outline 10%). Back-only glass chrome; shared card shell; card width = screen − 2× `screenHorizontalPadding`.
- **Layout gutters:** Home upload pill inner padding, Druid profile scroll, and floating tab bar use `screenHorizontalPadding` (24pt); documented as canonical content inset in `Theme.swift`.
- **Herbarium (native):** Scrollable list with `HerbariumSpecimenRowCard`, scroll-driven header shrink, `LeafIDTheme.surface` chrome; PDR §3.B updated for list + `Herbarium.md`.
- **Druid / Arboretum / Identify:** Profile title copy, scrollable Druid layout, Arboretum header + full-bleed map below header with **CARTO Dark Matter** tiles; Identify **Latest Discovery** card only after successful Preserve; Herbarium list fields aligned to `scans` (`common_name`, `scientific_name`, `photo_url`); post-save `loadData` awaited for fresher Herbarium.
- **Auth:** Password recovery via `Forgot password?` → glass modal + `resetPasswordForEmail` + inbox confirmation state (`lib/auth.ts`, `AuthGate.tsx`).
- `docs/EXECUTION_BOARD_P0_v1.0.md`: **Phase 1 — Backlog** (real map pins, Druid stats, Herbarium sync), board v1.2; earlier v1.1 Phase 1 product plan + roadmap cross-link unchanged in substance.
- Started P0 security hardening for environment/secret handling.
- Replaced hardcoded Supabase credentials with env-based configuration in `lib/supabase.ts`.
- Fixed Supabase Edge Function secret access to use `Deno.env.get("GROQ_API_KEY")`.
- Added `.env.example` with required client environment variables.
- Added local `.env.local` using existing Supabase project values to keep runtime behavior stable.
- Updated `README.md` as documentation hub for roadmap, audit, and execution artifacts.
- Versioned `PDR_LeafID.md` to v1.1 and linked companion execution docs.
- Aligned Capacitor identity in `capacitor.config.ts` (`appId` and `appName`).
- Upgraded iOS permission text in `ios/App/App/Info.plist` to App Review-quality copy and removed non-standard key.
- Strengthened `lib/botanyService.ts` with typed contracts and optional `user_id` persistence for new scans.
- Added deterministic iOS preparation scripts in `package.json` (`build:web`, `cap:sync:ios`, `ios:prepare`, `ios:open`).

