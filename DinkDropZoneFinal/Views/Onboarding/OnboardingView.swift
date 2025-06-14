//
//  OnboardingView.swift
//  DinkDropZoneFinal
//
//  Created by Assistant on 2025-06-13.
//

import SwiftUI
import CoreLocationUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @State private var currentPage = 0
    @State private var showConfetti = false
    @State private var selectedSkillLevel: SkillLevel = .beginner
    @State private var selectedPlayStyle: PlayStyle = .recreational
    @State private var selectedAvatar: String = "person.crop.circle.fill"
    @State private var animateElements = false
    
    private let totalPages = 4
    
    var body: some View {
        ZStack {
            // Dynamic background
            OnboardingBackground(currentPage: currentPage)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                ProgressIndicator(currentPage: currentPage, totalPages: totalPages)
                    .padding(.top, 60)
                    .padding(.horizontal, 24)
                
                // Page content
                TabView(selection: $currentPage) {
                    WelcomePage()
                        .tag(0)
                    SkillLevelPage(selectedSkillLevel: $selectedSkillLevel)
                        .tag(1)
                    PlayStylePage(selectedPlayStyle: $selectedPlayStyle)
                        .tag(2)
                    AvatarSelectionPage(selectedAvatar: $selectedAvatar)
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.5), value: currentPage)
                
                // Navigation buttons
                NavigationButtons(
                    currentPage: $currentPage,
                    totalPages: totalPages,
                    onFinish: finishOnboarding
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
            
            // Confetti overlay
            if showConfetti {
                EnhancedConfettiView()
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animateElements = true
            }
        }
    }
    
    private func finishOnboarding() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showConfetti = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                hasOnboarded = true
            }
        }
    }
}

// MARK: - Supporting Types

enum SkillLevel: String, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case pro = "Pro"
    
    var description: String {
        switch self {
        case .beginner: return "Just starting out"
        case .intermediate: return "Getting the hang of it"
        case .advanced: return "Competitive player"
        case .pro: return "Tournament level"
        }
    }
    
    var icon: String {
        switch self {
        case .beginner: return "figure.walk"
        case .intermediate: return "figure.run"
        case .advanced: return "figure.pickleball"
        case .pro: return "trophy.fill"
        }
    }
}

enum PlayStyle: String, CaseIterable {
    case recreational = "Recreational"
    case competitive = "Competitive"
    case social = "Social"
    case fitness = "Fitness"
    
    var description: String {
        switch self {
        case .recreational: return "Play for fun and relaxation"
        case .competitive: return "Love the thrill of competition"
        case .social: return "Meet new people and make friends"
        case .fitness: return "Stay active and healthy"
        }
    }
    
    var icon: String {
        switch self {
        case .recreational: return "sun.max.fill"
        case .competitive: return "flame.fill"
        case .social: return "person.3.fill"
        case .fitness: return "heart.fill"
        }
    }
}

// MARK: - Page Views

struct WelcomePage: View {
    @State private var animateTitle = false
    @State private var animateSubtitle = false
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Animated icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.blue.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(animateIcon ? 1.2 : 0.8)
                    .opacity(animateIcon ? 0.6 : 0)
                
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
                    .scaleEffect(animateIcon ? 1.0 : 0.5)
                    .opacity(animateIcon ? 1.0 : 0)
                    .shadow(color: .blue.opacity(0.5), radius: 15, x: 0, y: 8)
            }
            
            VStack(spacing: 16) {
                Text("Welcome to")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(animateTitle ? 1.0 : 0)
                    .offset(y: animateTitle ? 0 : 20)
                
                Text("DinkDropZone")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .blue.opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(animateTitle ? 1.0 : 0)
                    .offset(y: animateTitle ? 0 : 30)
                
                Text("Your journey to pickleball mastery starts here. Let's set up your profile and get you connected with the community.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .opacity(animateSubtitle ? 1.0 : 0)
                    .offset(y: animateSubtitle ? 0 : 20)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                animateIcon = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
                animateTitle = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(1.0)) {
                animateSubtitle = true
            }
        }
    }
}

struct SkillLevelPage: View {
    @Binding var selectedSkillLevel: SkillLevel
    @State private var animateCards = false
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("What's your skill level?")
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("This helps us match you with players of similar abilities")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            .padding(.top, 40)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                ForEach(SkillLevel.allCases, id: \.self) { level in
                    SkillLevelCard(
                        level: level,
                        isSelected: selectedSkillLevel == level,
                        onTap: { selectedSkillLevel = level }
                    )
                    .scaleEffect(animateCards ? 1.0 : 0.8)
                    .opacity(animateCards ? 1.0 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(SkillLevel.allCases.firstIndex(of: level) ?? 0) * 0.1), value: animateCards)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .onAppear {
            withAnimation {
                animateCards = true
            }
        }
    }
}

struct PlayStylePage: View {
    @Binding var selectedPlayStyle: PlayStyle
    @State private var animateCards = false
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("How do you like to play?")
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Choose your primary motivation for playing pickleball")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            .padding(.top, 40)
            
