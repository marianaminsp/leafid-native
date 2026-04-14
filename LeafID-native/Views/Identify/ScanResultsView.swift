//
//  ScanResultsView.swift
//  LeafID-native
//
//  `docs/ui-screens/ScanResults.png` + `design_system_build` (glass via material, ghost borders only, on-surface type).
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
private struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

// MARK: - Secondary CTA (matches `LeafPrimaryButton` metrics + `LeafIDTheme` radii)

private struct ScanResultsOutlineButton: View {
    let title: String
    var leadingSystemImage: String = "camera.viewfinder"
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: LeafIDTheme.space12) {
                Image(systemName: leadingSystemImage)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .tracking(0.4)
            }
            .foregroundStyle(LeafIDTheme.onSurface)
            .frame(maxWidth: .infinity)
            .padding(.vertical, LeafIDTheme.space16)
            .background(
                RoundedRectangle(cornerRadius: LeafIDTheme.radiusPrimaryButton, style: .continuous)
                    .fill(LeafIDTheme.surfaceContainerHigh.opacity(0.55))
            )
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: LeafIDTheme.radiusPrimaryButton, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: LeafIDTheme.radiusPrimaryButton, style: .continuous)
                    .strokeBorder(LeafIDTheme.outlineVariant.opacity(LeafIDTheme.liquidGlassBorderOpacity), lineWidth: 1)
            }
            .shadow(
                color: Color.black.opacity(LeafIDTheme.shadowButtonOpacity),
                radius: LeafIDTheme.shadowButtonRadius,
                y: LeafIDTheme.shadowButtonY
            )
            .scaleEffect(pressed ? 0.98 : 1)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.leafIDSpring) { pressed = true } }
                .onEnded { _ in withAnimation(.leafIDSpring) { pressed = false } }
        )
    }
}

// MARK: - Scan results

struct ScanResultsView: View {
    let result: IdentifyPreviewResult
    var imageJPEGData: Data?
    var onClose: () -> Void
    var onScanAgain: () -> Void

    @EnvironmentObject private var herbarium: HerbariumViewModel
    @State private var showShareSheet = false

    #if canImport(UIKit)
    private var backgroundImage: UIImage? {
        guard let imageJPEGData else { return nil }
        return UIImage(data: imageJPEGData)
    }
    #endif

    private var shareText: String {
        "\(result.commonName) — \(result.scientificName)\n\(result.descriptionText)"
    }

    private var familyLine: String {
        let f = result.family.trimmingCharacters(in: .whitespacesAndNewlines)
        if f.isEmpty { return "FAMILY" }
        return f.uppercased().contains("FAMILY") ? f.uppercased() : "\(f.uppercased()) FAMILY"
    }

    /// Plant.id–backed chips; empty strings are omitted.
    private var metadataChips: [(systemImage: String, title: String)] {
        var rows: [(String, String)] = []
        let sun = result.chipSunExposure.trimmingCharacters(in: .whitespacesAndNewlines)
        if !sun.isEmpty {
            rows.append(("sun.max.fill", "Sun exposure: \(sun)"))
        }
        let water = result.chipWatering.trimmingCharacters(in: .whitespacesAndNewlines)
        if !water.isEmpty {
            rows.append(("drop.fill", "Watering: \(water)"))
        }
        let phylum = result.chipPhylum.trimmingCharacters(in: .whitespacesAndNewlines)
        if !phylum.isEmpty {
            rows.append(("leaf.circle.fill", "Phylum: \(phylum)"))
        }
        return rows
    }

    private func resultsSheetShape() -> ResultsSheetTopRoundedShape {
        ResultsSheetTopRoundedShape(topCornerRadius: CornerRadius.resultsSheetTop)
    }

