//
//  BentoResultCard.swift
//  LeafID-native
//
//  High-intensity glass bento — `surfaceContainerLow` + material stack (`ScanResults` visual bible).
//

import SwiftUI

struct BentoResultCard: View {
    let result: IdentifyPreviewResult

    var body: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space16) {
            HStack(alignment: .top, spacing: LeafIDTheme.space12) {
                VStack(alignment: .leading, spacing: LeafIDTheme.space6) {
                    Text(result.commonName)
                        .font(LeafIDFont.plusJakarta(size: 26, weight: .bold))
                        .tracking(-0.4)
                        .foregroundStyle(LeafIDTheme.onSurface)
                        .lineLimit(2)
                    Text(result.scientificName)
                        .font(LeafIDFont.manrope(size: 15, weight: .medium))
                        .italic()
                        .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                MatchConfidenceBadge(confidence: result.confidence)
            }

            HStack(spacing: LeafIDTheme.space12) {
                bentoCell(
                    title: "Family",
                    value: result.family.isEmpty ? "—" : result.family,
                    fillWidth: true
                )
                bentoCell(
                    title: "Confidence",
                    value: String(format: "%.0f%%", result.confidence * 100),
                    fillWidth: true
                )
            }

            bentoCell(
                title: "Location context",
                value: result.locationLabel,
                fillWidth: false
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(LeafIDTheme.space20)
        .modifier(IntenseBentoGlassModifier(cornerRadius: CornerRadius.card))
    }

    private func bentoCell(title: String, value: String, fillWidth: Bool) -> some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space6) {
            Text(title.uppercased())
                .font(LeafIDFont.manrope(size: 10, weight: .bold))
                .tracking(2.0)
                .foregroundStyle(LeafIDTheme.primary)
            Text(value)
                .font(LeafIDFont.manrope(size: 14, weight: .medium))
                .foregroundStyle(LeafIDTheme.onSurface.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)
        }
        .frame(maxWidth: fillWidth ? .infinity : nil, alignment: .leading)
        .padding(LeafIDTheme.space16)
        .background(LeafIDTheme.surfaceContainerHighest.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.immersive / 2, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.immersive / 2, style: .continuous)
                .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct IntenseBentoGlassModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background {
                ZStack {
                    shape.fill(LeafIDTheme.surfaceContainerLow.opacity(0.94))
                    shape.fill(.ultraThinMaterial)
                }
            }
            .overlay {
                shape.strokeBorder(LeafIDTheme.chromeHighlight.opacity(0.2), lineWidth: 1)
            }
            .overlay {
                shape.strokeBorder(LeafIDTheme.outlineVariant.opacity(0.14), lineWidth: 1)
            }
            .clipShape(shape)
    }
}
