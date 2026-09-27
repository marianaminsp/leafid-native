# Testing & Debugging Cheat Sheet 📋

Keep this open while testing. Copy-paste commands as needed.

---

## 🚀 STARTUP

```bash
# 1. Connect device
Plug in iPhone via USB

# 2. Trust computer (on device)
Settings → General → Trust [Your Computer]

# 3. Run app (in Xcode)
⌘R

# 4. Open console (watch logs)
⌘⇧C
```

---

## 🔍 CONSOLE FILTERING (⌘F in Console)

| Command | Shows |
|---------|-------|
| `category:"botany"` | Plant identification |
| `category:"network"` | Network requests |
| `category:"auth"` | Authentication |
| `level:error` | Only errors |
| `level:warning` | Warnings + errors |
| `"timeout"` | Search text |

---

## 📝 LOGGING (Use Anywhere in Code)

```swift
// Plant identification
AppLog.identifyingPlant(fromImage: "camera")
AppLog.plantIdentified(species: "Alocasia", confidence: 0.95)
AppLog.plantIdentificationFailed(error)

// Network
AppLog.networkRequest(method: "POST", endpoint: "/api/identify")
AppLog.networkResponse(statusCode: 200, duration: 1523.5)
AppLog.slowNetworkResponse(duration: 4523, endpoint: "/api/identify")
AppLog.networkError(error, endpoint: "/api/identify")

// User actions
AppLog.userLoggedIn(userID: "user-123")
AppLog.userLoggedOut()
AppLog.userAction("Tapped camera button")

// Generic
AppLog.debug("Custom message")
AppLog.warning("⚠️ Something")
AppLog.error("❌ Failed")
```

---

## ✅ TESTING (⌘U to Run)

```swift
// Add to LeafID_nativeTests.swift

// Simple test
func testPlantIdentificationSucceeds() async throws {
    let service = BotanyService()
    let result = try await service.identifyPlant(image: testImage)
    XCTAssertNotNil(result)
}

// Error test
func testHandlesNetworkError() async {
    let service = BotanyService(mockClient: ErrorMockClient())
    let result = await service.identifyPlant(image: testImage)
    XCTAssertNil(result)
}

// Run all tests
⌘U

// Run specific test
⌘U (while cursor in test function)

// Watch test results
Tests tab in navigator (left panel)
```

---

## 🐛 FINDING BUGS

### Step 1: Notice Issue
```
App does something wrong while testing
OR
Console shows error
```

### Step 2: Reproduce
```
Note exact steps to reproduce
Example:
1. Tap Camera
2. Take photo
3. Wait for result
4. Plant not identified
```

### Step 3: Capture Logs
```
In Console:
⌘A (select all)
⌘C (copy)
Paste into bug report
```

### Step 4: Create Test Case
```swift
func testBugXXX_PlantNotIdentified() async {
    // Minimal code to reproduce
    let service = BotanyService()
    let result = await service.identifyPlant(image: darkImage)
    
    // This should fail with current code
    XCTAssertNotNil(result)
}

// Run: ⌘U
// Should FAIL (confirming bug exists)
```

### Step 5: Fix Code
```
Make the code change
```

### Step 6: Verify Fix
```
Run test again: ⌘U
Should PASS ✅ (confirming bug fixed)
```

---

## 🔧 DEVICE MANAGEMENT

```bash
# View connected devices
Window → Devices and Simulators

# View device logs
Window → Devices and Simulators
→ Select device → View Device Logs

# Trust computer again
On device: Settings → General → Trust [Computer]

# Unpair device
Window → Devices and Simulators
→ Right-click device → Unpair
(then plug back in to re-pair)

# Clear device logs
Window → Devices and Simulators
→ View Device Logs → [Clear button]
```

---

## 📊 SENTRY (Error Tracking)

```bash
# View errors
Go to https://sentry.io
→ LeafID-native project
→ Issues tab

# What you see
- Crash details
- Device info (iOS version, device model)
- Stack trace
- Breadcrumbs (actions before crash)
- User info (if logged in)

# Set up error context (in code)
import Sentry

let scope = SentrySDK.getCurrentScope()
scope.setContext(value: ["plantID": "123"], key: "plant")
SentrySDK.captureException(error)
```

---

## ⚡ QUICK COMMANDS

| Action | Shortcut |
|--------|----------|
| Run app | ⌘R |
| Stop app | ⌘. (period) |
| Run tests | ⌘U |
| Show console | ⌘⇧C |
| Search/filter console | ⌘F (when console active) |
| Profile app | ⌘I |
| Build (without running) | ⌘B |
| Build + Run | ⌘R |
| Run without building | ⌘⌃R |

---

## 🔴 COMMON ISSUES & FIXES

### Console shows nothing
```
✓ Device connected? (Check top-left dropdown)
✓ Console open? (⌘⇧C)
✓ App running? (Green indicator in Xcode)
❌ Try: Stop (⌘.) → Run (⌘R)
```

