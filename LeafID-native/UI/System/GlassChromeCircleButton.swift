//
//  GlassChromeCircleButton.swift
//  LeafID-native
//
//  Circular glass control — scanner flash, results back/share (`design_system_build` glass rhythm).
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct GlassChromeCircleButton: View {
    let systemImage: String
    var accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            #if canImport(UIKit)
            LeafIDHaptics.impact(.light)
            #endif
            action()
        }) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(LeafIDTheme.onSurface)
                .frame(width: 44, height: 44)
                .background {
                    Circle()
                        .fill(.ultraThinMaterial)
                }
                .overlay {
                    Circle()
                        .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.22), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
