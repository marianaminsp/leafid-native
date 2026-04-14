//
//  DruidProfileView.swift
//  LeafID-native
//
//  The Druid — passport-style identity & progression (PDR §2 / protocol Tab 4).
//

import SwiftUI

struct DruidProfileView: View {
    @StateObject private var viewModel = DruidProfileViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                LeafIDTheme.deepForest.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: LeafIDTheme.space28) {
                        passportHeader
                        statsRow
                        bioPassportPanel
                    }
                    .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                    .padding(.top, LeafIDTheme.space12)
                    .padding(.bottom, 36)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .task { await viewModel.refresh() }
    }

    private var passportHeader: some View {
        HStack(alignment: .center, spacing: LeafIDTheme.space20) {
            ZStack {
                Circle()
                    .fill(LeafIDTheme.passportAvatarGradient)
                    .frame(width: 88, height: 88)
                Text(initialGlyph)
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            .overlay {
                Circle()
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            }

            VStack(alignment: .leading, spacing: LeafIDTheme.space8) {
                Text(viewModel.profile?.displayName ?? "The Druid")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(.white)
                Text("Your growth in the wild")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(LeafIDTheme.slateMuted)
                if viewModel.isLoading {
                    StatusBadge(state: .loading)
                } else if viewModel.lastError != nil {
                    StatusBadge(state: .error)
                } else {
                    StatusBadge(state: .active)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(LeafIDTheme.space24)
        .background(
            RoundedRectangle(cornerRadius: LeafIDTheme.liquidGlassCornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay {
            RoundedRectangle(cornerRadius: LeafIDTheme.liquidGlassCornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.22),
                            LeafIDTheme.leafGreen.opacity(0.35),
                            Color.white.opacity(0.08),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: LeafIDTheme.liquidGlassCornerRadius, style: .continuous))
    }

    private var initialGlyph: String {
        let name = viewModel.profile?.displayName ?? "Druid"
        return String(name.prefix(1)).uppercased()
    }

    private var statsRow: some View {
        HStack(spacing: LeafIDTheme.space12) {
            GlassStatTile(
                title: "Specimens",
                value: viewModel.isLoading ? "…" : "\(viewModel.specimenCount)"
            )
            GlassStatTile(
                title: "Ancient Seeds",
                value: viewModel.isLoading ? "…" : "\(viewModel.ancientSeedsCount)"
            )
        }
    }

    private var bioPassportPanel: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space14) {
            Text("Passport bio")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(LeafIDTheme.slateMuted)
            Text(viewModel.profile?.bio ?? "")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .tracking(0.25)
                .foregroundStyle(.white.opacity(0.92))
                .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LeafIDTheme.space24)
        .liquidGlass()
    }
}
