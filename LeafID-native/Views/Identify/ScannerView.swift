//
//  ScannerView.swift
//  LeafID-native
//
//  Live capture: full-screen camera with even-odd dim mask (central 48pt rounded cutout), laser sweep,
//  glass shutter; on capture → normalized JPEG + device latitude/longitude/locality for Supabase.
//  Analyze: still frame + same chrome, silent identification (no pills / progress / flash).
//

import AVFoundation
import SwiftUI
#if canImport(CoreLocation)
import CoreLocation
#endif
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Stitch / DESIGN.md tokens (`docs/ui-screens/stitch_customized_screen_interface_replica/`)

private enum ScannerVisual {
    /// `primary` #a7da49
    static let accentPrimary = Color(hex: 0xA7DA49)
    /// `primary_container` #8dbe2e
    static let accentPrimaryContainer = Color(hex: 0x8DBE2E)
    static let scanCycleSeconds: TimeInterval = 6
    static let rippleCycleSeconds: TimeInterval = 2.5
}

// MARK: - Analyzing leaf status pill + pulsing dot

private struct AnalyzingLeafStatusPill: View {
    /// When true, the outer ring pulses (reduce motion disables animation).
    var isAnalyzing: Bool

    var body: some View {
        HStack(spacing: LeafIDTheme.space8) {
            PulsingPrimaryDot(isActive: isAnalyzing)
            Text(String(localized: "ANALYZING LEAF…"))
                .font(LeafIDFont.plusJakarta(size: 14, weight: .semibold))
                .tracking(-0.5)
                .foregroundStyle(ScannerVisual.accentPrimary)
                .textCase(.uppercase)
        }
        .padding(.horizontal, LeafIDTheme.space16)
        .padding(.vertical, LeafIDTheme.space10)
        .background {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(ScannerVisual.accentPrimary.opacity(0.2), lineWidth: 1)
        }
        .shadow(color: LeafIDTheme.shadowBase.opacity(0.35), radius: 16, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "Analyzing leaf"))
    }
}

private struct PulsingPrimaryDot: View {
    var isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let coreSize: CGFloat = 8

