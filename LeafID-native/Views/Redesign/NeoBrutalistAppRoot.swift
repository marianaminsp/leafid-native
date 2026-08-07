//
//  NeoBrutalistAppRoot.swift
//  LeafID-native
//
//  Connects the 6 standalone redesign screens into one flow: Welcome's "Start Identifying" leads
//  into a 4-tab flow (Map/Identify/Collection/Druid), and Identify's "Open Scanner" presents the
//  full-screen Scanner. Every other button either has nowhere to go yet in the 6 mockups — those
//  surface a "not yet designed" alert (see `missingScreenAlert` in NeoBrutalistTheme.swift) instead
//  of doing nothing, so gaps are easy to find while clicking through.
//
//  Not wired into the real app anywhere — reachable only by temporarily swapping the root view in
//  LeafID_nativeApp.swift for manual QA, same as every other screen in this redesign pass.
//

import SwiftUI

struct NeoBrutalistAppRoot: View {
    @State private var hasSeenWelcome = false
    @State private var selectedTab: NeoBrutalistTab = .identify
    @State private var showScanner = false

    var body: some View {
        Group {
            if !hasSeenWelcome {
                WelcomeNeoBrutalistView(onStartIdentifying: {
                    hasSeenWelcome = true
                })
            } else {
                tabContent
            }
        }
        .fullScreenCover(isPresented: $showScanner) {
            ScannerNeoBrutalistView(
                onClose: { showScanner = false },
                onSelectTab: { tab in selectedTab = tab }
            )
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .map:
            ArboretumNeoBrutalistView(onSelectTab: { selectedTab = $0 })
        case .identify:
            IdentifyNeoBrutalistView(
                onOpenScanner: { showScanner = true },
                onSelectTab: { selectedTab = $0 }
            )
        case .collection:
            HerbariumNeoBrutalistView(onSelectTab: { selectedTab = $0 })
        case .druid:
            DruidNeoBrutalistView(onSelectTab: { selectedTab = $0 })
        }
    }
}

struct NeoBrutalistAppRoot_Previews: PreviewProvider {
    static var previews: some View {
        NeoBrutalistAppRoot()
    }
}
