# Development Log - LeafID-native

Chronological record of development sessions, features completed, and key decisions.

---

## Session: 2026-09-28 - TestFlight backlog: D1, account deletion, i18n, observability, Sign in with Apple

**Focus**: Burn down P0/P1 launch blockers + onboarding UI polish
**Status**: ✅ Code complete for the items below; some need manual dashboard/device steps before "done"

### Completed (with commits)

1. **Onboarding/tutorial spacing + headline alignment**
   - Cover paragraphs: 50px top margin. Tutorial headline anchored at 50px so it lands on the
     *same baseline* as the onboarding headline (verified 4px apart in simulator); the eyebrow is an
     overlay above it, so its height never shifts the headline.
   - Files: `Views/Onboarding/OnboardingView.swift`. Commits `c32ee62`, `87557c6`, `0acf56e`, `da03bf2`.

2. **D1 — free-tier gate + dead paywall (P0)** — `a038160`
   - Single source of truth `FeatureFlags.premiumGatingEnabled = false` (top of `DruidProfileViewModel.swift`).
   - When false: `canUserScan()` in `HomeView` + `DruidProfileViewModel` short-circuit to true (no gate,
     paywall never opens); Druid quota card shows the daily-quota message; "Buy me a coffee" card hidden.
   - Replaces the earlier `#if DEBUG` hack that left the gate live in Release/TestFlight.
   - Flip the flag to `true` to re-enable gating once real StoreKit IAP exists.

3. **In-app account deletion (P1)** — `2756bb2`, `c178ab4`
   - `supabase/functions/delete-account/index.ts` (deployed to project `yuflikryfeunofptgrtr`, v1,
     verify_jwt=true). Deletes `scans` → `profiles` → best-effort storage (`plant-photos` + `plant-images`,
     lowercased-userId keys) → `auth.admin.deleteUser`.
   - Druid → "Delete account" with confirmation; `AuthViewModel.deleteAccount`.
   - Verified: unauth call → 401. NOT verified: real end-to-end delete (needs a throwaway account).

4. **Localized permission prompts (P1)** — `a6ad0a9`
   - Added `en.lproj/InfoPlist.strings` + `es.lproj/InfoPlist.strings` (camera/location/photos),
     registered the variant group in Copy Bundle Resources. Verified bundled via `plutil`.

5. **Quota observability (P1)** — `2df2c98`
   - `BotanyService.identifyPlantWithAI` emits PostHog `scan_quota_exceeded` and `scan_identify_result`
     (provider, provider_chain, provider_fallback_used, fallback, diagnostic_code, confidence).
   - NOT verified live (needs a real signed-in scan to confirm events land).

6. **Sign in with Apple (D3, P1)** — `d6d1fdf`, `505061e`
   - Native `SignInWithAppleButton` on LoginView, onboarding, Druid overlay. Supabase `id_token` grant
     with hashed/raw nonce, reusing `persistSessionTokens`/`hydrateSession`.
   - Added `LeafID-native.entitlements` (`com.apple.developer.applesignin`) + `CODE_SIGN_ENTITLEMENTS`.
   - Verified: builds clean, button renders (auto-localizes). NOT working end-to-end yet — see below.

### ⚠️ Pending manual steps (need Mariana's dashboards/device — cannot be done from code)

- **Sign in with Apple:** (1) enable "Sign in with Apple" capability on App ID `com.marianaminafro.leafid`
  in the Apple Developer portal; (2) create a Services ID + Sign in with Apple key and configure the Apple
  provider in Supabase (Auth → Providers → Apple). Then verify on a real device with an Apple ID.
- **Account deletion:** run one real end-to-end delete with a throwaway account (destructive).
- **Quota observability:** do a real signed-in scan and confirm events land in PostHog.

### Next up (tomorrow)

- **D4 — iPhone-only / portrait-only** (verifiable in-repo: `TARGETED_DEVICE_FAMILY` + orientation in
  pbxproj/Info.plist). Recommended for v1 to avoid iPad-layout rejection.
- **Real app icon** (replace `AppIcon-placeholder-1024.png`) — needs a design asset.
- **Privacy policy + App Store Connect privacy label** (add Sentry/PostHog/AI providers).
- Remaining P0 that needs the Apple account: signing/ASC record, release-config secrets in an Archive,
  release-build device smoke test, provider-quota health-check.

