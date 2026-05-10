//
//  LeafID_nativeApp.swift
//  LeafID-native
//
//  Created by Mariana Minafro Spinelli on 11/04/2026.
//

import CryptoKit
import Security
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
                            .accessibilityLabel("Restoring session")
                    }
                } else if authViewModel.isInPasswordRecovery {
                    PasswordRecoveryView()
                } else if authViewModel.isAuthenticated {
                    MainTabView()
                } else {
                    LoginView()
                }
            }
                .environmentObject(authViewModel)
                .leafIDToastHost()
                .onAppear {
                    ProfileStatsLocalStore.reconcileProfileQuotaWithLifetime()
                }
                .onOpenURL { url in
                    Task {
                        await authViewModel.handleIncomingURL(url)
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
    @Published private(set) var isAuthenticatingEmail = false
    @Published private(set) var isSendingPasswordReset = false
    @Published private(set) var isUpdatingPassword = false
    @Published private(set) var isInPasswordRecovery = false
    @Published private(set) var passwordResetEmailDestination: String?
    @Published private(set) var displayName = "The Druid"
    @Published private(set) var email = ""
    @Published var lastError: String?
    @Published var authNotice: String?

    private let defaults = UserDefaults.standard
    private let sessionAccessTokenKey = "auth.session.access_token"
    private let sessionRefreshTokenKey = "auth.session.refresh_token"
    private let sessionExpiryEpochKey = "auth.session.expires_at_epoch"
    private let druidLoggedInKey = "druid.is_logged_in"
    private let druidRealNameKey = "druid.real_name"
    private let profileScansCountKey = "profile.scans_count"
    private let profileIsPremiumKey = "profile.is_premium"
    private let googleIOSRedirectURI = "com.googleusercontent.apps.133761573510-233kdml7mn0p0d19pksj62h1t27oaide://auth"
    private let oauthPKCEVerifierKey = "auth.oauth.pkce.verifier"

    /// Same role as JS `resetPasswordForEmail(..., { redirectTo })`: value comes from `PASSWORD_RESET_REDIRECT` in Info.plist (xcconfig → build).
    private var passwordResetRedirectURI: String {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "PASSWORD_RESET_REDIRECT") as? String else {
            return "com.marianaminafro.leafid://reset-password"
        }
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("\""), value.hasSuffix("\""), value.count >= 2 {
            value = String(value.dropFirst().dropLast())
        }
        guard !value.isEmpty, !value.contains("$("), value != "$(PASSWORD_RESET_REDIRECT)" else {
            return "com.marianaminafro.leafid://reset-password"
        }
        return value
    }

    init() {
        Task { await restoreSession() }
    }

    func googleOAuthURL() -> URL? {
        guard let root = supabaseRootURLString(), let anon = supabaseAnonKey(),
              let verifier = makePKCEVerifier()
        else { return nil }
        defaults.set(verifier, forKey: oauthPKCEVerifierKey)
        let challenge = pkceChallengeS256(verifier: verifier)
        var components = URLComponents(string: "\(root)/auth/v1/authorize")
        components?.queryItems = [
            URLQueryItem(name: "provider", value: "google"),
            URLQueryItem(name: "redirect_to", value: googleIOSRedirectURI),
            URLQueryItem(name: "apikey", value: anon),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
        ]
        return components?.url
    }

    func handleIncomingURL(_ url: URL) async {
        let scheme = url.scheme?.lowercased() ?? ""
        let host = url.host?.lowercased() ?? ""

        if host == "auth",
           scheme == "com.googleusercontent.apps.133761573510-233kdml7mn0p0d19pksj62h1t27oaide"
        {
            await handleOAuthCallback(url)
            return
        }

        if isLeafIDPasswordRecoveryDeepLink(url) {
            await handlePasswordRecoveryCallback(url)
        }
    }

    /// `com.marianaminafro.leafid://reset-password#...` (host) or rare path-only variants.
    private func isLeafIDPasswordRecoveryDeepLink(_ url: URL) -> Bool {
        guard url.scheme?.caseInsensitiveCompare("com.marianaminafro.leafid") == .orderedSame else { return false }
        let host = (url.host ?? "").lowercased()
        if host == "reset-password" { return true }
        let path = url.path.lowercased()
        return path == "/reset-password" || path.hasSuffix("/reset-password")
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
            defaults.removeObject(forKey: oauthPKCEVerifierKey)
            lastError = "Google sign-in was cancelled or denied."
            return
        }

        let authCode = values["code"] ?? values["auth_code"]
        if let authCode, !authCode.isEmpty {
            do {
                let session = try await exchangePKCE(authCode: authCode)
                let expiresAtEpoch = Date().timeIntervalSince1970 + TimeInterval(session.expiresIn)
                persistSessionTokens(
                    accessToken: session.accessToken,
                    refreshToken: session.refreshToken,
                    expiresAtEpoch: expiresAtEpoch
                )
                await hydrateSession(accessToken: session.accessToken)
            } catch {
                clearSession()
                lastError = "Could not complete Google sign-in. Try again."
            }
            return
        }

        guard let accessToken = values["access_token"], !accessToken.isEmpty else {
            defaults.removeObject(forKey: oauthPKCEVerifierKey)
            lastError = "Missing access token from OAuth callback."
            return
        }
        defaults.removeObject(forKey: oauthPKCEVerifierKey)
        let refreshToken = values["refresh_token"]
        let expiresAtEpoch = values["expires_at"].flatMap(TimeInterval.init)
            ?? values["expires_in"].flatMap(TimeInterval.init).map { Date().timeIntervalSince1970 + $0 }

        persistSessionTokens(accessToken: accessToken, refreshToken: refreshToken, expiresAtEpoch: expiresAtEpoch)
        await hydrateSession(accessToken: accessToken)
    }

    func signInWithEmail(email: String, password: String) async {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedEmail.isEmpty, !password.isEmpty else {
            lastError = "Enter both email and password."
            return
        }

        isAuthenticatingEmail = true
        defer { isAuthenticatingEmail = false }
        authNotice = nil

        do {
            let session = try await signInWithEmailPassword(email: normalizedEmail, password: password)
            let expiresAtEpoch = Date().timeIntervalSince1970 + TimeInterval(session.expiresIn)
            persistSessionTokens(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                expiresAtEpoch: expiresAtEpoch
            )
            await hydrateSession(accessToken: session.accessToken)
        } catch {
            clearSession()
            lastError = "Invalid email or password."
        }
    }

    func signUpWithEmail(email: String, password: String) async {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedEmail.isEmpty, !password.isEmpty else {
            lastError = "Enter both email and password."
            return
        }
        guard password.count >= 6 else {
            lastError = "Password must be at least 6 characters."
            return
        }

        isAuthenticatingEmail = true
        defer { isAuthenticatingEmail = false }
        authNotice = nil
        lastError = nil

        do {
            if let session = try await registerWithEmailPassword(email: normalizedEmail, password: password) {
                let expiresAtEpoch = Date().timeIntervalSince1970 + TimeInterval(session.expiresIn)
                persistSessionTokens(
                    accessToken: session.accessToken,
                    refreshToken: session.refreshToken,
                    expiresAtEpoch: expiresAtEpoch
                )
                await hydrateSession(accessToken: session.accessToken)
            } else {
                authNotice = "Check your email to confirm your account, then sign in."
            }
        } catch {
            clearSession()
            lastError = "Could not create account. This email may already be registered."
        }
    }

    func sendPasswordReset(email: String) async {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedEmail.contains("@") else {
            lastError = "Enter a valid email address."
            return
        }

        isSendingPasswordReset = true
        defer { isSendingPasswordReset = false }

        do {
            try await requestPasswordReset(email: normalizedEmail)
            passwordResetEmailDestination = normalizedEmail
            lastError = nil
            ToastCenter.shared.show(
                String(localized: "Recovery email sent. Check your inbox and spam."),
                kind: .success
            )
        } catch let auth as AuthError {
            switch auth {
            case .configuration:
                lastError =
                    "Supabase is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY in Secrets.local.xcconfig."
            case .serverMessage(let message):
                lastError = message
            case .requestFailed:
                lastError = "Could not send reset email. Try again."
            }
        } catch {
            lastError = "Could not send reset email. Try again."
        }
    }

    func updatePassword(_ newPassword: String) async {
        guard newPassword.count >= 8 else {
            lastError = "Password must be at least 8 characters."
            return
        }
        guard let accessToken = defaults.string(forKey: sessionAccessTokenKey), !accessToken.isEmpty else {
            lastError = "Recovery session expired. Request another reset email."
            return
        }

        isUpdatingPassword = true
        defer { isUpdatingPassword = false }

        do {
            try await updateSupabasePassword(accessToken: accessToken, newPassword: newPassword)
            isInPasswordRecovery = false
            lastError = nil
            ToastCenter.shared.show(
                String(localized: "Password updated. Sign in with your new password."),
                kind: .success
            )
        } catch {
            lastError = "Could not update password. Request a new recovery link."
        }
    }

    func exitPasswordRecovery() {
        isInPasswordRecovery = false
        signOut()
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

    private func handlePasswordRecoveryCallback(_ url: URL) async {
        let values = parseOAuthValues(url)
        if values["error"] != nil {
            lastError = "This recovery link is invalid or expired."
            return
        }

        guard let accessToken = values["access_token"], !accessToken.isEmpty else {
            lastError = "Recovery session token missing."
            return
        }
        let refreshToken = values["refresh_token"]
        let expiresAtEpoch = values["expires_at"].flatMap(TimeInterval.init)
            ?? values["expires_in"].flatMap(TimeInterval.init).map { Date().timeIntervalSince1970 + $0 }

        persistSessionTokens(accessToken: accessToken, refreshToken: refreshToken, expiresAtEpoch: expiresAtEpoch)
        await hydrateSession(accessToken: accessToken)
        if isAuthenticated {
            isInPasswordRecovery = true
        }
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
            let serverScans = profile?.scansCount ?? 0
            let localLifetime = ProfileStatsLocalStore.totalScans
            defaults.set(max(serverScans, localLifetime), forKey: profileScansCountKey)
            defaults.set(profile?.isPremium ?? false, forKey: profileIsPremiumKey)

            isAuthenticated = true
            lastError = nil
            authNotice = nil
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
        isInPasswordRecovery = false
        email = ""
        displayName = "The Druid"
        passwordResetEmailDestination = nil
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
        var value = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if value.hasPrefix("\""), value.hasSuffix("\""), value.count >= 2 {
            value = String(value.dropFirst().dropLast())
        }
        guard !value.isEmpty, value.hasPrefix("http"), !value.contains("$(") else { return nil }
        // Reject xcconfig mistakes: unquoted `https://...` becomes `https:` because // starts a comment.
        guard let host = URL(string: value)?.host, host.contains(".") else { return nil }
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

        var result: [String: String] = [:]
        for rawPair in payload.split(separator: "&") {
            let pair = String(rawPair)
            let chunks = pair.split(separator: "=", maxSplits: 1).map(String.init)
            let key = chunks.first ?? ""
            guard !key.isEmpty else { continue }
            let value = chunks.count > 1 ? chunks[1] : ""
            result[key] = value.removingPercentEncoding ?? value
        }
        return result
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

    private func signInWithEmailPassword(email: String, password: String) async throws -> AuthSession {
        guard let root = supabaseRootURLString(), let anon = supabaseAnonKey(),
              let url = URL(string: "\(root)/auth/v1/token?grant_type=password")
        else { throw AuthError.configuration }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anon, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONEncoder().encode(EmailPasswordPayload(email: email, password: password))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw AuthError.requestFailed
        }
        return try JSONDecoder().decode(AuthSession.self, from: data)
    }

    private func registerWithEmailPassword(email: String, password: String) async throws -> AuthSession? {
        guard let root = supabaseRootURLString(), let anon = supabaseAnonKey(),
              let url = URL(string: "\(root)/auth/v1/signup")
        else { throw AuthError.configuration }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anon, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONEncoder().encode(EmailPasswordPayload(email: email, password: password))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw AuthError.requestFailed
        }

        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        func session(from dict: [String: Any]) -> AuthSession? {
            guard let at = dict["access_token"] as? String, !at.isEmpty,
                  let exp = dict["expires_in"] as? Int
            else { return nil }
            let rt = dict["refresh_token"] as? String
            return AuthSession(accessToken: at, refreshToken: rt, expiresIn: exp)
        }
        if let s = session(from: obj) { return s }
        if let nested = obj["session"] as? [String: Any] { return session(from: nested) }
        return nil
    }

    private func exchangePKCE(authCode: String) async throws -> AuthSession {
        guard let root = supabaseRootURLString(), let anon = supabaseAnonKey(),
              let url = URL(string: "\(root)/auth/v1/token?grant_type=pkce"),
              let verifier = defaults.string(forKey: oauthPKCEVerifierKey), !verifier.isEmpty
        else { throw AuthError.configuration }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anon, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONEncoder().encode(PKCEExchangePayload(authCode: authCode, codeVerifier: verifier))

        let (data, response) = try await URLSession.shared.data(for: request)
        defaults.removeObject(forKey: oauthPKCEVerifierKey)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw AuthError.requestFailed
        }
        return try JSONDecoder().decode(AuthSession.self, from: data)
    }

    private func makePKCEVerifier() -> String? {
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else { return nil }
        return Data(bytes).base64URLEncodedString()
    }

    private func pkceChallengeS256(verifier: String) -> String {
        let hash = SHA256.hash(data: Data(verifier.utf8))
        return Data(hash).base64URLEncodedString()
    }

    private func requestPasswordReset(email: String) async throws {
        guard let root = supabaseRootURLString(), let anon = supabaseAnonKey() else { throw AuthError.configuration }
        var components = URLComponents(string: "\(root)/auth/v1/recover")
        components?.queryItems = [
            URLQueryItem(name: "redirect_to", value: passwordResetRedirectURI),
        ]
        guard let url = components?.url else { throw AuthError.configuration }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anon, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anon)", forHTTPHeaderField: "Authorization")
        // GoTrue reads `redirect_to` from header / query (same as JS `resetPasswordForEmail` options.redirectTo). JSON body is email-only.
        request.setValue(passwordResetRedirectURI, forHTTPHeaderField: "redirect_to")
        request.httpBody = try JSONEncoder().encode(PasswordResetPayload(email: email))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.requestFailed }
        if (200 ... 299).contains(http.statusCode) { return }
        if let message = supabaseAuthErrorMessage(from: data) {
            throw AuthError.serverMessage(message)
        }
        throw AuthError.requestFailed
    }

    private func supabaseAuthErrorMessage(from data: Data) -> String? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        let candidates: [String?] = [
            obj["msg"] as? String,
            obj["message"] as? String,
            obj["error_description"] as? String,
            (obj["error"] as? String),
        ]
        let text = candidates.compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }.first { !$0.isEmpty }
        return text
    }

    private func updateSupabasePassword(accessToken: String, newPassword: String) async throws {
        guard let root = supabaseRootURLString(), let anon = supabaseAnonKey(),
              let url = URL(string: "\(root)/auth/v1/user")
        else { throw AuthError.configuration }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(anon, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONEncoder().encode(UpdatePasswordPayload(password: newPassword))

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw AuthError.requestFailed
        }
    }

}

