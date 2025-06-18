//
//  OnboardingView.swift
//  DinkDropZoneFinal
//
//  Created by Assistant on 2025-06-13.
//

import SwiftUI
import CoreLocationUI

struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    @State private var currentPage = 0
    @State private var selectedSkillLevel: SkillLevel = .beginner
    @State private var selectedPlayStyle: PlayStyle = .balanced
    @State private var selectedAvatar = "person.circle.fill"
    @State private var displayName = ""
    @State private var city = ""
    @State private var homeCourt = ""
    @State private var showConfetti = false
    
    let totalPages = 7
    
    var body: some View {
        ZStack {
            // Dynamic background that changes per page
            OnboardingGradientBackground(page: currentPage)
            
            TabView(selection: $currentPage) {
                // Page 1: Welcome
                WelcomePage()
                    .tag(0)
                
                // Page 2: Display Name
                DisplayNamePage(displayName: $displayName)
                    .tag(1)
                
                // Page 3: City/Location
                CityPage(city: $city)
                    .tag(2)
                
                // Page 4: Home Court
                HomeCourtPage(homeCourt: $homeCourt)
                    .tag(3)
                
                // Page 5: Skill Level
                SkillLevelPage(selectedSkillLevel: $selectedSkillLevel)
                    .tag(4)
                
                // Page 6: Play Style
                PlayStylePage(selectedPlayStyle: $selectedPlayStyle)
                    .tag(5)
                
                // Page 7: Avatar Selection
                AvatarSelectionPage(selectedAvatar: $selectedAvatar)
                    .tag(6)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Custom page indicators
            VStack {
                Spacer()
                
                HStack(spacing: 12) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: index == currentPage ? 30 : 8, height: 8)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentPage)
                    }
                }
                .padding(.bottom, 100)
            }
            
            // Navigation buttons
            VStack {
                Spacer()
                
                HStack {
                    if currentPage > 0 {
                        Button("Back") {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                currentPage -= 1
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(25)
                    }
                    
                    Spacer()
                    
                    Button(currentPage == totalPages - 1 ? "Complete Setup!" : "Next") {
                        if currentPage == totalPages - 1 {
                            completeOnboarding()
                        } else {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    .disabled(!isCurrentPageValid)
                    .opacity(isCurrentPageValid ? 1.0 : 0.6)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
            
            // Confetti overlay
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
    }
    
    private var isCurrentPageValid: Bool {
        switch currentPage {
        case 1: return !displayName.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return !city.trimmingCharacters(in: .whitespaces).isEmpty
        case 3: return !homeCourt.trimmingCharacters(in: .whitespaces).isEmpty
        default: return true
        }
    }
    
    private func completeOnboarding() {
        showConfetti = true
        
        // Save user preferences to AppState or UserDefaults
        saveUserPreferences()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                isOnboardingComplete = true
            }
        }
    }
    
    private func saveUserPreferences() {
        // Save to UserDefaults for now - in a real app you'd save to your user model
        UserDefaults.standard.set(displayName, forKey: "userDisplayName")
        UserDefaults.standard.set(city, forKey: "userCity")
        UserDefaults.standard.set(homeCourt, forKey: "userHomeCourt")
        UserDefaults.standard.set(selectedSkillLevel.rawValue, forKey: "userSkillLevel")
        UserDefaults.standard.set(selectedPlayStyle.rawValue, forKey: "userPlayStyle")
        UserDefaults.standard.set(selectedAvatar, forKey: "userAvatar")
    }
}

// MARK: - Individual Pages

struct WelcomePage: View {
    @State private var animateTitle = false
    @State private var animateSubtitle = false
    @State private var animateFeatures = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Logo and title
            VStack(spacing: 20) {
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .scaleEffect(animateTitle ? 1.0 : 0.5)
                    .opacity(animateTitle ? 1.0 : 0.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animateTitle)
                
                Text("Welcome to DinkDropZone!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(animateTitle ? 1.0 : 0.0)
                    .offset(y: animateTitle ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: animateTitle)
                
                Text("Your ultimate pickleball companion")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .opacity(animateSubtitle ? 1.0 : 0.0)
                    .offset(y: animateSubtitle ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6), value: animateSubtitle)
            }
            
            // Feature highlights
            VStack(spacing: 20) {
                FeatureHighlight(
                    icon: "person.2.fill",
                    title: "Find Players",
                    description: "Connect with players at your skill level",
                    color: .blue
                )
                .opacity(animateFeatures ? 1.0 : 0.0)
                .offset(x: animateFeatures ? 0 : -50)
                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.8), value: animateFeatures)
                
                FeatureHighlight(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Track Progress",
                    description: "Monitor your improvement and stats",
                    color: .green
                )
                .opacity(animateFeatures ? 1.0 : 0.0)
                .offset(x: animateFeatures ? 0 : 50)
                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(1.0), value: animateFeatures)
                
                FeatureHighlight(
                    icon: "trophy.fill",
                    title: "Compete",
                    description: "Join tournaments and climb the leaderboard",
                    color: .orange
                )
                .opacity(animateFeatures ? 1.0 : 0.0)
                .offset(x: animateFeatures ? 0 : -50)
                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(1.2), value: animateFeatures)
            }
            
            Spacer()
        }
        .padding(.horizontal, 30)
        .onAppear {
            animateTitle = true
            animateSubtitle = true
            animateFeatures = true
        }
    }
}