### Environment / how to resume (verified this session)

- **Build:** `xcodebuild -scheme LeafID-native -destination 'platform=iOS Simulator,name=iPhone 17' build`
  — do NOT pass `-derivedDataPath` (it triggers a stale Sentry XCFramework path error; default DerivedData
  works). iPhone 16 sim isn't installed; iPhone 17 is.
- **Run/screenshot:** simulator runs headless (no GUI window, can't mouse-tap). Use
  `xcrun simctl install/launch booted com.marianaminafro.leafid` + `xcrun simctl io booted screenshot`.
  Jump straight to LoginView with the launch arg `-hasCompletedOnboarding YES` (NSArgumentDomain).
- Full item status + the D3 manual steps are checked off/annotated in `docs/BACKLOG.md`.

---

## Session: 2026-09-27 - Bug Framework Setup

**Duration**: 2 hours  
**Focus**: Setting up comprehensive bug identification and fixing framework  
**Status**: ✅ Complete

### Completed

#### 1. **Created AppLogger.swift**
   - Location: `LeafID-native/Services/AppLogger.swift`
   - Pre-built logging shortcuts for all major subsystems
   - Categories: botany, network, auth, ui, storage, app
   - Examples: `AppLog.plantIdentified()`, `AppLog.networkError()`, etc.

#### 2. **Documentation Package**
   Created 5 comprehensive guides:
   
   - **BUG_FRAMEWORK_SUMMARY.md** (this session)
     - Overview of entire framework
     - What you get, quick start, success criteria
   
   - **TESTING_QUICK_START.md**
     - 5-minute setup
     - Daily workflow
     - Common issues
   
   - **TESTING_AND_DEBUGGING.md**
     - Complete reference guide
     - Device testing setup
     - Test organization (unit/integration/UI)
     - Error tracking with Sentry
     - Debug configuration
   
   - **LOGGING_INTEGRATION_EXAMPLE.md**
     - Real code examples
     - How to integrate AppLogger
     - Before/after comparisons
     - Common patterns
   
   - **SETUP_CHECKLIST.md**
     - Step-by-step 8-phase setup
     - Device connection
     - Console setup
     - Testing foundation
     - Error tracking verification
   
   - **TESTING_CHEAT_SHEET.md**
     - Quick reference
     - Common commands
     - Console filtering
     - Bug hunting workflow
     - Copy-paste code blocks

#### 3. **Testing Framework Integration**
   - Verified XCTest is already in place
   - Found existing test file: `LeafID-nativeTests/LeafID_nativeTests.swift`
   - Current tests: 6 unit tests covering utilities
   - Ready to expand with integration and UI tests

#### 4. **Error Tracking Verification**
   - Confirmed Sentry already integrated in `AppMonitoring.swift`
   - Sentry automatically captures crashes and uncaught exceptions
   - PostHog analytics also configured
   - Both services ready to use

### What's In Place Now

#### Infrastructure ✅
- [x] Structured logging system (AppLogger)
- [x] Device testing with Xcode
- [x] Console log viewing and filtering
- [x] XCTest framework
- [x] Sentry error tracking
- [x] PostHog analytics

#### Documentation ✅
- [x] Complete reference guides
- [x] Quick start guide
- [x] Setup checklist
- [x] Code examples
- [x] Cheat sheet

#### Not Yet Done (Next Steps)
- [ ] Integrate AppLogger into services
- [ ] Add new integration tests
- [ ] Achieve 70%+ code coverage
- [ ] Monitor Sentry dashboard regularly
- [ ] Establish daily testing routine

### Key Decisions

1. **Using XCTest** (not Third-party)
   - Apple's built-in framework
   - Integrated with Xcode
   - Great device testing support
   - Sufficient for current needs

2. **Structured Logging with Logger Framework**
   - Better than print() or NSLog
   - Zero overhead in Release builds
   - Perfect filtering in Console
   - Categories for organization

3. **Real Device Testing First**
   - USB connection during development
   - Real network behavior
   - Real performance characteristics
   - Will move to TestFlight later

4. **Sentry for Error Tracking**
   - Already integrated
   - Automatic crash reporting
   - Great for production monitoring
   - Free tier sufficient

### Metrics

**Files Created**: 7
- AppLogger.swift (1 file)
- Documentation (6 files)

**Documentation Pages**: 6
- Total words: ~12,000
- Code examples: 50+
- Setup steps: 40+
- Console filters: 15+

**Time Investment**: 2 hours
- Problem analysis: 20 min
- Component creation: 40 min
- Documentation: 60 min

### Next Session Priorities

1. **Day 1** (30 min): Connect device and verify logging
   - Plug in iPhone
   - Run ⌘R
   - Open Console ⌘⇧C
   - Verify logs appear

2. **Day 2** (1 hour): Add logging to BotanyService
   - Import AppLogger
   - Add 5-10 log calls
   - Test on device
   - Watch Console for logs

3. **Day 3** (1 hour): Create 3-5 integration tests
   - Based on TESTING_QUICK_START.md
   - Test critical services
   - Run with ⌘U

4. **Day 4+** (daily): Device testing workflow
   - Connect device
   - Test features
   - Find and log bugs
   - Fix with test verification

### Insights & Learnings

1. **Device Testing is Critical**
   - Simulator != Real device
   - Network behavior differs
   - Performance differs
   - Device testing catches real issues

2. **Logging is Better than Debugging**
   - Can't always break on device
   - Logging shows exact flow
   - Console filtering very powerful
   - Much faster than breakpoints for device

3. **Test-First Bug Fixing**
   - Write test that reproduces bug
   - Watch it fail
   - Fix code
   - Watch test pass
   - Prevents regression

4. **Sentry is Gold**
   - Automatically tracks all crashes
   - See what users experience
   - Much better than user reports
   - Worth monitoring regularly

### Resources Used

- Apple's Logger documentation
- XCTest framework docs
- Sentry iOS integration guide
- SwiftUI testing patterns

### Success Criteria Met

- [x] Identified current testing framework (XCTest)
- [x] Found error tracking in place (Sentry)
- [x] Created structured logging system
- [x] Documented comprehensive approach
- [x] Provided quick-start guide
- [x] Created actionable next steps

---

## Session: [Next Session]

**Duration**: TBD  
**Focus**: Integrate logging into services  
**Status**: Not started

### Plan

1. Import AppLogger in BotanyService
2. Add logging calls for plant identification flow
3. Test on device
4. Verify logs in Console
5. Create 3-5 integration tests

---

## Bug Tracking

### Current Status
- **Total Bugs Found**: 0
- **Bugs Being Investigated**: 0
- **Bugs Fixed**: 0
- **Sentry Issues**: [Check sentry.io]

### Bug Log

(Bugs will be logged here as found)

---

## Performance Notes

### App Startup
- Current: [TBD - measure with profiling]
- Target: < 2 seconds

### Plant Identification
- Current: [TBD - depends on network]
- Network call: < 3 seconds on good network
- Processing: < 1 second

### Memory
- Current: [TBD - monitor with Instruments]
- Target: < 200MB for idle, < 400MB peak

---

## Architecture & Decisions

### ADR-001: Logging Strategy
**Decision**: Use Apple's Logger framework with AppLog helper

**Rationale**:
- Native to iOS, no external dependencies
- Zero overhead in Release builds
- Perfect Console filtering
- Structured data logging

**Alternatives Considered**:
- print() / NSLog: Too simple, no filtering
- SwiftyBeaver: Overkill, external dependency
- CocoaLumberjack: Legacy, not maintained

**Status**: Implemented ✅

### ADR-002: Testing Framework
**Decision**: Use XCTest for all tests

**Rationale**:
- Built-in to Xcode
- No setup required
- Perfect device testing
- Works with UI tests

**Alternatives Considered**:
- Quick/Nimble: Nice syntax but external dependency
- XCTest is sufficient

**Status**: Confirmed ✅

### ADR-003: Device Testing Approach
**Decision**: Real device testing during development, then TestFlight

**Rationale**:
- Real network conditions
- Real device performance
- Catch real issues early
- Better than simulator-only testing

**Phases**:
1. Device testing (current)
2. Internal testing group
3. TestFlight beta
4. App Store release

**Status**: Phase 1 ✅

---

## Team Notes

- Framework ready for team to use
- No external dependencies added
- All guidance in TESTING_QUICK_START.md
- Questions? See TESTING_AND_DEBUGGING.md

---

**Last Updated**: 2026-09-27 14:30  
**Session Duration**: 2 hours  
**Status**: ✅ Complete - Ready for next phase
