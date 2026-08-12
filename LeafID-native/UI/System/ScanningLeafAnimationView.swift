//
//  ScanningLeafAnimationView.swift
//  LeafID-native
//
//  Scan ritual visual (PDR §3.A).
//

import SwiftUI

struct ScanningLeafAnimationView: View {
    @State private var pulse = false

    var body: some View {
        Image(systemName: "leaf.circle.fill")
            .font(.system(size: 120, weight: .thin))
            .foregroundStyle(LeafIDTheme.primary.opacity(0.9))
            .symbolRenderingMode(.hierarchical)
            .scaleEffect(pulse ? 1.06 : 0.94)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
            .onAppear { pulse = true }
            .accessibilityLabel("Scanning")
    }
}
