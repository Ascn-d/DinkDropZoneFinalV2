import Foundation
import AuthenticationServices
import SwiftData
import FirebaseAuth

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
    case invalidUser
    case emailInUse
    case weakPassword
    case invalidEmail
    
    var errorDescription: String? {
        switch self {
        case .cancelled: return "Authentication was cancelled"
        case .keychain: return "Keychain access error"
        case .network: return "Network connection error"
        case .unknown: return "An unknown error occurred"
        case .invalidUser: return "User not found"
        case .emailInUse: return "Email is already in use"
        case .weakPassword: return "Password should be at least 6 characters"
        case .invalidEmail: return "Invalid email address"
        }
    }
}

@Observable
@MainActor
final class AuthService: NSObject {

    // MARK: - Published State
    private(set) var currentUser: User? = nil
    private(set) var isLoading = false
    private(set) var lastError: AuthError?

    // MARK: - Private
    private var modelContext: ModelContext
    private let userIdentifierKey = "appleUserIdentifier"
    private var firebaseAuthStateListener: AuthStateDidChangeListenerHandle?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        super.init()
        
        // Set up Firebase Auth state listener
        setupFirebaseAuthListener()
        
        Task { 
            await restorePreviousSignIn() 
        }
    }
    
    deinit {
        // Remove the Firebase auth listener on main actor
        Task { @MainActor in
            if let listener = firebaseAuthStateListener {
                Auth.auth().removeStateDidChangeListener(listener)
            }
        }
    }
    
    // MARK: - Firebase Auth Integration
    
    private func setupFirebaseAuthListener() {
        firebaseAuthStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor [weak self] in
                if let firebaseUser = user {
                    await self?.handleFirebaseUserSignIn(firebaseUser)
                } else {
                    await self?.handleFirebaseUserSignOut()
                }
            }
        }
    }
    
    private func handleFirebaseUserSignIn(_ firebaseUser: FirebaseAuth.User) async {
        print("🔥 Firebase user signed in: \(firebaseUser.uid)")
        
        do {
            let user = try await FirebaseService.shared.getUser(id: firebaseUser.uid)
            currentUser = user
            print("✅ Retrieved user profile: \(user.displayName)")
            
            // Notify AppState of user change
            await MainActor.run {
                NotificationCenter.default.post(
                    name: NSNotification.Name("AuthServiceUserChanged"),
                    object: user
                )
            }
        } catch {
            // If user doesn't exist in Firestore, create them
            print("👤 Creating new user profile for Firebase user")
            let newUser = User(
                email: firebaseUser.email ?? "",
                password: "", // Firebase handles auth
                displayName: firebaseUser.displayName ?? "Player"
            )
            
            do {
                try await FirebaseService.shared.createUser(newUser)
                currentUser = newUser
                print("✅ Created new user profile: \(newUser.displayName)")
                
                // Notify AppState of user change
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("AuthServiceUserChanged"),
                        object: newUser
                    )
                }
            } catch {
                print("❌ Failed to create user profile: \(error)")
                lastError = .unknown
            }
        }
    }
    
    private func handleFirebaseUserSignOut() async {
        print("🔥 Firebase user signed out")
        currentUser = nil
        KeychainHelper.delete(userIdentifierKey)
        
        // Notify AppState of sign out
        await MainActor.run {
            NotificationCenter.default.post(
                name: NSNotification.Name("AuthServiceUserChanged"),
                object: nil
            )
        }
    }

    // MARK: - Public Authentication API
    
    func signInWithEmail(email: String, password: String) async throws -> User {
        isLoading = true
        lastError = nil
        
        do {
            let user = try await FirebaseService.shared.signIn(email: email, password: password)
            currentUser = user
            isLoading = false
            print("✅ Email sign in successful: \(user.displayName)")
            
            // Notify AppState of user change
            NotificationCenter.default.post(
                name: NSNotification.Name("AuthServiceUserChanged"),
                object: user
            )
            
            return user
        } catch {
            isLoading = false
            lastError = mapFirebaseError(error)
            print("❌ Email sign in failed: \(error)")
            throw lastError!
        }
    }
    
    func signUpWithEmail(email: String, password: String, displayName: String) async throws -> User {
        isLoading = true
        lastError = nil
        
        do {
            let user = try await FirebaseService.shared.signUp(email: email, password: password, displayName: displayName)
            currentUser = user
            isLoading = false
            print("✅ Email sign up successful: \(user.displayName)")
            
            // Notify AppState of user change
            NotificationCenter.default.post(
                name: NSNotification.Name("AuthServiceUserChanged"),
                object: user
            )
            
            return user
        } catch {
            isLoading = false
            lastError = mapFirebaseError(error)
            print("❌ Email sign up failed: \(error)")
            throw lastError!
        }
    }

    func signInWithApple() async throws -> User {
        isLoading = true
        lastError = nil
        
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

    func signOut() async throws {
        isLoading = true
        
        do {
            try await FirebaseService.shared.signOut()
            currentUser = nil
            KeychainHelper.delete(userIdentifierKey)
            isLoading = false
            print("✅ Sign out successful")
            
            // Notify AppState of sign out
            NotificationCenter.default.post(
                name: NSNotification.Name("AuthServiceUserChanged"),
                object: nil
            )
        } catch {
            isLoading = false
            lastError = .unknown
            print("❌ Sign out failed: \(error)")
            throw lastError!
        }
    }
    
    func createGuestUser() -> User {
        let guestUser = User(
            email: "guest@localhost", 
            password: "", 
            displayName: "Guest Player",
            elo: 1000, 
            xp: 0, 
            totalMatches: 0, 
            wins: 0, 
            losses: 0, 
            winStreak: 0
        )
        currentUser = guestUser
        print("👤 Created guest user")
        
        // Notify AppState of user change
        NotificationCenter.default.post(
            name: NSNotification.Name("AuthServiceUserChanged"),
            object: guestUser
        )
        
        return guestUser
    }

    // MARK: - Internal
    private func restorePreviousSignIn() async {
        // Check if Firebase user exists first (takes priority)
        if let firebaseUser = Auth.auth().currentUser {
            print("🔥 Found existing Firebase user: \(firebaseUser.uid)")
            await handleFirebaseUserSignIn(firebaseUser)
            return
        }
        
        // Check for stored Apple Sign In credentials
        if let data = try? KeychainHelper.load(for: userIdentifierKey),
           let identifier = String(data: data, encoding: .utf8) {
            do {
                let credential = try await ASAuthorizationAppleIDProvider().credentialState(forUserID: identifier)
                if credential == .authorized {
                    // Try to get user from Firebase using the Apple ID
                    do {
                        // Look up user in Firebase by email/identifier
                        let users = try await FirebaseService.shared.getGlobalLeaderboard(limit: 1000)
                        if let existingUser = users.first(where: { $0.email.contains(identifier) || $0.id.uuidString == identifier }) {
                            currentUser = existingUser
                            print("✅ Restored Firebase user from Apple Sign In: \(existingUser.displayName)")
                        } else {
                            print("⚠️ No Firebase user found for Apple ID, user needs to sign in again")
                        }
                    } catch {
                        print("⚠️ Failed to fetch Firebase user for Apple ID: \(error)")
                    }
                }
            } catch {
                print("⚠️ Failed to restore Apple Sign In: \(error)")
            }
        }
    }

    private func fetchUser(byIdentifier id: String) -> User? {
        let descriptor = FetchDescriptor<User>()
        let users = (try? modelContext.fetch(descriptor)) ?? []
        return users.first { $0.email == id }
    }
    
    private func mapFirebaseError(_ error: Error) -> AuthError {
        if let authError = error as? AuthErrorCode {
            switch authError.code {
            case .emailAlreadyInUse:
                return .emailInUse
            case .weakPassword:
                return .weakPassword
            case .invalidEmail:
                return .invalidEmail
            case .userNotFound:
                return .invalidUser
            case .networkError:
                return .network
            default:
                return .unknown
            }
        }
        return .unknown
    }

    // Continuation storage for Apple Sign In
    private var continuation: CheckedContinuation<User, Error>? = nil
}

