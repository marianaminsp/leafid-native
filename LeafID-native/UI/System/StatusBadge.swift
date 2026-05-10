//
//  StatusBadge.swift
//  LeafID-native
//
//  Small state pill for loading / error / active surfaces.
//

import SwiftUI

struct StatusBadge: View {
    enum State: String {
        case loading = "Loading"
        case error = "Error"
        case active = "Active"
    }

    let state: State

    private var tint: Color {
        switch state {
        case .loading: return LeafIDTheme.slateMuted
        case .error: return LeafIDTheme.error
        case .active: return LeafIDTheme.leafGreen
        }
    }

    var body: some View {
        Text(state.rawValue.uppercased())
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .tracking(1.0)
            .foregroundStyle(tint)
            .padding(.horizontal, LeafIDTheme.space12)
            .padding(.vertical, LeafIDTheme.space8)
            .background(
                Capsule()
                    .fill(LeafIDTheme.chromeHighlight.opacity(0.08))
                    .overlay(Capsule().strokeBorder(LeafIDTheme.chromeHighlight.opacity(0.12), lineWidth: 1))
            )
    }
}
