//
//  ArboretumViewModel.swift
//  LeafID-native
//
//  Map-specific projection for Arboretum (pins + region fitting).
//

import CoreLocation
import MapKit

struct ArboretumPin: Identifiable {
    var id: UUID { scan.id }
    let scan: Scan
    let coordinate: CLLocationCoordinate2D

    init?(scan: Scan) {
        guard let coordinate = scan.clCoordinate else { return nil }
        self.scan = scan
        self.coordinate = coordinate
    }
}

enum ArboretumMapConfig {
    static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.78, longitude: -1.6),
        span: MKCoordinateSpan(latitudeDelta: 0.28, longitudeDelta: 0.28)
    )

    static func regionFittingAllPins(_ pins: [ArboretumPin]) -> MKCoordinateRegion {
        let lats = pins.map { $0.coordinate.latitude }
        let lons = pins.map { $0.coordinate.longitude }
        guard let minLat = lats.min(),
              let maxLat = lats.max(),
              let minLon = lons.min(),
              let maxLon = lons.max()
        else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 42.78, longitude: -1.6),
                span: MKCoordinateSpan(latitudeDelta: 0.28, longitudeDelta: 0.28)
            )
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let latDelta = max(0.08, (maxLat - minLat) * 1.45)
        let lonDelta = max(0.08, (maxLon - minLon) * 1.45)
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }
}
