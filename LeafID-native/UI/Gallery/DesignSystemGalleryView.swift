//
//  DesignSystemGalleryView.swift
//  LeafID-native
//
//  Design System Foundry - component previews (Phase 3 scan / bento registration).
//

import SwiftUI

private let gallerySampleScan = HerbariumViewModel.placeholderCatalog[0]

private let gallerySampleResult = IdentifyPreviewResult(
    commonName: "Monstera Deliciosa",
    scientificName: "Monstera deliciosa",
    confidence: 0.88,
    locationLabel: "Indoor conservatory, morning light",
    family: "ARACEAE",
    descriptionText: "An iconic tropical climber with fenestrated leaves, widely grown indoors.",
    originCountry: "Mexico",
    isNewDiscovery: true,
    usedFallback: false,
    tagSecondary: "Bright indirect light",
    chipSunExposure: "Bright indirect light",
    chipWatering: "Allow soil to dry slightly between waterings",
    chipPhylum: "Magnoliophyta",
    paletteHexes: ["#2C4C1A", "#7AAE2E", "#6B4F2E"],
    botanicalSpirit: "A patient climber that follows light with calm persistence.",
    ethnobotany: "Aroids are commonly cultivated ornamentals across tropical and subtropical regions.",
    culturalLegacy: "Split-leaf silhouettes are a staple of contemporary botanical illustration."
)

struct DesignSystemGalleryView: View {
    var dismiss: () -> Void = {}

    private struct TokenColorSpec {
        let name: String
        let hex: String
        let color: Color
    }

    /// Static palette for the foundry (matches `Theme.swift` + derived tokens).
    private static let tokenColors: [TokenColorSpec] = [
        TokenColorSpec(name: "primary", hex: "#93BC10", color: LeafIDTheme.primary),
        TokenColorSpec(name: "primaryContainer", hex: "#8DC104", color: LeafIDTheme.primaryContainer),
        TokenColorSpec(name: "surface", hex: "#0B0F08", color: LeafIDTheme.surface),
        TokenColorSpec(name: "surfaceContainerLow", hex: "#10150C", color: LeafIDTheme.surfaceContainerLow),
        TokenColorSpec(name: "surfaceContainerHigh", hex: "#1C2116", color: LeafIDTheme.surfaceContainerHigh),
        TokenColorSpec(name: "surfaceContainerHighest", hex: "#22281C", color: LeafIDTheme.surfaceContainerHighest),
        TokenColorSpec(name: "onSurface", hex: "#F2F5E7", color: LeafIDTheme.onSurface),
        TokenColorSpec(name: "onSurfaceVariant", hex: "#A9ADA0", color: LeafIDTheme.onSurfaceVariant),
        TokenColorSpec(name: "onPrimary", hex: "#121212", color: LeafIDTheme.onPrimary),
        TokenColorSpec(name: "onPrimaryContainer", hex: "#253600", color: LeafIDTheme.onPrimaryContainer),
        TokenColorSpec(name: "outlineVariant", hex: "#45493F", color: LeafIDTheme.outlineVariant),
        TokenColorSpec(name: "specimenField", hex: "surfaceHigh 45%", color: LeafIDTheme.specimenField),
        TokenColorSpec(name: "scanButtonShadowColor", hex: "rgba(147,188,16,0.3)", color: LeafIDTheme.scanButtonShadowColor),
    ]

