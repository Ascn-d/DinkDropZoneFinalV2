import SwiftUI
import AuthenticationServices
import Observation

struct AuthView: View {
    @Environment(AppState.self) private var appState
    @Environment(\._openURL) private var openURL
    @Environment(\.modelContext) private var modelContext
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var authService: AuthService {
        if let existing = appState.authService {
            return existing
        } else {
            let service = AuthService(modelContext: modelContext)
            appState.authService = service
            return service
        }
    }

    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            Text("DinkDrop")
                .font(.largeTitle.bold())
            Text("Sign in to level-up your pickleball journey")
                .foregroundColor(.secondary)
            Spacer()
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                handle(result: result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 45)
            .disabled(isLoading)
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            Button("Continue as Guest") {
                appState.updateUser(guestUser())
            }
            .foregroundColor(.blue)
            Spacer()
        }
        .padding()
    }

    private func handle(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(_):
            Task {
                do {
                    isLoading = true
                    if authService.currentUser == nil {
                        // AuthService delegate will set currentUser asynchronously
                        try await authService.signInWithApple()
                    }
                    if let user = authService.currentUser {
                        appState.updateUser(user)
                    }
                } catch {
                    errorMessage = error.localizedDescription
                }
                isLoading = false
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func guestUser() -> User {
        let user = User(email: "guest@localhost", password: "", elo: 1000, xp: 0, totalMatches: 0, wins: 0, losses: 0, winStreak: 0)
        user.displayName = "Guest"
        return user
    }
}

#Preview {
    AuthView()
        .environment(AppState())
} 