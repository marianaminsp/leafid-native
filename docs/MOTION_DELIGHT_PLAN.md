# LeafID Motion & Delight Plan

Status: proposal, not yet implemented. Written 2026-08-07. References existing code as last verified earlier in this session (`MainTabView`'s `FloatingLiquidTabBar`, `HerbariumView`'s `specimenNamespace`/`matchedGeometryEffect` wiring to `BotanicalCardImmersiveView`, the card's `isFlipped` state, `ScanResultsView`'s save flow, the existing `.leafIDSpring` token) — re-verify line numbers before implementing if the codebase has moved on.

---

## Part 1 — Motion & Delight Plan (Animation & UX Strategy)

### Animation principles, translated to SwiftUI

Springs, not bezier curves, are the default in this app. `matchedGeometryEffect`, drag-to-dismiss, and tab switches all benefit from a spring's ability to absorb interruption/velocity, which a fixed-duration curve can't do.

| Purpose | When | Token | Why |
|---|---|---|---|
| **Tap** (responsiveness) | Button press, toggle, chip select | `.spring(response: 0.28, dampingFraction: 0.86)` | Fast, no overshoot — a control should feel *pressed*, not *bouncy* |
| **Reveal** (enter/exit) | Sheet, toast, cover appearing | Enter: `.spring(response: 0.45, dampingFraction: 0.88)` · Exit: `.spring(response: 0.22, dampingFraction: 0.9)` | Exits read as abrupt-but-clean; users want dismissed content *gone*, not lingering |
| **Flow** (spatial continuity) | matchedGeometryEffect — row → immersive card, tab switch | `.spring(response: 0.55, dampingFraction: 0.82, blendDuration: 0.2)` | Slower response for bigger on-screen jumps; too stiff a spring over a long distance reads as robotic, not fluid |
| **Flip** | Botanical Card front↔back | `.spring(response: 0.5, dampingFraction: 0.75)` | Deliberately a *touch* of overshoot — a mechanical card-flip has real inertia; zero bounce feels flat/digital |
| **Drag** | `immersiveDismissDrag`, any finger-tracked gesture | `.interactiveSpring(response: 0.3, dampingFraction: 0.86)` | Must track velocity/finger position exactly — a fixed-duration animation here reads as laggy no matter how fast |
| **Ambient/loading** | Scanning reticle, "AI thinking" pulse | `.easeInOut(duration: 1.2).repeatForever(autoreverses: true)` | Breathing, not mechanical — this is the one place a plain ease curve outperforms a spring |

**Consolidate into one vocabulary.** `HerbariumView.swift` already references `.leafIDSpring` — good precedent. Extend it into a small `LeafIDMotion` enum (`Theme.swift` or a new `Motion+LeafID.swift`) with named cases matching the table above (`.tap`, `.reveal`, `.flow`, `.flip`, `.drag`), so every screen pulls from the same 5-6 constants instead of ad-hoc magic numbers per view. This is the single highest-leverage change for "coherent movement across the app" — inconsistency usually comes from five different engineers' idea of "a spring," not from any one animation being wrong in isolation.

**Guardrails:**
- Never mix families on one gesture — don't spring the scale while easing the opacity of the same transition.
- Respect `UIAccessibility.isReduceMotionEnabled` everywhere `matchedGeometryEffect` or the 3D flip fires — cross-fade fallback, not "just disable the whole interaction."
- Exits are always faster than enters. If a dismiss animation and its matching present animation share a duration, the dismiss is wrong.

### Micro-interactions worth adding

