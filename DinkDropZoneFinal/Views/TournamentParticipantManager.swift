import SwiftUI

struct TournamentParticipantManager: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    let tournament: Tournament
    
    @State private var participants: [TournamentParticipant] = []
    @State private var waitingList: [TournamentParticipant] = []
    @State private var searchText = ""
    @State private var selectedFilter: ParticipantFilter = .all
    @State private var showingInviteSheet = false
    @State private var showingBulkActions = false
    @State private var selectedParticipants: Set<String> = []
    @State private var showingParticipantDetail = false
    @State private var selectedParticipant: TournamentParticipant?
    @State private var isLoading = false
    
    enum ParticipantFilter: String, CaseIterable {
        case all = "All"
        case registered = "Registered"
        case approved = "Approved"
        case pending = "Pending"
        case waitingList = "Waiting List"
        case checkedIn = "Checked In"
        case noShow = "No Show"
        
        var systemImage: String {
            switch self {
            case .all: return "person.2.fill"
            case .registered: return "person.badge.plus"
            case .approved: return "person.badge.checkmark"
            case .pending: return "person.badge.clock"
            case .waitingList: return "person.badge.minus"
            case .checkedIn: return "person.badge.checkmark"
            case .noShow: return "person.badge.questionmark"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with stats
                participantStatsHeader
                
                // Filter tabs
                filterTabs
                
                // Search bar
                searchSection
                
                // Participant list
                participantListSection
                
                // Bottom action bar
                if !selectedParticipants.isEmpty {
                    bottomActionBar
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Participants")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Close") {
                    dismiss()
                },
                trailing: HStack {
                    if selectedParticipants.isEmpty {
                        Button(action: {
                            showingInviteSheet = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                        }
                        
                        Button(action: {
                            showingBulkActions = true
                        }) {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.system(size: 18))
                        }
                    } else {
                        Button("Cancel") {
                            selectedParticipants.removeAll()
                        }
                    }
                }
            )
            .onAppear {
                loadParticipants()
            }
            .sheet(isPresented: $showingInviteSheet) {
                ParticipantInviteSheet(tournament: tournament)
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showingParticipantDetail) {
                if let participant = selectedParticipant {
                    ParticipantDetailSheet(participant: participant, tournament: tournament)
                        .environmentObject(appState)
                }
            }
            .actionSheet(isPresented: $showingBulkActions) {
                ActionSheet(
                    title: Text("Bulk Actions"),
                    message: Text("Choose an action for all participants"),
                    buttons: [
                        .default(Text("Send Message")) {
                            sendBulkMessage()
                        },
                        .default(Text("Check In All")) {
                            checkInAll()
                        },
                        .default(Text("Export List")) {
                            exportParticipantList()
                        },
                        .cancel()
                    ]
                )
            }
        }
    }
    
    // MARK: - Participant Stats Header
    
    private var participantStatsHeader: some View {
        HStack(spacing: 20) {
            statCard(
                title: "Total",
                value: "\(participants.count)",
                color: .blue,
                icon: "person.2.fill"
            )
            
            statCard(
                title: "Registered",
                value: "\(getParticipantCount(for: .registered))",
                color: .green,
                icon: "person.badge.plus"
            )
            
            statCard(
                title: "Waiting",
                value: "\(getParticipantCount(for: .waitingList))",
                color: .orange,
                icon: "person.badge.minus"
            )
            
            statCard(
                title: "Checked In",
                value: "\(getParticipantCount(for: .checkedIn))",
                color: .purple,
                icon: "person.badge.checkmark"
            )
        }
        .padding()
        .background(.regularMaterial)
    }
    
    private func statCard(title: String, value: String, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Filter Tabs
    
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(ParticipantFilter.allCases, id: \.self) { filter in
                    filterTab(filter)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private func filterTab(_ filter: ParticipantFilter) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFilter = filter
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: filter.systemImage)
                    .font(.system(size: 12, weight: .medium))
                
                Text(filter.rawValue)
                    .font(.system(size: 14, weight: .medium))
                
                let count = getParticipantCount(for: filter)
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(selectedFilter == filter ? .white : .secondary)
                        .foregroundColor(selectedFilter == filter ? .blue : .white)
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selectedFilter == filter ? .blue : .clear)
            .foregroundColor(selectedFilter == filter ? .white : .primary)
            .cornerRadius(8)
        }
    }
    
    // MARK: - Search Section
    
    private var searchSection: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search participants...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(.regularMaterial)
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Participant List Section
    
    private var participantListSection: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredParticipants, id: \.id) { participant in
                    participantRow(participant)
                        .onTapGesture {
                            if selectedParticipants.isEmpty {
                                selectedParticipant = participant
                                showingParticipantDetail = true
                            } else {
                                toggleSelection(participant)
                            }
                        }
                        .onLongPressGesture {
                            toggleSelection(participant)
                        }
                }
            }
        }
        .background(Color(.systemBackground))
    }
    
    private func participantRow(_ participant: TournamentParticipant) -> some View {
        HStack(spacing: 12) {
            // Selection indicator
            if !selectedParticipants.isEmpty {
                Button(action: {
                    toggleSelection(participant)
                }) {
                    Image(systemName: selectedParticipants.contains(participant.id.uuidString) ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                }
            }
            
            // Profile image placeholder
            Circle()
                .fill(getParticipantColor(participant).opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(participant.displayName.prefix(1))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(getParticipantColor(participant))
                )
            
            // Participant info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(participant.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    statusBadge(participant)
                }
                
                HStack {
                    Text("ELO: \(participant.elo)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let registrationDate = participant.registrationDate {
                        Text(registrationDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Action buttons
            if selectedParticipants.isEmpty {
                HStack(spacing: 8) {
                    if participant.status == "Pending" {
                        Button(action: {
                            approveParticipant(participant)
                        }) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                        }
                        
                        Button(action: {
                            rejectParticipant(participant)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.red)
                        }
                    } else if participant.status == "Registered" {
                        Button(action: {
                            checkInParticipant(participant)
                        }) {
                            Image(systemName: "person.badge.checkmark")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .padding()
        .background(selectedParticipants.contains(participant.id.uuidString) ? Color.blue.opacity(0.1) : .clear)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func statusBadge(_ participant: TournamentParticipant) -> some View {
        Text(participant.status.uppercased())
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(getStatusColor(participant.status))
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    // MARK: - Bottom Action Bar
    
    private var bottomActionBar: some View {
        HStack(spacing: 16) {
            Text("\(selectedParticipants.count) selected")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Button("Message") {
                messageSelected()
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Button("Check In") {
                checkInSelected()
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Button("Remove") {
                removeSelected()
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.red)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Helper Methods
    
    private func loadParticipants() {
        participants = tournament.participants
        // Load waiting list if available
        waitingList = [] // Would be loaded from Firebase
    }
    
    private var filteredParticipants: [TournamentParticipant] {
        var filtered = participants
        
        // Apply status filter
        switch selectedFilter {
        case .all:
            break
        case .registered:
            filtered = filtered.filter { $0.status == "Registered" }
        case .approved:
            filtered = filtered.filter { $0.status == "Approved" }
        case .pending:
            filtered = filtered.filter { $0.status == "Pending" }
        case .waitingList:
            filtered = waitingList
        case .checkedIn:
            filtered = filtered.filter { $0.status == "Checked In" }
        case .noShow:
            filtered = filtered.filter { $0.status == "No Show" }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { participant in
                participant.displayName.localizedCaseInsensitiveContains(searchText) ||
                participant.userID.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    private func getParticipantCount(for filter: ParticipantFilter) -> Int {
        switch filter {
        case .all:
            return participants.count
        case .registered:
            return participants.filter { $0.status == "Registered" }.count
        case .approved:
            return participants.filter { $0.status == "Approved" }.count
        case .pending:
            return participants.filter { $0.status == "Pending" }.count
        case .waitingList:
            return waitingList.count
        case .checkedIn:
            return participants.filter { $0.status == "Checked In" }.count
        case .noShow:
            return participants.filter { $0.status == "No Show" }.count
        }
    }
    
    private func getParticipantColor(_ participant: TournamentParticipant) -> Color {
        switch participant.status {
        case "Registered": return .green
        case "Approved": return .blue
        case "Pending": return .orange
        case "Checked In": return .purple
        case "No Show": return .red
        default: return .gray
        }
    }
    
    private func getStatusColor(_ status: String) -> Color {
        switch status {
        case "Registered": return .green
        case "Approved": return .blue
        case "Pending": return .orange
        case "Checked In": return .purple
        case "No Show": return .red
        default: return .gray
        }
    }
    
    private func toggleSelection(_ participant: TournamentParticipant) {
        let participantId = participant.id.uuidString
        if selectedParticipants.contains(participantId) {
            selectedParticipants.remove(participantId)
        } else {
            selectedParticipants.insert(participantId)
        }
    }
    
    private func approveParticipant(_ participant: TournamentParticipant) {
        // Implement approval logic
        print("Approving participant: \(participant.displayName)")
    }
    
    private func rejectParticipant(_ participant: TournamentParticipant) {
        // Implement rejection logic
        print("Rejecting participant: \(participant.displayName)")
    }
    
    private func checkInParticipant(_ participant: TournamentParticipant) {
        // Implement check-in logic
        print("Checking in participant: \(participant.displayName)")
    }
    
    private func sendBulkMessage() {
        // Implement bulk messaging
        print("Sending bulk message to all participants")
    }
    
    private func checkInAll() {
        // Implement bulk check-in
        print("Checking in all participants")
    }
    
    private func exportParticipantList() {
        // Implement export functionality
        print("Exporting participant list")
    }
    
    private func messageSelected() {
        // Implement messaging selected participants
        print("Messaging \(selectedParticipants.count) selected participants")
        selectedParticipants.removeAll()
    }
    
    private func checkInSelected() {
        // Implement check-in for selected participants
        print("Checking in \(selectedParticipants.count) selected participants")
        selectedParticipants.removeAll()
    }
    
    private func removeSelected() {
        // Implement removal of selected participants
        print("Removing \(selectedParticipants.count) selected participants")
        selectedParticipants.removeAll()
    }
}

// MARK: - Participant Invite Sheet

struct ParticipantInviteSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    let tournament: Tournament
    
    @State private var inviteMethod: InviteMethod = .email
    @State private var emailAddresses = ""
    @State private var shareLink = ""
    @State private var customMessage = ""
    @State private var isGeneratingLink = false
    
    enum InviteMethod: String, CaseIterable {
        case email = "Email"
        case link = "Share Link"
        case qr = "QR Code"
        
        var icon: String {
            switch self {
            case .email: return "envelope.fill"
            case .link: return "link"
            case .qr: return "qrcode"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Invite method selector
                Picker("Invite Method", selection: $inviteMethod) {
                    ForEach(InviteMethod.allCases, id: \.self) { method in
                        HStack {
                            Image(systemName: method.icon)
                            Text(method.rawValue)
                        }
                        .tag(method)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                // Method-specific content
                Group {
                    switch inviteMethod {
                    case .email:
                        emailInviteSection
                    case .link:
                        linkInviteSection
                    case .qr:
                        qrInviteSection
                    }
                }
                
                // Custom message
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom Message (Optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("Add a personal message...", text: $customMessage, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                Spacer()
                
                // Send button
                Button("Send Invites") {
                    sendInvites()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .cornerRadius(12)
            }
            .padding()
            .navigationTitle("Invite Participants")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
        }
    }
    
    private var emailInviteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email Addresses")
                .font(.subheadline)
                .fontWeight(.medium)
            
            TextField("Enter email addresses separated by commas", text: $emailAddresses, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
            
            Text("Separate multiple email addresses with commas")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var linkInviteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Share Link")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                TextField("Tournament invite link", text: $shareLink)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(true)
                
                Button(isGeneratingLink ? "Generating..." : "Generate") {
                    generateShareLink()
                }
                .disabled(isGeneratingLink)
            }
            
            if !shareLink.isEmpty {
                Button("Copy Link") {
                    UIPasteboard.general.string = shareLink
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }
    
    private var qrInviteSection: some View {
        VStack(spacing: 16) {
            Text("QR Code")
                .font(.subheadline)
                .fontWeight(.medium)
            
            // QR Code placeholder
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 200, height: 200)
                .cornerRadius(12)
                .overlay(
                    VStack {
                        Image(systemName: "qrcode")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("QR Code")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                )
            
            Button("Generate QR Code") {
                generateQRCode()
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
    }
    
    private func sendInvites() {
        // Implement invite sending logic
        print("Sending invites via \(inviteMethod.rawValue)")
        dismiss()
    }
    
    private func generateShareLink() {
        isGeneratingLink = true
        
        // Simulate link generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            shareLink = "https://dinkdropzone.com/tournament/\(tournament.id.uuidString)"
            isGeneratingLink = false
        }
    }
    
    private func generateQRCode() {
        // Implement QR code generation
        print("Generating QR code for tournament")
    }
}

// MARK: - Participant Detail Sheet

struct ParticipantDetailSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    let participant: TournamentParticipant
    let tournament: Tournament
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    VStack(spacing: 16) {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(participant.displayName.prefix(1))
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.blue)
                            )
                        
                        Text(participant.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("ELO: \(participant.elo)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Status and actions
                    VStack(spacing: 16) {
                        HStack {
                            Text("Status:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text(participant.status)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                        }
                        
                        if let registrationDate = participant.registrationDate {
                            HStack {
                                Text("Registered:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Text(registrationDate.formatted(date: .abbreviated, time: .shortened))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button("Send Message") {
                            // Implement messaging
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        
                        Button("View Match History") {
                            // Implement match history
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.secondary.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Participant Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Close") {
                    dismiss()
                }
            )
        }
    }
}

// MARK: - Preview

struct TournamentParticipantManager_Previews: PreviewProvider {
    static var previews: some View {
        TournamentParticipantManager(tournament: Tournament.sampleTournament)
            .environmentObject(AppState())
    }
} 