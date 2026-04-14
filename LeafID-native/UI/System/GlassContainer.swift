//
//  GlassContainer.swift
//  LeafID-native
//
//  Named glass wrapper for consistent padding and corner tokens.
//

import SwiftUI

struct GlassContainer<Content: View>: View {
    var cornerRadius: CGFloat = LeafIDTheme.liquidGlassCornerRadius
    var contentPadding: CGFloat = LeafIDTheme.space24
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(contentPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .liquidGlass(cornerRadius: cornerRadius)
    }
}
