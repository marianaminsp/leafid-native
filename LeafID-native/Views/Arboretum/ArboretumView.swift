//
//  ArboretumView.swift
//  LeafID-native
//
//  The Arboretum — map of where discoveries took root (PDR §3.C).
//

import MapKit
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ArboretumView: View {
    @EnvironmentObject private var herbariumViewModel: HerbariumViewModel
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.openURL) private var openURL
    /// When set, “Open in Herbarium” on the map popup switches tab and presents the immersive card.
    var onRequestHerbariumDetail: ((Scan) -> Void)? = nil
    @State private var mapRegion = ArboretumMapConfig.defaultRegion
    @State private var selectedScan: Scan?
    @State private var locationAlertMessage: String?
    @State private var showLocationSettingsShortcut = false
    @State private var userTrackingMode: MapUserTrackingMode = .none
    @State private var didApplyInitialRegion = false

    private var scans: [Scan] { herbariumViewModel.scans }
    private var pins: [ArboretumPin] { scans.compactMap(ArboretumPin.init) }

    var body: some View {
        GeometryReader { outerGeo in
            ZStack(alignment: .top) {
                Map(
                    coordinateRegion: $mapRegion,
                    interactionModes: .all,
                    showsUserLocation: true,
                    userTrackingMode: $userTrackingMode,
                    annotationItems: pins
                ) { pin in
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
                    .background {
                        ZStack(alignment: .bottom) {
                            Rectangle()
                                .fill(.ultraThinMaterial)
                            LinearGradient(
                                colors: [
                                    LeafIDTheme.surface.opacity(0.2),
                                    LeafIDTheme.surface.opacity(0.0),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .blendMode(.plusLighter)
                        }
                    }

                    LinearGradient(
                        stops: [
                            .init(color: LeafIDTheme.surface.opacity(0.62), location: 0.0),
                            .init(color: LeafIDTheme.surface.opacity(0.28), location: 0.45),
                            .init(color: LeafIDTheme.surface.opacity(0.06), location: 0.78),
                            .init(color: Color.clear, location: 1.0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 72)
                    .frame(maxWidth: .infinity)
                    .allowsHitTesting(false)

                    if herbariumViewModel.isRemoteLoading && herbariumViewModel.scans.isEmpty {
                        ProgressView(String(localized: "Loading your collection…"))
                            .tint(LeafIDTheme.primary)
                            .foregroundStyle(LeafIDTheme.onSurface)
                            .padding(.top, LeafIDTheme.space8)
                    }

                    if pins.isEmpty, !herbariumViewModel.isRemoteLoading {
                        noGeoPinsBanner
                            .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                            .padding(.top, LeafIDTheme.space12)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .allowsHitTesting(false)

                mapControls

                if let scan = selectedScan {
                    ZStack {
                        LeafIDTheme.shadowBase.opacity(0.5)
                            .ignoresSafeArea()
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.leafIDSpring) { selectedScan = nil }
                            }
                            .accessibilityLabel("Dismiss map specimen preview")
                            .accessibilityAddTraits(.isButton)

                        VStack {
                            Spacer()
                            VStack(alignment: .leading, spacing: LeafIDTheme.space10) {
                                if let handler = onRequestHerbariumDetail {
                                    CompactSpecimenCard(mapSpecimen: scan) {
                                        handler(scan)
                                        withAnimation(.leafIDSpring) { selectedScan = nil }
                                    }
                                } else {
                                    CompactSpecimenCard(mapSpecimen: scan) {}
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                            .padding(.bottom, LeafIDTheme.space28)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
        }
        .background(LeafIDTheme.deepForest)
        .preferredColorScheme(.dark)
        .onAppear {
            Task { @MainActor in
                if !didApplyInitialRegion, let region = recenterToAllSpecimens(scans: scans) {
                    mapRegion = region
                    didApplyInitialRegion = true
                }
            }
        }
        .onChange(of: herbariumViewModel.scans) { scans in
            Task { @MainActor in
                if let selected = selectedScan,
                   !scans.contains(where: { $0.id == selected.id }) {
                    selectedScan = nil
                }
                if let region = recenterToAllSpecimens(scans: scans) {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        mapRegion = region
                    }
                    didApplyInitialRegion = true
                }
            }
        }
        .alert(
            "Location Access Needed",
            isPresented: Binding(
                get: { locationAlertMessage != nil },
                set: { visible in
                    if !visible { clearLocationAlert() }
                }
            )
        ) {
            if showLocationSettingsShortcut {
                Button("Open Settings") { openAppSettings() }
            }
            Button("OK", role: .cancel) { clearLocationAlert() }
        } message: {
            Text(locationAlertMessage ?? "")
        }
        .refreshable {
            await herbariumViewModel.hydrateFromSupabase(auth: auth)
        }
    }

    private var mapControls: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: LeafIDTheme.space10) {
                    Button {
                        let tx = Transaction(animation: .easeInOut(duration: 0.22))
                        withTransaction(tx) { zoomMap(scale: 0.7) }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(LeafIDTheme.onSurface)
                            .frame(width: 44, height: 44)
                            .background(LeafIDTheme.surfaceContainerHigh.opacity(0.9))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Zoom in")

                    Button {
                        let tx = Transaction(animation: .easeInOut(duration: 0.22))
                        withTransaction(tx) { zoomMap(scale: 1.43) }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(LeafIDTheme.onSurface)
                            .frame(width: 44, height: 44)
                            .background(LeafIDTheme.surfaceContainerHigh.opacity(0.9))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Zoom out")

                    Button {
                        withAnimation(.leafIDSpring) {
                            if let region = recenterToAllSpecimens(scans: scans) {
                                mapRegion = region
                            }
                        }
                    } label: {
                        Image(systemName: "leaf.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(LeafIDTheme.onSurface)
                            .frame(width: 44, height: 44)
                            .background(LeafIDTheme.surfaceContainerHigh.opacity(0.9))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Center map on all specimens")
                    .disabled(pins.isEmpty)
                    .opacity(pins.isEmpty ? 0.45 : 1)

                    Button {
                        Task { @MainActor in
                            if let region = await recenterToUserLocation() {
                                let tx = Transaction(animation: .easeInOut(duration: 0.28))
                                withTransaction(tx) { mapRegion = region }
                            }
                        }
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(LeafIDTheme.onSurface)
                            .frame(width: 44, height: 44)
                            .background(LeafIDTheme.surfaceContainerHigh.opacity(0.9))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Center map on current location")
                }
            }
            .padding(.trailing, LeafIDTheme.screenHorizontalPadding)
            .padding(.bottom, 120)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .zIndex(0.5)
    }

    private var noGeoPinsBanner: some View {
        Text(String(localized: "No geotagged specimens yet. Capture with location enabled to plant discoveries on the map."))
            .font(LeafIDFont.manrope(size: 13, weight: .medium))
            .foregroundStyle(LeafIDTheme.onSurfaceVariant)
            .padding(LeafIDTheme.space12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LeafIDTheme.surfaceContainerHigh.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.resultsSheetTop, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.resultsSheetTop, style: .continuous)
                    .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.2), lineWidth: 1)
            }
    }

    private func openAppSettings() {
        #if canImport(UIKit)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
        #endif
    }

    private func recenterToAllSpecimens(scans: [Scan]) -> MKCoordinateRegion? {
        let mapPins = scans.compactMap(ArboretumPin.init)
        guard !mapPins.isEmpty else { return nil }
        return ArboretumMapConfig.regionFittingAllPins(mapPins)
    }

    private func recenterToUserLocation() async -> MKCoordinateRegion? {
        let result = await OneShotLocationRequest().requestCoordinateAndLocality()
        guard let coordinate = result.0 else {
            locationAlertMessage = String(localized: "LeafID could not determine your location right now. Check permission access and try again.")
            showLocationSettingsShortcut = true
            return nil
        }

        clearLocationAlert()
        return MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    }

    private func clearLocationAlert() {
        locationAlertMessage = nil
        showLocationSettingsShortcut = false
    }

    private func zoomMap(scale: Double) {
        var region = mapRegion
        let minDelta = 0.002
        let maxDelta = 120.0
        let nextLat = min(max(region.span.latitudeDelta * scale, minDelta), maxDelta)
        let nextLon = min(max(region.span.longitudeDelta * scale, minDelta), maxDelta)
        region.span = MKCoordinateSpan(latitudeDelta: nextLat, longitudeDelta: nextLon)
        mapRegion = region
    }
}

struct ArboretumView_Previews: PreviewProvider {
    static var previews: some View {
        ArboretumView()
            .environmentObject(HerbariumViewModel())
            .environmentObject(AuthViewModel())
    }
}
