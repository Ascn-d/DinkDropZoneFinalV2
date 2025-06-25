import SwiftUI

struct EnhancedStatsCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    let trend: StatTrend?
    let progress: Double?
    let maxValue: Double?
    let showAnimation: Bool
    
    enum StatTrend {
        case up(String)
        case down(String)
        case neutral
        
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
        
        var text: String? {
            switch self {
            case .up(let value), .down(let value): return value
            case .neutral: return nil
            }
        }
    }
    
    @State private var animateProgress = false
    @State private var animateValue = false
    
    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        color: Color,
        trend: StatTrend? = nil,
        progress: Double? = nil,
        maxValue: Double? = nil,
        showAnimation: Bool = true
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.trend = trend
        self.progress = progress
        self.maxValue = maxValue
        self.showAnimation = showAnimation
    }
    
    var body: some View {
        DSModernCard(style: .standard) {
            VStack(spacing: 12) {
                // Header with icon and trend
                HStack {
                    // Icon with background
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(color)
                    }
                    
                    Spacer()
                    
                    // Trend indicator
                    if let trend = trend {
                        HStack(spacing: 4) {
                            Image(systemName: trend.icon)
                                .font(.system(size: 10, weight: .medium))
                            
                            if let text = trend.text {
                                Text(text)
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                        .foregroundColor(trend.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(trend.color.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
                
                // Main content
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        // Title
                        Text(title)
                            .font(DS.Font.caption)
                            .fontWeight(.medium)
                            .foregroundColor(DS.Color.secondary)
                        
                        // Value with animation
                        Text(value)
                            .font(DS.Font.title2)
                            .fontWeight(.bold)
                            .foregroundColor(DS.Color.primary)
                            .scaleEffect(animateValue ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: animateValue)
                        
                        // Subtitle if provided
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(DS.Font.caption2)
                                .foregroundColor(DS.Color.secondary)
                        }
                    }
                    
                    // Progress bar if provided
                    if let progress = progress {
                        VStack(alignment: .leading, spacing: 4) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background
                                    Rectangle()
                                        .fill(color.opacity(0.1))
                                        .frame(height: 4)
                                        .clipShape(Capsule())
                                    
                                    // Progress
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [color, color.opacity(0.7)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(
                                            width: animateProgress ? geometry.size.width * progress : 0,
                                            height: 4
                                        )
                                        .clipShape(Capsule())
                                        .animation(.easeInOut(duration: 1.0), value: animateProgress)
                                }
                            }
                            .frame(height: 4)
                            
                            // Progress text
                            if let maxValue = maxValue {
                                HStack {
                                    Text("\(Int(progress * maxValue))/\(Int(maxValue))")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(DS.Color.secondary)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(progress * 100))%")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(color)
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            if showAnimation {
                withAnimation(.easeInOut(duration: 0.6).delay(0.1)) {
                    animateValue = true
                }
                withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
                    animateProgress = true
                }
            } else {
                animateProgress = true
                animateValue = true
            }
        }
    }
}

/// Compact stats card for grid layouts
struct CompactStatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let showRing: Bool
    let ringProgress: Double
    
    init(
        title: String,
        value: String,
        icon: String,
        color: Color,
        showRing: Bool = false,
        ringProgress: Double = 0.0
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.showRing = showRing
        self.ringProgress = ringProgress
    }
    
    var body: some View {
        DSModernCard(style: .minimal) {
            VStack(spacing: 8) {
                // Icon with optional progress ring
                ZStack {
                    if showRing {
                        DSProgressRing(
                            progress: ringProgress,
                            lineWidth: 4,
                            size: 40,
                            color: color
                        )
                    }
                    
                    Circle()
                        .fill(color.opacity(showRing ? 0.0 : 0.15))
                        .frame(width: showRing ? 32 : 40, height: showRing ? 32 : 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: showRing ? 14 : 16, weight: .medium))
                        .foregroundColor(color)
                }
                
                // Content
                VStack(spacing: 2) {
                    Text(value)
                        .font(DS.Font.headline)
                        .fontWeight(.bold)
                        .foregroundColor(DS.Color.primary)
                    
                    Text(title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DS.Color.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 90)
        }
    }
}

/// Large featured stats card
struct FeaturedStatsCard: View {
    let title: String
    let primaryValue: String
    let primaryLabel: String
    let secondaryStats: [(String, String)]
    let icon: String
    let color: Color
    let gradient: Bool
    
    init(
        title: String,
        primaryValue: String,
        primaryLabel: String,
        secondaryStats: [(String, String)] = [],
        icon: String,
        color: Color,
        gradient: Bool = true
    ) {
        self.title = title
        self.primaryValue = primaryValue
        self.primaryLabel = primaryLabel
        self.secondaryStats = secondaryStats
        self.icon = icon
        self.color = color
        self.gradient = gradient
    }
    
    var body: some View {
        DSModernCard(style: gradient ? .gradient : .prominent) {
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(DS.Font.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(DS.Color.secondary)
                        
                        HStack(spacing: 8) {
                            Image(systemName: icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(color)
                            
                            Text(primaryLabel)
                                .font(DS.Font.caption)
                                .foregroundColor(DS.Color.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // Primary value
                HStack {
                    DSAnimatedCounter(value: Int(primaryValue) ?? 0)
                        .foregroundColor(gradient ? color : DS.Color.primary)
                    
                    Spacer()
                }
                
                // Secondary stats
                if !secondaryStats.isEmpty {
                    Divider()
                        .background(color.opacity(0.2))
                    
                    HStack {
                        ForEach(Array(secondaryStats.enumerated()), id: \.offset) { index, stat in
                            VStack(spacing: 4) {
                                Text(stat.0)
                                    .font(DS.Font.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(DS.Color.primary)
                                
                                Text(stat.1)
                                    .font(DS.Font.caption2)
                                    .foregroundColor(DS.Color.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            
                            if index < secondaryStats.count - 1 {
                                Divider()
                                    .background(color.opacity(0.1))
                                    .frame(height: 30)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            // Enhanced stats cards
            HStack {
                EnhancedStatsCard(
                    title: "Current ELO",
                    value: "1,247",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue,
                    trend: .up("+52")
                )
                
                EnhancedStatsCard(
                    title: "Win Rate",
                    value: "73%",
                    subtitle: "Last 30 days",
                    icon: "trophy.fill",
                    color: .green,
                    progress: 0.73,
                    maxValue: 100
                )
            }
            
            // Compact stats grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                CompactStatsCard(
                    title: "Matches",
                    value: "42",
                    icon: "gamecontroller.fill",
                    color: .purple
                )
                
                CompactStatsCard(
                    title: "Level",
                    value: "15",
                    icon: "star.fill",
                    color: .orange,
                    showRing: true,
                    ringProgress: 0.6
                )
                
                CompactStatsCard(
                    title: "Streak",
                    value: "8",
                    icon: "flame.fill",
                    color: .red
                )
            }
            
            // Featured card
            FeaturedStatsCard(
                title: "This Month's Performance",
                primaryValue: "1247",
                primaryLabel: "Current ELO Rating",
                secondaryStats: [
                    ("12", "Wins"),
                    ("4", "Losses"),
                    ("75%", "Win Rate")
                ],
                icon: "chart.bar.fill",
                color: .blue
            )
        }
        .padding()
    }
} 