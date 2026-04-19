//
//  IdentifyPreviewResult.swift
//  LeafID-native
//
//  Ephemeral identify payload before persisting to `Scan` (PDR §3.A).
//

import Foundation

struct IdentifyPreviewResult: Equatable {
    var commonName: String
    var scientificName: String
    var confidence: Double
    var locationLabel: String
    /// Taxonomic family from Plant.id / edge function.
    var family: String
    /// Short description (e.g. wiki / curiosity line).
    var descriptionText: String
    var originCountry: String
    var isNewDiscovery: Bool
    var usedFallback: Bool
    /// Optional second tag (e.g. light hint); first tag often uses `locationLabel`.
    var tagSecondary: String
    /// Plant.id / edge: chip copy; empty → chip hidden in UI.
    var chipSunExposure: String
    var chipWatering: String
    var chipPhylum: String
    var paletteHexes: [String]
    var botanicalSpirit: String
    var ethnobotany: String
    var culturalLegacy: String
}

extension IdentifyPreviewResult {
    /// Shown only when the app cannot reach Supabase `identify-plant` (no Plant.id call from this build).
    static func offlineDemoPreview() -> IdentifyPreviewResult {
        IdentifyPreviewResult(
            commonName: "Offline demo",
            scientificName: "Add Supabase keys for Plant.id",
            confidence: 0.5,
            locationLabel: "Not from your photo",
            family: "UNCONFIGURED",
            descriptionText: "Real identification uses your Supabase Edge Function `identify-plant`, which calls Plant.id. Set user-defined build settings SUPABASE_URL and SUPABASE_ANON_KEY (mapped into Info.plist) to enable it. This text is a static placeholder until then.",
            originCountry: "—",
            isNewDiscovery: false,
            usedFallback: true,
            tagSecondary: "Partial shade",
            chipSunExposure: "Bright indirect light",
            chipWatering: "Moderate watering",
            chipPhylum: "Magnoliophyta",
            paletteHexes: ["#2C4C1A", "#7AAE2E", "#6B4F2E"],
            botanicalSpirit: "A patient teacher of adaptation and light-seeking growth.",
            ethnobotany: "Many aroids are cultivated ornamentals and studied for indoor air quality.",
            culturalLegacy: "Lush split-leaf forms appear frequently in modern tropical design and illustration."
        )
    }
}