    var body: some View {
        Group {
            if isActive && !reduceMotion {
                // `.animation` schedules can stall inside layered chrome; `.periodic` keeps the dot visibly alive.
                TimelineView(.periodic(from: .now, by: 1.0 / 36.0)) { context in
                    let now = context.date.timeIntervalSinceReferenceDate
                    let twinklePeriod: TimeInterval = 0.85
                    let twPhase = (now.truncatingRemainder(dividingBy: twinklePeriod)) / twinklePeriod
                    let coreOpacity = 0.35 + 0.65 * (0.5 + 0.5 * sin(twPhase * Double.pi * 2))

                    let ripplePeriod = ScannerVisual.rippleCycleSeconds
                    let rPhase = (now.truncatingRemainder(dividingBy: ripplePeriod)) / ripplePeriod
                    let ringScale = 1.0 + 1.75 * rPhase
                    let ringOpacity = 1.0 - rPhase

                    ZStack {
                        Circle()
                            .stroke(ScannerVisual.accentPrimary.opacity(0.55), lineWidth: 1.5)
                            .frame(width: coreSize, height: coreSize)
                            .scaleEffect(ringScale)
                            .opacity(ringOpacity)
                        Circle()
                            .fill(ScannerVisual.accentPrimary)
                            .frame(width: coreSize, height: coreSize)
                            .opacity(coreOpacity)
                    }
                    .frame(width: 36, height: 36)
                }
            } else {
                Circle()
                    .fill(ScannerVisual.accentPrimary)
                    .frame(width: coreSize, height: coreSize)
                    .frame(width: 36, height: 36)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Laser line (inside cutout)

private struct ScannerLaserSweep: View {
    var finderWidth: CGFloat
    var finderHeight: CGFloat
    var isRunning: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Smoothstep 0...1 for continuous ease (no harsh linear corners).
    private static func smoothstep(_ x: Double) -> Double {
        let t = min(1, max(0, x))
        return t * t * (3 - 2 * t)
    }

    private static func beamGradient() -> LinearGradient {
        LinearGradient(
            stops: [
                .init(color: ScannerVisual.accentPrimary.opacity(0), location: 0),
                .init(color: ScannerVisual.accentPrimary.opacity(0.92), location: 0.5),
                .init(color: ScannerVisual.accentPrimary.opacity(0), location: 1),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        Group {
            if isRunning && !reduceMotion {
                TimelineView(.animation(minimumInterval: 1 / 60, paused: false)) { context in
                    let duration = ScannerVisual.scanCycleSeconds
                    let t = context.date.timeIntervalSinceReferenceDate
                    let linear = (t.truncatingRemainder(dividingBy: duration)) / duration
                    let eased = Self.smoothstep(linear)
                    let barH: CGFloat = 6
                    let travel = finderHeight - barH
                    let y = -finderHeight * 0.5 + barH * 0.5 + CGFloat(eased) * travel

                    ZStack {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(Self.beamGradient())
                            .frame(width: max(0, finderWidth - 24), height: barH)
                            .blur(radius: 4)
                            .shadow(color: ScannerVisual.accentPrimary.opacity(0.8), radius: 12, y: 0)
                            .offset(y: y)
                    }
                    .frame(width: finderWidth, height: finderHeight)
                }
            }
        }
    }
}

// MARK: - Reveal sweep (analyze screen only — one deliberate pass, not a bouncing laser)

private struct ScannerRevealSweep: View {
    var finderWidth: CGFloat
    var finderHeight: CGFloat
    var isRunning: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static func smoothstep(_ x: Double) -> Double {
        let t = min(1, max(0, x))
        return t * t * (3 - 2 * t)
    }

    /// Full loop: travel down (0...travelFraction), then hold before repeating — a single
    /// "reading" pass, not a laser bouncing back and forth.
    private static let cycle: TimeInterval = 3.6
    private static let travelFraction = 0.45
    private static let bandHeight: CGFloat = 46

    var body: some View {
        Group {
            if isRunning && !reduceMotion {
                TimelineView(.animation(minimumInterval: 1 / 60, paused: false)) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    let phase = (t.truncatingRemainder(dividingBy: Self.cycle)) / Self.cycle
                    let travelPhase = min(1, phase / Self.travelFraction)
                    let eased = Self.smoothstep(travelPhase)

                    // Trail holds through the pass, then fades out over the next quarter-cycle.
                    let fadePhase = min(1, max(0, (phase - Self.travelFraction) / 0.25))
                    let trailOpacity = phase < Self.travelFraction ? 0.9 : 0.9 * (1 - fadePhase)

                    ZStack(alignment: .top) {
                        LinearGradient(
                            colors: [ScannerVisual.accentPrimary.opacity(0.16), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(width: finderWidth, height: finderHeight * CGFloat(eased))
                        .opacity(trailOpacity)

                        LinearGradient(
                            stops: [
                                .init(color: ScannerVisual.accentPrimary.opacity(0), location: 0),
                                .init(color: ScannerVisual.accentPrimary.opacity(0.85), location: 0.5),
                                .init(color: ScannerVisual.accentPrimary.opacity(0), location: 1),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(width: finderWidth, height: Self.bandHeight)
                        .blur(radius: 2)
                        .shadow(color: ScannerVisual.accentPrimary.opacity(0.6), radius: 10, y: 0)
                        .offset(y: -Self.bandHeight + CGFloat(eased) * (finderHeight + Self.bandHeight))
                    }
                    .frame(width: finderWidth, height: finderHeight, alignment: .top)
                }
            }
        }
    }
}

// MARK: - Even-odd dim (full outer rect + single rounded hole, eoFill)

private struct CinematicViewfinderDimShape: Shape {
    var holeWidth: CGFloat
    var holeHeight: CGFloat
    var cornerRadius: CGFloat
    /// Distance from the **top** of `rect` to the top of the hole (full-viewport coordinates).
    var holeMinY: CGFloat

    func path(in rect: CGRect) -> Path {
        let holeRect = CGRect(
            x: (rect.width - holeWidth) * 0.5,
            y: holeMinY,
            width: holeWidth,
            height: holeHeight
        )
        var path = Path()
        path.addRect(rect)
        path.addPath(Path(roundedRect: holeRect, cornerRadius: cornerRadius, style: .continuous))
        return path
    }
}

// MARK: - Shared layout + cutout

private enum ScannerChrome {
    static let shutterDiameter: CGFloat = LeafIDTheme.scanButtonSize * 1.15
    static let cutoutCornerRadius: CGFloat = 48

    /// Full viewport height (notch + home indicator regions included) for mask + layout math.
    static func fullViewportHeight(_ geo: GeometryProxy) -> CGFloat {
        geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom
    }

    /// Even-odd dim: single shape, full-bleed frame; pair with `.offset(y: -geo.safeAreaInsets.top)` so the path covers the status bar.
    @ViewBuilder
    static func dimOverlay(
        geo: GeometryProxy,
        fullViewportHeight: CGFloat,
        layout: (finderW: CGFloat, finderH: CGFloat, holeTop: CGFloat)
    ) -> some View {
        let cornerR = Self.cutoutCornerRadius
        CinematicViewfinderDimShape(
            holeWidth: layout.finderW,
            holeHeight: layout.finderH,
            cornerRadius: cornerR,
            holeMinY: layout.holeTop
        )
        .fill(LeafIDTheme.shadowBase.opacity(0.6), style: FillStyle(eoFill: true))
        .frame(width: geo.size.width, height: fullViewportHeight)
        .allowsHitTesting(false)
    }

    /// Dim + laser clipped to the hole (no L corners / no extra stroke — contrast is frame vs hole).
    @ViewBuilder
    static func cutoutLayers(
        geo: GeometryProxy,
        fullViewportHeight: CGFloat,
        layout: (finderW: CGFloat, finderH: CGFloat, holeTop: CGFloat),
        showLaser: Bool
    ) -> some View {
        let holeCenterY = layout.holeTop + layout.finderH * 0.5
        ZStack(alignment: .topLeading) {
            dimOverlay(geo: geo, fullViewportHeight: fullViewportHeight, layout: layout)
            if showLaser {
                ScannerLaserSweep(
                    finderWidth: layout.finderW,
                    finderHeight: layout.finderH,
                    isRunning: true
                )
                .frame(width: layout.finderW, height: layout.finderH)
                .position(x: geo.size.width * 0.5, y: holeCenterY)
                .clipShape(RoundedRectangle(cornerRadius: Self.cutoutCornerRadius, style: .continuous))
                .allowsHitTesting(false)
            }
        }
        .frame(width: geo.size.width, height: fullViewportHeight, alignment: .topLeading)
        .offset(y: -geo.safeAreaInsets.top)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    /// Positions the hole below the top chrome and above the reserved bottom (shutter band in live mode).
    /// `holeTop` is measured from the **physical top of the screen** (notch included) so it matches the full-bleed mask.
    static func holeLayout(in geo: GeometryProxy, bottomReserved: CGFloat) -> (finderW: CGFloat, finderH: CGFloat, holeTop: CGFloat) {
        let safe = geo.safeAreaInsets
        let fullH = fullViewportHeight(geo)
        let topChrome = safe.top + LeafIDTheme.headerTopInset + 52
        let bandHeight = fullH - topChrome - bottomReserved
        let innerBand = max(0, bandHeight - LeafIDTheme.space16)

        var finderWidth = min(geo.size.width * 0.76, fullH * 0.5)
        var finderHeight = finderWidth * 1.28
        if finderHeight > innerBand {
            finderHeight = innerBand
            finderWidth = max(160, finderHeight / 1.28)
        }
        finderWidth = max(200, min(finderWidth, geo.size.width - LeafIDTheme.screenHorizontalPadding * 2))
        finderHeight = max(200, min(finderHeight, innerBand))

        let holeTop = topChrome + max(LeafIDTheme.space8, (bandHeight - finderHeight) * 0.5)
        return (finderWidth, finderHeight, holeTop)
    }
}

// MARK: - Scanning density (layered above feed + dim; technical chrome)

// MARK: - Glass shutter (no icon)

private struct GlassShutterButton: View {
    var diameter: CGFloat
    var isEnabled: Bool
    var action: () -> Void

    var body: some View {
        Button(action: {
            #if canImport(UIKit)
            LeafIDHaptics.impact(.medium)
            #endif
            action()
        }) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: diameter, height: diameter)
                Circle()
                    .strokeBorder(LeafIDTheme.chromeHighlight, lineWidth: 2)
                    .frame(width: diameter, height: diameter)
            }
        }
        .buttonStyle(.plain)
        .shadow(color: LeafIDTheme.shadowBase.opacity(0.35), radius: 12, y: 6)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityLabel(String(localized: "Capture photo"))
    }
}

// MARK: - Entry

struct ScannerView: View {
    private enum Mode {
        case live(onClose: () -> Void, onCaptured: (Data, Double?, Double?, String?) -> Void)
        case analyze(jpeg: Data, onClose: () -> Void, onComplete: (IdentifyPreviewResult, Data) -> Void)
    }

    private let mode: Mode

    /// In-app camera: cutout + shutter; delivers JPEG + optional lat, lon, locality on capture.
    init(
        onClose: @escaping () -> Void,
        onCaptured: @escaping (Data, Double?, Double?, String?) -> Void
    ) {
        mode = .live(onClose: onClose, onCaptured: onCaptured)
    }

    /// Post-capture identification (still image).
    init(
        captureJPEGData: Data,
        onClose: @escaping () -> Void,
        onComplete: @escaping (IdentifyPreviewResult, Data) -> Void
    ) {
        mode = .analyze(jpeg: captureJPEGData, onClose: onClose, onComplete: onComplete)
    }

    var body: some View {
        switch mode {
        case let .live(onClose, onCaptured):
            ScannerLiveView(onClose: onClose, onCaptured: onCaptured)
        case let .analyze(jpeg, onClose, onComplete):
            ScannerAnalyzeView(jpeg: jpeg, onClose: onClose, onComplete: onComplete)
        }
    }
}

// MARK: - Live (owns camera session)

private struct ScannerLiveView: View {
    var onClose: () -> Void
    var onCaptured: (Data, Double?, Double?, String?) -> Void

    @StateObject private var camera = LeafIDCameraSession()
    @State private var permissionDenied = false
    @State private var isShutterBusy = false

    var body: some View {
        GeometryReader { geo in
            let fullH = ScannerChrome.fullViewportHeight(geo)
            let layout = ScannerChrome.holeLayout(
                in: geo,
                bottomReserved: geo.safeAreaInsets.bottom + LeafIDTheme.space16 + ScannerChrome.shutterDiameter + LeafIDTheme.space16
            )
            let showLaser = camera.isSessionRunning && camera.configurationError == nil && !permissionDenied

            ZStack {
                LiveCameraPreview(session: camera.session)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()

                ScannerChrome.cutoutLayers(
                    geo: geo,
                    fullViewportHeight: fullH,
                    layout: layout,
                    showLaser: showLaser
                )
                .zIndex(1)

                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Spacer(minLength: 0)
                        GlassChromeCircleButton(
                            systemImage: "xmark",
                            accessibilityLabel: String(localized: "Close")
                        ) {
                            onClose()
                        }
                    }
                    .padding(.top, geo.safeAreaInsets.top + LeafIDTheme.headerTopInset)
                    .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)

                    Spacer(minLength: 0)

                    GlassShutterButton(
                        diameter: ScannerChrome.shutterDiameter,
                        isEnabled: camera.isConfigured && !isShutterBusy && !permissionDenied
                    ) {
                        Task { await captureLivePhoto() }
                    }
                    .padding(.bottom, max(geo.safeAreaInsets.bottom, LeafIDTheme.space12) + LeafIDTheme.space8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(3)

                if let err = camera.configurationError {
                    cameraErrorOverlay(message: err)
                        .zIndex(4)
                } else if permissionDenied {
                    cameraErrorOverlay(
                        message: String(localized: "Camera access is required to capture a leaf.")
                    )
                    .zIndex(4)
                }
            }
            .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: ensureCameraPermissionAndStart)
        .onDisappear {
            camera.stop()
        }
    }

    private func cameraErrorOverlay(message: String) -> some View {
        ZStack {
            LeafIDTheme.shadowBase.opacity(0.55)
                .ignoresSafeArea()
            VStack(spacing: LeafIDTheme.space16) {
                Text(message)
                    .font(LeafIDFont.manrope(size: 15, weight: .medium))
                    .foregroundStyle(LeafIDTheme.onSurface)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                ModalCloseButton(action: onClose)
            }
        }
        .allowsHitTesting(true)
    }

    private func captureLivePhoto() async {
        guard !isShutterBusy else { return }
        isShutterBusy = true
        defer { isShutterBusy = false }

        guard let raw = await camera.capturePhoto() else { return }
        #if canImport(UIKit)
        guard let image = UIImage(data: raw), let jpeg = PickedImageEncoding.jpegData(from: image) else { return }
        #else
        let jpeg = raw
        #endif

        #if canImport(CoreLocation)
        let (coordinate, locality) = await CapturePickLocationEngine.coordinateAndLocality(
            exifCoordinate: nil,
            useDeviceFallback: true
        )
        let lat = coordinate?.latitude
        let lon = coordinate?.longitude
        #else
        let locality: String? = nil
        let lat: Double? = nil
        let lon: Double? = nil
        #endif

        await MainActor.run {
            onCaptured(jpeg, lat, lon, locality)
        }
    }

    private func ensureCameraPermissionAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            camera.configure()
            if camera.isConfigured { camera.start() }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.camera.configure()
                        if self.camera.isConfigured { self.camera.start() }
                    } else {
                        permissionDenied = true
                    }
                }
            }
        default:
            permissionDenied = true
        }
    }
}

// MARK: - Analyze (still + silent API)

private struct ScannerAnalyzeView: View {
    var jpeg: Data
    var onClose: () -> Void
    var onComplete: (IdentifyPreviewResult, Data) -> Void

