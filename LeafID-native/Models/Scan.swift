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
    /// Auto-processed hero image for the Botanical Card (subject-crop + auto-level + brand duotone).
    /// `nil` for scans saved before this shipped, or while generation is still in flight — falls back to `photoURL`.
    var cardImageURL: String? = nil

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
    /// Traditional/indigenous/vernacular name from the plant's culture or region of origin —
    /// distinct from `scientificName` and `commonName`. `nil` when none is well-documented.
    var traditionalName: String? = nil
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
        case cardImageURL = "card_image_url"
        case family
        case descriptionText = "description_text"
        case sunExposure = "sun_exposure"
        case watering
        case phylum
        case originCountry = "origin_country"
        case tagSecondary = "tag_secondary"
        case isNewDiscovery = "is_new_discovery"
        case paletteHexes = "palette_hexes"
        case traditionalName = "traditional_name"
        case botanicalSpirit = "botanical_spirit"
        case ethnobotany
        case culturalLegacy = "cultural_legacy"
    }
}

extension Scan {
    /// Custom decode: a handful of legacy `scans` rows have `NULL` in columns this struct
    /// treats as required (seen in practice: `common_name`). The synthesized decoder fails
    /// the *entire* `[Scan]` array over one bad row — decode leniently instead, so one
    /// malformed row can't take down the whole Herbarium fetch. Declared in an extension
    /// (not the struct body) so the compiler-synthesized memberwise initializer, used
    /// elsewhere to construct `Scan` directly, is preserved. `encode(to:)` stays synthesized.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decodeIfPresent(UUID.self, forKey: .userId)
        treeId = try container.decodeIfPresent(UUID.self, forKey: .treeId)
        let decodedCommonName = try container.decodeIfPresent(String.self, forKey: .commonName)
        let decodedScientificName = try container.decodeIfPresent(String.self, forKey: .scientificName)
        commonName = decodedCommonName ?? decodedScientificName ?? "Unnamed specimen"
        scientificName = decodedScientificName ?? decodedCommonName ?? "Unknown species"
        photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL) ?? ""
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence) ?? 0
        location = try container.decodeIfPresent(String.self, forKey: .location) ?? ""
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        locality = try container.decodeIfPresent(String.self, forKey: .locality)
        cardImageURL = try container.decodeIfPresent(String.self, forKey: .cardImageURL)
        family = try container.decodeIfPresent(String.self, forKey: .family)
        descriptionText = try container.decodeIfPresent(String.self, forKey: .descriptionText)
        sunExposure = try container.decodeIfPresent(String.self, forKey: .sunExposure)
        watering = try container.decodeIfPresent(String.self, forKey: .watering)
        phylum = try container.decodeIfPresent(String.self, forKey: .phylum)
        originCountry = try container.decodeIfPresent(String.self, forKey: .originCountry)
        tagSecondary = try container.decodeIfPresent(String.self, forKey: .tagSecondary)
        isNewDiscovery = try container.decodeIfPresent(Bool.self, forKey: .isNewDiscovery)
        paletteHexes = try container.decodeIfPresent([String].self, forKey: .paletteHexes)
        traditionalName = try container.decodeIfPresent(String.self, forKey: .traditionalName)
        botanicalSpirit = try container.decodeIfPresent(String.self, forKey: .botanicalSpirit)
        ethnobotany = try container.decodeIfPresent(String.self, forKey: .ethnobotany)
        culturalLegacy = try container.decodeIfPresent(String.self, forKey: .culturalLegacy)
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

    /// Capture-location line for UI surfaces: prefer reverse-geocoded locality, then saved location.
    var captureLocationLine: String {
        let local = locality?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !local.isEmpty {
            return BotanyService.displaySafeLocation(local)
        }
        return BotanyService.displaySafeLocation(location)
    }

    /// Optional formatted GPS string for components that support coordinate chips/rows.
    var captureGPSLine: String? {
        guard let latitude, let longitude else { return nil }
        return BotanyService.formatCardinalGPS(latitude: latitude, longitude: longitude)
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
        guard let createdAt else { return String(localized: "Found recently") }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        return "\(String(localized: "Found")) \(f.localizedString(for: createdAt, relativeTo: reference))"
    }

    // MARK: - Thumbnails (`photoURL` / `cardImageURL` may be `file://`, absolute path, or remote)

    private var trimmedPhotoURL: String {
        photoURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedCardImageURL: String {
        cardImageURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private static func resolvedLocalURL(from raw: String) -> URL? {
        guard !raw.isEmpty else { return nil }
        if raw.lowercased().hasPrefix("file://") {
            if let u = URL(string: raw) { return u }
            return URL(fileURLWithPath: String(raw.dropFirst(7)), isDirectory: false)
        }
        if raw.lowercased().hasPrefix("http") {
            return nil
        }
        if raw.hasPrefix("/") {
            return URL(fileURLWithPath: raw)
        }
        return nil
    }

    private static func resolvedRemoteURL(from raw: String) -> URL? {
        guard let u = URL(string: raw), let scheme = u.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return nil
        }
        return u
    }

    /// Local JPEG written under Documents/captures (see `BotanyService.writeCaptureJPEG`).
    var resolvedLocalCaptureURL: URL? { Self.resolvedLocalURL(from: trimmedPhotoURL) }

    /// Filesystem path for a local capture when `photoURL` points at a file (preferred for `UIImage(contentsOfFile:)`).
    var resolvedLocalCaptureFilePath: String? {
        guard let url = resolvedLocalCaptureURL, url.isFileURL else { return nil }
        return url.path
    }

    var resolvedRemoteImageURL: URL? { Self.resolvedRemoteURL(from: trimmedPhotoURL) }

    /// Local auto-processed card image (see `BotanicalCardImageProcessor` / `BotanyService.scheduleCardImageGeneration`).
    var resolvedLocalCardImageURL: URL? { Self.resolvedLocalURL(from: trimmedCardImageURL) }
    var resolvedRemoteCardImageURL: URL? { Self.resolvedRemoteURL(from: trimmedCardImageURL) }

    /// Prefers the processed card image; falls back to the raw capture. Use these for display everywhere
    /// the Botanical Card / Herbarium thumbnails render a specimen photo.
    var resolvedLocalDisplayURL: URL? { resolvedLocalCardImageURL ?? resolvedLocalCaptureURL }
    var resolvedRemoteDisplayURL: URL? { resolvedRemoteCardImageURL ?? resolvedRemoteImageURL }

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
    private static func uiImage(atLocal url: URL?) -> UIImage? {
        guard let url else { return nil }
        if url.isFileURL, let img = UIImage(contentsOfFile: url.path) { return img }
        if let data = try? Data(contentsOf: url), let img = UIImage(data: data) { return img }
        return nil
    }

    /// Loads a local specimen capture for display (file path + `Data` fallbacks).
    func uiImageForLocalCaptureDisplay() -> UIImage? {
        if let path = resolvedLocalCaptureFilePath, let img = UIImage(contentsOfFile: path) { return img }
        if let img = Self.uiImage(atLocal: resolvedLocalCaptureURL) { return img }
        let t = photoURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.hasPrefix("/"), let img = UIImage(contentsOfFile: t) { return img }
        return nil
    }

    /// Prefers the local processed card image; falls back to the raw local capture.
    func uiImageForLocalDisplay() -> UIImage? {
        Self.uiImage(atLocal: resolvedLocalCardImageURL) ?? uiImageForLocalCaptureDisplay()
    }

    func uiImageForLocalCaptureShare() -> UIImage? {
        uiImageForLocalCaptureDisplay()
    }
}
#endif