private enum AuthError: Error {
    case configuration
    case requestFailed
    case serverMessage(String)
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

private struct AuthSession: Decodable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int

    init(accessToken: String, refreshToken: String?, expiresIn: Int) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
    }

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try c.decode(String.self, forKey: .accessToken)
        refreshToken = try c.decodeIfPresent(String.self, forKey: .refreshToken)
        expiresIn = try c.decode(Int.self, forKey: .expiresIn)
    }
}

private struct PKCEExchangePayload: Encodable {
    let authCode: String
    let codeVerifier: String

    enum CodingKeys: String, CodingKey {
        case authCode = "auth_code"
        case codeVerifier = "code_verifier"
    }
}

private struct EmailPasswordPayload: Encodable {
    let email: String
    let password: String
}

private struct PasswordResetPayload: Encodable {
    let email: String
}

private struct UpdatePasswordPayload: Encodable {
    let password: String
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

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

struct LoginView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.openURL) private var openURL
    @State private var email = ""
    @State private var password = ""
    @State private var resetEmail = ""
    @State private var showPassword = false
    @State private var showRecoverySheet = false
    @State private var isSignUpMode = false

    private var primaryEmailButtonTitle: String {
        if authViewModel.isAuthenticatingEmail {
            return isSignUpMode ? "Creating account..." : "Signing in..."
        }
        return isSignUpMode ? "Create account" : "Login"
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [LeafIDTheme.surface, LeafIDTheme.surfaceContainerLow, LeafIDTheme.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: LeafIDTheme.space24) {
                    VStack(spacing: LeafIDTheme.space12) {
                        Circle()
                            .fill(LeafIDTheme.primary.opacity(0.2))
                            .frame(width: 68, height: 68)
                            .overlay {
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundStyle(LeafIDTheme.primary)
                            }
                        Text(isSignUpMode ? "Join LeafID" : "Welcome Back")
                            .font(LeafIDFont.plusJakarta(size: 46, weight: .bold))
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                            .foregroundStyle(LeafIDTheme.onSurface)
                        Text(isSignUpMode ? "Create an account to save your journey" : "Sign in to continue your journey")
                            .font(LeafIDFont.manrope(size: 20, weight: .medium))
                            .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, LeafIDTheme.space28)

                    VStack(alignment: .leading, spacing: LeafIDTheme.space16) {
                        AuthFieldLabel("EMAIL ADDRESS")
                        AuthTextField(text: $email, placeholder: "name@example.com", systemImage: "envelope.fill")
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()

                        HStack(alignment: .center) {
                            AuthFieldLabel("PASSWORD")
                            Spacer(minLength: 0)
                            if !isSignUpMode {
                                Button("Forgot?") {
                                    resetEmail = email
                                    showRecoverySheet = true
                                }
                                .font(LeafIDFont.manrope(size: 16, weight: .semibold))
                                .foregroundStyle(LeafIDTheme.primary)
                                .buttonStyle(.plain)
                            }
                        }

                        AuthSecureField(
                            text: $password,
                            placeholder: "Enter your password",
                            showPassword: $showPassword
                        )

                        LeafPrimaryButton(
                            title: primaryEmailButtonTitle,
                            leadingSystemImage: "arrow.right",
                            isEnabled: !authViewModel.isAuthenticatingEmail,
                            useSolidPrimaryFill: true
                        ) {
                            guard !email.isEmpty, !password.isEmpty else {
                                authViewModel.lastError = "Enter both email and password."
                                return
                            }
                            Task {
                                if isSignUpMode {
                                    await authViewModel.signUpWithEmail(email: email, password: password)
                                } else {
                                    await authViewModel.signInWithEmail(email: email, password: password)
                                }
                            }
                        }
                    }

                    Button {
                        guard let authURL = authViewModel.googleOAuthURL() else {
                            authViewModel.lastError =
                                "Supabase is not configured. Add SUPABASE_URL (quoted) and SUPABASE_ANON_KEY in Secrets.local.xcconfig."
                            return
                        }
                        authViewModel.lastError = nil
                        openURL(authURL)
                    } label: {
                        Text("Continue with Google")
                            .font(LeafIDFont.manrope(size: LeafIDFont.boutiqueSubtitleSize, weight: .semibold))
                            .foregroundStyle(LeafIDTheme.onSurface)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, LeafIDTheme.space16)
                            .padding(.horizontal, LeafIDTheme.space20)
                            .background(LeafIDTheme.surfaceContainerHighest)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                                    .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.15), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(authViewModel.isHandlingOAuthCallback)
                    .opacity(authViewModel.isHandlingOAuthCallback ? 0.55 : 1)

                    HStack(spacing: LeafIDTheme.space6) {
                        Text(isSignUpMode ? "Already have an account?" : "Don't have an account?")
                            .font(LeafIDFont.manrope(size: 16, weight: .medium))
                            .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                        Button(isSignUpMode ? "Sign in" : "Sign Up") {
                            isSignUpMode.toggle()
                            authViewModel.lastError = nil
                            authViewModel.authNotice = nil
                        }
                        .font(LeafIDFont.manrope(size: 16, weight: .semibold))
                        .foregroundStyle(LeafIDTheme.primary)
                        .buttonStyle(.plain)
                    }
                    .padding(.top, LeafIDTheme.space8)

                    if authViewModel.isHandlingOAuthCallback {
                        ProgressView("Completing Google sign in...")
                            .tint(LeafIDTheme.primary)
                            .foregroundStyle(LeafIDTheme.onSurface)
                            .accessibilityLabel("Completing Google sign in")
                    } else if let notice = authViewModel.authNotice {
                        Text(notice)
                            .font(LeafIDFont.manrope(size: 14, weight: .medium))
                            .foregroundStyle(LeafIDTheme.primary.opacity(0.95))
                            .multilineTextAlignment(.center)
                    } else if let lastError = authViewModel.lastError {
                        Text(lastError)
                            .font(LeafIDFont.manrope(size: 14, weight: .medium))
                            .foregroundStyle(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }

                    if let destination = authViewModel.passwordResetEmailDestination {
                        Text(
                            "Recovery email sent to \(destination). Check spam or promotions folders if it doesn’t arrive within a few minutes.\n\nFrom Gmail (or similar), open the link in Safari: tap ··· or the share icon, choose Open in Browser / Safari. In-app mail browsers often block returning to the app."
                        )
                        .font(LeafIDFont.manrope(size: 14, weight: .medium))
                        .foregroundStyle(LeafIDTheme.primary.opacity(0.95))
                        .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                .padding(.bottom, LeafIDTheme.space32)
            }
        }
        .sheet(isPresented: $showRecoverySheet) {
            PasswordRecoveryRequestSheet(email: $resetEmail)
                .environmentObject(authViewModel)
        }
    }
}

