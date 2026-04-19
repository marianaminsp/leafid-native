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
    /// Optional SF Symbol before the title. Use with `title: ""` for an icon-only pill (e.g. flip control).
    var leadingSystemImage: String? = nil

    private var isIconOnly: Bool {
        leadingSystemImage != nil && title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(spacing: LeafIDTheme.space10) {
            if showsStatusDot {
                Circle()
                    .fill(LeafIDTheme.primary)
                    .frame(width: 8, height: 8)
                    .shadow(color: LeafIDTheme.primary.opacity(0.45), radius: 4, y: 0)
            }
            if let symbol = leadingSystemImage {
                Image(systemName: symbol)
                    .font(.system(size: isIconOnly ? 24 : 18, weight: .semibold))
                    .foregroundStyle(LeafIDTheme.onSurface)
            }
            if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(title)
                    .font(LeafIDFont.manrope(size: 15, weight: .semibold))
                    .tracking(0.25)
                    .foregroundStyle(LeafIDTheme.onSurface)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, isIconOnly ? LeafIDTheme.space16 : LeafIDTheme.space24)
        .padding(.vertical, isIconOnly ? LeafIDTheme.space10 : LeafIDTheme.space12)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.18), lineWidth: 1)
        }
    }
}
