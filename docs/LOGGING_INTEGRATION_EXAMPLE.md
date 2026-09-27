# Logging Integration Example

Shows how to integrate `AppLogger` into existing services for better debugging visibility.

## Quick Example: Before vs After

### Before (No Logging)
```swift
// BotanyService.swift
func identifyPlant(image: UIImage) async -> PlantIdentification? {
    do {
        let response = try await api.post("/identify", with: image)
        return PlantIdentification(from: response)
    } catch {
        return nil  // Silent failure - hard to debug
    }
}
```

**Problem**: If this fails, you don't know why. Console shows nothing. Xcode can't help you.

### After (With AppLogger)
```swift
// BotanyService.swift
func identifyPlant(image: UIImage) async -> PlantIdentification? {
    AppLog.identifyingPlant(fromImage: "camera-capture")
    
    do {
        let response = try await api.post("/identify", with: image)
        let plant = PlantIdentification(from: response)
        
        AppLog.plantIdentified(species: plant.species, confidence: plant.confidence)
        
        return plant
    } catch {
        AppLog.plantIdentificationFailed(error)
        return nil
    }
}
```

**Benefit**: Now when testing:
- Console shows exactly where the flow is
- If it fails, you see the error immediately
- You can filter: `category:"botany"` to see only plant logs
- You can see performance: request timing, confidence scores

---

## Step-by-Step Integration

### Step 1: Make AppLogger Accessible

Currently `AppLogger.swift` is in `Services/`. You need to either:

**Option A**: Import in each file
```swift
import Foundation
// Add other imports...
// AppLogger is available because it's in the same target

// Use it directly:
AppLog.plantIdentified(species: "Alocasia", confidence: 0.95)
```

**Option B**: Create a public module (advanced)
```swift
// In AppLogger.swift, make sure these are accessible:
public let botanyLogger = Logger(subsystem: "com.leafid.native", category: "botany")
public enum AppLog { ... }
```

### Step 2: Add Logging to One Service

Pick one service (e.g., `BotanyService.swift`) and add logging:

#### Example: BotanyService

```swift
// LeafID-native/Services/BotanyService.swift

import Foundation
// ... other imports

class BotanyService {
    
    // MARK: - Plant Identification
    
    func identifyPlant(image: UIImage) async -> PlantIdentification? {
        AppLog.identifyingPlant(fromImage: "camera-capture")
        
        do {
            let imageData = image.jpegData(compressionQuality: 0.8)!
            
            AppLog.networkRequest(method: "POST", endpoint: "/api/v1/identify")
            let startTime = Date()
            
            let response = try await api.post(
                "/api/v1/identify",
                with: imageData
            )
            
            let duration = Date().timeIntervalSince(startTime) * 1000
            AppLog.networkResponse(statusCode: 200, duration: duration)
            
            let plant = PlantIdentification(from: response)
            AppLog.plantIdentified(
                species: plant.species,
                confidence: plant.confidence
            )
            
            return plant
            
        } catch let error as NetworkError {
            let duration = Date().timeIntervalSince(startTime) * 1000
            if duration > 5000 {
                AppLog.slowNetworkResponse(duration: duration, endpoint: "/api/v1/identify")
            }
            AppLog.networkError(error, endpoint: "/api/v1/identify")
            AppLog.plantIdentificationFailed(error)
            return nil
            
        } catch {
            AppLog.plantIdentificationFailed(error)
            return nil
        }
    }
    
    // MARK: - Load Plant Details
    
    func loadPlantDetails(id: String) async -> Plant? {
        AppLog.loadingPlantDetails(id: id)
        
        do {
            AppLog.networkRequest(method: "GET", endpoint: "/api/v1/plants/\(id)")
            let startTime = Date()
            
            let response = try await api.get("/api/v1/plants/\(id)")
            
            let duration = Date().timeIntervalSince(startTime) * 1000
            AppLog.networkResponse(statusCode: 200, duration: duration)
            
            let plant = Plant(from: response)
            AppLog.debug("Plant details loaded: \(plant.commonName)")
            
            return plant
            
        } catch {
            AppLog.networkError(error, endpoint: "/api/v1/plants/\(id)")
            return nil
        }
    }
}
```

#### Example: NetworkService

```swift
// LeafID-native/Services/NetworkService.swift

class NetworkService {
    
    func get(_ endpoint: String) async throws -> Data {
        AppLog.networkRequest(method: "GET", endpoint: endpoint)
        
        let startTime = Date()
        let (data, response) = try await URLSession.shared.data(from: url)
        let duration = Date().timeIntervalSince(startTime) * 1000
        
        if let httpResponse = response as? HTTPURLResponse {
            AppLog.networkResponse(statusCode: httpResponse.statusCode, duration: duration)
            
            if duration > 3000 {
                AppLog.slowNetworkResponse(duration: duration, endpoint: endpoint)
            }
        }
        
        return data
    }
}
```

#### Example: AuthViewModel

```swift
// LeafID-native/ViewModels/AuthViewModel.swift

@MainActor
class AuthViewModel: ObservableObject {
    
    @Published var isLoggedIn = false
    @Published var errorMessage: String?
    
    func login(email: String, password: String) async {
        AppLog.debug("Login attempt for: \(email)")
        
        do {
            let user = try await authService.login(email: email, password: password)
            AppLog.userLoggedIn(userID: user.id)
            self.isLoggedIn = true
            
        } catch let error as AuthError {
            AppLog.authenticationFailed(error)
            self.errorMessage = error.userMessage
        }
    }
    
    func logout() {
        AppLog.userLoggedOut()
        authService.logout()
        isLoggedIn = false
    }
}
```

