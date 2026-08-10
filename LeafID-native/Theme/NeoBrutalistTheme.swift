//
//  NeoBrutalistTheme.swift
//  LeafID-native
//
//  Design tokens for the "Urban Pop / Neo-Brutalist" redesign, translated from
//  stitch_botanical_explorer/leaf_id/DESIGN.md. Lives in its own file rather than
//  extending Theme.swift — this branch replaces the token set wholesale rather than
//  adding to it, and keeping it separate means `main` never has to see this file.
//
//  MARK: Cross-screen conventions (locked in 2026-08-09 after repeated visual-review passes
//  found each screen had independently drifted from these — treat this block as the source of
//  truth before copying a pattern from any one screen to another):
//
//  - **Primary CTA buttons** (full-width, one per screen — "Open Scanner," "Start Your
//    Collection," etc.): `background: primary` (#006D3F), white text, `height: 60`, heavy
//    border, `shadowOffset: 6`. Confirmed against the canonical "Leaf ID — Arboretum (WIP)"
//    artifact's `.cta-button`. Do NOT use `primaryContainer`/`onPrimaryContainer` (light mint)
//    for buttons — that pairing is for headline accent tags only (see below).
//  - **Headline construction**: first line plain `onSurface` text; second (accent) line is
//    EITHER (a) a hard-bordered `primaryContainer`-filled tag box — Identify's "STREETS.",
//    Herbarium's "HERBARIUM" — or (b) plain `primary`-colored text with no box — Arboretum's
//    "ARBORETUM", confirmed against its canonical artifact. Don't assume one pattern is "more
//    correct" and silently convert a screen to match — this split is real, confirmed twice.
//  - **Subhead with a left accent bar**: always build it as `Text(...).padding(.leading:
//    md).overlay(alignment: .leading) { Rectangle().fill(ink).frame(width: 4) }` — an
//    unconstrained `Rectangle` as a plain `HStack` sibling will stretch to fill any leftover
//    space in a zero-scroll flexible layout (bit Identify, then Herbarium, then Arboretum —
//    always the overlay form, never the HStack form).
//  - **Screen-level top padding**: apply exactly once, at the outer content container
//    (`.padding(.top, md)`) — never again inside a child like the headline itself, or the title
//    sits visibly lower on that one screen than the others (bit Herbarium — its headline had
//    its own redundant `.padding(.top, md)` stacked on top of the container's).
//  - **Zero-scroll flexible layout** (Identify, Arboretum): one hero/map element carries
//    `.frame(maxWidth: .infinity, maxHeight: .infinity)` and absorbs all leftover vertical
//    space; everything else (headline, CTA) is content-sized. No `ScrollView`. Screens that are
//    explicitly WIP (Arboretum's map) get no CTA at all — a call-to-action implies there's
//    somewhere further to go, which isn't true yet.
//

import SwiftUI

enum NeoBrutalistColor {
    static let surface = Color(hex: 0xF8F9FF)
    static let surfaceDim = Color(hex: 0xD7DAE3)
    static let surfaceBright = Color(hex: 0xF8F9FF)
    static let surfaceContainerLowest = Color(hex: 0xFFFFFF)
    static let surfaceContainerLow = Color(hex: 0xF1F3FC)
    static let surfaceContainer = Color(hex: 0xEBEEF7)
    static let surfaceContainerHigh = Color(hex: 0xE5E8F1)
    static let surfaceContainerHighest = Color(hex: 0xDFE2EB)

    static let onSurface = Color(hex: 0x181C22)
    static let onSurfaceVariant = Color(hex: 0x3B4A3F)
    static let inverseSurface = Color(hex: 0x2D3137)
    static let inverseOnSurface = Color(hex: 0xEEF0F9)

    static let outline = Color(hex: 0x6B7B6E)
    static let outlineVariant = Color(hex: 0xBACBBC)

    /// "Electric Green" — Druid status actions, successful IDs, growth indicators.
    static let primary = Color(hex: 0x006D3F)
    static let onPrimary = Color(hex: 0xFFFFFF)
    static let primaryContainer = Color(hex: 0x2AF598)
    static let onPrimaryContainer = Color(hex: 0x006C3F)
    static let inversePrimary = Color(hex: 0x00E38A)

    /// "Punchy Orange" — Herbarium alerts, high-priority botanical warnings.
    static let secondary = Color(hex: 0xB02700)
    static let onSecondary = Color(hex: 0xFFFFFF)
    static let secondaryContainer = Color(hex: 0xDC3300)
    static let onSecondaryContainer = Color(hex: 0xFFFBFF)

    /// "Neon Pink" — social interactions, discovery badges, playful flourishes.
    static let tertiary = Color(hex: 0xAD009B)
    static let onTertiary = Color(hex: 0xFFFFFF)
    static let tertiaryContainer = Color(hex: 0xFFC7ED)
    static let onTertiaryContainer = Color(hex: 0xAC0099)

    static let error = Color(hex: 0xBA1A1A)
    static let onError = Color(hex: 0xFFFFFF)
    static let errorContainer = Color(hex: 0xFFDAD6)
    static let onErrorContainer = Color(hex: 0x93000A)

    static let background = Color(hex: 0xF8F9FF)
    static let onBackground = Color(hex: 0x181C22)

    /// The "ink" for heavy borders and hard-offset shadows — DESIGN.md's Elevation & Depth section.
    static let ink = Color(hex: 0x0D1117)
}

enum NeoBrutalistSpacing {
    static let unit: CGFloat = 4
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 40
    static let gutter: CGFloat = 16
    static let marginMobile: CGFloat = 16
}

