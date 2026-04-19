import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Herbarium list row: thumbnail, title, “Found … ago”, location, chevron (`docs/ui-screens/Herbarium.png`).
struct HerbariumSpecimenRowCard: View {
    let scan: Scan
    var namespace: Namespace.ID? = nil
    var matchedGeometryId: UUID? = nil

    var body: some View {
        HStack(alignment: .center, spacing: LeafIDTheme.space16) {
            rowThumbnail

            VStack(alignment: .leading, spacing: LeafIDTheme.space6) {
                Text(scan.commonName.localizedCapitalized)
                    .font(LeafIDFont.plusJakarta(size: 18, weight: .bold))
                    .foregroundStyle(LeafIDTheme.onSurface)
                    .lineLimit(2)

                Text(scan.foundRelativePhrase())
                    .font(LeafIDFont.manrope(size: 13, weight: .semibold))
                    .foregroundStyle(LeafIDTheme.primary)

                Text(scan.location)
                    .font(LeafIDFont.manrope(size: 13, weight: .medium))
                    .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(LeafIDTheme.outlineVariant.opacity(0.85))
        }
        .padding(LeafIDTheme.space16)
        .background(LeafIDTheme.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.resultsSheetTop, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.resultsSheetTop, style: .continuous)
                .strokeBorder(LeafIDTheme.outlineVariant.opacity(LeafIDTheme.liquidGlassBorderOpacity), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var rowThumbnail: some View {
        let corner = LeafIDTheme.radiusSpecimenThumb
        let side = LeafIDTheme.herbariumRowThumbnail
        let base = RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(LeafIDTheme.specimenField)
            .frame(width: side, height: side)
            .overlay { rowThumbnailFill }
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))

        if let namespace, let matchedGeometryId {
            base.matchedGeometryEffect(id: matchedGeometryId, in: namespace)
        } else {
            base
        }
    }

    @ViewBuilder
    private var rowThumbnailFill: some View {
        let side = LeafIDTheme.herbariumRowThumbnail
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
                        .frame(width: side, height: side)
                        .clipped()
                case .failure:
                    rowThumbnailLocalFallback(side: side)
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            rowThumbnailLocalFallback(side: side)
        }
        #else
        rowLeafGlyph
        #endif
    }

    #if canImport(UIKit)
    @ViewBuilder
    private func rowThumbnailLocalFallback(side: CGFloat) -> some View {
        if let ui = scan.uiImageForLocalCaptureDisplay() {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
                .frame(width: side, height: side)
                .clipped()
        } else {
            rowLeafGlyph
        }
    }
    #endif

    private var rowLeafGlyph: some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: 28, weight: .semibold))
            .foregroundStyle(LeafIDTheme.primary.opacity(0.55))
    }
}

struct HerbariumSpecimenRowCard_Previews: PreviewProvider {
    static var previews: some View {
        HerbariumSpecimenRowCard(
            scan: Scan(
                id: UUID(),
                userId: nil,
                treeId: nil,
                commonName: "Monstera Deliciosa",
                scientificName: "Monstera deliciosa",
                photoURL: "",
                confidence: 0.92,
                location: "Tropical Forest Area",
                createdAt: Date().addingTimeInterval(-2 * 24 * 3600),
                latitude: nil,
                longitude: nil
            )
        )
        .padding()
        .background(LeafIDTheme.surface)
    }
}
