//
//  Achievements.swift
//  LeafID-native
//
//  Phase 1: catalog + rules from Herbarium scans + ProfileStatsLocalStore; monotonic unlock persistence.
//

import Foundation

// MARK: - Rule + context

enum AchievementRule: Equatable, Sendable {
    case plantsAtLeast(Int)
    case distinctSpeciesAtLeast(Int)
    case distinctFamiliesAtLeast(Int)
    case originCountriesAtLeast(Int)
    case lifetimeScansAtLeast(Int)
    case cumulativeSavesAtLeast(Int)
    case streakDaysAtLeast(Int)
}

struct AchievementContext: Equatable, Sendable {
    var plantsCount: Int
    var distinctSpecies: Int
    var distinctFamilies: Int
    var distinctOriginCountries: Int
    var lifetimeScans: Int
    var cumulativeHerbariumSaves: Int
    var discoveryStreakDays: Int

    init(scans: [Scan]) {
        plantsCount = scans.count
        distinctSpecies = Set(scans.map(\.scientificName)).count
        distinctFamilies = Set(
            scans.compactMap { $0.family?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
                .filter { !$0.isEmpty && $0 != "UNCLASSIFIED" }
        ).count
        distinctOriginCountries = Set(
            scans.compactMap {
                $0.originCountry?.trimmingCharacters(in: .whitespacesAndNewlines)
            }.filter { !$0.isEmpty && $0 != "—" && $0.lowercased() != "origin under review" }
        ).count
        let snap = ProfileStatsLocalStore.snapshot(from: scans)
        lifetimeScans = snap.totalScans
        cumulativeHerbariumSaves = ProfileStatsLocalStore.cumulativeHerbariumSaves
        discoveryStreakDays = snap.discoveryStreakDays
    }
}

extension AchievementRule {
    func isSatisfied(_ context: AchievementContext) -> Bool {
        switch self {
        case .plantsAtLeast(let n):
            return context.plantsCount >= n
        case .distinctSpeciesAtLeast(let n):
            return context.distinctSpecies >= n
        case .distinctFamiliesAtLeast(let n):
            return context.distinctFamilies >= n
        case .originCountriesAtLeast(let n):
            return context.distinctOriginCountries >= n
        case .lifetimeScansAtLeast(let n):
            return context.lifetimeScans >= n
        case .cumulativeSavesAtLeast(let n):
            return context.cumulativeHerbariumSaves >= n
        case .streakDaysAtLeast(let n):
            return context.discoveryStreakDays >= n
        }
    }
}

// MARK: - Definition + tile state

struct AchievementDefinition: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let symbolName: String
    let rule: AchievementRule
}

struct AchievementTileState: Identifiable, Equatable {
    var id: String { definition.id }
    let definition: AchievementDefinition
    /// Monotonic: once true, stays true in storage even if stats dip.
    let isEarned: Bool
}

// MARK: - Catalog

enum AchievementCatalog {
    static let definitions: [AchievementDefinition] = [
        AchievementDefinition(
            id: "greenhouse_guru",
            title: "Greenhouse Guru",
            subtitle: "Save your first specimen",
            symbolName: "house.fill",
            rule: .plantsAtLeast(1)
        ),
        AchievementDefinition(
            id: "catalog_builder",
            title: "Catalog Builder",
            subtitle: "Save 5 specimens",
            symbolName: "books.vertical.fill",
            rule: .plantsAtLeast(5)
        ),
        AchievementDefinition(
            id: "species_collector",
            title: "Species Collector",
            subtitle: "Log 3 distinct species",
            symbolName: "leaf.circle.fill",
            rule: .distinctSpeciesAtLeast(3)
        ),
        AchievementDefinition(
            id: "family_matters",
            title: "Family Matters",
            subtitle: "Represent 2 plant families",
            symbolName: "square.grid.2x2.fill",
            rule: .distinctFamiliesAtLeast(2)
        ),
        AchievementDefinition(
            id: "globe_trotter",
            title: "Globe Trotter",
            subtitle: "Species from 2 countries of origin",
            symbolName: "globe.americas.fill",
            rule: .originCountriesAtLeast(2)
        ),
        AchievementDefinition(
            id: "archivist",
            title: "Archivist",
            subtitle: "Preserve 3 times (lifetime)",
            symbolName: "archivebox.fill",
            rule: .cumulativeSavesAtLeast(3)
        ),
        AchievementDefinition(
            id: "dedicated",
            title: "Dedicated",
            subtitle: "Run 10 identifications",
            symbolName: "camera.viewfinder",
            rule: .lifetimeScansAtLeast(10)
        ),
        AchievementDefinition(
            id: "week_wanderer",
            title: "Week Wanderer",
            subtitle: "7-day discovery streak",
            symbolName: "flame.fill",
            rule: .streakDaysAtLeast(7)
        ),
    ]
}

// MARK: - Unlock persistence (UserDefaults)

enum AchievementUnlockStore {
    private static let key = "leafid.achievement_unlock_ids.v1"

    static func loadEarnedIds() -> Set<String> {
        guard let arr = UserDefaults.standard.array(forKey: key) as? [String] else { return [] }
        return Set(arr)
    }

    /// Merges any definitions that currently satisfy their rule into the earned set (monotonic).
    static func syncEarnedWithCurrentProgress(scans: [Scan]) {
        let context = AchievementContext(scans: scans)
        let passingNow = Set(
            AchievementCatalog.definitions
                .filter { $0.rule.isSatisfied(context) }
                .map(\.id)
        )
        var earned = loadEarnedIds()
        let before = earned
        earned.formUnion(passingNow)
        if earned != before {
            UserDefaults.standard.set(Array(earned), forKey: key)
        }
    }

    static func tiles(scans: [Scan]) -> [AchievementTileState] {
        syncEarnedWithCurrentProgress(scans: scans)
        let earned = loadEarnedIds()
        return AchievementCatalog.definitions.map { def in
            AchievementTileState(
                definition: def,
                isEarned: earned.contains(def.id)
            )
        }
    }
}
