//
//  LeafPrimaryButton.swift
//  LeafID-native
//
//  Premium tactile CTA — depth shadow + spring (Scan / results).
//

import SwiftUI

struct LeafPrimaryButton: View {
    let title: String
    var leadingSystemImage: String? = nil
    var isEnabled: Bool = true
    /// When `true`, uses solid `LeafIDTheme.primary` (e.g. scan results) instead of the leaf/deep gradient.
    var useSolidPrimaryFill: Bool = false
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: LeafIDTheme.space12) {
                if let leadingSystemImage {
                    Image(systemName: leadingSystemImage)
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .tracking(0.4)
            }
            .foregroundStyle(useSolidPrimaryFill ? LeafIDTheme.onPrimary : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, LeafIDTheme.space16)
                .background(
                    RoundedRectangle(cornerRadius: LeafIDTheme.radiusPrimaryButton, style: .continuous)
                        .fill(buttonFill)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: LeafIDTheme.radiusPrimaryButton, style: .continuous)
                        .strokeBorder(
                            useSolidPrimaryFill
                                ? LeafIDTheme.onPrimary.opacity(0.12)
                                : Color.white.opacity(0.18),
                            lineWidth: 1
                        )
                }
                .shadow(
                    color: Color.black.opacity(isEnabled ? LeafIDTheme.shadowButtonOpacity : 0.12),
                    radius: LeafIDTheme.shadowButtonRadius,
                    y: LeafIDTheme.shadowButtonY
                )
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

    private var buttonFill: AnyShapeStyle {
        if useSolidPrimaryFill {
            return AnyShapeStyle(LeafIDTheme.primary)
        }
        return AnyShapeStyle(
            LinearGradient(
                colors: [
                    LeafIDTheme.leafGreen,
                    LeafIDTheme.deepGreen,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
