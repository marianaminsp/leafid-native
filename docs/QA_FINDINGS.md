# LeafID-native QA Findings — Pre-TestFlight Audit
**Date:** 2026-09-28  
**Status:** BLOCKING ISSUES IDENTIFIED

---

## Critical Issues (P0 — Blocks TestFlight Upload)

### 1. **Dead Paywall Flow ("Buy me a coffee" button)**
- **Location:** `DruidProfileView.swift:259-260` and PaywallView
- **Issue:** The "Buy me a coffee" button opens PaywallView which has no StoreKit implementation
- **User Impact:** Users tap button → see "not connected yet" → dead end
- **Blocking:** D1 decision needed (free-tier gate strategy)
- **Fix Required:** Either:
  - (a) Disable the 3-scan gate for beta testers, rely on server daily quota
  - (b) OR hide the paywall until StoreKit is implemented
- **Status:** ⚠️ **DECISION PENDING** — See backlog D1

### 2. **Non-functional "Unlock more" Button**
- **Location:** `DruidProfileView.swift:191-193`
- **Issue:** Button also opens PaywallView (same dead-end problem)
- **User Impact:** Users at 3-scan limit see "Unlock more" button → hits dead end
- **Related to:** Issue #1 (same root cause)
- **Status:** ⚠️ **DECISION PENDING** — Depends on D1

### 3. **3-Scan Lifetime Limit Creates Dead-End**
- **Location:** `DruidProfileViewModel.swift:13` (`freeScanLimit = 3`)
- **Issue:** After 3 scans, testers cannot scan further without premium
- **Current Workaround:** Only owner's account marked `is_premium = true` in database
- **Problem:** Any other beta tester hits dead end after scan #3
- **Blocking:** Cannot invite multiple testers without fixing this
- **Status:** ⚠️ **INTERIM DECISION ACTIVE** — Revisit before expanding testers

### 4. **Server Daily Quota (Live but Untested)**
- **Status:** Deployed 2026-09-26 (migration `0010`, `identify-plant` v62)
- **Outstanding:** Manual in-app test not yet done (step 2 of BACKLOG.md)
- **Outstanding:** PostHog events for quota pressure not wired
- **Action Required:** 
  1. Manual test: Sign in → scan → bump `daily_scan_count` near limit → verify "come back tomorrow" message
  2. Wire PostHog events (quota_exceeded, provider_chain diagnostics)
- **Status:** ⚠️ **IN PROGRESS** — Part of P0

---

## High-Priority Issues (P1 — Blocks External TestFlight)

### 5. **No In-App Account Deletion**
- **Requirement:** App Store Guideline 5.1.1(v)
- **Missing:** 
  - No client UI in Druid ("Delete account" action)
  - No `delete-account` edge function
- **Needed:** Service role to delete storage images, `scans`, `profiles`, then call `auth.admin.deleteUser`
- **Status:** ❌ **NOT IMPLEMENTED**

### 6. **No Sign in with Apple**
- **Requirement:** App Store Guideline 4.8 (if Google is offered, must have equivalent)
- **Current:** Google OAuth only
- **Missing:** Apple Sign-In (Supabase supports it)
- **Risk:** Beta App Review or App Store review may flag this
- **Status:** ❌ **NOT IMPLEMENTED**

### 7. **App Icon Still Placeholder**
- **Location:** Asset `AppIcon-placeholder-1024.png`
- **Status:** ❌ **NOT DESIGNED**

### 8. **Privacy Policy Gaps**
- **Issue:** Policy doesn't mention:
  - Sentry (crash data collection)
  - PostHog (product interaction tracking)
  - AI provider details (Pl@ntNet, Google Gemini, Groq photos sharing)
- **Current:** Both services already declared in `PrivacyInfo.xcprivacy`
- **Status:** ⚠️ **PARTIALLY ADDRESSED** — Documentation gap

### 9. **App Store Connect Privacy Label Missing**
- **Requirement:** Fill privacy label matching `PrivacyInfo.xcprivacy`
- **Data Categories:** Email, precise location, photos, crash data, product interaction (all linked, none for tracking)
- **Status:** ❌ **NOT FILLED**

### 10. **Permission Strings Incomplete**
- **Issue:** English strings rewritten 2026-09-26 but no Spanish (`es.lproj/InfoPlist.strings`)
  - English users see localized prompts
  - Spanish users see English prompts (no translation)
- **Location String:** Still references shelved map feature ("center Arboretum on your position and geotag discoveries on the map")
  - Correct: "We need access to your photos to scan for plant identification and geotagging"
- **Status:** ⚠️ **PARTIALLY DONE** — ES translation missing, text needs reword

### 11. **Quota Observability Missing**
- **Issue:** `identify-plant` currently logs quota pressure with `print()` only
- **Need:** Send `provider_chain`, `diagnostic_code`, `quota_exceeded` to PostHog
- **Why:** This is how you'll monitor provider pressure while testers are active
- **Status:** ❌ **NOT IMPLEMENTED**

