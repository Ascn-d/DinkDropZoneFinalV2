import SwiftUI

struct TournamentMessageComposer: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    let tournament: Tournament
    
    @State private var messageText = ""
    @State private var selectedRecipients: Set<String> = []
    @State private var messageType: MessageType = .announcement
    @State private var isUrgent = false
    @State private var scheduleForLater = false
    @State private var scheduledDate = Date()
    @State private var isSending = false
    
    enum MessageType: String, CaseIterable {
        case announcement = "Announcement"
        case scheduleUpdate = "Schedule Update"
        case reminder = "Reminder"
        case congratulations = "Congratulations"
        case custom = "Custom"
        
        var icon: String {
            switch self {
            case .announcement: return "megaphone.fill"
            case .scheduleUpdate: return "calendar.badge.clock"
            case .reminder: return "bell.fill"
            case .congratulations: return "trophy.fill"
            case .custom: return "text.bubble.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Message type selector
                messageTypeSelector
                
                // Recipients section
                recipientsSection
                
                // Message composition area
                messageCompositionArea
                
                // Options section
                optionsSection
                
                Spacer()
                
                // Send button
                sendButton
            }
            .padding()
            .navigationTitle("Send Message")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Templates") {
                    // Show message templates
                }
            )
            .disabled(isSending)
        }
    }
    
    private var messageTypeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Message Type")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MessageType.allCases, id: \.self) { type in
                        Button(action: {
                            messageType = type
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 12))
                                
                                Text(type.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(messageType == type ? .blue : .secondary.opacity(0.1))
                            .foregroundColor(messageType == type ? .white : .primary)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.bottom, 20)
    }
    
    private var recipientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recipients")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                Button(action: {
                    toggleAllParticipants()
                }) {
                    HStack {
                        Image(systemName: selectedRecipients.count == tournament.participants.count ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(.blue)
                        
                        Text("All Participants (\(tournament.participants.count))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(tournament.participants.prefix(5), id: \.id) { participant in
                            participantRow(participant)
                        }
                        
                        if tournament.participants.count > 5 {
                            Text("+ \(tournament.participants.count - 5) more participants")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxHeight: 150)
            }
        }
        .padding(.bottom, 20)
    }
    
    private func participantRow(_ participant: TournamentParticipant) -> some View {
        Button(action: {
            toggleParticipant(participant)
        }) {
            HStack {
                Image(systemName: selectedRecipients.contains(participant.id.uuidString) ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(.blue)
                
                Text(participant.displayName)
                    .font(.subheadline)
                
                Spacer()
                
                Text("ELO: \(participant.elo)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var messageCompositionArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Message")
                .font(.headline)
                .fontWeight(.semibold)
            
            TextField("Type your message here...", text: $messageText, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(5...10)
            
            Text("\(messageText.count)/500 characters")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 20)
    }
    
    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Options")
                .font(.headline)
                .fontWeight(.semibold)
            
            Toggle("Mark as Urgent", isOn: $isUrgent)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Toggle("Schedule for Later", isOn: $scheduleForLater)
                .font(.subheadline)
                .fontWeight(.medium)
            
            if scheduleForLater {
                DatePicker("Send at:", selection: $scheduledDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(CompactDatePickerStyle())
                    .padding(.leading)
            }
        }
        .padding(.bottom, 20)
    }
    
    private var sendButton: some View {
        Button(action: {
            sendMessage()
        }) {
            HStack {
                if isSending {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(isSending ? "Sending..." : "Send Message")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(canSendMessage ? .blue : .secondary.opacity(0.5))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!canSendMessage || isSending)
    }
    
    private var canSendMessage: Bool {
        !messageText.isEmpty && !selectedRecipients.isEmpty
    }
    
    private func toggleAllParticipants() {
        if selectedRecipients.count == tournament.participants.count {
            selectedRecipients.removeAll()
        } else {
            selectedRecipients = Set(tournament.participants.map { $0.id.uuidString })
        }
    }
    
    private func toggleParticipant(_ participant: TournamentParticipant) {
        let participantId = participant.id.uuidString
        if selectedRecipients.contains(participantId) {
            selectedRecipients.remove(participantId)
        } else {
            selectedRecipients.insert(participantId)
        }
    }
    
    private func sendMessage() {
        isSending = true
        
        // Simulate sending message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSending = false
            dismiss()
        }
    }
}

struct TournamentPrizeManager: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    let tournament: Tournament
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Prize Management")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Coming Soon")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Prize pool management and distribution features will be available in a future update.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .cornerRadius(12)
            }
            .padding()
            .navigationTitle("Prize Management")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct TournamentAnalyticsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    let tournament: Tournament
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Tournament Analytics")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Coming Soon")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Detailed analytics and insights about your tournament performance will be available in a future update.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .cornerRadius(12)
            }
            .padding()
            .navigationTitle("Tournament Analytics")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct OrganizerNotificationCenter: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var notifications: [OrganizerNotification]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Notifications")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if notifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No notifications")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("You're all caught up!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(notifications, id: \.id) { notification in
                                notificationRow(notification)
                            }
                        }
                    }
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .cornerRadius(12)
            }
            .padding()
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func notificationRow(_ notification: OrganizerNotification) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(notification.type.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(notification.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(notification.timestamp.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Preview

struct TournamentMessageComposer_Previews: PreviewProvider {
    static var previews: some View {
        TournamentMessageComposer(tournament: Tournament.sampleTournament)
            .environmentObject(AppState())
    }
} 