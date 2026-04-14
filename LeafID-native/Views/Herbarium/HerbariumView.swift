//
//  HerbariumView.swift
//  LeafID-native
//
//  The Herbarium — saved scans from Results (`Preserve`) + layout `docs/ui-screens/Herbarium.png`.
//

import SwiftUI

private struct HerbariumHeaderMinYKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct HerbariumView: View {
    @EnvironmentObject private var viewModel: HerbariumViewModel
    @Namespace private var specimenNamespace
    @State private var selectedScan: Scan?
    @State private var headerMinY: CGFloat = 0

    private var headerCollapseProgress: CGFloat {
        let y = headerMinY
        let threshold: CGFloat = 96
        if y >= 0 { return 0 }
        return min(1, -y / threshold)
    }

    private var herbariumTitlePointSize: CGFloat {
        let expanded: CGFloat = 34
        let collapsed: CGFloat = 22
        return expanded + (collapsed - expanded) * headerCollapseProgress
    }

    var body: some View {
        ZStack {
            LeafIDTheme.surface.ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: LeafIDTheme.space16) {
                    herbariumScrollHeader
                        .padding(.bottom, LeafIDTheme.space8)

                    if viewModel.scans.isEmpty {
                        emptyState
                    } else {
                        ForEach(viewModel.scans) { scan in
                            Button {
                                withAnimation(.leafIDSpring) { selectedScan = scan }
                            } label: {
                                HerbariumSpecimenRowCard(
                                    scan: scan,
                                    namespace: specimenNamespace,
                                    matchedGeometryId: scan.id
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                .padding(.top, LeafIDTheme.space8)
                .padding(.bottom, LeafIDTheme.space28)
            }
            .coordinateSpace(name: "herbariumScroll")
            .onPreferenceChange(HerbariumHeaderMinYKey.self) { headerMinY = $0 }

            if let scan = selectedScan {
                BotanicalCardDetailView(
                    scan: scan,
                    namespace: specimenNamespace,
                    matchedGeometryId: scan.id,
                    onClose: {
                        withAnimation(.leafIDSpring) { selectedScan = nil }
                    }
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var herbariumScrollHeader: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space10) {
            Text("Herbarium")
                .font(LeafIDFont.plusJakarta(size: herbariumTitlePointSize, weight: .bold))
                .foregroundStyle(LeafIDTheme.onSurface)

            if headerCollapseProgress < 0.94 {
                Text("Your collection of botanical wonders")
                    .font(LeafIDFont.manrope(size: LeafIDFont.boutiqueSubtitleSize, weight: .medium))
                    .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                    .opacity(Double(max(0, 1 - headerCollapseProgress / 0.82)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeOut(duration: 0.2), value: headerCollapseProgress)
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: HerbariumHeaderMinYKey.self,
                    value: geo.frame(in: .named("herbariumScroll")).minY
                )
            }
        )
    }

    private var emptyState: some View {
        VStack(spacing: LeafIDTheme.space16) {
            Text("No specimens yet")
                .font(LeafIDFont.plusJakarta(size: 18, weight: .semibold))
                .foregroundStyle(LeafIDTheme.onSurface)
            Text("When you identify a plant, tap Save on the results screen — it will appear here.")
                .font(LeafIDFont.manrope(size: 14, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                .padding(.horizontal, LeafIDTheme.space24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .liquidGlass()
    }
}

struct HerbariumView_Previews: PreviewProvider {
    static var previews: some View {
        HerbariumView()
            .environmentObject(HerbariumViewModel())
    }
}
