import SwiftUI
import Observation

struct WelcomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\._openURL) private var openURL
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var error: String?
    @State private var isLoading = false
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            Form {
                Section("Credentials") {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("Password", text: $password)
                }

                if let error {
                    Text(error)
                        .foregroundColor(.red)
                }

                Button(isLoading ? "Signing In…" : "Sign In / Sign Up") {
                    Task { await handleAuth() }
                }
                .disabled(isLoading || email.isEmpty || password.isEmpty)
            }
            .navigationTitle("Welcome")
        }
    }

    private func handleAuth() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let auth = LocalAuthProvider(context: context)
            let user = (try? await auth.signIn(email: email, password: password)) ?? (try await auth.signUp(email: email, password: password))
            appState.currentUser = user
        } catch {
            self.error = error.localizedDescription
        }
    }
}

#Preview {
    WelcomeView()
        .environment(AppState())
} 