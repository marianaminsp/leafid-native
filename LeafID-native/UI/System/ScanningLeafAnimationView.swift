//
//  ScanningLeafAnimationView.swift
//  LeafID-native
//
//  Scan ritual visual — uses `scanning_leaf_animation` asset when present (PDR §3.A).
//

import SwiftUI
import UIKit

struct ScanningLeafAnimationView: View {
    @State private var pulse = false

    private static var leafAnimationUIImage: UIImage? {
        if let u = UIImage(named: "scanning_leaf_animation") { return u }
        if let u = UIImage(named: "scanning_leaf_animation.jpg") { return u }
        return nil
    }

    var body: some View {
        Group {
            if let ui = Self.leafAnimationUIImage {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 260, maxHeight: 260)
            } else {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 120, weight: .thin))
                    .foregroundStyle(LeafIDTheme.primary.opacity(0.9))
                    .symbolRenderingMode(.hierarchical)
                    .scaleEffect(pulse ? 1.06 : 0.94)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                    .onAppear { pulse = true }
            }
        }
        .accessibilityLabel("Scanning")
    }
}