private struct PasswordRecoveryView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false
    @State private var localError: String?

    var body: some View {
        ZStack {
            LeafIDTheme.surface.ignoresSafeArea()
            VStack(alignment: .leading, spacing: LeafIDTheme.space20) {
                Text("Create new password")
                    .font(LeafIDFont.plusJakarta(size: 34, weight: .bold))
                    .foregroundStyle(LeafIDTheme.onSurface)
                Text("Set a new password to finish your account recovery.")
                    .font(LeafIDFont.manrope(size: 16, weight: .medium))
                    .foregroundStyle(LeafIDTheme.onSurfaceVariant)

                VStack(alignment: .leading, spacing: LeafIDTheme.space12) {
                    AuthFieldLabel("NEW PASSWORD")
                    AuthSecureField(
                        text: $newPassword,
                        placeholder: "Minimum 8 characters",
                        showPassword: $showNewPassword
                    )
                    AuthFieldLabel("CONFIRM PASSWORD")
                    AuthSecureField(
                        text: $confirmPassword,
                        placeholder: "Repeat your password",
                        showPassword: $showConfirmPassword
                    )
                }

                if let localError {
                    Text(localError)
                        .font(LeafIDFont.manrope(size: 14, weight: .medium))
                        .foregroundStyle(.red.opacity(0.9))
                } else if let authError = authViewModel.lastError {
                    Text(authError)
                        .font(LeafIDFont.manrope(size: 14, weight: .medium))
                        .foregroundStyle(.red.opacity(0.9))
                }

                LeafPrimaryButton(
                    title: authViewModel.isUpdatingPassword ? "Updating..." : "Update Password",
                    isEnabled: !authViewModel.isUpdatingPassword && !newPassword.isEmpty && !confirmPassword.isEmpty,
                    useSolidPrimaryFill: true
                ) {
                    guard newPassword == confirmPassword else {
                        localError = "Passwords do not match."
                        return
                    }
                    localError = nil
                    Task {
                        await authViewModel.updatePassword(newPassword)
                    }
                }

                Button("Back to login") {
                    authViewModel.exitPasswordRecovery()
                }
                .font(LeafIDFont.manrope(size: 15, weight: .medium))
                .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, LeafIDTheme.space4)
            }
            .padding(LeafIDTheme.space24)
        }
    }
}

