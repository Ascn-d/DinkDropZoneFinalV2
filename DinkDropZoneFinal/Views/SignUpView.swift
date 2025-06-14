import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Logo and Title
                    VStack(spacing: 8) {
                        Image(systemName: "figure.pickleball")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                        Text("Join DinkDropZone")
                            .font(.title2.bold())
                    }
                    .padding(.top, 40)
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        // Display Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Display Name")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextField("Enter your name", text: $displayName)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.name)
                                .autocapitalization(.words)
                        }
                        
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
                                .textContentType(.newPassword)
                        }
                        
                        // Confirm Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            SecureField("Confirm your password", text: $confirmPassword)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.newPassword)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Sign Up Button
                    Button {
                        Task {
                            await signUp()
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Create Account")
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
                    
                    // Terms and Privacy
                    Text("By signing up, you agree to our Terms of Service and Privacy Policy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    // Sign In Link
                    HStack {
                        Text("Already have an account?")
                            .foregroundStyle(.secondary)
                        Button("Sign In") {
                            dismiss()
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
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        !displayName.isEmpty &&
        password == confirmPassword &&
        password.count >= 6 &&
        email.contains("@")
    }
    
    private func signUp() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Create Firebase Auth user
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Create user profile in Firestore
            let user = User(
                id: UUID(), // Generate new UUID for SwiftData
                email: email,
                password: password,
                displayName: displayName,
                skillLevel: "Beginner",
                elo: 1000,
                wins: 0,
                losses: 0
            )
            
            try await FirebaseService.shared.createUser(user)
            
            // Update app state
            appState.currentUser = user
            
            // Dismiss the view
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

#Preview {
    SignUpView()
        .modelContainer(for: [User.self])
} 