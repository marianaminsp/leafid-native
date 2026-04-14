//
//  SecondaryActionButton.swift
//  LeafID-native
//
//  Wide secondary CTA — `surfaceContainerHighest`, outline-variant hairline (`code.html`).
//

import SwiftUI

struct SecondaryActionButton: View {
    let title: String
    /// Homepage gallery row: upload metaphor (`arrow.up.doc`), not “share”.
    var systemImage: String = "arrow.up.doc"
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: LeafIDTheme.space12) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(LeafIDTheme.primary.opacity(0.95))
                Text(title)
                    .font(LeafIDFont.manrope(size: LeafIDFont.boutiqueSubtitleSize, weight: .semibold))
                    .foregroundStyle(LeafIDTheme.onSurface)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, LeafIDTheme.space16)
            .padding(.horizontal, LeafIDTheme.space20)
            .background(LeafIDTheme.surfaceContainerHighest)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                    .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.15), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
