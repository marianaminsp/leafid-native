//
//  ScannerNeoBrutalistView.swift
//  LeafID-native
//
//  Third redesign screen — a 1:1 SwiftUI build of stitch_botanical_explorer/identify/code.html
//  (the full-screen camera/scanner state). Background photo is the mockup's own placeholder,
//  not a live camera feed — camera capture stays whatever it is on the current shipped screen
//  until this gets wired up for real (out of scope for the visual pilot).
//
//  The shutter now runs the "Sticker Snap" capture moment (artifact afa8e734, "Scanner Moment:
//  Sticker Snap, Refined"): Tap → Analyzing (tilted sticker with a chase-meter + cycling status
//  text) → Reveal (the sticker flips to a result card with a staggered entrance). Result data is
//  mocked, matching every other redesign screen so far — this pass is about the capture *moment*
//  feeling alive, not live inference. "Save to Herbarium" flips the shared
//  `RedesignPrototypeState.hasDiscoveries` flag (UI-only — not a `BotanyService.saveUserCapture`
//  call) so Identify/Herbarium/Druid switch to their populated states; "Scan Another Specimen"
//  is real — it just resets back to the Tap state.
//

import SwiftUI

struct ScannerNeoBrutalistView: View {
    var onClose: () -> Void = {}
    var onSelectTab: (NeoBrutalistTab) -> Void = { _ in }

    @EnvironmentObject private var prototypeState: RedesignPrototypeState
    @State private var missingFeature: String?
    @State private var flashOn = false
    @State private var isFrontCamera = false

    @State private var stage: ScannerCaptureStage = .tap
    @State private var stickerBreathe = false
    @State private var statusPhraseIndex = 0

    var body: some View {
        VStack(spacing: 0) {
            header

            ZStack {
                GeometryReader { geo in
                    Image("IdentifyHeroPlaceholder")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
                Color.black.opacity(0.15)

                if stage == .tap {
                    tapOverlay
                        .transition(.opacity)
                }

                if stage != .tap {
                    captureMoment
                        .padding(NeoBrutalistSpacing.lg)
                        .transition(.opacity)
                }
            }
            .clipped()
            .frame(maxHeight: .infinity)
            .animation(.easeOut(duration: 0.25), value: stage)
        }
        .background(NeoBrutalistColor.surface.ignoresSafeArea())
        .missingScreenAlert($missingFeature)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: NeoBrutalistSpacing.sm) {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(NeoBrutalistColor.onSurface)
            }
            .buttonStyle(.plain)
            .padding(.trailing, NeoBrutalistSpacing.xs)

            Text("IDENTIFY")
                .font(NeoBrutalistFont.headlineMd())
                .foregroundStyle(NeoBrutalistColor.onSurface)

            Spacer()

            Button(action: { onSelectTab(.druid); onClose() }) {
                ZStack {
                    Circle().fill(NeoBrutalistColor.primary)
                    Image(systemName: "person.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(NeoBrutalistColor.onPrimary)
                }
                .frame(width: 36, height: 36)
                .overlay(Circle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.default))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, NeoBrutalistSpacing.md)
        .padding(.vertical, NeoBrutalistSpacing.sm)
        .background(NeoBrutalistColor.surface.opacity(0.94))
    }

    // MARK: - Tap state (camera chrome)

    private var tapOverlay: some View {
        VStack {
            HStack(alignment: .top) {
                aiActiveBadge
                Spacer()
                flashButton
            }
            .padding(.top, NeoBrutalistSpacing.sm)

            Spacer()

            reticle

            Spacer()

            controlRow
                .padding(.bottom, NeoBrutalistSpacing.xl)
        }
        .padding(.horizontal, NeoBrutalistSpacing.md)
    }

