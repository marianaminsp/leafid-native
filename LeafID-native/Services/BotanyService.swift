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
#if canImport(ImageIO)
import ImageIO
#endif
#if canImport(CoreLocation)
import CoreLocation
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
    let diagnostic_code: String?
    let provider: String?
    let provider_fallback_used: Bool?
    let provider_chain: [String]?
    let phylum: String?
    let sun_exposure: String?
    let watering: String?
}

private struct GeminiNarrative: Decodable {
    let origin: String?
    let colors: [String]?
    let botanical_spirit: String?
    let ethnobotany: String?
    let cultural_legacy: String?
    let origin_country: String?
    let palette_hexes: [String]?
}

private enum GeminiConfig {
    /// Stable model id for `generateContent` (unversioned `gemini-1.5-flash` often 404s as aliases change).
    /// See https://ai.google.dev/api/rest/v1beta/models — `gemini-2.0-flash` / `gemini-1.5-flash-002` are typical.
    private static let generateContentModel = "gemini-2.0-flash"

    static func generateContentURL() -> URL? {
        let raw = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String
        let key = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !key.isEmpty, !key.contains("$(") else { return nil }
        var c = URLComponents(string: "https://generativelanguage.googleapis.com/v1beta/models/\(generateContentModel):generateContent")
        c?.queryItems = [URLQueryItem(name: "key", value: key)]
        return c?.url
    }
}

private enum OpenRouterConfig {
    static var apiKey: String? {
        let raw = Bundle.main.object(forInfoDictionaryKey: "OPENROUTER_API_KEY") as? String
        let key = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !key.isEmpty, !key.contains("$(") else { return nil }
        return key
    }

    static let endpoint = URL(string: "https://openrouter.ai/api/v1/chat/completions")
}

enum BotanyService {
    /// `true` when the app POSTs to your Supabase `identify-plant` function (that function uses Plant.id on the server). `false` = demo-only results, no network identify.
    static var isPlantIdentificationLive: Bool {
        LeafIDSupabaseConfig.identifyEndpoint != nil && LeafIDSupabaseConfig.anonKey != nil
    }

    /// `true` when `SUPABASE_URL` + `SUPABASE_ANON_KEY` can be used for Storage upload + `scans` REST insert (Preserve).
    static var isSupabasePreserveConfigured: Bool {
        LeafIDSupabaseConfig.urlString != nil && LeafIDSupabaseConfig.anonKey != nil
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

    #if canImport(UIKit)
    /// Re-encodes JPEG to reduce payload size before Base64 (avoids large uploads / `nw_connection` drops).
    private static func jpegDataCompressedForUpload(_ data: Data, quality: CGFloat = 0.7) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        return image.jpegData(compressionQuality: quality)
    }
    #endif

    /// Prefers `captureJPEGData` (compressed); otherwise decodes `imageBase64` and compresses.
    private static func prepareIdentifyImagePayload(imageBase64: String, captureJPEGData: Data?) throws -> (base64: String, paletteData: Data?) {
        #if canImport(UIKit)
        if let raw = captureJPEGData, !raw.isEmpty, let compressed = jpegDataCompressedForUpload(raw, quality: 0.7) {
            return (compressed.base64EncodedString(), compressed)
        }
        let clean = cleanBase64(imageBase64)
        guard !clean.isEmpty else { throw BotanyServiceError.emptyImagePayload }
        if let decoded = Data(base64Encoded: clean), let compressed = jpegDataCompressedForUpload(decoded, quality: 0.7) {
            return (compressed.base64EncodedString(), compressed)
        }
        return (clean, Data(base64Encoded: clean))
        #else
        let clean = cleanBase64(imageBase64)
        guard !clean.isEmpty else { throw BotanyServiceError.emptyImagePayload }
        return (clean, nil)
        #endif
    }

