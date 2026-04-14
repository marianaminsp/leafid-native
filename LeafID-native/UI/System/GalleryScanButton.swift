//
//  GalleryScanButton.swift
//  LeafID-native
//
//  Homepage — solid primary disc, dark viewfinder + SCAN.
//

import SwiftUI

struct GalleryScanButton: View {
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(LeafIDTheme.primary)
                VStack(spacing: 6) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 44, weight: .regular))
                        .symbolRenderingMode(.monochrome)
                    Text("SCAN")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(3.2)
                }
                .foregroundStyle(LeafIDTheme.onPrimary)
                .multilineTextAlignment(.center)
            }
            .frame(width: LeafIDTheme.scanButtonSize, height: LeafIDTheme.scanButtonSize)
            .clipShape(Circle())
            .shadow(color: LeafIDTheme.scanButtonShadowColor, radius: LeafIDTheme.scanButtonShadowRadius * 0.55, y: 4)
        }
        .buttonStyle(.plain)
    }
}
