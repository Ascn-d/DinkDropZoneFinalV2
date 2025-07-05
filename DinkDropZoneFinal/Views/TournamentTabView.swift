import SwiftUI

struct TournamentTabView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var tournamentService = TournamentService(firebaseService: FirebaseService.shared)
    
    @State private var selectedTab = 0
    @State private var tournaments: [Tournament] = []
    @State private var myTournaments: [Tournament] = []
    @State private var liveTournaments: [Tournament] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var showCreateTournament = false
    @State private var selectedTournament: Tournament?
    @State private var showTournamentDetail = false
    
    private let tabs = ["Discover", "My Tournaments", "Live"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Tab Bar
                customTabBar
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    // Discover Tab
                    discoverTab
                        .tag(0)
                    
                    // My Tournaments Tab
                    myTournamentsTab
                        .tag(1)
                    
                    // Live Tab
                    liveTab
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
            }
            .navigationTitle("Tournaments")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateTournament = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.brown)
                    }
                }
            }
            .sheet(isPresented: $showCreateTournament) {
                CreateTournamentWizard()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showTournamentDetail) {
                if let tournament = selectedTournament {
                    TournamentDetailView(tournament: tournament, tournamentService: tournamentService)
                        .environmentObject(appState)
                }
            }
        }
        .onAppear {
            loadAllTournaments()
        }
        .refreshable {
            await refreshAllData()
        }
    }
    
    // MARK: - Custom Tab Bar
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: tabIcon(for: index))
                                .font(.system(size: 16, weight: .medium))
                            
                            Text(tabs[index])
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(selectedTab == index ? .brown : .secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedTab == index ? .brown.opacity(0.1) : Color.clear)
                        )
                        
                        // Tab indicator
                        Rectangle()
                            .fill(selectedTab == index ? .brown : Color.clear)
                            .frame(height: 3)
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(.separator.opacity(0.5))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
    
    // MARK: - Discover Tab
    
    private var discoverTab: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search tournaments...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                Button("Filter") {
                    // TODO: Add filter functionality
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.brown)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Tournament List
            if isLoading && tournaments.isEmpty {
                loadingView
            } else if filteredDiscoverTournaments.isEmpty {
                emptyDiscoverView
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredDiscoverTournaments) { tournament in
                            TournamentDiscoverCard(tournament: tournament) {
                                selectedTournament = tournament
                                showTournamentDetail = true
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    // MARK: - My Tournaments Tab
    
    private var myTournamentsTab: some View {
        VStack(spacing: 0) {
            if isLoading && myTournaments.isEmpty {
                loadingView
            } else if myTournaments.isEmpty {
                emptyMyTournamentsView
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(myTournaments) { tournament in
                            MyTournamentCard(tournament: tournament) {
                                selectedTournament = tournament
                                showTournamentDetail = true
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    // MARK: - Live Tab
    
    private var liveTab: some View {
        VStack(spacing: 0) {
            if isLoading && liveTournaments.isEmpty {
                loadingView
            } else if liveTournaments.isEmpty {
                emptyLiveView
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(liveTournaments) { tournament in
                            LiveTournamentCard(tournament: tournament) {
                                selectedTournament = tournament
                                showTournamentDetail = true
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading tournaments...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyDiscoverView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Tournaments Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Try adjusting your search or check back later for new tournaments.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyMyTournamentsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Tournaments Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Join your first tournament from the Discover tab!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                selectedTab = 0
            } label: {
                Text("Discover Tournaments")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.brown)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyLiveView: some View {
        VStack(spacing: 20) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Live Tournaments")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("No tournaments are currently in progress.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Methods
    
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "magnifyingglass.circle.fill"
        case 1: return "person.circle.fill"
        case 2: return "dot.radiowaves.left.and.right"
        default: return "circle"
        }
    }
    
    private var filteredDiscoverTournaments: [Tournament] {
        if searchText.isEmpty {
            return tournaments.filter { tournament in
                // Show tournaments that user hasn't joined
                guard let currentUser = appState.currentUser else { return true }
                return !tournament.participants.contains { $0.userID == currentUser.id.uuidString }
            }
        } else {
            return tournaments.filter { tournament in
                tournament.name.localizedCaseInsensitiveContains(searchText) ||
                tournament.description.localizedCaseInsensitiveContains(searchText) ||
                tournament.venueName.localizedCaseInsensitiveContains(searchText)
            }.filter { tournament in
                // Show tournaments that user hasn't joined
                guard let currentUser = appState.currentUser else { return true }
                return !tournament.participants.contains { $0.userID == currentUser.id.uuidString }
            }
        }
    }
    
    private func loadAllTournaments() {
        guard !isLoading else { return }
        
        isLoading = true
        
        Task {
            do {
                try await tournamentService.loadTournamentsFromFirebase()
                
                await MainActor.run {
                    let allTournaments = tournamentService.getAllTournaments()
                    self.tournaments = allTournaments
                    
                    // Filter my tournaments
                    if let currentUser = appState.currentUser {
                        self.myTournaments = allTournaments.filter { tournament in
                            tournament.participants.contains { $0.userID == currentUser.id.uuidString }
                        }
                    }
                    
                    // Filter live tournaments
                    self.liveTournaments = allTournaments.filter { tournament in
                        tournament.status == "In Progress"
                    }
                    
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("❌ Failed to load tournaments: \(error)")
                    self.isLoading = false
                }
            }
        }
    }
    
    @MainActor
    private func refreshAllData() async {
        do {
            try await tournamentService.loadTournamentsFromFirebase()
            
            let allTournaments = tournamentService.getAllTournaments()
            self.tournaments = allTournaments
            
            // Filter my tournaments
            if let currentUser = appState.currentUser {
                self.myTournaments = allTournaments.filter { tournament in
                    tournament.participants.contains { $0.userID == currentUser.id.uuidString }
                }
            }
            
            // Filter live tournaments
            self.liveTournaments = allTournaments.filter { tournament in
                tournament.status == "In Progress"
            }
        } catch {
            print("❌ Failed to refresh tournaments: \(error)")
        }
    }
}

// MARK: - Tournament Cards

struct TournamentDiscoverCard: View {
    let tournament: Tournament
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tournament.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(tournament.format)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(tournament.participants.count)/\(tournament.maxParticipants)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.brown)
                        
                        Text(tournament.status)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(statusColor.opacity(0.2))
                            .foregroundColor(statusColor)
                            .clipShape(Capsule())
                    }
                }
                
                if !tournament.venueName.isEmpty {
                    HStack {
                        Image(systemName: "location.circle")
                            .foregroundColor(.secondary)
                        
                        Text(tournament.venueName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                HStack {
                    Image(systemName: "calendar.circle")
                        .foregroundColor(.secondary)
                    
                    Text(tournament.startDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Join")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.brown)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.brown.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusColor: Color {
        switch tournament.status {
        case "Registration Open": return .green
        case "Registration Closed": return .orange
        case "In Progress": return .blue
        case "Completed": return .gray
        default: return .secondary
        }
    }
}

struct MyTournamentCard: View {
    let tournament: Tournament
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tournament.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(tournament.format)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(tournament.status)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(statusColor.opacity(0.2))
                            .foregroundColor(statusColor)
                            .clipShape(Capsule())
                        
                        if tournament.status == "In Progress" {
                            Text("Active")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                HStack {
                    Image(systemName: "calendar.circle")
                        .foregroundColor(.secondary)
                    
                    Text(tournament.startDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("View")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusColor: Color {
        switch tournament.status {
        case "Registration Open": return .green
        case "Registration Closed": return .orange
        case "In Progress": return .blue
        case "Completed": return .gray
        default: return .secondary
        }
    }
}

struct LiveTournamentCard: View {
    let tournament: Tournament
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                            .opacity(0.8)
                        
                        Text("LIVE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    Text("\(tournament.participants.count) players")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tournament.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(tournament.format)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "clock.circle")
                        .foregroundColor(.secondary)
                    
                    Text("Started \(tournament.startDate, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Watch")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.red.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.red.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TournamentTabView()
        .environmentObject(AppState())
} 