    /// POST to `identify-plant` when `SUPABASE_URL` + `SUPABASE_ANON_KEY` are set in Info.plist (via xcconfig); otherwise mock.
    static func identifyPlantWithAI(imageBase64: String, captureJPEGData: Data? = nil) async throws -> IdentifyPreviewResult {
        let payload: (base64: String, paletteData: Data?)
        do {
            payload = try prepareIdentifyImagePayload(imageBase64: imageBase64, captureJPEGData: captureJPEGData)
        } catch {
            throw BotanyServiceError.emptyImagePayload
        }
        guard !payload.base64.isEmpty else { throw BotanyServiceError.emptyImagePayload }

        guard let endpoint = LeafIDSupabaseConfig.identifyEndpoint,
              let anon = LeafIDSupabaseConfig.anonKey
        else {
            try await Task.sleep(nanoseconds: 600_000_000)
            ProfileStatsLocalStore.incrementTotalScans()
            let offline = IdentifyPreviewResult.offlineDemoPreview()
            return IdentifyPreviewResult(
                commonName: offline.commonName,
                scientificName: offline.scientificName,
                confidence: offline.confidence,
                locationLabel: offline.locationLabel,
                family: offline.family,
                descriptionText: offline.descriptionText,
                originCountry: offline.originCountry,
                isNewDiscovery: offline.isNewDiscovery,
                usedFallback: offline.usedFallback,
                tagSecondary: offline.tagSecondary,
                chipSunExposure: offline.chipSunExposure,
                chipWatering: offline.chipWatering,
                chipPhylum: offline.chipPhylum,
                paletteHexes: guaranteedPalette(
                    imagePalette: paletteHexes(from: captureJPEGData),
                    geminiPalette: nil
                ),
                botanicalSpirit: offline.botanicalSpirit,
                ethnobotany: offline.ethnobotany,
                culturalLegacy: offline.culturalLegacy
            )
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(anon)", forHTTPHeaderField: "Authorization")
        request.setValue(anon, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["image": payload.base64])

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 45
        configuration.timeoutIntervalForResource = 90
        configuration.waitsForConnectivity = true
        let session = URLSession(configuration: configuration)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw BotanyServiceError.identifyFailed(error.localizedDescription)
        }
        guard let http = response as? HTTPURLResponse else { throw BotanyServiceError.invalidResponse }
        guard (200 ... 299).contains(http.statusCode) else {
            let snippet = String(data: data, encoding: .utf8).map { String($0.prefix(280)) } ?? ""
            throw BotanyServiceError.identifyFailed("identify-plant HTTP \(http.statusCode): \(snippet)")
        }

        let decoded: IdentifyPlantJSON
        do {
            decoded = try decodeIdentifyPlantJSON(from: data)
        } catch {
            #if DEBUG
            print("[LeafID] identify-plant decode error: \(error). Body: \(String(data: data, encoding: .utf8) ?? "")")
            #endif
            throw BotanyServiceError.identifyFailed("Invalid identify response (HTTP \(http.statusCode))")
        }

        let common = decoded.common_name?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? decoded.native_name?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? "Unknown specimen"
        let scientific = decoded.scientific_name?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "Species under review"
        let family = decoded.family?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "Unclassified"
        let plantOrigin = normalizedOrigin(decoded.origin_country)
        let curiosity = decoded.curiosity?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? "Field identification from your specimen."
        let confidence = decoded.confidence.map { min(1, max(0, $0)) } ?? 0.2
        let fallback = decoded.fallback ?? false
        #if DEBUG
        let provider = decoded.provider?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "unspecified"
        let chain = (decoded.provider_chain ?? []).joined(separator: " -> ")
        print("[LeafID] identify provider: \(provider); fallback_used=\(decoded.provider_fallback_used == true); chain=\(chain.isEmpty ? "<none>" : chain)")
        if fallback {
            let diag = decoded.diagnostic_error?.trimmingCharacters(in: .whitespacesAndNewlines)
            let code = decoded.diagnostic_code?.trimmingCharacters(in: .whitespacesAndNewlines)
            print("[LeafID] identify-plant fallback diagnostic_error: \(diag?.isEmpty == false ? diag! : "<none>") | code=\(code?.isEmpty == false ? code! : "<none>")")
        }
        #endif

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

        // Prefer OpenRouter when configured (avoids burning Gemini free-tier quota); Gemini fills gaps.
        let openRouterFirst = await openRouterNarrative(
            commonName: common,
            scientificName: scientific,
            family: family,
            originCountry: plantOrigin ?? "Unknown",
            useFallbackPrompt: fallback
        )
        let needsGemini = OpenRouterConfig.apiKey == nil || hasMissingNarrativeFields(openRouterFirst)
        let gemini = needsGemini
            ? await geminiNarrative(
                commonName: common,
                scientificName: scientific,
                family: family,
                originCountry: plantOrigin ?? "Unknown"
            )
            : nil
        let openRouter = openRouterFirst

        let mergedOrigin = plantOrigin
            ?? normalizedOrigin(gemini?.origin)
            ?? normalizedOrigin(gemini?.origin_country)
            ?? normalizedOrigin(openRouter?.origin)
            ?? normalizedOrigin(openRouter?.origin_country)
        let locationLabel: String
        if fallback, let diag = decoded.diagnostic_error?.trimmingCharacters(in: .whitespacesAndNewlines), !diag.isEmpty {
            locationLabel = diag
        } else if let mergedOrigin {
            locationLabel = mergedOrigin
        } else {
            locationLabel = "Approximate — enable location for Arboretum pins"
        }

        let palette = guaranteedPalette(
            imagePalette: paletteHexes(from: payload.paletteData ?? captureJPEGData),
            geminiPalette: combinedAIPalette(primary: gemini, secondary: openRouter)
        )
        let spirit = firstMeaningful(
            gemini?.botanical_spirit,
            openRouter?.botanical_spirit,
            nonPlaceholderCuriosity(curiosity)
        ) ?? "\(common) (\(scientific)) — \(family)."
        let ethnobotany = firstMeaningful(
            gemini?.ethnobotany,
            openRouter?.ethnobotany,
            compactCareHints(sun: chipSun, water: chipWater, commonName: common)
        ) ?? ""
        let culturalLegacy = firstMeaningful(
            gemini?.cultural_legacy,
            openRouter?.cultural_legacy,
            mergedOrigin.map { "Associated region: \($0)." }
        ) ?? ""

        ProfileStatsLocalStore.incrementTotalScans()
        return IdentifyPreviewResult(
            commonName: common,
            scientificName: scientific,
            confidence: confidence,
            locationLabel: locationLabel,
            family: family.uppercased(),
            descriptionText: curiosity,
            originCountry: mergedOrigin ?? "",
            isNewDiscovery: isNew,
            usedFallback: fallback,
            tagSecondary: tagSecondary,
            chipSunExposure: chipSun ?? "",
            chipWatering: chipWater ?? "",
            chipPhylum: chipPhylum ?? "",
            paletteHexes: palette,
            botanicalSpirit: spirit,
            ethnobotany: ethnobotany,
            culturalLegacy: culturalLegacy
        )
    }

