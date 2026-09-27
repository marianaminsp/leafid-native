# LeafID Icon Library

**Status**: Complete design extraction | 66 custom botanical icons | Ready for integration

## Overview

Custom-designed botanical icon library extracted from vector source files. All icons follow a consistent 100×100 design grid (with some traced variants maintaining original aspect ratios). This is the canonical source for app iconography — replaces generic SF Symbols with branded botanical glyphs.

**Gallery**: See all icons in [Icon Extraction Review](https://claude.ai/code/artifact/f967a90a-dd18-4c00-945b-08fbe1523d41) (66 icons, organized by category)

---

## Icon Categories

### Leaf Family (6 icons)
Primary leaf forms used across navigation and UI.

| Icon ID | Name | Use Case | Notes | Selected |
|---------|------|----------|-------|----------|
| `icon2_0` ⭐ | Maple Leaf | Primary, high detail | 5-pointed, complex vein structure | ✅ Onboarding |
| `icon2_1` ⭐ | Oak Leaf | Simple, versatile | Curved edges, iconic silhouette | ✅ Onboarding |
| `icon2_2` ⭐ | Samara | Winged seed | Seed-pod form | ✅ Onboarding |
| `icon2_3` ⭐ | Aloe | Succulent variant | Thick, structured leaves | ✅ Onboarding |
| `icon2_4` | Monstera | Perforated leaf | Modern botanical | — |
| `icon2_5` | Ivy | Trailing vine | Natural, organic | — |

### Maple & Samara Grid (25 icons)
Comprehensive maple poses, compound-leaf arrangements, seed clusters, buds, and seasonal variations.

| Icon ID | Name | Category | Notes | Selected |
|---------|------|----------|-------|----------|
| `icon3_0` ⭐ | Maple variation | Poses/gestures | Multiple orientations, dynamic angles | ✅ Onboarding |
| `icon3_1` to `icon3_2` | Maple variations | Poses | Additional orientations | — |
| `icon3_3` ⭐ | Maple variation | Poses | Dynamic angle | ✅ Onboarding |
| `icon3_4` to `icon3_13` | Grid variations | Mixed | Compounds, clusters, details | — |
| `icon3_14` ⭐ | Samara/seed cluster | Seeds/flora | Organic arrangement | ✅ Onboarding |
| `icon3_15` to `icon3_18` | Additional variations | Mixed | Fine details, buds | — |

### Other Categories (Traced Variants & Details)
Complex botanical forms traced from reference art.

| Icon ID | Name | Category | Selected |
|---------|------|----------|----------|
| `icon_7` ⭐ | — | Traced variant | ✅ Onboarding |
| `icon_11` ⭐ | — | Complex form | ✅ Onboarding |
| `icon_12` ⭐ | — | Botanical detail | ✅ Onboarding |
| `icon_19` ⭐ | — | Traced variant | ✅ Onboarding |
| `icon_28` ⭐ | — | Complex detail | ✅ Onboarding |
| `icon_29` ⭐ | — | Botanical form | ✅ Onboarding |

**Traced from Reference Art** (using potrace): These icons maintain original aspect ratios and are not square like hand-authored glyphs.

---

## Current Implementation Status

### ✅ Completed
- Icon design & extraction (66 total)
- Gallery documentation
- Integration planning
- **Icon selection for onboarding** (13 icons tagged)

### ⏳ In Progress: Onboarding Integration
**Selected icons (13 total):**
- Leaf Family: `icon2_0`, `icon2_1`, `icon2_2`, `icon2_3`
- Maple Grid: `icon3_0`, `icon3_3`, `icon3_14`
- Other: `icon_7`, `icon_11`, `icon_12`, `icon_19`, `icon_28`, `icon_29`

**Integration path**: OnboardingView screens (cover, beats 1-3, sign-in)

### ⏹️ Deferred: Main App Navigation
Keeping current SF Symbols in:
- Herbarium tab (`"leaf.fill"`)
- Home screen (`"leaf.fill"`)
- Arboretum tab (`"map"`)
- Card flip (`"arrow.triangle.2.circlepath"`)

*Decision: Keep familiar app icons; enhance onboarding with botanical richness*

### Not Yet Designed
- Utility icons (xmark, chevron, share) — use SF Symbols (user expectation)
- Profile/user icons — use SF Symbols (standard)
- Paywall benefit icons — use SF Symbols (generic features)

---

## Onboarding Icon Usage (Selected)

**13 hand-picked icons** to enrich onboarding flow and immerse users in LeafID's botanical identity.

### Leaf Family (4 selected)
- `icon2_0` — Maple Leaf (high detail, complexity)
- `icon2_1` — Oak Leaf (simple, iconic)
- `icon2_2` — Samara (seed/discovery theme)
- `icon2_3` — Aloe (succulent, structure)

**Onboarding placement ideas:**
- Cover screen (Screen 1): Rotate through Leaf Family variants
- "How It Works" (Screen 2): Feature one iconic leaf
- "Your Herbarium" (Screen 3): Showcase samara/seed theme
- Sign-in (Screen 4): Display structured form (aloe)

### Maple & Samara Grid (3 selected)
- `icon3_0` — Maple variation (organic, flowing)
- `icon3_3` — Maple variation (dynamic angle)
- `icon3_14` — Samara/seed cluster (organic arrangement)

**Placement:** Accent elements, transitions, decorative backgrounds

### Other Traced Variants (6 selected)
- `icon_7`, `icon_11`, `icon_12`, `icon_19`, `icon_28`, `icon_29`

**Placement:** Fine details, corner accents, botanical richness in backgrounds

### Design Approach
- **Rotate through 2-3 variants** on each screen to show botanical diversity
- **Use as decorative accents** (corners, transitions) to reinforce brand
- **Size range**: 16-48pt depending on context
- **Color**: Primary green (#93BC10) with occasional opacity variations

---

## Integration Notes

### SVG Format
All icons are SVG paths embedded in the gallery artifact. Before wiring into Swift code, icons need to be:
1. Extracted as `.svg` files or
2. Converted to SwiftUI `Shape` code (Path builders), or
3. Stored as `.pdf` vector assets in Xcode

### Naming Convention
Use descriptive names when adding to codebase:
- `herbariumTabIcon` (for Herbarium tab)
- `herbariumTabIcon_alt` (for alternate design)
- `homeLeafHero` (for home screen feature)
- `cardFlipIcon` (for interaction button)

### Design Grid
- **Hand-authored glyphs**: 100×100 square (except as noted)
- **Traced glyphs**: Original aspect ratio preserved
- **Line weight**: Consistent stroke width across family
- **Style**: Stroke-based silhouette, minimal detail

---

## How to Use (When Integration Starts)

### Option A: SwiftUI Paths (Recommended)
Convert SVG paths to SwiftUI `Shape` structs, similar to existing `LeafIDIcon.swift`:

```swift
struct HerbariumTabIcon: Shape {
    func path(in rect: CGRect) -> Path {
        // SVG path converted to SwiftUI Path
    }
}

// Usage:
HerbariumTabIcon()
    .fill(Color.green)
    .frame(width: 24, height: 24)
```

### Option B: PDF Vector Assets
1. Save SVG as PDF in Xcode Assets
2. Reference as `Image("HerbariumTabIcon")`
3. Simplest integration, less customization

### Option C: Custom Icon Component
Extend or replace `LeafIDIcon.swift` to include all 66 glyphs:

```swift
enum LeafIDIcon.Kind {
    case mapleLead, oakLeaf, samara, aloe, monstera, ivy
    case mapleGrid0, mapleGrid1, /* ... 25 more variations ... */
    // etc.
}
```

---

## Figma/Design Source

All icons extracted from vector design source. If original files are available:
- **Location**: [Design source file path — to be documented]
- **Last updated**: [Date of extraction]
- **Tool**: potrace (for traced variants)

---

## Next Steps

1. **Review** — User selects which icons to use for primary navigation (Herbarium, Home, Arboretum, Card flip)
2. **Extract** — Convert selected SVG icons to Swift code or PDF assets
3. **Integrate** — Wire into MainTabView, HomeView, BotanicalCardImmersiveView, etc.
4. **Test** — Verify icons display correctly at all sizes
5. **Polish** — Adjust colors, weights, sizes based on runtime appearance

---

## References

- Icon Gallery: https://claude.ai/code/artifact/f967a90a-dd18-4c00-945b-08fbe1523d41
- LeafID Design System: `docs/DESIGN_SYSTEM.md` (when created)
- Related: `LeafID-native/UI/System/LeafIDIcons.swift` (existing icon component)

