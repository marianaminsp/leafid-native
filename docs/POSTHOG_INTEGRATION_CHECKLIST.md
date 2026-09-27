# PostHog Analytics Integration Checklist

**Status**: Ready to implement | 5 flows | 13 event tracking points

PostHog is already installed and initialized in `AppMonitoring.swift` and `LeafID_nativeApp.swift`.
This checklist provides exact file locations, line numbers, and ready-to-paste code snippets.

---

## 1. ONBOARDING FLOW

### File: `LeafID-native/Views/Onboarding/OnboardingView.swift`

**Tracking Points:**
- Screen 1 (Cover) viewed
- Screen 2 (How It Works) reached
- Screen 3 (Your Herbarium) reached  
- Screen 4 (Sign-In) reached
- Sign-In initiated with Google

### 1.1: Add PostHog import
**Location:** After `import SwiftUI` (line 10)
```swift
import PostHog
```

### 1.2: Track screen views in `advance()` function
**Location:** Line 60-62, replace the function:
```swift
private func advance() {
    PostHogSDK.shared?.capture("onboarding_screen_advanced", properties: [
        "from_screen": step,
        "to_screen": step + 1,
        "timestamp": Date().timeIntervalSince1970
    ])
    step += 1
}
```

### 1.3: Track sign-in attempt
**Location:** Line 64-73, in `signInWithGoogle()` function, add after line 70 (after `authViewModel.lastError = nil`):
```swift
PostHogSDK.shared?.capture("onboarding_google_signin_initiated", properties: [
    "flow": "onboarding",
    "timestamp": Date().timeIntervalSince1970
])
```

---

## 2. HOME SCREEN SCAN BUTTON

### File: `LeafID-native/Views/Home/HomeView.swift`

**Tracking Points:**
- Camera scan button tapped
- Gallery upload button tapped

### 2.1: Add PostHog import
**Location:** After `import SwiftUI` (line 8)
```swift
import PostHog
```

### 2.2: Track camera scan
**Location:** Line 302, in the scan FAB tap, add immediately AFTER `showCameraPicker = true`:
```swift
PostHogSDK.shared?.capture("scan_initiated", properties: [
    "method": "camera",
    "scans_count": scansCount,
    "is_premium": isPremium,
    "timestamp": Date().timeIntervalSince1970
])
```

### 2.3: Track gallery upload
**Location:** Line 273, in `HomeUploadGalleryButton` action closure, add after `action()`:
```swift
PostHogSDK.shared?.capture("scan_initiated", properties: [
    "method": "gallery",
    "scans_count": scansCount,
    "is_premium": isPremium,
    "timestamp": Date().timeIntervalSince1970
])
```

**OR** (better): Extract to shared function at bottom of HomeView:
```swift
private func trackScanInitiated(method: String) {
    PostHogSDK.shared?.capture("scan_initiated", properties: [
        "method": method,
        "scans_count": scansCount,
        "is_premium": isPremium,
        "timestamp": Date().timeIntervalSince1970
    ])
}
```
Then use: `trackScanInitiated(method: "camera")` and `trackScanInitiated(method: "gallery")`

---

## 3. CARD IMMERSIVE VIEW (Flip & Dismiss)

### File: `LeafID-native/Views/Herbarium/BotanicalCardImmersiveView.swift`

**Tracking Points:**
- Card flipped (front → back)
- Card dismissed/closed
- Card share action

### 3.1: Add PostHog import
**Location:** After other imports
```swift
import PostHog
```

### 3.2: Track card flip
**Location:** Line 250 (in DragGesture handler), replace:
```swift
isFlipped.toggle()
```
With:
```swift
isFlipped.toggle()
PostHogSDK.shared?.capture("card_flipped", properties: [
    "plant_id": specimen.id.uuidString,
    "view": isFlipped ? "back" : "front",
    "flip_method": "gesture",
    "timestamp": Date().timeIntervalSince1970
])
```

### 3.3: Track flip from button (if exists)
**Location:** Line 309 (flip button tap), add same tracking:
```swift
PostHogSDK.shared?.capture("card_flipped", properties: [
    "plant_id": specimen.id.uuidString,
    "view": isFlipped ? "back" : "front",
    "flip_method": "button",
    "timestamp": Date().timeIntervalSince1970
])
```

