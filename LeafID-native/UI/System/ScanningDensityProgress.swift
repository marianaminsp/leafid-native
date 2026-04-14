//
//  ScanningDensityProgress.swift
//  LeafID-native
//
//  Determinate “SCANNING DENSITY” bar — track `surfaceContainerHigh`, fill `primary`.
//

import SwiftUI

struct ScanningDensityProgress: View {
    /// 0...1
    var progress: Double

    private var clamped: Double {
        min(1, max(0, progress))
    }

    private var percentText: String {
        "\(Int((clamped * 100).rounded()))%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space10) {
            HStack {
                Text("SCANNING DENSITY")
                    .font(LeafIDFont.manrope(size: 10, weight: .bold))
                    .tracking(2.2)
                    .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                Spacer(minLength: 0)
                Text(percentText)
                    .font(LeafIDFont.manrope(size: 13, weight: .semibold))
                    .foregroundStyle(LeafIDTheme.onSurface)
                    .monospacedDigit()
            }

            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LeafIDTheme.surfaceContainerHigh)
                    Capsule()
                        .fill(LeafIDTheme.primary)
                        .frame(width: max(8, w * clamped))
                        .shadow(color: LeafIDTheme.primary.opacity(0.4), radius: 6, y: 0)
                }
            }
            .frame(height: 8)
            .clipShape(Capsule())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Scanning density \(percentText)")
    }
}
