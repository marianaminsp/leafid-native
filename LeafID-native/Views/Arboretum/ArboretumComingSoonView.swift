//
//  ArboretumComingSoonView.swift
//  LeafID-native
//
//  MVP placeholder for the Arboretum tab — the real map (ArboretumView.swift) is fully built
//  but deliberately shelved pre-launch to cut map QA/perf surface and avoid polishing UI that's
//  likely to change in the upcoming redesign. Every scan still stores GPS coordinates regardless
//  (see CapturePickLocation.swift + Scan.latitude/longitude), so historical pins are ready to
//  backfill the moment this screen is swapped back to ArboretumView.
//

import SwiftUI

struct ArboretumComingSoonView: View {
    var body: some View {
        GeometryReader { outerGeo in
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: LeafIDTheme.space10) {
                    Text("Arboretum")
                        .font(LeafIDFont.plusJakarta(size: 34, weight: .bold))
                        .foregroundStyle(LeafIDTheme.onSurface)
                    Text("Where your botanical discoveries took root.")
                        .font(LeafIDFont.manrope(size: LeafIDFont.boutiqueSubtitleSize, weight: .medium))
                        .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                }
                .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                .padding(.top, outerGeo.safeAreaInsets.top + LeafIDTheme.space8)
                .padding(.bottom, LeafIDTheme.space12)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)

                VStack(spacing: LeafIDTheme.space16) {
                    Image(systemName: "map")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(LeafIDTheme.primary)

                    Text(String(localized: "Coming soon"))
                        .font(LeafIDFont.manrope(size: 11, weight: .bold))
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(LeafIDTheme.onPrimaryContainer)
                        .padding(.horizontal, LeafIDTheme.space12)
                        .padding(.vertical, LeafIDTheme.space6)
                        .background(LeafIDTheme.primaryContainer)
                        .clipShape(Capsule())

                    Text(String(localized: "We're building an interactive map of every specimen you've found. Keep scanning — LeafID is already saving the location of each discovery so your map is ready the moment it launches."))
                        .font(LeafIDFont.manrope(size: 14, weight: .medium))
                        .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                .accessibilityElement(children: .combine)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(LeafIDTheme.deepForest.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

struct ArboretumComingSoonView_Previews: PreviewProvider {
    static var previews: some View {
        ArboretumComingSoonView()
    }
}
