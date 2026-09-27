# Testing Quick Start Guide 🚀

5-minute setup for solid device testing with Xcode.

## Today: First 5 Minutes

### 1. Connect Your Device (1 min)
```bash
# Plug in iPhone/iPad via USB
# On device: Settings → General → Trust [Your Computer]
# In Xcode: Product → Run (⌘R)
```

### 2. See Console Logs (1 min)
```
Xcode: ⌘⇧C
Logs appear in real-time while you test
⌘F to search/filter
```

### 3. Start Using AppLogger (2 min)

Instead of `print("something")`, use:

```swift
// At top of file:
import AppLogger  // (once you import the Services)

// In your code:
AppLog.plantIdentified(species: "Alocasia", confidence: 0.95)
AppLog.networkError(error, endpoint: "/api/identify")
AppLog.userAction("Tapped camera button")
```

### 4. Run a Test (1 min)
```
Xcode: ⌘U
Tests run, results appear in navigator
All tests should pass ✅
```

---

## This Week: Expand Testing

### Task 1: Add 3 Integration Tests
Copy this pattern into `LeafID_nativeTests.swift`:

```swift
// MARK: - New Integration Tests

func testIdentifyPlantWithValidImage() async throws {
    let service = BotanyService()
    let testImage = UIImage(named: "test-leaf")!
    
    let result = try await service.identifyPlant(image: testImage)
    
    XCTAssertNotNil(result)
    XCTAssertGreater(result.confidence, 0)
}

func testLoadPlantDetailsReturnsValidPlant() async throws {
    let service = BotanyService()
    
    let plant = try await service.loadPlantDetails(id: "test-123")
    
    XCTAssertNotNil(plant.id)
    XCTAssertNotNil(plant.species)
}

func testNetworkErrorIsHandledGracefully() async {
    let service = BotanyService()
    
    // Force network error (disconnect network, or mock)
    let result = await service.identifyPlant(image: invalidImage)
    
    XCTAssertNil(result)
}
```

### Task 2: Add Logging to Key Functions

Find 3 important functions and add logging:

```swift
// Before
func identifyPlant(image: UIImage) async {
    let result = await api.post("/identify", body: image)
    return result
}

// After
func identifyPlant(image: UIImage) async {
    AppLog.identifyingPlant(fromImage: "user-photo")
    let result = await api.post("/identify", body: image)
    AppLog.plantIdentified(species: result.species, confidence: result.confidence)
    return result
}
```

---

## Daily Testing Workflow

### Morning: Prepare Device
```bash
# 1. Connect iPhone via USB
# 2. Unlock device
# 3. In Xcode: Product → Run (⌘R)
# 4. Open Console: ⌘⇧C
```

### During Testing: Monitor & Report

1. **Test Feature**: Go through user flow normally
2. **Watch Console**: ⌘⇧C shows all logs
3. **Found Bug?**: 
   - Note the exact steps
   - Copy console logs (⌘A, ⌘C)
   - Create a test case to reproduce it

### When Bug Found: Create Test Case

```swift
func testBugXXX_PlantNameNotDisplaying() {
    let plant = Plant(name: "", species: "Alocasia")
    
    let displayName = plant.displayName
    
    XCTAssertNotNil(displayName)  // This fails with current bug
    XCTAssertFalse(displayName.isEmpty)
}
```

Then run: ⌘U
Test fails ✅ (shows bug exists)

Fix the bug in code.

Run: ⌘U again
Test passes ✅ (bug is fixed)

---

## Console Filtering Cheat Sheet

Open Console: **⌘⇧C**

Then use **⌘F** to filter:

| Filter | Shows |
|--------|-------|
| `category:"botany"` | All plant identification logs |
| `category:"network"` | All network requests/responses |
| `level:error` | Only errors |
| `"plant identification failed"` | Search text |
| `category:"botany" level:error` | Errors in botany |

---

## Commands You'll Use Daily

| Action | Shortcut |
|--------|----------|
| Run app on device | ⌘R |
| Run all tests | ⌘U |
| Open/Focus console | ⌘⇧C |
| Search console | ⌘F (when console focused) |
| Stop running app | ⌘. |
| View device logs | Window → Devices and Simulators |
| Profile performance | ⌘I |

---

## Common Issues & Solutions

### Issue: Can't see logs in console
**Solution**: 
- Make sure Console is open: ⌘⇧C
- Check device is connected (top-left dropdown shows device name)
- Try: Product → Stop, then ⌘R again

### Issue: Tests fail but work on device
**Solution**:
- Tests use mock data, device uses real API
- Add both: unit tests (fast, use mocks) + integration tests (slow, use real API)

### Issue: Can't connect device
**Solution**:
- Try: Unpair device (Devices & Simulators → device → ⓧ)
- Unplug USB, plug back in
- Restart Xcode

---

## Success Check ✅

You're ready when you can:

- [ ] Run app on device and see Console logs
- [ ] Filter logs in Console to find specific messages
- [ ] Run all tests with ⌘U (under 10 seconds)
- [ ] Find a bug and write a test case for it
- [ ] Fix the bug and verify test passes

---

## Next: Full Framework

Once this works smoothly, read:
→ `TESTING_AND_DEBUGGING.md` for comprehensive guide

---

**Framework Version**: 1.0
**Last Updated**: 2026-09-27
