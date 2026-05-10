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
    @EnvironmentObject private var auth: AuthViewModel
    @Namespace private var specimenNamespace
    @State private var selectedScan: Scan?
    @State private var immersiveUseMatchedGeometry = true
    @State private var headerMinY: CGFloat = 0

    private let pendingPresentScan: Binding<Scan?>
    private let restoreTabAfterImmersiveDismiss: Binding<RootTab?>
    private let rootTabSelection: Binding<RootTab>

    init(
        pendingPresentScan: Binding<Scan?> = .constant(nil),
        restoreTabAfterImmersiveDismiss: Binding<RootTab?> = .constant(nil),
        rootTabSelection: Binding<RootTab> = .constant(.herbarium)
    ) {
        self.pendingPresentScan = pendingPresentScan
        self.restoreTabAfterImmersiveDismiss = restoreTabAfterImmersiveDismiss
        self.rootTabSelection = rootTabSelection
    }

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
        GeometryReader { outerGeo in
            ZStack {
                LeafIDTheme.surface.ignoresSafeArea()

                VStack(spacing: 0) {
                    herbariumScrollHeader
                        .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                        .padding(.top, outerGeo.safeAreaInsets.top + LeafIDTheme.space8)
                        .padding(.bottom, LeafIDTheme.space8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(LeafIDTheme.surface)

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: LeafIDTheme.space16) {
                            Color.clear
                                .frame(height: 1)
                                .background(
                                    GeometryReader { proxy in
                                        Color.clear.preference(
                                            key: HerbariumHeaderMinYKey.self,
                                            value: proxy.frame(in: .named("herbariumScroll")).minY
                                        )
                                    }
                                )

                            if viewModel.scans.isEmpty, !viewModel.isRemoteLoading {
                                emptyState
                            } else if !viewModel.scans.isEmpty {
                                ForEach(viewModel.scans) { scan in
                                    Button {
                                        immersiveUseMatchedGeometry = true
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
                    .refreshable {
                        await viewModel.hydrateFromSupabase(auth: auth)
                    }
                }

                if viewModel.isRemoteLoading && viewModel.scans.isEmpty {
                    ProgressView(String(localized: "Loading your collection…"))
                        .tint(LeafIDTheme.primary)
                        .foregroundStyle(LeafIDTheme.onSurface)
                        .allowsHitTesting(false)
                }

                if let scan = selectedScan {
                    BotanicalCardImmersiveView(
                        scan: scan,
                        namespace: immersiveUseMatchedGeometry ? specimenNamespace : nil,
                        matchedGeometryId: immersiveUseMatchedGeometry ? scan.id : nil,
                        onClose: {
                            withAnimation(.leafIDSpring) { selectedScan = nil }
                            if let tab = restoreTabAfterImmersiveDismiss.wrappedValue {
                                rootTabSelection.wrappedValue = tab
                                restoreTabAfterImmersiveDismiss.wrappedValue = nil
                            }
                        }
                    )
                    .transition(.opacity)
                    .zIndex(2)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { presentPendingScanIfNeeded() }
        .onChange(of: pendingPresentScan.wrappedValue?.id) { _ in
            presentPendingScanIfNeeded()
        }
    }

    private func presentPendingScanIfNeeded() {
        guard let scan = pendingPresentScan.wrappedValue else { return }
        pendingPresentScan.wrappedValue = nil
        immersiveUseMatchedGeometry = false
        withAnimation(.leafIDSpring) { selectedScan = scan }
    }

    private var herbariumScrollHeader: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space10) {
            Text(String(localized: "Herbarium"))
                .font(LeafIDFont.plusJakarta(size: herbariumTitlePointSize, weight: .bold))
                .foregroundStyle(LeafIDTheme.onSurface)

            if headerCollapseProgress < 0.94 {
                Text(String(localized: "Your collection of botanical wonders"))
                    .font(LeafIDFont.manrope(size: LeafIDFont.boutiqueSubtitleSize, weight: .medium))
                    .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                    .opacity(Double(max(0, 1 - headerCollapseProgress / 0.82)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeOut(duration: 0.2), value: headerCollapseProgress)
    }

    private var emptyState: some View {
        VStack(spacing: LeafIDTheme.space20) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 52, weight: .thin))
                .foregroundStyle(LeafIDTheme.primary.opacity(0.92))
                .accessibilityHidden(true)
            Text(String(localized: "No specimens yet"))
                .font(LeafIDFont.plusJakarta(size: 20, weight: .bold))
                .foregroundStyle(LeafIDTheme.onSurface)
            Text(String(localized: "When you identify a plant, tap Save on the results screen — it will appear here."))
                .font(LeafIDFont.manrope(size: 15, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                .fixedSize(horizontal: false, vertical: true)
            Text(String(localized: "Open Scan to identify a plant, then save it from the results."))
                .font(LeafIDFont.manrope(size: 13, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(LeafIDTheme.primary.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LeafIDTheme.space32)
        .padding(.horizontal, LeafIDTheme.space16)
        .liquidGlass()
    }
}

struct HerbariumView_Previews: PreviewProvider {
    static var previews: some View {
        HerbariumView()
            .environmentObject(HerbariumViewModel())
            .environmentObject(AuthViewModel())
    }
}
