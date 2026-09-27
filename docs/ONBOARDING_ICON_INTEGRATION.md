# Onboarding Icon Integration Plan

**13 selected custom icons** wired into 4-screen onboarding flow for botanical immersion.

---

## Selected Icons Inventory

| Category | IDs | Count | Strategy |
|----------|-----|-------|----------|
| Leaf Family | icon2_0, icon2_1, icon2_2, icon2_3 | 4 | Rotating primary (screen-by-screen) |
| Maple Grid | icon3_0, icon3_3, icon3_14 | 3 | Dynamic accents (transitions) |
| Other | icon_7, icon_11, icon_12, icon_19, icon_28, icon_29 | 6 | Background decorative (corners/edges) |

---

## Screen-by-Screen Placement Strategy

### Screen 0: Cover (Animated intro)
**Primary icon**: Rotating Leaf Family
- **Hero position**: Circle overlay (already `LeafIDIcon(kind: .mapleLeaf)` ✓)
- **Enhancement**: Cycle through icon2_0 → icon2_1 → icon2_3 on each headline beat
- **Accent corner**: icon_7 (top-right, low opacity 0.3, 24pt)
- **Animation**: Fade + subtle scale on headline transition

**Code structure**:
```swift
private struct OnboardingCoverScreen: View {
    @State private var heroIconKind: LeafIDIcon.Kind = .mapleLeaf
    
    // On headline transition:
    private let heroIconSequence: [LeafIDIcon.Kind] = [
        .mapleLeaf,    // beat 0
        .oakLeaf,      // beat 1  
        .aloe          // beat 2
    ]
    
    // On headline change, update heroIconKind
    // Accent corner: icon_7 (requires SVG path in LeafIDIcons)
}
```

**Files to update**:
- `LeafID-native/Views/Onboarding/OnboardingView.swift` → OnboardingCoverScreen (lines 78-156)
- `LeafID-native/UI/System/LeafIDIcons.swift` → Add 13 new icon paths

---

### Screen 1: "How It Works" Beat
**Primary**: Samara (icon2_2) — discovery theme
- **Hero top**: icon2_2 in 48pt circle frame, green background tint
- **Left accent**: icon3_0 (20pt, opacity 0.4, vertical offset -8pt from middle)
- **Right accent**: icon_11 (20pt, opacity 0.4, vertical offset +8pt from middle)

**Code structure**:
```swift
private struct OnboardingBeatScreen: View {
    let iconSymbol: LeafIDIcon.Kind  // Pass from parent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Icon hero (top)
            ZStack {
                Circle().fill(LeafIDTheme.primary.opacity(0.15))
                LeafIDIcon(kind: iconSymbol, style: .filled, size: 48, color: LeafIDTheme.primary)
            }
            .frame(width: 80, height: 80)
            .padding(.bottom, LeafIDTheme.space20)
            
            // Content center
            OnboardingEyebrow(eyebrow)
            LeafIDTypography.displayTitle(headline)
            Text(bodyText)
            
            Spacer()
            
            // Side accents
            HStack {
                LeafIDIcon(kind: .mapleLeafVariant1, size: 20, color: LeafIDTheme.primary.opacity(0.4))
                    .offset(y: -8)
                Spacer()
                LeafIDIcon(kind: .tracedVariant11, size: 20, color: LeafIDTheme.primary.opacity(0.4))
                    .offset(y: 8)
            }
            .padding(.bottom, LeafIDTheme.space20)
        }
    }
}
```

**Files to update**:
- `LeafID-native/Views/Onboarding/OnboardingView.swift` → OnboardingBeatScreen (lines 160-210)
- Pass `icon2_2` for Screen 1

---

### Screen 2: "Your Herbarium" Beat
**Primary**: Samara cluster (icon3_14) — collection/archive theme
- **Hero top**: icon3_14 in 56pt frame (larger, emphasizes abundance)
- **Left accent**: icon_12 (20pt, opacity 0.3, angled)
- **Right accent**: icon_19 (20pt, opacity 0.3, mirrored)