    private var aiActiveBadge: some View {
        HStack(spacing: NeoBrutalistSpacing.xs) {
            Circle()
                .fill(NeoBrutalistColor.primaryContainer)
                .frame(width: 8, height: 8)
            Text("BOTANIST AI ACTIVE")
                .font(.custom("SpaceMono-Bold", size: 11))
                .kerning(1.2)
                .foregroundStyle(NeoBrutalistColor.onPrimary)
        }
        .padding(.horizontal, NeoBrutalistSpacing.sm)
        .padding(.vertical, NeoBrutalistSpacing.xs)
        .background(NeoBrutalistColor.primary.opacity(0.9))
        .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.default, shadowOffset: 4)
    }

    private var flashButton: some View {
        Button(action: { flashOn.toggle() }) {
            Image(systemName: flashOn ? "bolt.fill" : "bolt.slash.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(flashOn ? NeoBrutalistColor.onPrimary : NeoBrutalistColor.onSurface)
                .frame(width: 36, height: 36)
                .background(flashOn ? NeoBrutalistColor.primary : NeoBrutalistColor.surface.opacity(0.9))
                .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.default, shadowOffset: 4)
        }
        .buttonStyle(NeoBrutalistPressableStyle(shadowOffset: 4))
    }

    private var reticle: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { corner in
                ReticleBracket()
                    .stroke(NeoBrutalistColor.primaryContainer, lineWidth: 4)
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(Double(corner) * 90))
                    .offset(
                        x: (corner == 1 || corner == 2) ? 110 : -110,
                        y: (corner == 2 || corner == 3) ? 110 : -110
                    )
            }
        }
        .frame(width: 252, height: 252)
    }

    private var controlRow: some View {
        HStack(spacing: NeoBrutalistSpacing.lg) {
            circleControl(systemImage: "photo.on.rectangle", size: 48) {
                missingFeature = "Photo Library Picker"
            }

            Button(action: startCapture) {
                ZStack {
                    Circle()
                        .fill(NeoBrutalistColor.primaryContainer)
                        .overlay(Circle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.heavy))
                    Circle()
                        .fill(NeoBrutalistColor.primary)
                        .overlay(Circle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.default))
                        .frame(width: 60, height: 60)
                }
                .frame(width: 76, height: 76)
            }
            .buttonStyle(.plain)

            circleControl(systemImage: isFrontCamera ? "camera.rotate.fill" : "arrow.triangle.2.circlepath.camera", size: 48) {
                isFrontCamera.toggle()
            }
        }
    }

    private func circleControl(systemImage: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(NeoBrutalistColor.onSurface)
                .frame(width: size, height: size)
                .background(Circle().fill(NeoBrutalistColor.surface.opacity(0.9)))
                .overlay(Circle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.default))
        }
        .buttonStyle(NeoBrutalistPressableStyle(shadowOffset: 2))
    }

    // MARK: - Capture moment (Analyzing → Reveal)

    private var captureMoment: some View {
        ZStack {
            analyzingSticker
                .opacity(stage == .analyzing ? 1 : 0)

            revealCard
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(stage == .reveal ? 1 : 0)
        }
        .rotation3DEffect(
            .degrees(stage == .reveal ? 180 : 0),
            axis: (x: 0, y: 1, z: 0),
            anchor: .center,
            perspective: 0.6
        )
        .animation(.spring(response: 0.55, dampingFraction: 0.72), value: stage)
    }

    private func startCapture() {
        stage = .analyzing
        statusPhraseIndex = 0
        stickerBreathe = false
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            stickerBreathe = true
        }
        Task {
            try? await Task.sleep(for: .seconds(2.6))
            guard stage == .analyzing else { return }
            stage = .reveal
        }
    }

    private var analyzingSticker: some View {
        VStack(spacing: NeoBrutalistSpacing.md) {
            GeometryReader { geo in
                Image("IdentifyHeroPlaceholder")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .overlay(
                LinearGradient(
                    colors: [Color.clear, NeoBrutalistColor.ink.opacity(0.55)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            )

            VStack(spacing: NeoBrutalistSpacing.sm) {
                statusCycleText
                chaseMeter
            }
            .padding(.horizontal, NeoBrutalistSpacing.md)
            .padding(.bottom, NeoBrutalistSpacing.md)
        }
        .frame(maxWidth: 300, maxHeight: 420)
        .background(NeoBrutalistColor.ink)
        .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.heavy, shadowOffset: NeoBrutalistStroke.shadowOffsetLarge)
        .rotationEffect(.degrees(-3))
        .scaleEffect(stickerBreathe ? 1.02 : 1)
        .overlay(alignment: .topLeading) {
            stickerCornerBadge
                .rotationEffect(.degrees(-3))
                .offset(x: -12, y: -12)
        }
    }

    private var stickerCornerBadge: some View {
        Text("AI ACTIVE")
            .font(.custom("SpaceMono-Bold", size: 10))
            .kerning(1)
            .foregroundStyle(NeoBrutalistColor.onPrimary)
            .padding(.horizontal, NeoBrutalistSpacing.xs)
            .padding(.vertical, 4)
            .background(NeoBrutalistColor.primary)
            .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.default, shadowOffset: 3)
    }

    private var statusCycleText: some View {
        Text(ScannerCaptureStage.analyzingPhrases[statusPhraseIndex])
            .font(.custom("SpaceMono-Bold", size: 12))
            .kerning(1)
            .foregroundStyle(NeoBrutalistColor.surface)
            .contentTransition(.opacity)
            .task(id: stage) {
                guard stage == .analyzing else { return }
                while stage == .analyzing {
                    try? await Task.sleep(for: .seconds(1.2))
                    guard stage == .analyzing else { return }
                    withAnimation(.easeInOut(duration: 0.25)) {
                        statusPhraseIndex = (statusPhraseIndex + 1) % ScannerCaptureStage.analyzingPhrases.count
                    }
                }
            }
    }

    /// Segmented "Druid Progress Bar" component language (DESIGN.md) as a chase animation:
    /// Electric Green sweeps across the track, each segment offset by 0.1s like the artifact's meter.
    private var chaseMeter: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: 2) {
                ForEach(0..<8, id: \.self) { index in
                    let phase = t - Double(index) * 0.1
                    let wave = (cos(phase / 1.4 * 2 * .pi) + 1) / 2
                    Rectangle()
                        .fill(NeoBrutalistColor.surfaceContainerHigh)
                        .overlay(
                            Rectangle().fill(NeoBrutalistColor.primaryContainer.opacity(wave))
                        )
                        .frame(height: 6)
                }
            }
        }
    }

    // MARK: - Reveal card

    private var revealCard: some View {
        VStack(alignment: .leading, spacing: NeoBrutalistSpacing.sm) {
            Text("NEW DISCOVERY")
                .font(.custom("SpaceMono-Bold", size: 10))
                .kerning(1.4)
                .foregroundStyle(NeoBrutalistColor.onPrimary)
                .padding(.horizontal, NeoBrutalistSpacing.sm)
                .padding(.vertical, 4)
                .background(NeoBrutalistColor.primary)
                .staggerReveal(stage == .reveal, delay: 0.05)

            Text("PINSTRIPE CALATHEA")
                .font(NeoBrutalistFont.headlineLgMobile())
                .foregroundStyle(NeoBrutalistColor.onSurface)
                .staggerReveal(stage == .reveal, delay: 0.16)

            Text("Calathea ornata")
                .font(.custom("SpaceMono-Bold", size: 12))
                .italic()
                .foregroundStyle(NeoBrutalistColor.onSurfaceVariant)
                .staggerReveal(stage == .reveal, delay: 0.28)

            HStack(spacing: NeoBrutalistSpacing.xs) {
                Text("94% MATCH")
                    .font(.custom("SpaceMono-Bold", size: 11))
                    .foregroundStyle(NeoBrutalistColor.onPrimaryContainer)
                    .padding(.horizontal, NeoBrutalistSpacing.xs)
                    .padding(.vertical, 4)
                    .background(NeoBrutalistColor.primaryContainer)
                    .overlay(Rectangle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.default))
                Text("HIGH CONFIDENCE")
                    .font(.custom("SpaceMono-Bold", size: 10))
                    .foregroundStyle(NeoBrutalistColor.onSurfaceVariant)
            }
            .staggerReveal(stage == .reveal, delay: 0.38)

            HStack(spacing: NeoBrutalistSpacing.xs) {
                revealChip("URBAN")
                revealChip("RARE")
            }
            .staggerReveal(stage == .reveal, delay: 0.48)

            Spacer(minLength: NeoBrutalistSpacing.sm)

            VStack(spacing: NeoBrutalistSpacing.sm) {
                Button(action: {
                    prototypeState.hasDiscoveries = true
                    onClose()
                }) {
                    Text("SAVE TO HERBARIUM")
                        .font(.custom("SpaceMono-Bold", size: 13))
                        .kerning(1)
                        .foregroundStyle(NeoBrutalistColor.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, NeoBrutalistSpacing.sm)
                        .background(NeoBrutalistColor.primary)
                        .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.default, shadowOffset: 4)
                }
                .buttonStyle(NeoBrutalistPressableStyle(shadowOffset: 4))
                .staggerReveal(stage == .reveal, delay: 0.68)

                Button(action: resetToTap) {
                    Text("SCAN ANOTHER SPECIMEN")
                        .font(.custom("SpaceMono-Bold", size: 13))
                        .kerning(1)
                        .foregroundStyle(NeoBrutalistColor.onSurface)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, NeoBrutalistSpacing.sm)
                        .overlay(Rectangle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.default))
                }
                .buttonStyle(.plain)
                .staggerReveal(stage == .reveal, delay: 0.78)
            }
        }
        .padding(NeoBrutalistSpacing.md)
        .frame(maxWidth: 300, maxHeight: 420)
        .background(NeoBrutalistColor.surface)
        .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.heavy, shadowOffset: NeoBrutalistStroke.shadowOffsetLarge)
    }

    private func revealChip(_ title: String) -> some View {
        Text(title)
            .font(.custom("SpaceMono-Bold", size: 10))
            .foregroundStyle(NeoBrutalistColor.onSurface)
            .padding(.horizontal, NeoBrutalistSpacing.xs)
            .padding(.vertical, 3)
            .overlay(Rectangle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.default))
    }

    private func resetToTap() {
        stage = .tap
        stickerBreathe = false
    }
}

private enum ScannerCaptureStage {
    case tap
    case analyzing
    case reveal

    static let analyzingPhrases = ["SCANNING LEAF…", "CROSS-REFERENCING…", "CONFIRMING MATCH…"]
}

/// One right-angle corner bracket of the scanner reticle; rotated per corner in `reticle`.
private struct ReticleBracket: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

/// Staggered pop/rise entrance for the reveal card's children — mirrors the artifact's `popIn`/
/// `riseIn` keyframes (spring scale+fade, per-element delay) rather than one blanket fade.
private struct StaggerRevealModifier: ViewModifier {
    let appeared: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.9)
            .offset(y: appeared ? 0 : 6)
            .animation(.spring(response: 0.4, dampingFraction: 0.72).delay(appeared ? delay : 0), value: appeared)
    }
}

private extension View {
    func staggerReveal(_ appeared: Bool, delay: Double) -> some View {
        modifier(StaggerRevealModifier(appeared: appeared, delay: delay))
    }
}

struct ScannerNeoBrutalistView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerNeoBrutalistView()
            .environmentObject(RedesignPrototypeState())
    }
}
