//
//  GalleryScanButton.swift
//  LeafID-native
//
//  Homepage — solid primary disc, dark viewfinder + SCAN.
//

import SwiftUI

struct GalleryScanButton: View {
    var action: () -> Void = {}

    /// Homepage hero control — 15% base bump over `LeafIDTheme.scanButtonSize`, plus an extra 10% for legibility (total ≈ 1.265×).
    private static let scale: CGFloat = 1.15 * 1.1

    var body: some View {
        let side = LeafIDTheme.scanButtonSize * Self.scale
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(LeafIDTheme.primary)
                VStack(spacing: 6 * Self.scale) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 44 * Self.scale, weight: .regular))
                        .symbolRenderingMode(.monochrome)
                    Text("SCAN")
                        .font(.system(size: 10 * Self.scale, weight: .black, design: .rounded))
                        .tracking(3.2 * Self.scale)
                }
                .foregroundStyle(LeafIDTheme.onPrimary)
                .multilineTextAlignment(.center)
            }
            .frame(width: side, height: side)
            .clipShape(Circle())
            .shadow(
                color: LeafIDTheme.scanButtonShadowColor,
                radius: LeafIDTheme.scanButtonShadowRadius * 0.55 * Self.scale,
                y: 4 * Self.scale
            )
        }
        .buttonStyle(.plain)
    }
}
