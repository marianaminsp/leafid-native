//
//  GlassScanHeaderPill.swift
//  LeafID-native
//
//  Scanner status — glass capsule (e.g. “Analyzing leaf…”).
//

import SwiftUI

struct GlassScanHeaderPill: View {
    var title: String = "Analyzing leaf…"
    var showsStatusDot: Bool = false

    var body: some View {
        HStack(spacing: LeafIDTheme.space10) {
            if showsStatusDot {
                Circle()
                    .fill(LeafIDTheme.primary)
                    .frame(width: 8, height: 8)
                    .shadow(color: LeafIDTheme.primary.opacity(0.45), radius: 4, y: 0)
            }
            Text(title)
                .font(LeafIDFont.manrope(size: 15, weight: .semibold))
                .tracking(0.25)
                .foregroundStyle(LeafIDTheme.onSurface)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, LeafIDTheme.space24)
        .padding(.vertical, LeafIDTheme.space12)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.18), lineWidth: 1)
        }
    }
}