    @EnvironmentObject private var authViewModel: AuthViewModel

    @State private var failedMessage: String?
    @State private var analysisRunId = UUID()
    @State private var isAnalyzing = true

    private var scanningChromeActive: Bool {
        failedMessage == nil && isAnalyzing
    }

    var body: some View {
        GeometryReader { geo in
            let fullH = ScannerChrome.fullViewportHeight(geo)
            // No more bottom chrome to clear now that the progress bar is gone — the cutout
            // can use that space instead of reserving room for something no longer there.
            let layout = ScannerChrome.holeLayout(
                in: geo,
                bottomReserved: geo.safeAreaInsets.bottom + LeafIDTheme.space24
            )

            ZStack {
                #if canImport(UIKit)
                if let captureImage = UIImage(data: jpeg) {
                    Image(uiImage: captureImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .ignoresSafeArea()
                } else {
                    LeafIDTheme.surface
                }
                #else
                LeafIDTheme.surface
                #endif

                // Laser off here — ScannerRevealSweep below replaces it for this screen with
                // one deliberate top-to-bottom pass instead of a bouncing beam.
                ScannerChrome.cutoutLayers(
                    geo: geo,
                    fullViewportHeight: fullH,
                    layout: layout,
                    showLaser: false
                )
                .zIndex(1)

                ScannerRevealSweep(
                    finderWidth: layout.finderW,
                    finderHeight: layout.finderH,
                    isRunning: scanningChromeActive
                )
                .frame(width: layout.finderW, height: layout.finderH)
                .position(x: geo.size.width * 0.5, y: layout.holeTop + layout.finderH * 0.5)
                .clipShape(RoundedRectangle(cornerRadius: ScannerChrome.cutoutCornerRadius, style: .continuous))
                .allowsHitTesting(false)
                .zIndex(2)

                VStack(spacing: 0) {
                    HStack(alignment: .center, spacing: 0) {
                        Color.clear
                            .frame(width: 44, height: 44)
                            .accessibilityHidden(true)
                        Spacer(minLength: 0)
                        AnalyzingLeafStatusPill(isAnalyzing: scanningChromeActive)
                        Spacer(minLength: 0)
                        GlassChromeCircleButton(
                            systemImage: "xmark",
                            accessibilityLabel: String(localized: "Close")
                        ) {
                            onClose()
                        }
                    }
                    .padding(.top, geo.safeAreaInsets.top + LeafIDTheme.headerTopInset)
                    .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(4)

                if let failedMessage {
                    analyzeErrorBanner(message: failedMessage, geo: geo)
                        .zIndex(5)
                }
            }
            .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
        .task(id: analysisRunId) {
            await runIdentify()
        }
        .accessibilityHint(
            String(localized: "Location is captured when you take a photo with the in-app camera.")
        )
    }

    private func runIdentify() async {
        await MainActor.run {
            isAnalyzing = true
        }

        let requestStart = Date()
        // A fast API response would otherwise cut the reveal-sweep effect short, ending the
        // moment almost instantly — enforce a floor so it always plays out and actually reads.
        let minimumAnalyzingDuration: TimeInterval = 2.6

        do {
            let result = try await BotanyService.identifyPlantWithAI(
                imageBase64: "",
                captureJPEGData: jpeg,
                accessToken: authViewModel.supabaseAccessToken
            )
            let elapsed = Date().timeIntervalSince(requestStart)
            if elapsed < minimumAnalyzingDuration {
                try? await Task.sleep(nanoseconds: UInt64((minimumAnalyzingDuration - elapsed) * 1_000_000_000))
            }
            try await Task.sleep(nanoseconds: 700_000_000)
            await MainActor.run {
                isAnalyzing = false
                onComplete(result, jpeg)
            }
        } catch {
            #if canImport(UIKit)
            await MainActor.run {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
            #endif
            let fallback = String(localized: "Couldn’t reach the botanist. Try again.")
            let detail: String = {
                let raw: String = {
                    if let b = error as? BotanyServiceError {
                        return b.localizedDescription
                    }
                    let s = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !s.isEmpty, s != "(null)" { return s }
                    return fallback
                }()
                let maxLen = 220
                if raw.count <= maxLen { return raw }
                return String(raw.prefix(maxLen)).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
            }()
            await MainActor.run {
                isAnalyzing = false
                failedMessage = detail
            }
        }
    }

    private func analyzeErrorBanner(message: String, geo: GeometryProxy) -> some View {
        VStack(spacing: LeafIDTheme.space12) {
            HStack(alignment: .top, spacing: LeafIDTheme.space10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                Text(message)
                    .font(LeafIDFont.manrope(size: 13, weight: .medium))
                    .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: LeafIDTheme.space8)
            }
            Button {
                failedMessage = nil
                analysisRunId = UUID()
            } label: {
                Text(String(localized: "Retry identification"))
                    .font(LeafIDFont.manrope(size: 14, weight: .semibold))
                    .foregroundStyle(LeafIDTheme.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LeafIDTheme.space12)
                    .background(LeafIDTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: LeafIDTheme.space12, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityHint(String(localized: "Runs plant identification again with the same photo."))
        }
        .padding(LeafIDTheme.space16)
        .background {
            RoundedRectangle(cornerRadius: LeafIDTheme.space12, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: LeafIDTheme.space12, style: .continuous)
                .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.22), lineWidth: 1)
        }
        .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
        .padding(.top, geo.safeAreaInsets.top + 52 + LeafIDTheme.space8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
