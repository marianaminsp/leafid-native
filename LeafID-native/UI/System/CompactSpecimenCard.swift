//
//  CompactSpecimenCard.swift
//  LeafID-native
//
//  Grid / map popup: glass chrome. Last Found: `surfaceContainerLow`, 32pt radius (`code.html` cards).
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct CompactSpecimenCard: View {
    enum GridStyle {
        case grid
        case mapPopup
    }

    private enum Mode {
        case grid(
            commonName: String,
            scientificName: String,
            locationLine: String?,
            style: GridStyle,
            namespace: Namespace.ID?,
            matchedGeometryId: UUID?,
            onOpenInHerbarium: (() -> Void)?
        )
        case lastFound(Scan)
        /// Arboretum pin sheet: same chrome as map popup with real thumbnail + “Open in Herbarium”.
        case mapSpecimen(Scan, onOpenInHerbarium: () -> Void)
    }

    private let mode: Mode

    init(
        commonName: String,
        scientificName: String,
        locationLine: String? = nil,
        style: GridStyle,
        namespace: Namespace.ID? = nil,
        matchedGeometryId: UUID? = nil,
        onOpenInHerbarium: (() -> Void)? = nil
    ) {
        mode = .grid(
            commonName: commonName,
            scientificName: scientificName,
            locationLine: locationLine,
            style: style,
            namespace: namespace,
            matchedGeometryId: matchedGeometryId,
            onOpenInHerbarium: onOpenInHerbarium
        )
    }

    init(lastFound scan: Scan) {
        mode = .lastFound(scan)
    }

    init(mapSpecimen scan: Scan, onOpenInHerbarium: @escaping () -> Void) {
        mode = .mapSpecimen(scan, onOpenInHerbarium: onOpenInHerbarium)
    }

    var body: some View {
        switch mode {
        case let .mapSpecimen(scan, onOpen):
            mapSpecimenBody(scan: scan, onOpenInHerbarium: onOpen)
        case let .grid(commonName, scientificName, locationLine, style, namespace, matchedGeometryId, onOpenInHerbarium):
            gridBody(
                commonName: commonName,
                scientificName: scientificName,
                locationLine: locationLine,
                style: style,
                namespace: namespace,
                matchedGeometryId: matchedGeometryId,
                onOpenInHerbarium: onOpenInHerbarium
            )
        case let .lastFound(scan):
            lastFoundBody(scan: scan)
        }
    }

    private func gridInnerPadding(style: GridStyle) -> CGFloat {
        switch style {
        case .grid: return LeafIDTheme.space16
        case .mapPopup: return LeafIDTheme.space14
        }
    }

    @ViewBuilder
    private func mapSpecimenBody(scan: Scan, onOpenInHerbarium: @escaping () -> Void) -> some View {
        let cornerRadius = LeafIDTheme.radiusCompactCard
        let locationLine = scan.captureLocationLine
        VStack(alignment: .leading, spacing: LeafIDTheme.space10) {
            mapSpecimenThumbnail(scan: scan)
                .aspectRatio(1, contentMode: .fit)
            Text(scan.commonName.localizedCapitalized)
                .font(LeafIDFont.plusJakarta(size: 15, weight: .semibold))
                .tracking(0.3)
                .foregroundStyle(LeafIDTheme.onSurface)
                .lineLimit(2)
            Text(scan.scientificName)
                .font(LeafIDFont.manrope(size: 12, weight: .medium))
                .italic()
                .tracking(0.2)
                .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                .lineLimit(2)
            let clean = locationLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if !clean.isEmpty {
                Text(clean)
                    .font(LeafIDFont.manrope(size: 11, weight: .semibold))
                    .foregroundStyle(LeafIDTheme.onSurfaceVariant.opacity(0.9))
                    .lineLimit(2)
            }
            Button(action: onOpenInHerbarium) {
                HStack(spacing: LeafIDTheme.space8) {
                    Text(String(localized: "Open in Herbarium"))
                        .font(LeafIDFont.manrope(size: 12, weight: .bold))
                        .foregroundStyle(LeafIDTheme.primary)
                    Image(systemName: "arrow.up.forward.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(LeafIDTheme.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, LeafIDTheme.space4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "Open full specimen in Herbarium"))
        }
        .padding(gridInnerPadding(style: .mapPopup))
        .liquidGlass(cornerRadius: cornerRadius)
        .shadow(
            color: LeafIDTheme.shadowBase.opacity(LeafIDTheme.shadowCardOpacity),
            radius: LeafIDTheme.shadowCardRadius,
            y: LeafIDTheme.shadowCardY
        )
    }

    @ViewBuilder
    private func mapSpecimenThumbnail(scan: Scan) -> some View {
        let corner = LeafIDTheme.radiusSpecimenThumb
        let placeholder = RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(LeafIDTheme.specimenField)
            .overlay {
                Image(systemName: "leaf.fill")
                    .font(.title)
                    .foregroundStyle(LeafIDTheme.primary.opacity(0.6))
            }

        #if canImport(UIKit)
        Group {
            if let remote = scan.resolvedRemoteImageURL {
                AsyncImage(url: remote) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().tint(LeafIDTheme.primary)
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        lastFoundThumbnailLocalCapture(scan: scan, placeholder: placeholder)
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                lastFoundThumbnailLocalCapture(scan: scan, placeholder: placeholder)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        #else
        placeholder
        #endif
    }

    @ViewBuilder
    private func gridBody(
        commonName: String,
        scientificName: String,
        locationLine: String?,
        style: GridStyle,
        namespace: Namespace.ID?,
        matchedGeometryId: UUID?,
        onOpenInHerbarium: (() -> Void)?
    ) -> some View {
        let cornerRadius = LeafIDTheme.radiusCompactCard
        VStack(alignment: .leading, spacing: LeafIDTheme.space10) {
            gridThumbnail(namespace: namespace, matchedGeometryId: matchedGeometryId)
            Text(commonName)
                .font(LeafIDFont.plusJakarta(size: 15, weight: .semibold))
                .tracking(0.3)
                .foregroundStyle(LeafIDTheme.onSurface)
                .lineLimit(2)
            Text(scientificName)
                .font(LeafIDFont.manrope(size: 12, weight: .medium))
                .italic()
                .tracking(0.2)
                .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                .lineLimit(2)
            if let locationLine {
                let clean = locationLine.trimmingCharacters(in: .whitespacesAndNewlines)
                if !clean.isEmpty {
                    Text(clean)
                        .font(LeafIDFont.manrope(size: 11, weight: .semibold))
                        .foregroundStyle(LeafIDTheme.onSurfaceVariant.opacity(0.9))
                        .lineLimit(2)
                }
            }
            if style == .mapPopup, let openHerbarium = onOpenInHerbarium {
                Button(action: openHerbarium) {
                    HStack(spacing: LeafIDTheme.space8) {
                        Text("Open in Herbarium")
                            .font(LeafIDFont.manrope(size: 12, weight: .bold))
                            .foregroundStyle(LeafIDTheme.primary)
                        Image(systemName: "arrow.up.forward.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(LeafIDTheme.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, LeafIDTheme.space4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open full specimen in Herbarium")
            }
        }
        .padding(gridInnerPadding(style: style))
        .liquidGlass(cornerRadius: cornerRadius)
        .shadow(
            color: LeafIDTheme.shadowBase.opacity(LeafIDTheme.shadowCardOpacity),
            radius: LeafIDTheme.shadowCardRadius,
            y: LeafIDTheme.shadowCardY
        )
    }

    @ViewBuilder
    private func gridThumbnail(namespace: Namespace.ID?, matchedGeometryId: UUID?) -> some View {
        let base = RoundedRectangle(cornerRadius: LeafIDTheme.radiusSpecimenThumb, style: .continuous)
            .fill(LeafIDTheme.specimenField)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                Image(systemName: "leaf.fill")
                    .font(.title)
                    .foregroundStyle(LeafIDTheme.primary.opacity(0.6))
            }

        if let namespace, let matchedGeometryId {
            base.matchedGeometryEffect(id: matchedGeometryId, in: namespace)
        } else {
            base
        }
    }

    private func lastFoundBody(scan: Scan) -> some View {
        HStack(alignment: .center, spacing: LeafIDTheme.space20) {
            lastFoundThumbnail(scan: scan)
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: LeafIDTheme.radiusSpecimenThumb, style: .continuous))

            VStack(alignment: .leading, spacing: LeafIDTheme.space6) {
                Text("Last Found")
                    .font(LeafIDFont.manrope(size: 10, weight: .bold))
                    .tracking(2.4)
                    .foregroundStyle(LeafIDTheme.primary)
                    .textCase(.uppercase)
                Text(scan.commonName.localizedCapitalized)
                    .font(LeafIDFont.plusJakarta(size: 22, weight: .bold))
                    .tracking(-0.35)
                    .foregroundStyle(LeafIDTheme.onSurface)
                    .lineLimit(2)
                Text(scan.captureLocationLine)
                    .font(LeafIDFont.manrope(size: 13, weight: .medium))
                    .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                    .lineLimit(1)
                if let gps = scan.captureGPSLine {
                    Text(gps)
                        .font(LeafIDFont.manrope(size: 11, weight: .medium))
                        .monospaced()
                        .foregroundStyle(LeafIDTheme.onSurfaceVariant.opacity(0.82))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(LeafIDTheme.outlineVariant.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(LeafIDTheme.space20)
        .background(LeafIDTheme.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.15), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func lastFoundThumbnail(scan: Scan) -> some View {
        let corner = LeafIDTheme.radiusSpecimenThumb
        let placeholder = RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(LeafIDTheme.surfaceContainerHigh)
            .overlay {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(LeafIDTheme.primary.opacity(0.55))
            }

        #if canImport(UIKit)
        if let remote = scan.resolvedRemoteImageURL {
            AsyncImage(url: remote) { phase in
                switch phase {
                case .empty:
                    ProgressView().tint(LeafIDTheme.primary)
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    lastFoundThumbnailLocalCapture(scan: scan, placeholder: placeholder)
                @unknown default:
                    placeholder
                }
            }
        } else {
            lastFoundThumbnailLocalCapture(scan: scan, placeholder: placeholder)
        }
        #else
        placeholder
        #endif
    }

    #if canImport(UIKit)
    @ViewBuilder
    private func lastFoundThumbnailLocalCapture(scan: Scan, placeholder: some View) -> some View {
        if let local = scan.resolvedLocalCaptureURL,
           let data = try? Data(contentsOf: local),
           let ui = UIImage(data: data) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
        } else {
            placeholder
        }
    }
    #endif
}
