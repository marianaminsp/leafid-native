//
//  GreenDotMarker.swift
//  LeafID-native
//
//  Arboretum map marker — custom green dot (PDR §3.C).
//

import SwiftUI

struct GreenDotMarker: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(LeafIDTheme.leafGreen.opacity(0.35))
                .frame(width: LeafIDTheme.mapMarkerDotSize + 10, height: LeafIDTheme.mapMarkerDotSize + 10)
            Circle()
                .fill(LeafIDTheme.leafGreen)
                .frame(width: LeafIDTheme.mapMarkerDotSize, height: LeafIDTheme.mapMarkerDotSize)
                .overlay {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.55), lineWidth: LeafIDTheme.mapMarkerRingWidth)
                }
                .shadow(color: LeafIDTheme.leafGreen.opacity(0.55), radius: 6, y: 2)
        }
        .accessibilityLabel("Discovery marker")
    }
}
