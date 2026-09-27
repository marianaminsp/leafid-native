# Bug Identification & Fixing Framework - Setup Checklist

Complete this checklist to have a solid testing framework connected with Xcode.

---

## Phase 1: Infrastructure (30 minutes)

### ✅ Logging System
- [x] `AppLogger.swift` created with Logger categories
  - Location: `LeafID-native/Services/AppLogger.swift`
  - Contains: botanyLogger, networkLogger, authLogger, etc.
  - Status: Ready to use

### ✅ Documentation
- [x] `TESTING_AND_DEBUGGING.md` created
  - Comprehensive guide for device testing
  - Console filtering, test organization, error tracking
  - Status: Reference guide ready
  
- [x] `TESTING_QUICK_START.md` created
  - 5-minute quick start
  - Daily workflow
  - Console commands
  - Status: Quick reference ready

### ✅ Error Tracking
- [x] Sentry already integrated via `AppMonitoring.swift`
  - Captures crashes automatically
  - Captures uncaught exceptions
  - Status: Ready to use

---

## Phase 2: Device Connection (15 minutes)

### Connection Setup
- [ ] **Connect iPhone/iPad via USB**
  - Physical device required (not simulator for this phase)
  - Status: _____________________

- [ ] **Trust Computer on Device**
  - On device: Settings → General → Trust [Your Computer Name]
  - Status: _____________________

- [ ] **Verify in Xcode**
  - Window → Devices and Simulators
  - Your device should show green "Connected" dot
  - Status: _____________________

### Build & Run Setup
- [ ] **Select Device in Xcode**
  - Top-left dropdown (next to scheme name)
  - Should show your device name (e.g., "iPhone 15 Pro")
  - Status: _____________________

- [ ] **Build & Run App**
  - Product → Run (⌘R)
  - Or: ⌘R shortcut
  - App should install and launch on device
  - Status: _____________________

---

## Phase 3: Xcode Console Setup (10 minutes)

### Enable Console
- [ ] **Open Debug Console**
  - Keyboard: ⌘⇧C
  - Or: View → Debug Area → Show Debug Area
  - You should see a panel appear at the bottom showing logs
  - Status: _____________________

- [ ] **Test Logging**
  - Look for Sentry initialization logs
  - Look for PostHog initialization logs
  - Should see something like: "Sentry initialized" or "PostHog configured"
  - Status: _____________________

### Configure Console Filtering
- [ ] **Search/Filter Console**
  - In Console: ⌘F (opens filter dialog)
  - Try: `category:"botany"`
  - Try: `level:error`
  - Try: `category:"network"`
  - Status: _____________________

---

## Phase 4: Add Logging to One Service (20 minutes)

Pick one service and add AppLogger calls. Example: `BotanyService`

### Integrate AppLogger
- [ ] **Import AppLogger in one service**
  - File: `LeafID-native/Services/BotanyService.swift`
  - Add at top: Add proper import when AppLogger is accessible
  - Status: _____________________

- [ ] **Add 5-10 log calls**
  - When plant identification starts: `AppLog.identifyingPlant(...)`
  - When it succeeds: `AppLog.plantIdentified(...)`
  - When it fails: `AppLog.plantIdentificationFailed(...)`
  - When loading details: `AppLog.loadingPlantDetails(...)`
  - Status: _____________________

- [ ] **Rebuild and Test**
  - ⌘R to rebuild and run on device
  - Go through plant identification flow
  - Watch Console (⌘⇧C) - should see your logs
  - Status: _____________________

- [ ] **Filter Logs**
  - In Console: ⌘F
  - Filter: `category:"botany"`
  - Should see only botany-related logs
  - Status: _____________________

---

## Phase 5: Testing Foundation (30 minutes)

### Review Existing Tests
- [ ] **Run Current Tests**
  - ⌘U to run all tests
  - Should pass without errors
  - Location: `LeafID-native/LeafID-nativeTests/LeafID_nativeTests.swift`
  - Status: All pass ✅ / Some fail ❌
  - Status: _____________________

### Add One New Test
- [ ] **Create One Integration Test**
  - Based on: `TESTING_QUICK_START.md` → "Task 1"
  - Add test to `LeafID_nativeTests.swift`
  - Example: `testIdentifyPlantWithValidImage()`
  - Status: _____________________

- [ ] **Run New Test**
  - ⌘U to run
  - Should pass or provide clear failure
  - Status: Pass ✅ / Fail ❌ (intentional?)
  - Status: _____________________

### Verify CI Connection
- [ ] **Tests Run Locally**
  - ⌘U takes < 5 seconds
  - Results show in test navigator
  - Status: _____________________

