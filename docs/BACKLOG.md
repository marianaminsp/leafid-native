# Backlog — TestFlight launch

Last reviewed: 2026-09-26, against the code on `main` (`a4da240`), not against older docs.
Supersedes the launch-gap sections of `APP_STORE_LAUNCH_CHECKLIST.md` (2026-05-09),
`EXECUTION_BOARD_P0_v1.0.md` (2026-04) and `audit/qa-launch-checklist.html` Part B (2026-08-07).
The per-screen QA cases in `audit/qa-launch-checklist.html` Part A are still the test plan.

Each item has enough context to pick back up cold. Link to the ADR or file rather than duplicating it.

**Path to launch:** Internal TestFlight (no Apple review) → External TestFlight (Beta App Review) → App Store.
Items are grouped by the stage they block.

---

## 0. Decisions to make first

These change what goes into the P0/P1 lists below.

- [x] **D1: Free-tier gate for beta testers.** **Resolved 2026-09-28 (option a).** A single build-wide
  flag `FeatureFlags.premiumGatingEnabled = false` (`DruidProfileViewModel.swift`) now switches off the
  client scan gate and the paywall in *all* configs (not just DEBUG). `canUserScan()` in `HomeView` and
  `DruidProfileViewModel` short-circuit to `true`; the Druid quota card shows the daily-quota message and
  the support/"Buy me a coffee" card is hidden while `PaywallView` has no StoreKit. Server-side daily
  quota (D2) is the only free-tier protection. Flip the flag to `true` to re-enable gating once real IAP
  ships. The interim per-owner `is_premium` hack is no longer needed for testers.
- [x] **D2: Ship the server daily scan quota in the first build?** **Yes. Live 2026-09-26:** migration `0010` applied via the SQL Editor and `identify-plant` v62 deployed. Still open: the manual in-app test (step 2 below) and PostHog events.
  Full context in the "Daily scan quota" section below and [ADR-0005](DECISIONS/ADR-0005-identify-daily-scan-quota.md).
  If D1 = (a), this quota becomes the *only* protection for the shared free-tier provider budget.
  That argues for shipping it in the first build.
- [x] **D3: Sign in with Apple.** **Decided + client done 2026-09-28 (keep both providers).** Native
  `SignInWithAppleButton` added everywhere Google is (login, onboarding, Druid), wired to Supabase's
  `id_token` grant with a hashed/raw nonce. **Two manual steps remain before it works end to end** (see
  P1 "Resolve D3" below) — both need the Apple Developer + Supabase dashboards.
- [ ] **D4: iPad and landscape.** `TARGETED_DEVICE_FAMILY = "1,2"` and iPhone landscape are declared
  (pbxproj lines 712–713, 723), but no view has an iPad or landscape layout. **Recommendation:** iPhone-only
  and portrait-only for v1. Otherwise App Review tests on iPad and the stretched layout is a rejection risk.

---

## P0 — Blocks the first internal TestFlight upload

- [x] **Accept the Xcode license.** *(No longer blocking as of 2026-09-28: repeated clean `xcodebuild`
  runs succeeded this session, so the license is accepted.)*
- [x] **Resolve D1** (3-scan gate + dead paywall). *(Done 2026-09-28 — see D1 above. Gate + paywall off
  via `FeatureFlags.premiumGatingEnabled` in all build configs.)*
- [x] **Export compliance key.** *(Done 2026-09-26 in `Info.plist`.)* Add `ITSAppUsesNonExemptEncryption = NO` (the app only uses HTTPS).
  Otherwise every upload stops at the export-compliance question in App Store Connect.
- [ ] **Check signing and the App Store Connect record.** Team `497XL32H55`, bundle id
  `com.marianaminafro.leafid`. Confirm the app record exists in App Store Connect.
  Version `1.0` / build `1`. Bump `CURRENT_PROJECT_VERSION` on every upload.
- [ ] **Release-config secrets.** `Secrets.xcconfig` has empty defaults and real values live in the
  gitignored `Secrets.local.xcconfig`. Confirm that an **Archive** (Release) build actually picks up
  `SUPABASE_URL` / `SUPABASE_ANON_KEY` / `POSTHOG_*` / `SENTRY_DSN`. Otherwise the TestFlight build
  launches into the "missing configuration" state.
