//
//  Scan.swift
//  LeafID-native
//
//  Mirrors `public.scans` usage in docs/SWIFT_MIGRATION_GUIDE.md §2.
//

import CoreLocation
import Foundation

struct Scan: Identifiable, Codable, Equatable {
    var id: UUID
    /// Owner — `auth.users.id` (canonical column `user_id`)
    var userId: UUID?
    var treeId: UUID?
    var commonName: String
    var scientificName: String
    var photoURL: String
    var confidence: Double
    var location: String
    var createdAt: Date?

    /// Planned for Arboretum pins (nullable in DB)
    var latitude: Double?
    var longitude: Double?
    /// City or town from reverse-geocode of capture GPS (`public.scans.locality`).
    var locality: String? = nil

    // MARK: - Plant.id / identify-plant metadata (local + future `scans` columns)

    /// Taxonomic family from the edge function (often uppercase).
    var family: String? = nil
    /// Curiosity / wiki-style line from Plant.id pipeline.
    var descriptionText: String? = nil
    var sunExposure: String? = nil
    var watering: String? = nil
    var phylum: String? = nil
    /// Country of origin when distinct from `location` label.
    var originCountry: String? = nil
    var tagSecondary: String? = nil
    /// High-confidence first-time identification flag from identify flow.
    var isNewDiscovery: Bool? = nil
    /// 3-color signature palette for boutique card + profile aggregate.
    var paletteHexes: [String]? = nil
    var botanicalSpirit: String? = nil
    var ethnobotany: String? = nil
    var culturalLegacy: String? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case treeId = "tree_id"
        case commonName = "common_name"
        case scientificName = "scientific_name"
        case photoURL = "photo_url"
        case confidence
        case location
        case createdAt = "created_at"
        case latitude
        case longitude
        case locality
        case family
        case descriptionText = "description_text"
        case sunExposure = "sun_exposure"
        case watering
        case phylum
        case originCountry = "origin_country"
        case tagSecondary = "tag_secondary"
        case isNewDiscovery = "is_new_discovery"
        case paletteHexes = "palette_hexes"
        case botanicalSpirit = "botanical_spirit"
        case ethnobotany
        case culturalLegacy = "cultural_legacy"
    }
}

extension Scan {
    var clCoordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Front-card location line: prefer origin country when meaningful, else `location`.
    var botanicalOriginLine: String {
        let o = originCountry?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !o.isEmpty, o != "—", o.lowercased() != "origin under review" { return o }
        return location
    }

    /// Main “type” row on card back (family preferred, else phylum).
    var botanicalTypeSummary: String {
        let f = family?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !f.isEmpty, f.lowercased() != "unclassified" { return f }
        let p = phylum?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !p.isEmpty { return p }
        return "—"
    }

    var showsNewDiscoveryBadge: Bool { isNewDiscovery == true }

    /// “Found 2 days ago” copy for Herbarium list rows (`Herbarium.png`).
    func foundRelativePhrase(reference: Date = .now) -> String {
        guard let createdAt else { return "Found recently" }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        return "Found \(f.localizedString(for: createdAt, relativeTo: reference))"
    }

    // MARK: - Thumbnails (`photoURL` may be `file://`, absolute path, or remote)

    private var trimmedPhotoURL: String {
        photoURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Local JPEG written under Documents/captures (see `BotanyService.writeCaptureJPEG`).
    var resolvedLocalCaptureURL: URL? {
        let t = trimmedPhotoURL
        guard !t.isEmpty else { return nil }
        if t.lowercased().hasPrefix("file://") {
            if let u = URL(string: t) { return u }
            return URL(fileURLWithPath: String(t.dropFirst(7)), isDirectory: false)
        }
        if t.lowercased().hasPrefix("http") {
            return nil
        }
        if t.hasPrefix("/") {
            return URL(fileURLWithPath: t)
        }
        return nil
    }

    /// Filesystem path for a local capture when `photoURL` points at a file (preferred for `UIImage(contentsOfFile:)`).
    var resolvedLocalCaptureFilePath: String? {
        guard let url = resolvedLocalCaptureURL, url.isFileURL else { return nil }
        return url.path
    }

    var resolvedRemoteImageURL: URL? {
        let t = trimmedPhotoURL
        guard let u = URL(string: t), let scheme = u.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return nil
        }
        return u
    }

    var normalizedPaletteHexes: [String] {
        (paletteHexes ?? [])
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
            .filter { !$0.isEmpty }
            .map { $0.hasPrefix("#") ? $0 : "#\($0)" }
            .prefix(3)
            .map { String($0) }
    }
}

#if canImport(UIKit)
import UIKit

extension Scan {
    /// Loads a local specimen capture for display (file path + `Data` fallbacks).
    func uiImageForLocalCaptureDisplay() -> UIImage? {
        if let path = resolvedLocalCaptureFilePath, let img = UIImage(contentsOfFile: path) { return img }
        if let url = resolvedLocalCaptureURL {
            if url.isFileURL {
                if let img = UIImage(contentsOfFile: url.path) { return img }
            }
            if let data = try? Data(contentsOf: url), let img = UIImage(data: data) { return img }
        }
        let t = photoURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.hasPrefix("/"), let img = UIImage(contentsOfFile: t) { return img }
        return nil
    }

    func uiImageForLocalCaptureShare() -> UIImage? {
        uiImageForLocalCaptureDisplay()
    }
}
#endif
