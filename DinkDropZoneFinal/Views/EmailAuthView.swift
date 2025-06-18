import SwiftUI
import FirebaseAuth

struct EmailAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var animateForm = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 16) {
                            // Logo
                            Image(systemName: "figure.pickleball")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .scaleEffect(animateForm ? 1.0 : 0.8)
                                .opacity(animateForm ? 1.0 : 0)
                            
                            VStack(spacing: 8) {
                                Text(isSignUp ? "Create Account" : "Welcome Back")
                                    .font(.title.bold())
                                    .foregroundColor(.primary)
                                
                                Text(isSignUp ? "Join the DinkDropZone community" : "Sign in to your account")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .opacity(animateForm ? 1.0 : 0)
                            .offset(y: animateForm ? 0 : 20)
                        }
                        .padding(.top, 20)
                        
                        // Form
                        VStack(spacing: 20) {
                            // Full Name (Sign Up only)
                            if isSignUp {
                                CustomTextField(
                                    title: "Full Name",
                                    text: $fullName,
                                    icon: "person.fill",
                                    placeholder: "Enter your full name"
                                )
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                            }
                            
                            // Email
                            CustomTextField(
                                title: "Email",
                                text: $email,
                                icon: "envelope.fill",
                                placeholder: "Enter your email",
                                keyboardType: .emailAddress,
                                textContentType: .emailAddress
                            )
                            
                            // Password
                            CustomSecureField(
                                title: "Password",
                                text: $password,
                                showPassword: $showPassword,
                                placeholder: "Enter your password"
                            )
                            
                            // Confirm Password (Sign Up only)
                            if isSignUp {
                                CustomSecureField(
                                    title: "Confirm Password",
                                    text: $confirmPassword,
                                    showPassword: $showConfirmPassword,
                                    placeholder: "Confirm your password"
                                )
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                            }
                        }
                        .opacity(animateForm ? 1.0 : 0)
                        .offset(y: animateForm ? 0 : 30)
                        
                        // Action Button
                        Button {
                            Task {
                                await handleAuthentication()
                            }
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.9)
                                } else {
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(25)
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isLoading || !isFormValid)
                        .opacity(isFormValid ? 1.0 : 0.6)
                        .scaleEffect(animateForm ? 1.0 : 0.9)
                        
                        // Toggle Sign Up/Sign In
                        Button {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                isSignUp.toggle()
                                // Clear form when switching
                                if isSignUp {
                                    confirmPassword = ""
                                    fullName = ""
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                    .foregroundColor(.secondary)
                                Text(isSignUp ? "Sign In" : "Sign Up")
                                    .foregroundColor(.blue)
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                        }
                        .opacity(animateForm ? 1.0 : 0)
                        
                        // Error Message
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                                .transition(.scale.combined(with: .opacity))
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                animateForm = true
            }
        }
    }
    
    private var isFormValid: Bool {
        let emailValid = email.contains("@") && !email.isEmpty
        let passwordValid = password.count >= 6
        
        if isSignUp {
            let nameValid = !fullName.trimmingCharacters(in: .whitespaces).isEmpty
            let passwordsMatch = password == confirmPassword
            return emailValid && passwordValid && nameValid && passwordsMatch
        } else {
            return emailValid && passwordValid
        }
    }
    
    private func handleAuthentication() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if isSignUp {
                // Create account
                let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
                
                // Update display name
                let changeRequest = authResult.user.createProfileChangeRequest()
                changeRequest.displayName = fullName
                try await changeRequest.commitChanges()
                
                // Create user in your system
                let user = User(
                    email: email,
                    password: password,
                    elo: 1000,
                    xp: 0,
                    totalMatches: 0,
                    wins: 0,
                    losses: 0,
                    winStreak: 0
                )
                user.displayName = fullName
                
                appState.updateUser(user)
            } else {
                // Sign in
                try await Auth.auth().signIn(withEmail: email, password: password)
                
                // Create or fetch user
                let user = User(
                    email: email,
                    password: password,
                    elo: 1000,
                    xp: 0,
                    totalMatches: 0,
                    wins: 0,
                    losses: 0,
                    winStreak: 0
                )
                
                appState.updateUser(user)
            }
            
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Custom Form Components

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .autocapitalization(.none)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: text.isEmpty ? 0 : 1)
            )
        }
    }
}

struct CustomSecureField: View {
    let title: String
    @Binding var text: String
    @Binding var showPassword: Bool
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                Group {
                    if showPassword {
                        TextField(placeholder, text: $text)
                    } else {
                        SecureField(placeholder, text: $text)
                    }
                }
                .textFieldStyle(.plain)
                .textContentType(.password)
                
                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: text.isEmpty ? 0 : 1)
            )
        }
    }
}

#Preview {
    EmailAuthView()
        .environment(AppState())
} 