import SwiftUI
import FirebaseAuth

struct WelcomeView: View {
    @Environment(AppState.self) private var appState
    @State private var email = ""
    @State private var password = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showingSignUp = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Logo and Title
                    VStack(spacing: 8) {
                        Image(systemName: "figure.pickleball")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                        Text("Welcome to DinkDropZone")
                            .font(.title2.bold())
                    }
                    .padding(.top, 40)
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        
                        // Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.password)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Sign In Button
                    Button {
                        Task {
                            await signIn()
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Sign In")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .disabled(isLoading || !isFormValid)
                    
                    // Sign Up Link
                    HStack {
                        Text("Don't have an account?")
                            .foregroundStyle(.secondary)
                        Button("Sign Up") {
                            showingSignUp = true
                        }
                        .foregroundStyle(.blue)
                    }
                    .font(.subheadline)
                }
                .padding()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    private func signIn() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let user = try await FirebaseService.shared.signIn(email: email, password: password)
            appState.currentUser = user
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

#Preview {
    WelcomeView()
        .modelContainer(for: [User.self])
} 