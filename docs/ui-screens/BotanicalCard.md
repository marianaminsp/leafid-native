# Botanical card (Herbarium detail)

Implementation: `LeafID-native/Views/Herbarium/BotanicalCardDetailView.swift`.

## Front

Pixel map from **`botanicalcard-front/code.html`** (Tailwind spacing, 1rem = 16pt) → `LeafIDTheme.botanical*` in `Theme.swift`:

| HTML | Token / value |
|------|----------------|
| `rounded-[48px]` inner shell | `botanicalCardCornerRadius` (48) |
| `border-outline-variant/10` | `botanicalCardBorderOpacity` (0.1) |
| `tonal-gradient` | `#0b0f08` 0% → 90% opacity, top to bottom |
| Close `top-14 right-6`, `p-2.5`, icon 20px | `botanicalFrontCloseInsetTop` 56, `CloseInsetTrailing` 24, padding 10 |
| Bottom block `p-10 pb-28`, `space-y-2` | overlay H 40, bottom 112, stack spacing 8 |
| Eyebrow `text-[10px]` `tracking-[0.2em]` | 10pt, tracking 2 |
| Title `text-4xl` extrabold | 36pt Plus Jakarta heavy |
| Location `text-sm`, icon filled | 14pt, `location.fill` |
| Rarity `-top-12 right-10`, `px-4 py-1.5`, 10px | offsets −48 / trailing 40, capsule padding 16×6 |
| Flip `bottom-10`, `p-4`, icon `text-2xl` | bottom 40, padding 16, icon 24, primary + lime glow |

Copy: **“Scientific Identification”** (match mock). Rarity: **“Native species”** unless `isNewDiscovery` → **“New discovery”**.

- **Matched geometry** on the hero stack from Herbarium rows.
- **Gutter:** card width = screen − `2 × screenHorizontalPadding` (24pt), same as Home / Herbarium / Scan flows.

## Back

Layout inspired by **`BotanicalCard-back.png`**, using the **same outer shell** as the front (shared height, `CornerRadius.immersive`, single flip container):

- Top app chrome (separate from the card): close, **“BOTANICAL DETAIL”** pill, flip control; on the back, a disabled **Share** affordance.
- **Identity row:** circular photo with primary stroke, **scientific** name (Plus Jakarta), **common** name in all-caps Manrope + primary.
- **Main properties:** three glass-style rows fed from **identify-plant / Plant.id** fields persisted on `Scan`:
  - **Type** — `family`, falling back to `phylum`
  - **Light** — `sun_exposure` (from `IdentifyPreviewResult.chipSunExposure`)
  - **Watering** — `watering` (from `chipWatering`)
- **Curiosity** — `description_text` (edge `curiosity` → `IdentifyPreviewResult.descriptionText`), with fallback copy if empty.
- **Pagination dots** under the card mirror front vs back.

## Data wiring

When the user taps **Save** on results, `BotanyService.saveUserCapture` copies identification metadata onto `Scan` (family, description, sun/water/phylum, origin, tags, `is_new_discovery`). Older rows without those fields show “—” or placeholder curiosity text until re-identified.

## References

- [botanicalcard-front/DESIGN.md](./botanicalcard-front/DESIGN.md)
- [botanicalcard-front/code.html](./botanicalcard-front/code.html)
- [BotanicalCard-back.png](./BotanicalCard-back.png)
