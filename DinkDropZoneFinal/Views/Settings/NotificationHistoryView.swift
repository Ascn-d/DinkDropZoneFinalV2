import SwiftUI

struct NotificationHistoryView: View {
    @ObservedObject var notificationManager: SmartNotificationManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: HistoryFilter = .all
    @State private var searchText = ""
    @State private var showingFilterSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                searchAndFilterBar
                
                // History List
                if filteredHistory.isEmpty {
                    emptyStateView
                } else {
                    historyList
                }
            }
            .navigationTitle("Notification History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        clearAllHistory()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterSheet(selectedFilter: $selectedFilter)
        }
    }
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search notifications...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    showingFilterSheet = true
                }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            
            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(HistoryFilter.allCases, id: \.self) { filter in
                        FilterPill(
                            filter: filter,
                            isSelected: selectedFilter == filter,
                            count: countForFilter(filter)
                        ) {
                            selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    private var historyList: some View {
        List {
            ForEach(groupedHistory, id: \.key) { group in
                Section(header: sectionHeader(for: group.key)) {
                    ForEach(group.value) { item in
                        NotificationHistoryRow(item: item)
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Notifications")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Your notification history will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private func sectionHeader(for date: String) -> some View {
        HStack {
            Text(date)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(countForDate(date)) notifications")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Data Processing
    
    private var filteredHistory: [NotificationHistoryItem] {
        let filtered = notificationManager.notificationHistory.filter { item in
            // Apply search filter
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                return item.type.displayName.lowercased().contains(searchLower) ||
                       item.tournamentId.lowercased().contains(searchLower)
            }
            return true
        }.filter { item in
            // Apply type filter
            switch selectedFilter {
            case .all:
                return true
            case .delivered:
                return item.wasDelivered
            case .interacted:
                return item.wasInteractedWith
            case .highPriority:
                return item.priority == .high || item.priority == .urgent
            case .today:
                return Calendar.current.isDateInToday(item.sentAt)
            case .thisWeek:
                return Calendar.current.isDate(item.sentAt, equalTo: Date(), toGranularity: .weekOfYear)
            }
        }
        
        return filtered.sorted { $0.sentAt > $1.sentAt }
    }
    
    private var groupedHistory: [(key: String, value: [NotificationHistoryItem])] {
        let grouped = Dictionary(grouping: filteredHistory) { item in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: item.sentAt)
        }
        
        return grouped.sorted { first, second in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let firstDate = formatter.date(from: first.key) ?? Date.distantPast
            let secondDate = formatter.date(from: second.key) ?? Date.distantPast
            return firstDate > secondDate
        }
    }
    
    private func countForFilter(_ filter: HistoryFilter) -> Int {
        switch filter {
        case .all:
            return notificationManager.notificationHistory.count
        case .delivered:
            return notificationManager.notificationHistory.filter { $0.wasDelivered }.count
        case .interacted:
            return notificationManager.notificationHistory.filter { $0.wasInteractedWith }.count
        case .highPriority:
            return notificationManager.notificationHistory.filter { $0.priority == .high || $0.priority == .urgent }.count
        case .today:
            return notificationManager.notificationHistory.filter { Calendar.current.isDateInToday($0.sentAt) }.count
        case .thisWeek:
            return notificationManager.notificationHistory.filter { Calendar.current.isDate($0.sentAt, equalTo: Date(), toGranularity: .weekOfYear) }.count
        }
    }
    
    private func countForDate(_ dateString: String) -> Int {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        guard let date = formatter.date(from: dateString) else { return 0 }
        
        return notificationManager.notificationHistory.filter { item in
            Calendar.current.isDate(item.sentAt, inSameDayAs: date)
        }.count
    }
    
    private func clearAllHistory() {
        notificationManager.notificationHistory.removeAll()
    }
}

// MARK: - Supporting Views

struct FilterPill: View {
    let filter: HistoryFilter
    let isSelected: Bool
    let count: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(filter.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelected ? Color.white.opacity(0.3) : Color.secondary.opacity(0.2))
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.blue : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

struct NotificationHistoryRow: View {
    let item: NotificationHistoryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Type Icon
                Image(systemName: iconForType(item.type))
                    .foregroundColor(colorForType(item.type))
                    .frame(width: 24, height: 24)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.type.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(timeAgoString(from: item.sentAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status Indicators
                HStack(spacing: 8) {
                    if item.wasDelivered {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                    
                    if item.wasInteractedWith {
                        Image(systemName: "hand.tap.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                    
                    PriorityBadge(priority: item.priority)
                }
            }
            
            // Tournament Info
            if !item.tournamentId.isEmpty {
                Text("Tournament: \(item.tournamentId)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 32)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconForType(_ type: TournamentNotificationType) -> String {
        switch type {
        case .tournamentStartingSoon: return "play.circle"
        case .matchReadyPersonalized: return "sportscourt"
        case .bracketUpdatedSmart: return "list.bullet"
        case .performanceInsight: return "chart.bar"
        case .strategicRecommendation: return "lightbulb"
        case .socialEngagement: return "person.3"
        case .tournamentCompleted: return "trophy"
        case .achievementUnlocked: return "star"
        case .friendActivity: return "heart"
        case .trainingRecommendation: return "book"
        }
    }
    
    private func colorForType(_ type: TournamentNotificationType) -> Color {
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
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct PriorityBadge: View {
    let priority: NotificationPriority
    
    var body: some View {
        Text(priority.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(priority.color)
            )
    }
}

struct FilterSheet: View {
    @Binding var selectedFilter: HistoryFilter
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(HistoryFilter.allCases, id: \.self) { filter in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(filter.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(filter.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedFilter == filter {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedFilter = filter
                        dismiss()
                    }
                }
            }
            .navigationTitle("Filter History")
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

// MARK: - Supporting Types

enum HistoryFilter: CaseIterable {
    case all
    case delivered
    case interacted
    case highPriority
    case today
    case thisWeek
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .delivered: return "Delivered"
        case .interacted: return "Interacted"
        case .highPriority: return "High Priority"
        case .today: return "Today"
        case .thisWeek: return "This Week"
        }
    }
    
    var description: String {
        switch self {
        case .all: return "Show all notifications"
        case .delivered: return "Successfully delivered notifications"
        case .interacted: return "Notifications that were tapped or acted upon"
        case .highPriority: return "High and urgent priority notifications"
        case .today: return "Notifications from today"
        case .thisWeek: return "Notifications from this week"
        }
    }
}

// MARK: - Extensions

extension NotificationPriority {
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Med"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

// MARK: - Preview

struct NotificationHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationHistoryView(
            notificationManager: SmartNotificationManager(
                pushService: PushServiceV2(),
                firebaseService: FirebaseService.shared
            )
        )
    }
} 