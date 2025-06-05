import Foundation
import CryptoKit
import SwiftData

enum AuthError: Error, LocalizedError {
    case alreadyExists
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .alreadyExists: return "User already exists"
        case .invalidCredentials: return "Invalid email/password"
        }
    }
}

protocol AuthProvider: Sendable {
    func signUp(email: String, password: String) async throws -> User
    func signIn(email: String, password: String) async throws -> User
}

actor LocalAuthProvider: AuthProvider {
    private var keychain: [String: String] = [:] // email : hashedPassword (stub)
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    private func hash(_ password: String) -> String {
        let digest = SHA256.hash(data: Data(password.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    func signUp(email: String, password: String) async throws -> User {
        guard keychain[email] == nil else { throw AuthError.alreadyExists }
        let hashed = hash(password)
        keychain[email] = hashed

        let user = User(email: email)
        context.insert(user)
        try context.save()
        return user
    }

    func signIn(email: String, password: String) async throws -> User {
        guard let stored = keychain[email], stored == hash(password) else {
            throw AuthError.invalidCredentials
        }

        let fetch = FetchDescriptor<User>(predicate: #Predicate { $0.email == email })
        if let user = try? context.fetch(fetch).first {
            return user
        }
        // Should never reach here, but create if missing
        let newUser = User(email: email)
        context.insert(newUser)
        try context.save()
        return newUser
    }
} 