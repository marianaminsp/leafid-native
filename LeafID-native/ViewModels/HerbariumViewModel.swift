//
//  HerbariumViewModel.swift
//  LeafID-native
//
//  Phase 3: load `scans` for `auth.uid()` via Supabase (see web `loadData` / botanyService).
//

import Combine
import Foundation

final class HerbariumViewModel: ObservableObject {
    @Published var scans: [Scan] = []

    private static let persistenceKey = "herbarium.saved_scans.v1"

    init(useSeedData: Bool = true) {
        if let loaded = Self.loadPersistedScans(), !loaded.isEmpty {
            scans = loaded
        } else if useSeedData {
            scans = HerbariumViewModel.placeholderCatalog
        }
    }

    /// Seeded specimens for grid + map parity (docs/PDR.md §3).
    static let placeholderCatalog: [Scan] = [
        Scan(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000001") ?? UUID(),
            userId: nil,
            treeId: nil,
            commonName: "Monstera Deliciosa",
            scientificName: "Monstera deliciosa",
            photoURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/9/9d/Monstera_deliciosa3.jpg/480px-Monstera_deliciosa3.jpg",
            confidence: 0.94,
            location: "Tropical Forest Area",
            createdAt: Date().addingTimeInterval(-2 * 86_400),
            latitude: 42.825,
            longitude: -1.645,
            family: "ARACEAE",
            descriptionText: "In the wild, related aroids climb rainforest trunks; fenestrations may help the leaf withstand wind and rain.",
            sunExposure: "Bright indirect light",
            watering: "Allow soil to dry slightly between waterings",
            phylum: "Magnoliophyta",
            originCountry: "Mexico",
            tagSecondary: "Warm, humid air",
            isNewDiscovery: true
        ),
        Scan(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000002") ?? UUID(),
            userId: nil,
            treeId: nil,
            commonName: "Ficus benjamina",
            scientificName: "Ficus benjamina",
            photoURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Starr_020803-0084_Ficus_benjamina.jpg/480px-Starr_020803-0084_Ficus_benjamina.jpg",
            confidence: 0.88,
            location: "Indoor atrium, east wing",
            createdAt: Date().addingTimeInterval(-5 * 86_400),
            latitude: 42.72,
            longitude: -1.52,
            family: "MORACEAE",
            descriptionText: "Weeping fig is a classic interior tree; it drops leaves when light or watering shifts suddenly.",
            sunExposure: "Bright filtered light",
            watering: "Water when top inch of soil feels dry",
            phylum: "Magnoliophyta",
            originCountry: "Southeast Asia",
            tagSecondary: "Avoid cold drafts",
            isNewDiscovery: false
        ),
        Scan(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000003") ?? UUID(),
            userId: nil,
            treeId: nil,
            commonName: "English Oak",
            scientificName: "Quercus robur",
            photoURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/3/31/Quercus_robur2.jpg/480px-Quercus_robur2.jpg",
            confidence: 0.91,
            location: "Navarre, Spain",
            createdAt: Date().addingTimeInterval(-12 * 86_400),
            latitude: 42.68,
            longitude: -1.78,
            family: "FAGACEAE",
            descriptionText: "Ancient Druids considered this tree sacred, often conducting their most important rituals beneath its sprawling canopy.",
            sunExposure: "Full sun to partial shade",
            watering: "Deep, occasional watering once established",
            phylum: "Magnoliophyta",
            originCountry: "Europe",
            tagSecondary: "Long-lived hardwood",
            isNewDiscovery: false
        ),
    ]

    private static let placeholderIDSet = Set(placeholderCatalog.map(\.id))

    /// `true` when the list is exactly the built-in demo catalog (no real saves loaded from disk).
    var isShowingPlaceholderCatalog: Bool {
        !scans.isEmpty && Set(scans.map(\.id)) == Self.placeholderIDSet
    }

    /// Most recent user-saved specimen (`scans[0]` after each insert). Excludes demo seed data.
    var mostRecentSavedSpecimen: Scan? {
        guard !isShowingPlaceholderCatalog else { return nil }
        return scans.first
    }

    /// Appends a specimen after Preserve. `Scan.photoURL` should be the Supabase **public** Storage URL when upload succeeded (see `BotanyService.saveUserCapture`); otherwise a local `file://` capture path.
    func appendPreservedScan(_ scan: Scan) {
        if isShowingPlaceholderCatalog {
            scans = []
        }
        scans.insert(scan, at: 0)
        persistScans()
    }

    /// Updates a persisted scan in place (e.g. reverse-geocoded capture location after save).
    func patchPreservedScan(id: UUID, update: (inout Scan) -> Void) {
        guard let idx = scans.firstIndex(where: { $0.id == id }) else { return }
        var s = scans[idx]
        update(&s)
        scans[idx] = s
        persistScans()
    }

    private static func loadPersistedScans() -> [Scan]? {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let decoded = try? decoder.decode([Scan].self, from: data) else { return nil }
        return decoded.map { scan in
            var sanitized = scan
            let locality = scan.locality?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let baseLocation = locality.isEmpty ? scan.location : locality
            sanitized.location = BotanyService.displaySafeLocation(baseLocation)
            let safeOrigin = BotanyService.displaySafeOrigin(scan.originCountry)
            sanitized.originCountry = safeOrigin.isEmpty ? nil : safeOrigin
            return sanitized
        }
    }

    private func persistScans() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(scans) else { return }
        UserDefaults.standard.set(data, forKey: Self.persistenceKey)
        NotificationCenter.default.post(name: .herbariumCollectionDidChange, object: nil)
    }
}
