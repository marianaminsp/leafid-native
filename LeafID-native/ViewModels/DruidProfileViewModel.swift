//
//  DruidProfileViewModel.swift
//  LeafID-native
//
//  Supabase-backed profile + stats (protocol Tab 4). Wire REST/Realtime when client lands.
//

import Combine
import Foundation

@MainActor
final class DruidProfileViewModel: ObservableObject {
    private static let freeScanLimit = 3
    private static let googleClientID = "133761573510-233kdml7mn0p0d19pksj62h1t27oaide.apps.googleusercontent.com"

    @Published private(set) var profile: Profile?
    @Published private(set) var specimenCount: Int = 0
    @Published private(set) var ancientSeedsCount: Int = 0
    @Published private(set) var isLoading = true
    @Published var lastError: String?

    @Published var isLoggedIn = false
    @Published var realName = "The Druid"
    @Published var scansCount = 0
    @Published var isPremium = false

    var rankTitle: String {
        switch scansCount {
        case 0 ... 5: return "Wandering Seed"
        case 6 ... 15: return "Forest Sprout"
        case 16 ... 50: return "Oak Guardian"
        default: return "Archdruid"
        }
    }

    var remainingScans: Int {
        if isPremium { return Int.max }
        return max(0, Self.freeScanLimit - scansCount)
    }

    var energyProgress: Double {
        if isPremium { return 1 }
        let consumed = min(Self.freeScanLimit, max(0, scansCount))
        return Double(consumed) / Double(Self.freeScanLimit)
    }

    func canUserScan() -> Bool {
        isPremium || scansCount < Self.freeScanLimit
    }

    func googleSignInURL() -> URL? {
        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: Self.googleClientID),
            URLQueryItem(name: "response_type", value: "token"),
            URLQueryItem(name: "scope", value: "openid email profile"),
            URLQueryItem(name: "redirect_uri", value: "com.googleusercontent.apps.133761573510-233kdml7mn0p0d19pksj62h1t27oaide://auth"),
            URLQueryItem(name: "prompt", value: "select_account"),
        ]
        return components?.url
    }

    func completeLocalGoogleLoginDisplay(name: String = "LeafID Explorer") {
        isLoggedIn = true
        realName = name
        UserDefaults.standard.set(true, forKey: "druid.is_logged_in")
        UserDefaults.standard.set(name, forKey: "druid.real_name")
    }

    func refresh() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        isLoggedIn = UserDefaults.standard.bool(forKey: "druid.is_logged_in")
        realName = UserDefaults.standard.string(forKey: "druid.real_name") ?? "The Druid"
        scansCount = UserDefaults.standard.integer(forKey: "profile.scans_count")
        isPremium = UserDefaults.standard.bool(forKey: "profile.is_premium")

        // Placeholder: replace with Supabase `profiles` + aggregates once auth is fully wired.
        try? await Task.sleep(nanoseconds: 350_000_000)
        profile = Profile(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID(),
            displayName: realName,
            bio: """
            Field botanist at heart — collecting ancient seeds one walk at a time. \
            The Herbarium is my journal; the Arboretum, my map of wonder.
            """,
            avatarURL: nil,
            scansCount: scansCount,
            isPremium: isPremium,
            ancientSeedsCount: 12
        )
        specimenCount = scansCount
        ancientSeedsCount = profile?.ancientSeedsCount ?? 0
    }
}
