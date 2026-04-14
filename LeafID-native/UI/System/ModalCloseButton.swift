//
//  ModalCloseButton.swift
//  LeafID-native
//
//  Full-screen scan / results: circular glass dismiss control (SF Symbol `xmark`).
//

import SwiftUI

struct ModalCloseButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(LeafIDTheme.onSurface)
                .frame(width: 44, height: 44)
                .background {
                    Circle()
                        .fill(.ultraThinMaterial)
                }
                .overlay {
                    Circle()
                        .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.22), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
    }
}
