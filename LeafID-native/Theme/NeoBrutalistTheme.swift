//
//  NeoBrutalistTheme.swift
//  LeafID-native
//
//  Design tokens for the "Urban Pop / Neo-Brutalist" redesign, translated from
//  stitch_botanical_explorer/leaf_id/DESIGN.md. Lives in its own file rather than
//  extending Theme.swift — this branch replaces the token set wholesale rather than
//  adding to it, and keeping it separate means `main` never has to see this file.
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