### 12. **Beta App Review Info Not Prepared**
- **Missing:**
  - Beta description
  - "What to Test" note
  - Working demo account (email + password, pre-confirmed)
  - Reviewer contact email
- **Status:** ❌ **NOT WRITTEN**

---

## Medium-Priority Issues (P2 — Before App Store Submission)

### 13. **StoreKit / Premium Not Implemented**
- **Issue:** PaywallView references StoreKit but no products, transactions, or recovery
- **Options:**
  - Implement real IAP (significant work)
  - OR hide paywall entirely until v2
- **Recommendation:** Hide paywall for v1 (see D1)
- **Status:** ❌ **NOT IMPLEMENTED**

### 14. **`print()` Calls Not Cleaned Up**
- **Count:** 34 instances in app target
- **Should:** Route useful logs to Sentry breadcrumbs instead
- **Status:** ⚠️ **DEFERRED** — Not a blocker

### 15. **iPad & Landscape Support Declared but Not Tested**
- **Current:** `TARGETED_DEVICE_FAMILY = "1,2"` and landscape declared in pbxproj (lines 712–713, 723)
- **Issue:** No view has iPad or landscape layout
- **Recommendation:** iPhone-only / portrait-only for v1
- **Risk:** App Review tests on iPad → layout rejection if not addressed
- **Action:** Either implement layouts or remove device family declaration
- **Status:** ⚠️ **DECISION PENDING** — See D4 in backlog

### 16. **Keychain Migration Incomplete**
- **Issue:** OAuth PKCE verifier still in UserDefaults (short-lived, low severity)
- **Status:** ⚠️ **DEFERRED** — Not a blocker

### 17. **Light Mode Not Tested**
- **Current:** Dark-only (appears intentional but not confirmed)
- **Status:** ⚠️ **DEFERRED** — Design decision

### 18. **Accessibility Not Audited**
- **Needs:**
  - VoiceOver on every screen
  - Dynamic Type at largest size
  - Reduce Motion (scanner reveal sweep)
- **Baseline:** Only 15/36 view files had labels in prior audit
- **Status:** ❌ **NOT DONE** — P2 priority

### 19. **CI/CD Not Configured**
- **Missing:** Build + unit tests on every push (GitHub Actions or Xcode Cloud)
- **Status:** ❌ **NOT IMPLEMENTED**

### 20. **Store Listing Not Created**
- **Needs:**
  - Screenshots for required device sizes (EN + ES)
  - Age rating, category, copyright
  - Base copy on `APP_STORE_LISTING.md` (map claims already removed)
- **Status:** ❌ **NOT WRITTEN**

---

## Summary: Path Forward

| Phase | Status | Blocker Count |
|-------|--------|---------------|
| **P0** (Internal TestFlight) | ⚠️ Blocked | **4 critical** |
| **P1** (External TestFlight) | ❌ Not Ready | **8 high** |
| **P2** (App Store) | ❌ Not Ready | **8 medium** |

### Immediate Actions (Next 2-3 Days)

1. **Resolve D1** (free-tier gate strategy)
   - Decision: Disable 3-scan gate for beta? OR raise gate to 25?
   - Impact: Unblocks testers
   
2. **Manual Daily Quota Test** (30 min)
   - Sign in → scan → manually bump `daily_scan_count` near 25
   - Verify "come back tomorrow" message appears
   
3. **Wire PostHog Quota Events** (1-2 hours)
   - Add events to `identify-plant` when quota exceeded
   
4. **In-App Account Deletion** (4-6 hours)
   - Druid UI: Add "Delete account" action
   - Edge function: `delete-account` (calls `auth.admin.deleteUser`)
   
5. **Privacy Policy & Label Updates** (1-2 hours)
   - Add Sentry, PostHog, AI providers to privacy policy
   - Fill App Store Connect privacy label

### Test Checklist
- [ ] Release-build smoke test on a real device (if available)
- [ ] Sign up → scan → save → Herbarium → Druid → sign out → relaunch
- [ ] Confirm DEBUG-only Foundry gear/gallery is absent
- [ ] Verify one PostHog + Sentry event arrives from Release build
- [ ] Tap "Buy me a coffee" → verify dead end (then decide D1)
- [ ] Create new account → hit 3-scan limit → verify message (D1 decision)

---

## Notes

- **Provider Quotas:** Last verified 2026-08-07. Check Pl@ntNet, Gemini, Groq dashboards before inviting testers
- **Free-tier Project:** Auto-pauses after ~1 week idle. Was paused 2026-09-26; check Dashboard if identification suddenly fails
- **Build Issue Resolved:** Initial SPM path issue resolved by omitting `-derivedDataPath` flag (2026-09-28)
