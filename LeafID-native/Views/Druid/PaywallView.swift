//
//  PaywallView.swift
//  LeafID-native
//
//  Premium upsell surface shown when free scan quota is exhausted.
//

import SwiftUI

struct PaywallView: View {
    var onUpgradeTap: () -> Void = {}

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        LeafIDTheme.surface,
                        LeafIDTheme.surfaceContainerLow,
                        LeafIDTheme.surface
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: LeafIDTheme.space24) {
                        paywallHero
                        benefitsSection
                        upgradeButton
                    }
                    .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                    .padding(.top, LeafIDTheme.space24)
                    .padding(.bottom, LeafIDTheme.space32)
                }
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }

    private var paywallHero: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space12) {
            Text("Haz que tu herbario crezca!")
                .font(LeafIDFont.plusJakarta(size: 30, weight: .bold))
                .foregroundStyle(LeafIDTheme.onSurface)
            Text("Desbloquea herramientas botánicas avanzadas y sigue explorando sin límites.")
                .font(LeafIDFont.manrope(size: 16, weight: .medium))
                .foregroundStyle(LeafIDTheme.onSurfaceVariant)
        }
        .padding(LeafIDTheme.space20)
        .background(LeafIDTheme.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.16), lineWidth: 1)
        }
    }

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space12) {
            benefitRow(systemImage: "camera.viewfinder", title: "Escaneos ilimitados")
            benefitRow(systemImage: "cross.case.fill", title: "Salud de plantas")
            benefitRow(systemImage: "doc.richtext.fill", title: "PDF")
        }
        .padding(LeafIDTheme.space20)
        .background(LeafIDTheme.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.16), lineWidth: 1)
        }
    }

    private func benefitRow(systemImage: String, title: String) -> some View {
        HStack(spacing: LeafIDTheme.space12) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(LeafIDTheme.primary)
                .frame(width: 28, height: 28)
            Text(title)
                .font(LeafIDFont.manrope(size: 16, weight: .semibold))
                .foregroundStyle(LeafIDTheme.onSurface)
            Spacer(minLength: 0)
        }
    }

    private var upgradeButton: some View {
        Button {
            onUpgradeTap()
        } label: {
            Text("Hacerse Premium")
                .font(LeafIDFont.plusJakarta(size: 18, weight: .bold))
                .foregroundStyle(LeafIDTheme.surface)
                .frame(maxWidth: .infinity)
                .padding(.vertical, LeafIDTheme.space16)
                .background(LeafIDTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView()
    }
}
