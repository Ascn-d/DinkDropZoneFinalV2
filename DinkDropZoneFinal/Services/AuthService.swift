import Foundation
import AuthenticationServices
import Observation
import SwiftData

// Simple Keychain helper
enum KeychainHelper {
    static func save(_ data: Data, for key: String) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                     kSecAttrAccount as String: key,
                                     kSecValueData as String: data]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw AuthError.keychain }
    }

    static func load(for key: String) throws -> Data? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                     kSecAttrAccount as String: key,
                                     kSecReturnData as String: kCFBooleanTrue!,
                                     kSecMatchLimit as String: kSecMatchLimitOne]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw AuthError.keychain }
        return result as? Data
    }

    static func delete(_ key: String) {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                     kSecAttrAccount as String: key]
        SecItemDelete(query as CFDictionary)
    }
}

enum AuthError: LocalizedError {
    case cancelled
    case keychain
    case network
    case unknown
}

@Observable
@MainActor
final class AuthService: NSObject {

    // MARK: - Published State
    private(set) var currentUser: User? = nil

    // MARK: - Private
    private var modelContext: ModelContext
    private let userIdentifierKey = "appleUserIdentifier"

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        super.init()
        Task { await restorePreviousSignIn() }
    }

    // MARK: - Public API
    func signInWithApple() async throws {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            controller.performRequests()
        }
    }

    func signOut() {
        currentUser = nil
        KeychainHelper.delete(userIdentifierKey)
    }

    // MARK: - Internal
    private func restorePreviousSignIn() async {
        if let data = try? KeychainHelper.load(for: userIdentifierKey),
           let identifier = String(data: data, encoding: .utf8) {
            do {
                let credential = try await ASAuthorizationAppleIDProvider().credentialState(forUserID: identifier)
                if credential == .authorized {
                    // For demo we just create a placeholder user
                    if let existing = fetchUser(byIdentifier: identifier) {
                        currentUser = existing
                    }
                }
            } catch {
                // ignore
            }
        }
    }

    private func fetchUser(byIdentifier id: String) -> User? {
        let descriptor = FetchDescriptor<User>()
        let users = (try? modelContext.fetch(descriptor)) ?? []
        return users.first { $0.email == id }
    }

    // Continuation storage
    private var continuation: CheckedContinuation<Void, Error>? = nil
}

// MARK: - ASAuthorizationControllerDelegate & Presentation
extension AuthService: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: AuthError.unknown); return
        }
        let userId = appleIDCredential.user
        // Save identifier to keychain
        try? KeychainHelper.save(Data(userId.utf8), for: userIdentifierKey)

        // Map to app User model
        let email = appleIDCredential.email ?? "user_\(userId)@example.com"
        let user: User
        if let existing = fetchUser(byIdentifier: email) {
            user = existing
        } else {
            user = User(email: email, password: "", elo: 1000, xp: 0, totalMatches: 0, wins: 0, losses: 0, winStreak: 0)
            user.displayName = appleIDCredential.fullName?.givenName ?? "Player"
            modelContext.insert(user)
        }
        currentUser = user
        continuation?.resume()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
            continuation?.resume(throwing: AuthError.cancelled)
        } else {
            continuation?.resume(throwing: AuthError.unknown)
        }
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Use the first connected window scene
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available")
        }
        return window
    }
}

 