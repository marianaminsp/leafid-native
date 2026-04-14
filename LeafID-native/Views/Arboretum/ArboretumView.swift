//
//  ArboretumView.swift
//  LeafID-native
//
//  The Arboretum — map of where discoveries took root (PDR §3.C).
//

import MapKit
import SwiftUI

private struct ArboretumPin: Identifiable {
    var id: UUID { scan.id }
    let scan: Scan
    let coordinate: CLLocationCoordinate2D

    init?(scan: Scan) {
        guard let coordinate = scan.clCoordinate else { return nil }
        self.scan = scan
        self.coordinate = coordinate
    }
}

struct ArboretumView: View {
    @EnvironmentObject private var viewModel: HerbariumViewModel
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.78, longitude: -1.6),
        span: MKCoordinateSpan(latitudeDelta: 0.28, longitudeDelta: 0.28)
    )
    @State private var selectedScan: Scan?

    private var pins: [ArboretumPin] {
        viewModel.scans.compactMap(ArboretumPin.init)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(coordinateRegion: $region, annotationItems: pins) { pin in
                MapAnnotation(coordinate: pin.coordinate) {
                    Button {
                        withAnimation(.leafIDSpring) {
                            selectedScan = pin.scan
                        }
                    } label: {
                        GreenDotMarker()
                    }
                    .buttonStyle(.plain)
                }
            }
            .colorScheme(.dark)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                BoutiqueHeader(
                    layout: .stacked(plainTop: "The", accentBottom: "Arboretum"),
                    subtitle: "Where your botanical discoveries took root."
                )
                .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, LeafIDTheme.headerTopInset)

            if let scan = selectedScan {
                VStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: LeafIDTheme.space10) {
                        Button {
                            withAnimation(.leafIDSpring) { selectedScan = nil }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .accessibilityLabel("Dismiss specimen card")

                        CompactSpecimenCard(
                            commonName: scan.commonName,
                            scientificName: scan.scientificName,
                            style: .mapPopup
                        )
                    }
                    .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                    .padding(.bottom, LeafIDTheme.space28)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .zIndex(1)
            }
        }
        .background(LeafIDTheme.deepForest)
        .preferredColorScheme(.dark)
        .animation(.leafIDSpring, value: selectedScan?.id)
    }
}

struct ArboretumView_Previews: PreviewProvider {
    static var previews: some View {
        ArboretumView()
            .environmentObject(HerbariumViewModel())
    }
}
