# Testing & Debugging Framework for LeafID-native

A comprehensive guide for identifying and fixing bugs during device testing with Xcode.

## 📋 Table of Contents
1. [Device Testing Setup](#device-testing-setup)
2. [Xcode Console Logging](#xcode-console-logging)
3. [Testing Framework (XCTest)](#testing-framework-xctest)
4. [Error Tracking with Sentry](#error-tracking-with-sentry)
5. [Debug Build Configuration](#debug-build-configuration)
6. [Bug Triage Workflow](#bug-triage-workflow)

---

## Device Testing Setup

### Prerequisites
- Physical iPhone/iPad with target iOS version
- Xcode with your device added to signing team
- Valid Apple Developer Certificate

### Step 1: Enable Device Debugging
1. **Connect Device to Mac via USB**
2. **Trust the Mac on device**: Settings → General → Trust
3. **In Xcode**: Window → Devices and Simulators → Select your device
4. **Verify**: Status should show "Connected" with a green dot

### Step 2: Configure Run Scheme
1. Open Xcode → Product → Scheme → Edit Scheme
2. **Run Tab**:
   - Executable: LeafID-native
   - Debug Executable: ✓ Checked
   - Console: ✓ Checked (to see logs)
   - Show environment variables: ✓ Checked
3. **Pre-actions**:
   - Add: `defaults write com.apple.CoreSimulator.CoreSimulatorService DebugLogging 1` (for detailed logs)

### Step 3: Select Device and Run
1. Top menu: Select your device from scheme dropdown
2. Product → Run (⌘R)
3. Xcode Console automatically opens below showing **all app logs in real-time**

### Step 4: Monitor Console While Testing
- **Filter logs**: ⌘F in console
- **Pause/Resume**: Pause button or ⌘Y
- **Clear**: ⌘K
- **Search patterns**: Filter by your app bundle ID or custom tags

---

## Xcode Console Logging

### Logger Framework (Recommended)
Replace NSLog/print with structured logging:

```swift
import os

// Create a logger for different subsystems
let botanyLogger = Logger(subsystem: "com.leafid.native", category: "botany")
let networkLogger = Logger(subsystem: "com.leafid.native", category: "network")

// In your code:
botanyLogger.debug("Identifying plant: \(plantName)")
botanyLogger.error("Failed to identify: \(error.localizedDescription)")
networkLogger.warning("Slow API response: \(duration)ms")
```

### Benefits Over print()
- ✅ **Severity levels**: Debug, Info, Warning, Error, Fault
- ✅ **Structured data**: Key-value pairs visible in Console
- ✅ **Filtering**: Filter by subsystem/category in Console
- ✅ **Performance**: Zero overhead in Release builds
- ✅ **Device capture**: Automatically included in device logs

### Console Viewing

#### Option 1: Xcode Console (Recommended while developing)
- Shows real-time logs during development
- Filter by subsystem: `category:"botany"`
- Right-click → Download logs for offline analysis

#### Option 2: Device Logs (After disconnecting)
1. Window → Devices and Simulators → Select device
2. View Device Logs (bottom panel)
3. Filter and search device-wide logs

---

## Testing Framework (XCTest)

### Current Test Structure
Tests are in: `LeafID-native/LeafID-nativeTests/LeafID_nativeTests.swift`

Current tests cover:
- ✅ ProfileStatsLocalStore utility
- ✅ BotanyService helpers
- ✅ KeychainTokenStore round-trip
- ✅ Color(hex:) parsing

### Expanding Test Coverage

#### 1. Unit Tests for Services

Add tests for critical services:

```swift
// MARK: - BotanyService API Tests
func testIdentifyPlantSuccessfully() async throws {
    let mockResponse = PlantIdentificationResponse(
        species: "Alocasia",
        confidence: 0.95
    )
    // Mock the network call
    let service = BotanyService(networkClient: MockNetworkClient(response: mockResponse))
    
    let result = try await service.identifyPlant(image: testImage)
    
    XCTAssertEqual(result.species, "Alocasia")
    XCTAssertGreater(result.confidence, 0.9)
}

func testIdentifyPlantNetworkError() async throws {
    let service = BotanyService(networkClient: MockNetworkClient(error: .networkUnavailable))
    
    let result = await service.identifyPlant(image: testImage)
    
    XCTAssertNil(result, "Should return nil on network error")
}
```

#### 2. ViewModel Tests

```swift
// MARK: - PlantDetailViewModelTests
func testLoadPlantDetails() async {
    let viewModel = PlantDetailViewModel(plantID: "test-123")
    
    await viewModel.loadDetails()
    
    XCTAssertNotNil(viewModel.plant)
    XCTAssertEqual(viewModel.plant?.id, "test-123")
}

func testHandlesLoadingError() async {
    let viewModel = PlantDetailViewModel(plantID: "invalid")
    
    await viewModel.loadDetails()
    
    XCTAssertNotNil(viewModel.error)
    XCTAssertTrue(viewModel.error?.contains("not found") ?? false)
}
```

#### 3. Integration Tests

```swift
// MARK: - Integration Tests
func testFullImageCaptureToIdentificationFlow() async throws {
    // Test the complete user flow
    let camera = MockCameraService(image: testPlantImage)
    let botany = BotanyService()
    
    let capturedImage = try camera.capturePhoto()
    let identification = try await botany.identifyPlant(image: capturedImage)
    
    XCTAssertNotNil(identification.species)
}
```

#### 4. UI Tests

Create `LeafID-nativeUITests/` for UI testing:

```swift
func testNavigateToPlantDetail() {
    let app = XCUIApplication()
    app.launch()
    
    // Tap on first plant result
    app.cells.firstMatch.tap()
    
    // Verify detail screen shows
    XCTAssertTrue(app.navigationBars["Plant Details"].exists)
    XCTAssertTrue(app.images["plant-photo"].exists)
}

func testOpenCameraFromHome() {
    let app = XCUIApplication()
    app.launch()
    
    app.buttons["Camera"].tap()
    
    // Camera permission dialog might appear
    app.alerts.buttons["Allow"].tap()
    
    // Verify camera view opened
    XCTAssertTrue(app.otherElements["CameraView"].exists)
}
```

### Running Tests with Xcode

```bash
# Run all tests
⌘U

# Run specific test class
⌘U while cursor in test file

# Run tests on device
Product → Scheme → Edit Scheme → Test → Run
Select your device before running
```

---

## Error Tracking with Sentry

Sentry is already integrated via `AppMonitoring.swift`. Enhance it:

### 1. Custom Error Context

```swift
import Sentry

// In error handlers:
do {
    try await identifyPlant(image)
} catch {
    // Capture with context
    let scope = Sentry.SentrySDK.getCurrentScope()
    scope.setContext(value: [
        "plant_species": plantName,
        "image_size": "\(image.size.width)x\(image.size.height)",
        "user_tier": userProfile.tier
    ], key: "plant_identification")
    
    Sentry.SentrySDK.captureException(error)
}
```

### 2. Breadcrumbs for Debugging

```swift
// Log important actions
Sentry.SentrySDK.addBreadcrumb(
    Sentry.Breadcrumb(
        level: .info,
        message: "User opened plant detail",
        data: ["plant_id": plant.id, "timestamp": Date()]
    )
)
```

### 3. User Tracking

```swift
// In login/auth flow:
Sentry.SentrySDK.setUser(
    Sentry.User(userId: userID, email: userEmail, username: displayName)
)
```

### Viewing Errors in Sentry Dashboard

1. Go to [sentry.io](https://sentry.io)
2. Select LeafID-native project
3. Issues tab shows all reported errors
4. Click on any issue to see:
   - Device info
   - iOS version
   - Stack trace
   - Breadcrumbs
   - Custom context
   - User info

---

## Debug Build Configuration

### Ensure Debug Symbols Are Included

1. Xcode → Targets → LeafID-native
2. Build Settings tab
3. Search: "Debug Information Format"
4. For Debug: `DWARF with dSYM File`
5. For Release: `DWARF with dSYM File` (for stack trace symbolication)

### Enable Console Logging Levels

Update `AppMonitoring.swift`:

```swift
static func configure() {
    // ... existing code ...
    
    #if DEBUG
    // Enable verbose logging in debug builds
    os_log_set_level(OS_LOG_DEFAULT, OS_LOG_TYPE_DEBUG)
    #endif
}
```

### Environment Variables for Testing

In Xcode Scheme → Run → Arguments:

```
-com.apple.CoreSimulator.CoreSimulatorService DebugLogging 1
-com.apple.CoreFoundation.CFLogLevel 3
-NSDebugEnabled YES
```

---

## Bug Triage Workflow

### Daily Device Testing Cycle

1. **Pre-Test Setup** (5 min)
   ```bash
   # Make sure device is connected
   xcode-select --install  # Update Xcode if needed
   
   # Clear device app data for clean test
   Product → Scheme → Run → Arguments
   Add environment: RESET_APP_DATA=1
   ```

2. **Test on Device** (Testing phase)
   - Xcode Console visible (⌘⇧C)
   - Filter logs by subsystem: `category:"botany"` or `category:"network"`
   - Perform user flows
   - Note any issues

3. **Capture Issues** (When bug found)
   - **Screenshot**: ⌘S (saves to Desktop)
   - **Device Log**: Window → Devices → View Device Logs
   - **Console**: ⌘A to select all, ⌘C to copy
   - **Note exact steps to reproduce**

4. **Create Reduced Test Case**
   ```swift
   // Add to LeafID_nativeTests.swift
   func testBugXXX_ReproducesIssueWithEmptyPlantName() {
       // Minimal code to reproduce the bug
       let emptyPlant = Plant(name: "", species: nil)
       
       // This should fail before fix, pass after
       XCTAssertNotNil(emptyPlant.displayName)
   }
   ```

5. **Fix and Verify**
   - Make code change
   - Run: ⌘U to verify test passes
   - Run: ⌘R on device to verify real behavior
   - Run: ⌘U again to ensure no regression

### Bug Report Template

When logging an issue in docs/DEVLOG.md:

```markdown
## Bug: [Brief Title]

**Severity**: Critical / High / Medium / Low

**Device**: iPhone 15 Pro, iOS 18.0

**Steps to Reproduce**:
1. Open app
2. Tap "Camera"
3. Take photo of leaf
4. Observe: [What happens]
5. Expected: [What should happen]

**Console Error**:
```
[Error] botany: Failed to process image: NSInvalidArgumentException
```

**Test Case**:
```swift
func testBugXXX_ReproducesIssue() {
    // Minimal reproduction
}
```

**Root Cause**: [Your analysis]

**Fix**: [Code change]

**Verification**: ✓ Test passes, ✓ Device test passes, ✓ No regression
```

---

## Commands Reference

### Testing
```bash
# Unit tests
⌘U

# Run specific test
⌘U (while in test file)

# View device logs
Window → Devices and Simulators → Device Logs

# View console
⌘⇧C (Debug area)

# Filter console
⌘F in console
```

### Device Management
```bash
# List connected devices
xcrun xcode-select -p

# View device logs from terminal
log stream --device --level debug --predicate 'eventMessage contains[c] "leafid"'

# Capture device logs
defaults read com.apple.CoreSimulator.CoreSimulatorService

# Clear device logs
log erase --all
```

### Performance Testing
```bash
# Profile with Instruments
Product → Profile (⌘I)

# Use Time Profiler to find slow code
# Use Memory Graph to find leaks
# Use Network Link Conditioner for slow network
```

---

## Success Criteria

Your testing & debugging setup is solid when:

- ✅ Can see all app logs in Xcode Console while testing on device
- ✅ Every bug has a minimal test case demonstrating it
- ✅ Tests run in under 5 seconds
- ✅ 80%+ code coverage on critical paths (BotanyService, ViewModels)
- ✅ All Sentry errors are triaged within 24 hours
- ✅ Zero "Unhandled exceptions" in Sentry
- ✅ Debug builds run cleanly on device with no compiler warnings
- ✅ Can reproduce any reported issue by following your test case

---

## Next Steps

1. ✅ **Today**: Set up device logging with Logger framework
2. ✅ **This Week**: Add 3-5 critical integration tests
3. ✅ **This Sprint**: Achieve 70%+ test coverage on BotanyService
4. ✅ **Ongoing**: Every bug gets a test case before fix

---

## Resources

- [Apple's Logger Documentation](https://developer.apple.com/documentation/os/logger)
- [XCTest Framework Guide](https://developer.apple.com/documentation/xctest)
- [Sentry iOS Documentation](https://docs.sentry.io/platforms/apple/guides/ios/)
- [Instruments Performance Testing](https://developer.apple.com/instruments/)

---

**Last Updated**: 2026-09-27
**Framework Status**: Ready for implementation
