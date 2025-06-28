import SwiftUI

struct MyTournamentsView: View {
    @StateObject private var viewModel: MyTournamentsViewModel
    @EnvironmentObject private var appState: AppState
    
    init() {
        _viewModel = StateObject(wrappedValue: MyTournamentsViewModel(
            tournamentService: TournamentService(firebaseService: FirebaseService.shared)
        ))
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerSection
                    
                    if viewModel.isLoading {
                        ProgressView("Loading your tournaments...")
                            .frame(maxHeight: .infinity)
                    } else if viewModel.filteredTournaments.isEmpty {
                        emptyStateSection
                    } else {
                        tournamentsList
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.setup(with: appState)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Tournaments")
                        .font(.largeTitle)
                        .fontWeight(.heavy)

                    Text("Track your progress and upcoming matches")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { Task { viewModel.refreshTournaments() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .foregroundColor(viewModel.isLoading ? .gray : .accentColor)
                }
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal)
            
            filterSection
        }
        .padding(.vertical)
        .background(Color(.secondarySystemGroupedBackground).ignoresSafeArea())
    }
    
    private var filterSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search tournaments...", text: $viewModel.searchText)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MyTournamentsViewModel.TournamentStatusFilter.allCases, id: \.self) { filter in
                        MyTournamentFilterChip(
                            title: filter.rawValue,
                            count: viewModel.getFilterCount(filter),
                            isSelected: viewModel.selectedFilter == filter
                        ) {
                            withAnimation(.spring()) {
                                viewModel.selectedFilter = filter
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var tournamentsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredTournaments) { tournament in
                    MyTournamentCard(
                        tournament: tournament,
                        userStatus: viewModel.getUserStatus(for: tournament),
                        onTap: { viewModel.selectTournament(tournament, forDetail: true) },
                        onViewParticipants: { viewModel.selectTournament(tournament, forParticipants: true) },
                        onLeaveTournament: {
                            Task { await viewModel.leaveTournament(tournament) }
                        }
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            viewModel.refreshTournaments()
        }
        .sheet(isPresented: $viewModel.showingTournamentDetail) {
            if let tournament = viewModel.selectedTournament {
                TournamentDetailView(tournament: tournament, tournamentService: viewModel.tournamentService)
                    .environmentObject(appState)
            }
        }
        .sheet(isPresented: $viewModel.showingParticipants) {
            if let tournament = viewModel.selectedTournament {
                TournamentParticipantsView(tournament: tournament)
                    .environmentObject(appState)
            }
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    private var emptyStateSection: some View {
        VStack {
            Spacer()
            Text(viewModel.emptyStateTitle)
                .font(.headline)
            Text(viewModel.emptyStateSubtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button("Find Tournaments") {
                NotificationCenter.default.post(name: .navigateToTournaments, object: nil)
            }
            .padding()
            Spacer()
        }
    }
}

fileprivate struct MyTournamentFilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .padding(6)
                        .background(Circle().fill(isSelected ? Color.white.opacity(0.2) : Color.black.opacity(0.1)))
                }
            }
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

fileprivate struct MyTournamentCard: View {
    let tournament: Tournament
    let userStatus: UserTournamentStatus
    let onTap: () -> Void
    let onViewParticipants: () -> Void
    let onLeaveTournament: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                header
                
                if tournament.status == "In Progress" {
                    progressSection
                } else {
                    detailsSection
                }
                
                footer
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(tournament.name)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(tournament.venueName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            MyTournamentStatusBadge(text: userStatus.description, color: userStatus.color)
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Your Next Match")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("vs. Team Rocket") // Placeholder
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            ProgressView(value: 0.6)
                .progressViewStyle(LinearProgressViewStyle(tint: userStatus.color))
        }
    }
    
    private var detailsSection: some View {
        HStack(spacing: 16) {
            DetailItem(icon: "calendar", text: tournament.startDate.formatted(date: .abbreviated, time: .shortened))
            DetailItem(icon: "person.2.fill", text: "\(tournament.registeredCount)/\(tournament.maxParticipants)")
            DetailItem(icon: "trophy.fill", text: tournament.format)
        }
    }
    
    private var footer: some View {
        HStack {
            Button(action: onViewParticipants) {
                Text("Participants")
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            if !isFinishedOrEliminated() {
                Button(action: onLeaveTournament) {
                    Text("Leave")
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private func isFinishedOrEliminated() -> Bool {
        switch userStatus {
        case .finished, .eliminated:
            return true
        default:
            return false
        }
    }
    
    private func DetailItem(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

fileprivate struct MyTournamentStatusBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
    }
} 