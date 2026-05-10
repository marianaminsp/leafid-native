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
    @Environment(\.openURL) private var openURL
    /// When set, “Open in Herbarium” on the map popup switches tab and presents the immersive card.
    var onRequestHerbariumDetail: ((Scan) -> Void)? = nil
    @State private var mapRegion = ArboretumMapConfig.defaultRegion
    @State private var selectedScan: Scan?
    @State private var locationAlertMessage: String?
    @State private var showLocationSettingsShortcut = false
    @State private var userTrackingMode: MapUserTrackingMode = .none
    @State private var didApplyInitialRegion = false
    #if DEBUG
    @State private var debugLocationStatus: String = "Location debug: idle"
    #endif

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
                    arboretumHeader
                        .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                        .padding(.top, outerGeo.safeAreaInsets.top + LeafIDTheme.space8)
                        .padding(.bottom, LeafIDTheme.space8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black)

                    LinearGradient(
                        stops: [
                            .init(color: Color.black, location: 0),
                            .init(color: Color.black.opacity(0.45), location: 0.42),
                            .init(color: Color.black.opacity(0.08), location: 0.78),
                            .init(color: Color.clear, location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 52)
                    .frame(maxWidth: .infinity)
                    .allowsHitTesting(false)

                    if pins.isEmpty {
                        noGeoPinsBanner
                            .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                            .padding(.top, LeafIDTheme.space12)
                    }
                    #if DEBUG
                    debugLocationBanner
                        .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                        .padding(.top, LeafIDTheme.space8)
                    #endif
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .allowsHitTesting(false)

                mapControls

                if let scan = selectedScan {
                    ZStack {
                        Color.black.opacity(0.5)
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
                                    Button {
                                        handler(scan)
                                        withAnimation(.leafIDSpring) { selectedScan = nil }
                                    } label: {
                                        HerbariumSpecimenRowCard(
                                            scan: scan,
                                            namespace: nil,
                                            matchedGeometryId: nil
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Open full specimen in Herbarium")
                                } else {
                                    HerbariumSpecimenRowCard(
                                        scan: scan,
                                        namespace: nil,
                                        matchedGeometryId: nil
                                    )
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
                if !didApplyInitialRegion, let region = recenterToAllSpecimens(scans: scans) {
                    mapRegion = region
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
    }

    private var arboretumHeader: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space10) {
            Text("Arboretum")
                .font(LeafIDFont.plusJakarta(size: 34, weight: .bold))
                .foregroundStyle(LeafIDTheme.onSurface)

            Text("Where your botanical discoveries took root.")
                .font(LeafIDFont.manrope(size: LeafIDFont.boutiqueSubtitleSize, weight: .medium))
                .foregroundStyle(LeafIDTheme.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        Text("No geotagged specimens yet. Capture with location enabled to plant discoveries on the map.")
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

    #if DEBUG
    private var debugLocationBanner: some View {
        Text(debugLocationStatus)
            .font(LeafIDFont.manrope(size: 12, weight: .semibold))
            .foregroundStyle(LeafIDTheme.onSurfaceVariant)
            .padding(LeafIDTheme.space10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LeafIDTheme.surfaceContainerHigh.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.resultsSheetTop, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.resultsSheetTop, style: .continuous)
                    .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.22), lineWidth: 1)
            }
    }
    #endif

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
        #if DEBUG
        let status = CLLocationManager().authorizationStatus
        debugLocationStatus = "Requesting location (auth: \(status.debugLabel))..."
        #endif

        let result = await OneShotLocationRequest().requestCoordinateAndLocality()
        guard let coordinate = result.0 else {
            locationAlertMessage = "LeafID could not determine your location right now. Check permission access and try again."
            showLocationSettingsShortcut = true
            #if DEBUG
            let locality = result.1?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if locality.isEmpty {
                debugLocationStatus = "Location request failed: no coordinates returned."
            } else {
                debugLocationStatus = "Location request failed: no coordinates (locality: \(locality))."
            }
            #endif
            return nil
        }

        clearLocationAlert()
        #if DEBUG
        let locality = result.1?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let coordinateLine = BotanyService.formatCardinalGPS(latitude: coordinate.latitude, longitude: coordinate.longitude)
        if locality.isEmpty {
            debugLocationStatus = "Location resolved: \(coordinateLine)"
        } else {
            debugLocationStatus = "Location resolved: \(coordinateLine) · \(locality)"
        }
        #endif
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

#if DEBUG
private extension CLAuthorizationStatus {
    var debugLabel: String {
        switch self {
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorizedAlways: return "authorizedAlways"
        case .authorizedWhenInUse: return "authorizedWhenInUse"
        @unknown default: return "unknown"
        }
    }
}
#endif

struct ArboretumView_Previews: PreviewProvider {
    static var previews: some View {
        ArboretumView()
            .environmentObject(HerbariumViewModel())
    }
}
