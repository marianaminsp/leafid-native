//
//  HerbariumSpecimen.swift
//  LeafID-native
//
//  Mock specimen data shared by the Herbarium sticker pile and the Botanical Card it opens
//  into. Fields match the *real* card-back data model in `BotanicalCardImmersiveView.swift`
//  (Colour Signature, Traditional Name, Botanical Spirit, Ethnobotany, Cultural Legacy) —
//  not the gardening-facts model (Type/Light/Watering) from the stale `BotanicalCard.md` doc
//  the original redesign artifact was built against. This isn't a gardening app, it's cultural.
//

import SwiftUI

struct HerbariumSpecimen: Identifiable {
    let id = UUID()
    let latinName: String
    let commonName: String
    let chip: String
    let imageAsset: String
    let accent: Color
    /// Traditional/indigenous name — `nil` (row hidden) when none is well-documented, same rule
    /// as the real card: never invented.
    let traditionalName: String?
    let paletteHexes: [String]
    let botanicalSpirit: String
    let ethnobotany: String
    let culturalLegacy: String

    static let sample: [HerbariumSpecimen] = [
        HerbariumSpecimen(
            latinName: "ACER SAMARA", commonName: "Maple Seed Pod", chip: "NATIVE SPECIES",
            imageAsset: "SamaraLastDiscovery", accent: NeoBrutalistColor.primary,
            traditionalName: nil,
            paletteHexes: ["#B02700", "#006D3F"],
            botanicalSpirit: "A traveler by design, built to leave home the moment it's ready.",
            ethnobotany: "Samaras are winged achenes that spin like helicopters as they fall, letting the wind carry maple seeds away from the parent tree.",
            culturalLegacy: "The maple's turning leaves mark autumn across temperate cultures worldwide, from Japanese momiji-viewing to the maple leaf's place on Canada's flag."
        ),
        HerbariumSpecimen(
            latinName: "STRELITZIA REGINAE", commonName: "Bird of Paradise", chip: "NEW DISCOVERY",
            imageAsset: "BirdOfParadiseIllustration", accent: NeoBrutalistColor.secondary,
            traditionalName: "Crane Flower",
            paletteHexes: ["#DC3300", "#006D3F"],
            botanicalSpirit: "A bloom shaped like flight, waiting for a bird that already knows the way.",
            ethnobotany: "Its bird-like bloom is pollinated by sunbirds in its native South Africa, which land on the petal to reach the nectar.",
            culturalLegacy: "Strelitzia reginae is the official flower of the city of Los Angeles, and its genus name honors Queen Charlotte of Mecklenburg-Strelitz."
        ),
        HerbariumSpecimen(
            latinName: "ALOCASIA AMAZONICA", commonName: "African Mask Plant", chip: "NATIVE SPECIES",
            imageAsset: "AlocasiaIllustration", accent: NeoBrutalistColor.tertiary,
            traditionalName: "Elephant Ear",
            paletteHexes: ["#AD009B", "#181C22"],
            botanicalSpirit: "Dark leaves, pale veins — a map drawn for no one but itself.",
            ethnobotany: "A hybrid cultivar, not found in the wild — its dramatic dark leaves and pale veins were bred for ornamental impact.",
            culturalLegacy: "A fixture of the modern houseplant-collecting culture that took off in the 2010s, prized specifically for a look nature never produced on its own."
        ),
        HerbariumSpecimen(
            latinName: "HYLOCEREUS UNDATUS", commonName: "Dragon Fruit", chip: "NEW DISCOVERY / RARE",
            imageAsset: "DragonFruitIllustration", accent: NeoBrutalistColor.primary,
            traditionalName: "Pitaya",
            paletteHexes: ["#AD009B", "#2AF598", "#181C22"],
            botanicalSpirit: "A flower that blooms once, at night, for no one but the moths.",
            ethnobotany: "Its night-blooming flowers open for a single night, pollinated by moths and bats before closing forever by sunrise.",
            culturalLegacy: "Known as \"thanh long\" (dragon's eyes) in Vietnamese, tied to dragon folklore and used in Lunar New Year offerings."
        ),
    ]
}
