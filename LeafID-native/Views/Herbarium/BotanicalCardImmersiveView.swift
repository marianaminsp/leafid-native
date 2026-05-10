//
//  BotanicalCardImmersiveView.swift
//  LeafID-native
//
//  New immersive boutique card variant (non-destructive: original card remains untouched).
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(CoreLocation)
import CoreLocation
#endif

struct BotanicalCardImmersiveView: View {
    let scan: Scan
    var preview: IdentifyPreviewResult? = nil
    var namespace: Namespace.ID? = nil
    var matchedGeometryId: UUID? = nil
    var onClose: () -> Void = {}

    @State private var isFlipped = false
    @State private var showShareSheet = false
    @State private var immersiveDismissDrag: CGFloat = 0
    /// GPS row: coordinates read **only** from the saved JPEG/HEIC EXIF (nil when absent).
    @State private var exifGPSCoordinate: (latitude: Double, longitude: Double)?
    /// City / place where the photo was taken (IPTC, `Scan.location`, preview labels, reverse geocode).
    @State private var resolvedPhotoPlace: String = ""
    /// Country where the capture was taken (reverse geocode `CLPlacemark.country`, then fallbacks).
    @State private var resolvedPhotoCountryName: String = ""
    @State private var resolvedPhotoISOCountryCode: String?
    @State private var culturalLegacyDisplay: String = ""

    private func isUsableOriginString(_ raw: String?) -> String? {
        let t = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let lowered = t.lowercased()
        guard !t.isEmpty, t != "—", lowered != "origin under review", lowered != "not provided", lowered != "unknown" else {
            return nil
        }
        return t
    }

    /// Where the photo was taken — maps preview `locationLabel` / `originCountry` and stored `Scan.location`, avoiding weak Plant.id copy.
    private var fallbackPhotoPlaceLine: String {
        let ordered = [
            preview?.locationLabel,
            scan.location,
            preview?.originCountry,
            scan.originCountry,
        ]
        for c in ordered {
            if let t = c?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty,
               !BotanyService.isWeakCaptureLocationString(t) {
                return t
            }
        }
        for c in ordered {
            let t = c?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !t.isEmpty { return BotanyService.displaySafeLocation(t) }
        }
        return BotanyService.displaySafeLocation(nil)
    }

    private var mergedPaletteHexes: [String] {
        let candidates = (scan.normalizedPaletteHexes + (preview?.paletteHexes ?? []))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
            .filter { !$0.isEmpty }
            .map { $0.hasPrefix("#") ? $0 : "#\($0)" }
        var merged: [String] = []
        for hex in candidates where isValidHex(hex) {
            if !merged.contains(hex) { merged.append(hex) }
            if merged.count == 3 { return merged }
        }
        let fallback = ["#2C4C1A", "#7AAE2E", "#6B4F2E"]
        for hex in fallback where merged.count < 3 {
            if !merged.contains(hex) { merged.append(hex) }
        }
        return Array(merged.prefix(3))
    }

    private var mergedSpirit: String {
        let candidates = [scan.botanicalSpirit, preview?.botanicalSpirit, scan.descriptionText]
        for c in candidates {
            let t = c?.trimmingCharacters(in: .whitespacesAndNewlines.union(.newlines)) ?? ""
            if !t.isEmpty { return t }
        }
        return "A resilient specimen whose form follows light, patience, and adaptation."
    }

    private var mergedEthnobotany: String {
        let candidates = [scan.ethnobotany, preview?.ethnobotany]
        for c in candidates {
            let t = c?.trimmingCharacters(in: .whitespacesAndNewlines.union(.newlines)) ?? ""
            if !t.isEmpty { return t }
        }
        let family = (scan.family ?? "botanical")
        return "Traditionally cultivated across communities for ornamental and practical horticultural use in \(family)-linked gardens."
    }

    private var mergedCulturalLegacy: String {
        BotanyService.mergedCulturalLegacy(scan: scan, preview: preview)
    }

    private var photoPlaceLineForFront: String {
        let trimmed = resolvedPhotoPlace.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, !BotanyService.isWeakCaptureLocationString(trimmed) { return trimmed }
        return fallbackPhotoPlaceLine
    }

