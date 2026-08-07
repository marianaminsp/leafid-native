//
//  NeoBrutalistAppHeader.swift
//  LeafID-native
//
//  Shared top bar for the redesign screens (wordmark + level chip + avatar) —
//  appears across identify_any_plant, the_arboretum, and your_herbarium mockups.
//

import SwiftUI

struct NeoBrutalistAppHeader: View {
    var levelLabel: String = "Lvl 12"
    /// Taps through to the Druid tab — the profile screen these mockups don't repeat per-screen.
    var onAvatarTap: () -> Void = {}

    var body: some View {
        HStack(spacing: NeoBrutalistSpacing.sm) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(NeoBrutalistColor.primary)
            Text("Leaf ID")
                .font(NeoBrutalistFont.headlineMd())
                .foregroundStyle(NeoBrutalistColor.primary)

            Spacer(minLength: NeoBrutalistSpacing.md)

            Text(levelLabel)
                .font(.custom("SpaceMono-Bold", size: 12))
                .kerning(1.2)
                .foregroundStyle(NeoBrutalistColor.secondary)

            Button(action: onAvatarTap) {
                ZStack {
                    Circle().fill(NeoBrutalistColor.primary)
                    Image(systemName: "person.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(NeoBrutalistColor.onPrimary)
                }
                .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, NeoBrutalistSpacing.md)
        .padding(.vertical, NeoBrutalistSpacing.sm)
        .background(NeoBrutalistColor.surface.opacity(0.92))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(NeoBrutalistColor.ink.opacity(0.08))
                .frame(height: 1)
        }
    }
}
