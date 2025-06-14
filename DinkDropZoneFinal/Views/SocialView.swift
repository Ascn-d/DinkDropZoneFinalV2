import SwiftUI

struct SocialView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedCategory: SocialCategory = .feed
    @State private var showingCreatePost = false
    @State private var showingJoinLeague = false
    @State private var showingEventDetails = false
    @State private var selectedEvent: CommunityEvent? = nil
    
    enum SocialCategory: String, CaseIterable {
        case feed = "Feed"
        case leagues = "Leagues"
        case events = "Events"
        case courts = "Courts"
        case challenges = "Challenges"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with online status
                socialHeader
                
                // Category picker
                categoryPicker
                
                // Content based on selected category
                ScrollView {
                    LazyVStack(spacing: 16) {
                        switch selectedCategory {
                        case .feed:
                            communityFeedContent
                        case .leagues:
                            leaguesContent
                        case .events:
                            eventsContent
                        case .courts:
                            courtsContent
                        case .challenges:
                            challengesContent
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("DinkDrop Community")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreatePost = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingCreatePost) {
                CreatePostView()
            }
            .sheet(isPresented: $showingJoinLeague) {
                JoinLeagueView()
            }
            .sheet(item: $selectedEvent) { event in
                EventDetailsView(event: event)
            }
        }
    }
    
    // MARK: - Header
    
    private var socialHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back! 👋")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let user = appState.currentUser {
                        Text(user.displayName.isEmpty ? "Player" : user.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                
                Spacer()
                
                // Online players indicator
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("247 online")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Text("1,432 members")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Quick actions
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    QuickActionChip(
                        title: "Find Match",
                        icon: "gamecontroller.fill",
                        color: .blue
                    ) {
                        // TODO: Navigate to queue
                    }
                    
                    QuickActionChip(
                        title: "Join League",
                        icon: "trophy.fill",
                        color: .orange
                    ) {
                        showingJoinLeague = true
                    }
                    
                    QuickActionChip(
                        title: "Book Court",
                        icon: "mappin.and.ellipse",
                        color: .green
                    ) {
                        // TODO: Navigate to court booking
                    }
                    
                    QuickActionChip(
                        title: "Weekly Tournament",
                        icon: "star.fill",
                        color: .purple
                    ) {
                        // TODO: Show tournament details
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }
    
    // MARK: - Category Picker
    
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SocialCategory.allCases, id: \.self) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    } label: {
                        Text(category.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedCategory == category ? Color.blue : Color(.tertiarySystemBackground))
                            )
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Community Feed Content
    
    private var communityFeedContent: some View {
        VStack(spacing: 16) {
            // Community announcements
            CommunityAnnouncementCard(
                title: "🏆 Weekly Tournament Results",
                message: "Congratulations to Sarah Chen for winning this week's Advanced League tournament!",
                timestamp: "2 hours ago",
                isPinned: true
            )
            
            // Player posts
            ForEach(getSamplePosts()) { post in
                                    SocialPostCard(post: post)
            }
            
            // League updates
            LeagueUpdateCard(
                leagueName: "San Francisco League",
                update: "New season starting next week! Registration closes in 3 days.",
                participants: 24,
                timestamp: "5 hours ago"
            )
            
            // Achievement celebrations
            PlayerAchievementCard(
                playerName: "Mike Johnson",
                achievement: "Reached 1800 ELO Rating!",
                playerImage: nil,
                timestamp: "1 day ago"
            )
        }
    }
    
    // MARK: - Leagues Content
    
    private var leaguesContent: some View {
        VStack(spacing: 16) {
            // My leagues
            VStack(alignment: .leading, spacing: 12) {
                Text("My Leagues")
                    .font(.headline)
                    .fontWeight(.bold)
                
                SocialLeagueCard(
                    name: "San Francisco Advanced League",
                    division: "Division A",
                    position: 3,
                    totalPlayers: 16,
                    nextMatch: "Tomorrow at 7:00 PM",
                    color: .blue,
                    isJoined: true
                )
            }
            
            // Available leagues
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Available Leagues")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Button("View All") {
                        // TODO: Show all leagues
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                SocialLeagueCard(
                    name: "Bay Area Beginners League",
                    division: "Open Registration",
                    position: nil,
                    totalPlayers: 8,
                    nextMatch: "Starts Monday",
                    color: .green,
                    isJoined: false
                )
                
                SocialLeagueCard(
                    name: "Weekend Warriors League",
                    division: "Intermediate",
                    position: nil,
                    totalPlayers: 12,
                    nextMatch: "Saturday mornings",
                    color: .orange,
                    isJoined: false
                )
            }
        }
    }
    
    // MARK: - Events Content
    
    private var eventsContent: some View {
        VStack(spacing: 16) {
            // Upcoming events
            VStack(alignment: .leading, spacing: 12) {
                Text("Upcoming Events")
                    .font(.headline)
                    .fontWeight(.bold)
                
                ForEach(getSampleEvents()) { event in
                    EventCard(event: event) {
                        selectedEvent = event
                        showingEventDetails = true
                    }
                }
            }
            
            // Past events
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Events")
                    .font(.headline)
                    .fontWeight(.bold)
                
                PastEventCard(
                    name: "Summer Championship",
                    date: "Last Saturday",
                    participants: 32,
                    winner: "Sarah Chen"
                )
            }
        }
    }
    
    // MARK: - Courts Content
    
    private var courtsContent: some View {
        VStack(spacing: 16) {
            // Nearby courts
            VStack(alignment: .leading, spacing: 12) {
                Text("Courts Near You")
                    .font(.headline)
                    .fontWeight(.bold)
                
                ForEach(getSampleCourts()) { court in
                    CourtCard(court: court)
                }
            }
        }
    }
    
    // MARK: - Challenges Content
    
    private var challengesContent: some View {
        VStack(spacing: 16) {
            // Weekly community challenge
            CommunityChallenge(
                title: "🔥 Weekly Distance Challenge",
                description: "Play matches at 5 different courts this week",
                progress: 0.6,
                reward: "500 XP + Court Explorer Badge",
                timeLeft: "3 days left"
            )
            
            // Player challenges
            VStack(alignment: .leading, spacing: 12) {
                Text("Player Challenges")
                    .font(.headline)
                    .fontWeight(.bold)
                
                PlayerChallengeCard(
                    challenger: "Alex Thompson",
                    message: "Ready for a rematch? Let's see if you can beat me this time! 😄",
                    stakes: "Winner buys coffee",
                    timestamp: "2 hours ago"
                )
                
                PlayerChallengeCard(
                    challenger: "Emma Wilson",
                    message: "Looking for practice partners for doubles. Anyone interested?",
                    stakes: "Practice match",
                    timestamp: "5 hours ago"
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getSamplePosts() -> [SocialPost] {
        return [
            SocialPost(
                id: "1",
                author: "John Smith",
                content: "Had an amazing match today! Finally broke through to 1600 ELO. The key was staying patient at the net 🏓",
                timestamp: Date().addingTimeInterval(-3600),
                likes: 12,
                comments: 3,
                authorImage: nil
            ),
            SocialPost(
                id: "2", 
                author: "Lisa Park",
                content: "Pro tip: Work on your third shot drop! It's a game changer. Who wants to practice together this weekend?",
                timestamp: Date().addingTimeInterval(-7200),
                likes: 8,
                comments: 5,
                authorImage: nil
            )
        ]
    }
    
    private func getSampleEvents() -> [CommunityEvent] {
        return [
            CommunityEvent(
                id: "1",
                name: "Friday Night Lights Tournament",
                date: Date().addingTimeInterval(86400 * 2),
                location: "Golden Gate Park Courts",
                participants: 16,
                maxParticipants: 32,
                description: "Weekly tournament under the lights!",
                type: .tournament
            ),
            CommunityEvent(
                id: "2",
                name: "Beginner Clinic with Pro Coach",
                date: Date().addingTimeInterval(86400 * 5),
                location: "SF Recreation Center",
                participants: 8,
                maxParticipants: 12,
                description: "Learn fundamentals from a certified instructor",
                type: .clinic
            )
        ]
    }
    
    private func getSampleCourts() -> [SocialCourt] {
        return [
            SocialCourt(
                id: "1",
                name: "Golden Gate Park",
                distance: "0.8 mi",
                availability: .available,
                rating: 4.5,
                pricePerHour: 15,
                amenities: ["Lights", "Parking", "Restrooms"]
            ),
            SocialCourt(
                id: "2", 
                name: "Mission Dolores Courts",
                distance: "1.2 mi",
                availability: .busy,
                rating: 4.2,
                pricePerHour: 12,
                amenities: ["Parking", "Water fountain"]
            )
        ]
    }
}

// MARK: - Supporting Views

struct QuickActionChip: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(color.opacity(0.1))
            )
            .foregroundColor(color)
        }
    }
}

