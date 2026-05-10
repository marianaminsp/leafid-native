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
#if canImport(CoreLocation)
import CoreLocation
#endif

#if canImport(CoreLocation)
private enum ScanResultsGeo {
    static func reverseGeocodeCity(latitude: Double, longitude: Double) async -> String? {
        await withCheckedContinuation { continuation in
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(CLLocation(latitude: latitude, longitude: longitude)) { placemarks, _ in
                let name: String? = {
                    guard let p = placemarks?.first else { return nil }
                    if let s = p.locality?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty { return s }
                    if let s = p.subLocality?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty { return s }
                    return nil
                }()
                continuation.resume(returning: name)
            }
        }
    }
}
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
    var captureLatitude: Double? = nil
    var captureLongitude: Double? = nil
    /// Device locality from `CLLocationManager` + reverse geocode at pick/capture time, when available.
    var captureLocality: String? = nil
    var onClose: () -> Void
    var onScanAgain: () -> Void

    @EnvironmentObject private var herbarium: HerbariumViewModel
    @State private var showShareSheet = false
    @State private var showSaveFailureAlert = false
    #if canImport(UIKit)
    @State private var immersivePreviewScan: Scan?
    @State private var immersivePreviewFilePath: String?
    @State private var previewPlaceLine: String = ""
    @State private var previewGPSLine: String = ""
    #endif

    /// Saving requires non-empty JPEG bytes and a successful write under `Documents/captures/`.
    private var canSaveToHerbarium: Bool {
        guard let imageJPEGData, !imageJPEGData.isEmpty else { return false }
        return true
    }

    #if canImport(UIKit)
    private var backgroundImage: UIImage? {
        guard let imageJPEGData else { return nil }
        return UIImage(data: imageJPEGData)
    }
    #endif

    private var shareText: String {
        "\(displayCommonName) — \(displayScientificTitle)\n\(result.descriptionText)"
    }

    private var familyLine: String {
        let f = result.family.trimmingCharacters(in: .whitespacesAndNewlines)
        if f.isEmpty { return "FAMILY" }
        return f.uppercased().contains("FAMILY") ? f.uppercased() : "\(f.uppercased()) FAMILY"
    }

    private var isFallbackResult: Bool { result.usedFallback }

    private var displayScientificTitle: String {
        if isFallbackResult { return "Exploring Specimen..." }
        return result.scientificName
    }

    private var displayCommonName: String {
        if isFallbackResult { return "Analyzing..." }
        return result.commonName.localizedCapitalized
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

    #if canImport(UIKit)
    @MainActor
    private func refreshPreviewCaptureContext() async {
        #if canImport(ImageIO)
        guard let data = imageJPEGData, !data.isEmpty else {
            let preset = captureLocality?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !preset.isEmpty {
                previewPlaceLine = preset
            } else {
                let loc = result.locationLabel.trimmingCharacters(in: .whitespacesAndNewlines)
                previewPlaceLine = BotanyService.isWeakCaptureLocationString(loc) ? "" : loc
            }
            previewGPSLine = ""
            return
        }
        let exif = BotanyService.readCaptureMetadata(fromJPEGData: data)
        let mergedLat = captureLatitude ?? exif.coordinate?.latitude
        let mergedLon = captureLongitude ?? exif.coordinate?.longitude

        let presetLocality = captureLocality?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        var place = ""
        if !presetLocality.isEmpty { place = presetLocality }
        let iptc = exif.iptcPlacemarkLine?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if place.isEmpty, !iptc.isEmpty {
            let parts = iptc.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            place = parts.first.map { String($0) } ?? iptc
        }
        if place.isEmpty {
            let loc = result.locationLabel.trimmingCharacters(in: .whitespacesAndNewlines)
            if !BotanyService.isWeakCaptureLocationString(loc) { place = loc }
        }

        if let la = mergedLat, let lo = mergedLon {
            #if canImport(CoreLocation)
            if place.isEmpty, let city = await ScanResultsGeo.reverseGeocodeCity(latitude: la, longitude: lo) {
                place = city
            }
            #endif
            previewGPSLine = BotanyService.formatCardinalGPS(latitude: la, longitude: lo)
        } else {
            previewGPSLine = ""
        }
        previewPlaceLine = place
        #else
        let presetNoImageIO = captureLocality?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !presetNoImageIO.isEmpty {
            previewPlaceLine = presetNoImageIO
        } else {
            let loc = result.locationLabel.trimmingCharacters(in: .whitespacesAndNewlines)
            previewPlaceLine = BotanyService.isWeakCaptureLocationString(loc) ? "" : loc
        }
        if let la = captureLatitude, let lo = captureLongitude {
            previewGPSLine = BotanyService.formatCardinalGPS(latitude: la, longitude: lo)
        } else {
            previewGPSLine = ""
        }
        #endif
    }

    @ViewBuilder
    private var previewCaptureMetadataRow: some View {
        if previewPlaceLine.isEmpty && previewGPSLine.isEmpty {
            EmptyView()
        } else {
            HStack(alignment: .firstTextBaseline, spacing: LeafIDTheme.space8) {
                if !previewPlaceLine.isEmpty {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 10, weight: .semibold))
                    Text(previewPlaceLine)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
                if !previewGPSLine.isEmpty {
                    if !previewPlaceLine.isEmpty {
                        Text("·")
                            .opacity(0.75)
                    }
                    Text(previewGPSLine)
                        .font(LeafIDFont.manrope(size: 10, weight: .medium))
                        .monospaced()
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .font(LeafIDFont.manrope(size: 11, weight: .medium))
            .foregroundStyle(LeafIDTheme.onSurfaceVariant.opacity(0.6))
        }
    }

    @ViewBuilder
    private var highConfidenceMatchBadge: some View {
        if result.confidence >= 0.85 {
            HStack(spacing: LeafIDTheme.space6) {
                if result.confidence >= 0.92 {
                    Text(String(localized: "High confidence"))
                        .font(LeafIDFont.manrope(size: 10, weight: .bold))
                        .tracking(0.5)
                }
                Text("\(Int((result.confidence * 100).rounded()))% match")
                    .font(LeafIDFont.manrope(size: 10, weight: .semibold))
            }
            .foregroundStyle(LeafIDTheme.primary.opacity(0.95))
            .padding(.horizontal, LeafIDTheme.space10)
            .padding(.vertical, LeafIDTheme.space6)
            .background(
                Capsule(style: .continuous)
                    .fill(LeafIDTheme.primary.opacity(0.14))
            )
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(LeafIDTheme.primary.opacity(0.28), lineWidth: 1)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                "Match confidence \(Int((result.confidence * 100).rounded())) percent"
            )
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var fallbackLowConfidenceBadge: some View {
        if isFallbackResult {
            HStack(spacing: LeafIDTheme.space6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10, weight: .bold))
                Text("Low Confidence")
                    .font(LeafIDFont.manrope(size: 10, weight: .bold))
                    .tracking(0.6)
            }
            .foregroundStyle(Color.orange.opacity(0.95))
            .padding(.horizontal, LeafIDTheme.space10)
            .padding(.vertical, LeafIDTheme.space6)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.orange.opacity(0.14))
            )
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(Color.orange.opacity(0.28), lineWidth: 1)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Low confidence fallback result")
        }
    }
    #endif

    var body: some View {
        GeometryReader { geo in
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

                    sheetPanel(geo: geo)
                }
            }
            .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
        #if canImport(UIKit)
        .task {
            await refreshPreviewCaptureContext()
        }
        #endif
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
        .alert(
            String(localized: "Couldn’t save to Herbarium"),
            isPresented: $showSaveFailureAlert
        ) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            Text(String(localized: "The specimen photo couldn’t be written to disk. Check storage permissions and try again."))
        }
        #if canImport(UIKit)
        .fullScreenCover(item: $immersivePreviewScan, onDismiss: {
            BotanyService.deleteImmersivePreviewCaptureFileIfNeeded(path: immersivePreviewFilePath)
            immersivePreviewFilePath = nil
        }) { scan in
            BotanicalCardImmersiveView(
                scan: scan,
                preview: result,
                onClose: { immersivePreviewScan = nil }
            )
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
            if isFallbackResult {
                fallbackLowConfidenceBadge
            } else {
                MatchConfidenceBadge(confidence: result.confidence, useResultsTitle: true)
            }
        }
        .padding(.top, geo.safeAreaInsets.top + LeafIDTheme.space8)
        .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
    }

    private func sheetPanelDragHandle() -> some View {
        Capsule()
            .fill(LeafIDTheme.onSurfaceVariant.opacity(0.4))
            .frame(width: 44, height: 5)
            .padding(.top, LeafIDTheme.space8)
            .padding(.bottom, LeafIDTheme.space6)
    }

    @ViewBuilder
    private func sheetPanelScrollStack(sheetHorizontalInset: CGFloat, contentBottom: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space12) {
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
                fallbackLowConfidenceBadge
            }

            #if canImport(UIKit)
            sheetSpecimenPreviewButton()
            #else
            Text(displayScientificTitle)
                .font(LeafIDFont.plusJakarta(size: 28, weight: .bold))
                .tracking(-0.4)
                .foregroundStyle(LeafIDTheme.onSurface)

            Text(displayCommonName)
                .font(LeafIDFont.plusJakarta(size: 18, weight: .medium))
                .italic()
                .foregroundStyle(LeafIDTheme.onSurface.opacity(0.92))
            #endif

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
                isEnabled: canSaveToHerbarium,
                useSolidPrimaryFill: true
            ) {
                Task {
                    let saved = await BotanyService.saveUserCapture(
                        result: result,
                        imageJPEGData: imageJPEGData,
                        captureLatitude: captureLatitude,
                        captureLongitude: captureLongitude,
                        captureLocality: captureLocality,
                        herbarium: herbarium
                    )
                    if saved != nil {
                        #if canImport(UIKit)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        #endif
                        onClose()
                    } else {
                        #if canImport(UIKit)
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                        #endif
                        showSaveFailureAlert = true
                    }
                }
            }
            .padding(.top, LeafIDTheme.space4)

            if !canSaveToHerbarium {
                Text(String(localized: "Add a photo before saving — capture data is missing."))
                    .font(LeafIDFont.manrope(size: 12, weight: .medium))
                    .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ScanResultsOutlineButton(title: "Scan another specimen") {
                onScanAgain()
            }
        }
        .padding(.horizontal, sheetHorizontalInset)
        .padding(.bottom, contentBottom)
    }

    #if canImport(UIKit)
    @ViewBuilder
    private func sheetSpecimenPreviewButton() -> some View {
        Button {
            Task {
                let scan = await BotanyService.buildImmersivePreviewScan(
                    result: result,
                    imageJPEGData: imageJPEGData,
                    captureLatitude: captureLatitude,
                    captureLongitude: captureLongitude,
                    captureLocality: captureLocality
                )
                await MainActor.run {
                    if let scan {
                        immersivePreviewFilePath = scan.resolvedLocalCaptureFilePath
                        immersivePreviewScan = scan
                    }
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: LeafIDTheme.space6) {
                Text(displayScientificTitle)
                    .font(LeafIDFont.plusJakarta(size: 28, weight: .bold))
                    .tracking(-0.4)
                    .foregroundStyle(LeafIDTheme.onSurface)
                    .multilineTextAlignment(.leading)

                previewCaptureMetadataRow

                Text(displayCommonName)
                    .font(LeafIDFont.plusJakarta(size: 18, weight: .medium))
                    .italic()
                    .foregroundStyle(LeafIDTheme.onSurface.opacity(0.92))
                    .multilineTextAlignment(.leading)

                highConfidenceMatchBadge
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "Specimen summary"))
        .accessibilityHint(String(localized: "Opens the full specimen card"))
    }
    #endif

    private func sheetPanel(geo: GeometryProxy) -> some View {
        let shape = resultsSheetShape()
        let sheetHorizontalInset = LeafIDTheme.space16
        /// Tight to safe area: 8pt above home indicator / bottom inset.
        let contentBottom = geo.safeAreaInsets.bottom + 8
        let scrollMaxHeight = max(
            260,
            geo.size.height - geo.safeAreaInsets.top - geo.safeAreaInsets.bottom - 96
        )

        return VStack(spacing: 0) {
            sheetPanelDragHandle()
            ViewThatFits(in: .vertical) {
                sheetPanelScrollStack(
                    sheetHorizontalInset: sheetHorizontalInset,
                    contentBottom: contentBottom
                )
                ScrollView(.vertical, showsIndicators: false) {
                    sheetPanelScrollStack(
                        sheetHorizontalInset: sheetHorizontalInset,
                        contentBottom: contentBottom
                    )
                }
                .frame(maxHeight: scrollMaxHeight)
            }
        }
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
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
