//
//  BotanyService.swift
//  LeafID-native
//
//  Port target: lib/botanyService.ts — identify-plant edge function, Storage `plant-images`, `scans` insert/fetch.
//

import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(ImageIO)
import ImageIO
#endif
#if canImport(CoreLocation)
import CoreLocation
#endif

enum BotanyServiceError: Error, LocalizedError {
    case emptyImagePayload
    case identifyFailed(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .emptyImagePayload:
            return String(localized: "Photo data is missing. Try another image.")
        case .identifyFailed(let detail):
            return detail
        case .invalidResponse:
            return String(localized: "Couldn’t read the identification response. Try again.")
        }
    }
}

private enum LeafIDSupabaseConfig {
    static var urlString: String? {
        let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
        var t = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if t.hasPrefix("\""), t.hasSuffix("\""), t.count >= 2 {
            t = String(t.dropFirst().dropLast())
        }
        guard !t.isEmpty, t.hasPrefix("http"), !t.contains("$(") else { return nil }
        guard let host = URL(string: t)?.host, host.contains(".") else { return nil }
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

    static var narrateEndpoint: URL? {
        guard var base = urlString else { return nil }
        if base.hasSuffix("/") { base.removeLast() }
        return URL(string: base + "/functions/v1/narrate-plant")
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
    let traditional_name: String?
    let botanical_spirit: String?
    let ethnobotany: String?
    let cultural_legacy: String?
    let origin_country: String?
    let palette_hexes: [String]?
}

enum BotanyService {
    private static let unknownOriginFallback = "Origin unavailable"
    private static let identifyCacheKey = "leafid.identify.cache.v1"
    private static let identifyCacheMaxEntries = 160
    private static let perceptualMatchMaxHammingDistance = 6

    /// `true` when the app POSTs to your Supabase `identify-plant` function (that function uses Plant.id on the server). `false` = demo-only results, no network identify.
    static var isPlantIdentificationLive: Bool {
        LeafIDSupabaseConfig.identifyEndpoint != nil && LeafIDSupabaseConfig.anonKey != nil
    }

    /// `true` when `SUPABASE_URL` + `SUPABASE_ANON_KEY` can be used for Storage upload + `scans` REST insert (Preserve).
    static var isSupabasePreserveConfigured: Bool {
        LeafIDSupabaseConfig.urlString != nil && LeafIDSupabaseConfig.anonKey != nil
    }

    /// Kill-switch for the on-device Botanical Card auto-processing pipeline (crop + level + brand
    /// grade). Flip to `false` to fall back to showing raw captures everywhere without a build change
    /// to the flag's *effect* (the rendering fallback always exists) — only the *generation* stops.
    static let isCardImageProcessingEnabled = true

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
        let sourceImageData = payload.paletteData ?? captureJPEGData

        if let cached = cachedIdentifyResult(for: sourceImageData) {
            ProfileStatsLocalStore.incrementTotalScans()
            return cached
        }

        guard let endpoint = LeafIDSupabaseConfig.identifyEndpoint,
              let anon = LeafIDSupabaseConfig.anonKey
        else {
            try await Task.sleep(nanoseconds: 600_000_000)
            ProfileStatsLocalStore.incrementTotalScans()
            let offline = IdentifyPreviewResult.offlineDemoPreview()
            let preview = IdentifyPreviewResult(
                commonName: offline.commonName,
                scientificName: offline.scientificName,
                confidence: offline.confidence,
                locationLabel: displaySafeLocation(offline.locationLabel),
                family: offline.family,
                descriptionText: offline.descriptionText,
                originCountry: displaySafeOrigin(offline.originCountry),
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
                traditionalName: offline.traditionalName,
                botanicalSpirit: offline.botanicalSpirit,
                ethnobotany: offline.ethnobotany,
                culturalLegacy: offline.culturalLegacy
            )
            storeIdentifyCache(preview: preview, imageData: sourceImageData)
            return preview
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

        // Cultural/historical narrative is generated server-side (narrate-plant edge function),
        // same free-tier-conscious provider order (OpenRouter free router, Gemini fallback) as
        // before — just moved off-device so the LLM keys never ship inside the app binary.
        let narrative = await fetchNarrative(
            commonName: common,
            scientificName: scientific,
            family: family,
            originCountry: plantOrigin ?? "Unknown",
            useFallbackPrompt: fallback
        )

        let wikiOrigin = await freeOriginFromWikipedia(scientificName: scientific, commonName: common)
        let mergedOrigin = plantOrigin
            ?? normalizedOrigin(narrative?.origin)
            ?? normalizedOrigin(narrative?.origin_country)
            ?? wikiOrigin
        let locationLabel = displaySafeLocation(mergedOrigin ?? unknownOriginFallback)

        let palette = guaranteedPalette(
            imagePalette: paletteHexes(from: payload.paletteData ?? captureJPEGData),
            geminiPalette: narrative?.colors ?? narrative?.palette_hexes
        )
        let traditionalName = narrative?.traditional_name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let spirit = firstMeaningful(
            narrative?.botanical_spirit,
            nonPlaceholderCuriosity(curiosity)
        ) ?? "\(common) (\(scientific)) — \(family)."
        let ethnobotany = firstMeaningful(
            narrative?.ethnobotany,
            compactCareHints(sun: chipSun, water: chipWater, commonName: common)
        ) ?? ""
        var culturalLegacy = firstMeaningful(
            narrative?.cultural_legacy,
            mergedOrigin.map { "Associated region: \($0)." }
        ) ?? ""
        culturalLegacy = culturalLegacy.trimmingCharacters(in: .whitespacesAndNewlines.union(.newlines))
        if culturalLegacy.isEmpty {
            culturalLegacy = fallbackCulturalLegacyPhrase(
                commonName: common,
                scientificName: scientific,
                family: family,
                originLine: mergedOrigin
            )
        } else {
            culturalLegacy = clampNarrativeLine(culturalLegacy)
        }

        ProfileStatsLocalStore.incrementTotalScans()
        let preview = IdentifyPreviewResult(
            commonName: common,
            scientificName: scientific,
            confidence: confidence,
            locationLabel: locationLabel,
            family: family.uppercased(),
            descriptionText: curiosity,
            originCountry: displaySafeOrigin(mergedOrigin),
            isNewDiscovery: isNew,
            usedFallback: fallback,
            tagSecondary: tagSecondary,
            chipSunExposure: chipSun ?? "",
            chipWatering: chipWater ?? "",
            chipPhylum: chipPhylum ?? "",
            paletteHexes: palette,
            traditionalName: traditionalName,
            botanicalSpirit: spirit,
            ethnobotany: ethnobotany,
            culturalLegacy: culturalLegacy
        )
        storeIdentifyCache(preview: preview, imageData: sourceImageData)
        return preview
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
        herbarium: HerbariumViewModel,
        accessToken: String? = nil,
        userId: UUID? = nil
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

        var mergedLat: Double?
        var mergedLon: Double?
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
        locationLine = displaySafeLocation(result.locationLabel)
        #endif

        #if canImport(CoreLocation)
        if mergedLat == nil || mergedLon == nil {
            // Backfilling GPS during save shouldn't block the save flow on a first-time permission
            // dialog — keep both waits short here; Arboretum's explicit "locate me" is where we're
            // willing to wait out a real permission prompt.
            let deviceShot = await OneShotLocationRequest().requestCoordinateAndLocality(
                fixWaitSeconds: 2.5,
                authorizationWaitSeconds: 2.5
            )
            if let c = deviceShot.0 {
                mergedLat = c.latitude
                mergedLon = c.longitude
            }
        }
        #endif

        #if canImport(CoreLocation)
        let locality = await localityForCapture(
            captureLocality: captureLocality,
            mergedLatitude: mergedLat,
            mergedLongitude: mergedLon
        )
        let captureCountry = await countryForCapture(mergedLatitude: mergedLat, mergedLongitude: mergedLon)
        #else
        let locality: String? = nil
        let captureCountry: String? = nil
        #endif

        let localPhotoURLString = photoURL
        var resolvedPhotoURL = localPhotoURLString
        if isSupabasePreserveConfigured,
           let token = accessToken,
           let ownerId = userId
        {
            if let publicURL = await uploadJPEGToPlantImagesBucket(
                jpegData: imageJPEGData,
                scanId: id,
                userId: ownerId,
                accessToken: token
            ) {
                resolvedPhotoURL = publicURL
            } else {
                #if DEBUG
                print("[LeafID] Supabase Storage upload failed; using local capture path until retry.")
                #endif
            }
        } else if isSupabasePreserveConfigured {
            #if DEBUG
            print("[LeafID] Preserve: missing session; skipping Storage upload (sign in required for bucket RLS).")
            #endif
        }

        let localityFallback = locality?.trimmingCharacters(in: .whitespacesAndNewlines)
        let canonicalLocationSource: String = {
            if let localityFallback, !localityFallback.isEmpty {
                let current = locationLine.trimmingCharacters(in: .whitespacesAndNewlines)
                if current.isEmpty || isWeakCaptureLocationString(current) {
                    return localityFallback
                }
            }
            return locationLine
        }()
        let safeLocationLine = displaySafeLocation(canonicalLocationSource)
        let safeOrigin = displaySafeOrigin(result.originCountry.nilIfEmpty ?? captureCountry)
        let scan = Scan(
            id: id,
            userId: userId,
            treeId: nil,
            commonName: result.commonName,
            scientificName: result.scientificName,
            photoURL: resolvedPhotoURL,
            confidence: result.confidence,
            location: safeLocationLine,
            createdAt: Date(),
            latitude: mergedLat,
            longitude: mergedLon,
            locality: locality,
            family: result.family,
            descriptionText: result.descriptionText,
            sunExposure: result.chipSunExposure.nilIfEmpty,
            watering: result.chipWatering.nilIfEmpty,
            phylum: result.chipPhylum.nilIfEmpty,
            originCountry: safeOrigin.nilIfEmpty,
            tagSecondary: result.tagSecondary.nilIfEmpty,
            isNewDiscovery: result.isNewDiscovery,
            paletteHexes: result.paletteHexes,
            traditionalName: result.traditionalName.nilIfEmpty,
            botanicalSpirit: result.botanicalSpirit.nilIfEmpty,
            ethnobotany: result.ethnobotany.nilIfEmpty,
            culturalLegacy: culturalLegacyForPersist(from: result).nilIfEmpty
        )

        if isSupabasePreserveConfigured, let token = accessToken, userId != nil {
            let inserted = await insertScanRowRest(scan, accessToken: token)
            if !inserted {
                #if DEBUG
                print("[LeafID][scans][insert] specimen kept locally only; see preceding error for cause (RLS / column drift / network).")
                #endif
                // Silent before this: the scan looked saved this session (still appended below) but
                // never reached Supabase, so it vanished on the next `hydrateFromSupabase` wholesale
                // refresh with no visible cause. Surface it so a repeat report is actionable.
                ToastCenter.shared.show(
                    String(localized: "Saved, but couldn't sync to your account — it may not appear after reopening the app."),
                    kind: .error
                )
            }
        } else {
            #if DEBUG
            let cfg = isSupabasePreserveConfigured ? "configured" : "NOT configured"
            let tok = accessToken == nil ? "missing" : "present"
            let uid = userId == nil ? "missing" : "present"
            print("[LeafID][scans][insert] skipped remote POST: supabase=\(cfg) accessToken=\(tok) userId=\(uid) id=\(scan.id.uuidString)")
            #endif
        }

        herbarium.appendPreservedScan(scan)
        ProfileStatsLocalStore.recordHerbariumSave()

        #if canImport(UIKit) && canImport(CoreLocation)
        if let lat = mergedLat, let lon = mergedLon, isWeakCaptureLocationString(safeLocationLine) {
            scheduleReverseGeocodeForCaptureLocation(
                scanId: id,
                latitude: lat,
                longitude: lon,
                herbarium: herbarium,
                accessToken: accessToken
            )
        }
        #endif

        #if canImport(UIKit) && canImport(CoreImage) && canImport(Vision)
        scheduleCardImageGeneration(
            scanId: id,
            sourceJPEGData: imageJPEGData,
            userId: userId,
            accessToken: accessToken,
            herbarium: herbarium
        )
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
        locationLine = displaySafeLocation(result.locationLabel)
        #endif

        #if canImport(CoreLocation)
        let locality = await localityForCapture(
            captureLocality: captureLocality,
            mergedLatitude: mergedLat,
            mergedLongitude: mergedLon
        )
        let captureCountry = await countryForCapture(mergedLatitude: mergedLat, mergedLongitude: mergedLon)
        #else
        let locality: String? = nil
        let captureCountry: String? = nil
        #endif

        let canonicalLocationSource: String = {
            let localityFallback = locality?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !localityFallback.isEmpty {
                let current = locationLine.trimmingCharacters(in: .whitespacesAndNewlines)
                if current.isEmpty || isWeakCaptureLocationString(current) {
                    return localityFallback
                }
            }
            return locationLine
        }()

        return Scan(
            id: id,
            userId: nil,
            treeId: nil,
            commonName: result.commonName,
            scientificName: result.scientificName,
            photoURL: photoURL,
            confidence: result.confidence,
            location: displaySafeLocation(canonicalLocationSource),
            createdAt: nil,
            latitude: mergedLat,
            longitude: mergedLon,
            locality: locality,
            family: result.family,
            descriptionText: result.descriptionText,
            sunExposure: result.chipSunExposure.nilIfEmpty,
            watering: result.chipWatering.nilIfEmpty,
            phylum: result.chipPhylum.nilIfEmpty,
            originCountry: displaySafeOrigin(result.originCountry.nilIfEmpty ?? captureCountry).nilIfEmpty,
            tagSecondary: result.tagSecondary.nilIfEmpty,
            isNewDiscovery: result.isNewDiscovery,
            paletteHexes: result.paletteHexes,
            traditionalName: result.traditionalName.nilIfEmpty,
            botanicalSpirit: result.botanicalSpirit.nilIfEmpty,
            ethnobotany: result.ethnobotany.nilIfEmpty,
            culturalLegacy: culturalLegacyForPersist(from: result).nilIfEmpty
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
        if t == "origin unavailable" { return true }
        if t.contains("origin data not provided") { return true }
        if t.contains("origin not provided") { return true }
        if t.contains("not provided") { return true }
        if t == "unknown" { return true }
        if t == "region not specified" { return true }
        if t.contains("plant.id [non_json]") { return true }
        if t.contains("api key") { return true }
        if t.contains("insufficient") && t.contains("credit") { return true }
        if t.contains("http ") { return true }
        if t.contains("error") && t.contains("identify") { return true }
        return false
    }

    static func displaySafeLocation(_ raw: String?) -> String {
        let t = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if t.isEmpty || isWeakCaptureLocationString(t) { return unknownOriginFallback }
        return t
    }

    static func displaySafeOrigin(_ raw: String?) -> String {
        let t = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if t.isEmpty || isWeakCaptureLocationString(t) { return unknownOriginFallback }
        return t
    }

    /// Shared GPS caption for cards (monospaced Manrope applied at call site).
    static func formatCardinalGPS(latitude: Double, longitude: Double) -> String {
        let latHem = latitude >= 0 ? "N" : "S"
        let lonHem = longitude >= 0 ? "E" : "W"
        let la = abs(latitude)
        let lo = abs(longitude)
        return "\(latHem) \(String(format: "%.4f", la))° · \(lonHem) \(String(format: "%.4f", lo))°"
    }

    /// Aligned with identify prompts (`cultural_legacy` <= 220 chars).
    static let culturalLegacyMaxLength = 220

    static func clampNarrativeLine(_ raw: String, maxLen: Int = culturalLegacyMaxLength) -> String {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines.union(.newlines))
        guard t.count > maxLen else { return t }
        let end = t.index(t.startIndex, offsetBy: max(0, maxLen - 1))
        return String(t[...end]).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }

    /// Safe, generic cultural framing oriented toward History / Mythology / Art themes.
    /// Avoids medical claims and invented folklore — speaks to documented patterns at the
    /// family / regional level when species-specific copy is unavailable.
    static func fallbackCulturalLegacyPhrase(
        commonName: String,
        scientificName: String,
        family: String,
        originLine: String?
    ) -> String {
        let common = commonName.trimmingCharacters(in: .whitespacesAndNewlines)
        let sci = scientificName.trimmingCharacters(in: .whitespacesAndNewlines)
        let subject = common.isEmpty ? sci : common
        let famRaw = family.trimmingCharacters(in: .whitespacesAndNewlines)
        let fam = famRaw.isEmpty ? "plant" : famRaw.lowercased()
        let origin = originLine?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let originPhrase: String
        if origin.isEmpty || isWeakCaptureLocationString(origin) || origin == unknownOriginFallback {
            originPhrase = "many regions"
        } else {
            originPhrase = origin
        }
        let line =
            "Across history, mythology, and botanical art, \(subject) and other plants in the \(fam) family appear in herbals, garden traditions, and ornamental illustration tied to \(originPhrase)."
        return clampNarrativeLine(line)
    }

    /// Single source for card surfaces: saved field, live preview, then template from taxonomy/origin.
    static func mergedCulturalLegacy(scan: Scan, preview: IdentifyPreviewResult? = nil) -> String {
        let candidates = [scan.culturalLegacy, preview?.culturalLegacy]
        for c in candidates {
            let t = c?.trimmingCharacters(in: .whitespacesAndNewlines.union(.newlines)) ?? ""
            if !t.isEmpty { return clampNarrativeLine(t) }
        }
        var famMerged = scan.family?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if famMerged.isEmpty, let pf = preview?.family.trimmingCharacters(in: .whitespacesAndNewlines), !pf.isEmpty {
            famMerged = pf
        }
        let fromScan = scan.originCountry?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let fromPreview = preview.map { $0.originCountry.trimmingCharacters(in: .whitespacesAndNewlines) } ?? ""
        let originHint = fromScan.isEmpty ? fromPreview : fromScan
        let originLine = originHint.isEmpty ? scan.botanicalOriginLine : originHint
        return fallbackCulturalLegacyPhrase(
            commonName: scan.commonName,
            scientificName: scan.scientificName,
            family: famMerged.isEmpty ? "plants" : famMerged,
            originLine: originLine
        )
    }

    /// When the only available text is the generic fallback (no real Plant.id / preview source),
    /// enrich from Wikipedia REST summary, then optional Gemini (same API key as narrative),
    /// targeting a History / Mythology / Art angle for the species.
    static func enrichCulturalLegacyDisplay(scan: Scan, preview: IdentifyPreviewResult?, baseline: String) async -> String {
        let trimmed = baseline.trimmingCharacters(in: .whitespacesAndNewlines.union(.newlines))

        // Real source check: if we already have authored copy from the identify pipeline
        // (Plant.id / Gemini / OpenRouter) saved on the scan or attached to a live preview,
        // skip enrichment to avoid overwriting curated content.
        let scanSource = scan.culturalLegacy?.trimmingCharacters(in: .whitespacesAndNewlines.union(.newlines)) ?? ""
        let previewSource = preview?.culturalLegacy.trimmingCharacters(in: .whitespacesAndNewlines.union(.newlines)) ?? ""
        let hasRealSource = !scanSource.isEmpty || !previewSource.isEmpty
        if hasRealSource { return baseline }

        let sci = scan.scientificName.trimmingCharacters(in: .whitespacesAndNewlines)
        let com = scan.commonName.trimmingCharacters(in: .whitespacesAndNewlines)
        if let wiki = await wikipediaExtractForCulturalLegacy(scientificName: sci, commonName: com), !wiki.isEmpty {
            return wiki
        }

        let fam = (scan.family ?? preview?.family ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if let gem = await fetchLegacyFact(commonName: com, scientificName: sci, family: fam) {
            let g = gem.trimmingCharacters(in: .whitespacesAndNewlines.union(.newlines))
            if !g.isEmpty { return clampNarrativeLine(g) }
        }

        if trimmed.isEmpty {
            return mergedCulturalLegacy(scan: scan, preview: preview)
        }
        return baseline
    }

    static func culturalLegacyForPersist(from result: IdentifyPreviewResult) -> String {
        let trimmed = result.culturalLegacy.trimmingCharacters(in: .whitespacesAndNewlines.union(.newlines))
        if !trimmed.isEmpty { return clampNarrativeLine(trimmed) }
        return fallbackCulturalLegacyPhrase(
            commonName: result.commonName,
            scientificName: result.scientificName,
            family: result.family,
            originLine: result.originCountry
        )
    }

    private struct CachedIdentifyEntry: Codable {
        let perceptualHash: String
        let exactHash: String?
        let savedAtEpoch: TimeInterval
        let preview: CachedIdentifyPreview
    }

    private struct CachedIdentifyPreview: Codable {
        let commonName: String
        let scientificName: String
        let confidence: Double
        let locationLabel: String
        let family: String
        let descriptionText: String
        let originCountry: String
        let isNewDiscovery: Bool
        let usedFallback: Bool
        let tagSecondary: String
        let chipSunExposure: String
        let chipWatering: String
        let chipPhylum: String
        let paletteHexes: [String]
        let traditionalName: String
        let botanicalSpirit: String
        let ethnobotany: String
        let culturalLegacy: String

        init(preview: IdentifyPreviewResult) {
            commonName = preview.commonName
            scientificName = preview.scientificName
            confidence = preview.confidence
            locationLabel = preview.locationLabel
            family = preview.family
            descriptionText = preview.descriptionText
            originCountry = preview.originCountry
            isNewDiscovery = preview.isNewDiscovery
            usedFallback = preview.usedFallback
            tagSecondary = preview.tagSecondary
            chipSunExposure = preview.chipSunExposure
            chipWatering = preview.chipWatering
            chipPhylum = preview.chipPhylum
            paletteHexes = preview.paletteHexes
            traditionalName = preview.traditionalName
            botanicalSpirit = preview.botanicalSpirit
            ethnobotany = preview.ethnobotany
            culturalLegacy = preview.culturalLegacy
        }

        var asPreview: IdentifyPreviewResult {
            IdentifyPreviewResult(
                commonName: commonName,
                scientificName: scientificName,
                confidence: confidence,
                locationLabel: locationLabel,
                family: family,
                descriptionText: descriptionText,
                originCountry: originCountry,
                isNewDiscovery: isNewDiscovery,
                usedFallback: usedFallback,
                tagSecondary: tagSecondary,
                chipSunExposure: chipSunExposure,
                chipWatering: chipWatering,
                chipPhylum: chipPhylum,
                paletteHexes: paletteHexes,
                traditionalName: traditionalName,
                botanicalSpirit: botanicalSpirit,
                ethnobotany: ethnobotany,
                culturalLegacy: culturalLegacy
            )
        }
    }

    private static func cachedIdentifyResult(for imageData: Data?) -> IdentifyPreviewResult? {
        guard let imageData,
              let queryPHash = perceptualHashHex(for: imageData)
        else { return nil }
        let queryExact = exactHashHex(for: imageData)
        let entries = loadIdentifyCacheEntries()

        if let queryExact {
            if let exactHit = entries.first(where: { $0.exactHash == queryExact }) {
                return exactHit.preview.asPreview
            }
        }

        var best: (distance: Int, preview: IdentifyPreviewResult)?
        for entry in entries {
            guard let d = hammingDistanceHex(queryPHash, entry.perceptualHash) else { continue }
            if d <= perceptualMatchMaxHammingDistance {
                if best == nil || d < best!.distance {
                    best = (distance: d, preview: entry.preview.asPreview)
                }
            }
        }
        return best?.preview
    }

    private static func storeIdentifyCache(preview: IdentifyPreviewResult, imageData: Data?) {
        guard let imageData,
              let pHash = perceptualHashHex(for: imageData)
        else { return }
        let exact = exactHashHex(for: imageData)
        var entries = loadIdentifyCacheEntries()

        if let idx = entries.firstIndex(where: { $0.exactHash != nil && $0.exactHash == exact }) {
            entries.remove(at: idx)
        }
        entries.insert(
            CachedIdentifyEntry(
                perceptualHash: pHash,
                exactHash: exact,
                savedAtEpoch: Date().timeIntervalSince1970,
                preview: CachedIdentifyPreview(preview: preview)
            ),
            at: 0
        )
        if entries.count > identifyCacheMaxEntries {
            entries = Array(entries.prefix(identifyCacheMaxEntries))
        }
        saveIdentifyCacheEntries(entries)
    }

    private static func loadIdentifyCacheEntries() -> [CachedIdentifyEntry] {
        guard let data = UserDefaults.standard.data(forKey: identifyCacheKey),
              let decoded = try? JSONDecoder().decode([CachedIdentifyEntry].self, from: data)
        else { return [] }
        return decoded
    }

    private static func saveIdentifyCacheEntries(_ entries: [CachedIdentifyEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: identifyCacheKey)
    }

    private static func exactHashHex(for data: Data) -> String? {
        #if canImport(CryptoKit)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
        #else
        return nil
        #endif
    }

    #if canImport(UIKit)
    private static func perceptualHashHex(for data: Data) -> String? {
        guard let img = UIImage(data: data), let cg = img.cgImage else { return nil }
        let side = 8
        guard let context = CGContext(
            data: nil,
            width: side,
            height: side,
            bitsPerComponent: 8,
            bytesPerRow: side,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }
        context.interpolationQuality = .low
        context.draw(cg, in: CGRect(x: 0, y: 0, width: side, height: side))
        guard let ptr = context.data?.assumingMemoryBound(to: UInt8.self) else { return nil }
        var values: [UInt8] = []
        values.reserveCapacity(side * side)
        for i in 0 ..< (side * side) { values.append(ptr[i]) }
        let avg = values.reduce(0, { $0 + Int($1) }) / values.count
        var bits = ""
        bits.reserveCapacity(values.count)
        for v in values { bits.append(Int(v) >= avg ? "1" : "0") }
        return binaryToHex(bits)
    }
    #else
    private static func perceptualHashHex(for _: Data) -> String? { nil }
    #endif

    private static func binaryToHex(_ binary: String) -> String {
        var result = ""
        var idx = binary.startIndex
        while idx < binary.endIndex {
            let next = binary.index(idx, offsetBy: 4, limitedBy: binary.endIndex) ?? binary.endIndex
            let chunk = String(binary[idx ..< next])
            let value = Int(chunk, radix: 2) ?? 0
            result += String(format: "%1x", value)
            idx = next
        }
        return result
    }

    private static func hammingDistanceHex(_ a: String, _ b: String) -> Int? {
        let lhs = Array(a.lowercased())
        let rhs = Array(b.lowercased())
        guard lhs.count == rhs.count else { return nil }
        var distance = 0
        for i in 0 ..< lhs.count {
            guard let lv = Int(String(lhs[i]), radix: 16), let rv = Int(String(rhs[i]), radix: 16) else { return nil }
            distance += (lv ^ rv).nonzeroBitCount
        }
        return distance
    }

    private static func freeOriginFromWikipedia(scientificName: String, commonName: String) async -> String? {
        let queries = [scientificName, commonName].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        for q in queries {
            guard let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(encoded)")
            else { continue }
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else { continue }
                if let summary = try? JSONDecoder().decode(WikipediaSummary.self, from: data),
                   let extracted = shortOriginFromText(summary.extract) {
                    return extracted
                }
            } catch {
                continue
            }
        }
        return nil
    }

    private struct WikipediaSummary: Decodable {
        let extract: String?
    }

    private static func shortOriginFromText(_ raw: String?) -> String? {
        let text = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else { return nil }
        let lower = text.lowercased()
        let markers = ["native to ", "originating in ", "endemic to "]
        for marker in markers {
            guard let range = lower.range(of: marker) else { continue }
            let start = range.upperBound
            let tail = String(text[start...])
            let sentenceEnd = tail.firstIndex(where: { ".;".contains($0) }) ?? tail.endIndex
            let candidate = String(tail[..<sentenceEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
            if let normalized = normalizedOrigin(candidate), normalized.count <= 64 {
                return normalized
            }
        }
        return nil
    }

    private static func wikipediaExtractForCulturalLegacy(scientificName: String, commonName: String) async -> String? {
        let queries = [scientificName, commonName]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        var seen = Set<String>()
        let unique = queries.filter { seen.insert($0.lowercased()).inserted }
        for q in unique {
            guard let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(encoded)")
            else { continue }
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else { continue }
                guard let summary = try? JSONDecoder().decode(WikipediaSummary.self, from: data),
                      let extract = summary.extract?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !extract.isEmpty
                else { continue }
                let cleaned = sanitizeWikiExtractForLegacy(extract)
                let line = clampNarrativeLine(cleaned)
                if line.count >= 48 { return line }
            } catch {
                continue
            }
        }
        return nil
    }

    private static func sanitizeWikiExtractForLegacy(_ raw: String) -> String {
        var t = raw.replacingOccurrences(of: #"\[\d+\]"#, with: "", options: .regularExpression)
        t = t.replacingOccurrences(of: #"\[a\]"#, with: "", options: .regularExpression)
        t = t.replacingOccurrences(of: "  ", with: " ")
        if let range = t.range(of: "\n") {
            t = String(t[..<range.lowerBound])
        }
        let sentenceEnd = t.firstIndex(where: { ".!?".contains($0) }) ?? t.endIndex
        var out = String(t[..<sentenceEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
        if out.isEmpty { out = t.trimmingCharacters(in: .whitespacesAndNewlines) }
        return out
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

    /// Cultural/historical narrative, generated server-side by the `narrate-plant` edge function
    /// (same free-tier-conscious OpenRouter-free → Gemini-direct order the client used to do itself).
    private static func fetchNarrative(
        commonName: String,
        scientificName: String,
        family: String,
        originCountry: String,
        useFallbackPrompt: Bool
    ) async -> GeminiNarrative? {
        guard let endpoint = LeafIDSupabaseConfig.narrateEndpoint, let anon = LeafIDSupabaseConfig.anonKey else { return nil }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(anon)", forHTTPHeaderField: "Authorization")
        request.setValue(anon, forHTTPHeaderField: "apikey")
        request.timeoutInterval = 20
        let body: [String: Any] = [
            "commonName": commonName,
            "scientificName": scientificName,
            "family": family,
            "originCountry": originCountry,
            "useFallbackPrompt": useFallbackPrompt,
        ]
        guard let payload = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        request.httpBody = payload

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else { return nil }
            return try? JSONDecoder().decode(GeminiNarrative.self, from: data)
        } catch {
            #if DEBUG
            print("[narrate-plant Error] \(error.localizedDescription)")
            #endif
            return nil
        }
    }

    /// Single historical/mythological/artistic fact for legacy scans missing cultural content —
    /// same edge function as `fetchNarrative`, `mode: "legacy_fact"` swaps in the narrower prompt.
    private static func fetchLegacyFact(commonName: String, scientificName: String, family: String) async -> String? {
        guard let endpoint = LeafIDSupabaseConfig.narrateEndpoint, let anon = LeafIDSupabaseConfig.anonKey else { return nil }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(anon)", forHTTPHeaderField: "Authorization")
        request.setValue(anon, forHTTPHeaderField: "apikey")
        request.timeoutInterval = 18
        let body: [String: Any] = [
            "commonName": commonName,
            "scientificName": scientificName,
            "family": family,
            "mode": "legacy_fact",
        ]
        guard let payload = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        request.httpBody = payload

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else { return nil }
            return try? JSONDecoder().decode(GeminiNarrative.self, from: data).cultural_legacy
        } catch {
            return nil
        }
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
            let res = await fetchNarrative(
                commonName: s.common,
                scientificName: s.scientific,
                family: s.family,
                originCountry: s.origin,
                useFallbackPrompt: false
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
    /// Reverse-geocodes the capture point and patches `locality`/`location` onto the saved scan —
    /// locally right away, and (when Preserve is configured) back to Supabase via PostgREST, so it
    /// survives the next `hydrateFromSupabase` wholesale refresh instead of silently reverting.
    private static func scheduleReverseGeocodeForCaptureLocation(
        scanId: UUID,
        latitude: Double,
        longitude: Double,
        herbarium: HerbariumViewModel,
        accessToken: String?
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
            Task { @MainActor in
                var patchedLocality: String?
                var patchedLocation: String?
                herbarium.patchPreservedScan(id: scanId) { scan in
                    if scan.locality == nil, let loc = localityName {
                        scan.locality = loc
                        patchedLocality = loc
                    }
                    guard !line.isEmpty else { return }
                    guard BotanyService.isWeakCaptureLocationString(scan.location) else { return }
                    scan.location = line
                    patchedLocation = line
                }
                guard let token = accessToken, patchedLocality != nil || patchedLocation != nil else { return }
                var columns: [String: Any] = [:]
                if let patchedLocality { columns["locality"] = patchedLocality }
                if let patchedLocation { columns["location"] = patchedLocation }
                let ok = await patchScanColumnsRest(scanId: scanId, accessToken: token, columns: columns)
                #if DEBUG
                if !ok {
                    print("[LeafID][scans][patch] locality/location patch failed scanId=\(scanId.uuidString)")
                }
                #endif
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
            if !iptcLine.isEmpty { return displaySafeLocation(iptcLine) }
            if !resultLoc.isEmpty { return displaySafeLocation(resultLoc) }
            return unknownOriginFallback
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

    private static func countryForCapture(
        mergedLatitude: Double?,
        mergedLongitude: Double?
    ) async -> String? {
        guard let la = mergedLatitude, let lo = mergedLongitude else { return nil }
        return await withCheckedContinuation { continuation in
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(CLLocation(latitude: la, longitude: lo)) { placemarks, _ in
                let country = placemarks?.first?.country?.trimmingCharacters(in: .whitespacesAndNewlines)
                continuation.resume(returning: country?.isEmpty == false ? country : nil)
            }
        }
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

    /// Sibling of the raw capture — never overwrites `writeCaptureJPEG`'s file.
    private static func writeCardImageJPEG(_ data: Data, scanId: UUID) -> URL? {
        guard !data.isEmpty else { return nil }
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let captures = dir.appendingPathComponent("captures", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: captures, withIntermediateDirectories: true)
            let url = captures.appendingPathComponent("\(scanId.uuidString)_card.jpg")
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    // MARK: - Supabase Preserve (Storage `plant-images` + `public.scans` via PostgREST)

    /// When `false`, PostgREST inserts omit `latitude` / `longitude` / `locality` so inserts succeed if those columns are not migrated yet. Set to `true` after adding nullable columns on `public.scans`.
    private static let postgRESTScansIncludeGeoColumns = true
    /// Set `true` only if your `public.scans` table includes these optional narrative columns (see `docs/SWIFT_MIGRATION_GUIDE.md`).
    private static let postgRESTScansIncludeExtendedMetadata = false

    private static let plantImagesBucketId = "plant-images"

    private static func supabaseProjectRootURLString() -> String? {
        guard var base = LeafIDSupabaseConfig.urlString else { return nil }
        if base.hasSuffix("/") { base.removeLast() }
        return base
    }

    private static func supabaseJSONDecoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if container.decodeNil() {
                throw DecodingError.valueNotFound(Date.self, .init(codingPath: decoder.codingPath, debugDescription: "null date"))
            }
            let str = try container.decode(String.self)
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = f.date(from: str) { return date }
            f.formatOptions = [.withInternetDateTime]
            if let date = f.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO8601 date: \(str)")
        }
        return d
    }

    /// Fetches scans visible to the current user (`RLS` restricts rows to `user_id = auth.uid()` when policies are enabled).
    static func fetchScansForCurrentUser(accessToken: String) async throws -> [Scan] {
        guard let root = supabaseProjectRootURLString(), let anon = LeafIDSupabaseConfig.anonKey else {
            throw BotanyServiceError.invalidResponse
        }
        var components = URLComponents(string: "\(root)/rest/v1/scans")
        components?.queryItems = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "created_at.desc"),
        ]
        guard let url = components?.url else { throw BotanyServiceError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(anon, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 45
        configuration.timeoutIntervalForResource = 60
        let session = URLSession(configuration: configuration)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw BotanyServiceError.invalidResponse }
        guard (200 ... 299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw BotanyServiceError.identifyFailed(msg.isEmpty ? "HTTP \(http.statusCode)" : msg)
        }

        do {
            return try supabaseJSONDecoder().decode([Scan].self, from: data)
        } catch {
            #if DEBUG
            print("[LeafID] scans decode error: \(error.localizedDescription)")
            #endif
            throw BotanyServiceError.invalidResponse
        }
    }

    /// Uploads JPEG to `plant-images/{userId}/{scanId}{suffix}.jpg` and returns the **public** object
    /// URL. `suffix` defaults to `""` (the raw capture, `scans.photo_url`); pass `"_card"` for the
    /// derived Botanical Card hero image (`scans.card_image_url`) — same bucket, same owner-scoped
    /// RLS policy (keyed on the `{userId}/` path prefix, unaffected by the filename).
    private static func uploadJPEGToPlantImagesBucket(
        jpegData: Data,
        scanId: UUID,
        userId: UUID,
        accessToken: String,
        suffix: String = ""
    ) async -> String? {
        guard let root = supabaseProjectRootURLString(), let anon = LeafIDSupabaseConfig.anonKey else { return nil }
        guard !jpegData.isEmpty else { return nil }
        let owner = userId.uuidString.lowercased()
        let fileName = "\(scanId.uuidString.lowercased())\(suffix).jpg"
        let objectPath = "\(owner)/\(fileName)"
        let encodedPath = objectPath.split(separator: "/")
            .map { String($0).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String($0) }
            .joined(separator: "/")
        guard let uploadURL = URL(string: "\(root)/storage/v1/object/\(plantImagesBucketId)/\(encodedPath)") else { return nil }

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
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
            return "\(root)/storage/v1/object/public/\(plantImagesBucketId)/\(encodedPath)"
        } catch {
            #if DEBUG
            print("[LeafID] Storage upload error: \(error.localizedDescription)")
            #endif
            return nil
        }
    }

    /// Inserts one row into `public.scans` (PostgREST) using the **user JWT** so RLS `with check (auth.uid() = user_id)` succeeds.
    private static func insertScanRowRest(_ scan: Scan, accessToken: String) async -> Bool {
        guard let root = supabaseProjectRootURLString(), let anon = LeafIDSupabaseConfig.anonKey else { return false }
        guard let url = URL(string: "\(root)/rest/v1/scans") else { return false }
        guard let uid = scan.userId else {
            #if DEBUG
            print("[LeafID] scans insert skipped: missing user_id on Scan model.")
            #endif
            return false
        }

        var row: [String: Any] = [
            "id": scan.id.uuidString,
            "user_id": uid.uuidString,
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
        if let tid = scan.treeId {
            row["tree_id"] = tid.uuidString
        }
        if postgRESTScansIncludeExtendedMetadata {
            if let family = scan.family, !family.isEmpty { row["family"] = family }
            if let descriptionText = scan.descriptionText, !descriptionText.isEmpty { row["description_text"] = descriptionText }
            if let sun = scan.sunExposure, !sun.isEmpty { row["sun_exposure"] = sun }
            if let water = scan.watering, !water.isEmpty { row["watering"] = water }
            if let phylum = scan.phylum, !phylum.isEmpty { row["phylum"] = phylum }
            if let origin = scan.originCountry, !origin.isEmpty { row["origin_country"] = origin }
            if let tag = scan.tagSecondary, !tag.isEmpty { row["tag_secondary"] = tag }
            if let isNew = scan.isNewDiscovery { row["is_new_discovery"] = isNew }
            if let spirit = scan.botanicalSpirit, !spirit.isEmpty { row["botanical_spirit"] = spirit }
            if let eth = scan.ethnobotany, !eth.isEmpty { row["ethnobotany"] = eth }
            if let cult = scan.culturalLegacy, !cult.isEmpty { row["cultural_legacy"] = cult }
        }

        guard let body = try? JSONSerialization.data(withJSONObject: [row]) else { return false }

        #if DEBUG
        let prettyBody = (try? JSONSerialization.data(withJSONObject: [row], options: [.prettyPrinted, .sortedKeys]))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "<unavailable>"
        print("[LeafID][scans][insert] POST \(url.absoluteString)")
        print("[LeafID][scans][insert] columns: \(row.keys.sorted())")
        print("[LeafID][scans][insert] JSON:\n\(prettyBody)")
        #endif

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
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
            guard let http = response as? HTTPURLResponse else {
                #if DEBUG
                print("[LeafID][scans][insert] non-HTTP response; aborting")
                #endif
                return false
            }
            if (200 ... 299).contains(http.statusCode) {
                #if DEBUG
                print("[LeafID][scans][insert] HTTP \(http.statusCode) OK id=\(scan.id.uuidString)")
                #endif
                return true
            }
            #if DEBUG
            logScansInsertFailure(statusCode: http.statusCode, data: data, scanId: scan.id)
            #endif
            return false
        } catch {
            #if DEBUG
            print("[LeafID][scans][insert] network error id=\(scan.id.uuidString): \(error.localizedDescription)")
            #endif
            return false
        }
    }

    #if DEBUG
    /// Pretty-prints the PostgREST error envelope (`{ code, message, details, hint }`)
    /// and adds a quick diagnostic hint for the most common failure codes seen on
    /// `public.scans` inserts (RLS denial, schema-cache drift, FK violation, auth).
    private static func logScansInsertFailure(statusCode: Int, data: Data, scanId: UUID) {
        let raw = String(data: data, encoding: .utf8) ?? ""
        print("[LeafID][scans][insert] HTTP \(statusCode) FAIL id=\(scanId.uuidString)")
        print("[LeafID][scans][insert] body: \(raw)")

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        let code = json["code"] as? String ?? ""
        let message = json["message"] as? String ?? ""
        let details = json["details"] as? String ?? ""
        let hint = json["hint"] as? String ?? ""
        if !code.isEmpty || !message.isEmpty {
            print("[LeafID][scans][insert] postgREST code=\(code) message=\(message) details=\(details) hint=\(hint)")
        }

        let diagnostic: String?
        switch (statusCode, code) {
        case (401, _):
            diagnostic = "401: missing/expired JWT — re-auth and retry."
        case (403, _), (_, "42501"):
            diagnostic = "RLS denied: `auth.uid() = user_id` on policy `scans_insert_own` failed. Confirm Scan.userId matches the signed-in user's id."
        case (_, "PGRST204"):
            diagnostic = "PGRST204: column missing in PostgREST schema cache — Swift payload lists a column the live `public.scans` does not have."
        case (_, "23502"):
            diagnostic = "23502: NOT NULL violation — a required column was sent as null."
        case (_, "23503"):
            diagnostic = "23503: FK violation — likely `user_id` not found in `auth.users` (stale/cached auth?)."
        case (_, "23505"):
            diagnostic = "23505: unique violation — `id` already exists in `public.scans`."
        case (_, "22P02"):
            diagnostic = "22P02: invalid type cast — likely a uuid/text mismatch (e.g. `tree_id`)."
        default:
            diagnostic = nil
        }
        if let diagnostic { print("[LeafID][scans][insert] hint -> \(diagnostic)") }
    }
    #endif

    // MARK: - Generic PATCH (used by card-image generation + reverse-geocode locality fix)

    /// Patches arbitrary columns on an existing `public.scans` row via PostgREST, using the user's
    /// JWT so RLS `using (auth.uid() = user_id)` succeeds. Returns `true` on 2xx.
    private static func patchScanColumnsRest(scanId: UUID, accessToken: String, columns: [String: Any]) async -> Bool {
        guard let root = supabaseProjectRootURLString(), let anon = LeafIDSupabaseConfig.anonKey else { return false }
        guard !columns.isEmpty else { return false }
        var components = URLComponents(string: "\(root)/rest/v1/scans")
        components?.queryItems = [URLQueryItem(name: "id", value: "eq.\(scanId.uuidString)")]
        guard let url = components?.url else { return false }
        guard let body = try? JSONSerialization.data(withJSONObject: columns) else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
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
                #if DEBUG
                print("[LeafID][scans][patch] HTTP \(http.statusCode) OK id=\(scanId.uuidString) columns=\(columns.keys.sorted())")
                #endif
                return true
            }
            #if DEBUG
            let msg = String(data: data, encoding: .utf8) ?? ""
            print("[LeafID][scans][patch] HTTP \(http.statusCode) FAIL id=\(scanId.uuidString) columns=\(columns.keys.sorted()) body=\(msg)")
            #endif
            return false
        } catch {
            #if DEBUG
            print("[LeafID][scans][patch] network error id=\(scanId.uuidString): \(error.localizedDescription)")
            #endif
            return false
        }
    }

    // MARK: - Botanical Card auto-processing (crop + level + brand grade; see BotanicalCardImageProcessor)

    #if canImport(UIKit) && canImport(CoreImage) && canImport(Vision)
    /// In-flight guard so a row and the immersive card mounting concurrently for the same scan
    /// don't both kick off processing. Main-actor isolated — only ever touched from `ensureCardImageIfNeeded`.
    @MainActor
    private static var cardImageGenerationInFlight = Set<UUID>()

    /// Fire-and-forget, called from `saveUserCapture` right after the scan is appended — never blocks
    /// the Save button. Mirrors `scheduleReverseGeocodeForCaptureLocation`'s shape.
    private static func scheduleCardImageGeneration(
        scanId: UUID,
        sourceJPEGData: Data,
        userId: UUID?,
        accessToken: String?,
        herbarium: HerbariumViewModel
    ) {
        guard isCardImageProcessingEnabled else { return }
        Task.detached(priority: .utility) {
            await generateAndPersistCardImage(
                scanId: scanId,
                sourceJPEGData: sourceJPEGData,
                userId: userId,
                accessToken: accessToken,
                herbarium: herbarium
            )
        }
    }

    /// Runs the CoreImage/Vision pipeline, writes the derived JPEG locally, uploads it (Preserve
    /// configured + authenticated), and patches both the in-memory scan and — critically — the
    /// remote row, so it survives the next `hydrateFromSupabase` wholesale refresh.
    private static func generateAndPersistCardImage(
        scanId: UUID,
        sourceJPEGData: Data,
        userId: UUID?,
        accessToken: String?,
        herbarium: HerbariumViewModel
    ) async {
        guard let processedData = BotanicalCardImageProcessor.makeCardImageJPEG(from: sourceJPEGData) else {
            #if DEBUG
            print("[LeafID][cardimage] processing failed scanId=\(scanId.uuidString)")
            #endif
            return
        }
        guard let localURL = writeCardImageJPEG(processedData, scanId: scanId) else {
            #if DEBUG
            print("[LeafID][cardimage] local write failed scanId=\(scanId.uuidString)")
            #endif
            return
        }

        var resolvedCardImageURL = localURL.absoluteString
        await herbarium.patchPreservedScan(id: scanId) { scan in
            scan.cardImageURL = resolvedCardImageURL
        }

        guard isSupabasePreserveConfigured, let token = accessToken, let ownerId = userId else {
            #if DEBUG
            print("[LeafID][cardimage] generated locally only (Preserve not configured/authenticated) scanId=\(scanId.uuidString)")
            #endif
            return
        }
        guard let publicURL = await uploadJPEGToPlantImagesBucket(
            jpegData: processedData,
            scanId: scanId,
            userId: ownerId,
            accessToken: token,
            suffix: "_card"
        ) else {
            #if DEBUG
            print("[LeafID][cardimage] Storage upload failed; keeping local card image scanId=\(scanId.uuidString)")
            #endif
            return
        }
        resolvedCardImageURL = publicURL
        await herbarium.patchPreservedScan(id: scanId) { scan in
            scan.cardImageURL = resolvedCardImageURL
        }
        let patched = await patchScanColumnsRest(
            scanId: scanId,
            accessToken: token,
            columns: ["card_image_url": resolvedCardImageURL]
        )
        #if DEBUG
        print("[LeafID][cardimage] \(patched ? "generated + patched" : "generated, remote patch FAILED") scanId=\(scanId.uuidString)")
        #endif
    }

    /// Lazily backfills `cardImageURL` for a scan saved before this feature shipped (or where
    /// generation hasn't landed yet). No-ops if already present or already in flight — safe to call
    /// from `.task`/`.onAppear` on every row/card render.
    @MainActor
    static func ensureCardImageIfNeeded(for scan: Scan, herbarium: HerbariumViewModel, auth: AuthViewModel) async {
        guard isCardImageProcessingEnabled else { return }
        guard scan.cardImageURL == nil else { return }
        guard !cardImageGenerationInFlight.contains(scan.id) else { return }
        cardImageGenerationInFlight.insert(scan.id)
        defer { cardImageGenerationInFlight.remove(scan.id) }

        guard let sourceData = await sourceJPEGDataForCardGeneration(scan: scan) else { return }
        await generateAndPersistCardImage(
            scanId: scan.id,
            sourceJPEGData: sourceData,
            userId: scan.userId ?? auth.supabaseUserId,
            accessToken: auth.supabaseAccessToken,
            herbarium: herbarium
        )
    }

    /// Local capture file first (no network); falls back to downloading `photoURL` when only a
    /// remote copy exists (e.g. a scan preserved from another device).
    private static func sourceJPEGDataForCardGeneration(scan: Scan) async -> Data? {
        if let localURL = scan.resolvedLocalCaptureURL,
           let data = try? Data(contentsOf: localURL), !data.isEmpty
        {
            return data
        }
        guard let remoteURL = scan.resolvedRemoteImageURL else { return nil }
        do {
            let (data, response) = try await URLSession.shared.data(from: remoteURL)
            guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode), !data.isEmpty else {
                return nil
            }
            return data
        } catch {
            return nil
        }
    }
    #endif
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