| Moment | Trigger | Haptic | Motion |
|---|---|---|---|
| Shutter tap (ScannerView) | Press-down, not release | `.impactOccurred(.medium)` on touch-down | Instant scale-pop, camera-shutter convention |
| Save to Herbarium | The moment the **local** write completes (not the network upload — matches the app's existing local-first save pattern) | `.notificationOccurred(.success)` | Spring pop + toast, `.tap` token |
| Save failure | `showSaveFailureAlert` fires | `.notificationOccurred(.error)` | Tight shake, zero bounce — errors should never feel playful |
| Card flip | Exactly at the 90° rotation midpoint, when the back content starts becoming visible | `.impactOccurred(.light)` | `.flip` token — not on tap-down, since the tap is a control impact but the flip is the card's own physicality |
| Tab bar switch | On tap, synchronous with the animation start | `UISelectionFeedbackGenerator().selectionChanged()` | `.tap` token on the pill/indicator |
| Herbarium row → Botanical Card | Tap | **No haptic** — this is navigation via `matchedGeometryEffect`, not a confirmation; let the geometry motion itself carry the "arrival" | `.flow` token |
| Scan result reveal (ScanResultsView) | Results view appears | None | Staggered reveal — title, then confidence badge, then chips — not all at once. This is the app's core "magic moment"; a single fade undersells it |

---

## Part 2 — Functional & Visual Testing Plan

### Priority order

1. **Home / Scan entry** (highest traffic, sets the tone)
2. **Scanner → Scan Results → Save** (the core loop)
3. **Botanical Card flip** (the flagship redesigned screen)
4. **Herbarium grid/list → Card transition** (matchedGeometryEffect, highest risk of jank)
5. **Tab bar** (touched on every screen — small bugs here compound)
6. **Auth (Login/Sign up)** — lower motion priority, mostly static forms
7. **Druid/Paywall** — lowest priority for this pass

### Checklist

#### 1. Home
| # | Test | Acceptance criteria | Result |
|---|---|---|---|
| 1.1 | Open the app cold | No visible layout pop/flash before first frame settles; if a splash/transition exists, it ends within ~400ms | |
| 1.2 | Tap the scan CTA | Button gives tactile feedback (scale-down) **before** the camera cover animates in — feedback should never wait on navigation | |
| 1.3 | "Recent catches" row appears/updates | New items animate in with the `.reveal` token, not a hard cut | |

#### 2. Scanner → Results → Save
| # | Test | Acceptance criteria | Result |
|---|---|---|---|
| 2.1 | Shutter tap | Haptic fires on press-down, not on the resulting screen transition. Photo-capture flash/scale is instant (<100ms perceived) | |
| 2.2 | Scanning/analyzing state | Reticle or progress motion loops smoothly — no visible stutter, no hard jump-cut at the loop seam | |
| 2.3 | Results reveal | Title, confidence, chips appear staggered, not simultaneous. Total reveal choreography under ~600ms so it doesn't feel slow | |
| 2.4 | Tap "Save to Herbarium" | Success haptic + confirmation motion fire the moment the local file write completes — **not** after the Supabase upload (should feel instant even offline) | |
| 2.5 | Force a save failure (airplane mode / bad path) | Error haptic is distinct from success — no shared "generic buzz," and the shake has no bounce | |

#### 3. Botanical Card flip
| # | Test | Acceptance criteria | Result |
|---|---|---|---|
| 3.1 | Tap the flip control | Rotation uses the `.flip` spring — you should feel a *slight* overshoot/settle at the end, not a hard stop | |
| 3.2 | Haptic timing | Light impact lands exactly at the 90° midpoint (when front content disappears / back starts appearing) — not on initial tap | |
| 3.3 | Flip mid-animation, tap again immediately | Spring must be interruptible — reversing direction should feel continuous, no snap-to-start | |
| 3.4 | Enable Reduce Motion in Settings, retest | Flip becomes a cross-fade, not disabled entirely | |

#### 4. Herbarium → Card transition
| # | Test | Acceptance criteria | Result |
|---|---|---|---|
| 4.1 | Tap a Herbarium row | The thumbnail visibly *becomes* the card hero image via `matchedGeometryEffect` — no flash, resize pop, or frame where the image briefly disappears | |
| 4.2 | Scroll the list fast, then tap a row mid-scroll | Transition still completes cleanly — no dropped frames, no wrong row selected | |
| 4.3 | Dismiss the card via drag (`immersiveDismissDrag`) | Motion tracks your finger 1:1 while dragging; releasing above the threshold completes the dismiss with velocity carried through, not a fixed-duration snap-back | |
| 4.4 | Dismiss via close button vs. drag | Both should feel like the same "family" of motion — same easing character, not two different animations for the same outcome | |

#### 5. Tab bar (`FloatingLiquidTabBar`)
| # | Test | Acceptance criteria | Result |
|---|---|---|---|
| 5.1 | Tap each of the 4 tabs in sequence, fast | Selection haptic fires on every tap, even rapid ones — no dropped/debounced haptics | |
| 5.2 | Watch the active-tab indicator | Slides/morphs to the new position, doesn't teleport; consistent duration regardless of how far it travels | |

#### 6-7. Auth / Druid / Paywall
Lower priority — confirm form field focus/error states have *some* motion (not a hard cut), and that's sufficient for this pass.

### How to report results back

For anything that doesn't match the acceptance criteria, use this shape:

```
Screen/Component: [e.g. "Botanical Card flip"]
Test #: [e.g. 3.2]
What I did: [exact steps]
What happened: [specific — "haptic fired on tap-down, not at the midpoint" beats "haptic feels off"]
Expected: [copy from the acceptance criteria, or your own read of what "right" would feel like]
Device: [Simulator model + iOS version, or physical device]
```

Describe timing problems in relative terms, not adjectives alone — "the flip settles noticeably slower than the tab switch" is fixable immediately; "feels weird" sends me hunting. A screen recording (QuickTime → File → New Screen Recording, works for Simulator too) resolves ambiguity faster than any description.

### Implementation order

Once file access allows it, start with the `LeafIDMotion` token set — everything downstream (checklist items 1-5) depends on it existing first.
