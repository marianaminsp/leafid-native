//
//  MainTabView.swift
//
//  Floating liquid-glass tab bar: Home, Arboretum, Herbarium, Druid.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var herbariumVM = HerbariumViewModel()
    @State private var selectedTab: RootTab = .home

    var body: some View {
        Group {
            switch selectedTab {
            case .home:
                HomeView()
            case .arboretum:
                ArboretumView()
            case .herbarium:
                HerbariumView()
            case .druid:
                ProfileView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FloatingLiquidTabBar(selection: $selectedTab)
                .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                .padding(.top, LeafIDTheme.space8)
                .padding(.bottom, LeafIDTheme.space10)
        }
        .environmentObject(herbariumVM)
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
        case .home: return "Home"
        case .arboretum: return "Arboretum"
        case .herbarium: return "Herbarium"
        case .druid: return "Druid"
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
                .strokeBorder(Color.white.opacity(LeafIDTheme.liquidGlassBorderOpacity), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: pillRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.45), radius: 28, y: 14)
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