struct CommunityAnnouncementCard: View {
    let title: String
    let message: String
    let timestamp: String
    let isPinned: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if isPinned {
                    Image(systemName: "pin.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text(timestamp)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isPinned ? Color.orange.opacity(0.1) : Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isPinned ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
}

struct SocialPostCard: View {
    let post: SocialPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(post.author.prefix(1)))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(post.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text(post.content)
                .font(.subheadline)
            
            HStack(spacing: 20) {
                Button {
                    // TODO: Like post
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                        Text("\(post.likes)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Button {
                    // TODO: Comment on post
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "message")
                        Text("\(post.comments)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Data Models

struct SocialPost: Identifiable {
    let id: String
    let author: String
    let content: String
    let timestamp: Date
    let likes: Int
    let comments: Int
    let authorImage: String?
}

struct CommunityEvent: Identifiable {
    let id: String
    let name: String
    let date: Date
    let location: String
    let participants: Int
    let maxParticipants: Int
    let description: String
    let type: EventType
    
    enum EventType {
        case tournament, clinic, social, practice
    }
}

struct SocialCourt: Identifiable {
    let id: String
    let name: String
    let distance: String
    let availability: Availability
    let rating: Double
    let pricePerHour: Int
    let amenities: [String]
    
    enum Availability {
        case available, busy, full
    }
}

// MARK: - Placeholder Views

struct CreatePostView: View {
    var body: some View {
        Text("Create Post View")
    }
}

struct JoinLeagueView: View {
    var body: some View {
        Text("Join League View")
    }
}

struct EventDetailsView: View {
    let event: CommunityEvent
    
    var body: some View {
        Text("Event Details for \(event.name)")
    }
}

struct SocialLeagueCard: View {
    let name: String
    let division: String
    let position: Int?
    let totalPlayers: Int
    let nextMatch: String
    let color: Color
    let isJoined: Bool
    
    var body: some View {
        // Placeholder implementation
        Text("League Card: \(name)")
    }
}

struct EventCard: View {
    let event: CommunityEvent
    let action: () -> Void
    
    var body: some View {
        // Placeholder implementation
        Text("Event Card: \(event.name)")
    }
}

struct PastEventCard: View {
    let name: String
    let date: String
    let participants: Int
    let winner: String
    
    var body: some View {
        // Placeholder implementation
        Text("Past Event: \(name)")
    }
}

struct CourtCard: View {
    let court: SocialCourt
    
    var body: some View {
        // Placeholder implementation
        Text("Court: \(court.name)")
    }
}

struct CommunityChallenge: View {
    let title: String
    let description: String
    let progress: Double
    let reward: String
    let timeLeft: String
    
    var body: some View {
        // Placeholder implementation
        Text("Challenge: \(title)")
    }
}

struct PlayerChallengeCard: View {
    let challenger: String
    let message: String
    let stakes: String
    let timestamp: String
    
    var body: some View {
        // Placeholder implementation
        Text("Challenge from: \(challenger)")
    }
}

struct LeagueUpdateCard: View {
    let leagueName: String
    let update: String
    let participants: Int
    let timestamp: String
    
    var body: some View {
        // Placeholder implementation
        Text("League Update: \(leagueName)")
    }
}

struct PlayerAchievementCard: View {
    let playerName: String
    let achievement: String
    let playerImage: String?
    let timestamp: String
    
    var body: some View {
        // Placeholder implementation
        Text("Achievement: \(playerName) - \(achievement)")
    }
}

#Preview {
    SocialView()
        .environment(AppState())
} 