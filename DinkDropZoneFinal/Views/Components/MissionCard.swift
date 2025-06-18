import SwiftUI

// MARK: - Mission Card

struct MissionCard: View {
    let mission: Mission
    @State private var animateProgress = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Mission Icon
                ZStack {
                    Circle()
                        .fill(missionColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: mission.type.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(missionColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(mission.type.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(mission.type.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Mission Type Badge
                Text(missionTypeBadge)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(missionColor.opacity(0.2))
                    .foregroundColor(missionColor)
                    .clipShape(Capsule())
            }
            
            // Progress Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(mission.progress)/\(mission.targetValue)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        // Progress Fill
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [missionColor.opacity(0.8), missionColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: animateProgress ? geometry.size.width * mission.progressPercentage : 0,
                                height: 8
                            )
                            .animation(.easeInOut(duration: 1.0).delay(0.3), value: animateProgress)
                    }
                }
                .frame(height: 8)
            }
            
            // Reward Section
            HStack {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                
                Text("\(mission.type.xpReward) XP")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if mission.isCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Text("Completed")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                } else {
                    Text("\(Int(mission.progressPercentage * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(missionColor)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(mission.isCompleted ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .scaleEffect(mission.isCompleted ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: mission.isCompleted)
        .onAppear {
            animateProgress = true
        }
    }
    
    private var missionColor: Color {
        switch mission.type.color {
        case "blue": return .blue
        case "purple": return .purple
        case "gold": return .orange
        default: return .blue
        }
    }
    
    private var missionTypeBadge: String {
        if mission.type.isDaily {
            return "DAILY"
        } else if mission.type.isWeekly {
            return "WEEKLY"
        } else {
            return "ACHIEVEMENT"
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
                    .fill(missionColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: mission.type.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(missionColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(mission.type.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("\(mission.progress)/\(mission.targetValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Progress Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                    .frame(width: 24, height: 24)
                
                Circle()
                    .trim(from: 0, to: mission.progressPercentage)
                    .stroke(missionColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 24, height: 24)
                    .rotationEffect(.degrees(-90))
                
                if mission.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(missionColor)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private var missionColor: Color {
        switch mission.type.color {
        case "blue": return .blue
        case "purple": return .purple
        case "gold": return .orange
        default: return .blue
        }
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
    
    var progressPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mission Progress")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Keep completing missions to earn XP!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(completedCount)/\(totalCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.8), .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * progressPercentage,
                            height: 12
                        )
                        .animation(.easeInOut(duration: 1.0), value: progressPercentage)
                }
            }
            .frame(height: 12)
            
            // Stats
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    Text("\(todayXP) XP Today")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(Int(progressPercentage * 100))% Complete")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            MissionProgressSummary(completedCount: 3, totalCount: 5, todayXP: 250)
            
            MissionCard(mission: Mission(type: .playMatches, createdAt: Date()))
            
            CompactMissionCard(mission: Mission(type: .winMatches, createdAt: Date()))
            
            MissionListView(
                missions: [
                    Mission(type: .sendMessages, createdAt: Date()),
                    Mission(type: .addFriends, createdAt: Date())
                ],
                title: "Daily Missions"
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
} 