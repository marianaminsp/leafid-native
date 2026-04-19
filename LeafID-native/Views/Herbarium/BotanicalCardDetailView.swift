//
//  BotanicalCardDetailView.swift
//  LeafID-native
//
//  Front: pixel-aligned to `docs/ui-screens/botanicalcard-front/code.html` (see `LeafIDTheme` botanical tokens).
//  Back: same outer shell + width as front; top chrome only when back. Plant.id fields on `Scan`.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
private struct BotanicalActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

struct BotanicalCardDetailView: View {
    let scan: Scan
    var namespace: Namespace.ID?
    var matchedGeometryId: UUID?
    let onClose: () -> Void

    @State private var flipDegrees: Double = 0
    @State private var showShareSheet = false
    @State private var enrichmentLoading = true

    private var showBack: Bool { flipDegrees >= 90 }

    var body: some View {
        ZStack {
            LeafIDTheme.surface.ignoresSafeArea()

            Circle()
                .fill(LeafIDTheme.primary.opacity(0.05))
                .frame(width: 384, height: 384)
                .blur(radius: 120)
                .allowsHitTesting(false)

            GeometryReader { geo in
                let gutter = LeafIDTheme.screenHorizontalPadding
                let cardWidth = geo.size.width - 2 * gutter
                let safeTop = geo.safeAreaInsets.top
                let safeBottom = geo.safeAreaInsets.bottom
                let footerBlock: CGFloat = 48
                let backChromeHeight: CGFloat = showBack ? 62 : 0
                let chromeSpacing: CGFloat = showBack ? LeafIDTheme.space12 : 0
                let cardHeight = max(
                    400,
                    min(
                        geo.size.height - safeTop - safeBottom - footerBlock - backChromeHeight - chromeSpacing,
                        geo.size.height * 0.78
                    )
                )

                VStack(spacing: chromeSpacing) {
                    if showBack {
                        backTopChrome
                            .frame(width: cardWidth)
                    }

                    cardShell(width: cardWidth, height: cardHeight)
                        .padding(.horizontal, gutter)

                    BotanicalCardPageIndicator(showBack: showBack)
                        .padding(.top, LeafIDTheme.space4)

                    Text(showBack ? "Flip to return to the specimen photo." : "Flip to open the botanical folio.")
                        .font(LeafIDFont.manrope(size: 12, weight: .medium))
                        .tracking(0.6)
                        .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, gutter)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, safeTop)
                .padding(.bottom, safeBottom)
            }
        }
        .preferredColorScheme(.dark)
        .task { await fakeEnrichmentDelay() }
        #if canImport(UIKit)
        .sheet(isPresented: $showShareSheet) {
            let items: [Any] = {
                var all: [Any] = ["\(scan.commonName) — \(scan.scientificName)"]
                if let local = scan.resolvedLocalCaptureURL,
                   let data = try? Data(contentsOf: local),
                   let img = UIImage(data: data) {
                    all.insert(img, at: 0)
                }
                return all
            }()
            BotanicalActivityView(activityItems: items)
        }
        #endif
    }

    /// Back only — matches card width (`screenHorizontalPadding` gutters app-wide).
    private var backTopChrome: some View {
        ZStack {
            HStack(spacing: LeafIDTheme.space12) {
                Button(action: onClose) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(LeafIDTheme.onSurface)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(.ultraThinMaterial))
                        .overlay {
                            Circle()
                                .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.22), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")

                Spacer(minLength: 0)

                HStack(spacing: LeafIDTheme.space8) {
                    shareDisabledButton
                    flipCircleButton
                }
            }
            botanicalDetailPill
        }
        .padding(.horizontal, LeafIDTheme.space16)
        .padding(.vertical, LeafIDTheme.space12)
        .liquidGlass(cornerRadius: LeafIDTheme.radiusCompactCard)
    }

    private var flipCircleButton: some View {
        Button(action: flipCard) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(LeafIDTheme.onSurface)
                .frame(width: 44, height: 44)
                .background(Circle().fill(.ultraThinMaterial))
                .overlay {
                    Circle()
                        .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.22), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(showBack ? "Show front of card" : "Show back of card")
    }

    private var shareDisabledButton: some View {
        Button(action: {}) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(LeafIDTheme.primary.opacity(0.55))
                .frame(width: 44, height: 44)
                .background(Circle().fill(.ultraThinMaterial))
                .overlay {
                    Circle()
                        .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.15), lineWidth: 1)
                }
        }
        .disabled(true)
        .opacity(0.55)
        .accessibilityLabel("Share — coming soon")
    }

    private var botanicalDetailPill: some View {
        Text("BOTANICAL DETAIL")
            .font(LeafIDFont.manrope(size: 10, weight: .bold))
            .tracking(2.0)
            .foregroundStyle(LeafIDTheme.onPrimary)
            .padding(.horizontal, LeafIDTheme.space14)
            .padding(.vertical, LeafIDTheme.space8)
            .background(Capsule().fill(LeafIDTheme.primary))
            .shadow(color: LeafIDTheme.scanButtonShadowColor.opacity(0.45), radius: 10, y: 3)
    }

    private func cardShell(width: CGFloat, height: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: LeafIDTheme.botanicalCardCornerRadius, style: .continuous)
        return ZStack {
            Group {
                if flipDegrees < 90 {
                    BotanicalCardFrontFace(
                        scan: scan,
                        namespace: namespace,
                        matchedGeometryId: matchedGeometryId,
                        onClose: onClose,
                        onShare: { showShareSheet = true },
                        onFlip: flipCard
                    )
                } else {
                    BotanicalCardBackFace(scan: scan, enrichmentLoading: enrichmentLoading)
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                }
            }
            .rotation3DEffect(.degrees(flipDegrees), axis: (x: 0, y: 1, z: 0), perspective: 0.52)
        }
        .frame(width: width, height: height)
        .clipShape(shape)
        .overlay {
            shape.strokeBorder(LeafIDTheme.outlineVariant.opacity(LeafIDTheme.botanicalCardBorderOpacity), lineWidth: 1)
        }
        .shadow(color: LeafIDTheme.scanButtonShadowColor.opacity(0.22), radius: 24, y: 12)
    }

    private func flipCard() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
            flipDegrees = showBack ? 0 : 180
        }
    }

    private func fakeEnrichmentDelay() async {
        try? await Task.sleep(nanoseconds: 450_000_000)
        await MainActor.run { enrichmentLoading = false }
    }
}

