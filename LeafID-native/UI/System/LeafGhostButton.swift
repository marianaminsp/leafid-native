//
//  LeafGhostButton.swift
//  LeafID-native
//
//  Secondary CTA with outline style — ghost/empty appearance.
//

import SwiftUI

struct LeafGhostButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: {
            LeafIDHaptics.impact(.light)
            action()
        }) {
            Text(title)
                .font(LeafIDFont.manrope(size: 15, weight: .semibold))
                .foregroundStyle(LeafIDTheme.onSurface)
                .frame(maxWidth: .infinity)
                .padding(.vertical, LeafIDTheme.space16)
                .overlay {
                    RoundedRectangle(cornerRadius: LeafIDTheme.radiusPrimaryButton, style: .continuous)
                        .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.5), lineWidth: 1)
                }
                .scaleEffect(pressed ? 0.98 : 1)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard isEnabled else { return }
                    withAnimation(.leafIDSpring) { pressed = true }
                }
                .onEnded { _ in
                    withAnimation(.leafIDSpring) { pressed = false }
                }
        )
    }
}
