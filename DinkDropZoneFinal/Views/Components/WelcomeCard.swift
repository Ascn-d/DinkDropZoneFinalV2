import SwiftUI

struct WelcomeCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradientColors: [Color]
    let action: () -> Void
    
    @State private var animateCard = false
    @State private var animateIcon = false
    @State private var animateText = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                // Icon with glow effect
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [gradientColors.first?.opacity(0.3) ?? Color.blue.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)
                        .scaleEffect(animateIcon ? 1.2 : 0.8)
                        .opacity(animateIcon ? 0.8 : 0)
                    
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(animateIcon ? 1.0 : 0.6)
                        .opacity(animateIcon ? 1.0 : 0)
                }
                
                // Text content
                VStack(spacing: 8) {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                        .opacity(animateText ? 1.0 : 0)
                        .offset(y: animateText ? 0 : 10)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(animateText ? 1.0 : 0)
                        .offset(y: animateText ? 0 : 15)
                }
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: gradientColors.map { $0.opacity(0.3) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(animateCard ? 1.0 : 0.95)
            .opacity(animateCard ? 1.0 : 0)
        }
        .buttonStyle(ScaleButtonStyle())
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateCard = true
            }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3)) {
                animateIcon = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                animateText = true
            }
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct FeatureHighlight: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            .scaleEffect(animate ? 1.0 : 0.8)
            .opacity(animate ? 1.0 : 0)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(animate ? 1.0 : 0)
            .offset(x: animate ? 0 : 20)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animate = true
            }
        }
    }
}

struct AnimatedGradientCard: View {
    let content: AnyView
    let gradientColors: [Color]
    
    @State private var animateGradient = false
    
    var body: some View {
        content
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: animateGradient ? gradientColors.reversed() : gradientColors,
                            startPoint: animateGradient ? .topLeading : .bottomTrailing,
                            endPoint: animateGradient ? .bottomTrailing : .topLeading
                        )
                    )
                    .shadow(color: gradientColors.first?.opacity(0.3) ?? Color.blue.opacity(0.3), radius: 15, x: 0, y: 8)
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
            }
    }
}

#Preview {
    VStack(spacing: 20) {
        WelcomeCard(
            title: "Find Players",
            subtitle: "Connect with pickleball players in your area",
            icon: "person.3.fill",
            gradientColors: [.blue, .purple],
            action: {}
        )
        
        FeatureHighlight(
            icon: "trophy.fill",
            title: "Track Progress",
            description: "Monitor your improvement with detailed statistics",
            color: .orange
        )
        
        AnimatedGradientCard(
            content: AnyView(
                VStack {
                    Text("Premium Feature")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Unlock advanced analytics")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            ),
            gradientColors: [.pink, .purple]
        )
    }
    .padding()
} 