    private var photoCountryLineForFront: String {
        let trimmed = resolvedPhotoCountryName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        if let last = ImmersiveCardGeo.countryFromCommaListLastSegment(photoPlaceLineForFront) { return last }
        if let o = isUsableOriginString(preview?.originCountry) ?? isUsableOriginString(scan.originCountry) { return o }
        return BotanyService.displaySafeOrigin(nil)
    }

    /// City / first segment of place line when building an origin string.
    private var cityLineForFront: String {
        let raw = photoPlaceLineForFront.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return "" }
        let parts = raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        if let first = parts.first { return String(first) }
        return raw
    }

    /// Origin from capture metadata / geocode: city and country when both differ from the full line.
    private var originLineForFront: String {
        let city = cityLineForFront.trimmingCharacters(in: .whitespacesAndNewlines)
        let country = photoCountryLineForFront.trimmingCharacters(in: .whitespacesAndNewlines)
        if !city.isEmpty, !country.isEmpty, city.caseInsensitiveCompare(country) != .orderedSame {
            return "\(city), \(country)"
        }
        let full = photoPlaceLineForFront.trimmingCharacters(in: .whitespacesAndNewlines)
        if !full.isEmpty { return full }
        if !country.isEmpty { return country }
        return city
    }

    /// EXIF GPS if present, else coordinates on the scan from capture / upload.
    private var displayCaptureCoordinate: (latitude: Double, longitude: Double)? {
        if let e = exifGPSCoordinate { return e }
        if let la = scan.latitude, let lo = scan.longitude { return (latitude: la, longitude: lo) }
        return nil
    }

    var body: some View {
        GeometryReader { geo in
            let horizontalCardInset: CGFloat = 0
            let cardWidth = geo.size.width - (2 * horizontalCardInset)
            let topPad = geo.safeAreaInsets.top + 4
            let bottomGap: CGFloat = 0
            #if canImport(UIKit)
            let screenH = UIScreen.main.bounds.height
            #else
            let screenH = geo.size.height
            #endif
            let desiredCardH = screenH * 0.92
            let maxCardH = geo.size.height - topPad - bottomGap
            let cardHeight = max(320, min(desiredCardH, maxCardH))
            let bodyContentHeight = max(220, cardHeight - ImmersiveCardActionLayout.footerHeight)

            ZStack(alignment: .top) {
                LeafIDTheme.surface.ignoresSafeArea()

                ZStack {
                    CardBodyView(
                        scan: scan,
                        isFlipped: isFlipped,
                        contentHeight: bodyContentHeight,
                        originPhotoLine: originLineForFront,
                        captureCoordinate: displayCaptureCoordinate,
                        paletteHexes: mergedPaletteHexes,
                        spiritText: mergedSpirit,
                        ethnobotanyText: mergedEthnobotany,
                        culturalLegacyText: mergedCulturalLegacy
                    )
                    .frame(width: cardWidth, height: bodyContentHeight)
                    .frame(width: cardWidth, height: cardHeight, alignment: .top)
                    .rotation3DEffect(
                        .degrees(isFlipped ? 180 : 0),
                        axis: (x: 0, y: 1, z: 0),
                        anchor: .center,
                        anchorZ: 0,
                        perspective: 6
                    )
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.immersive, style: .continuous))
                    .clipped()
                    .overlay {
                        RoundedRectangle(cornerRadius: CornerRadius.immersive, style: .continuous)
                            .strokeBorder(LeafIDTheme.outlineVariant.opacity(LeafIDTheme.botanicalCardBorderOpacity), lineWidth: 1)
                    }
                    .animation(.spring(response: 0.55, dampingFraction: 0.72), value: isFlipped)

                    CardShellView(
                        isFlipped: isFlipped,
                        onClose: onClose,
                        onShare: { showShareSheet = true },
                        onFlip: triggerFlip
                    )
                    .frame(width: cardWidth, height: cardHeight)
                    .zIndex(24)
                }
                .frame(width: cardWidth, height: cardHeight)
                .padding(.top, topPad)
                .frame(maxWidth: .infinity, alignment: .top)
                .offset(y: immersiveDismissDrag)
                .gesture(
                    DragGesture(minimumDistance: 28)
                        .onChanged { value in
                            let dy = value.translation.height
                            let dx = value.translation.width
                            guard dy > 0, abs(dx) < dy + 24 else { return }
                            immersiveDismissDrag = dy
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 110
                            let endY = value.predictedEndTranslation.height
                            let shouldClose = value.translation.height > threshold || endY > 170
                            if shouldClose {
                                onClose()
                            }
                            immersiveDismissDrag = 0
                        }
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .task(id: scan.id) {
            await resolvePhotoPlaceAndCoordinates()
        }
        .task(id: scan.id) {
            let base = BotanyService.mergedCulturalLegacy(scan: scan, preview: preview)
            culturalLegacyDisplay = base
            culturalLegacyDisplay = await BotanyService.enrichCulturalLegacyDisplay(
                scan: scan,
                preview: preview,
                baseline: base
            )
        }
        #if canImport(UIKit)
        .sheet(isPresented: $showShareSheet) {
            let items: [Any] = {
                var all: [Any] = ["\(scan.commonName) — \(scan.scientificName)"]
                if let image = scan.uiImageForLocalCaptureShare() {
                    all.insert(image, at: 0)
                }
                return all
            }()
            BotanicalImmersiveActivityView(activityItems: items)
        }
        #endif
        .preferredColorScheme(.dark)
    }

    private func triggerFlip() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
            isFlipped.toggle()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
        }
    }

    @MainActor
    private func resolvePhotoPlaceAndCoordinates() async {
        exifGPSCoordinate = nil
        resolvedPhotoCountryName = ""
        resolvedPhotoISOCountryCode = nil
        var geocodeLat: Double?
        var geocodeLon: Double?
        #if canImport(UIKit) && canImport(ImageIO)
        if let url = scan.resolvedLocalCaptureURL {
            let meta = BotanyService.readCaptureMetadata(fromFileURL: url)
            if let c = meta.coordinate {
                exifGPSCoordinate = (latitude: c.latitude, longitude: c.longitude)
                geocodeLat = c.latitude
                geocodeLon = c.longitude
            }
            if let iptc = meta.iptcPlacemarkLine?.trimmingCharacters(in: .whitespacesAndNewlines), !iptc.isEmpty {
                resolvedPhotoPlace = iptc
            }
        }
        #endif
        if geocodeLat == nil, let la = scan.latitude, let lo = scan.longitude {
            geocodeLat = la
            geocodeLon = lo
        }
        if resolvedPhotoPlace.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            resolvedPhotoPlace = fallbackPhotoPlaceLine
        }
        #if canImport(CoreLocation)
        if let la = geocodeLat, let lo = geocodeLon {
            let geo = await reverseGeocodeDetails(latitude: la, longitude: lo)
            if BotanyService.isWeakCaptureLocationString(resolvedPhotoPlace),
               let cap = geo.captionLine?.trimmingCharacters(in: .whitespacesAndNewlines), !cap.isEmpty {
                resolvedPhotoPlace = cap
            }
            if let country = geo.countryName?.trimmingCharacters(in: .whitespacesAndNewlines), !country.isEmpty {
                resolvedPhotoCountryName = country
            }
            resolvedPhotoISOCountryCode = geo.isoCountryCode
        }
        #endif
    }

    #if canImport(CoreLocation)
    private struct ImmersiveReverseGeocodeResult {
        var captionLine: String?
        var countryName: String?
        var isoCountryCode: String?
    }

    private func reverseGeocodeDetails(latitude: Double, longitude: Double) async -> ImmersiveReverseGeocodeResult {
        await withCheckedContinuation { continuation in
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(CLLocation(latitude: latitude, longitude: longitude)) { placemarks, _ in
                guard let placemark = placemarks?.first else {
                    continuation.resume(returning: ImmersiveReverseGeocodeResult(captionLine: nil, countryName: nil, isoCountryCode: nil))
                    return
                }
                let city = placemark.locality?.trimmingCharacters(in: .whitespacesAndNewlines)
                let country = placemark.country?.trimmingCharacters(in: .whitespacesAndNewlines)
                let caption: String? = {
                    if let c = city, !c.isEmpty, let co = country, !co.isEmpty { return "\(c), \(co)" }
                    if let c = city, !c.isEmpty { return c }
                    if let co = country, !co.isEmpty { return co }
                    let sub = placemark.subLocality?.trimmingCharacters(in: .whitespacesAndNewlines)
                    let region = placemark.administrativeArea?.trimmingCharacters(in: .whitespacesAndNewlines)
                    var parts: [String] = []
                    if let s = sub, !s.isEmpty { parts.append(s) }
                    if let r = region, !r.isEmpty { parts.append(r) }
                    return parts.isEmpty ? nil : parts.joined(separator: ", ")
                }()
                let iso = placemark.isoCountryCode?.trimmingCharacters(in: .whitespacesAndNewlines)
                continuation.resume(
                    returning: ImmersiveReverseGeocodeResult(
                        captionLine: caption,
                        countryName: country,
                        isoCountryCode: (iso?.isEmpty == false) ? iso : nil
                    )
                )
            }
        }
    }
    #endif

    private func isValidHex(_ value: String) -> Bool {
        let t = value.replacingOccurrences(of: "#", with: "")
        return t.count == 6 && t.range(of: "^[0-9A-F]{6}$", options: .regularExpression) != nil
    }
}

