import SwiftUI
import Observation

struct WelcomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\._openURL) private var openURL
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var error: String?
    @State private var isLoading = false
    @State private var isAnimating = false
    @State private var isEmailValid = false
    @State private var isPasswordValid = false
    @State private var showPassword = false
    @State private var buttonScale: CGFloat = 1.0
    @Environment(\.modelContext) private var context

    // Game-like colors
    private let gameColors = [
        Color(red: 0.2, green: 0.5, blue: 0.9),  // Electric Blue
        Color(red: 0.6, green: 0.2, blue: 0.9),  // Neon Purple
        Color(red: 0.9, green: 0.4, blue: 0.2),  // Fire Orange
        Color(red: 0.2, green: 0.8, blue: 0.6)   // Cyber Green
    ]

    var body: some View {
        ZStack {
            // Animated background
            LinearGradient(
                colors: [gameColors[0].opacity(0.3), gameColors[1].opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated particles
            ForEach(0..<20) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [gameColors[index % gameColors.count].opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: CGFloat.random(in: 10...30))
                    .offset(
                        x: isAnimating ? CGFloat.random(in: -200...200) : CGFloat.random(in: -200...200),
                        y: isAnimating ? CGFloat.random(in: -400...400) : CGFloat.random(in: -400...400)
                    )
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 2...4))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.1),
                        value: isAnimating
                    )
            }

            // Main content
            VStack(spacing: 30) {
                // Logo and Title
                VStack(spacing: 10) {
                    // Animated game controller
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [gameColors[0], gameColors[1]],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .shadow(color: gameColors[0].opacity(0.5), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.white)
                            .symbolEffect(.bounce, options: .repeating)
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                            .animation(
                                Animation.linear(duration: 20)
                                    .repeatForever(autoreverses: false),
                                value: isAnimating
                            )
                    }
                    .padding(.bottom, 10)
                    
                    Text("DinkDrop")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gameColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: gameColors[0].opacity(0.3), radius: 5, x: 0, y: 2)
                    
                    Text("Level Up Your Game")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .opacity(isAnimating ? 1 : 0)
                        .animation(.easeIn(duration: 1).delay(0.5), value: isAnimating)
                }
                .padding(.top, 50)

                // Login Form
                VStack(spacing: 20) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Email")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            if !email.isEmpty {
                                Image(systemName: isEmailValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(isEmailValid ? .green : .red)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        TextField("", text: $email)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isEmailValid ? Color.green : gameColors[0].opacity(0.3), lineWidth: 1)
                            )
                            .onChange(of: email) { _, newValue in
                                withAnimation {
                                    isEmailValid = newValue.contains("@") && newValue.contains(".")
                                }
                            }
                    }

                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Password")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            if !password.isEmpty {
                                Image(systemName: isPasswordValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(isPasswordValid ? .green : .red)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        HStack {
                            if showPassword {
                                TextField("", text: $password)
                            } else {
                                SecureField("", text: $password)
                            }
                            Button {
                                withAnimation {
                                    showPassword.toggle()
                                }
                            } label: {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isPasswordValid ? Color.green : gameColors[0].opacity(0.3), lineWidth: 1)
                        )
                        .onChange(of: password) { _, newValue in
                            withAnimation {
                                isPasswordValid = newValue.count >= 6
                            }
                        }
                    }

                    if let error {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.callout)
                            .padding(.top, 5)
                            .transition(.scale.combined(with: .opacity))
                    }

                    // Sign in button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            buttonScale = 0.95
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                buttonScale = 1.0
                            }
                        }
                        Task { await handleAuth() }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isLoading ? "Signing In..." : "Start Your Journey")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [gameColors[0], gameColors[1]],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: gameColors[0].opacity(0.3), radius: 5, x: 0, y: 3)
                        .scaleEffect(buttonScale)
                    }
                    .disabled(isLoading || !isEmailValid || !isPasswordValid)
                    .opacity(isLoading || !isEmailValid || !isPasswordValid ? 0.6 : 1)
                }
                .padding(.horizontal, 30)
                .padding(.top, 30)

                Spacer()
            }
        }
        .onAppear {
            isAnimating = true
        }
    }

    private func handleAuth() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let auth = LocalAuthProvider(context: context)
            let user: User
            
            // Try to sign in first
            if let signedInUser = try? await auth.signIn(email: email, password: password) {
                user = signedInUser
            } else {
                // If sign in fails, try to sign up
                user = try await auth.signUp(email: email, password: password)
            }
            
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