// MARK: - Front (`code.html`)

private struct BotanicalCardFrontFace: View {
    let scan: Scan
    var namespace: Namespace.ID?
    var matchedGeometryId: UUID?
    let onClose: () -> Void
    let onShare: () -> Void
    let onFlip: () -> Void

    private var rarityPillText: String {
        scan.showsNewDiscoveryBadge ? "New discovery" : "Native species"
    }

    /// `tonal-gradient` in HTML: 180deg, #0b0f08 0% → 0.9 at 100%.
    private var tonalGradient: LinearGradient {
        let c = Color(red: 11 / 255, green: 15 / 255, blue: 8 / 255)
        return LinearGradient(
            stops: [
                .init(color: c.opacity(0), location: 0),
                .init(color: c.opacity(0.9), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        ZStack {
            LeafIDTheme.surfaceContainerHigh

            ZStack {
                ScanSpecimenPhotoFill(scan: scan)
                tonalGradient
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .modifier(BotanicalHeroMatchedGeometry(namespace: namespace, id: matchedGeometryId))

            // Bottom copy: `p-10 pb-28 space-y-2`; rarity `absolute -top-12 right-10` relative to this block.
            VStack {
                Spacer(minLength: 0)
                ZStack(alignment: .topTrailing) {
                    VStack(alignment: .leading, spacing: LeafIDTheme.botanicalFrontStackSpacing) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Scientific Identification")
                                .font(LeafIDFont.manrope(size: LeafIDTheme.botanicalFrontEyebrowSize, weight: .bold))
                                .tracking(LeafIDTheme.botanicalFrontEyebrowTracking)
                                .foregroundStyle(LeafIDTheme.primary)
                                .padding(.bottom, LeafIDTheme.botanicalFrontStackSpacing)

                            Text(scan.commonName)
                                .font(LeafIDFont.plusJakarta(size: LeafIDTheme.botanicalFrontTitleSize, weight: .heavy))
                                .tracking(-0.45)
                                .foregroundStyle(LeafIDTheme.onSurface)
                                .lineLimit(4)
                                .minimumScaleFactor(0.86)
                                .lineSpacing(2)
                            Text(scan.scientificName)
                                .font(LeafIDFont.manrope(size: 16, weight: .medium))
                                .italic()
                                .foregroundStyle(LeafIDTheme.onSurface.opacity(0.88))
                                .padding(.top, LeafIDTheme.space8)
                        }

                        HStack(spacing: LeafIDTheme.botanicalFrontStackSpacing) {
                            Text((scan.family ?? "UNCLASSIFIED").uppercased())
                                .font(LeafIDFont.manrope(size: 11, weight: .bold))
                                .tracking(1.4)
                                .foregroundStyle(LeafIDTheme.onPrimary)
                                .padding(.horizontal, LeafIDTheme.space10)
                                .padding(.vertical, LeafIDTheme.space6)
                                .background(Capsule().fill(LeafIDTheme.surfaceContainerHigh.opacity(0.8)))
                        }
                        .padding(.top, LeafIDTheme.botanicalFrontStackSpacing)
                        HStack(spacing: LeafIDTheme.space8) {
                            Image(systemName: "location.fill")
                                .font(.system(size: LeafIDTheme.botanicalFrontLocationSize, weight: .semibold))
                                .foregroundStyle(LeafIDTheme.primary)
                            Text(scan.botanicalOriginLine.uppercased())
                                .font(LeafIDFont.manrope(size: LeafIDTheme.botanicalFrontLocationSize, weight: .semibold))
                                .tracking(1.8)
                                .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                                .lineLimit(2)
                        }
                        if let lat = scan.latitude, let lon = scan.longitude {
                            Text(String(format: "GPS %.4f, %.4f", lat, lon))
                                .font(LeafIDFont.manrope(size: 12, weight: .semibold))
                                .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(rarityPillText)
                        .font(LeafIDFont.manrope(size: LeafIDTheme.botanicalFrontEyebrowSize, weight: .bold))
                        .tracking(0.6)
                        .foregroundStyle(LeafIDTheme.onPrimary)
                        .padding(.horizontal, LeafIDTheme.botanicalFrontRarityPaddingH)
                        .padding(.vertical, LeafIDTheme.botanicalFrontRarityPaddingV)
                        .background(Capsule().fill(LeafIDTheme.primary))
                        .shadow(color: LeafIDTheme.scanButtonShadowColor, radius: 20, y: 4)
                        .padding(.trailing, LeafIDTheme.botanicalFrontRarityInsetTrailing)
                        .offset(y: LeafIDTheme.botanicalFrontRarityOffsetY)
                }
                .padding(.horizontal, LeafIDTheme.botanicalFrontOverlayPaddingH)
                .padding(.bottom, LeafIDTheme.botanicalFrontOverlayPaddingBottom)
            }

            // top controls
            VStack {
                HStack {
                    GlassChromeCircleButton(systemImage: "xmark", accessibilityLabel: "Close", action: onClose)
                    Spacer(minLength: 0)
                    GlassChromeCircleButton(systemImage: "square.and.arrow.up", accessibilityLabel: "Share", action: onShare)
                }
                .padding(.top, LeafIDTheme.botanicalFrontCloseInsetTop)
                .padding(.horizontal, LeafIDTheme.botanicalFrontCloseInsetTrailing)
                Spacer(minLength: 0)
            }

            // `bottom-10` flip — primary circle, `p-4`, 24pt refresh icon, lime glow
            VStack {
                Spacer(minLength: 0)
                Button(action: onFlip) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: LeafIDTheme.botanicalFrontFlipIconSize, weight: .bold))
                        .foregroundStyle(LeafIDTheme.onPrimary)
                        .padding(LeafIDTheme.botanicalFrontFlipPadding)
                        .background(Circle().fill(LeafIDTheme.primary))
                        .shadow(color: LeafIDTheme.scanButtonShadowColor, radius: 20, y: 0)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Flip card")
                .padding(.bottom, LeafIDTheme.botanicalFrontFlipInsetBottom)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct BotanicalHeroMatchedGeometry: ViewModifier {
    var namespace: Namespace.ID?
    var id: UUID?

    func body(content: Content) -> some View {
        if let namespace, let id {
            content.matchedGeometryEffect(id: id, in: namespace, isSource: false)
        } else {
            content
        }
    }
}

// MARK: - Back (same shell / interior gutter as front overlay)

private struct BotanicalCardBackFace: View {
    let scan: Scan
    let enrichmentLoading: Bool

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: LeafIDTheme.space20) {
                HStack(alignment: .center, spacing: LeafIDTheme.space16) {
                    botanicalAvatar
                    VStack(alignment: .leading, spacing: LeafIDTheme.space6) {
                        Text(scan.scientificName)
                            .font(LeafIDFont.plusJakarta(size: 22, weight: .bold))
                            .foregroundStyle(LeafIDTheme.onSurface)
                            .lineLimit(3)
                        Text(scan.commonName.uppercased())
                            .font(LeafIDFont.manrope(size: 12, weight: .bold))
                            .tracking(1.6)
                            .foregroundStyle(LeafIDTheme.primary)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text("Main properties")
                    .font(LeafIDFont.manrope(size: 10, weight: .bold))
                    .tracking(2.2)
                    .foregroundStyle(LeafIDTheme.onSurfaceVariant)

                VStack(spacing: LeafIDTheme.space10) {
                    BotanicalPropertyGlassRow(
                        icon: "leaf",
                        label: "Type",
                        value: scan.botanicalTypeSummary
                    )
                    BotanicalPropertyGlassRow(
                        icon: "sun.max",
                        label: "Light",
                        value: displayOrDash(scan.sunExposure)
                    )
                    BotanicalPropertyGlassRow(
                        icon: "drop",
                        label: "Watering",
                        value: displayOrDash(scan.watering)
                    )
                }

                paletteSection

                narrativeBlock(title: "Botanical Spirit", text: scan.botanicalSpirit)
                narrativeBlock(title: "Ethnobotany", text: scan.ethnobotany)
                narrativeBlock(title: "Cultural Legacy", text: scan.culturalLegacy)
            }
            .padding(.horizontal, LeafIDTheme.botanicalFrontOverlayPaddingH)
            .padding(.top, LeafIDTheme.space20)
            .padding(.bottom, LeafIDTheme.space16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                LeafIDTheme.surfaceContainerLow
                LinearGradient(
                    colors: [
                        LeafIDTheme.surfaceContainerHigh.opacity(0.35),
                        LeafIDTheme.surface.opacity(0.9),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
    }

    private var botanicalAvatar: some View {
        ZStack {
            Circle()
                .strokeBorder(LeafIDTheme.primary.opacity(0.85), lineWidth: 2)
            ScanSpecimenPhotoFill(scan: scan)
                .frame(width: 52, height: 52)
                .clipShape(Circle())
        }
        .frame(width: 58, height: 58)
    }

    private var paletteSection: some View {
        return VStack(alignment: .leading, spacing: LeafIDTheme.space10) {
            Text("Designer Palette")
                .font(LeafIDFont.manrope(size: 10, weight: .bold))
                .tracking(2.0)
                .foregroundStyle(LeafIDTheme.primary)
            HStack(spacing: LeafIDTheme.space12) {
                ForEach((scan.normalizedPaletteHexes.isEmpty ? ["#2C4C1A", "#7AAE2E", "#6B4F2E"] : scan.normalizedPaletteHexes), id: \.self) { hex in
                    VStack(spacing: LeafIDTheme.space6) {
                        Circle()
                            .fill(colorFromHex(hex))
                            .frame(width: 32, height: 32)
                            .overlay {
                                Circle().strokeBorder(LeafIDTheme.outlineVariant.opacity(0.25), lineWidth: 1)
                            }
                        Text(hex)
                            .font(LeafIDFont.manrope(size: 10, weight: .semibold))
                            .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(LeafIDTheme.space20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.resultsSheetTop, style: .continuous)
                .fill(LeafIDTheme.primary.opacity(0.12))
        )
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.resultsSheetTop, style: .continuous)
                .strokeBorder(LeafIDTheme.primary.opacity(0.22), lineWidth: 1)
        }
    }

    private func narrativeBlock(title: String, text: String?) -> some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space10) {
            Text(title)
                .font(LeafIDFont.manrope(size: 10, weight: .bold))
                .tracking(2.0)
                .foregroundStyle(LeafIDTheme.primary)
            if enrichmentLoading {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(LeafIDTheme.surfaceContainerHigh.opacity(0.8))
                    .frame(height: 16)
                    .redacted(reason: .placeholder)
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(LeafIDTheme.surfaceContainerHigh.opacity(0.8))
                    .frame(height: 16)
                    .redacted(reason: .placeholder)
            } else {
                Text(displayOrFallback(text, fallback: scan.descriptionText))
                    .font(LeafIDFont.manrope(size: 15, weight: .medium))
                    .foregroundStyle(LeafIDTheme.onSurface)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(LeafIDTheme.space20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.resultsSheetTop, style: .continuous)
                .fill(LeafIDTheme.primary.opacity(0.12))
        )
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.resultsSheetTop, style: .continuous)
                .strokeBorder(LeafIDTheme.primary.opacity(0.22), lineWidth: 1)
        }
    }

    private func displayOrFallback(_ raw: String?, fallback: String?) -> String {
        let primary = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !primary.isEmpty { return primary }
        let backup = fallback?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !backup.isEmpty { return backup }
        return "Narrative context is still loading for this specimen."
    }

    private func displayOrDash(_ raw: String?) -> String {
        let t = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return t.isEmpty ? "—" : t
    }

    private func colorFromHex(_ raw: String) -> Color {
        let hex = raw.replacingOccurrences(of: "#", with: "")
        guard let int = UInt32(hex, radix: 16) else { return LeafIDTheme.primary }
        return Color(hex: int)
    }
}

// MARK: - Shared pieces

private struct BotanicalPropertyGlassRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: LeafIDTheme.space14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(LeafIDTheme.primary.opacity(0.95))
                .frame(width: 36, alignment: .center)
            Text(label)
                .font(LeafIDFont.manrope(size: 14, weight: .semibold))
                .foregroundStyle(LeafIDTheme.onSurfaceVariant)
            Spacer(minLength: 0)
            Text(value)
                .font(LeafIDFont.manrope(size: 14, weight: .semibold))
                .foregroundStyle(LeafIDTheme.onSurface)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, LeafIDTheme.space16)
        .padding(.vertical, LeafIDTheme.space14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.resultsSheetTop, style: .continuous)
                .fill(LeafIDTheme.surfaceContainerHigh.opacity(0.88))
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.resultsSheetTop, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.resultsSheetTop, style: .continuous)
                .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.1), lineWidth: 1)
        }
    }
}

