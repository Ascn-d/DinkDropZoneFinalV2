//
//  SplashView.swift
//

import SwiftUI

struct SplashView: View {
    @Binding var isActive: Bool
    @State private var animate = false
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var backgroundOpacity: Double = 0
    @State private var particlesOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground()
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
            
            // Floating particles
            FloatingParticlesView()
                .opacity(particlesOpacity)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo with sophisticated animation
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.blue.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(animate ? 1.2 : 0.8)
                        .opacity(animate ? 0.6 : 0)
                    
                    // Main logo
                    Image(systemName: "figure.pickleball")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        .shadow(color: .blue.opacity(0.5), radius: 20, x: 0, y: 10)
                }
                
                // App title with elegant typography
                VStack(spacing: 8) {
                    Text("DinkDropZone")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .blue.opacity(0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(textOpacity)
                    
                    Text("Elevate Your Pickleball Game")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(textOpacity)
                }
            }
        }
        .onAppear {
            startAnimationSequence()
        }
    }
    
    private func startAnimationSequence() {
        // Background fade in
        withAnimation(.easeIn(duration: 0.5)) {
            backgroundOpacity = 1
        }
        
        // Particles appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeIn(duration: 0.8)) {
                particlesOpacity = 1
            }
        }
        
        // Logo animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
                animate = true
            }
        }
        
        // Text animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.8)) {
                textOpacity = 1.0
            }
        }
        
        // Auto dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                isActive = false
            }
        }
    }
}

// MARK: - Supporting Views

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: animateGradient ? 
                [Color.blue.opacity(0.8), Color.purple.opacity(0.6), Color.blue.opacity(0.9)] :
                [Color.purple.opacity(0.6), Color.blue.opacity(0.9), Color.purple.opacity(0.8)],
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

struct FloatingParticlesView: View {
    @State private var particles: [Particle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            generateParticles()
            animateParticles()
        }
    }
    
    private func generateParticles() {
        particles = (0..<20).map { _ in
            Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                ),
                size: CGFloat.random(in: 2...8),
                opacity: Double.random(in: 0.1...0.6)
            )
        }
    }
    
    private func animateParticles() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.linear(duration: 0.1)) {
                for i in particles.indices {
                    particles[i].position.y -= CGFloat.random(in: 0.5...2.0)
                    particles[i].position.x += CGFloat.random(in: -0.5...0.5)
                    
                    if particles[i].position.y < -10 {
                        particles[i].position.y = UIScreen.main.bounds.height + 10
                        particles[i].position.x = CGFloat.random(in: 0...UIScreen.main.bounds.width)
                    }
                }
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let size: CGFloat
    let opacity: Double
}

#Preview {
    SplashView(isActive: .constant(true))
}
