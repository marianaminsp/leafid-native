# Herbarium screen

Reference: [`Herbarium.png`](./Herbarium.png).

## Purpose

The Herbarium tab lists **saved specimens**: every entry is a `Scan` the user persisted from the **Scan results** flow (Save / Preserve). New items are prepended via `HerbariumViewModel.appendPreservedScan` (see `BotanyService` / results UI).

## Layout

- **Background:** `LeafIDTheme.surface`.
- **Header:** Same type stack as Home — **Plus Jakarta** title, **Manrope** subtitle — with copy “Herbarium” / “Your collection of botanical wonders”. The list is scrollable; as the user scrolls, the title **interpolates** from 34pt toward 22pt and the subtitle **fades out** (scroll offset via `PreferenceKey` + named `coordinateSpace` on the `ScrollView`).
- **List:** Vertical stack of **`HerbariumSpecimenRowCard`** rows (not the 2-column grid). Each row: square thumbnail (`LeafIDTheme.herbariumRowThumbnail`), **common name**, **“Found … ago”** in `LeafIDTheme.primary` (`Scan.foundRelativePhrase()`), **location** in `onSurfaceVariant`, trailing chevron. Card uses `surfaceContainerHigh`, `CornerRadius.resultsSheetTop`, subtle outline stroke.
- **Detail:** Tapping a row opens **`BotanicalCardDetailView`** with `matchedGeometryEffect` on the row thumbnail id (same namespace pattern as the former grid card).

## Components

| Piece | Location |
|-------|----------|
| Row card | `LeafID-native/UI/System/HerbariumSpecimenRowCard.swift` |
| Screen | `LeafID-native/Views/Herbarium/HerbariumView.swift` |
| Foundry preview | `DesignSystemGalleryView` → “HerbariumSpecimenRowCard” |
