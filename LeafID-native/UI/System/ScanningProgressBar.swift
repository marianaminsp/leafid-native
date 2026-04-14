//
//  ScanningProgressBar.swift
//  LeafID-native
//
//  Scanner viewport — primary “scan line” sweep over `surfaceContainerHigh` track.
//

import SwiftUI

struct ScanningProgressBar: View {
    var isAnimating: Bool = true
    @State private var sweepPhase: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let bandWidth = w * 0.38
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(LeafIDTheme.surfaceContainerHigh)
                Capsule()
                    .fill(LeafIDTheme.primary)
                    .frame(width: bandWidth)
                    .offset(x: (w + bandWidth) * sweepPhase - bandWidth)
                    .shadow(color: LeafIDTheme.primary.opacity(0.45), radius: 6, y: 0)
            }
        }
        .frame(height: 8)
        .clipShape(Capsule())
        .onAppear {
            guard isAnimating else {
                sweepPhase = 0.5
                return
            }
            sweepPhase = 0
            withAnimation(.linear(duration: 1.15).repeatForever(autoreverses: false)) {
                sweepPhase = 1
            }
        }
        .onChange(of: isAnimating) { anim in
            if anim {
                sweepPhase = 0
                withAnimation(.linear(duration: 1.15).repeatForever(autoreverses: false)) {
                    sweepPhase = 1
                }
            } else {
                sweepPhase = 0.5
            }
        }
    }
}