### 3.4: Track card dismissal
**Location:** Find the close/dismiss action (likely in gesture handler or close button)
Add when dismissing:
```swift
PostHogSDK.shared?.capture("card_dismissed", properties: [
    "plant_id": specimen.id.uuidString,
    "time_viewed_seconds": timeSpentOnCard,  // if available
    "dismissal_method": "gesture", // or "button"
    "timestamp": Date().timeIntervalSince1970
])
```

### 3.5: Track share action (if present)
**Location:** Find share button action, add:
```swift
PostHogSDK.shared?.capture("plant_shared", properties: [
    "plant_id": specimen.id.uuidString,
    "share_method": "system_share", // or "copy_link", "messages"
    "timestamp": Date().timeIntervalSince1970
])
```

---

## 4. HERBARIUM VIEW (Collection & Filters)

### File: `LeafID-native/Views/Herbarium/HerbariumView.swift`

**Tracking Points:**
- Herbarium viewed
- Specimen tapped/selected
- Filter applied (if any)

### 4.1: Add PostHog import
**Location:** After `import SwiftUI` (line 8)
```swift
import PostHog
```

### 4.2: Track herbarium view
**Location:** Add to `body` view, in `.onAppear()` or at top of ZStack:
```swift
.onAppear {
    PostHogSDK.shared?.capture("herbarium_viewed", properties: [
        "total_plants": viewModel.scans.count,
        "timestamp": Date().timeIntervalSince1970
    ])
}
```

### 4.3: Track specimen tap
**Location:** Line 65-67, in the `Button { }` closure, replace:
```swift
Button {
    immersiveUseMatchedGeometry = true
    PostHogSDK.shared?.capture("specimen_selected", properties: [
        "plant_id": scan.id.uuidString,
        "common_name": scan.commonName,
        "timestamp": Date().timeIntervalSince1970
    ])
    withAnimation(.leafIDSpring) { selectedScan = scan }
} label: {
```

### 4.4: Track refresh/hydrate (optional)
**Location:** Line 87-89, in `.refreshable { }` block:
```swift
.refreshable {
    PostHogSDK.shared?.capture("herbarium_refreshed", properties: [
        "timestamp": Date().timeIntervalSince1970
    ])
    await viewModel.hydrateFromSupabase(auth: auth)
}
```

---

## 5. USER PROPERTIES (Set on Login)

### File: `LeafID-native/ViewModels/AuthViewModel.swift` (or wherever login completes)

**Add after successful authentication:**
```swift
PostHogSDK.shared?.identify(userId, userProperties: [
    "email": userEmail,
    "display_name": displayName,
    "total_scans": scansCount,
    "is_premium": isPremium,
    "app_version": Bundle.main.appVersion, // requires extension
    "timestamp": Date().timeIntervalSince1970
])
```

---

## Implementation Order

1. **Add PostHog imports** to each file (5 imports)
2. **Onboarding events** (2 events: advance, sign-in)
3. **Home scan events** (2 events: camera, gallery)
4. **Card immersive events** (3 events: flip, dismiss, share)
5. **Herbarium events** (3 events: view, specimen-select, refresh)
6. **User properties** (1 identify call)

---

## Testing Checklist

- [ ] Build app, run on simulator
- [ ] Navigate through onboarding → check PostHog dashboard for events
- [ ] Scan plant (camera or gallery) → check `scan_initiated` event
- [ ] Open immersive card → check `card_opened` (if added)
- [ ] Flip card → check `card_flipped` event
- [ ] Close card → check `card_dismissed` event
- [ ] Share plant → check `plant_shared` event
- [ ] Open Herbarium → check `herbarium_viewed` event
- [ ] Tap specimen → check `specimen_selected` event
- [ ] Log in → check user properties set in PostHog

---

## PostHog Dashboard Access

- **Cloud**: https://us.posthog.com (or eu.posthog.com)
- **Free tier**: 100k events/month
- **Events visible after**: ~5-10 seconds from capture

---

## Notes

- All events include `timestamp` for chronological tracking
- `plant_id` uses UUID string for correlation across events
- User properties set once on login; subsequent scans auto-tagged
- Gestures vs. buttons tracked separately for UX insights
- Optional: Add "session_id" to all events for session replay correlation

