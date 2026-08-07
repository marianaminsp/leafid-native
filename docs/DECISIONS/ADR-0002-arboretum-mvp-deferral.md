# ADR-0002: Defer Arboretum (map) from MVP launch

Date: 2026-08-06
Status: Accepted
Decision owners: Product

## Context

`ArboretumView` (interactive MapKit view of geotagged specimens) is fully built, but polishing and
QA-ing it pre-launch — pin clustering/performance at scale, zoom/recenter edge cases, the cross-tab
bridge into Herbarium — adds real scope right before a planned visual redesign that will likely touch
this screen again. Shipping it now risks polishing UI that gets reworked shortly after.

## Decision

Ship the MVP with the Arboretum tab entry point still visible in the tab bar, but routed to
`ArboretumComingSoonView.swift` (a static "coming soon" placeholder) instead of the real map. The
built map (`ArboretumView.swift`) stays in the codebase, intentionally shelved, not deleted — swap
`MainTabView.swift`'s `.arboretum` case back to it once the map ships (post-launch or as part of the
redesign).

**Hard requirement:** GPS coordinates must keep being captured and saved for every scan
(`Scan.latitude`/`longitude`/`locality`, via `CapturePickLocationEngine` in both `ScannerView.swift`
and `ImagePickerBridge.swift`) even while the map UI is hidden. This is already implemented and must
not be removed or treated as dead code just because Arboretum isn't visible — it's what lets the
Arboretum map backfill **historical pins** the moment it's re-enabled, instead of only showing pins
for scans captured after that date.

## Consequences

### Positive

- Cuts real pre-launch QA scope: the 8 Arboretum-specific test cases and the map-performance
  cross-cutting case in `docs/audit/qa-launch-checklist.html` collapse to a single "placeholder
  state renders correctly" check.
- No functional coupling risk — nothing else in the app depends on Arboretum being live (verified:
  only comment references elsewhere in the codebase).
- Zero data loss — location capture is unaffected, so the map "just works" retroactively when it
  ships.

### Negative

- App Store listing copy needed a pass to remove map claims (`docs/APP_STORE_LISTING.md`) — must be
  re-added when the map ships, or the listing will undersell the app.
- A visible-but-inert tab is a deliberate choice, not the default — confirm the "coming soon" state
  reads as intentional in review, not broken.

## Alternatives Considered

1. Hide the tab entirely (3-tab bar) until the map ships.
   - Avoids an inert tab, but loses the "coming soon" signal to users and requires re-adding tab-bar
     layout logic later instead of a one-line view swap.
2. Ship the real map at launch.
   - No listing/copy rework needed, but keeps the launch-blocking QA surface this ADR is meant to cut,
     and risks redesign churn shortly after shipping it.

## Next Actions

1. Re-point `MainTabView.swift`'s `.arboretum` case to `ArboretumView` once the map ships.
2. Re-add Arboretum claims to `docs/APP_STORE_LISTING.md` at that point.
3. Re-expand the Arboretum QA section in `docs/audit/qa-launch-checklist.html` (full 8-case list is
   preserved there under "Post-MVP" for reuse).
