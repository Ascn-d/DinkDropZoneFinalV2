import SwiftUI

struct ChatView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: ChatTab = .messages
    @State private var searchText = ""
    @State private var showingNewChat = false
    @State private var showingCreateGroup = false
    
    enum ChatTab: String, CaseIterable {
        case messages = "Messages"
        case groups = "Groups"
        case leagues = "Leagues"
        case matches = "Match Planning"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with online status and search
                chatHeader
                
                // Tab selector
                tabSelector
                
                // Content based on selected tab
                ScrollView {
                    LazyVStack(spacing: 8) {
                        switch selectedTab {
                        case .messages:
                            directMessagesContent
                        case .groups:
                            groupChatsContent
                        case .leagues:
                            leagueChannelsContent
                        case .matches:
                            matchPlanningContent
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            if selectedTab == .groups {
                                showingCreateGroup = true
                            } else {
                                showingNewChat = true
                            }
                        } label: {
                            Image(systemName: selectedTab == .groups ? "person.3.fill" : "square.and.pencil")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNewChat) {
                NewChatView()
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupView()
            }
        }
    }
    
    // MARK: - Header
    
    private var chatHeader: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search conversations...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
            
            // Quick stats
            HStack(spacing: 20) {
                VStack(spacing: 2) {
                    Text("12")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Active")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 2) {
                    Text("3")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Unread")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 2) {
                    Text("8")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Groups")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Online indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Online")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ChatTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(tab.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(selectedTab == tab ? .blue : .secondary)
                            
                            Rectangle()
                                .fill(selectedTab == tab ? Color.blue : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .frame(minWidth: 80)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Direct Messages Content
    
    private var directMessagesContent: some View {
        VStack(spacing: 8) {
            ForEach(getSampleDirectMessages()) { conversation in
                NavigationLink {
                    ConversationView(conversation: conversation)
                } label: {
                    ConversationRow(conversation: conversation)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Group Chats Content
    
    private var groupChatsContent: some View {
        VStack(spacing: 8) {
            ForEach(getSampleGroupChats()) { group in
                NavigationLink {
                    GroupChatView(group: group)
                } label: {
                    GroupChatRow(group: group)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - League Channels Content
    
    private var leagueChannelsContent: some View {
        VStack(spacing: 16) {
            ForEach(getSampleLeagueChannels(), id: \.name) { league in
                LeagueChannelSection(league: league)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Match Planning Content
    
    private var matchPlanningContent: some View {
        VStack(spacing: 8) {
            // Quick actions for match planning
            VStack(spacing: 12) {
                HStack {
                    Text("Quick Actions")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    MatchPlanningActionCard(
                        title: "Schedule Match",
                        icon: "calendar.badge.plus",
                        color: .blue,
                        action: {
                            // TODO: Schedule match
                        }
                    )
                    
                    MatchPlanningActionCard(
                        title: "Find Partner",
                        icon: "person.2.fill",
                        color: .green,
                        action: {
                            // TODO: Find partner
                        }
                    )
                    
                    MatchPlanningActionCard(
                        title: "Join Tournament",
                        icon: "trophy.fill",
                        color: .orange,
                        action: {
                            // TODO: Join tournament
                        }
                    )
                    
                    MatchPlanningActionCard(
                        title: "Book Court",
                        icon: "mappin.circle.fill",
                        color: .purple,
                        action: {
                            // TODO: Book court
                        }
                    )
                }
            }
            .padding(.bottom)
            
            // Active match planning conversations
            VStack(alignment: .leading, spacing: 12) {
                Text("Active Match Plans")
                    .font(.headline)
                    .fontWeight(.bold)
                
                ForEach(getSampleMatchPlanningChats()) { chat in
                    NavigationLink {
                        MatchPlanningChatView(chat: chat)
                    } label: {
                        MatchPlanningRow(chat: chat)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Helper Methods
    
    private func getSampleDirectMessages() -> [ChatConversation] {
        return [
            ChatConversation(
                id: "1",
                name: "Sarah Chen",
                lastMessage: "Great match today! Want to play again tomorrow?",
                timestamp: Date().addingTimeInterval(-300),
                unreadCount: 2,
                isOnline: true,
                avatar: nil,
                type: .direct
            ),
            ChatConversation(
                id: "2",
                name: "Mike Johnson",
                lastMessage: "Thanks for the tips on my serve! 🏓",
                timestamp: Date().addingTimeInterval(-1800),
                unreadCount: 0,
                isOnline: false,
                avatar: nil,
                type: .direct
            ),
            ChatConversation(
                id: "3",
                name: "Emma Wilson",
                lastMessage: "Are you free for doubles practice this weekend?",
                timestamp: Date().addingTimeInterval(-3600),
                unreadCount: 1,
                isOnline: true,
                avatar: nil,
                type: .direct
            )
        ]
    }
    
    private func getSampleGroupChats() -> [GroupChat] {
        return [
            GroupChat(
                id: "1",
                name: "SF Bay Area Players",
                description: "Local pickleball community",
                memberCount: 47,
                lastMessage: "Anyone up for a game at Golden Gate Park?",
                timestamp: Date().addingTimeInterval(-600),
                unreadCount: 5,
                avatar: nil,
                isActive: true
            ),
            GroupChat(
                id: "2",
                name: "Beginner Tips & Tricks",
                description: "Learning together",
                memberCount: 23,
                lastMessage: "Here's a great video on dinking technique",
                timestamp: Date().addingTimeInterval(-2400),
                unreadCount: 0,
                avatar: nil,
                isActive: true
            ),
            GroupChat(
                id: "3",
                name: "Tournament Team Alpha",
                description: "Competitive doubles team",
                memberCount: 4,
                lastMessage: "Practice tomorrow at 6 PM confirmed",
                timestamp: Date().addingTimeInterval(-5400),
                unreadCount: 2,
                avatar: nil,
                isActive: true
            )
        ]
    }
    
    private func getSampleLeagueChannels() -> [LeagueChannel] {
        return [
            LeagueChannel(
                name: "San Francisco League",
                channels: [
                    Channel(name: "📢 Announcements", unreadCount: 1, isPinned: true),
                    Channel(name: "💬 General", unreadCount: 3, isPinned: false),
                    Channel(name: "🏆 Results", unreadCount: 0, isPinned: false),
                    Channel(name: "📅 Schedule", unreadCount: 2, isPinned: false)
                ]
            ),
            LeagueChannel(
                name: "Bay Area Beginners",
                channels: [
                    Channel(name: "📢 Welcome", unreadCount: 0, isPinned: true),
                    Channel(name: "❓ Questions", unreadCount: 1, isPinned: false),
                    Channel(name: "🎯 Practice Tips", unreadCount: 0, isPinned: false)
                ]
            )
        ]
    }
    
    private func getSampleMatchPlanningChats() -> [MatchPlanningChat] {
        return [
            MatchPlanningChat(
                id: "1",
                title: "Friday Night Doubles",
                participants: ["Sarah", "Mike", "You"],
                status: .confirmed,
                matchDate: Date().addingTimeInterval(86400),
                court: "Golden Gate Park",
                lastActivity: "Court booked! See you at 7 PM",
                timestamp: Date().addingTimeInterval(-900)
            ),
            MatchPlanningChat(
                id: "2", 
                title: "Weekend Practice Session",
                participants: ["Emma", "Lisa", "You"],
                status: .planning,
                matchDate: Date().addingTimeInterval(86400 * 2),
                court: "TBD",
                lastActivity: "Looking for a court, any suggestions?",
                timestamp: Date().addingTimeInterval(-3600)
            )
        ]
    }
}

// MARK: - Supporting Views

struct ConversationRow: View {
    let conversation: ChatConversation
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text(String(conversation.name.prefix(1)))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                if conversation.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .offset(x: 16, y: 16)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(conversation.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(conversation.lastMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Circle().fill(Color.blue))
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
}

struct GroupChatRow: View {
    let group: GroupChat
    
    var body: some View {
        HStack(spacing: 12) {
            // Group avatar
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "person.3.fill")
                    .font(.title3)
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(group.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(group.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text("\(group.memberCount) members")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(group.lastMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if group.unreadCount > 0 {
                        Text("\(group.unreadCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Circle().fill(Color.green))
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
}

struct LeagueChannelSection: View {
    let league: LeagueChannel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(league.name)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text("\(league.channels.count) channels")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 4) {
                ForEach(league.channels, id: \.name) { channel in
                    HStack {
                        Text(channel.name)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        if channel.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        
                        Spacer()
                        
                        if channel.unreadCount > 0 {
                            Text("\(channel.unreadCount)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Circle().fill(Color.red))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.tertiarySystemBackground))
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct MatchPlanningActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
            )
        }
    }
}

struct MatchPlanningRow: View {
    let chat: MatchPlanningChat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(chat.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                StatusBadge(status: chat.status)
            }
            
            HStack {
                Image(systemName: "person.3.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(chat.participants.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(chat.court)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(chat.matchDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(chat.lastActivity)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(2)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
}

struct StatusBadge: View {
    let status: MatchPlanningStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(status.color.opacity(0.2))
            )
            .foregroundColor(status.color)
    }
}

// MARK: - Data Models

struct ChatConversation: Identifiable {
    let id: String
    let name: String
    let lastMessage: String
    let timestamp: Date
    let unreadCount: Int
    let isOnline: Bool
    let avatar: String?
    let type: ConversationType
    
    enum ConversationType {
        case direct, group
    }
}

struct GroupChat: Identifiable {
    let id: String
    let name: String
    let description: String
    let memberCount: Int
    let lastMessage: String
    let timestamp: Date
    let unreadCount: Int
    let avatar: String?
    let isActive: Bool
}

struct LeagueChannel {
    let name: String
    let channels: [Channel]
}

struct Channel {
    let name: String
    let unreadCount: Int
    let isPinned: Bool
}

struct MatchPlanningChat: Identifiable {
    let id: String
    let title: String
    let participants: [String]
    let status: MatchPlanningStatus
    let matchDate: Date
    let court: String
    let lastActivity: String
    let timestamp: Date
}

enum MatchPlanningStatus: String {
    case planning = "Planning"
    case confirmed = "Confirmed"
    case completed = "Completed"
    case cancelled = "Cancelled"
    
    var color: Color {
        switch self {
        case .planning: return .orange
        case .confirmed: return .green
        case .completed: return .blue
        case .cancelled: return .red
        }
    }
}

// MARK: - Placeholder Views

struct NewChatView: View {
    var body: some View {
        Text("New Chat View")
    }
}

struct CreateGroupView: View {
    var body: some View {
        Text("Create Group View")
    }
}

struct ConversationView: View {
    let conversation: ChatConversation
    
    var body: some View {
        Text("Chat with \(conversation.name)")
    }
}

struct GroupChatView: View {
    let group: GroupChat
    
    var body: some View {
        Text("Group: \(group.name)")
    }
}

struct MatchPlanningChatView: View {
    let chat: MatchPlanningChat
    
    var body: some View {
        Text("Match Planning: \(chat.title)")
    }
}

#Preview {
    ChatView()
        .environment(AppState())
} 