# LeafID Icon Library

**Status**: Complete design extraction | 66 custom botanical icons | Ready for integration

## Overview

Custom-designed botanical icon library extracted from vector source files. All icons follow a consistent 100×100 design grid (with some traced variants maintaining original aspect ratios). This is the canonical source for app iconography — replaces generic SF Symbols with branded botanical glyphs.

**Gallery**: See all icons in [Icon Extraction Review](https://claude.ai/code/artifact/f967a90a-dd18-4c00-945b-08fbe1523d41) (66 icons, organized by category)

---

## Icon Categories

### Leaf Family (6 icons)
Primary leaf forms used across navigation and UI.

| Icon ID | Name | Use Case | Notes |
|---------|------|----------|-------|
| `icon2_0` | Maple Leaf | Primary, high detail | 5-pointed, complex vein structure |
| `icon2_1` | Oak Leaf | Simple, versatile | Curved edges, iconic silhouette |
| `icon2_2` | Samara | Winged seed | Seed-pod form |
| `icon2_3` | Aloe | Succulent variant | Thick, structured leaves |
| `icon2_4` | Monstera | Perforated leaf | Modern botanical |
| `icon2_5` | Ivy | Trailing vine | Natural, organic |

### Maple & Samara Grid (25 icons)
Comprehensive maple poses, compound-leaf arrangements, seed clusters, buds, and seasonal variations.

| Icon ID | Name | Category | Notes |
|---------|------|----------|-------|
| `icon3_0` to `icon3_18` | Maple variations | Poses/gestures | Multiple orientations, dynamic angles |
| (Various) | Ash-compound leaves | Structural | Natural branching |
| (Various) | Samara clusters | Seeds/flora | Organic scattering |
| (Various) | Buds & stems | Details | Spring/growth theme |

**Traced from Reference Art** (using potrace): These icons maintain original aspect ratios and are not square like hand-authored glyphs.

---

## Current Implementation Status

### ✅ Completed
- Icon design & extraction (66 total)
- Gallery documentation
- Integration planning

### ⏳ Ready to Wire Up
- [ ] Herbarium tab icon
- [ ] Home screen leaf icon
- [ ] Arboretum tab icon
- [ ] Card flip/interaction icon
- [ ] Additional decorative/contextual icons

### Not Yet Designed
- Utility icons (xmark, chevron, share) — use SF Symbols (user expectation)
- Profile/user icons — use SF Symbols (standard)
- Paywall benefit icons — use SF Symbols (generic features)

---

## Recommended Replacements

Priority order for integration (visual impact first):

### 🔴 HIGH IMPACT (Featured Navigation)
1. **Herbarium Tab** → Leaf Family icon (likely `icon2_0` or `icon2_1`)
2. **Home Screen Hero** → Leaf Family icon (likely `icon2_1` or `icon2_0`)

### 🟡 MEDIUM IMPACT (Navigation Tabs)
3. **Arboretum Tab** → Tree/plant variation (from Maple Grid)
4. **Card Flip Button** → Samara/seed icon (from Leaf Family or Grid)

### ⚪ LOW IMPACT (Decorative)
5. **Background accents** → Traced leaf sprays (complex detail)
6. **Botanical variety** → Mixed icons for contextual richness

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