struct DisplayNamePage: View {
    @Binding var displayName: String
    @State private var animateElements = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "person.badge.plus.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .scaleEffect(animateElements ? 1.0 : 0.5)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animateElements)
                
                VStack(spacing: 15) {
                    Text("What should we call you?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Choose a display name that other players will see")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .opacity(animateElements ? 1.0 : 0.0)
                .offset(y: animateElements ? 0 : 20)
                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: animateElements)
            }
            
            // Custom text field
            VStack(spacing: 10) {
                TextField("Enter your display name", text: $displayName)
                    .font(.title2)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .focused($isTextFieldFocused)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .scaleEffect(animateElements ? 1.0 : 0.8)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6), value: animateElements)
                
                if !displayName.isEmpty {
                    Text("Looking good, \(displayName)! 👋")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .onAppear {
            animateElements = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                isTextFieldFocused = true
            }
        }
    }
}

struct CityPage: View {
    @Binding var city: String
    @State private var animateElements = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .scaleEffect(animateElements ? 1.0 : 0.5)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animateElements)
                
                VStack(spacing: 15) {
                    Text("Where do you play?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Tell us your city so we can find nearby players and courts")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .opacity(animateElements ? 1.0 : 0.0)
                .offset(y: animateElements ? 0 : 20)
                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: animateElements)
            }
            
            // Custom text field
            VStack(spacing: 10) {
                TextField("Enter your city", text: $city)
                    .font(.title2)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .focused($isTextFieldFocused)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .scaleEffect(animateElements ? 1.0 : 0.8)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6), value: animateElements)
                
                if !city.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Great! We'll find players near \(city)")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .onAppear {
            animateElements = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                isTextFieldFocused = true
            }
        }
    }
}

struct HomeCourtPage: View {
    @Binding var homeCourt: String
    @State private var animateElements = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "house.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .scaleEffect(animateElements ? 1.0 : 0.5)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animateElements)
                
                VStack(spacing: 15) {
                    Text("What's your home court?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Where do you usually play? This helps us suggest nearby matches")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .opacity(animateElements ? 1.0 : 0.0)
                .offset(y: animateElements ? 0 : 20)
                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: animateElements)
            }
            
            // Custom text field
            VStack(spacing: 10) {
                TextField("Enter your home court or club", text: $homeCourt)
                    .font(.title2)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .focused($isTextFieldFocused)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .scaleEffect(animateElements ? 1.0 : 0.8)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6), value: animateElements)
                
                if !homeCourt.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.blue)
                        Text("Perfect! We'll prioritize matches at \(homeCourt)")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .onAppear {
            animateElements = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                isTextFieldFocused = true
            }
        }
    }
}

struct SkillLevelPage: View {
    @Binding var selectedSkillLevel: SkillLevel
    @State private var animateCards = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 15) {
                Text("What's your skill level?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Help us match you with the right players")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 30)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(SkillLevel.allCases, id: \.self) { level in
                    SkillLevelCard(
                        level: level,
                        isSelected: selectedSkillLevel == level
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedSkillLevel = level
                        }
                    }
                    .scaleEffect(animateCards ? 1.0 : 0.8)
                    .opacity(animateCards ? 1.0 : 0.0)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.8)
                        .delay(Double(SkillLevel.allCases.firstIndex(of: level) ?? 0) * 0.1),
                        value: animateCards
                    )
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .onAppear {
            animateCards = true
        }
    }
}

