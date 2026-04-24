//
//  LeafID_nativeApp.swift
//  LeafID-native
//
//  Created by Mariana Minafro Spinelli on 11/04/2026.
//

import SwiftUI

@main
struct LeafID_nativeApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isLoadingSession {
                    ZStack {
                        LeafIDTheme.deepForest.ignoresSafeArea()
                        ProgressView("Restoring session...")
                            .tint(.white)
                            .foregroundStyle(.white)
                    }
                } else if authViewModel.isAuthenticated {
                    MainTabView()
                } else {
                    LoginView()
                }
            }
                .environmentObject(authViewModel)
                .onOpenURL { url in
                    Task {
                        await authViewModel.handleOAuthCallback(url)
                    }
                }
        }
    }
}

@MainActor
final class AuthViewModel: ObservableObject {
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isLoadingSession = true
    @Published private(set) var isHandlingOAuthCallback = false
    @Published private(set) var displayName = "The Druid"
    @Published private(set) var email = ""
    @Published var lastError: String?

    private let defaults = UserDefaults.standard
    private let sessionAccessTokenKey = "auth.session.access_token"
    private let sessionRefreshTokenKey = "auth.session.refresh_token"
    private let sessionExpiryEpochKey = "auth.session.expires_at_epoch"
    private let druidLoggedInKey = "druid.is_logged_in"
    private let druidRealNameKey = "druid.real_name"
    private let profileScansCountKey = "profile.scans_count"
    private let profileIsPremiumKey = "profile.is_premium"
    private let googleIOSRedirectURI = "com.googleusercontent.apps.133761573510-233kdml7mn0p0d19pksj62h1t27oaide://auth"

    init() {
        Task { await restoreSession() }
    }

    func googleOAuthURL() -> URL? {
        var components = URLComponents(string: "https://yuflikryfeunofptgrtr.supabase.co/auth/v1/authorize")
        components?.queryItems = [
            URLQueryItem(name: "provider", value: "google"),
            URLQueryItem(name: "redirect_to", value: googleIOSRedirectURI),
        ]
        return components?.url
    }

    func handleOAuthCallback(_ url: URL) async {
        guard url.host?.lowercased() == "auth" else { return }
        let acceptedSchemes = ["com.googleusercontent.apps.133761573510-233kdml7mn0p0d19pksj62h1t27oaide"]
        guard let callbackScheme = url.scheme?.lowercased(),
              acceptedSchemes.contains(callbackScheme)
        else { return }
        isHandlingOAuthCallback = true
        defer { isHandlingOAuthCallback = false }

        let values = parseOAuthValues(url)
        if values["error"] != nil {
            clearSession()
            lastError = "Google sign-in was cancelled or denied."
            return
        }

        guard let accessToken = values["access_token"], !accessToken.isEmpty else {
            lastError = "Missing access token from OAuth callback."
            return
        }
        let refreshToken = values["refresh_token"]
        let expiresAtEpoch = values["expires_at"].flatMap(TimeInterval.init)
            ?? values["expires_in"].flatMap(TimeInterval.init).map { Date().timeIntervalSince1970 + $0 }

        persistSessionTokens(accessToken: accessToken, refreshToken: refreshToken, expiresAtEpoch: expiresAtEpoch)
        await hydrateSession(accessToken: accessToken)
    }

    func signOut() {
        clearSession()
    }

    private func restoreSession() async {
        defer { isLoadingSession = false }
        guard let accessToken = defaults.string(forKey: sessionAccessTokenKey), !accessToken.isEmpty else {
            clearSession()
            return
        }

        let expiresAt = defaults.double(forKey: sessionExpiryEpochKey)
        if expiresAt > 0, Date().timeIntervalSince1970 >= expiresAt {
            clearSession()
            return
        }

        await hydrateSession(accessToken: accessToken)
    }

    private func hydrateSession(accessToken: String) async {
        do {
            let user = try await fetchUser(accessToken: accessToken)
            let profile: DruidProfileRow?
            do {
                profile = try await fetchProfile(accessToken: accessToken, userID: user.id)
            } catch {
                // Do not fail login when profile bootstrap/query is not ready yet.
                profile = nil
            }

            email = user.email ?? ""
            displayName = profile?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                ?? user.fullName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                ?? "The Druid"

            defaults.set(true, forKey: druidLoggedInKey)
            defaults.set(displayName, forKey: druidRealNameKey)
            defaults.set(profile?.scansCount ?? 0, forKey: profileScansCountKey)
            defaults.set(profile?.isPremium ?? false, forKey: profileIsPremiumKey)

            isAuthenticated = true
            lastError = nil
            NotificationCenter.default.post(name: .druidAuthDidChange, object: nil)
        } catch {
            clearSession()
            lastError = "Failed to restore session from Supabase."
        }
    }

