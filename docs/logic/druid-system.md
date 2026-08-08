# Druid Identity System

This document defines the canonical logic for Druid identity, progression, and energy behavior in LeafID.

## Progression Path

- `0-5` scans: `Wandering Seed` (Icon: `Seedling`)
- `6-15` scans: `Forest Sprout` (Icon: `Leaf`)
- `16-50` scans: `Oak Guardian` (Icon: `Tree`)
- `50+` scans: `Archdruid` (Icon: `Sparkles`)

## Redesign Note: Level/XP Backfill (2026-08-08)

The neo-brutalist redesign's Druid screen (`stitch_botanical_explorer/the_druid`, `DruidNeoBrutalistView.swift`) introduces a numeric Level + XP model ("LVL 24", "8,240 / 10,000 XP") on top of the rank titles above — distinct from this doc's original scan-count-only thresholds. Reconciling the two (does XP map 1:1 to scan count, or is it a separate weighted point system per discovery?) is still open and needs to happen before the redesign's Druid screen is built for real, not just mocked.

**Decision:** when Level/XP logic ships, it must be computed from each user's *existing* discovery/scan history, not reset to zero. A user who already has 40 discoveries starts at whatever level that history earns them the same day the feature ships — nobody gets pushed back to "Seedling Druid" / Level 1 just because the feature launched after they signed up. This mirrors ADR-0002's precedent for the Arboretum map: GPS data keeps being captured specifically so the map can backfill historical pins once it ships — same backfill principle applies here to Level/XP.

Consequence for the redesign mockups: the "Seedling Druid" empty state (design exploration only, not yet built) is the correct state solely for users with **zero real history** — not a temporary placeholder state for every user on launch day.

## Energy System

- Base (free users): `3` scans total
- Premium users: `Unlimited` scans

## Druid Passport (UI Logic)

- If user is **not logged in**:
  - Show `Login Overlay` with `Google Sign-in`.

- If user **is logged in**:
  - Show:
    - `User Name`
    - `Rank`
    - `Energy Gauge`
  - If scans are `0`, show a `Buy me a Coffee` button.

## Implementation Note

All future features that touch Druid progression, scan gating, or passport rendering must follow this file as source-of-truth logic.

## Latest Status

### DONE (Implemented & Pushed)

- Druid progression thresholds are implemented in `LeafID-native/ViewModels/DruidProfileViewModel.swift` via `rankTitle` (`0-5`, `6-15`, `16-50`, `50+`).
- Druid energy quota logic is implemented in `LeafID-native/ViewModels/DruidProfileViewModel.swift` (`freeScanLimit = 3`, premium unlimited, `canUserScan()`).
- Druid Passport UI shell is implemented in `LeafID-native/Views/Druid/DruidProfileView.swift` (passport header, energy card, login overlay, scanner/paywall gate area).
- URL scheme and OAuth callback entry are implemented in `LeafID-native/Info.plist` (`leafid`) and `LeafID-native/LeafID_nativeApp.swift` (`onOpenURL` handling `leafid://auth`).
- Paywall presentation and basic scan gating are implemented in `LeafID-native/Views/Home/HomeView.swift`, `LeafID-native/Views/Identify/IdentifyView.swift`, and `LeafID-native/Views/Druid/PaywallView.swift`.

### IN PROGRESS (Coded, Needs Testing/Validation)

- OAuth callback bridge correctness is partially implemented but not fully validated end to end (`LeafID-native/LeafID_nativeApp.swift` + `LeafID-native/Views/Druid/DruidProfileView.swift`).
- Current login UX still uses local shortcut state in `DruidProfileView` (`completeLocalGoogleLoginDisplay()`), so UI can appear logged in before callback verification.
- Paywall/entitlement path is UI-complete but purchase activation is not wired in production (`PaywallView` has `onUpgradeTap` placeholder usage).

### PENDING (Next Steps)

- Add deterministic tests for `leafid://auth` callback success, error, empty payload, and invalid host/scheme behavior in app callback handling.
- Align and unify scan-count source of truth (`profile.scans_count` used for gating vs separate lifetime counter path in stats storage).
- Decide and apply the canonical Druid tab surface (`MainTabView` currently routes `.druid` to `ProfileView`, while passport logic is in `DruidProfileView`).
- Resolve rule mismatch for passport CTA (`Buy me a Coffee`) against this doc's stated condition.
- Complete production auth/payment configuration work (Google Cloud production redirect setup and premium entitlement activation path).
- Reconcile scan-count rank thresholds above with the redesign's Level/XP model, then implement Level/XP as a backfill from existing history — see "Redesign Note: Level/XP Backfill" above.

## Consistency Audit Snapshot

- `DruidProfileView` logic broadly matches this document's rank/energy model, but it is not currently the active `.druid` tab destination in `MainTabView`.
- URL scheme config for `leafid://auth` is present and callback parsing exists, but callback reliability and state transitions still need focused tests.
- Paywall surfaces are in place, but entitlement activation and callback-side validation remain the key reliability gap.

## Next Immediate Action

First task when resuming: create and run a focused test suite for `leafid://auth` callback handling in `LeafID-native/LeafID_nativeApp.swift` before changing any auth behavior.

Recommended first test matrix:
- `leafid://auth#access_token=...&id_token=...` -> logs user in and posts auth-change notification.
- `leafid://auth?error=access_denied` -> clears login state and posts auth-change notification.
- `leafid://auth` (no tokens/error) -> no false-positive login transition.
- Non-matching scheme/host -> ignored safely.