private enum ImmersiveCardGeo {
    /// When geocode country is missing, use the last comma-separated segment (often the country).
    static func countryFromCommaListLastSegment(_ line: String) -> String? {
        let parts = line.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard parts.count >= 2, let last = parts.last else { return nil }
        return String(last)
    }

    static func flagEmoji(fromISOCountryCode code: String?) -> String {
        guard let code = code?.trimmingCharacters(in: .whitespacesAndNewlines), code.count == 2 else { return "" }
        let upper = code.uppercased()
        var scalars = String.UnicodeScalarView()
        for v in upper.unicodeScalars {
            guard (65...90).contains(v.value) else { return "" }
            if let regional = UnicodeScalar(0x1F1E6 + (v.value - 65)) {
                scalars.append(regional)
            } else {
                return ""
            }
        }
        return String(scalars)
    }
}

/// Shared geometry for the floating action row on the immersive card.
/// Keeping this in one place prevents front/back drift and overlap regressions.
private enum ImmersiveCardActionLayout {
    static let buttonDiameter: CGFloat = 44
    static let footerTopPadding: CGFloat = 10
    static let footerBottomPadding: CGFloat = 14
    static var footerHeight: CGFloat {
        footerTopPadding + buttonDiameter + footerBottomPadding
    }
}

