//
//  MainTabView.swift
//
//  Floating liquid-glass tab bar + tab order aligned with `docs/ui-screens/Homepage.png` / Profile.png.
//

import SwiftUI

private enum FoundryGate {
    static let password = "Test"
}

struct MainTabView: View {
    @StateObject private var herbariumVM = HerbariumViewModel()
    @State private var selectedTab: RootTab = .home
    @State private var showFoundryPasswordGate = false
    @State private var showFoundryGallery = false

    var body: some View {
        Group {
            switch selectedTab {
            case .home:
                HomeView()
            case .scan:
                IdentifyView()
            case .herbarium:
                HerbariumView()
            case .profile:
                ProfileView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(alignment: .center, spacing: LeafIDTheme.space10) {
                FloatingLiquidTabBar(selection: $selectedTab)
                FoundryTabBarButton {
                    showFoundryPasswordGate = true
                }
            }
            .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
            .padding(.top, LeafIDTheme.space8)
            .padding(.bottom, LeafIDTheme.space10)
        }
        .environmentObject(herbariumVM)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showFoundryPasswordGate) {
            FoundryPasswordGateSheet(
                isPresented: $showFoundryPasswordGate,
                showGallery: $showFoundryGallery
            )
        }
        .fullScreenCover(isPresented: $showFoundryGallery) {
            DesignSystemGalleryView {
                showFoundryGallery = false
            }
        }
    }
}

// MARK: - Root tabs

enum RootTab: Int, CaseIterable, Hashable {
    case home
    case scan
    case herbarium
    case profile

    var title: String {
        switch self {
        case .home: return "Home"
        case .scan: return "Scan"
        case .herbarium: return "Herbarium"
        case .profile: return "Profile"
        }
    }

    func systemImage(isSelected: Bool) -> String {
        switch self {
        case .home: return isSelected ? "house.fill" : "house"
        case .scan: return "camera.aperture"
        case .herbarium: return isSelected ? "leaf.fill" : "leaf"
        case .profile: return isSelected ? "person.crop.circle.fill" : "person.crop.circle"
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

// MARK: - Foundry (bottom bar)

private struct FoundryTabBarButton: View {
    let action: () -> Void

    private let radius: CGFloat = 22

    var body: some View {
        Button(action: action) {
            VStack(spacing: LeafIDTheme.space4) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("Foundry")
                    .font(LeafIDFont.manrope(size: 9, weight: .bold))
                    .tracking(0.15)
            }
            .foregroundStyle(LeafIDTheme.onSurfaceVariant)
            .frame(width: 72)
            .padding(.vertical, LeafIDTheme.space10)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(Color(red: 28 / 255, green: 33 / 255, blue: 22 / 255, opacity: 0.72))
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.white.opacity(LeafIDTheme.liquidGlassBorderOpacity), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: Color.black.opacity(0.45), radius: 28, y: 14)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open Design System Foundry")
    }
}

private struct FoundryPasswordGateSheet: View {
    @Binding var isPresented: Bool
    @Binding var showGallery: Bool
    @State private var passwordEntry = ""
    @State private var gateError = false
    @FocusState private var passwordFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: LeafIDTheme.space20) {
                Text("Design System Foundry")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(LeafIDTheme.onSurface)

                SecureField("Password", text: $passwordEntry)
                    .textContentType(.password)
                    .focused($passwordFocused)
                    .padding(LeafIDTheme.space16)
                    .background(LeafIDTheme.surfaceContainerLow)
                    .clipShape(RoundedRectangle(cornerRadius: LeafIDTheme.space12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: LeafIDTheme.space12, style: .continuous)
                            .strokeBorder(
                                gateError ? LeafIDTheme.primary.opacity(0.45) : LeafIDTheme.outlineVariant.opacity(0.15),
                                lineWidth: 1
                            )
                    }

                if gateError {
                    Text("Incorrect password")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(LeafIDTheme.primary.opacity(0.9))
                }

                Button("Unlock Foundry") {
                    attemptUnlock()
                }
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(LeafIDTheme.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, LeafIDTheme.space14)
                .background(LeafIDTheme.surfaceContainerHigh)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))

                Spacer(minLength: 0)
            }
            .padding(LeafIDTheme.space24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(LeafIDTheme.surface.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                }
            }
            .onAppear { passwordFocused = true }
        }
        .preferredColorScheme(.dark)
        .onDisappear {
            passwordEntry = ""
            gateError = false
        }
    }

    private func attemptUnlock() {
        if passwordEntry == FoundryGate.password {
            gateError = false
            isPresented = false
            passwordEntry = ""
            showGallery = true
        } else {
            gateError = true
        }
    }
}
