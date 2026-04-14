Leaf ID: Technical & Design Flow Architecture
1. Vision & Objective
Leaf ID is a high-end botanical discovery application that merges cutting-edge AI identification, precise geospatial mapping, and immersive gamification. The core experience follows a "Pokedex-style" philosophy, allowing users to catalog trees not just as data points, but as personal and shared memories within a premium digital ecosystem.


2. Global UI Architecture
The application is built on a 4-Tab Navigation System featuring high-performance native transitions and a shared Liquid Glass Design System.
Navigation Structure:
Arboretum (Geospatial Hub): Interactive map exploration.
Scan (Central Action): Primary entry point for AI identification.
Herbarium (Collection): High-end gallery of discovered species.
Druid (Identity): Profile, progression, and botanical rank.


3. Core Functional Flows
A. The Scan & Discovery Flow (Tab 2)
Input: Users can capture a live photo or upload from the library.
Processing: Integration with Gemini 2.0 Flash for rapid, accurate identification.
Visual Feedback: Implementation of the scanning_leaf_animation during the identification phase.
Outcome: Display of the ScanResults interface.
Interaction: Users can review the identification and choose to "Save to Herbarium."
Optimization: Streamlined data confirmation to ensure a frictionless transition from real-world plant to digital asset.
B. The Herbarium & Botanical Card (Tab 3)
The Gallery: A scrollable list of saved specimens using **`HerbariumSpecimenRowCard`** (see `docs/ui-screens/Herbarium.md` / `Herbarium.png`). Entries are **`Scan`** rows created when the user saves from **Scan results** (`Preserve` / Save). The header uses the same typography family as Home (Plus Jakarta + Manrope) and **shrinks while scrolling** (title scales down, subtitle fades).
Expansion Logic: Tapping a row triggers a seamless transition into the Botanical Card view (shared `matchedGeometryEffect` id on the thumbnail).
Botanical Card Details:
- Interactivity: Full-screen immersive card with 3D flip animation (Front/Back); shared outer shell for both faces (`CornerRadius.immersive`). See `docs/ui-screens/BotanicalCard.md`.
- Front: Full-bleed photo, editorial overlay per `botanicalcard-front/` (Plus Jakarta title, Manrope location line, rarity capsule from Plant.id confidence path).
- Back: Identity row + “Main properties” (type / light / watering from persisted `Scan` Plant.id fields) + curiosity paragraph; Share remains staged.
- Layout: Keep chrome (close / flip / pill) outside the flipping card; scroll only the back face content inside the fixed card height.
Social Hook: "Share with Friends" feature (Currently flagged as "Coming Soon").
C. The Arboretum (Tab 1)
Visual Style: Full-screen dark mode map with custom styling.
Markers: Discovered plants are represented as Green Dots.
Interaction: Tapping a dot triggers a floating Compact Card (reusing the Herbarium component) to maintain design consistency across the ecosystem.
Controls: Minimalist zoom and orientation controls integrated into the glass UI.


4. Design System & Tokens
Tab Bar: Implemented as a LiquidGlass component—blur-heavy, elegant, and simple.
Headers: All section headers follow the unified Design System (consistent typography, transparency, and safe-area padding).
Typography: High-contrast serif for headings and crisp sans-serif for technical data.
Materials: Extensive use of .ultraThinMaterial and custom glass modifiers.