// MARK: - ASAuthorizationControllerDelegate & Presentation
extension AuthService: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: AuthError.unknown)
            return
        }
        
        Task {
            do {
                isLoading = true
                let userId = appleIDCredential.user
                
                // Save identifier to keychain
                try? KeychainHelper.save(Data(userId.utf8), for: userIdentifierKey)

                // Create Firebase credential from Apple ID
                guard let appleIDToken = appleIDCredential.identityToken,
                      let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    throw AuthError.unknown
                }
                
                let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                        idToken: idTokenString,
                                                        rawNonce: "")
                
                // Sign in to Firebase with Apple credential
                let authResult = try await Auth.auth().signIn(with: credential)
                
                // Create or get user profile from Firestore
                let email = appleIDCredential.email ?? authResult.user.email ?? "user_\(userId)@apple.com"
                let displayName = appleIDCredential.fullName?.givenName ?? authResult.user.displayName ?? "Apple User"
                
                let user: User
                if let existing = try? await FirebaseService.shared.getUser(id: authResult.user.uid) {
                    user = existing
                } else {
                    user = User(
                        email: email,
                        password: "", // Firebase handles auth
                        displayName: displayName,
                        elo: 1000,
                        xp: 0,
                        totalMatches: 0,
                        wins: 0,
                        losses: 0,
                        winStreak: 0
                    )
                    try await FirebaseService.shared.createUser(user)
                }
                
                currentUser = user
                isLoading = false
                
                continuation?.resume(returning: user)
                print("✅ Apple Sign In successful: \(user.displayName)")
                
                // Notify AppState of user change
                NotificationCenter.default.post(
                    name: NSNotification.Name("AuthServiceUserChanged"),
                    object: user
                )
                
            } catch {
                isLoading = false
                lastError = .unknown
                continuation?.resume(throwing: error)
                print("❌ Apple Sign In failed: \(error)")
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        isLoading = false
        
        if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
            lastError = .cancelled
            continuation?.resume(throwing: AuthError.cancelled)
        } else {
            lastError = .unknown
            continuation?.resume(throwing: AuthError.unknown)
        }
        print("❌ Apple Sign In error: \(error)")
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

 