            VStack(spacing: 16) {
                ForEach(PlayStyle.allCases, id: \.self) { style in
                    PlayStyleCard(
                        style: style,
                        isSelected: selectedPlayStyle == style,
                        onTap: { selectedPlayStyle = style }
                    )
                    .scaleEffect(animateCards ? 1.0 : 0.8)
                    .opacity(animateCards ? 1.0 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(PlayStyle.allCases.firstIndex(of: style) ?? 0) * 0.1), value: animateCards)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .onAppear {
            withAnimation {
                animateCards = true
            }
        }
    }
}

struct AvatarSelectionPage: View {
    @Binding var selectedAvatar: String
    @State private var animateAvatars = false
    
    private let avatarOptions = [
        "person.crop.circle.fill",
        "person.crop.circle.badge.plus",
        "person.crop.circle.badge.checkmark",
        "person.crop.circle.badge.xmark",
        "person.crop.circle.badge.moon",
        "person.crop.circle.badge.clock"
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("Choose your avatar")
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Pick an avatar that represents you on the court")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            .padding(.top, 40)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3), spacing: 20) {
                ForEach(avatarOptions, id: \.self) { avatar in
                    AvatarOption(
                        systemName: avatar,
                        isSelected: selectedAvatar == avatar,
                        onTap: { selectedAvatar = avatar }
                    )
                    .scaleEffect(animateAvatars ? 1.0 : 0.5)
                    .opacity(animateAvatars ? 1.0 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(avatarOptions.firstIndex(of: avatar) ?? 0) * 0.1), value: animateAvatars)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .onAppear {
            withAnimation {
                animateAvatars = true
            }
        }
    }
}

// MARK: - Supporting Views

struct OnboardingBackground: View {
    let currentPage: Int
    @State private var animateGradient = false
    
    var body: some View {
        let colors = backgroundColors(for: currentPage)
        
        LinearGradient(
            colors: animateGradient ? colors.reversed() : colors,
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
        .animation(.easeInOut(duration: 0.8), value: currentPage)
    }
    
    private func backgroundColors(for page: Int) -> [Color] {
        switch page {
        case 0: return [Color.blue.opacity(0.8), Color.purple.opacity(0.6)]
        case 1: return [Color.green.opacity(0.8), Color.blue.opacity(0.6)]
        case 2: return [Color.orange.opacity(0.8), Color.red.opacity(0.6)]
        case 3: return [Color.purple.opacity(0.8), Color.pink.opacity(0.6)]
        default: return [Color.blue.opacity(0.8), Color.purple.opacity(0.6)]
        }
    }
}

struct ProgressIndicator: View {
    let currentPage: Int
    let totalPages: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index <= currentPage ? Color.white : Color.white.opacity(0.3))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentPage)
            }
        }
    }
}

struct SkillLevelCard: View {
    let level: SkillLevel
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: level.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .blue : .white)
                
                VStack(spacing: 4) {
                    Text(level.rawValue)
                        .font(.headline)
                        .foregroundColor(isSelected ? .blue : .white)
                    
                    Text(level.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .blue.opacity(0.8) : .white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
    }
}

struct PlayStyleCard: View {
    let style: PlayStyle
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: style.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .blue : .white)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(style.rawValue)
                        .font(.headline)
                        .foregroundColor(isSelected ? .blue : .white)
                    
                    Text(style.description)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .blue.opacity(0.8) : .white.opacity(0.7))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
    }
}

struct AvatarOption: View {
    let systemName: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Image(systemName: systemName)
                .font(.system(size: 40))
                .foregroundColor(isSelected ? .blue : .white)
                .frame(width: 80, height: 80)
                .background(
                    Circle()
                        .fill(isSelected ? Color.white : Color.white.opacity(0.1))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                )
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
    }
}

struct NavigationButtons: View {
    @Binding var currentPage: Int
    let totalPages: Int
    let onFinish: () -> Void
    
    var body: some View {
        HStack {
            // Back button
            if currentPage > 0 {
                Button("Back") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentPage -= 1
                    }
                }
                .foregroundColor(.white.opacity(0.8))
                .font(.system(size: 16, weight: .medium))
            }
            
            Spacer()
            
            // Next/Finish button
            Button(currentPage == totalPages - 1 ? "Get Started" : "Next") {
                if currentPage == totalPages - 1 {
                    onFinish()
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentPage += 1
                    }
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.blue)
            .frame(width: 120, height: 44)
            .background(Color.white)
            .cornerRadius(22)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}

struct EnhancedConfettiView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        // Create multiple emitter layers for different effects
        let colors: [UIColor] = [.systemBlue, .systemPurple, .systemGreen, .systemOrange, .systemPink]
        
        for (index, color) in colors.enumerated() {
            let emitter = CAEmitterLayer()
            emitter.emitterPosition = CGPoint(x: UIScreen.main.bounds.midX + CGFloat(index - 2) * 50, y: -10)
            emitter.emitterShape = .line
            emitter.emitterSize = CGSize(width: 50, height: 2)
            
            let cell = CAEmitterCell()
            cell.birthRate = 20
            cell.lifetime = 6.0
            cell.velocity = 200
            cell.velocityRange = 50
            cell.scale = 0.03
            cell.scaleRange = 0.02
            cell.emissionRange = .pi / 4
            cell.spin = 2
            cell.spinRange = 3
            cell.contents = UIImage(systemName: "circle.fill")?.withTintColor(color).cgImage
            
            emitter.emitterCells = [cell]
            view.layer.addSublayer(emitter)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

#Preview {
    OnboardingView()
}