    private static let layoutTokenLines: [(String, String)] = [
        ("space4 … space32", "4, 6, 8, 10, 12, 14, 16, 20, 22, 24, 28, 32 pt"),
        ("screenHorizontalPadding", "24 pt"),
        ("headerTopInset", "12 pt"),
        ("homeBottomTabClearance", "0 pt (safeAreaInset tab bar)"),
        ("scanButtonSize", "112 pt"),
        ("scanButtonShadowRadius", "50 pt"),
        ("liquidGlassCornerRadius / card", "32 pt (CornerRadius.card)"),
        ("radiusSpecimenThumb", "16 pt"),
        ("herbariumRowThumbnail", "80 pt"),
        ("botanicalCardCornerRadius", "48 pt (`CornerRadius.immersive`)"),
        ("botanical front overlay", "H 40 pt, bottom 112 pt (`p-10` / `pb-28`)"),
        ("botanical front title", "36 pt (`text-4xl`)"),
        ("radiusPrimaryButton", "32 pt"),
        ("shadowCard", "radius 24, y 10, opacity 0.35"),
        ("shadowButton", "radius 16, y 8, opacity 0.45"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                LeafIDTheme.surface.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: LeafIDTheme.space28) {
                        Text("Design System Foundry")
                            .font(LeafIDFont.plusJakarta(size: 28, weight: .bold))
                            .tracking(-0.35)
                            .foregroundStyle(LeafIDTheme.onSurface)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, LeafIDTheme.space8)

                        VStack(alignment: .leading, spacing: LeafIDTheme.space28) {
                        foundrySection("Tokens — Color (LeafIDTheme)") {
                            VStack(alignment: .leading, spacing: LeafIDTheme.space12) {
                                ForEach(0 ..< Self.tokenColors.count, id: \.self) { i in
                                    let row = Self.tokenColors[i]
                                    galleryColorRow(row.name, row.hex, row.color)
                                }
                            }
                        }

                        foundrySection("Tokens — Layout & radii") {
                            VStack(alignment: .leading, spacing: LeafIDTheme.space8) {
                                ForEach(0 ..< Self.layoutTokenLines.count, id: \.self) { i in
                                    let line = Self.layoutTokenLines[i]
                                    galleryTokenLine(line.0, line.1)
                                }
                            }
                        }

                        foundrySection("Molecules - CompactSpecimenCard") {
                            VStack(alignment: .leading, spacing: LeafIDTheme.space16) {
                                CompactSpecimenCard(lastFound: gallerySampleScan)
                                CompactSpecimenCard(
                                    commonName: "Monstera Deliciosa",
                                    scientificName: "Monstera deliciosa",
                                    style: .grid
                                )
                                .frame(maxWidth: 180)
                            }
                        }

                        foundrySection("Molecules - HerbariumSpecimenRowCard") {
                            HerbariumSpecimenRowCard(scan: gallerySampleScan)
                        }

                        foundrySection("Atoms - ModalCloseButton") {
                            HStack {
                                Spacer()
                                ModalCloseButton {}
                                Spacer()
                            }
                            .padding(.vertical, LeafIDTheme.space12)
                        }

                        foundrySection("Atoms - GlassChromeCircleButton") {
                            HStack(spacing: LeafIDTheme.space16) {
                                GlassChromeCircleButton(systemImage: "chevron.left", accessibilityLabel: "Back") {}
                                GlassChromeCircleButton(systemImage: "bolt.fill", accessibilityLabel: "Flash") {}
                                GlassChromeCircleButton(systemImage: "square.and.arrow.up", accessibilityLabel: "Share") {}
                            }
                        }

                        foundrySection("Atoms - MatchConfidenceBadge") {
                            VStack(alignment: .leading, spacing: LeafIDTheme.space12) {
                                HStack(spacing: LeafIDTheme.space12) {
                                    MatchConfidenceBadge(confidence: 0.91)
                                    MatchConfidenceBadge(confidence: 0.42)
                                }
                                MatchConfidenceBadge(confidence: 0.88, useResultsTitle: true)
                            }
                        }

                        foundrySection("Molecules - ScanningProgressBar") {
                            VStack(alignment: .leading, spacing: LeafIDTheme.space12) {
                                Text("Animating")
                                    .font(LeafIDFont.manrope(size: 11, weight: .bold))
                                    .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                                ScanningProgressBar(isAnimating: true)
                                Text("Static (gallery)")
                                    .font(LeafIDFont.manrope(size: 11, weight: .bold))
                                    .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                                ScanningProgressBar(isAnimating: false)
                            }
                        }

                        foundrySection("Molecules - ScanningDensityProgress") {
                            VStack(spacing: LeafIDTheme.space16) {
                                ScanningDensityProgress(progress: 0.34)
                                ScanningDensityProgress(progress: 0.78)
                                ScanningDensityProgress(progress: 1)
                            }
                        }

                        foundrySection("Molecules - ScanReticleFrame") {
                            ScanReticleFrame()
                                .frame(height: 220)
                                .padding(.vertical, LeafIDTheme.space8)
                        }
                        }

                        VStack(alignment: .leading, spacing: LeafIDTheme.space28) {
                        foundrySection("Headers - GlassScanHeaderPill") {
                            VStack(spacing: LeafIDTheme.space16) {
                                HStack {
                                    Spacer()
                                    GlassScanHeaderPill(title: "Analyzing leaf...", showsStatusDot: true)
                                    Spacer()
                                }
                                HStack {
                                    Spacer()
                                    GlassScanHeaderPill(title: "Analyzing leaf...", showsStatusDot: false)
                                    Spacer()
                                }
                            }
                        }

                        foundrySection("Molecules - BentoResultCard") {
                            BentoResultCard(result: gallerySampleResult)
                        }

                        foundrySection("Signature - GalleryScanButton") {
                            HStack {
                                Spacer()
                                GalleryScanButton {}
                                Spacer()
                            }
                        }

                        foundrySection("CTA LeafPrimaryButton with icon") {
                            LeafPrimaryButton(title: "Save to Herbarium", leadingSystemImage: "leaf.fill", action: {})
                        }
                        }
                    }
                    .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                    .padding(.vertical, LeafIDTheme.space24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(LeafIDTheme.primary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func foundrySection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space12) {
            Text(title)
                .font(LeafIDFont.manrope(size: 11, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(LeafIDTheme.onSurfaceVariant)
            content()
        }
    }

    private func galleryColorRow(_ name: String, _ hex: String, _ color: Color) -> some View {
        HStack(alignment: .center, spacing: LeafIDTheme.space16) {
            RoundedRectangle(cornerRadius: LeafIDTheme.space8, style: .continuous)
                .fill(color)
                .frame(width: 48, height: 48)
                .overlay {
                    RoundedRectangle(cornerRadius: LeafIDTheme.space8, style: .continuous)
                        .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.35), lineWidth: 1)
                }
            VStack(alignment: .leading, spacing: LeafIDTheme.space4) {
                Text(name)
                    .font(LeafIDFont.manrope(size: 14, weight: .semibold))
                    .foregroundStyle(LeafIDTheme.onSurface)
                Text(hex)
                    .font(LeafIDFont.manrope(size: 12, weight: .medium))
                    .foregroundStyle(LeafIDTheme.onSurfaceVariant)
            }
            Spacer(minLength: 0)
        }
    }

    private func galleryTokenLine(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(LeafIDFont.manrope(size: 13, weight: .semibold))
                .foregroundStyle(LeafIDTheme.onSurface)
            Spacer()
            Text(value)
                .font(LeafIDFont.manrope(size: 12, weight: .medium))
                .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct DesignSystemGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        DesignSystemGalleryView()
    }
}
