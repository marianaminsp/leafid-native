//
//  NeoBrutalistTabBar.swift
//  LeafID-native
//
//  Shared bottom nav for the redesign screens — same structure appears in the
//  identify_any_plant, the_arboretum, your_herbarium, and the_druid mockups
//  (Map / Identify / Collection / Druid), only the active tab differs.
//

import SwiftUI

enum NeoBrutalistTab: CaseIterable {
    case map, identify, collection, druid

    var label: String {
        switch self {
        case .map: return "ARBORETUM"
        case .identify: return "IDENTIFY"
        case .collection: return "HERBARIUM"
        case .druid: return "DRUID"
        }
    }

    var systemImage: String {
        switch self {
        case .map: return "map.fill"
        case .identify: return "viewfinder"
        case .collection: return "leaf.fill"
        case .druid: return "sparkles"
        }
    }
}

struct NeoBrutalistTabBar: View {
    var activeTab: NeoBrutalistTab
    var onSelect: (NeoBrutalistTab) -> Void = { _ in }

    var body: some View {
        HStack(spacing: NeoBrutalistSpacing.xs) {
            ForEach(NeoBrutalistTab.allCases, id: \.self) { tab in
                Button {
                    onSelect(tab)
                } label: {
                    tabItem(tab)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, NeoBrutalistSpacing.sm)
        .padding(.vertical, NeoBrutalistSpacing.sm)
        .background(NeoBrutalistColor.surface.opacity(0.92))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(NeoBrutalistColor.ink.opacity(0.08))
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private func tabItem(_ tab: NeoBrutalistTab) -> some View {
        let isActive = tab == activeTab
        VStack(spacing: 4) {
            Image(systemName: tab.systemImage)
                .font(.system(size: 20, weight: .bold))
            Text(tab.label)
                .font(.custom("SpaceMono-Bold", size: 10))
        }
        .foregroundStyle(isActive ? NeoBrutalistColor.onPrimaryContainer : NeoBrutalistColor.onSurfaceVariant)
        .padding(.horizontal, NeoBrutalistSpacing.sm)
        .padding(.vertical, NeoBrutalistSpacing.sm)
        .background(isActive ? NeoBrutalistColor.primaryContainer : Color.clear)
        .modifier(ActiveTabDecoration(isActive: isActive))
    }
}

/// Applies the hard-shadow/border treatment only to the active tab pill, matching the mockup's
/// `data-active-classes` (inactive tabs stay borderless/flat).
private struct ActiveTabDecoration: ViewModifier {
    var isActive: Bool

    func body(content: Content) -> some View {
        if isActive {
            content.neoBrutalistSurface(borderWidth: NeoBrutalistStroke.default, shadowOffset: 4)
        } else {
            content
        }
    }
}