private struct CardShellView: View {
    let isFlipped: Bool
    let onClose: () -> Void
    let onShare: () -> Void
    let onFlip: () -> Void
    private let bottomScrimHeight: CGFloat = 120

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer(minLength: 0)
                GlassChromeCircleButton(systemImage: "xmark", accessibilityLabel: "Close", action: onClose)
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)
            .zIndex(32)

            Spacer(minLength: 0)
                .allowsHitTesting(false)

            ZStack(alignment: .bottom) {
                if isFlipped {
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: LeafIDTheme.surface.opacity(0.00), location: 0.00),
                            .init(color: LeafIDTheme.surface.opacity(0.00), location: 0.58),
                            .init(color: LeafIDTheme.surface.opacity(0.22), location: 0.78),
                            .init(color: LeafIDTheme.surface.opacity(0.58), location: 0.90),
                            .init(color: LeafIDTheme.surface.opacity(0.90), location: 1.00),
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: bottomScrimHeight)
                    .allowsHitTesting(false)
                }

                HStack(spacing: LeafIDTheme.space16) {
                    Spacer(minLength: 0)
                    GlassChromeCircleButton(systemImage: "square.and.arrow.up", accessibilityLabel: "Share", action: onShare)
                    GlassChromeCircleButton(
                        systemImage: "arrow.right.circle",
                        accessibilityLabel: isFlipped ? "View specimen photo" : "View card back",
                        action: onFlip
                    )
                    Spacer(minLength: 0)
                }
                .padding(.bottom, ImmersiveCardActionLayout.footerBottomPadding)
            }
            .frame(maxWidth: .infinity)
            .frame(height: ImmersiveCardActionLayout.footerHeight)
            .zIndex(32)
        }
    }
}

private struct CardBodyView: View {
    let scan: Scan
    let isFlipped: Bool
    let contentHeight: CGFloat
    let originPhotoLine: String
    var captureCoordinate: (latitude: Double, longitude: Double)?
    let paletteHexes: [String]
    let spiritText: String
    let ethnobotanyText: String
    let culturalLegacyText: String