    /// Persists a `Scan` into the local collection; extend with Storage upload + Supabase insert.
    /// Uses `captureLocality` when provided (on-shutter device locality); otherwise reverse-geocodes merged GPS for `locality`.
    /// Returns `nil` when JPEG data is missing/empty or the capture file could not be written (no scan is appended).
    @MainActor
    static func saveUserCapture(
        result: IdentifyPreviewResult,
        imageJPEGData: Data?,
        captureLatitude: Double? = nil,
        captureLongitude: Double? = nil,
        captureLocality: String? = nil,
        herbarium: HerbariumViewModel
    ) async -> UUID? {
        guard let imageJPEGData, !imageJPEGData.isEmpty else {
            #if DEBUG
            print("[LeafID] saveUserCapture: missing or empty imageJPEGData; scan not saved.")
            #endif
            return nil
        }
        let id = UUID()
        guard let fileURL = writeCaptureJPEG(imageJPEGData, scanId: id) else {
            #if DEBUG
            print("[LeafID] saveUserCapture: writeCaptureJPEG failed for scanId=\(id.uuidString)")
            #endif
            return nil
        }
        let photoURL = fileURL.absoluteString

        let mergedLat: Double?
        let mergedLon: Double?
        let locationLine: String
        #if canImport(UIKit) && canImport(ImageIO)
        let merged = mergedLocationLineAndCoordinates(
            result: result,
            imageJPEGData: imageJPEGData,
            captureLatitude: captureLatitude,
            captureLongitude: captureLongitude
        )
        locationLine = merged.locationLine
        mergedLat = merged.mergedLat
        mergedLon = merged.mergedLon
        #else
        mergedLat = captureLatitude
        mergedLon = captureLongitude
        locationLine = result.locationLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        #endif

        #if canImport(CoreLocation)
        let locality = await localityForCapture(
            captureLocality: captureLocality,
            mergedLatitude: mergedLat,
            mergedLongitude: mergedLon
        )
        #else
        let locality: String? = nil
        #endif

        let localPhotoURLString = photoURL
        var resolvedPhotoURL = localPhotoURLString
        if isSupabasePreserveConfigured {
            if let publicURL = await uploadJPEGToPlantPhotosBucket(jpegData: imageJPEGData, objectName: "\(id.uuidString).jpg") {
                resolvedPhotoURL = publicURL
            } else {
                #if DEBUG
                print("[LeafID] Supabase Storage upload failed; using local capture path until retry.")
                #endif
            }
        }

        let scan = Scan(
            id: id,
            userId: nil,
            treeId: nil,
            commonName: result.commonName,
            scientificName: result.scientificName,
            photoURL: resolvedPhotoURL,
            confidence: result.confidence,
            location: locationLine,
            createdAt: Date(),
            latitude: mergedLat,
            longitude: mergedLon,
            locality: locality,
            family: result.family,
            descriptionText: result.descriptionText,
            sunExposure: result.chipSunExposure.nilIfEmpty,
            watering: result.chipWatering.nilIfEmpty,
            phylum: result.chipPhylum.nilIfEmpty,
            originCountry: result.originCountry.nilIfEmpty,
            tagSecondary: result.tagSecondary.nilIfEmpty,
            isNewDiscovery: result.isNewDiscovery,
            paletteHexes: result.paletteHexes,
            botanicalSpirit: result.botanicalSpirit.nilIfEmpty,
            ethnobotany: result.ethnobotany.nilIfEmpty,
            culturalLegacy: result.culturalLegacy.nilIfEmpty
        )

        let remoteInsertSucceeded: Bool
        if isSupabasePreserveConfigured {
            remoteInsertSucceeded = await insertScanRowRest(scan)
        } else {
            remoteInsertSucceeded = false
        }

        herbarium.appendPreservedScan(scan)
        if remoteInsertSucceeded || !isSupabasePreserveConfigured {
            ProfileStatsLocalStore.recordHerbariumSave()
        }

        #if canImport(UIKit) && canImport(CoreLocation)
        if let lat = mergedLat, let lon = mergedLon, isWeakCaptureLocationString(locationLine) {
            scheduleReverseGeocodeForCaptureLocation(scanId: id, latitude: lat, longitude: lon, herbarium: herbarium)
        }
        #endif

        return id
    }

