//
//  Theme.swift
//  LeafID-native
//
//  Tokens synchronized with `docs/ui-screens/design_system_build/code.html` (tailwind.config); primary `#93BC10`.
//  PDR: `docs/PDR.md` §4 (materials) — use these tokens, not ad-hoc Color.white / .padding defaults.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// HTML `rounded-[2rem]` / `rounded-[3rem]` from `docs/ui-screens/design_system_build/code.html`.
enum CornerRadius {
    static let card: CGFloat = 32
    static let immersive: CGFloat = 48
    /// Bottom results / scanner panels (subtler than immersive).
    static let resultsSheetTop: CGFloat = 20
    /// Panel edge flush with the screen (no rounding).
    static let flushEdge: CGFloat = 0
}

/// Full-width bottom sheet: `CornerRadius.resultsSheetTop` on the top corners, square bottom edge.
struct ResultsSheetTopRoundedShape: Shape {
    var topCornerRadius: CGFloat = CornerRadius.resultsSheetTop

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = min(topCornerRadius, rect.width / 2, rect.height / 2)
        path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + r), control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        path.addQuadCurve(to: CGPoint(x: rect.minX + r, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

enum LeafIDTheme {
    // MARK: - Core palette (tailwind `extend.colors`)

    /// Brand / homepage accent green.
    static let primary = Color(hex: 0x93BC10)
    /// Gradient / tonal partner to `primary` (aligned with `design_system_build` `primary-container`).
    static let primaryContainer = Color(hex: 0x8DC104)
    static let surface = Color(hex: 0x0B0F08)
    static let surfaceContainerLow = Color(hex: 0x10150C)
    static let surfaceContainerHigh = Color(hex: 0x1C2116)
    static let surfaceContainerHighest = Color(hex: 0x22281C)

    static let onSurface = Color(hex: 0xF2F5E7)
    static let onSurfaceVariant = Color(hex: 0xA9ADA0)
    /// Icons and labels on solid `primary` fills (mock: near-black on lime).
    static let onPrimary = Color(hex: 0x121212)
    static let onPrimaryContainer = Color(hex: 0x253600)
    static let outlineVariant = Color(hex: 0x45493F)

    // MARK: - SCAN button (code.html “SCAN BUTTON”)

    /// `w-32 h-32`
    static let scanButtonSize: CGFloat = 112
    /// Glow aligned with `primary` (approx. `rgba(147,188,16,0.3)`).
    static let scanButtonShadowRadius: CGFloat = 50
    static let scanButtonShadowColor = Color(red: 147 / 255, green: 188 / 255, blue: 16 / 255, opacity: 0.3)

    // MARK: - Glass / chrome (PDR §4 + HTML surface-container-high usage)

    static let liquidGlassCornerRadius: CGFloat = CornerRadius.card // alias
    static let liquidGlassBorderOpacity: Double = 0.15

    // MARK: - Layout rhythm (from HTML: `px-6` = 24pt, `p-5`/`p-6` patterns)

    static let space4: CGFloat = 4
    static let space8: CGFloat = 8
    static let space6: CGFloat = 6
    static let space10: CGFloat = 10
    static let space12: CGFloat = 12
    static let space14: CGFloat = 14
    static let space16: CGFloat = 16
    static let space20: CGFloat = 20
    static let space22: CGFloat = 22
    static let space24: CGFloat = 24
    static let space28: CGFloat = 28
    static let space32: CGFloat = 32
    /// `px-6` horizontal screen gutter — **canonical** inset for full-width cards & buttons (Home, Herbarium, Scan, botanical card, tab bar).
    static let screenHorizontalPadding: CGFloat = 24
    static let headerTopInset: CGFloat = 12

    /// Extra space below scroll content when the system safe area does not already include chrome (e.g. full-screen flows).
    static let homeBottomTabClearance: CGFloat = 0

    // MARK: - Legacy aliases (pre–Visual Bible call sites)

    static let deepForest = surface
    static let leafGreen = primary
    static let deepGreen = surfaceContainerHigh
    static let leafGreenAlt = primary
    static let slateMuted = onSurfaceVariant
    static let specimenField = surfaceContainerHigh.opacity(0.45)

    static let radiusSpecimenThumb: CGFloat = 16
    static let radiusCompactCard: CGFloat = CornerRadius.card
    static let radiusStatTile: CGFloat = CornerRadius.card
    static let radiusPrimaryButton: CGFloat = CornerRadius.card

    static let shadowCardRadius: CGFloat = 24
    static let shadowCardY: CGFloat = 10
    static let shadowCardOpacity: Double = 0.35

    static let shadowButtonRadius: CGFloat = 16
    static let shadowButtonY: CGFloat = 8
    static let shadowButtonOpacity: Double = 0.45

    static let mapMarkerDotSize: CGFloat = 14
    static let mapMarkerRingWidth: CGFloat = 2

    /// Herbarium list row thumbnail (`docs/ui-screens/Herbarium.png`).
    static let herbariumRowThumbnail: CGFloat = 80

    // MARK: - Botanical card front (`docs/ui-screens/botanicalcard-front/code.html`, 1rem = 16pt)

    /// Inner shell radius `rounded-[48px]`.
    static let botanicalCardCornerRadius: CGFloat = CornerRadius.immersive
    /// `top-14` — close inset from top of card.
    static let botanicalFrontCloseInsetTop: CGFloat = 56
    /// `right-6` — close inset from trailing edge of card.
    static let botanicalFrontCloseInsetTrailing: CGFloat = 24
    /// Close control `p-2.5`; icon `text-[20px]`.
    static let botanicalFrontCloseIconSize: CGFloat = 20
    static let botanicalFrontClosePadding: CGFloat = 10
    /// Bottom overlay `p-10` horizontal / top; `pb-28` bottom.
    static let botanicalFrontOverlayPaddingH: CGFloat = 40
    static let botanicalFrontOverlayPaddingBottom: CGFloat = 112
    /// `space-y-2` / `mb-2` / `pt-2` / `gap-2` = 8pt.
    static let botanicalFrontStackSpacing: CGFloat = 8
    /// Label `text-[10px]`, `tracking-[0.2em]` → ~2pt at 10px.
    static let botanicalFrontEyebrowSize: CGFloat = 10
    static let botanicalFrontEyebrowTracking: CGFloat = 2
    /// `text-4xl` = 2.25rem = 36pt.
    static let botanicalFrontTitleSize: CGFloat = 36
    /// Location row `text-sm` = 14pt.
    static let botanicalFrontLocationSize: CGFloat = 14
    /// Rarity pill offset `-top-12` / `right-10` from overlay box.
    static let botanicalFrontRarityOffsetY: CGFloat = -48
    static let botanicalFrontRarityInsetTrailing: CGFloat = 40
    static let botanicalFrontRarityPaddingH: CGFloat = 16
    static let botanicalFrontRarityPaddingV: CGFloat = 6
    /// Flip FAB `bottom-10`, `p-4`, icon `text-2xl` = 24pt.
    static let botanicalFrontFlipInsetBottom: CGFloat = 40
    static let botanicalFrontFlipPadding: CGFloat = 16
    static let botanicalFrontFlipIconSize: CGFloat = 24
    /// Card edge `border-outline-variant/10`.
    static let botanicalCardBorderOpacity: Double = 0.1

    static var passportAvatarGradient: LinearGradient {
        LinearGradient(
            colors: [surfaceContainerHigh, primary.opacity(0.35)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Typography (`docs/ui-screens/design_system_build/code.html` — Plus Jakarta / Manrope)

/// PostScript names when fonts are added to the target; otherwise system fallback (per Phase 2 spec).
enum LeafIDFont {
    /// Tailwind `text-3xl` → 1.875rem → 30pt @16px root.
    static let boutiqueTitleSize: CGFloat = 30
    /// Tailwind `text-base` → 1rem → 16pt.
    static let boutiqueSubtitleSize: CGFloat = 16

    static func plusJakarta(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        #if canImport(UIKit)
        let psName: String
        switch weight {
        case .bold, .heavy: psName = "PlusJakartaSans-Bold"
        case .semibold: psName = "PlusJakartaSans-SemiBold"
        case .medium: psName = "PlusJakartaSans-Medium"
        default: psName = "PlusJakartaSans-Regular"
        }
        if UIFont(name: psName, size: size) != nil {
            return .custom(psName, size: size)
        }
        #endif
        return .system(size: size, weight: weight, design: .default)
    }

    static func manrope(size: CGFloat, weight: Font.Weight = .medium) -> Font {
        #if canImport(UIKit)
        let psName: String
        switch weight {
        case .bold, .heavy: psName = "Manrope-Bold"
        case .semibold: psName = "Manrope-SemiBold"
        case .medium: psName = "Manrope-Medium"
        default: psName = "Manrope-Regular"
        }
        if UIFont(name: psName, size: size) != nil {
            return .custom(psName, size: size)
        }
        #endif
        return .system(size: size, weight: weight, design: .rounded)
    }
}

enum LeafIDTypography {
    static func displayTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 34, weight: .heavy, design: .rounded))
            .tracking(0.6)
            .foregroundStyle(LeafIDTheme.onSurface)
    }

    static func accentLine(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 34, weight: .heavy, design: .rounded))
            .tracking(0.6)
            .foregroundStyle(LeafIDTheme.primary)
    }

    static func headerSubtitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .tracking(1.2)
            .foregroundStyle(LeafIDTheme.onSurfaceVariant)
    }
}