- [ ] **Release-build smoke on a real device**, from an archived build, not Debug:
  sign up → scan → save → Herbarium → Druid → sign out → relaunch restores session.
  Confirm the DEBUG-only Foundry gear/gallery is absent.
  Confirm one event arrives in both PostHog and Sentry from the Release build.
- [x] **Confirm the live DB is up to date.** *(Verified 2026-09-26: `0007`, `0009` and `0010` are all live.)* Note: the free-tier
  project **auto-pauses after about a week idle** (it was paused on 2026-09-26). If identification suddenly fails, check this first. Applied: `0007` (per ADR-0004). Not confirmed:
  `20260807_0009_plant_narrative_cache_traditional_name.sql`. `0010` applied (quota, see D2).
  Check each in the Dashboard. Apply via the SQL Editor, because `db push` is still blocked (ADR-0004).
- [ ] **Provider quotas are healthy.** Check Pl@ntNet, Gemini and Groq keys and remaining free-tier
  quota in the Supabase secrets and provider dashboards. Gemini was found exhausted once (ADR-0004).

## P1 — Blocks external TestFlight (Beta App Review)

- [x] **In-app account deletion.** *(Implemented + deployed 2026-09-28.)* Druid → "Delete account" with a
  confirmation dialog (`DruidProfileView`), `AuthViewModel.deleteAccount` calls the `delete-account` edge
  function (deployed to `yuflikryfeunofptgrtr`, v1, `verify_jwt=true`). Order: delete `scans` (non-cascade
  FK to `auth.users`), then `profiles`, best-effort storage cleanup across `plant-photos` + `plant-images`
  with lowercased-userId keys, then `auth.admin.deleteUser`. **Verified:** unauth call → 401.
  **Still to do:** one real end-to-end delete with a throwaway account (destructive, do manually).
- [~] **Resolve D3** (Sign in with Apple). *Client implemented 2026-09-28 (native button + Supabase
  `id_token` exchange, entitlement added, builds clean, button renders). Remaining manual setup:*
  1. *Apple Developer portal: enable "Sign in with Apple" capability on App ID `com.marianaminafro.leafid`
     (Automatic signing then regenerates the profile — required for device/Archive builds).*
  2. *Create a "Services ID" + a Sign in with Apple key, and configure the **Apple provider** in Supabase
     Auth (Dashboard → Authentication → Providers → Apple) with the Services ID, Team ID, Key ID, and key.*
  *Until both are done, tapping the button shows Apple's sheet but the token exchange returns a provider
  error. Then verify end to end on a real device with an Apple ID.*
- [ ] **Resolve D4** (iPhone-only / portrait-only), or test iPad properly.
- [ ] **Real app icon.** The asset is still `AppIcon-placeholder-1024.png`.
- [ ] **Privacy policy update.** Hosted and linked from Druid
  (`https://marianaminsp.github.io/leafid-native/docs/PRIVACY_POLICY.html`, returns 200). It doesn't
  mention **Sentry** (crash data) or **PostHog** (product interaction). Both are already declared in
  `PrivacyInfo.xcprivacy`. Also cover the AI providers photos are sent to (Pl@ntNet, Google Gemini, Groq).
- [ ] **App Store Connect privacy label.** Fill it to match `PrivacyInfo.xcprivacy`: email, precise
  location, photos, crash data, product interaction. All linked, none used for tracking.
- [x] **Permission strings.** *(Done 2026-09-28.)* EN rewritten 2026-09-26 in pbxproj (location string
  already describes Herbarium geotagging, no shelved-map wording). Added `en.lproj/InfoPlist.strings` and
  `es.lproj/InfoPlist.strings` (camera / location / photo-library) and registered the variant group in
  Copy Bundle Resources, so prompts now localize per device language. Verified: clean build bundles both
  `.lproj/InfoPlist.strings`; `plutil` confirms the Spanish values with accents intact.
- [x] **Remove the `_debug` field** *(Done and deployed 2026-09-26, `narrate-plant` v6.)* from `narrate-plant` responses (`index.ts:331,379,386`). It leaks
  provider/error strings to the client. Replace it with server logs.