struct PlayStylePage: View {
    @Binding var selectedPlayStyle: PlayStyle
    @State private var animateCards = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 15) {
                Text("What's your play style?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("This helps us understand your game")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 30)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(PlayStyle.allCases, id: \.self) { style in
                    PlayStyleCard(
                        style: style,
                        isSelected: selectedPlayStyle == style
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedPlayStyle = style
                        }
                    }
                    .scaleEffect(animateCards ? 1.0 : 0.8)
                    .opacity(animateCards ? 1.0 : 0.0)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.8)
                        .delay(Double(PlayStyle.allCases.firstIndex(of: style) ?? 0) * 0.1),
                        value: animateCards
                    )
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .onAppear {
            animateCards = true
        }
    }
}

struct AvatarSelectionPage: View {
    @Binding var selectedAvatar: String
    @State private var animateAvatars = false
    
    let avatarOptions = [
        "person.circle.fill",
        "person.crop.circle.fill",
        "figure.walk",
        "figure.run",
        "sportscourt.fill",
        "tennis.racket"
    ]
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 15) {
                Text("Choose your avatar")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Pick an icon that represents you")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                ForEach(avatarOptions, id: \.self) { avatar in
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedAvatar = avatar
                        }
                    }) {
                        Image(systemName: avatar)
                            .font(.system(size: 40))
                            .foregroundColor(selectedAvatar == avatar ? .blue : .white)
                            .frame(width: 80, height: 80)
                            .background(
                                Circle()
                                    .fill(selectedAvatar == avatar ? Color.white : Color.white.opacity(0.2))
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                selectedAvatar == avatar ? Color.blue : Color.clear,
                                                lineWidth: 3
                                            )
                                    )
                            )
                            .scaleEffect(selectedAvatar == avatar ? 1.1 : 1.0)
                            .shadow(
                                color: selectedAvatar == avatar ? .blue.opacity(0.5) : .clear,
                                radius: 10,
                                x: 0,
                                y: 5
                            )
                    }
                    .scaleEffect(animateAvatars ? 1.0 : 0.5)
                    .opacity(animateAvatars ? 1.0 : 0.0)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.8)
                        .delay(Double(avatarOptions.firstIndex(of: avatar) ?? 0) * 0.1),
                        value: animateAvatars
                    )
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .onAppear {
            animateAvatars = true
        }
    }
}

// MARK: - Supporting Views

struct SkillLevelCard: View {
    let level: SkillLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(level.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .blue : .white)
                
                Text(level.description)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue.opacity(0.8) : .white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? Color.white : Color.white.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(
                                isSelected ? Color.blue : Color.white.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .shadow(
                color: isSelected ? .blue.opacity(0.3) : .clear,
                radius: 10,
                x: 0,
                y: 5
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct PlayStyleCard: View {
    let style: PlayStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(style.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .blue : .white)
                
                Text(style.description)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue.opacity(0.8) : .white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? Color.white : Color.white.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(
                                isSelected ? Color.blue : Color.white.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .shadow(
                color: isSelected ? .blue.opacity(0.3) : .clear,
                radius: 10,
                x: 0,
                y: 5
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct OnboardingGradientBackground: View {
    let page: Int
    @State private var animateGradient = false
    
    var gradientColors: [Color] {
        switch page {
        case 0: return [.blue, .purple, .pink]
        case 1: return [.green, .blue, .teal]
        case 2: return [.orange, .red, .pink]
        case 3: return [.purple, .blue, .indigo]
        case 4: return [.cyan, .blue, .purple]
        case 5: return [.mint, .green, .blue]
        case 6: return [.pink, .purple, .blue]
        default: return [.blue, .purple, .pink]
        }
    }
    
    var body: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
        .onChange(of: page) { _ in
            withAnimation(.easeInOut(duration: 0.8)) {
                animateGradient.toggle()
            }
        }
    }
}

struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<50, id: \.self) { index in
                Circle()
                    .fill(Color.random)
                    .frame(width: CGFloat.random(in: 4...12))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: animate ? UIScreen.main.bounds.height + 100 : -100
                    )
                    .animation(
                        .linear(duration: Double.random(in: 2...4))
                        .delay(Double.random(in: 0...2))
                        .repeatForever(autoreverses: false),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

extension Color {
    static var random: Color {
        return Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
}
