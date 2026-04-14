//
//  ScanReticleFrame.swift
//  LeafID-native
//
//  Reference `scanning_leaf_animation.png` — white corner brackets, green scan line upper third, 3 white dots.
//

import SwiftUI

struct ScanReticleFrame: View {
    var cornerLength: CGFloat = 32
    var lineWidth: CGFloat = 2.5
    @State private var scanLinePulse: CGFloat = 1

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let inset: CGFloat = lineWidth / 2

            ZStack {
                CornerBracketsShape(cornerLength: cornerLength)
                    .stroke(Color.white.opacity(0.95), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .padding(inset)
                    .shadow(color: Color.white.opacity(0.25), radius: 4, y: 0)

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

                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(0.95))
                        .frame(width: 5, height: 5)
                        .shadow(color: Color.white.opacity(0.6), radius: 4, y: 0)
                        .position(
                            x: w * (0.32 + CGFloat(i) * 0.18),
                            y: h * (0.38 + CGFloat(i % 2) * 0.14)
                        )
                }
            }
        }
        .onAppear {
            scanLinePulse = 0.92
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                scanLinePulse = 1
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