**Code**: Same component as Screen 1, pass different icon

---

### Screen 3: Sign-In Screen
**Primary**: Structured leaf (icon2_3 Aloe) — growth/progression theme
- **Above headline**: icon2_3 (40pt, centered, primary color)
- **Bottom corners**: icon_28 (16pt, opacity 0.2) + icon_29 (16pt, opacity 0.2)
- **Behind rank circle**: Subtle icon_7 glow (60pt, opacity 0.08)

**Code structure**:
```swift
private struct OnboardingSignInScreen: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero icon
            LeafIDIcon(kind: .aloe, style: .filled, size: 40, color: LeafIDTheme.primary)
                .padding(.bottom, LeafIDTheme.space16)
            
            OnboardingEyebrow(String(localized: "THE PATH"))
            Text(String(localized: "Wandering Seed to Archdruid."))
            
            // Background glow (low opacity accent)
            ZStack(alignment: .center) {
                LeafIDIcon(kind: .tracedVariant7, size: 60, color: LeafIDTheme.primary.opacity(0.08))
                HStack(spacing: LeafIDTheme.space10) {
                    Circle().fill(LeafIDTheme.primary).frame(width: 8, height: 8)
                    Text("Archdruid")
                }
            }
            
            Spacer()
            
            // Bottom corner accents
            HStack {
                LeafIDIcon(kind: .tracedVariant28, size: 16, color: LeafIDTheme.primary.opacity(0.2))
                Spacer()
                LeafIDIcon(kind: .tracedVariant29, size: 16, color: LeafIDTheme.primary.opacity(0.2))
            }
            .padding(.bottom, LeafIDTheme.space20)
            
            VStack(spacing: LeafIDTheme.space10) {
                LeafPrimaryButton(title: String(localized: "Continue with Google"), useSolidPrimaryFill: true, action: onContinueWithGoogle)
                OnboardingGhostButton(title: String(localized: "Not now"), action: onNotNow)
            }
        }
    }
}
```

**Files to update**:
- `LeafID-native/Views/Onboarding/OnboardingView.swift` → OnboardingSignInScreen (lines 214-267)

---

## Icon Component Updates Required

### 1. LeafIDIcons.swift — Add 13 New Icons

**New Kind enum cases**:
```swift
enum LeafIDIcon.Kind {
    // Existing
    case mapleLeaf, oakLeaf, acorn, pinecone, berry, flower, tree, sprout
    
    // NEW: Leaf Family (4)
    case samara          // icon2_2
    case aloe            // icon2_3
    
    // NEW: Maple Grid (3)
    case mapleLeafVariant1   // icon3_0
    case mapleLeafVariant2   // icon3_3
    case samaraCluster       // icon3_14
    
    // NEW: Traced Variants (6)
    case tracedVariant7, tracedVariant11, tracedVariant12
    case tracedVariant19, tracedVariant28, tracedVariant29
}
```

**Path builders** (extract SVG paths from gallery artifact):
```swift
private enum LeafIDGlyphPaths {
    // existing paths...
    
    // ICON2_2: Samara (winged seed)
    static func samara(_ rect: CGRect) -> Path {
        var path = Path()
        // SVG path data converted to SwiftUI Path
        // [Extract from gallery artifact icon2_2]
        return path
    }
    
    // ICON2_3: Aloe
    static func aloe(_ rect: CGRect) -> Path { /*...*/ }
    
    // ICON3_0: Maple variant 1
    static func mapleLeafVariant1(_ rect: CGRect) -> Path { /*...*/ }
    
    // etc. for all 13 icons
}
```

