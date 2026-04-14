//
//  GlassStatTile.swift
//  LeafID-native
//
//  Druid passport stat cell — glass-morphic tile (protocol Tab 4).
//

import SwiftUI

struct GlassStatTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space8) {
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .tracking(0.4)
                .foregroundStyle(LeafIDTheme.leafGreen)
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(LeafIDTheme.slateMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LeafIDTheme.space20)
        .liquidGlass(cornerRadius: LeafIDTheme.radiusStatTile)
    }
}