    #if canImport(UIKit)
    /// Builds a non-persisted `Scan` backed by a cache JPEG so `BotanicalCardImmersiveView` can show the current identify result before Preserve.
    @MainActor
    static func buildImmersivePreviewScan(
        result: IdentifyPreviewResult,
        imageJPEGData: Data?,
        captureLatitude: Double?,
        captureLongitude: Double?,
        captureLocality: String? = nil
    ) async -> Scan? {
        guard let imageJPEGData, !imageJPEGData.isEmpty else { return nil }
        let id = UUID()
        guard let fileURL = writeImmersivePreviewJPEG(imageJPEGData, previewId: id) else { return nil }
        let photoURL = fileURL.absoluteString

        let mergedLat: Double?
        let mergedLon: Double?
        let locationLine: String
        #if canImport(ImageIO)
        let merged = mergedLocationLineAndCoordinates(
            result: result,
            imageJPEGData: imageJPEGData,
            captureLatitude: captureLatitude,
            captureLongitude: captureLongitude
        )
        locationLine = merged.locationLine
        mergedLat = merged.mergedLat
        mergedLon = merged.mergedLon
        #else
        mergedLat = captureLatitude
        mergedLon = captureLongitude
        locationLine = result.locationLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        #endif

        #if canImport(CoreLocation)
        let locality = await localityForCapture(
            captureLocality: captureLocality,
            mergedLatitude: mergedLat,
            mergedLongitude: mergedLon
        )
        #else
        let locality: String? = nil
        #endif

        return Scan(
            id: id,
            userId: nil,
            treeId: nil,
            commonName: result.commonName,
            scientificName: result.scientificName,
            photoURL: photoURL,
            confidence: result.confidence,
            location: locationLine,
            createdAt: nil,
            latitude: mergedLat,
            longitude: mergedLon,
            locality: locality,
            family: result.family,
            descriptionText: result.descriptionText,
            sunExposure: result.chipSunExposure.nilIfEmpty,
            watering: result.chipWatering.nilIfEmpty,
            phylum: result.chipPhylum.nilIfEmpty,
            originCountry: result.originCountry.nilIfEmpty,
            tagSecondary: result.tagSecondary.nilIfEmpty,
            isNewDiscovery: result.isNewDiscovery,
            paletteHexes: result.paletteHexes,
            botanicalSpirit: result.botanicalSpirit.nilIfEmpty,
            ethnobotany: result.ethnobotany.nilIfEmpty,
            culturalLegacy: result.culturalLegacy.nilIfEmpty
        )
    }

    /// Removes the cache file created for `buildImmersivePreviewScan` when the immersive sheet closes.
    static func deleteImmersivePreviewCaptureFileIfNeeded(path: String?) {
        guard let path, path.contains("leafid-immersive-preview") else { return }
        try? FileManager.default.removeItem(atPath: path)
    }

    static func deleteImmersivePreviewCaptureFileIfNeeded(for scan: Scan) {
        deleteImmersivePreviewCaptureFileIfNeeded(path: scan.resolvedLocalCaptureFilePath)
    }
    #endif

    /// `true` when a saved `location` line should be replaced by IPTC / reverse-geocode when possible.
    static func isWeakCaptureLocationString(_ raw: String) -> Bool {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if t.isEmpty { return true }
        if t == "—" { return true }
        if t == "location pending" { return true }
        if t.contains("origin data not provided") { return true }
        if t.contains("origin not provided") { return true }
        if t.contains("not provided") { return true }
        if t == "unknown" { return true }
        if t == "region not specified" { return true }
        return false
    }

    /// Shared GPS caption for cards (monospaced Manrope applied at call site).
    static func formatCardinalGPS(latitude: Double, longitude: Double) -> String {
        let latHem = latitude >= 0 ? "N" : "S"
        let lonHem = longitude >= 0 ? "E" : "W"
        let la = abs(latitude)
        let lo = abs(longitude)
        return "\(latHem) \(String(format: "%.4f", la))° · \(lonHem) \(String(format: "%.4f", lo))°"
    }