### App crashes, need device logs
```
1. Window → Devices and Simulators
2. Select your device
3. Click "View Device Logs" (bottom panel)
4. Find the crash entry
5. Can download for analysis
```

### Can't connect device
```
1. Unplug USB cable
2. Window → Devices and Simulators
3. Right-click device → Unpair
4. Plug USB back in
5. On device: Trust computer again
6. Try: Product → Run (⌘R)
```

### Tests failing inconsistently
```
✓ Add logging to understand what's different
✓ Use real data (not just mocks)
✓ Run individually: click test name
✓ Run on device: ⌘R to see real behavior
```

### App runs slow
```
1. Profile: ⌘I
2. Choose "Time Profiler"
3. Let it run while you use app
4. See which methods take most time
5. Optimize those methods
```

---

## 📈 MEASURING PERFORMANCE

### Network Timing
```swift
let start = Date()
let result = try await api.post("/identify", data: imageData)
let duration = Date().timeIntervalSince(start) * 1000
AppLog.networkResponse(statusCode: 200, duration: duration)
// Logs: ✓ Response: 200 (1523.5ms)
```

### Function Timing
```swift
let start = CFAbsoluteTimeGetCurrent()
processImage(image)
let duration = (CFAbsoluteTimeGetCurrent() - start) * 1000
AppLog.debug("Image processing took: \(String(format: "%.0f", duration))ms")
```

---

## 📚 REFERENCE FILES

| Document | Purpose |
|----------|---------|
| `TESTING_QUICK_START.md` | 5-min setup |
| `SETUP_CHECKLIST.md` | Step-by-step setup |
| `TESTING_AND_DEBUGGING.md` | Full reference |
| `LOGGING_INTEGRATION_EXAMPLE.md` | Code examples |
| `BUG_FRAMEWORK_SUMMARY.md` | Overview |
| `AppLogger.swift` | Logging shortcuts |

---

## 🎯 DAILY ROUTINE

```
Morning:
├─ ⌘R (run on device)
├─ ⌘⇧C (open console)
├─ ⌘F (filter logs)
└─ Ready to test

Testing:
├─ Go through features
├─ Watch for errors
├─ Note unusual behavior
└─ Take screenshots

Bug Found:
├─ Note steps
├─ Copy console logs
├─ Create test case
├─ Make code change
├─ Run ⌘U to verify
└─ Commit with test

Before Shutdown:
├─ ⌘U (all tests pass?)
├─ Check Sentry dashboard
└─ Update DEVLOG.md
```

---

## 💾 COPY-PASTE BLOCKS

### New Test Template
```swift
func testBugXXX_DescribeIssue() async throws {
    // Setup
    let service = BotanyService()
    
    // Execute
    let result = try await service.identifyPlant(image: testImage)
    
    // Verify
    XCTAssertNotNil(result)
}
```

### Error Handling with Logging
```swift
do {
    let result = try await identifyPlant(image)
    AppLog.plantIdentified(species: result.species, 
                          confidence: result.confidence)
    return result
} catch {
    AppLog.plantIdentificationFailed(error)
    return nil
}
```

### Network Call with Timing
```swift
let startTime = Date()
let response = try await api.post("/api/identify", with: imageData)
let duration = Date().timeIntervalSince(startTime) * 1000
AppLog.networkResponse(statusCode: 200, duration: duration)
```

---

## ✨ PRO TIPS

1. **Filter console by category while testing**
   - Reduces noise, easier to spot issues
   - `category:"botany"` shows only plant logs

2. **Keep one test failing** while fixing bug
   - Ensures fix actually works
   - Prevents regression (test catches if you break it again)

3. **Use breakpoints strategically**
   - Click line number to add breakpoint
   - Xcode pauses there, shows variables
   - Great for complex logic

4. **Test on real device, not simulator**
   - Real network behavior
   - Real performance
   - Real device constraints

5. **Watch Sentry daily**
   - New errors appearing?
   - Can see patterns
   - Know what users experience

6. **Log at decision points**
   - Before/after API calls
   - Before/after state changes
   - Before/after conditional branches

---

## 🚨 WHEN STUCK

1. **Check Console** (⌘⇧C)
   - Is there an error?
   - What does it say?

2. **Filter Console** (⌘F)
   - `level:error` to find errors
   - `category:"botany"` for feature

3. **Check Sentry** (sentry.io)
   - Same error happening in real app?
   - How many users affected?

4. **Create Test Case**
   - Minimal code to reproduce
   - Try to make test fail first
   - Then fix code to make it pass

5. **Add More Logging**
   - Log before/after problem area
   - Narrow down where it fails
   - Fix the exact line

6. **Run on Device vs Simulator**
   - Different behavior? Network issue
   - Same on both? Local code issue

---

**Print or bookmark this page**
**Last Updated**: 2026-09-27
