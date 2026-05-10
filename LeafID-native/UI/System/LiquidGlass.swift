//
//  LiquidGlass.swift
//  LeafID-native
//
//  Glass surface primitive (docs/PDR.md §4).
//

import SwiftUI

struct LiquidGlassViewModifier: ViewModifier {
    var cornerRadius: CGFloat = LeafIDTheme.liquidGlassCornerRadius

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background(shape.fill(.ultraThinMaterial))
            .overlay(shape.strokeBorder(Color.white.opacity(LeafIDTheme.liquidGlassBorderOpacity), lineWidth: 1))
            .clipShape(shape)
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = LeafIDTheme.liquidGlassCornerRadius) -> some View {
        modifier(LiquidGlassViewModifier(cornerRadius: cornerRadius))
    }
}
