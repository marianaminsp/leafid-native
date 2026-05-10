//
//  MainTabView.swift
//
//  Floating liquid-glass tab bar: Home, Arboretum, Herbarium, Druid.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @StateObject private var herbariumVM = HerbariumViewModel()
    @State private var selectedTab: RootTab = .home
    @State private var pendingHerbariumScan: Scan?
    @State private var restoreTabAfterHerbariumImmersive: RootTab?

    var body: some View {
        Group {
            switch selectedTab {
            case .home:
                HomeView()
            case .arboretum:
                ArboretumView(
                    onRequestHerbariumDetail: { scan in
                        restoreTabAfterHerbariumImmersive = .arboretum
                        pendingHerbariumScan = scan
                        selectedTab = .herbarium
                    }
                )
            case .herbarium:
                HerbariumView(
                    pendingPresentScan: $pendingHerbariumScan,
                    restoreTabAfterImmersiveDismiss: $restoreTabAfterHerbariumImmersive,
                    rootTabSelection: $selectedTab
                )
            case .druid:
                DruidProfileView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ZStack(alignment: .bottom) {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: LeafIDTheme.surface.opacity(0.00), location: 0.00),
                        .init(color: LeafIDTheme.surface.opacity(0.00), location: 0.60),
                        .init(color: LeafIDTheme.surface.opacity(0.20), location: 0.78),
                        .init(color: LeafIDTheme.surface.opacity(0.55), location: 0.90),
                        .init(color: LeafIDTheme.surface.opacity(0.88), location: 1.00),
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(maxWidth: .infinity)
                .frame(height: 108)
                .allowsHitTesting(false)

                FloatingLiquidTabBar(selection: $selectedTab)
                    .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                    .padding(.top, LeafIDTheme.space8)
                    .padding(.bottom, LeafIDTheme.space10)
            }
            .frame(maxWidth: .infinity)
        }
        .environmentObject(herbariumVM)
        .task(id: auth.supabaseUserId) {
            await herbariumVM.hydrateFromSupabase(auth: auth)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Root tabs

enum RootTab: Int, CaseIterable, Hashable {
    case home
    case arboretum
    case herbarium
    case druid

    var title: String {
        switch self {
        case .home: return String(localized: "Home")
        case .arboretum: return String(localized: "Arboretum")
        case .herbarium: return String(localized: "Herbarium")
        case .druid: return String(localized: "Druid")
        }
    }

    func systemImage(isSelected: Bool) -> String {
        switch self {
        case .home: return isSelected ? "house.fill" : "house"
        case .arboretum: return isSelected ? "map.fill" : "map"
        case .herbarium: return isSelected ? "leaf.fill" : "leaf"
        case .druid: return isSelected ? "person.crop.circle.fill" : "person.crop.circle"
        }
    }
}

// MARK: - Floating bar

private struct FloatingLiquidTabBar: View {
    @Binding var selection: RootTab

    private let pillRadius: CGFloat = 28

    var body: some View {
        HStack(spacing: 0) {
            ForEach(RootTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.vertical, LeafIDTheme.space10)
        .padding(.horizontal, LeafIDTheme.space8)
        .frame(maxWidth: .infinity)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: pillRadius, style: .continuous)
                    .fill(Color(red: 28 / 255, green: 33 / 255, blue: 22 / 255, opacity: 0.72))
                RoundedRectangle(cornerRadius: pillRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: pillRadius, style: .continuous)
                .strokeBorder(LeafIDTheme.chromeHighlight.opacity(LeafIDTheme.liquidGlassBorderOpacity), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: pillRadius, style: .continuous))
        .shadow(color: LeafIDTheme.shadowBase.opacity(0.45), radius: 28, y: 14)
    }

    private func tabButton(_ tab: RootTab) -> some View {
        let isSelected = selection == tab
        return Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                selection = tab
            }
        } label: {
            VStack(spacing: LeafIDTheme.space4) {
                Image(systemName: tab.systemImage(isSelected: isSelected))
                    .font(.system(size: 20, weight: .semibold))
                Text(tab.title)
                    .font(LeafIDFont.manrope(size: 10, weight: .bold))
                    .tracking(0.2)
            }
            .foregroundStyle(isSelected ? LeafIDTheme.primary : LeafIDTheme.onSurfaceVariant)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