    /// Decodes top-level `IdentifyPlantJSON` or common wrapper objects from edge functions.
    private static func decodeIdentifyPlantJSON(from data: Data) throws -> IdentifyPlantJSON {
        if let v = try? JSONDecoder().decode(IdentifyPlantJSON.self, from: data) {
            return v
        }
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BotanyServiceError.invalidResponse
        }
        for key in ["data", "result", "plant", "identification", "payload"] {
            if let inner = obj[key] as? [String: Any],
               let innerData = try? JSONSerialization.data(withJSONObject: inner),
               let v = try? JSONDecoder().decode(IdentifyPlantJSON.self, from: innerData) {
                return v
            }
        }
        throw BotanyServiceError.invalidResponse
    }

    private static func nonPlaceholderCuriosity(_ raw: String) -> String? {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return nil }
        if t == "Field identification from your specimen." { return nil }
        return t
    }

    private static func compactCareHints(sun: String?, water: String?, commonName: String) -> String? {
        let s = sun.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.flatMap { $0.isEmpty ? nil : $0 }
        let w = water.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.flatMap { $0.isEmpty ? nil : $0 }
        guard s != nil || w != nil else { return nil }
        if let s, let w { return "\(commonName): \(s); \(w)." }
        if let s { return "\(commonName): \(s)." }
        return "\(commonName): \(w!)."
    }

    private static func geminiNarrative(
        commonName: String,
        scientificName: String,
        family: String,
        originCountry: String
    ) async -> GeminiNarrative? {
        guard let endpoint = GeminiConfig.generateContentURL() else { return nil }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        let prompt = """
        Return ONLY valid JSON (no markdown, no explanations, no code fences).
        Required keys:
        - origin
        - botanical_spirit
        - ethnobotany
        - cultural_legacy
        - colors
        Rules:
        - origin: short location string (country or region)
        - botanical_spirit / ethnobotany / cultural_legacy: each <= 220 chars
        - colors: array with exactly 3 hex values in #RRGGBB format
        Species: \(scientificName)
        Common name: \(commonName)
        Family: \(family)
        Origin: \(originCountry)
        """
        let userTurn: [String: Any] = [
            "role": "user",
            "parts": [
                ["text": prompt] as [String: Any],
            ],
        ]
        let body: [String: Any] = ["contents": [userTurn]]
        guard let payload = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        request.httpBody = payload

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 45
        configuration.waitsForConnectivity = true
        let session = URLSession(configuration: configuration)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            #if DEBUG
            print("[Gemini Error] \(error.localizedDescription)")
            #endif
            return nil
        }
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            #if DEBUG
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            let rawBody = String(data: data, encoding: .utf8) ?? "<non-utf8>"
            print("[Gemini HTTP \(code)] \(rawBody.prefix(500))")
            if code == 429 {
                print("[Gemini] 429 = free-tier quota; OpenRouter is used first when configured.")
            }
            #endif
            return nil
        }
        #if DEBUG
        let rawBody = String(data: data, encoding: .utf8) ?? "<non-utf8>"
        print("[Gemini RAW Response] \(rawBody.prefix(800))")
        #endif
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String
        else { return nil }

        #if DEBUG
        print("[Gemini Text Payload] \(text.prefix(400))")
        #endif

        guard let normalized = normalizedJSONObjectString(from: text),
              let raw = normalized.data(using: .utf8)
        else { return nil }
        return try? JSONDecoder().decode(GeminiNarrative.self, from: raw)
    }

    private static func normalizedJSONObjectString(from text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let withoutFence: String
        if trimmed.hasPrefix("```") {
            withoutFence = trimmed
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```JSON", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            withoutFence = trimmed
        }

        guard let start = withoutFence.firstIndex(of: "{"),
              let end = withoutFence.lastIndex(of: "}")
        else { return nil }
        return String(withoutFence[start ... end])
    }

    private static func openRouterNarrative(
        commonName: String,
        scientificName: String,
        family: String,
        originCountry: String,
        useFallbackPrompt: Bool
    ) async -> GeminiNarrative? {
        guard let key = OpenRouterConfig.apiKey, let endpoint = OpenRouterConfig.endpoint else { return nil }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 6

        let prompt = narrativeJSONPrompt(
            commonName: commonName,
            scientificName: scientificName,
            family: family,
            originCountry: originCountry,
            useFallbackPrompt: useFallbackPrompt
        )
        let body: [String: Any] = [
            "model": "openrouter/free",
            "messages": [
                ["role": "user", "content": prompt],
            ],
            "temperature": 0.6,
        ]
        guard let payload = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        request.httpBody = payload

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 429 { return nil }
            #if DEBUG
            print("[OpenRouter RAW Response] \(String(data: data, encoding: .utf8) ?? "<non-utf8>")")
            #endif
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let text = message["content"] as? String,
                  let normalized = normalizedJSONObjectString(from: text),
                  let raw = normalized.data(using: .utf8)
            else { return nil }
            #if DEBUG
            print("[OpenRouter Text Payload] \(text)")
            #endif
            return try? JSONDecoder().decode(GeminiNarrative.self, from: raw)
        } catch {
            #if DEBUG
            print("[OpenRouter Error] \(error.localizedDescription)")
            #endif
            return nil
        }
    }

    private static func narrativeJSONPrompt(
        commonName: String,
        scientificName: String,
        family: String,
        originCountry: String,
        useFallbackPrompt: Bool
    ) -> String {
        if useFallbackPrompt {
            return """
            Return ONLY valid JSON (no markdown, no explanations, no code fences).
            Required keys:
            - origin
            - botanical_spirit
            - ethnobotany
            - cultural_legacy
            - colors
            Rules:
            - Write about a mysterious plant found in nature (generic, poetic, grounded).
            - Never use the words "under review" or "unknown".
            - origin: short location string (country or region)
            - botanical_spirit / ethnobotany / cultural_legacy: each <= 220 chars
            - colors: array with exactly 3 hex values in #RRGGBB format
            """
        }
        return """
        Return ONLY valid JSON (no markdown, no explanations, no code fences).
        Required keys:
        - origin
        - botanical_spirit
        - ethnobotany
        - cultural_legacy
        - colors
        Rules:
        - origin: short location string (country or region)
        - botanical_spirit / ethnobotany / cultural_legacy: each <= 220 chars
        - colors: array with exactly 3 hex values in #RRGGBB format
        Species: \(scientificName)
        Common name: \(commonName)
        Family: \(family)
        Origin: \(originCountry)
        """
    }

    #if canImport(UIKit)
    private static func paletteHexes(from imageData: Data?) -> [String]? {
        guard let imageData, let ui = UIImage(data: imageData), let cg = ui.cgImage else { return nil }
        let width = 32
        let height = 32
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var pixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        guard let ctx = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
        var bins: [Int: Int] = [:]
        var reps: [Int: (Int, Int, Int)] = [:]
        for i in stride(from: 0, to: pixels.count, by: 4) {
            let r = Int(pixels[i]); let g = Int(pixels[i + 1]); let b = Int(pixels[i + 2])
            let qr = (r / 32) * 32
            let qg = (g / 32) * 32
            let qb = (b / 32) * 32
            let key = (qr << 16) | (qg << 8) | qb
            bins[key, default: 0] += 1
            reps[key] = (qr, qg, qb)
        }
        let top = bins.sorted { $0.value > $1.value }.prefix(3).compactMap { reps[$0.key] }
        guard !top.isEmpty else { return nil }
        return top.map { rgbToHex($0.0, $0.1, $0.2) }
    }
    #else
    private static func paletteHexes(from _: Data?) -> [String]? { nil }
    #endif

    private static func rgbToHex(_ r: Int, _ g: Int, _ b: Int) -> String {
        String(format: "#%02X%02X%02X", r, g, b)
    }

    private static func guaranteedPalette(imagePalette: [String]?, geminiPalette: [String]?) -> [String] {
        let fallback = ["#2C4C1A", "#7AAE2E", "#6B4F2E"]
        var merged: [String] = []
        for hex in (imagePalette ?? []) + (geminiPalette ?? []) {
            guard let valid = normalizedHex(hex) else { continue }
            if !merged.contains(valid) {
                merged.append(valid)
            }
            if merged.count == 3 { return merged }
        }
        for hex in fallback where merged.count < 3 {
            if !merged.contains(hex) { merged.append(hex) }
        }
        return Array(merged.prefix(3))
    }

    private static func combinedAIPalette(primary: GeminiNarrative?, secondary: GeminiNarrative?) -> [String] {
        let p1 = (primary?.colors ?? primary?.palette_hexes ?? [])
        let p2 = (secondary?.colors ?? secondary?.palette_hexes ?? [])
        return p1 + p2
    }

    private static func hasMissingNarrativeFields(_ narrative: GeminiNarrative?) -> Bool {
        guard let narrative else { return true }
        return firstMeaningful(narrative.botanical_spirit) == nil
            || firstMeaningful(narrative.ethnobotany) == nil
            || firstMeaningful(narrative.cultural_legacy) == nil
    }

    private static func firstMeaningful(_ values: String?...) -> String? {
        for v in values {
            let t = v?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !t.isEmpty { return t }
        }
        return nil
    }

    private static func normalizedHex(_ raw: String?) -> String? {
        let t = (raw ?? "").trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !t.isEmpty else { return nil }
        let noHash = t.hasPrefix("#") ? String(t.dropFirst()) : t
        guard noHash.count == 6, noHash.range(of: "^[0-9A-F]{6}$", options: .regularExpression) != nil else {
            return nil
        }
        return "#\(noHash)"
    }

    private static func normalizedOrigin(_ raw: String?) -> String? {
        let t = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !t.isEmpty else { return nil }
        let lowered = t.lowercased()
        if lowered == "not provided" || lowered == "unknown" || lowered == "origin under review" || t == "—" {
            return nil
        }
        return t
    }

    static func runGeminiStressTest() async -> [String] {
        let samples: [(common: String, scientific: String, family: String, origin: String)] = [
            ("Monstera Deliciosa", "Monstera deliciosa", "Araceae", "Mexico"),
            ("Lavender", "Lavandula angustifolia", "Lamiaceae", "Mediterranean"),
            ("English Oak", "Quercus robur", "Fagaceae", "Europe"),
            ("Rubber Plant", "Ficus elastica", "Moraceae", "South Asia"),
            ("Rose", "Rosa rubiginosa", "Rosaceae", "Eurasia"),
        ]
        var lines: [String] = []
        for s in samples {
            let res = await geminiNarrative(
                commonName: s.common,
                scientificName: s.scientific,
                family: s.family,
                originCountry: s.origin
            )
            let origin = normalizedOrigin(res?.origin) ?? normalizedOrigin(res?.origin_country) ?? "-"
            let spirit = (res?.botanical_spirit ?? "-").prefix(48)
            let colors = guaranteedPalette(imagePalette: nil, geminiPalette: res?.colors ?? res?.palette_hexes).joined(separator: ",")
            lines.append("\(s.scientific): origin=\(origin) colors=\(colors) spirit=\(spirit)")
        }
        #if DEBUG
        print("[Gemini Stress Test] \(lines.joined(separator: " | "))")
        #endif
        return lines
    }

    #if canImport(UIKit) && canImport(ImageIO)
    /// EXIF GPS + IPTC city/region strings read from a saved capture or in-memory JPEG.
    struct CaptureImageMetadataResult {
        var coordinate: (latitude: Double, longitude: Double)?
        var iptcPlacemarkLine: String?
    }

    static func readCaptureMetadata(fromJPEGData data: Data) -> CaptureImageMetadataResult {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else {
            return CaptureImageMetadataResult(coordinate: nil, iptcPlacemarkLine: nil)
        }
        return readCaptureMetadata(imageSource: src)
    }

    static func readCaptureMetadata(fromFileURL url: URL) -> CaptureImageMetadataResult {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return CaptureImageMetadataResult(coordinate: nil, iptcPlacemarkLine: nil)
        }
        return readCaptureMetadata(imageSource: src)
    }

    private static func readCaptureMetadata(imageSource src: CGImageSource) -> CaptureImageMetadataResult {
        guard let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [String: Any] else {
            return CaptureImageMetadataResult(coordinate: nil, iptcPlacemarkLine: nil)
        }
        let coord = gpsCoordinate(from: props)
        let iptc = iptcPlacemarkLine(from: props)
        return CaptureImageMetadataResult(coordinate: coord, iptcPlacemarkLine: iptc)
    }

    private static func gpsCoordinate(from props: [String: Any]) -> (latitude: Double, longitude: Double)? {
        guard let gps = props[kCGImagePropertyGPSDictionary as String] as? [String: Any] else { return nil }
        guard let latDeg = gpsDegrees(from: gps[kCGImagePropertyGPSLatitude as String]),
              let lonDeg = gpsDegrees(from: gps[kCGImagePropertyGPSLongitude as String]) else {
            return nil
        }
        var lat = abs(latDeg)
        if (gps[kCGImagePropertyGPSLatitudeRef as String] as? String)?.uppercased() == "S" {
            lat = -lat
        }
        var lon = abs(lonDeg)
        if (gps[kCGImagePropertyGPSLongitudeRef as String] as? String)?.uppercased() == "W" {
            lon = -lon
        }
        return (lat, lon)
    }

    private static func iptcPlacemarkLine(from props: [String: Any]) -> String? {
        guard let iptc = props[kCGImagePropertyIPTCDictionary as String] as? [String: Any] else { return nil }
        func str(_ key: String) -> String? {
            if let s = iptc[key] as? String {
                let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
                return t.isEmpty ? nil : t
            }
            if let n = iptc[key] as? NSNumber {
                return n.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return nil
        }
        let city = str(kCGImagePropertyIPTCCity as String)
        let sub = str(kCGImagePropertyIPTCSubLocation as String)
        let province = str(kCGImagePropertyIPTCProvinceState as String)
        let country = str(kCGImagePropertyIPTCCountryPrimaryLocationName as String)
        let parts = [sub, city, province, country].compactMap { $0 }.filter { !$0.isEmpty }
        guard !parts.isEmpty else { return nil }
        var seen = Set<String>()
        let unique = parts.filter { seen.insert($0.lowercased()).inserted }
        return unique.joined(separator: ", ")
    }

    private static func gpsDegrees(from value: Any?) -> Double? {
        guard let value else { return nil }
        if let d = value as? Double { return d }
        if let n = value as? NSNumber { return n.doubleValue }
        if let arr = value as? [Any] { return gpsDmsToDecimal(arr) }
        if let arr = value as? NSArray {
            return gpsDmsToDecimal((0 ..< arr.count).compactMap { arr.object(at: $0) as Any })
        }
        return nil
    }

    private static func gpsDmsToDecimal(_ parts: [Any]) -> Double? {
        guard parts.count >= 3 else { return nil }
        guard let d = gpsRationalToDouble(parts[0]),
              let m = gpsRationalToDouble(parts[1]),
              let s = gpsRationalToDouble(parts[2]) else { return nil }
        return abs(d) + abs(m) / 60.0 + abs(s) / 3600.0
    }

    private static func gpsRationalToDouble(_ value: Any) -> Double? {
        if let d = value as? Double { return d }
        if let n = value as? NSNumber { return n.doubleValue }
        if let dict = value as? NSDictionary {
            let num = dict.object(forKey: "Numerator" as NSString) as? NSNumber
                ?? dict.object(forKey: "numerator" as NSString) as? NSNumber
            let den = dict.object(forKey: "Denominator" as NSString) as? NSNumber
                ?? dict.object(forKey: "denominator" as NSString) as? NSNumber
            guard let num, let den, den.doubleValue != 0 else { return nil }
            return num.doubleValue / den.doubleValue
        }
        if let dict = value as? [String: Any] {
            let num = (dict["Numerator"] as? NSNumber)?.doubleValue
                ?? (dict["numerator"] as? NSNumber)?.doubleValue
            let den = (dict["Denominator"] as? NSNumber)?.doubleValue
                ?? (dict["denominator"] as? NSNumber)?.doubleValue
            guard let num, let den, den != 0 else { return nil }
            return num / den
        }
        return nil
    }
    #endif

    #if canImport(UIKit) && canImport(CoreLocation)
    private static func scheduleReverseGeocodeForCaptureLocation(
        scanId: UUID,
        latitude: Double,
        longitude: Double,
        herbarium: HerbariumViewModel
    ) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, _ in
            guard let placemark = placemarks?.first else { return }
            let city = placemark.locality?.trimmingCharacters(in: .whitespacesAndNewlines)
            let sub = placemark.subLocality?.trimmingCharacters(in: .whitespacesAndNewlines)
            let region = placemark.administrativeArea?.trimmingCharacters(in: .whitespacesAndNewlines)
            let country = placemark.country?.trimmingCharacters(in: .whitespacesAndNewlines)
            var parts: [String] = []
            if let s = sub, !s.isEmpty { parts.append(s) }
            if let c = city, !c.isEmpty { parts.append(c) }
            if let r = region, !r.isEmpty, r != city { parts.append(r) }
            if let co = country, !co.isEmpty { parts.append(co) }
            let line = parts.joined(separator: ", ")
            let localityName: String? = {
                if let c = city, !c.isEmpty { return c }
                if let s = sub, !s.isEmpty { return s }
                return nil
            }()
            guard !line.isEmpty || localityName != nil else { return }
            DispatchQueue.main.async {
                herbarium.patchPreservedScan(id: scanId) { scan in
                    if scan.locality == nil, let loc = localityName { scan.locality = loc }
                    guard !line.isEmpty else { return }
                    guard BotanyService.isWeakCaptureLocationString(scan.location) else { return }
                    scan.location = line
                }
            }
        }
    }
    #endif

    #if canImport(UIKit) && canImport(ImageIO)
    private static func mergedLocationLineAndCoordinates(
        result: IdentifyPreviewResult,
        imageJPEGData: Data,
        captureLatitude: Double?,
        captureLongitude: Double?
    ) -> (locationLine: String, mergedLat: Double?, mergedLon: Double?) {
        let exif = readCaptureMetadata(fromJPEGData: imageJPEGData)
        let mergedLat = captureLatitude ?? exif.coordinate?.latitude
        let mergedLon = captureLongitude ?? exif.coordinate?.longitude
        let resultLoc = result.locationLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let iptcLine = exif.iptcPlacemarkLine?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let locationLine: String = {
            if !iptcLine.isEmpty, !isWeakCaptureLocationString(iptcLine) { return iptcLine }
            if !resultLoc.isEmpty, !isWeakCaptureLocationString(resultLoc) { return resultLoc }
            if !iptcLine.isEmpty { return iptcLine }
            if !resultLoc.isEmpty { return resultLoc }
            return "Location pending"
        }()
        return (locationLine, mergedLat, mergedLon)
    }
    #endif

    #if canImport(CoreLocation)
    private static func reverseGeocodeLocality(latitude: Double, longitude: Double) async -> String? {
        await withCheckedContinuation { continuation in
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(CLLocation(latitude: latitude, longitude: longitude)) { placemarks, _ in
                let resolved: String? = {
                    guard let p = placemarks?.first else { return nil }
                    if let s = p.locality?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty { return s }
                    if let s = p.subLocality?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty { return s }
                    if let s = p.subAdministrativeArea?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
                        return s
                    }
                    return nil
                }()
                continuation.resume(returning: resolved)
            }
        }
    }

    private static func localityForCapture(
        captureLocality: String?,
        mergedLatitude: Double?,
        mergedLongitude: Double?
    ) async -> String? {
        let trimmed = captureLocality?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmed.isEmpty { return trimmed }
        guard let la = mergedLatitude, let lo = mergedLongitude else { return nil }
        return await reverseGeocodeLocality(latitude: la, longitude: lo)
    }
    #endif

    #if canImport(UIKit)
    private static func writeImmersivePreviewJPEG(_ data: Data, previewId: UUID) -> URL? {
        guard !data.isEmpty else { return nil }
        guard let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dir = caches.appendingPathComponent("leafid-immersive-preview", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let url = dir.appendingPathComponent("\(previewId.uuidString).jpg")
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
    #endif

    private static func writeCaptureJPEG(_ data: Data, scanId: UUID) -> URL? {
        guard !data.isEmpty else { return nil }
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

    // MARK: - Supabase Preserve (Storage `plant-photos` + `public.scans` via PostgREST)

    /// When `false`, PostgREST inserts omit `latitude` / `longitude` / `locality` so inserts succeed if those columns are not migrated yet. Set to `true` after adding nullable columns on `public.scans`.
    private static let postgRESTScansIncludeGeoColumns = true

    private static func supabaseProjectRootURLString() -> String? {
        guard var base = LeafIDSupabaseConfig.urlString else { return nil }
        if base.hasSuffix("/") { base.removeLast() }
        return base
    }

    /// Uploads JPEG to the `plant-photos` bucket and returns the **public** URL for `scans.photo_url`.
    private static func uploadJPEGToPlantPhotosBucket(jpegData: Data, objectName: String) async -> String? {
        guard let root = supabaseProjectRootURLString(), let anon = LeafIDSupabaseConfig.anonKey else { return nil }
        let safeName = objectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !safeName.isEmpty, !jpegData.isEmpty else { return nil }
        guard let uploadURL = URL(string: "\(root)/storage/v1/object/plant-photos/\(safeName)") else { return nil }

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(anon)", forHTTPHeaderField: "Authorization")
        request.setValue(anon, forHTTPHeaderField: "apikey")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "x-upsert")
        request.httpBody = jpegData

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 90
        configuration.timeoutIntervalForResource = 120
        let session = URLSession(configuration: configuration)

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { return nil }
            guard (200 ... 299).contains(http.statusCode) else {
                #if DEBUG
                let msg = String(data: data, encoding: .utf8) ?? ""
                print("[LeafID] Storage upload HTTP \(http.statusCode): \(msg)")
                #endif
                return nil
            }
            return "\(root)/storage/v1/object/public/plant-photos/\(safeName)"
        } catch {
            #if DEBUG
            print("[LeafID] Storage upload error: \(error.localizedDescription)")
            #endif
            return nil
        }
    }

    /// Inserts one row into `public.scans` (PostgREST). Geo fields are optional in the JSON when `postgRESTScansIncludeGeoColumns` is enabled and the table has those columns.
    private static func insertScanRowRest(_ scan: Scan) async -> Bool {
        guard let root = supabaseProjectRootURLString(), let anon = LeafIDSupabaseConfig.anonKey else { return false }
        guard let url = URL(string: "\(root)/rest/v1/scans") else { return false }

        var row: [String: Any] = [
            "id": scan.id.uuidString,
            "common_name": scan.commonName,
            "scientific_name": scan.scientificName,
            "photo_url": scan.photoURL,
            "confidence": scan.confidence,
            "location": scan.location,
        ]
        if postgRESTScansIncludeGeoColumns {
            if let lat = scan.latitude { row["latitude"] = lat }
            if let lon = scan.longitude { row["longitude"] = lon }
            if let loc = scan.locality?.trimmingCharacters(in: .whitespacesAndNewlines), !loc.isEmpty {
                row["locality"] = loc
            }
        }
        if let uid = scan.userId {
            row["user_id"] = uid.uuidString
        }
        if let tid = scan.treeId {
            row["tree_id"] = tid.uuidString
        }

        guard let body = try? JSONSerialization.data(withJSONObject: [row]) else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(anon)", forHTTPHeaderField: "Authorization")
        request.setValue(anon, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = body

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 45
        let session = URLSession(configuration: configuration)

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            if (200 ... 299).contains(http.statusCode) {
                return true
            }
            #if DEBUG
            let msg = String(data: data, encoding: .utf8) ?? ""
            print("[LeafID] scans insert HTTP \(http.statusCode): \(msg)")
            #endif
            return false
        } catch {
            #if DEBUG
            print("[LeafID] scans insert error: \(error.localizedDescription)")
            #endif
            return false
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