private struct PasswordRecoveryRequestSheet: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var email: String

    var body: some View {
        NavigationStack {
            ZStack {
                LeafIDTheme.surface.ignoresSafeArea()
                VStack(alignment: .leading, spacing: LeafIDTheme.space16) {
                    Text("Recover password")
                        .font(LeafIDFont.plusJakarta(size: 28, weight: .bold))
                        .foregroundStyle(LeafIDTheme.onSurface)
                    Text("Enter your account email and we will send a recovery link.")
                        .font(LeafIDFont.manrope(size: 15, weight: .medium))
                        .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                    Text(
                        "Tip: after you receive the email, open the link in Safari if the app does not open (Gmail’s in-app browser often blocks app links)."
                    )
                    .font(LeafIDFont.manrope(size: 13, weight: .medium))
                    .foregroundStyle(LeafIDTheme.onSurfaceVariant.opacity(0.9))

                    AuthFieldLabel("EMAIL")
                    AuthTextField(text: $email, placeholder: "name@example.com", systemImage: "envelope.fill")
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()

                    LeafPrimaryButton(
                        title: authViewModel.isSendingPasswordReset ? "Sending..." : "Send recovery link",
                        isEnabled: !authViewModel.isSendingPasswordReset && !email.isEmpty,
                        useSolidPrimaryFill: true
                    ) {
                        Task {
                            await authViewModel.sendPasswordReset(email: email)
                            if authViewModel.lastError == nil {
                                dismiss()
                            }
                        }
                    }

                    if let error = authViewModel.lastError {
                        Text(error)
                            .font(LeafIDFont.manrope(size: 14, weight: .medium))
                            .foregroundStyle(.red.opacity(0.9))
                    }

                    Spacer(minLength: 0)
                }
                .padding(LeafIDTheme.space24)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ModalCloseButton { dismiss() }
                }
            }
        }
    }
}