    var body: some View {
        GeometryReader { geo in
            let homeBottom = geo.safeAreaInsets.bottom

            ZStack {
                #if canImport(UIKit)
                Group {
                    if let backgroundImage {
                        Image(uiImage: backgroundImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                            .ignoresSafeArea()
                    } else {
                        LeafIDTheme.surface
                    }
                }
                #else
                LeafIDTheme.surface
                #endif

                VStack(spacing: 0) {
                    topChrome(geo)

                    Spacer(minLength: 0)

                    sheetPanel(maxHeight: geo.size.height * 0.62, homeIndicatorInset: homeBottom)
                }
            }
            .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
        #if canImport(UIKit)
        .sheet(isPresented: $showShareSheet) {
            let items: [Any] = {
                var a: [Any] = [shareText]
                if let imageJPEGData, let img = UIImage(data: imageJPEGData) {
                    a.insert(img, at: 0)
                }
                return a
            }()
            ActivityView(activityItems: items)
        }
        #endif
    }

    private func topChrome(_ geo: GeometryProxy) -> some View {
        ZStack {
            HStack {
                GlassChromeCircleButton(
                    systemImage: "chevron.left",
                    accessibilityLabel: "Back"
                ) {
                    onClose()
                }
                Spacer(minLength: 0)
                GlassChromeCircleButton(
                    systemImage: "square.and.arrow.up",
                    accessibilityLabel: "Share"
                ) {
                    showShareSheet = true
                }
            }
            MatchConfidenceBadge(confidence: result.confidence, useResultsTitle: true)
        }
        .padding(.top, geo.safeAreaInsets.top + LeafIDTheme.space8)
        .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
    }

    private func sheetPanel(maxHeight: CGFloat, homeIndicatorInset: CGFloat) -> some View {
        let shape = resultsSheetShape()
        let contentBottom = max(homeIndicatorInset, LeafIDTheme.space4)

        return VStack(spacing: 0) {
            Capsule()
                .fill(LeafIDTheme.onSurfaceVariant.opacity(0.4))
                .frame(width: 44, height: 5)
                .padding(.top, LeafIDTheme.space12)
                .padding(.bottom, LeafIDTheme.space8)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: LeafIDTheme.space16) {
                    HStack(alignment: .center, spacing: LeafIDTheme.space12) {
                        if result.isNewDiscovery {
                            Text("NEW DISCOVERY")
                                .font(LeafIDFont.manrope(size: 9, weight: .bold))
                                .tracking(2.2)
                                .foregroundStyle(LeafIDTheme.onPrimary)
                                .padding(.horizontal, LeafIDTheme.space10)
                                .padding(.vertical, LeafIDTheme.space6)
                                .background(
                                    Capsule()
                                        .fill(LeafIDTheme.primary)
                                )
                        }
                        Text(familyLine)
                            .font(LeafIDFont.manrope(size: 10, weight: .semibold))
                            .tracking(1.8)
                            .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }

                    Text(result.scientificName)
                        .font(LeafIDFont.plusJakarta(size: 28, weight: .bold))
                        .tracking(-0.4)
                        .foregroundStyle(LeafIDTheme.onSurface)

                    Text(result.commonName)
                        .font(LeafIDFont.plusJakarta(size: 18, weight: .medium))
                        .italic()
                        .foregroundStyle(LeafIDTheme.onSurface.opacity(0.92))

                    metadataChipsSection

                    Text(result.descriptionText)
                        .font(LeafIDFont.manrope(size: 15, weight: .medium))
                        .foregroundStyle(LeafIDTheme.onSurface.opacity(0.88))
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(LeafIDTheme.space4)

                    if !BotanyService.isPlantIdentificationLive {
                        Text("Demo mode: connect Supabase (`identify-plant` + Plant.id) for live results.")
                            .font(LeafIDFont.manrope(size: 11, weight: .semibold))
                            .foregroundStyle(LeafIDTheme.primary.opacity(0.85))
                            .padding(.vertical, LeafIDTheme.space6)
                    }

                    LeafPrimaryButton(
                        title: "Save to Herbarium",
                        leadingSystemImage: "leaf.fill",
                        useSolidPrimaryFill: true
                    ) {
                        _ = BotanyService.saveUserCapture(
                            result: result,
                            imageJPEGData: imageJPEGData,
                            herbarium: herbarium
                        )
                        onClose()
                    }
                    .padding(.top, LeafIDTheme.space4)

                    ScanResultsOutlineButton(title: "Scan another specimen") {
                        onScanAgain()
                    }
                }
                .padding(.horizontal, LeafIDTheme.space24)
                .padding(.bottom, contentBottom)
            }
            .frame(maxHeight: maxHeight)
        }
        .frame(maxWidth: .infinity)
        .background {
            shape
                .fill(.ultraThinMaterial)
        }
        .background {
            shape
                .fill(LeafIDTheme.surfaceContainerLow.opacity(0.22))
        }
        .overlay {
            shape
                .stroke(LeafIDTheme.outlineVariant.opacity(LeafIDTheme.liquidGlassBorderOpacity), lineWidth: 1)
        }
        .clipShape(shape)
        .ignoresSafeArea(edges: .bottom)
    }

    @ViewBuilder
    private var metadataChipsSection: some View {
        let chips = metadataChips
        if chips.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: LeafIDTheme.space10) {
                HStack(alignment: .top, spacing: LeafIDTheme.space10) {
                    ForEach(Array(chips.prefix(2).enumerated()), id: \.offset) { _, chip in
                        resultTagPill(systemImage: chip.systemImage, title: chip.title)
                    }
                }
                if chips.count > 2 {
                    HStack(alignment: .top, spacing: LeafIDTheme.space10) {
                        resultTagPill(systemImage: chips[2].systemImage, title: chips[2].title)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private func resultTagPill(systemImage: String, title: String) -> some View {
        HStack(spacing: LeafIDTheme.space8) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(LeafIDTheme.primary)
            Text(title)
                .font(LeafIDFont.manrope(size: 11, weight: .semibold))
                .foregroundStyle(LeafIDTheme.onSurface.opacity(0.9))
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, LeafIDTheme.space12)
        .padding(.vertical, LeafIDTheme.space10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LeafIDTheme.surfaceContainerHigh.opacity(0.4))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: LeafIDTheme.radiusSpecimenThumb, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: LeafIDTheme.radiusSpecimenThumb, style: .continuous)
                .strokeBorder(LeafIDTheme.outlineVariant.opacity(LeafIDTheme.liquidGlassBorderOpacity), lineWidth: 1)
        }
    }
}
