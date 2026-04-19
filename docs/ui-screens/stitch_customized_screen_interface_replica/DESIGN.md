# Design System Specification: Botanical Immersive Interface

## 1. Overview & Creative North Star

### The Creative North Star: "The Digital Biologist"
This design system is built to transform a standard utility into a premium, editorial experience. We are moving away from "app-like" containers and toward a "Living Laboratory" aesthetic. The interface should feel like a high-end lens through which the user interacts with nature—merging technical precision with organic softness.

To break the "template" look, this system prioritizes **Atmospheric Immersion**. We achieve this through:
*   **Intentional Asymmetry:** Breaking the grid with overlapping botanical data and floating scanning indicators.
*   **Tonal Depth:** Utilizing deep, forest-inspired greens and blacks to allow the vibrant primary accents to "glow" as if light is passing through a leaf.
*   **Macro Focus:** Large typography scales and generous breathing room that treat plant data with the same reverence as a luxury fashion magazine.

---

## 2. Colors

The palette is anchored in deep environmental tones, designed to make the camera feed and plant photography the hero.

*   **Primary Accent (`primary`: #a7da49):** Use this for high-priority actions and active scanning states. It should feel electric and alive.
*   **The Container Core (`primary_container`: #8dbe2e):** The workhorse for progress bars and primary buttons.
*   **The Void (`background`: #0f150d):** A deep, organic black-green that provides more soul than a standard #000000.

### The "No-Line" Rule
**Explicit Instruction:** You are prohibited from using 1px solid borders to define sections or cards. 
*   **Boundaries** must be created through background color shifts. For example, a `surface_container_low` card should sit on a `surface` background. 
*   **Transitions** should feel like shadows in a forest—gradual and soft, not harsh and mechanical.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers. 
1.  **Base:** `surface` (#0f150d)
2.  **Secondary Content:** `surface_container_low` (#171d15)
3.  **Interactive Elements:** `surface_container_high` (#252c23)
Use these tiers to create "nested" depth without relying on structural lines.

### The "Glass & Gradient" Rule
To achieve a signature look, utilize **Glassmorphism** for all floating UI elements (like the 'Analyzing' pill or 'Flash' toggle).
*   **Style:** Apply `surface_variant` at 40% opacity with a `backdrop-blur` of 20px. 
*   **Soulful Gradients:** For main CTAs, use a subtle linear gradient from `primary` (#a7da49) to `primary_container` (#8dbe2e) at a 135-degree angle. This mimics the natural variegation found in foliage.

---

## 3. Typography

We utilize **Manrope** for its technical yet friendly geometric construction.

*   **Display Scales (`display-lg` to `display-sm`):** Reserved for high-impact botanical names or scanning percentages. These should feel authoritative and editorial.
*   **Headline & Title:** Used for plant health statuses and category headers.
*   **Labels (`label-md`, `label-sm`):** Use these for technical metadata (e.g., "SCANNING DENSITY"). Always use `on_surface_variant` for labels to maintain a sophisticated hierarchy.

**Editorial Tip:** Pair a `display-md` botanical name with a `label-md` uppercase subtitle. The contrast in scale creates a premium "specimen label" feel.

---

## 4. Elevation & Depth

In this system, depth is a matter of light and atmosphere, not drop-shadows.

### The Layering Principle
Stack tiers to create lift. A card using `surface_container_highest` placed on a `surface_dim` background creates a natural, soft lift that feels integrated into the environment.

### Ambient Shadows
When a floating effect is required (e.g., a "Care Tip" floating over the camera feed):
*   **Blur:** 24px - 40px.
*   **Opacity:** 6% - 10%.
*   **Color:** Use a tinted version of `on_primary_fixed_variant` rather than grey. This ensures shadows feel like they belong in a botanical environment.

### The "Ghost Border" Fallback
If accessibility requires a container definition, use a **Ghost Border**:
*   Token: `outline_variant` (#434937) at **15% opacity**.
*   This creates a "whisper" of an edge that defines space without cluttering the visual field.

---

## 5. Components

### The Scanning Viewfinder
*   **Corners:** Use `xl` (1.5rem) or `lg` (1rem) roundedness.
*   **Stroke:** Avoid a full box. Use corner brackets only, using the `primary` token.
*   **Animation:** Implement a slow "pulse" on the brackets to indicate life and active processing.

### Buttons & Inputs
*   **Primary Button:** Pill-shaped (`full` roundedness). Use the primary gradient. Typography should be `title-sm` in `on_primary`.
*   **Ghost Inputs:** For search or data entry, use `surface_container_highest` with no border and `sm` (0.25rem) roundedness.

### Progress Bars (e.g., "Scanning Density")
*   **Track:** `surface_variant` at 30% opacity.
*   **Indicator:** `primary_container` (#8dbe2e).
*   **Layout:** Keep the label ("SCANNING DENSITY") and value ("72%") on the same horizontal line using `label-md` for an ultra-clean, technical look.

### Cards & Lists
*   **The Divider Forbid:** Never use 1px divider lines.
*   **Separation:** Use `md` (0.75rem) vertical spacing from the spacing scale to separate list items. Use subtle background shifts (`surface_container_low` vs `surface_container_high`) to distinguish different content blocks.

---

## 6. Do's and Don'ts

### Do
*   **DO** use semi-transparency for all overlays. The user should always feel the presence of the "living" camera feed behind the UI.
*   **DO** embrace wide margins. Negative space is a luxury; use it to make the content feel curated.
*   **DO** use `primary_fixed_dim` for icons to ensure they are legible but not distracting against dark imagery.

### Don't
*   **DON'T** use pure white (#FFFFFF) for text. Use `on_surface` or `on_surface_variant` to prevent "visual vibration" on dark backgrounds.
*   **DON'T** use sharp 90-degree corners. Everything in nature is rounded; the UI should follow suit (minimum `sm` roundedness).
*   **DON'T** use standard Material shadows. They are too "software-heavy." Stick to Tonal Layering or Ambient Shadows.
*   **DON'T** crowd the scanning area. Keep technical readouts to the periphery to maintain the immersive feel of the camera.