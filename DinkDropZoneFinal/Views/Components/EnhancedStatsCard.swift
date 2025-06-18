import SwiftUI

struct EnhancedStatsCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    let trend: TrendDirection?
    let trendValue: String?
    let showGradient: Bool
    
    enum TrendDirection {
        case up, down, neutral
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
    }
    
    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        color: Color,
        trend: TrendDirection? = nil,
        trendValue: String? = nil,
        showGradient: Bool = true
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.trend = trend
        self.trendValue = trendValue
        self.showGradient = showGradient
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with icon and trend
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(showGradient ? .white : color)
                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                
                Spacer()
                
                if let trend = trend, let trendValue = trendValue {
                    HStack(spacing: 2) {
                        Image(systemName: trend.icon)
                            .font(.caption2)
                        Text(trendValue)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(showGradient ? .white.opacity(0.9) : trend.color)
                }
            }
            
            // Main value
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(showGradient ? .white : .primary)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(showGradient ? .white.opacity(0.8) : .secondary)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(showGradient ? .white.opacity(0.9) : .secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(
            Group {
                if showGradient {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            color,
                            color.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    Color(.secondarySystemBackground)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    showGradient ? Color.white.opacity(0.2) : color.opacity(0.3),
                    lineWidth: 1
                )
        )
        .shadow(
            color: showGradient ? color.opacity(0.3) : Color.black.opacity(0.1),
            radius: showGradient ? 8 : 4,
            x: 0,
            y: showGradient ? 4 : 2
        )
    }
}

struct AnimatedStatsCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    let animationDelay: Double
    
    @State private var isVisible = false
    @State private var scale = 0.8
    @State private var opacity = 0.0
    
    var body: some View {
        EnhancedStatsCard(
            title: title,
            value: value,
            subtitle: subtitle,
            icon: icon,
            color: color,
            showGradient: true
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(
                .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
                .delay(animationDelay)
            ) {
                scale = 1.0
                opacity = 1.0
                isVisible = true
            }
        }
    }
}

struct InteractiveStatsCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    let action: (() -> Void)?
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            action?()
        } label: {
            EnhancedStatsCard(
                title: title,
                value: value,
                subtitle: subtitle,
                icon: icon,
                color: color,
                showGradient: true
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    VStack(spacing: 16) {
        EnhancedStatsCard(
            title: "ELO Rating",
            value: "1,847",
            subtitle: "Advanced",
            icon: "star.fill",
            color: .blue,
            trend: .up,
            trendValue: "+23",
            showGradient: true
        )
        
        AnimatedStatsCard(
            title: "Win Rate",
            value: "78%",
            subtitle: "Last 30 days",
            icon: "chart.line.uptrend.xyaxis",
            color: .green,
            animationDelay: 0.2
        )
        
        InteractiveStatsCard(
            title: "Matches",
            value: "142",
            subtitle: "This season",
            icon: "gamecontroller.fill",
            color: .purple
        ) {
            print("Stats card tapped!")
        }
    }
    .padding()
} 