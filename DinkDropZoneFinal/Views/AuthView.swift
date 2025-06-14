import SwiftUI
import AuthenticationServices
import Observation

struct AuthView: View {
    @Environment(AppState.self) private var appState
    @Environment(\._openURL) private var openURL
    @Environment(\.modelContext) private var modelContext
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingEmailAuth = false
    @State private var currentPage = 0
    @State private var animateElements = false

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
        ZStack {
            // Dynamic background
            DynamicAuthBackground()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Hero section with animated elements
                    HeroSection(animateElements: $animateElements)
                        .frame(height: UIScreen.main.bounds.height * 0.6)
                    
                    // Authentication options
                    AuthenticationSection(
                        isLoading: $isLoading,
                        errorMessage: $errorMessage,
                        showingEmailAuth: $showingEmailAuth,
                        onAppleSignIn: { handle(result: $0) },
                        onGuestContinue: { appState.updateUser(guestUser()) }
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                animateElements = true
            }
        }
        .sheet(isPresented: $showingEmailAuth) {
            EmailAuthView()
        }
    }

    private func handle(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(_):
            Task {
                do {
                    isLoading = true
                    if authService.currentUser == nil {
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

// MARK: - Hero Section

struct HeroSection: View {
    @Binding var animateElements: Bool
    @State private var logoRotation: Double = 0
    @State private var floatingOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Animated logo with floating effect
            ZStack {
                // Glow rings
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 140 + CGFloat(index * 20))
                        .scaleEffect(animateElements ? 1.0 : 0.5)
                        .opacity(animateElements ? 0.6 : 0)
                        .animation(.easeOut(duration: 1.0).delay(Double(index) * 0.2), value: animateElements)
                }
                
                // Main logo
                Image(systemName: "figure.pickleball")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .blue.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(logoRotation))
                    .offset(y: floatingOffset)
                    .shadow(color: .blue.opacity(0.5), radius: 15, x: 0, y: 8)
                    .scaleEffect(animateElements ? 1.0 : 0.3)
                    .opacity(animateElements ? 1.0 : 0)
            }
            .onAppear {
                // Continuous floating animation
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                    floatingOffset = -10
                }
                // Slow rotation
                withAnimation(.linear(duration: 20.0).repeatForever(autoreverses: false)) {
                    logoRotation = 360
                }
            }
            
            // Title with typewriter effect
            VStack(spacing: 12) {
                TypewriterText(
                    text: "DinkDropZone",
                    font: .system(size: 42, weight: .bold, design: .rounded),
                    startAnimation: animateElements
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .blue.opacity(0.9)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                
                Text("Where Champions Are Made")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(animateElements ? 1.0 : 0)
                    .animation(.easeOut(duration: 0.8).delay(1.5), value: animateElements)
            }
            
            Spacer()
        }
    }
}

// MARK: - Authentication Section

struct AuthenticationSection: View {
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?
    @Binding var showingEmailAuth: Bool
    let onAppleSignIn: (Result<ASAuthorization, Error>) -> Void
    let onGuestContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Welcome text
            VStack(spacing: 8) {
                Text("Join the Community")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text("Connect with players, track your progress, and elevate your game")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.bottom, 10)
            
            // Sign in with Apple
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: onAppleSignIn
            .signInWithAppleButtonStyle(.whiteOutline)
            .frame(height: 50)
            .cornerRadius(25)
            .disabled(isLoading)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            // Email sign in button
            Button {
                showingEmailAuth = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("Continue with Email")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .cornerRadius(25)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            .disabled(isLoading)
            
            // Divider
            HStack {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 1)
                Text("or")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.vertical, 8)
            
            // Guest continue
            Button {
                onGuestContinue()
            } label: {
                Text("Continue as Guest")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(25)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            }
            .disabled(isLoading)
            
            // Error message
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Loading indicator
            if isLoading {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
                    .padding(.top, 10)
            }
        }
    }
}

// MARK: - Supporting Views

struct DynamicAuthBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: animateGradient ?
                    [Color.blue.opacity(0.9), Color.purple.opacity(0.7), Color.blue.opacity(0.8)] :
                    [Color.purple.opacity(0.8), Color.blue.opacity(0.8), Color.purple.opacity(0.9)],
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            
            // Overlay pattern
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    
                    path.move(to: CGPoint(x: 0, y: height * 0.7))
                    path.addCurve(
                        to: CGPoint(x: width, y: height * 0.5),
                        control1: CGPoint(x: width * 0.3, y: height * 0.8),
                        control2: CGPoint(x: width * 0.7, y: height * 0.3)
                    )
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.1), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

struct TypewriterText: View {
    let text: String
    let font: Font
    let startAnimation: Bool
    @State private var displayedText = ""
    
    var body: some View {
        Text(displayedText)
            .font(font)
            .onChange(of: startAnimation) { _, newValue in
                if newValue {
                    typeWriter()
                }
            }
    }
    
    private func typeWriter() {
        displayedText = ""
        for (index, character) in text.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                displayedText += String(character)
            }
        }
    }
}

#Preview {
    AuthView()
        .environment(AppState())
} 