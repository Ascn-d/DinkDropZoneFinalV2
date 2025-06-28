import SwiftUI
import Combine

@MainActor
class MyTournamentsViewModel: ObservableObject {
    @Published var myTournaments: [Tournament] = []
    @Published var isLoading = true
    @Published var selectedFilter: TournamentStatusFilter = .all
    @Published var searchText = ""
    @Published var errorMessage = ""
    @Published var showingError = false
    @Published var selectedTournament: Tournament?
    @Published var showingTournamentDetail = false
    @Published var showingParticipants = false
    
    let tournamentService: TournamentService
    private var appState: AppState?
    private var cancellables = Set<AnyCancellable>()

    init(tournamentService: TournamentService) {
        self.tournamentService = tournamentService
    }
    
    func setup(with appState: AppState) {
        self.appState = appState
        loadMyTournaments()
        
        // Observe changes to myTournaments
        $myTournaments
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var filteredTournaments: [Tournament] {
        let filteredByStatus: [Tournament]
        switch selectedFilter {
        case .all:
            filteredByStatus = myTournaments
        case .active:
            filteredByStatus = myTournaments.filter { $0.status == "In Progress" }
        case .upcoming:
            filteredByStatus = myTournaments.filter { $0.status == "Registration Open" || $0.status == "Registration Closed" }
        case .completed:
            filteredByStatus = myTournaments.filter { $0.status == "Completed" }
        }

        if searchText.isEmpty {
            return filteredByStatus
        } else {
            return filteredByStatus.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    func getFilterCount(_ filter: TournamentStatusFilter) -> Int {
        switch filter {
        case .all:
            return myTournaments.count
        case .active:
            return myTournaments.filter { $0.status == "In Progress" }.count
        case .upcoming:
            return myTournaments.filter { $0.status == "Registration Open" || $0.status == "Registration Closed" }.count
        case .completed:
            return myTournaments.filter { $0.status == "Completed" }.count
        }
    }
    
    var emptyStateTitle: String {
        return "No Tournaments" // Placeholder
    }
    
    var emptyStateSubtitle: String {
        return "Join a tournament to see it here." // Placeholder
    }
    
    func refreshTournaments() {
        loadMyTournaments()
    }
    
    func selectTournament(_ tournament: Tournament, forDetail: Bool) {
        self.selectedTournament = tournament
        self.showingTournamentDetail = forDetail
        self.showingParticipants = !forDetail
    }

    func selectTournament(_ tournament: Tournament, forParticipants: Bool) {
        self.selectedTournament = tournament
        self.showingParticipants = forParticipants
        self.showingTournamentDetail = !forParticipants
    }
    
    func leaveTournament(_ tournament: Tournament) async {
        guard let user = appState?.currentUser else { return }
        do {
            try await tournamentService.leaveTournament(tournament, user: user)
            myTournaments.removeAll { $0.id == tournament.id }
        } catch {
            errorMessage = "Failed to leave tournament: \(error.localizedDescription)"
            showingError = true
        }
    }

    func getUserStatus(for tournament: Tournament) -> UserTournamentStatus {
        guard let user = appState?.currentUser else { return .notRegistered }
        return tournamentService.getUserTournamentStatus(user: user, tournament: tournament)
    }
    
    private func loadMyTournaments() {
        isLoading = true
        guard let userId = appState?.currentUser?.id.uuidString else {
            isLoading = false
            return
        }
        
        Task {
            do {
                let tournaments = try await tournamentService.firebaseService.getUserTournaments(userId: userId)
                self.myTournaments = tournaments.sorted { $0.startDate > $1.startDate }
            } catch {
                errorMessage = "Failed to load tournaments: \(error.localizedDescription)"
                showingError = true
            }
            isLoading = false
        }
    }
    
    enum TournamentStatusFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case upcoming = "Upcoming"
        case completed = "Completed"
    }
} 