enum NeoBrutalistStroke {
    /// Chips/tags — DESIGN.md Components: "1px border and no shadow."
    static let hairline: CGFloat = 1
    /// Default interactive surface border (buttons, cards, inputs).
    static let `default`: CGFloat = 2
    /// Emphasized border weight for primary containers and Arboretum-style cards.
    static let heavy: CGFloat = 3
    /// Default hard-shadow offset.
    static let shadowOffset: CGFloat = 4
    /// Larger hard-shadow offset for elevated/primary surfaces.
    static let shadowOffsetLarge: CGFloat = 8
}

/// Font family names are the exact PostScript names baked into each .ttf in
/// `LeafID-native/Resources/Fonts` — re-verify with fontTools if a font file is ever swapped.
enum NeoBrutalistFont {
    static func displayLg() -> Font { .custom("Syne-ExtraBold", size: 48) }
    static func headlineLg() -> Font { .custom("Syne-Bold", size: 32) }
    static func headlineLgMobile() -> Font { .custom("Syne-Bold", size: 28) }
    static func headlineMd() -> Font { .custom("Syne-Bold", size: 24) }
    static func bodyLg() -> Font { .custom("HankenGrotesk-Regular", size: 18) }
    static func bodyMd() -> Font { .custom("HankenGrotesk-Regular", size: 16) }
    static func bodyMedium(size: CGFloat) -> Font { .custom("HankenGrotesk-Medium", size: size) }
    /// `label-caps` — pair with `.textCase(.uppercase)` and wide tracking at the call site
    /// (SwiftUI has no built-in letter-spacing modifier; `kerning(1.2)` approximates DESIGN.md's 0.1em).
    static func labelCaps() -> Font { .custom("SpaceMono-Bold", size: 12) }
}

// MARK: - Hard-edge depth (DESIGN.md "Elevation & Depth")

/// 100%-opacity offset shadow, no blur — the system's signature "Neubrutalist shadow." Renders as a
/// solid rectangle behind the content, offset down-right; every primary container in this system has
/// 0px corner radius, so a plain Rectangle always matches the content's own shape.
struct NeoBrutalistHardShadow: ViewModifier {
    var offset: CGFloat = NeoBrutalistStroke.shadowOffset
    var color: Color = NeoBrutalistColor.ink

    func body(content: Content) -> some View {
        content.background(
            Rectangle()
                .fill(color)
                .offset(x: offset, y: offset)
        )
    }
}

struct NeoBrutalistBorder: ViewModifier {
    var width: CGFloat = NeoBrutalistStroke.default
    var color: Color = NeoBrutalistColor.ink

    func body(content: Content) -> some View {
        content.overlay(Rectangle().strokeBorder(color, lineWidth: width))
    }
}

extension View {
    func neoBrutalistHardShadow(
        offset: CGFloat = NeoBrutalistStroke.shadowOffset,
        color: Color = NeoBrutalistColor.ink
    ) -> some View {
        modifier(NeoBrutalistHardShadow(offset: offset, color: color))
    }

    func neoBrutalistBorder(
        width: CGFloat = NeoBrutalistStroke.default,
        color: Color = NeoBrutalistColor.ink
    ) -> some View {
        modifier(NeoBrutalistBorder(width: width, color: color))
    }

    /// The signature component treatment — thick border + hard-offset shadow. Order matters: border
    /// first so the shadow rectangle ends up behind the already-bordered content, not just the fill.
    func neoBrutalistSurface(
        borderWidth: CGFloat = NeoBrutalistStroke.heavy,
        shadowOffset: CGFloat = NeoBrutalistStroke.shadowOffset,
        shadowColor: Color = NeoBrutalistColor.ink
    ) -> some View {
        self
            .neoBrutalistBorder(width: borderWidth, color: shadowColor)
            .neoBrutalistHardShadow(offset: shadowOffset, color: shadowColor)
    }
}

/// "Press into the shadow" interaction — DESIGN.md Shapes/Interactive States: on tap, content shifts
/// by the shadow's offset to land exactly where the shadow was, springing back on release. Reuses the
/// `.tap` spring token from `docs/MOTION_DELIGHT_PLAN.md` (response 0.28 / damping 0.86) — motion
/// timing carries over independent of the visual skin.
struct NeoBrutalistPressableStyle: ButtonStyle {
    var shadowOffset: CGFloat = NeoBrutalistStroke.shadowOffset

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(
                x: configuration.isPressed ? shadowOffset : 0,
                y: configuration.isPressed ? shadowOffset : 0
            )
            .animation(.spring(response: 0.28, dampingFraction: 0.86), value: configuration.isPressed)
    }
}

// MARK: - Missing-screen signposting

/// Every button in the redesign is tappable — for the ones whose destination isn't among the 6
/// stitch_botanical_explorer mockups yet, this surfaces that clearly instead of doing nothing, so
/// gaps are easy to find while clicking through rather than silently swallowed.
private struct MissingScreenAlertModifier: ViewModifier {
    @Binding var featureName: String?

    func body(content: Content) -> some View {
        content.alert(
            featureName ?? "",
            isPresented: Binding(
                get: { featureName != nil },
                set: { if !$0 { featureName = nil } }
            )
        ) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            Text("This screen isn't in the neo-brutalist redesign mockups yet.")
        }
    }
}

extension View {
    /// Bind a screen-local `@State private var missingFeature: String?`; setting it to a feature
    /// name (e.g. a button's label) shows the alert, `nil` dismisses it.
    func missingScreenAlert(_ featureName: Binding<String?>) -> some View {
        modifier(MissingScreenAlertModifier(featureName: featureName))
    }
}
