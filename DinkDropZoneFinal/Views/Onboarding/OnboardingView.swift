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
    @State private var page = 0
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            TabView(selection: $page) {
                SkillPage()
                    .tag(0)
                LocationPage()
                    .tag(1)
                AvatarPage()
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle())
            
            VStack {
                Spacer()
                if page == 2 {
                    Button(action: finish) {
                        Text("Let's Play")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    .transition(.move(edge: .bottom))
                    .padding(.bottom)
                }
            }
            
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: page)
    }
    
    private func finish() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        withAnimation {
            showConfetti = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            hasOnboarded = true
        }
    }
}

#Preview {
    OnboardingView()
}

private struct SkillPage: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Select your skill level")
                .font(.title)
                .bold()
            HStack(spacing: 16) {
                ForEach(["Beginner", "Intermediate", "Advanced"], id: \ .self) { level in
                    Text(level)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            Spacer()
        }
        .padding()
    }
}

private struct LocationPage: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Enable location to find nearby players")
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
            LocationButton(.shareCurrentLocation) {
                // location request handled in App
            }
            .cornerRadius(8)
            .symbolVariant(.fill)
            Spacer()
        }
        .padding()
    }
}

private struct AvatarPage: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Choose your avatar")
                .font(.title)
                .bold()
            Image(systemName: "person.crop.circle")
                .resizable()
                .frame(width: 120, height: 120)
                .foregroundColor(.accentColor)
            Spacer()
        }
        .padding()
    }
}

private struct ConfettiView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: UIScreen.main.bounds.midX, y: -10)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: UIScreen.main.bounds.width, height: 2)
        
        let cell = CAEmitterCell()
        cell.birthRate = 30
        cell.lifetime = 4.0
        cell.velocity = 150
        cell.scale = 0.02
        cell.emissionRange = .pi
        cell.contents = UIImage(systemName: "circle.fill")?.withTintColor(.systemPink).cgImage
        
        emitter.emitterCells = [cell]
        view.layer.addSublayer(emitter)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