private struct AuthFieldLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(LeafIDFont.manrope(size: 13, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(LeafIDTheme.onSurfaceVariant)
    }
}

private struct AuthTextField: View {
    @Binding var text: String
    let placeholder: String
    let systemImage: String

    var body: some View {
        HStack(spacing: LeafIDTheme.space12) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(LeafIDTheme.onSurfaceVariant)
            TextField(placeholder, text: $text)
                .font(LeafIDFont.manrope(size: 17, weight: .medium))
                .foregroundStyle(LeafIDTheme.onSurface)
        }
        .padding(.horizontal, LeafIDTheme.space16)
        .padding(.vertical, LeafIDTheme.space16)
        .background(LeafIDTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: LeafIDTheme.radiusPrimaryButton, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: LeafIDTheme.radiusPrimaryButton, style: .continuous)
                .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.35), lineWidth: 1)
        }
    }
}

private struct AuthSecureField: View {
    @Binding var text: String
    let placeholder: String
    @Binding var showPassword: Bool

    var body: some View {
        HStack(spacing: LeafIDTheme.space12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(LeafIDTheme.onSurfaceVariant)

            Group {
                if showPassword {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .font(LeafIDFont.manrope(size: 17, weight: .medium))
            .foregroundStyle(LeafIDTheme.onSurface)

            Button {
                showPassword.toggle()
            } label: {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(LeafIDTheme.onSurfaceVariant)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, LeafIDTheme.space16)
        .padding(.vertical, LeafIDTheme.space16)
        .background(LeafIDTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: LeafIDTheme.radiusPrimaryButton, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: LeafIDTheme.radiusPrimaryButton, style: .continuous)
                .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.35), lineWidth: 1)
        }
    }
}

extension Notification.Name {
    static let druidAuthDidChange = Notification.Name("druidAuthDidChange")
    /// Posted after Herbarium scans are persisted (save or patch). Druid / stats UIs can refresh.
    static let herbariumCollectionDidChange = Notification.Name("herbariumCollectionDidChange")
}
