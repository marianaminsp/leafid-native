# Design System Strategy: Nocturnal Botanical

## 1. Overview & Creative North Star
This design system is built upon the Creative North Star of **"The Nocturnal Naturalist."** It seeks to replicate the experience of exploring a dense forest at twilight—where the world is composed of deep, layered shadows and sudden, vibrant bioluminescence. 

We are moving away from the "generic app" aesthetic. Instead, we embrace **Organic Editorialism**. This system breaks the rigid digital grid through intentional asymmetry, overlapping card structures, and a dramatic typographic scale. By treating the screen as a tactile, layered canvas rather than a flat interface, we create a premium experience that feels like a high-end coffee table book come to life.

---

## 2. Colors: Tonal Depth & Bioluminescence
Our palette is rooted in the absence of light, using specialized tokens to create a "glowing" effect for interactive elements.

### The "No-Line" Rule
**Explicit Instruction:** Use of 1px solid borders for sectioning or container definition is strictly prohibited. Physicality is achieved through background shifts. A card (using `surface-container-high`) sits on a section (using `surface`) to define its edge. Lines feel "engineered"; tonal shifts feel "grown."

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers.
- **Surface (#0b0f08):** The base forest floor.
- **Surface-Container-Low (#10150c):** Used for large content blocks.
- **Surface-Container-Highest (#22281c):** Reserved for the most interactive or elevated cards, like plant detail panels.

### The "Glass & Gradient" Rule
Floating elements (such as the primary navigation bar) should utilize a "Glassmorphism" approach:
- **Token:** `surface-container-high` at 70% opacity.
- **Effect:** `backdrop-blur: 24px`.
- **Signature Textures:** For the central Scan button, use a subtle radial gradient from `primary` (#93bc10) to `primary-container` (#8dc104) to give the button a spherical, organic volume rather than a flat plastic feel.

---

## 3. Typography: Modernity Meets Authority
We use a dual-font strategy to balance clean modernity with editorial authority.

*   **Display & Headlines (Plus Jakarta Sans):** These are our "Voice." Large, bold, and slightly tight-tracked to feel authoritative. They should dominate the layout with generous white space.
*   **Body & Labels (Manrope):** These are our "Clarity." Manrope’s geometric yet warm proportions ensure readability even in low-light (dark mode) environments.

**Hierarchy Note:** 
- Use `display-lg` (3.5rem) for plant names to create a signature focal point. 
- Use `label-md` in all-caps with `primary` coloring for metadata (e.g., "RARITY" or "LAST FOUND") to provide a technical, "scanned" aesthetic.

---

## 4. Elevation & Depth: Tonal Layering
Traditional shadows are often too harsh for a nature-inspired theme. We replace them with **Ambient Glows.**

*   **The Layering Principle:** Stack `surface-container-lowest` (#000000) inside a `surface-variant` container to create deep recesses for input fields.
*   **Ambient Shadows:** For floating action buttons, use a shadow color derived from `surface-tint` (#93bc10) at 8% opacity with a 40px blur. This creates a "glow" rather than a "shadow."
*   **The "Ghost Border" Fallback:** If a boundary is strictly required for accessibility, use the `outline-variant` token at **15% opacity**. This creates a hint of an edge that disappears into the background, maintaining the "No-Line" philosophy.

---

## 5. Components

### The Central Scan Button
A signature component. A perfect circle utilizing `primary_fixed` with a subtle outer glow (using `surface_tint` at low opacity). It must feel like the "heart" of the interface.

### Primary Buttons
- **Style:** Fully rounded (`rounded-full`).
- **Color:** `primary` (#93bc10) with `on-primary` (#121212) text on solid primary fills.
- **State:** On hover/press, transition to `primary_dim` to simulate a slight dimming of light.

### Custom Input Fields
- **Style:** `surface-container-low` background with a `rounded-lg` (1rem) corner.
- **Interaction:** No border on idle. On focus, use a "Ghost Border" of `primary` at 30% opacity.

### Plant Detail Cards
- **Forbid Dividers:** Use `surface-container-high` cards on a `surface` background. 
- **Internal Spacing:** Use vertical white space (24px - 32px) to separate the plant name from its properties. 
- **Curiosity Callouts:** Use a `secondary_container` background for "Did You Know" facts to provide a soft tonal shift that draws the eye without high-contrast jarring.

---

## 6. Do's and Don'ts

### Do
*   **Do** use asymmetrical layouts. Let plant images "bleed" off the edge of cards to create a sense of wild growth.
*   **Do** use `primary` accents sparingly. It should feel like a rare flower found in a dark forest—precious and functional.
*   **Do** prioritize high-quality botanical photography. The UI is the frame; the plant is the art.

### Don't
*   **Don't** use pure white (#FFFFFF) for text. Use `on_surface` (#f2f5e7) to reduce eye strain and maintain the nocturnal mood.
*   **Don't** use 1px dividers or borders. This is a "No-Line" system.
*   **Don't** use standard "drop shadows" (Black/Grey). Use tinted glows or tonal layering to achieve depth.
*   **Don't** clutter the scan screen. It should be a meditative experience focused on the central action.