### Step 3: Test the Logging

1. **Build and run app on device**
   ```
   ⌘R
   ```

2. **Open Console**
   ```
   ⌘⇧C
   ```

3. **Go through the feature**
   - Tap "Camera"
   - Take photo
   - Wait for identification
   - View results

4. **Watch Console**
   You should see logs like:
   ```
   🌿 Identifying plant from image: camera-capture
   🌐 POST /api/v1/identify
   ✓ Response: 200 (1523.5ms)
   ✅ Plant identified: Alocasia (confidence: 94.5%)
   ```

5. **Filter logs**
   - Press ⌘F in console
   - Type: `category:"botany"`
   - Should show only botany-related logs

### Step 4: Monitor Performance

Now you can see which operations are slow:

```
⚠️ Slow response: 4523ms for /api/v1/identify
```

This tells you:
- The API took 4.5 seconds (might be slow network)
- You know which endpoint is slow
- Can optimize: compression, caching, etc.

---

## Common Logging Patterns

### Pattern 1: Request/Response Timing

```swift
let startTime = Date()

// ... do work ...

let duration = Date().timeIntervalSince(startTime) * 1000
AppLog.networkResponse(statusCode: 200, duration: duration)
```

### Pattern 2: Error Context

```swift
do {
    try riskyOperation()
} catch {
    AppLog.error("Operation failed: \(error.localizedDescription)", 
                 file: #file, line: #line)
    // Handle error
}
```

### Pattern 3: State Changes

```swift
if userProfile.isFirstTime {
    AppLog.debug("First time user detected")
    // Show onboarding
}

AppLog.userAction("Navigated to plant detail")
```

### Pattern 4: Conditional Logging

```swift
// Only log in debug builds
#if DEBUG
AppLog.debug("AuthToken: \(authToken)")  // Don't log secrets in release!
#endif
```

---

## Console Filtering Patterns

Use **⌘F** in Console to filter:

### By Category
```
category:"botany"          # Only plant logs
category:"network"         # Only network logs
category:"auth"           # Only auth logs
```

### By Level
```
level:error               # Only errors
level:warning             # Only warnings
level:info                # Info and higher
```

### By Text
```
"Alocasia"               # Search text
"failed"                 # Search substring
```

### Combinations
```
category:"botany" level:error     # Errors in botany
category:"network" "failed"       # Network failures
```

---

## What to Log vs What Not to Log

### ✅ DO Log

- Function entry points (start of important flows)
- API requests and responses
- User actions (button taps, navigation)
- Errors with context
- Performance metrics (timing, sizes)
- State changes (login, logout, data loaded)

### ❌ DON'T Log

- Passwords or authentication tokens
- Full user data (emails, addresses)
- Large data objects (entire responses)
- Loops/repeated operations
- Debug variable values (use breakpoints instead)
- Secrets from config files

### 🤔 BE CAREFUL

```swift
// Bad: Logging sensitive data
AppLog.debug("User credentials: \(password)")

// Good: Log that login happened
AppLog.userLoggedIn(userID: userID)

// Bad: Logging huge objects
AppLog.debug("Full response: \(entireAPIResponse)")

// Good: Logging summary
AppLog.plantIdentified(species: plant.species, confidence: 0.95)
```

---

## Benefits in Action

### Scenario 1: Plant Identification Fails

**With Logging**:
```
🌿 Identifying plant from image: camera-capture
🌐 POST /api/v1/identify
❌ Network error for /api/v1/identify: timeout
❌ Plant identification failed: timeout
```

**You immediately know**: Network call timed out.

**Without Logging**:
```
// Nothing - silent failure
// You have no idea what went wrong
```

### Scenario 2: Performance Issues

**With Logging**:
```
🌐 POST /api/v1/identify
✓ Response: 200 (4523.0ms)
⚠️ Slow response: 4523ms for /api/v1/identify
```

**You can see**: API response took 4.5 seconds (slow!)

**Without Logging**:
```
// App feels slow but you don't know why
// Could be network, could be processing
```

### Scenario 3: Crash Debugging

**With Logging**:
```
👤 User logged in: user-123
🌿 Identifying plant from image: camera-capture
🌐 POST /api/v1/identify
// ... app crashes ...
```

**You know**: Crash happened right after network request.

**Without Logging**:
```
// App crashed, no clue where in the flow
```

---

## Integration Checklist

- [ ] Import/access AppLogger in your service
- [ ] Add logging to 3-5 key functions
- [ ] Test: Run app on device (⌘R)
- [ ] Watch Console: ⌘⇧C
- [ ] Filter logs: ⌘F in console
- [ ] Verify: Logs appear as expected
- [ ] Commit code with logging added

---

## Next Steps

1. ✅ Integrate AppLogger into BotanyService
2. ✅ Integrate into NetworkService
3. ✅ Integrate into AuthViewModel
4. ✅ Add logging to 2-3 more critical services
5. ✅ Create tests that verify correct logging occurs

---

**Framework Version**: 1.0
**Last Updated**: 2026-09-27