private struct BotanicalCardPageIndicator: View {
    let showBack: Bool

    var body: some View {
        HStack(spacing: LeafIDTheme.space10) {
            Capsule()
                .fill(showBack ? LeafIDTheme.onSurfaceVariant.opacity(0.35) : LeafIDTheme.primary)
                .frame(width: 30, height: 4)
            Capsule()
                .fill(showBack ? LeafIDTheme.primary : LeafIDTheme.onSurfaceVariant.opacity(0.35))
                .frame(width: 30, height: 4)
        }
    }
}

private struct ScanSpecimenPhotoFill: View {
    let scan: Scan

    var body: some View {
        GeometryReader { geo in
            Group {
                #if canImport(UIKit)
                specimenUIKit(size: geo.size)
                #else
                placeholderLeaf
                #endif
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    #if canImport(UIKit)
    @ViewBuilder
    private func specimenUIKit(size _: CGSize) -> some View {
        if let local = scan.resolvedLocalCaptureURL,
           let data = try? Data(contentsOf: local),
           let ui = UIImage(data: data) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
        } else if let remote = scan.resolvedRemoteImageURL {
            AsyncImage(url: remote) { phase in
                switch phase {
                case .empty:
                    ProgressView().tint(LeafIDTheme.primary)
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholderLeaf
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            placeholderLeaf
        }
    }
    #endif

    private var placeholderLeaf: some View {
        ZStack {
            LeafIDTheme.specimenField
            Image(systemName: "leaf.fill")
                .font(.system(size: 56, weight: .thin))
                .foregroundStyle(LeafIDTheme.primary.opacity(0.55))
        }
    }
}