- [ ] **Xcode Shows Test Coverage**
  - Product → Scheme → Edit Scheme
  - Test tab → Code Coverage: enabled
  - Run ⌘U again
  - Should show % coverage on files
  - Status: _____________________

---

## Phase 6: Error Tracking Verification (10 minutes)

### Sentry Integration Check
- [ ] **Sentry Dashboard Accessible**
  - Go to https://sentry.io
  - Login with your credentials
  - Select "LeafID-native" project
  - Status: _____________________

- [ ] **Test Error Capture**
  - Simulate an error in app (intentionally)
  - Force divide-by-zero or nil reference (in dev only)
  - Let Sentry capture it
  - Check Sentry dashboard after 30 seconds
  - Should see the error listed in Issues
  - Status: _____________________

- [ ] **Verify Breadcrumbs**
  - In Sentry error detail
  - Should see "Breadcrumbs" section showing:
    - App launch
    - User actions
    - Network requests
  - Status: _____________________

---

## Phase 7: Daily Testing Workflow (5 minutes)

### Create Daily Test Routine
- [ ] **Morning Checklist**
  - [ ] Connect device via USB
  - [ ] Open Xcode
  - [ ] ⌘R to run on device
  - [ ] ⌘⇧C to open Console
  - [ ] Ready to test
  - Status: _____________________

- [ ] **When Testing**
  - Go through feature normally
  - Watch Console for any errors/warnings
  - Use ⌘F to filter logs: `level:error`
  - Status: _____________________

- [ ] **When Bug Found**
  - Note exact steps to reproduce
  - Copy Console logs: ⌘A, ⌘C
  - Create test case based on: `TESTING_QUICK_START.md`
  - Status: _____________________

- [ ] **When Fixing Bug**
  - Modify code
  - Run test: ⌘U (should fail before fix, pass after)
  - Run app: ⌘R (verify it works)
  - Run tests again: ⌘U (verify all still pass)
  - Status: _____________________

---

## Phase 8: Documentation Update (10 minutes)

- [ ] **Update Project CLAUDE.md**
  - Add note about logging framework
  - Add note about device testing approach
  - Add links to new docs
  - Status: _____________________

- [ ] **Update Project DEVLOG.md**
  - Record setup completion
  - Note any issues encountered
  - Record baseline test coverage
  - Status: _____________________

- [ ] **Share with Team** (if applicable)
  - Link to `TESTING_QUICK_START.md`
  - Show working example
  - Status: _____________________

---

## Quick Verification (5 minutes)

You're done when all of these work:

- [ ] Can build and run app on device: **⌘R** works
- [ ] Can see logs in Console: **⌘⇧C** shows logs while app runs
- [ ] Can filter logs: **⌘F** in console filters by category/level
- [ ] Can run tests: **⌘U** runs tests in < 5 seconds, all pass
- [ ] Can see errors in Sentry: Error dashboard shows recent app errors
- [ ] Can write test case: Created at least 1 new test case
- [ ] Can use AppLogger: Used in at least 1 service file

---

## Troubleshooting

### Console shows nothing
```
1. Check device is selected: top-left dropdown shows device name
2. Check console is open: ⌘⇧C
3. Try: Product → Stop (⌘.)
4. Then: Product → Run (⌘R) again
```

### Tests fail
```
1. Read error message carefully
2. Check test assumptions (does mock data match?)
3. Run on device to see real behavior
4. Add logging to understand issue
5. Update test or code accordingly
```

### Device not connecting
```
1. Unplug USB cable
2. In Xcode: Window → Devices and Simulators
3. Find your device, click ⓧ to unpair
4. Plug USB back in
5. Trust computer on device again
```

### Can't see Sentry errors
```
1. Check Sentry DSN is set correctly in AppMonitoring.swift
2. Wait 30 seconds for Sentry to process
3. Check you're looking at right project in Sentry.io
4. Verify app built in DEBUG mode
```

---

## Summary

**Total Setup Time**: ~2 hours (first time only)

**What You Have**:
1. ✅ Real device testing with Xcode
2. ✅ Structured logging to Console
3. ✅ Console filtering by category/level
4. ✅ XCTest framework with unit + integration tests
5. ✅ Sentry error tracking and crash reporting
6. ✅ Daily testing workflow
7. ✅ Bug → Test case → Fix → Verify cycle

**Next Steps**:
1. Continue adding logging to services
2. Build test coverage to 70%+ on critical code
3. Run daily device tests
4. Triage Sentry errors weekly
5. Document learnings in DEVLOG.md

---

**Framework Status**: ✅ Ready to use
**Last Updated**: 2026-09-27
**Setup Started**: ___________
**Setup Completed**: ___________
