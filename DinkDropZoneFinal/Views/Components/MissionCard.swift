import SwiftUI

// MARK: - Mission Card

struct MissionCard: View {
    let mission: Mission
    @Environment(XPManager.self) private var xpManager
    
    private var progressText: String {
        return "\(mission.progress)/\(mission.type.targetValue)"
    }
    
    private var progressPercentage: Double {
        return Double(mission.progress) / Double(mission.type.targetValue)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(missionColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: mission.type.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(missionColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mission.type.title)
                        .font(DS.Font.headline)
                        .foregroundColor(DS.Color.primary)
                    
                    Text(mission.type.description)
                        .font(DS.Font.caption)
                        .foregroundColor(DS.Color.secondary)
                }
                
                Spacer()
                
                // XP Reward
                VStack(alignment: .trailing, spacing: 2) {
                    Text("+\(mission.xpReward) XP")
                        .font(DS.Font.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    if mission.isCompleted {
                        Text("Completed")
                            .font(DS.Font.caption2)
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Progress bar
            VStack(spacing: 6) {
                HStack {
                    Text(progressText)
                        .font(DS.Font.caption)
                        .foregroundColor(DS.Color.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(progressPercentage * 100))%")
                        .font(DS.Font.caption)
                        .foregroundColor(DS.Color.secondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 4)
                            .fill(missionColor)
                            .frame(width: geometry.size.width * CGFloat(progressPercentage), height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(DS.Color.surface)
        .cornerRadius(DS.Layout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Layout.cornerRadius)
                .stroke(mission.isCompleted ? Color.green.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var missionColor: Color {
        switch mission.type.color {
        case "blue": return .blue
        case "gold": return .yellow
        case "purple": return .purple
        default: return .blue
        }
    }
}

// MARK: - Compact Mission Card

struct CompactMissionCard: View {
    let mission: Mission
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(mission.type.color).opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: mission.type.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(mission.type.color))
            }
            
            // Mission info
            VStack(alignment: .leading, spacing: 2) {
                Text(mission.type.rawValue)
                    .font(DS.Font.caption)
                    .fontWeight(.semibold)
                
                // Progress bar
                HStack(spacing: 4) {
                    ProgressView(value: mission.progressPercentage)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color(mission.type.color)))
                        .scaleEffect(x: 1, y: 0.5, anchor: .center)
                    
                    Text("\(mission.progress)/\(mission.type.targetValue)")
                        .font(DS.Font.caption2)
                        .foregroundColor(DS.Color.secondary)
                }
            }
            
            Spacer()
            
            // XP reward
            Text("\(mission.xpReward) XP")
                .font(DS.Font.caption)
                .fontWeight(.medium)
                .foregroundColor(.orange)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(DS.Color.surface)
        .cornerRadius(DS.Layout.cornerRadius)
    }
}

// MARK: - Mission List View

struct MissionListView: View {
    let missions: [Mission]
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            if missions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    
                    Text("All missions completed!")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("New missions will be available soon.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(missions) { mission in
                        MissionCard(mission: mission)
                    }
                }
            }
        }
    }
}

// MARK: - Mission Progress Summary

struct MissionProgressSummary: View {
    let completedCount: Int
    let totalCount: Int
    let todayXP: Int
    
    private var progressPercentage: Double {
        return totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress ring
            HStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(DS.Color.divider, lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: progressPercentage)
                        .stroke(
                            progressPercentage >= 1.0 ? Color.green : DS.Color.accent,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(completedCount)/\(totalCount)")
                            .font(DS.Font.title3)
                            .fontWeight(.bold)
                        
                        Text("Done")
                            .font(DS.Font.caption)
                            .foregroundColor(DS.Color.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Progress")
                        .font(DS.Font.headline)
                        .fontWeight(.bold)
                    
                    Text("Complete missions to earn XP")
                        .font(DS.Font.subheadline)
                        .foregroundColor(DS.Color.secondary)
                    
                                            Text("\(todayXP) XP earned today")
                            .font(DS.Font.caption)
                            .foregroundColor(Color.orange)
                            .padding(.top, 4)
                }
            }
            
            // Motivational message
            if progressPercentage >= 1.0 {
                Text("All missions completed! Great job!")
                    .font(DS.Font.caption)
                    .foregroundColor(Color.green)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if progressPercentage >= 0.5 {
                Text("You're making great progress! Keep it up!")
                    .font(DS.Font.caption)
                    .foregroundColor(DS.Color.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Text("Complete more missions to earn XP and rewards")
                    .font(DS.Font.caption)
                    .foregroundColor(DS.Color.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

/// Modern compact mission card for dashboard
struct ModernMissionCard: View {
    let mission: Mission
    
    var body: some View {
        DSModernCard(style: .minimal) {
            HStack(spacing: 12) {
                // Mission icon with progress ring
                ZStack {
                    DSProgressRing(
                        progress: Double(mission.progress),
                        lineWidth: 3,
                        size: 36,
                        color: mission.isCompleted ? Color.green : Color.orange
                    )
                    
                    Image(systemName: mission.isCompleted ? "checkmark" : mission.type.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(mission.isCompleted ? Color.green : Color.orange)
                }
                
                // Mission details
                VStack(alignment: .leading, spacing: 4) {
                    Text(mission.type.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(DS.Color.primary)
                        .lineLimit(1)
                    
                    Text(mission.type.description)
                        .font(.system(size: 11))
                        .foregroundColor(DS.Color.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Reward
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 3) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color.orange)
                        
                        Text("\(mission.type.xpReward)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.orange)
                    }
                    
                    if !mission.isCompleted {
                        Text("\(mission.progress)/\(mission.type.targetValue)")
                            .font(.system(size: 9))
                            .foregroundColor(DS.Color.secondary)
                    }
                }
            }
        }
    }
}

/// Modern recent match card for dashboard
struct ModernRecentMatchCard: View {
    let match: GameMatchWrapper
    @EnvironmentObject private var appState: AppState
    
    private var isWin: Bool {
        guard let currentUser = appState.currentUser else { return false }
        return match.result(for: currentUser) == "Win"
    }
    
    var body: some View {
        DSModernCard(style: .minimal) {
            HStack(spacing: 12) {
                // Result indicator
                ZStack {
                    Circle()
                        .fill(isWin ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: isWin ? "checkmark" : "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isWin ? Color.green : Color.red)
                }
                
                // Match details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("vs \(match.opponent(for: appState.currentUser!))")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(DS.Color.primary)
                        
                        Spacer()
                        
                        Text(match.score)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DS.Color.primary)
                    }
                    
                    HStack {
                        Text(match.date, style: .date)
                            .font(.system(size: 11))
                            .foregroundColor(DS.Color.secondary)
                        
                        Spacer()
                        
                        // ELO change
                        HStack(spacing: 3) {
                            Image(systemName: match.eloChange.hasPrefix("+") ? "arrow.up" : "arrow.down")
                                .font(.system(size: 9))
                            
                            Text(match.eloChange)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(match.eloChange.hasPrefix("+") ? Color.green : Color.red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background((match.eloChange.hasPrefix("+") ? Color.green : Color.red).opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        MissionProgressSummary(
            completedCount: 3,
            totalCount: 5,
            todayXP: 250
        )
        
        MissionCard(
            mission: Mission(
                type: .playMatches,
                progress: 2,
                isCompleted: false
            )
        )
        
        MissionCard(
            mission: Mission(
                type: .winMatches,
                progress: 2,
                isCompleted: true
            )
        )
        
        CompactMissionCard(
            mission: Mission(
                type: .scorePoints,
                progress: 15,
                isCompleted: false
            )
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
} 