# App Store launch checklist (LeafID native)

Use this before submitting a Release build to App Store Connect. Date: 2026-05-09.

## Product and stability

- [ ] Identify → Preserve → Herbarium works on a clean install (signed-in user).
- [ ] Auth: email, password reset deep link, and any enabled OAuth providers (e.g. Google).
- [ ] Arboretum: map gestures, zoom controls, specimen pins, location permission denial path.
- [ ] No DEBUG-only overlays in Release (e.g. location debug banner; verify Archive scheme).
- [ ] No secrets committed in source: use `LeafID-native/Config/Secrets.local.xcconfig` (gitignored; copy from `Secrets.local.xcconfig.example`). Archive/TestFlight builds must not ship known-leaked keys—rotate OpenRouter / Gemini / Supabase if they were ever in git.

## Permissions and copy (`Info.plist`)

- [ ] `NSCameraUsageDescription` — accurate, user-facing reason.
- [ ] Photo library usage string if the picker accesses the library.
- [ ] `NSLocationWhenInUseUsageDescription` — map + capture metadata; matches actual use.

## Privacy and compliance

- [ ] App Privacy questionnaire in App Store Connect matches data collection (photos, location, account, AI if applicable).
- [ ] Public privacy policy URL live and referenced in Connect.
- [ ] If the app uses generative AI for plant copy, describe it accurately in review notes and product page.

## Backend and security

- [ ] Production Supabase project: migrations applied (e.g. `scans.user_id`), RLS tightened toward least privilege.
- [ ] Edge functions: validation, timeouts, no leaked service keys in client bundles.
- [ ] Rotate any previously exposed API keys; revoke old keys after validation.

## App Store Connect assets

- [ ] Version/build numbers, copyright, age rating.
- [ ] Screenshots for required device classes and locales you support.
- [ ] App icon and launch screen correct for all idiom/size requirements.

## QA matrix (suggested)

- [ ] Smallest and largest target iPhone sizes; latest iOS and declared minimum OS.
- [ ] Dark mode; poor network / offline graceful degradation.
- [ ] Denied camera, photos, and location (each).

## Submission

- [ ] TestFlight internal smoke on Release build, then external beta if needed.
- [ ] Review notes: test account credentials if login is required; steps for reviewers.
