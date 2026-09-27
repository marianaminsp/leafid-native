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

- [ ] **D1: Free-tier gate for beta testers.** The client blocks scanning after **3 lifetime scans**
  (`DruidProfileViewModel.swift:13`, `freeScanLimit = 3`) and opens `PaywallView`, whose upgrade button
  is a no-op with no StoreKit behind it (`PaywallView.swift:16`, copy says "not connected yet").
  A tester is at a dead end after scan #3. Options: (a) raise/disable the client gate for beta and rely
  on the server daily quota (D2), or (b) mark beta accounts `is_premium` in `profiles`.
  **Recommendation:** (a). Ship no paywall until StoreKit exists.
  **Interim decision (2026-09-26):** only the owner's account is set `is_premium = true` in `profiles`
  (via the SQL Editor), with no code change. **Revisit before inviting any other tester.** Anyone else
  still hits the 3-scan dead end.
- [x] **D2: Ship the server daily scan quota in the first build?** **Yes. Live 2026-09-26:** migration `0010` applied via the SQL Editor and `identify-plant` v62 deployed. Still open: the manual in-app test (step 2 below) and PostHog events.
  Full context in the "Daily scan quota" section below and [ADR-0005](DECISIONS/ADR-0005-identify-daily-scan-quota.md).
  If D1 = (a), this quota becomes the *only* protection for the shared free-tier provider budget.
  That argues for shipping it in the first build.
- [ ] **D3: Sign in with Apple, or drop Google?** Google OAuth is offered (login, onboarding, Druid).
  Apple Sign-In isn't. Guideline 4.8 requires an equivalent option. It usually surfaces at App Store
  review, sometimes already at Beta App Review. Adding Apple Sign-In (Supabase supports it) is the
  standard answer.
- [ ] **D4: iPad and landscape.** `TARGETED_DEVICE_FAMILY = "1,2"` and iPhone landscape are declared
  (pbxproj lines 712–713, 723), but no view has an iPad or landscape layout. **Recommendation:** iPhone-only
  and portrait-only for v1. Otherwise App Review tests on iPad and the stretched layout is a rejection risk.

---

## P0 — Blocks the first internal TestFlight upload

- [ ] **Accept the Xcode license.** `git` and `xcodebuild` currently fail with "You have not agreed to
  the Xcode license agreements" (probably after an Xcode update). Run `sudo xcodebuild -license` in
  Terminal, then re-confirm a clean build (last confirmed 2026-09-18).
- [ ] **Resolve D1** (3-scan gate + dead paywall). Without this, every tester stalls on day one.
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

- [ ] **In-app account deletion.** Required by Guideline 5.1.1(v) for any app with account creation.
  Nothing exists today (no client UI, no edge function). Needs a Druid → "Delete account" action and a
  `delete-account` edge function (service role: delete storage images, `scans`, `profiles`, then
  `auth.admin.deleteUser`).
- [ ] **Resolve D3** (Sign in with Apple).
- [ ] **Resolve D4** (iPhone-only / portrait-only), or test iPad properly.
- [ ] **Real app icon.** The asset is still `AppIcon-placeholder-1024.png`.
- [ ] **Privacy policy update.** Hosted and linked from Druid
  (`https://marianaminsp.github.io/leafid-native/docs/PRIVACY_POLICY.html`, returns 200). It doesn't
  mention **Sentry** (crash data) or **PostHog** (product interaction). Both are already declared in
  `PrivacyInfo.xcprivacy`. Also cover the AI providers photos are sent to (Pl@ntNet, Google Gemini, Groq).
- [ ] **App Store Connect privacy label.** Fill it to match `PrivacyInfo.xcprivacy`: email, precise
  location, photos, crash data, product interaction. All linked, none used for tracking.
- [ ] **Permission strings.** *(EN rewritten 2026-09-26 in pbxproj. Still to do: there is no `InfoPlist.strings`, so the prompts show in English for Spanish users. Add `es.lproj/InfoPlist.strings`.)* The location string still says "center Arboretum on your position and
  geotag discoveries on the map", but the map is shelved (ADR-0002). Reword it to describe what
  happens today (geotagging scans). "We need access to your photos…" is fine, but should use the same
  voice as the others. Check the Spanish versions too.
- [x] **Remove the `_debug` field** *(Done and deployed 2026-09-26, `narrate-plant` v6.)* from `narrate-plant` responses (`index.ts:331,379,386`). It leaks
  provider/error strings to the client. Replace it with server logs.
- [ ] **Beta App Review info.** Write the beta description and a "What to Test" note. Add a working
  demo account (email and password, pre-confirmed) in review notes. Add a contact email.
- [ ] **Quota observability.** Send `provider_chain` / `diagnostic_code` / `quota_exceeded` to PostHog
  (currently `print()` only). This is how you'll see provider pressure while testers are active.

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
4. PostHog events for quota pressure (see P1 "Quota observability").

---

## Resolved

- 2026-09-18: `DesignSystemGalleryView.swift:197` build error ("extra argument in call") no longer
  reproduces after a4da240. A clean `xcodebuild` succeeded.
- 2026-08: PostHog + Sentry wired and verified. Privacy manifest declares crash data and product
  interaction. Onboarding flow added. LLM keys moved server-side (ADR-0003). Narrative cache applied (ADR-0004).