    var body: some View {
        ZStack {
            CardFrontView(
                scan: scan,
                originPhotoLine: originPhotoLine,
                captureCoordinate: captureCoordinate
            )
            .frame(maxWidth: .infinity)
            .frame(height: contentHeight)
            .contentShape(Rectangle())
            .opacity(isFlipped ? 0 : 1)

            CardBackView(
                scan: scan,
                paletteHexes: paletteHexes,
                spiritText: spiritText,
                ethnobotanyText: ethnobotanyText,
                culturalLegacyText: culturalLegacyText
            )
            .frame(maxWidth: .infinity)
            .frame(height: contentHeight)
            .contentShape(Rectangle())
            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            .opacity(isFlipped ? 1 : 0)
        }
    }
}

private struct CardFrontView: View {
    let scan: Scan
    let originPhotoLine: String
    var captureCoordinate: (latitude: Double, longitude: Double)?

    private var commonNameTitleCase: String {
        scan.commonName.localizedCapitalized
    }

    var body: some View {
        GeometryReader { g in
            let halfH = g.size.height * 0.5
            ZStack(alignment: .bottom) {
                #if canImport(UIKit)
                Group {
                    specimenUIKit(scan: scan)
                }
                .aspectRatio(contentMode: .fill)
                .frame(width: g.size.width, height: g.size.height)
                .clipped()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                #else
                LeafIDTheme.surfaceContainerLow
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                #endif

                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    LinearGradient(
                        stops: [
                            .init(color: Color.clear, location: 0),
                            .init(color: LeafIDTheme.surface.opacity(0.9), location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: halfH)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: LeafIDTheme.space12) {
                    Text(commonNameTitleCase)
                        .font(LeafIDFont.plusJakarta(size: 44, weight: .bold))
                        .foregroundStyle(LeafIDTheme.onSurface)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)

                    Text(scan.scientificName)
                        .font(LeafIDFont.manrope(size: 17, weight: .medium))
                        .italic()
                        .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                        .lineLimit(2)

                    if !originPhotoLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        HStack(alignment: .top, spacing: LeafIDTheme.space8) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(LeafIDTheme.onSurface.opacity(0.9))
                            Text(originPhotoLine)
                                .font(LeafIDFont.manrope(size: 14, weight: .semibold))
                                .foregroundStyle(LeafIDTheme.onSurface)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(2)
                        }
                    }

                    if let coord = captureCoordinate {
                        Text(BotanyService.formatCardinalGPS(latitude: coord.latitude, longitude: coord.longitude))
                            .font(LeafIDFont.manrope(size: 12, weight: .medium))
                            .monospaced()
                            .foregroundStyle(LeafIDTheme.onSurfaceVariant.opacity(0.85))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 110)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct CardBackView: View {
    let scan: Scan
    let paletteHexes: [String]
    let spiritText: String
    let ethnobotanyText: String
    let culturalLegacyText: String
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: LeafIDTheme.space16) {
                ImmersiveSpecimenFill(scan: scan)
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay {
                        Circle().strokeBorder(LeafIDTheme.outlineVariant.opacity(0.3), lineWidth: 1)
                    }

                VStack(alignment: .leading, spacing: LeafIDTheme.space6) {
                    Text(scan.scientificName)
                        .font(LeafIDFont.plusJakarta(size: 20, weight: .bold))
                        .foregroundStyle(LeafIDTheme.onSurface)
                        .lineLimit(3)
                    Text(scan.commonName.uppercased())
                        .font(LeafIDFont.manrope(size: 12, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(LeafIDTheme.primary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, LeafIDTheme.botanicalFrontOverlayPaddingH)
            .padding(.top, LeafIDTheme.space24)
            .padding(.bottom, LeafIDTheme.space16)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: LeafIDTheme.space16) {
                    colorSignatureSection

                    VStack(alignment: .leading, spacing: LeafIDTheme.space10) {
                        Text("Botanical Spirit")
                            .font(LeafIDFont.manrope(size: 11, weight: .bold))
                            .tracking(1.6)
                            .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                            .textCase(.uppercase)
                        Text("“\(spiritText)”")
                            .font(.system(size: 16, weight: .regular, design: .serif))
                            .italic()
                            .foregroundStyle(LeafIDTheme.onSurface)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(LeafIDTheme.space16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.resultsSheetTop, style: .continuous)
                                    .fill(LeafIDTheme.surfaceContainerHigh)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: CornerRadius.resultsSheetTop, style: .continuous)
                                    .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.14), lineWidth: 1)
                            }
                    }

                    narrativeSection(title: "Ethnobotany", text: ethnobotanyText)
                    narrativeSection(title: "Cultural Legacy", text: culturalLegacyText)
                }
                .padding(.horizontal, LeafIDTheme.botanicalFrontOverlayPaddingH)
                .padding(.top, LeafIDTheme.space8)
                .padding(.bottom, LeafIDTheme.space24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: LeafIDTheme.surfaceContainerLow.opacity(0.00), location: 0.00),
                        .init(color: LeafIDTheme.surfaceContainerLow.opacity(0.00), location: 0.45),
                        .init(color: LeafIDTheme.surfaceContainerLow.opacity(0.42), location: 0.78),
                        .init(color: LeafIDTheme.surfaceContainerLow.opacity(0.92), location: 1.00),
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(maxWidth: .infinity)
                .frame(height: 76)
                .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LeafIDTheme.surfaceContainerLow)
    }

    private var colorSignatureSection: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space10) {
            Text("Colour Signature")
                .font(LeafIDFont.manrope(size: 11, weight: .bold))
                .tracking(1.6)
                .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                .textCase(.uppercase)

            HStack(spacing: LeafIDTheme.space16) {
                ForEach(paletteHexes, id: \.self) { hex in
                    VStack(spacing: LeafIDTheme.space6) {
                        Circle()
                            .fill(colorFromHex(hex))
                            .frame(width: 44, height: 44)
                            .overlay {
                                Circle()
                                    .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.45), lineWidth: 1)
                            }
                        Text(hex)
                            .font(LeafIDFont.manrope(size: 11, weight: .medium))
                            .monospaced()
                            .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func narrativeSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space8) {
            Text(title)
                .font(LeafIDFont.manrope(size: 11, weight: .bold))
                .tracking(1.6)
                .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                .textCase(.uppercase)
            Text(text)
                .font(LeafIDFont.manrope(size: 14, weight: .regular))
                .foregroundStyle(LeafIDTheme.onSurface)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(LeafIDTheme.space16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.resultsSheetTop, style: .continuous)
                .fill(LeafIDTheme.surfaceContainerHigh)
        )
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.resultsSheetTop, style: .continuous)
                .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.14), lineWidth: 1)
        }
    }

    private func colorFromHex(_ raw: String) -> Color {
        let t = raw.replacingOccurrences(of: "#", with: "")
        guard let value = UInt32(t, radix: 16) else { return LeafIDTheme.primary }
        return Color(hex: value)
    }
}