- [ ] **Beta App Review info.** Write the beta description and a "What to Test" note. Add a working
  demo account (email and password, pre-confirmed) in review notes. Add a contact email.
- [x] **Quota observability.** *(Done 2026-09-28.)* `BotanyService.identifyPlantWithAI` now captures two
  PostHog events (reusing the initialized SDK): `scan_quota_exceeded` (with `diagnostic_code`,
  `provider_chain`) before throwing `dailyQuotaExceeded`, and `scan_identify_result` on every identify
  (`provider`, `provider_chain`, `provider_fallback_used`, `fallback`, `diagnostic_code`, `confidence`).
  DEBUG `print()`s kept for local debugging. **Not yet verified live** — needs a real signed-in scan to
  confirm events land in PostHog.

## P2 — Before App Store submission (not needed for TestFlight)

- [ ] **StoreKit / premium.** Implement real IAP, or keep the paywall hidden (see D1). Remove the "not
  connected yet" disclaimer copy either way.
- [ ] **Store listing.** Screenshots for the required device sizes, EN + ES. Age rating, category and
  copyright. Base the copy on `APP_STORE_LISTING.md` (map claims were already removed).
- [ ] **Accessibility pass.** VoiceOver on every live screen, Dynamic Type at the largest size,
  Reduce Motion (scanner reveal sweep). Earlier audit: only 15/36 view files had labels.
- [ ] **Finish the Keychain migration.** The OAuth PKCE verifier is still in UserDefaults (short-lived,
  low severity).
- [ ] **Clean up `print()` calls** (34 in the app target). Route anything useful to Sentry breadcrumbs.
- [ ] **CI.** Run build + unit tests on every push (GitHub Actions or Xcode Cloud).
- [ ] **Light mode.** Confirm dark-only is a deliberate decision.

---

## Daily scan quota (detail for D2)

Added: 2026-08-12 · Status: **live since 2026-09-26** (steps 1 and 3 kept at 25/day; steps 2 and 4 open)

**What exists:** A per-user daily cap on `identify-plant` calls, enforced server-side. It stops a few
beta testers from burning through the shared free-tier provider quota (Pl@ntNet / Gemini-direct)
for everyone else on the same day. Fully implemented and building clean:

- `supabase/migrations/20260812_0010_identify_daily_scan_quota.sql` adds new columns on `profiles` and
  the `SECURITY DEFINER` function `check_and_increment_daily_scan_quota`.
- `supabase/functions/identify-plant/index.ts` checks the quota before any provider call. It returns
  `quota_exceeded: true` rather than an HTTP error.
- `BotanyService.swift` / `ScannerView.swift`: the client now forwards the real user JWT (it used to
  send the anon key) and throws `BotanyServiceError.dailyQuotaExceeded` with user-facing copy.
- Full writeup: [ADR-0005](DECISIONS/ADR-0005-identify-daily-scan-quota.md).

**Risk framing:** It is designed to fail *open*. If the migration isn't applied, an old client hits the
new function, or the RPC errors, `identify-plant` behaves exactly as before and scanning never breaks.
The residual risk: it's untested against a live Supabase instance, and it touches the most critical
path in the app.

**Before shipping:**
1. Apply the migration in the Dashboard SQL Editor.
2. Do one manual pass: sign in, scan, bump `daily_scan_count` near the limit in the table, and confirm
   the "come back tomorrow" message shows.
3. Replace the placeholder `p_daily_limit = 25` with a number sized against the current Pl@ntNet and
   Gemini free-tier limits (not re-checked since 2026-08-07).
4. ~~PostHog events for quota pressure~~ *(Done 2026-09-28 — see P1 "Quota observability".)*

---

## Resolved

- 2026-09-18: `DesignSystemGalleryView.swift:197` build error ("extra argument in call") no longer
  reproduces after a4da240. A clean `xcodebuild` succeeded.
- 2026-08: PostHog + Sentry wired and verified. Privacy manifest declares crash data and product
  interaction. Onboarding flow added. LLM keys moved server-side (ADR-0003). Narrative cache applied (ADR-0004).