    private func clearSession() {
        defaults.removeObject(forKey: sessionAccessTokenKey)
        defaults.removeObject(forKey: sessionRefreshTokenKey)
        defaults.removeObject(forKey: sessionExpiryEpochKey)
        defaults.set(false, forKey: druidLoggedInKey)
        defaults.removeObject(forKey: druidRealNameKey)
        defaults.set(0, forKey: profileScansCountKey)
        defaults.set(false, forKey: profileIsPremiumKey)
        isAuthenticated = false
        email = ""
        displayName = "The Druid"
        NotificationCenter.default.post(name: .druidAuthDidChange, object: nil)
    }

    private func persistSessionTokens(accessToken: String, refreshToken: String?, expiresAtEpoch: TimeInterval?) {
        defaults.set(accessToken, forKey: sessionAccessTokenKey)
        if let refreshToken, !refreshToken.isEmpty {
            defaults.set(refreshToken, forKey: sessionRefreshTokenKey)
        } else {
            defaults.removeObject(forKey: sessionRefreshTokenKey)
        }
        if let expiresAtEpoch {
            defaults.set(expiresAtEpoch, forKey: sessionExpiryEpochKey)
        } else {
            defaults.removeObject(forKey: sessionExpiryEpochKey)
        }
    }

    private func supabaseRootURLString() -> String? {
        let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
        let value = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !value.isEmpty, value.hasPrefix("http"), !value.contains("$(") else { return nil }
        return value.hasSuffix("/") ? String(value.dropLast()) : value
    }

    private func supabaseAnonKey() -> String? {
        let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String
        let value = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !value.isEmpty, !value.contains("$(") else { return nil }
        return value
    }

    private func parseOAuthValues(_ url: URL) -> [String: String] {
        let payload = [url.fragment ?? "", url.query ?? ""]
            .filter { !$0.isEmpty }
            .joined(separator: "&")

        let pairs = payload
            .split(separator: "&")
            .map(String.init)
            .map { pair -> (String, String) in
                let chunks = pair.split(separator: "=", maxSplits: 1).map(String.init)
                let key = chunks.first ?? ""
                let value = chunks.count > 1 ? chunks[1] : ""
                return (key, value.removingPercentEncoding ?? value)
            }
        return Dictionary(uniqueKeysWithValues: pairs)
    }

    private func fetchUser(accessToken: String) async throws -> AuthUser {
        guard let root = supabaseRootURLString(), let anon = supabaseAnonKey(),
              let url = URL(string: "\(root)/auth/v1/user") else { throw AuthError.configuration }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(anon, forHTTPHeaderField: "apikey")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw AuthError.requestFailed
        }
        return try JSONDecoder().decode(AuthUser.self, from: data)
    }

    private func fetchProfile(accessToken: String, userID: String) async throws -> DruidProfileRow? {
        guard let root = supabaseRootURLString(), let anon = supabaseAnonKey() else { throw AuthError.configuration }
        var components = URLComponents(string: "\(root)/rest/v1/profiles")
        components?.queryItems = [
            URLQueryItem(name: "id", value: "eq.\(userID)"),
            URLQueryItem(name: "select", value: "display_name,scans_count,is_premium"),
            URLQueryItem(name: "limit", value: "1"),
        ]
        guard let url = components?.url else { throw AuthError.configuration }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(anon, forHTTPHeaderField: "apikey")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw AuthError.requestFailed
        }
        let rows = try JSONDecoder().decode([DruidProfileRow].self, from: data)
        return rows.first
    }

}

private enum AuthError: Error {
    case configuration
    case requestFailed
}

private struct AuthUser: Decodable {
    let id: String
    let email: String?
    let userMetadata: UserMetadata?

    var fullName: String? { userMetadata?.fullName ?? userMetadata?.name }

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case userMetadata = "user_metadata"
    }
}

private struct UserMetadata: Decodable {
    let fullName: String?
    let name: String?

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case name
    }
}

private struct DruidProfileRow: Decodable {
    let displayName: String?
    let scansCount: Int?
    let isPremium: Bool?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case scansCount = "scans_count"
        case isPremium = "is_premium"
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

struct LoginView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            LeafIDTheme.deepForest.ignoresSafeArea()
            VStack(alignment: .leading, spacing: LeafIDTheme.space20) {
                Text("LeafID")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Sign in to restore your Druid Passport and Supabase profile.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(LeafIDTheme.slateMuted)

                Button {
                    guard let authURL = authViewModel.googleOAuthURL() else { return }
                    openURL(authURL)
                } label: {
                    Text("Continue with Google")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, LeafIDTheme.space14)
                        .background(LeafIDTheme.leafGreen)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
                }
                .buttonStyle(.plain)

                if authViewModel.isHandlingOAuthCallback {
                    ProgressView("Signing in...")
                        .tint(.white)
                        .foregroundStyle(.white)
                } else if let lastError = authViewModel.lastError {
                    Text(lastError)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.red.opacity(0.9))
                }
            }
            .padding(LeafIDTheme.space24)
        }
    }
}

extension Notification.Name {
    static let druidAuthDidChange = Notification.Name("druidAuthDidChange")
}