private struct ImmersiveSpecimenFill: View {
    let scan: Scan

    var body: some View {
        Group {
            #if canImport(UIKit)
            if let ui = scan.uiImageForLocalCaptureDisplay() {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else if let remote = scan.resolvedRemoteImageURL {
                AsyncImage(url: remote) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            LeafIDTheme.surfaceContainerHigh
                            ProgressView().tint(LeafIDTheme.primary)
                        }
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
            #else
            placeholder
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var placeholder: some View {
        LeafIDTheme.surfaceContainerLow
    }
}

#if canImport(UIKit)
@ViewBuilder
private func specimenUIKit(scan: Scan) -> some View {
    if let ui = scan.uiImageForLocalCaptureDisplay() {
        Image(uiImage: ui)
            .resizable()
            .scaledToFill()
    } else if let remote = scan.resolvedRemoteImageURL {
        AsyncImage(url: remote) { phase in
            switch phase {
            case .empty:
                ZStack {
                    LeafIDTheme.surfaceContainerHigh
                    ProgressView().tint(LeafIDTheme.primary)
                }
            case let .success(image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                ImmersiveSpecimenMissingPlaceholder()
            @unknown default:
                ImmersiveSpecimenMissingPlaceholder()
            }
        }
    } else {
        ImmersiveSpecimenMissingPlaceholder()
    }
}

private struct ImmersiveSpecimenMissingPlaceholder: View {
    var body: some View {
        LeafIDTheme.surfaceContainerLow
    }
}
#endif

#if canImport(UIKit)
private struct BotanicalImmersiveActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

