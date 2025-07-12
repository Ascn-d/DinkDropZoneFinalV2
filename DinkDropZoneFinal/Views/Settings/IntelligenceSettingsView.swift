import SwiftUI

struct IntelligenceSettingsView: View {
    @ObservedObject var notificationManager: SmartNotificationManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingResetConfirmation = false
    @State private var showingAnalyticsDetail = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Intelligence Level
                    intelligenceLevelSection
                    
                    // Feature Controls
                    featureControlsSection
                    
                    // Behavioral Analysis
                    behavioralAnalysisSection
                    
                    // Performance Metrics
                    performanceMetricsSection
                    
                    // Data Management
                    dataManagementSection
                }
                .padding()
            }
            .navigationTitle("AI Intelligence")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Reset AI Learning", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAILearning()
            }
        } message: {
            Text("This will erase all learned behavior patterns and reset AI intelligence to default settings. This action cannot be undone.")
        }
        .sheet(isPresented: $showingAnalyticsDetail) {
            AnalyticsDetailView(notificationManager: notificationManager)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // AI Status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Status")
                        .font(.headline)
                    
                    Text(aiStatusDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(notificationManager.isProcessingIntelligence ? Color.orange : Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text(notificationManager.isProcessingIntelligence ? "Processing" : "Active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Processing Indicator
            if notificationManager.isProcessingIntelligence {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
    }
    
    private var intelligenceLevelSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Intelligence Level")
                .font(.headline)
            
            VStack(spacing: 0) {
                ForEach(IntelligenceLevel.allCases, id: \.self) { level in
                    intelligenceLevelRow(level: level)
                    
                    if level != IntelligenceLevel.allCases.last {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
    
    private func intelligenceLevelRow(level: IntelligenceLevel) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: iconForIntelligenceLevel(level))
                        .foregroundColor(colorForIntelligenceLevel(level))
                        .frame(width: 28, height: 28)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(level.rawValue.capitalized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(descriptionForIntelligenceLevel(level))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Features for this level
                HStack {
                    ForEach(featuresForIntelligenceLevel(level), id: \.self) { feature in
                        Text(feature)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(colorForIntelligenceLevel(level).opacity(0.7))
                            )
                    }
                }
                .padding(.leading, 36)
            }
            
            Spacer()
            
            // Selection Indicator
            if notificationManager.preferences.intelligenceLevel == level {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.secondary)
                    .font(.title2)
            }
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            notificationManager.preferences.intelligenceLevel = level
        }
    }
    
    private var featureControlsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Intelligence Features")
                .font(.headline)
            
            VStack(spacing: 0) {
                // Behavioral Analysis
                featureToggleRow(
                    title: "Behavioral Analysis",
                    description: "Learn from your tournament patterns and preferences",
                    icon: "brain.head.profile",
                    color: .purple,
                    isEnabled: $notificationManager.intelligenceSettings.behaviorAnalysisEnabled
                )
                
                Divider()
                
                // Contextual Processing
                featureToggleRow(
                    title: "Contextual Processing",
                    description: "Understand tournament context and adapt notifications",
                    icon: "eye.trianglebadge.exclamationmark",
                    color: .blue,
                    isEnabled: $notificationManager.intelligenceSettings.contextualProcessingEnabled
                )
                
                Divider()
                
                // Schedule Optimization
                featureToggleRow(
                    title: "Schedule Optimization",
                    description: "Time notifications based on your activity patterns",
                    icon: "clock.badge.checkmark",
                    color: .green,
                    isEnabled: $notificationManager.intelligenceSettings.scheduleOptimizationEnabled
                )
                
                Divider()
                
                // Personalized Content
                featureToggleRow(
                    title: "Personalized Content",
                    description: "Customize notification content based on your style",
                    icon: "person.crop.circle.badge.plus",
                    color: .orange,
                    isEnabled: $notificationManager.intelligenceSettings.personalizedContentEnabled
                )
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
    
    private func featureToggleRow(
        title: String,
        description: String,
        icon: String,
        color: Color,
        isEnabled: Binding<Bool>
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .frame(width: 24, height: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Advanced Settings Link
                if isEnabled.wrappedValue {
                    Button("Advanced Settings") {
                        // Show advanced settings for this feature
                    }
                    .font(.caption)
                    .foregroundColor(color)
                    .padding(.leading, 32)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: isEnabled)
                .tint(color)
        }
        .padding()
    }
    
    private var behavioralAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Behavioral Analysis")
                    .font(.headline)
                
                Spacer()
                
                Button("View Details") {
                    showingAnalyticsDetail = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if notificationManager.intelligenceSettings.behaviorAnalysisEnabled {
                VStack(spacing: 12) {
                    // Learning Progress
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Learning Progress")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("74%")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        
                        ProgressView(value: 0.74)
                            .tint(.blue)
                        
                        Text("AI has analyzed 47 tournaments and 156 matches")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    
                    // Behavior Insights
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        BehaviorInsightCard(
                            title: "Peak Activity",
                            value: "7-9 PM",
                            icon: "clock.fill",
                            color: .blue
                        )
                        
                        BehaviorInsightCard(
                            title: "Response Time",
                            value: "3.2 min",
                            icon: "timer",
                            color: .green
                        )
                        
                        BehaviorInsightCard(
                            title: "Engagement",
                            value: "High",
                            icon: "hand.tap.fill",
                            color: .purple
                        )
                        
                        BehaviorInsightCard(
                            title: "Preferences",
                            value: "Match Focus",
                            icon: "target",
                            color: .orange
                        )
                    }
                }
            } else {
                Text("Enable behavioral analysis to see insights")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
            }
        }
    }
    
    private var performanceMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Metrics")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                IntelligenceMetricCard(
                    title: "Delivery Rate",
                    value: "98.5%",
                    change: "+2.1%",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                IntelligenceMetricCard(
                    title: "Interaction Rate",
                    value: "67.3%",
                    change: "+12.4%",
                    icon: "hand.tap.fill",
                    color: .blue
                )
                
                IntelligenceMetricCard(
                    title: "Relevance Score",
                    value: "8.9/10",
                    change: "+0.7",
                    icon: "target",
                    color: .purple
                )
                
                IntelligenceMetricCard(
                    title: "Opt-out Rate",
                    value: "1.2%",
                    change: "-0.8%",
                    icon: "xmark.circle.fill",
                    color: .red
                )
            }
        }
    }
    
    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Management")
                .font(.headline)
            
            VStack(spacing: 0) {
                // Data Usage
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Data Usage")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("AI learning data: 12.3 MB")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Export") {
                        exportData()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding()
                .background(Color(.systemBackground))
                
                Divider()
                
                // Reset AI Learning
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reset AI Learning")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Clear all learned patterns and start fresh")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Reset") {
                        showingResetConfirmation = true
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
                .padding()
                .background(Color(.systemBackground))
                
                Divider()
                
                // Privacy Settings
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Privacy Settings")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Manage data collection and sharing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Configure") {
                        // Show privacy settings
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Methods
    
    private var aiStatusDescription: String {
        if notificationManager.isProcessingIntelligence {
            return "AI is analyzing your behavior patterns..."
        } else {
            return "AI intelligence is active and learning from your interactions"
        }
    }
    
    private func iconForIntelligenceLevel(_ level: IntelligenceLevel) -> String {
        switch level {
        case .basic: return "circle"
        case .smart: return "brain"
        case .advanced: return "brain.head.profile"
        case .expert: return "brain.head.profile.fill"
        }
    }
    
    private func colorForIntelligenceLevel(_ level: IntelligenceLevel) -> Color {
        switch level {
        case .basic: return .gray
        case .smart: return .blue
        case .advanced: return .purple
        case .expert: return .indigo
        }
    }
    
    private func descriptionForIntelligenceLevel(_ level: IntelligenceLevel) -> String {
        switch level {
        case .basic: return "Simple notifications with basic timing"
        case .smart: return "Personalized timing and content adaptation"
        case .advanced: return "Behavioral analysis and context understanding"
        case .expert: return "Full AI intelligence with predictive insights"
        }
    }
    
    private func featuresForIntelligenceLevel(_ level: IntelligenceLevel) -> [String] {
        switch level {
        case .basic: return ["Basic Alerts"]
        case .smart: return ["Smart Timing", "Content Adaptation"]
        case .advanced: return ["Behavior Analysis", "Context Awareness", "Optimization"]
        case .expert: return ["Predictive AI", "Full Intelligence", "Advanced Analytics"]
        }
    }
    
    private func resetAILearning() {
        // Reset AI learning data
        notificationManager.intelligenceSettings = IntelligenceSettings()
        // Clear behavioral data
        // Reset learning progress
    }
    
    private func exportData() {
        // Export AI learning data
    }
}

// MARK: - Supporting Views

struct BehaviorInsightCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                
                Spacer()
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct IntelligenceMetricCard: View {
    let title: String
    let value: String
    let change: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
                
                Text(change)
                    .font(.caption)
                    .foregroundColor(change.hasPrefix("+") ? .green : .red)
                    .fontWeight(.medium)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct AnalyticsDetailView: View {
    @ObservedObject var notificationManager: SmartNotificationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Detailed analytics view would go here")
                        .font(.title2)
                        .padding()
                }
            }
            .navigationTitle("Analytics Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct IntelligenceSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        IntelligenceSettingsView(
            notificationManager: SmartNotificationManager(
                pushService: PushServiceV2(),
                firebaseService: FirebaseService.shared
            )
        )
    }
} 