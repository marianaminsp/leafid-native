//
//  ScanReticleFrame.swift
//  LeafID-native
//
//  White corner brackets, lime scan line, feature dots — gallery (static pulse) or scanner
//  (vertical sweep + dynamic dots). Paused / Reduce Motion use a calm static reticle.
//

import SwiftUI

struct ScanReticleFrame: View {
    var cornerLength: CGFloat = 32
    var lineWidth: CGFloat = 2.5
    /// `true`: vertical scan sweep + dynamic dots (analyze screen). `false`: legacy gallery pulse.
    var scannerMode: Bool = false
    /// When `scannerMode`, freezes motion (e.g. API error).
    var paused: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scanLinePulse: CGFloat = 1

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let inset: CGFloat = lineWidth / 2

            ZStack {
                CornerBracketsShape(cornerLength: cornerLength)
                    .stroke(LeafIDTheme.chromeHighlight.opacity(0.95), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .padding(inset)
                    .shadow(color: LeafIDTheme.chromeHighlight.opacity(0.25), radius: 4, y: 0)

                if scannerMode {
                    if paused || reduceMotion {
                        scannerStaticLineAndDots(w: w, h: h)
                    } else {
                        TimelineView(.animation(minimumInterval: 1.0 / 45.0)) { context in
                            scannerAnimatedLineAndDots(
                                w: w,
                                h: h,
                                t: context.date.timeIntervalSinceReferenceDate
                            )
                        }
                    }
                } else {
                    galleryScanLineAndDots(w: w, h: h)
                }
            }
        }
        .onAppear {
            guard !scannerMode else { return }
            scanLinePulse = 0.92
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                scanLinePulse = 1
            }
        }
    }

    // MARK: - Gallery (DesignSystemGalleryView)

    @ViewBuilder
    private func galleryScanLineAndDots(w: CGFloat, h: CGFloat) -> some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        LeafIDTheme.primary.opacity(0),
                        LeafIDTheme.primary.opacity(0.98),
                        LeafIDTheme.primary.opacity(0),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: w * 0.68, height: 3)
            .shadow(color: LeafIDTheme.primary.opacity(0.65), radius: 10, y: 0)
            .scaleEffect(x: scanLinePulse, y: 1, anchor: .center)
            .offset(y: -h * 0.22)

        ForEach(0 ..< 3, id: \.self) { i in
            Circle()
                .fill(LeafIDTheme.chromeHighlight.opacity(0.95))
                .frame(width: 5, height: 5)
                .shadow(color: LeafIDTheme.chromeHighlight.opacity(0.6), radius: 4, y: 0)
                .position(
                    x: w * (0.32 + CGFloat(i) * 0.18),
                    y: h * (0.38 + CGFloat(i % 2) * 0.14)
                )
        }
    }

    // MARK: - Scanner (vertical sweep + dynamic dots)

    private func scannerAnimatedLineAndDots(w: CGFloat, h: CGFloat, t: TimeInterval) -> some View {
        let phaseY = (sin(t * 1.12) + 1) * 0.5
        let yFromTop = (0.12 + 0.76 * phaseY) * h
        let lineOffsetY = yFromTop - h * 0.5

        return ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            LeafIDTheme.primary.opacity(0),
                            LeafIDTheme.primary.opacity(0.98),
                            LeafIDTheme.primary.opacity(0),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: w * 0.68, height: 3)
                .shadow(color: LeafIDTheme.primary.opacity(0.7), radius: 12, y: 0)
                .shadow(color: LeafIDTheme.primary.opacity(0.35), radius: 20, y: 0)
                .offset(y: lineOffsetY)

            ForEach(0 ..< 3, id: \.self) { i in
                let baseX = w * (0.28 + CGFloat(i) * 0.22)
                let baseY = h * (0.36 + CGFloat(i % 3) * 0.12)
                let driftX = 5.0 * sin(t * 1.4 + Double(i) * 1.7)
                let driftY = 4.0 * sin(t * 1.1 + Double(i) * 2.1)
                let pulse = 0.88 + 0.12 * sin(t * 2.2 + Double(i))
                Circle()
                    .fill(LeafIDTheme.chromeHighlight.opacity(0.92 * pulse))
                    .frame(width: 6, height: 6)
                    .shadow(color: LeafIDTheme.chromeHighlight.opacity(0.55 * pulse), radius: 5, y: 0)
                    .scaleEffect(pulse)
                    .position(x: baseX + CGFloat(driftX), y: baseY + CGFloat(driftY))
            }
        }
    }

    private func scannerStaticLineAndDots(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            LeafIDTheme.primary.opacity(0),
                            LeafIDTheme.primary.opacity(0.98),
                            LeafIDTheme.primary.opacity(0),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: w * 0.68, height: 3)
                .shadow(color: LeafIDTheme.primary.opacity(0.65), radius: 10, y: 0)
                .offset(y: 0)

            ForEach(0 ..< 3, id: \.self) { i in
                Circle()
                    .fill(LeafIDTheme.chromeHighlight.opacity(0.95))
                    .frame(width: 6, height: 6)
                    .shadow(color: LeafIDTheme.chromeHighlight.opacity(0.6), radius: 4, y: 0)
                    .position(
                        x: w * (0.3 + CGFloat(i) * 0.2),
                        y: h * (0.4 + CGFloat(i) * 0.1)
                    )
            }
        }
    }
}

private struct CornerBracketsShape: Shape {
    var cornerLength: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let l = min(cornerLength, rect.width / 2, rect.height / 2)

        p.move(to: CGPoint(x: rect.minX, y: rect.minY + l))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + l, y: rect.minY))

        p.move(to: CGPoint(x: rect.maxX - l, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + l))

        p.move(to: CGPoint(x: rect.maxX, y: rect.maxY - l))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX - l, y: rect.maxY))

        p.move(to: CGPoint(x: rect.minX + l, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - l))

        return p
    }
}
