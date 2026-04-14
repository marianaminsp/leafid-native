//
//  BotanyService.swift
//  LeafID-native
//
//  Port target: lib/botanyService.ts — identify-plant edge function, Storage `plant-photos`, `scans` insert.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum BotanyServiceError: Error {
    case emptyImagePayload
    case identifyFailed(String)
    case invalidResponse
}

private enum LeafIDSupabaseConfig {
    static var urlString: String? {
        let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
        let t = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !t.isEmpty, t.hasPrefix("http"), !t.contains("$(") else { return nil }
        return t
    }

    static var anonKey: String? {
        let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String
        let t = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !t.isEmpty, !t.contains("$(") else { return nil }
        return t
    }

    static var identifyEndpoint: URL? {
        guard var base = urlString else { return nil }
        if base.hasSuffix("/") { base.removeLast() }
        return URL(string: base + "/functions/v1/identify-plant")
    }
}

private struct IdentifyPlantJSON: Decodable {
    let common_name: String?
    let native_name: String?
    let scientific_name: String?
    let family: String?
    let origin_country: String?
    let curiosity: String?
    let confidence: Double?
    let fallback: Bool?
    let diagnostic_error: String?
    let phylum: String?
    let sun_exposure: String?
    let watering: String?
}

enum BotanyService {
    /// `true` when the app POSTs to your Supabase `identify-plant` function (that function uses Plant.id on the server). `false` = demo-only results, no network identify.
    static var isPlantIdentificationLive: Bool {
        LeafIDSupabaseConfig.identifyEndpoint != nil && LeafIDSupabaseConfig.anonKey != nil
    }

    /// Default capture when opening the scanner from the hero button (until live camera is wired).
    #if canImport(UIKit)
    static func defaultPlaceholderImageData() -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 12, height: 12), format: format)
        let image = renderer.image { ctx in
            let cg = ctx.cgContext
            cg.setFillColor(UIColor(red: 0.06, green: 0.09, blue: 0.05, alpha: 1).cgColor)
            cg.fill(CGRect(x: 0, y: 0, width: 12, height: 12))
            cg.setFillColor(UIColor(red: 0.4, green: 0.6, blue: 0.15, alpha: 1).cgColor)
            cg.fillEllipse(in: CGRect(x: 2, y: 2, width: 8, height: 8))
        }
        return image.jpegData(compressionQuality: 0.9) ?? Data()
    }
    #else
    static func defaultPlaceholderImageData() -> Data { Data() }
    #endif

    static func cleanBase64(_ imageBase64: String) -> String {
        if imageBase64.contains(",") {
            return String(imageBase64.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false).last ?? "")
        }
        return imageBase64
    }

    /// POST to `identify-plant` when `SUPABASE_URL` + `SUPABASE_ANON_KEY` are set in Info.plist (via xcconfig); otherwise mock.
    static func identifyPlantWithAI(imageBase64: String) async throws -> IdentifyPreviewResult {
        guard !imageBase64.isEmpty else { throw BotanyServiceError.emptyImagePayload }

        let clean = cleanBase64(imageBase64)

        guard let endpoint = LeafIDSupabaseConfig.identifyEndpoint,
              let anon = LeafIDSupabaseConfig.anonKey
        else {
            try await Task.sleep(nanoseconds: 600_000_000)
            ProfileStatsLocalStore.incrementTotalScans()
            return IdentifyPreviewResult.offlineDemoPreview()
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(anon)", forHTTPHeaderField: "Authorization")
        request.setValue(anon, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["image": clean])

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 25
        let session = URLSession(configuration: configuration)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw BotanyServiceError.invalidResponse }

        let decoded: IdentifyPlantJSON
        do {
            decoded = try JSONDecoder().decode(IdentifyPlantJSON.self, from: data)
        } catch {
            throw BotanyServiceError.identifyFailed("Invalid response (\(http.statusCode))")
        }

        let common = decoded.common_name?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? decoded.native_name?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? "Unknown specimen"
        let scientific = decoded.scientific_name?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "Species under review"
        let family = decoded.family?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "Unclassified"
        let origin = decoded.origin_country?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "Origin under review"
        let curiosity = decoded.curiosity?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? "Field identification from your specimen."
        let confidence = decoded.confidence.map { min(1, max(0, $0)) } ?? 0.2
        let fallback = decoded.fallback ?? false

        let locationLabel: String
        if fallback, let diag = decoded.diagnostic_error?.trimmingCharacters(in: .whitespacesAndNewlines), !diag.isEmpty {
            locationLabel = diag
        } else if origin.isEmpty || origin == "Origin under review" {
            locationLabel = "Approximate — enable location for Arboretum pins"
        } else {
            locationLabel = origin
        }

        let isNew = !fallback && confidence >= 0.72

        let chipSun = decoded.sun_exposure?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let chipWater = decoded.watering?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let chipPhylum = decoded.phylum?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty

        let tagSecondary: String
        if fallback {
            tagSecondary = "Review image"
        } else if let chipSun {
            tagSecondary = chipSun
        } else if let chipWater {
            tagSecondary = chipWater
        } else {
            tagSecondary = "Field conditions"
        }

        ProfileStatsLocalStore.incrementTotalScans()
        return IdentifyPreviewResult(
            commonName: common,
            scientificName: scientific,
            confidence: confidence,
            locationLabel: locationLabel,
            family: family.uppercased(),
            descriptionText: curiosity,
            originCountry: origin,
            isNewDiscovery: isNew,
            usedFallback: fallback,
            tagSecondary: tagSecondary,
            chipSunExposure: chipSun ?? "",
            chipWatering: chipWater ?? "",
            chipPhylum: chipPhylum ?? ""
        )
    }

    /// Persists a `Scan` into the local collection; extend with Storage upload + Supabase insert.
    @MainActor
    static func saveUserCapture(
        result: IdentifyPreviewResult,
        imageJPEGData: Data?,
        herbarium: HerbariumViewModel
    ) -> UUID {
        let id = UUID()
        let photoURL: String
        if let imageJPEGData,
           let fileURL = writeCaptureJPEG(imageJPEGData, scanId: id) {
            photoURL = fileURL.absoluteString
        } else {
            photoURL = ""
        }

        let scan = Scan(
            id: id,
            userId: nil,
            treeId: nil,
            commonName: result.commonName,
            scientificName: result.scientificName,
            photoURL: photoURL,
            confidence: result.confidence,
            location: result.locationLabel,
            createdAt: Date(),
            latitude: nil,
            longitude: nil,
            family: result.family,
            descriptionText: result.descriptionText,
            sunExposure: result.chipSunExposure.nilIfEmpty,
            watering: result.chipWatering.nilIfEmpty,
            phylum: result.chipPhylum.nilIfEmpty,
            originCountry: result.originCountry.nilIfEmpty,
            tagSecondary: result.tagSecondary.nilIfEmpty,
            isNewDiscovery: result.isNewDiscovery
        )
        herbarium.appendPreservedScan(scan)
        ProfileStatsLocalStore.recordHerbariumSave()
        return id
    }

    private static func writeCaptureJPEG(_ data: Data, scanId: UUID) -> URL? {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let captures = dir.appendingPathComponent("captures", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: captures, withIntermediateDirectories: true)
            let url = captures.appendingPathComponent("\(scanId.uuidString).jpg")
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
