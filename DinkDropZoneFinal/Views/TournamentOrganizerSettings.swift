import SwiftUI

struct TournamentOrganizerSettings: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    let tournament: Tournament
    
    @State private var tournamentName: String
    @State private var tournamentDescription: String
    @State private var maxParticipants: Int
    @State private var entryFee: Double
    @State private var prizePool: Double
    @State private var isPublic: Bool
    @State private var requiresApproval: Bool
    @State private var allowSpectators: Bool
    @State private var enableLiveStreaming: Bool
    @State private var allowPartnerRequests: Bool
    @State private var autoStartWhenFull: Bool
    @State private var enableRealTimeUpdates: Bool
    @State private var showPlayerRankings: Bool
    @State private var allowPlayerWithdrawal: Bool
    @State private var enablePushNotifications: Bool
    @State private var selectedTemplate: TournamentTemplate
    
    // Advanced Settings
    @State private var maxGamesPerMatch: Int
    @State private var gameToPoints: Int
    @State private var mustWinByTwo: Bool
    @State private var useTimeouts: Bool
    @State private var timeoutDuration: Int
    @State private var matchTimeLimit: Int
    @State private var noShowGracePeriod: Int
    @State private var enableVideoUploads: Bool
    @State private var enableMatchStats: Bool
    @State private var enableSocialSharing: Bool
    
    // Communication Settings
    @State private var allowParticipantChat: Bool
    @State private var moderateChat: Bool
    @State private var enableAnnouncements: Bool
    @State private var sendResultNotifications: Bool
    @State private var sendScheduleUpdates: Bool
    @State private var enableDiscussionBoard: Bool
    
    // Privacy & Security
    @State private var participantListVisibility: ParticipantVisibility
    @State private var requireEmailVerification: Bool
    @State private var enableUserBlocking: Bool
    @State private var reportingEnabled: Bool
    @State private var dataRetentionDays: Int
    
    // Tournament Management
    @State private var enableWaitingList: Bool
    @State private var waitingListSize: Int
    @State private var enableSubstitutions: Bool
    @State private var substitutionDeadline: Date
    @State private var enableLatecomerJoining: Bool
    @State private var lateJoinDeadline: Date
    
    @State private var isLoading = false
    @State private var showingDeleteConfirmation = false
    @State private var showingResetConfirmation = false
    @State private var showingAdvancedSettings = false
    @State private var showingTemplateSelector = false
    @State private var hasUnsavedChanges = false
    
    enum ParticipantVisibility: String, CaseIterable {
        case `public` = "Public"
        case participantsOnly = "Participants Only"
        case organizerOnly = "Organizer Only"
        case hidden = "Hidden"
    }
    
    enum TournamentTemplate: String, CaseIterable {
        case standard = "Standard Tournament"
        case quickPlay = "Quick Play"
        case professional = "Professional"
        case community = "Community Event"
        case charity = "Charity Tournament"
        case custom = "Custom"
        
        var description: String {
            switch self {
            case .standard: return "Standard tournament settings with common configurations"
            case .quickPlay: return "Fast-paced tournament with shorter matches"
            case .professional: return "Professional-level tournament with advanced features"
            case .community: return "Community-focused tournament with social features"
            case .charity: return "Charity tournament with fundraising features"
            case .custom: return "Fully customizable tournament settings"
            }
        }
    }
    
    init(tournament: Tournament) {
        self.tournament = tournament
        self._tournamentName = State(initialValue: tournament.name)
        self._tournamentDescription = State(initialValue: tournament.description)
        self._maxParticipants = State(initialValue: tournament.maxParticipants)
        self._entryFee = State(initialValue: tournament.entryFee)
        self._prizePool = State(initialValue: tournament.prizePool)
        self._isPublic = State(initialValue: tournament.isPublic)
        self._requiresApproval = State(initialValue: tournament.requiresApproval)
        self._allowSpectators = State(initialValue: tournament.allowSpectators)
        self._enableLiveStreaming = State(initialValue: tournament.enableLiveStreaming)
        self._allowPartnerRequests = State(initialValue: tournament.allowPartnerRequests)
        self._autoStartWhenFull = State(initialValue: tournament.autoStartWhenFull)
        self._enableRealTimeUpdates = State(initialValue: tournament.enableRealTimeUpdates)
        self._showPlayerRankings = State(initialValue: tournament.showPlayerRankings)
        self._allowPlayerWithdrawal = State(initialValue: tournament.allowPlayerWithdrawal)
        self._enablePushNotifications = State(initialValue: tournament.enablePushNotifications)
        self._selectedTemplate = State(initialValue: .standard)
        
        // Initialize advanced settings with defaults
        self._maxGamesPerMatch = State(initialValue: 3)
        self._gameToPoints = State(initialValue: 11)
        self._mustWinByTwo = State(initialValue: true)
        self._useTimeouts = State(initialValue: true)
        self._timeoutDuration = State(initialValue: 60)
        self._matchTimeLimit = State(initialValue: 30)
        self._noShowGracePeriod = State(initialValue: 15)
        self._enableVideoUploads = State(initialValue: false)
        self._enableMatchStats = State(initialValue: true)
        self._enableSocialSharing = State(initialValue: true)
        
        // Initialize communication settings
        self._allowParticipantChat = State(initialValue: true)
        self._moderateChat = State(initialValue: false)
        self._enableAnnouncements = State(initialValue: true)
        self._sendResultNotifications = State(initialValue: true)
        self._sendScheduleUpdates = State(initialValue: true)
        self._enableDiscussionBoard = State(initialValue: false)
        
        // Initialize privacy settings
        self._participantListVisibility = State(initialValue: .public)
        self._requireEmailVerification = State(initialValue: false)
        self._enableUserBlocking = State(initialValue: true)
        self._reportingEnabled = State(initialValue: true)
        self._dataRetentionDays = State(initialValue: 365)
        
        // Initialize management settings
        self._enableWaitingList = State(initialValue: true)
        self._waitingListSize = State(initialValue: 10)
        self._enableSubstitutions = State(initialValue: true)
        self._substitutionDeadline = State(initialValue: Date())
        self._enableLatecomerJoining = State(initialValue: false)
        self._lateJoinDeadline = State(initialValue: Date())
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Tournament Template Selector
                        templateSection
                        
                        // Basic Settings
                        basicSettingsSection
                        
                        // Tournament Rules
                        rulesSection
                        
                        // Features & Functionality
                        featuresSection
                        
                        // Communication Settings
                        communicationSection
                        
                        // Privacy & Security
                        privacySection
                        
                        // Tournament Management
                        managementSection
                        
                        // Advanced Settings
                        if showingAdvancedSettings {
                            advancedSettingsSection
                        }
                        
                        // Action Buttons
                        actionButtonsSection
                        
                        // Danger Zone
                        dangerZoneSection
                    }
                }
                
                if isLoading {
                    loadingOverlay
                }
            }
            .navigationTitle("Tournament Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    handleCancel()
                },
                trailing: Button("Save") {
                    Task {
                        await saveSettings()
                    }
                }
                .disabled(isLoading)
                .fontWeight(.semibold)
            )
            .onChange(of: tournamentName) { _ in hasUnsavedChanges = true }
            .onChange(of: tournamentDescription) { _ in hasUnsavedChanges = true }
            .onChange(of: maxParticipants) { _ in hasUnsavedChanges = true }
            .onChange(of: entryFee) { _ in hasUnsavedChanges = true }
            .onChange(of: prizePool) { _ in hasUnsavedChanges = true }
            .onChange(of: isPublic) { _ in hasUnsavedChanges = true }
            .onChange(of: requiresApproval) { _ in hasUnsavedChanges = true }
            .onChange(of: allowSpectators) { _ in hasUnsavedChanges = true }
            .onChange(of: enableLiveStreaming) { _ in hasUnsavedChanges = true }
            .onChange(of: allowPartnerRequests) { _ in hasUnsavedChanges = true }
            .onChange(of: autoStartWhenFull) { _ in hasUnsavedChanges = true }
            .onChange(of: enableRealTimeUpdates) { _ in hasUnsavedChanges = true }
            .onChange(of: showPlayerRankings) { _ in hasUnsavedChanges = true }
            .onChange(of: allowPlayerWithdrawal) { _ in hasUnsavedChanges = true }
            .onChange(of: enablePushNotifications) { _ in hasUnsavedChanges = true }
            .alert("Unsaved Changes", isPresented: .constant(hasUnsavedChanges && !isLoading)) {
                Button("Save") {
                    Task {
                        await saveSettings()
                    }
                }
                Button("Discard", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("You have unsaved changes. Would you like to save them before leaving?")
            }
            .alert("Delete Tournament", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteTournament()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this tournament? This action cannot be undone.")
            }
            .alert("Reset Settings", isPresented: $showingResetConfirmation) {
                Button("Reset", role: .destructive) {
                    resetToDefaults()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to reset all settings to defaults? This will lose all customizations.")
            }
            .sheet(isPresented: $showingTemplateSelector) {
                TournamentTemplateSelector(selectedTemplate: $selectedTemplate)
            }
        }
    }
    
    // MARK: - Template Section
    
    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tournament Template")
                .font(.headline)
                .fontWeight(.semibold)
            
            Button(action: {
                showingTemplateSelector = true
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedTemplate.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(selectedTemplate.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
        .padding(.top)
    }
    
    // MARK: - Basic Settings Section
    
    private var basicSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Tournament Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tournament Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("Enter tournament name", text: $tournamentName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Tournament Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("Enter tournament description", text: $tournamentDescription, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                // Max Participants
                VStack(alignment: .leading, spacing: 8) {
                    Text("Maximum Participants")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        TextField("Max participants", value: $maxParticipants, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Stepper("", value: $maxParticipants, in: 4...128, step: 2)
                    }
                }
                
                // Entry Fee
                VStack(alignment: .leading, spacing: 8) {
                    Text("Entry Fee")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        
                        TextField("0.00", value: $entryFee, format: .currency(code: "USD"))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                // Prize Pool
                VStack(alignment: .leading, spacing: 8) {
                    Text("Prize Pool")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        
                        TextField("0.00", value: $prizePool, format: .currency(code: "USD"))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - Rules Section
    
    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tournament Rules")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Games per Match
                HStack {
                    Text("Games per Match")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Picker("Games per Match", selection: $maxGamesPerMatch) {
                        ForEach(1...5, id: \.self) { games in
                            Text("\(games)").tag(games)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 150)
                }
                
                // Points per Game
                HStack {
                    Text("Points per Game")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Picker("Points per Game", selection: $gameToPoints) {
                        ForEach([11, 15, 21], id: \.self) { points in
                            Text("\(points)").tag(points)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 150)
                }
                
                // Win by Two
                Toggle("Must Win by Two", isOn: $mustWinByTwo)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                // Timeouts
                Toggle("Allow Timeouts", isOn: $useTimeouts)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if useTimeouts {
                    HStack {
                        Text("Timeout Duration")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        HStack {
                            TextField("60", value: $timeoutDuration, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                            
                            Text("seconds")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Match Time Limit
                HStack {
                    Text("Match Time Limit")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    HStack {
                        TextField("30", value: $matchTimeLimit, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                        
                        Text("minutes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // No Show Grace Period
                HStack {
                    Text("No-Show Grace Period")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    HStack {
                        TextField("15", value: $noShowGracePeriod, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                        
                        Text("minutes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Features & Functionality")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                Toggle("Public Tournament", isOn: $isPublic)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Toggle("Requires Approval", isOn: $requiresApproval)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Toggle("Allow Spectators", isOn: $allowSpectators)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Toggle("Enable Live Streaming", isOn: $enableLiveStreaming)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Toggle("Allow Partner Requests", isOn: $allowPartnerRequests)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Toggle("Auto-Start When Full", isOn: $autoStartWhenFull)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Toggle("Real-Time Updates", isOn: $enableRealTimeUpdates)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Toggle("Show Player Rankings", isOn: $showPlayerRankings)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Toggle("Allow Player Withdrawal", isOn: $allowPlayerWithdrawal)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Toggle("Push Notifications", isOn: $enablePushNotifications)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - Communication Section
    
    private var communicationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Communication Settings")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                Toggle("Participant Chat", isOn: $allowParticipantChat)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if allowParticipantChat {
                    Toggle("Moderate Chat", isOn: $moderateChat)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.leading)
                }
                
                Toggle("Tournament Announcements", isOn: $enableAnnouncements)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Toggle("Result Notifications", isOn: $sendResultNotifications)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Toggle("Schedule Updates", isOn: $sendScheduleUpdates)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Toggle("Discussion Board", isOn: $enableDiscussionBoard)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - Privacy Section
    
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Privacy & Security")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Participant List Visibility
                VStack(alignment: .leading, spacing: 8) {
                    Text("Participant List Visibility")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Participant List Visibility", selection: $participantListVisibility) {
                        ForEach(ParticipantVisibility.allCases, id: \.self) { visibility in
                            Text(visibility.rawValue).tag(visibility)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Toggle("Require Email Verification", isOn: $requireEmailVerification)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Toggle("Enable User Blocking", isOn: $enableUserBlocking)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Toggle("Reporting System", isOn: $reportingEnabled)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                // Data Retention
                HStack {
                    Text("Data Retention")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    HStack {
                        TextField("365", value: $dataRetentionDays, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                        
                        Text("days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - Management Section
    
    private var managementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tournament Management")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                Toggle("Enable Waiting List", isOn: $enableWaitingList)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if enableWaitingList {
                    HStack {
                        Text("Waiting List Size")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        HStack {
                            TextField("10", value: $waitingListSize, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                            
                            Text("participants")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.leading)
                }
                
                Toggle("Enable Substitutions", isOn: $enableSubstitutions)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if enableSubstitutions {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Substitution Deadline")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        DatePicker("", selection: $substitutionDeadline, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                    .padding(.leading)
                }
                
                Toggle("Allow Latecomer Joining", isOn: $enableLatecomerJoining)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if enableLatecomerJoining {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Late Join Deadline")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        DatePicker("", selection: $lateJoinDeadline, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                    .padding(.leading)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - Advanced Settings Section
    
    private var advancedSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Advanced Settings")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                Toggle("Enable Video Uploads", isOn: $enableVideoUploads)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Toggle("Enable Match Statistics", isOn: $enableMatchStats)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Toggle("Enable Social Sharing", isOn: $enableSocialSharing)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Show/Hide Advanced Settings
            Button(action: {
                withAnimation {
                    showingAdvancedSettings.toggle()
                }
            }) {
                HStack {
                    Image(systemName: showingAdvancedSettings ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                    
                    Text(showingAdvancedSettings ? "Hide Advanced Settings" : "Show Advanced Settings")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Reset to Defaults
            Button(action: {
                showingResetConfirmation = true
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                    
                    Text("Reset to Defaults")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal)
    }
    
    // MARK: - Danger Zone Section
    
    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Danger Zone")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.red)
            
            VStack(spacing: 12) {
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 14, weight: .medium))
                        
                        Text("Delete Tournament")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                    .padding()
                    .background(.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                Text("This action cannot be undone. All tournament data will be permanently deleted.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
        .padding(.bottom, 24)
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    Text("Saving Settings...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            )
    }
    
    // MARK: - Helper Methods
    
    private func handleCancel() {
        if hasUnsavedChanges {
            // Show confirmation dialog
            return
        }
        dismiss()
    }
    
    private func saveSettings() async {
        isLoading = true
        
        // Simulate saving to Firebase
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Here you would update the tournament in Firebase
        // await appState.updateTournament(updatedTournament)
        
        hasUnsavedChanges = false
        isLoading = false
        dismiss()
    }
    
    private func resetToDefaults() {
        // Reset all settings to default values
        maxParticipants = 32
        entryFee = 0.0
        prizePool = 0.0
        isPublic = true
        requiresApproval = false
        allowSpectators = true
        enableLiveStreaming = false
        allowPartnerRequests = true
        autoStartWhenFull = false
        enableRealTimeUpdates = true
        showPlayerRankings = true
        allowPlayerWithdrawal = true
        enablePushNotifications = true
        
        maxGamesPerMatch = 3
        gameToPoints = 11
        mustWinByTwo = true
        useTimeouts = true
        timeoutDuration = 60
        matchTimeLimit = 30
        noShowGracePeriod = 15
        
        allowParticipantChat = true
        moderateChat = false
        enableAnnouncements = true
        sendResultNotifications = true
        sendScheduleUpdates = true
        enableDiscussionBoard = false
        
        participantListVisibility = .public
        requireEmailVerification = false
        enableUserBlocking = true
        reportingEnabled = true
        dataRetentionDays = 365
        
        enableWaitingList = true
        waitingListSize = 10
        enableSubstitutions = true
        enableLatecomerJoining = false
        
        enableVideoUploads = false
        enableMatchStats = true
        enableSocialSharing = true
        
        hasUnsavedChanges = true
    }
    
    private func deleteTournament() {
        // Implement tournament deletion
        // This would call the Firebase service to delete the tournament
        dismiss()
    }
}

// MARK: - Template Selector Sheet

struct TournamentTemplateSelector: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTemplate: TournamentOrganizerSettings.TournamentTemplate
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ForEach(TournamentOrganizerSettings.TournamentTemplate.allCases, id: \.self) { template in
                    Button(action: {
                        selectedTemplate = template
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text(template.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if template == selectedTemplate {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding()
                        .background(template == selectedTemplate ? Color.accentColor.opacity(0.1) : .clear)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider()
                }
                
                Spacer()
            }
            .navigationTitle("Select Template")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
    }
}

// MARK: - Preview

struct TournamentOrganizerSettings_Previews: PreviewProvider {
    static var previews: some View {
        TournamentOrganizerSettings(tournament: Tournament.sampleTournament)
            .environmentObject(AppState())
    }
} 