**mainBuilder mapping**:
```swift
private var mainBuilder: (CGRect) -> Path {
    switch kind {
    case .mapleLeaf: return LeafIDGlyphPaths.mapleLeaf
    case .oakLeaf: return LeafIDGlyphPaths.oakLeaf
    // existing...
    case .samara: return LeafIDGlyphPaths.samara
    case .aloe: return LeafIDGlyphPaths.aloe
    case .mapleLeafVariant1: return LeafIDGlyphPaths.mapleLeafVariant1
    // ... 10 more
    }
}
```

---

## Implementation Sequence

1. **Extract SVG paths** from icon gallery (`icon2_2`, `icon2_3`, `icon3_0`, `icon3_3`, `icon3_14`, `icon_7`, `icon_11`, `icon_12`, `icon_19`, `icon_28`, `icon_29`)
   - Convert each SVG → SwiftUI Path builder
   - Add to LeafIDIcons.swift

2. **Update LeafIDIcon.Kind enum** with 13 new cases (see above)

3. **Update OnboardingCoverScreen**
   - Add `heroIconSequence` state
   - Cycle icon on each headline beat
   - Add top-right accent (icon_7)

4. **Update OnboardingBeatScreen** (generic, reusable)
   - Accept `iconSymbol` parameter
   - Place hero icon (48-56pt)
   - Add left/right accents

5. **Update OnboardingSignInScreen**
   - Hero icon (40pt, centered)
   - Background glow accent
   - Bottom corner accents

6. **Pass icons to screens** from OnboardingView parent:
   - Screen 0 (Cover): Self-managed rotation
   - Screen 1 (Beat 1): Pass `icon2_2` (Samara)
   - Screen 2 (Beat 2): Pass `icon3_14` (Samara cluster)
   - Screen 3 (SignIn): Self-managed multiple icons

---

## Code Files to Modify

| File | Lines | Changes |
|------|-------|---------|
| LeafIDIcons.swift | New paths | Add 13 icon path builders |
| LeafIDIcons.swift | enum Kind | Add 13 cases |
| LeafIDIcons.swift | mainBuilder | Add 13 mappings |
| OnboardingView.swift | 78-156 | OnboardingCoverScreen → rotating hero icon + top-right accent |
| OnboardingView.swift | 160-210 | OnboardingBeatScreen → add icon parameter + hero frame + side accents |
| OnboardingView.swift | 214-267 | OnboardingSignInScreen → hero icon + background glow + corner accents |
| OnboardingView.swift | 26 | Pass `icon2_2` to Screen 1 |
| OnboardingView.swift | 37 | Pass `icon3_14` to Screen 2 |

---

## Design Specs

### Sizing
- **Hero icons** (Cover, Beat screens): 48-56pt
- **Accent icons** (side/corner): 16-24pt
- **Background glow**: 60pt

### Colors
- **Filled primary**: `LeafIDTheme.primary` (#93BC10)
- **Accents**: `.opacity(0.2–0.4)` depending on prominence
- **Background glow**: `.opacity(0.08)` (subtle)

### Animation
- **Hero rotation** (Cover): Fade + 0.52s easeInOut on headline change
- **Accents**: Static (no animation, clean)
- **Screen transition**: Existing `.asymmetric` (no change)

---

## Next Steps: Execution Checklist

- [ ] Extract all 13 SVG paths from icon gallery artifact
- [ ] Convert to SwiftUI Path builders
- [ ] Update LeafIDIcons.swift (enum + paths)
- [ ] Modify OnboardingCoverScreen (rotating hero + accent)
- [ ] Modify OnboardingBeatScreen (parameter + hero + accents)
- [ ] Modify OnboardingSignInScreen (hero + glow + corners)
- [ ] Test on device (all 4 screens, rotations, transitions)
- [ ] Commit: "Wire 13 custom icons into onboarding screens"

---

## Notes
- SVG extraction: Each icon's SVG path data must be hand-converted or use an SVG→SwiftUI Path tool
- Color consistency: All icons use `LeafIDTheme.primary` per design tokens
- No new component files needed: Inline in existing OnboardingView.swift (keep simple)
- Backwards compatible: No changes to main app navigation icons
