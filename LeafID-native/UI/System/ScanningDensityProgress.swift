//
//  ScanningDensityProgress.swift
//  LeafID-native
//
//  “SCANNING DENSITY” readout — `docs/ui-screens/stitch_customized_screen_interface_replica/DESIGN.md`
//  Track: surface_variant @ ~30% opacity. Fill: primary_container → primary gradient + soft glow.
//

import SwiftUI

struct ScanningDensityProgress: View {
    enum Style: Equatable {
        /// Label + percent + track (gallery / spec).
        case fullCaption
        /// Thin bar only — no header row or track “card” chrome (scanner HUD).
        case scannerOverlay
    }

    /// 0...1
    var progress: Double
    var style: Style = .fullCaption

    private var clamped: Double {
        min(1, max(0, progress))
    }

    private var percentText: String {
        "\(Int((clamped * 100).rounded()))%"
    }

    private var fillGradient: LinearGradient {
        LinearGradient(
            colors: [LeafIDTheme.primaryContainer, LeafIDTheme.primary],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        Group {
            switch style {
            case .fullCaption:
                VStack(alignment: .leading, spacing: LeafIDTheme.space10) {
                    HStack(alignment: .lastTextBaseline) {
                        Text("SCANNING DENSITY")
                            .font(LeafIDFont.plusJakarta(size: 12, weight: .semibold))
                            .tracking(1.6)
                            .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                        Spacer(minLength: 0)
                        Text(percentText)
                            .font(LeafIDFont.manrope(size: 13, weight: .semibold))
                            .foregroundStyle(LeafIDTheme.primary)
                            .monospacedDigit()
                    }
                    densityBar(trackOpacity: 0.3)
                }
            case .scannerOverlay:
                densityBar(trackOpacity: 0.12)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Scanning density \(percentText)")
    }

    @ViewBuilder
    private func densityBar(trackOpacity: Double) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(LeafIDTheme.surfaceContainerHighest.opacity(trackOpacity))
                Capsule()
                    .fill(fillGradient)
                    .frame(width: max(8, w * clamped))
                    .shadow(color: LeafIDTheme.primary.opacity(0.35), radius: 8, y: 0)
            }
        }
        .frame(height: 6)
        .clipShape(Capsule())
    }
}
