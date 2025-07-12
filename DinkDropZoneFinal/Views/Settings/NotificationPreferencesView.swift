import SwiftUI

struct NotificationPreferencesView: View {
    @StateObject private var notificationManager: SmartNotificationManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingAdvancedSettings = false
    @State private var showingNotificationHistory = false
    @State private var showingIntelligenceSettings = false
    
    init(notificationManager: SmartNotificationManager) {
        _notificationManager = StateObject(wrappedValue: notificationManager)
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Main Settings
                    mainNotificationSettings
                    
                    // Notification Types
                    notificationTypesSection
                    
                    // Intelligence Settings
                    intelligenceSection
                    
                    // Quiet Hours
                    quietHoursSection
                    
                    // Advanced Settings
                    advancedSettingsSection
                    
                    // Statistics
                    statisticsSection
                }
                .padding()
            }
            .navigationTitle("Notification Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        notificationManager.savePreferences()
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAdvancedSettings) {
            Text("Advanced Settings Coming Soon")
                .navigationTitle("Advanced Settings")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { showingAdvancedSettings = false }
                    }
                }
        }
        .sheet(isPresented: $showingNotificationHistory) {
            NotificationHistoryView(notificationManager: notificationManager)
        }
        .sheet(isPresented: $showingIntelligenceSettings) {
            IntelligenceSettingsView(notificationManager: notificationManager)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Smart Notifications")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Personalized alerts powered by AI")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.purple)
                        Text("AI Level: \(notificationManager.preferences.intelligenceLevel.rawValue.capitalized)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    Text("\(notificationManager.activeNotifications.count) active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var mainNotificationSettings: some View {
        VStack(spacing: 0) {
            // Master Toggle
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable Notifications")
                        .font(.headline)
                    
                    Text("Receive tournament updates and alerts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $notificationManager.preferences.isEnabled)
                    .tint(.blue)
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // Personalization Toggle
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .foregroundColor(.purple)
                        Text("AI Personalization")
                            .font(.headline)
                    }
                    
                    Text("Tailored content based on your behavior")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $notificationManager.preferences.personalizationEnabled)
                    .tint(.purple)
                    .disabled(!notificationManager.preferences.isEnabled)
            }
            .padding()
            .background(Color(.systemBackground))
            .opacity(notificationManager.preferences.isEnabled ? 1.0 : 0.6)
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var notificationTypesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notification Types")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(TournamentNotificationType.allCases, id: \.self) { type in
                    notificationTypeRow(for: type)
                    
                    if type != TournamentNotificationType.allCases.last {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
    
    private func notificationTypeRow(for type: TournamentNotificationType) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: iconForNotificationType(type))
                        .foregroundColor(colorForNotificationType(type))
                        .frame(width: 24, height: 24)
                    
                    Text(type.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Text(descriptionForNotificationType(type))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Toggle("", isOn: Binding(
                    get: { notificationManager.preferences.allowedTypes.contains(type) },
                    set: { enabled in
                        if enabled {
                            notificationManager.preferences.allowedTypes.insert(type)
                        } else {
                            notificationManager.preferences.allowedTypes.remove(type)
                        }
                    }
                ))
                .tint(.blue)
                .disabled(!notificationManager.preferences.isEnabled)
                
                if let limit = notificationManager.preferences.rateLimits[type] {
                    Text("Max \(limit)/hr")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .opacity(notificationManager.preferences.isEnabled ? 1.0 : 0.6)
    }
    
    private var intelligenceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("AI Intelligence")
                    .font(.headline)
                
                Spacer()
                
                Button("Configure") {
                    showingIntelligenceSettings = true
                }
                .font(.caption)
                .foregroundColor(.purple)
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                // Intelligence Level
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Intelligence Level")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(intelligenceLevelDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Picker("Intelligence Level", selection: $notificationManager.preferences.intelligenceLevel) {
                        ForEach(IntelligenceLevel.allCases, id: \.self) { level in
                            Text(level.rawValue.capitalized)
                                .tag(level)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .disabled(!notificationManager.preferences.isEnabled || !notificationManager.preferences.personalizationEnabled)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
                
                // Intelligence Features
                VStack(spacing: 0) {
                    intelligenceFeatureRow(
                        title: "Behavioral Analysis",
                        description: "Learn from your tournament patterns",
                        icon: "chart.line.uptrend.xyaxis",
                        isEnabled: $notificationManager.intelligenceSettings.behaviorAnalysisEnabled
                    )
                    
                    Divider()
                    
                    intelligenceFeatureRow(
                        title: "Contextual Processing",
                        description: "Understand tournament context",
                        icon: "brain.head.profile",
                        isEnabled: $notificationManager.intelligenceSettings.contextualProcessingEnabled
                    )
                    
                    Divider()
                    
                    intelligenceFeatureRow(
                        title: "Schedule Optimization",
                        description: "Time notifications perfectly",
                        icon: "clock.badge.checkmark",
                        isEnabled: $notificationManager.intelligenceSettings.scheduleOptimizationEnabled
                    )
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
            }
            .opacity(notificationManager.preferences.isEnabled && notificationManager.preferences.personalizationEnabled ? 1.0 : 0.6)
        }
    }
    
    private func intelligenceFeatureRow(
        title: String,
        description: String,
        icon: String,
        isEnabled: Binding<Bool>
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.purple)
                        .frame(width: 20, height: 20)
                    
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: isEnabled)
                .tint(.purple)
                .disabled(!notificationManager.preferences.isEnabled || !notificationManager.preferences.personalizationEnabled)
        }
        .padding()
    }
    
    private var quietHoursSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quiet Hours")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                // Quiet Hours Toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable Quiet Hours")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Pause notifications during specified hours")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $notificationManager.preferences.quietHours.isActive)
                        .tint(.blue)
                        .disabled(!notificationManager.preferences.isEnabled)
                }
                .padding()
                .background(Color(.systemBackground))
                
                if notificationManager.preferences.quietHours.isActive {
                    Divider()
                    
                    // Time Selection
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("From")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Picker("Start Hour", selection: $notificationManager.preferences.quietHours.startHour) {
                                ForEach(0..<24) { hour in
                                    Text(formatHour(hour))
                                        .tag(hour)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(height: 80)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("To")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Picker("End Hour", selection: $notificationManager.preferences.quietHours.endHour) {
                                ForEach(0..<24) { hour in
                                    Text(formatHour(hour))
                                        .tag(hour)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(height: 80)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .opacity(notificationManager.preferences.isEnabled ? 1.0 : 0.6)
        }
    }
    
    private var advancedSettingsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingAdvancedSettings = true
            }) {
                HStack {
                    Image(systemName: "gear")
                        .foregroundColor(.blue)
                    
                    Text("Advanced Settings")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                showingNotificationHistory = true
            }) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.blue)
                    
                    Text("Notification History")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(notificationManager.notificationHistory.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatisticCard(
                    title: "Today",
                    value: "\(todayNotificationCount)",
                    icon: "bell.fill",
                    color: .blue
                )
                
                StatisticCard(
                    title: "This Week",
                    value: "\(weekNotificationCount)",
                    icon: "calendar",
                    color: .green
                )
                
                StatisticCard(
                    title: "Active",
                    value: "\(notificationManager.activeNotifications.count)",
                    icon: "dot.radiowaves.left.and.right",
                    color: .orange
                )
                
                StatisticCard(
                    title: "Success Rate",
                    value: "\(Int(successRate * 100))%",
                    icon: "checkmark.circle.fill",
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func iconForNotificationType(_ type: TournamentNotificationType) -> String {
        switch type {
        case .tournamentStartingSoon: return "play.circle.fill"
        case .matchReadyPersonalized: return "sportscourt.fill"
        case .bracketUpdatedSmart: return "list.bullet.below.rectangle"
        case .performanceInsight: return "chart.bar.fill"
        case .strategicRecommendation: return "lightbulb.fill"
        case .socialEngagement: return "person.3.fill"
        case .tournamentCompleted: return "trophy.fill"
        case .achievementUnlocked: return "star.fill"
        case .friendActivity: return "heart.fill"
        case .trainingRecommendation: return "book.fill"
        }
    }
    
    private func colorForNotificationType(_ type: TournamentNotificationType) -> Color {
        switch type {
        case .tournamentStartingSoon: return .red
        case .matchReadyPersonalized: return .blue
        case .bracketUpdatedSmart: return .green
        case .performanceInsight: return .purple
        case .strategicRecommendation: return .orange
        case .socialEngagement: return .pink
        case .tournamentCompleted: return .yellow
        case .achievementUnlocked: return .cyan
        case .friendActivity: return .mint
        case .trainingRecommendation: return .indigo
        }
    }
    
    private func descriptionForNotificationType(_ type: TournamentNotificationType) -> String {
        switch type {
        case .tournamentStartingSoon: return "Alerts before tournaments begin"
        case .matchReadyPersonalized: return "Personalized match notifications"
        case .bracketUpdatedSmart: return "Intelligent bracket change alerts"
        case .performanceInsight: return "AI-powered performance analysis"
        case .strategicRecommendation: return "Strategic tips and advice"
        case .socialEngagement: return "Social activity updates"
        case .tournamentCompleted: return "Tournament completion notifications"
        case .achievementUnlocked: return "Achievement unlock celebrations"
        case .friendActivity: return "Friend activity notifications"
        case .trainingRecommendation: return "Training and improvement tips"
        }
    }
    
    private var intelligenceLevelDescription: String {
        switch notificationManager.preferences.intelligenceLevel {
        case .basic: return "Simple notifications"
        case .smart: return "Personalized timing and content"
        case .advanced: return "Behavioral analysis and optimization"
        case .expert: return "Full AI-powered intelligence"
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
    
    private var todayNotificationCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return notificationManager.notificationHistory.filter { item in
            Calendar.current.isDate(item.sentAt, inSameDayAs: today)
        }.count
    }
    
    private var weekNotificationCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return notificationManager.notificationHistory.filter { item in
            item.sentAt >= weekAgo
        }.count
    }
    
    private var successRate: Double {
        let totalNotifications = notificationManager.notificationHistory.count
        guard totalNotifications > 0 else { return 0.0 }
        
        let successfulNotifications = notificationManager.notificationHistory.filter { item in
            item.wasDelivered && item.wasInteractedWith
        }.count
        
        return Double(successfulNotifications) / Double(totalNotifications)
    }
}

// MARK: - Supporting Views

struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview

struct NotificationPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationPreferencesView(
            notificationManager: SmartNotificationManager(
                pushService: PushServiceV2(),
                firebaseService: FirebaseService.shared
            )
        )
    }
} 