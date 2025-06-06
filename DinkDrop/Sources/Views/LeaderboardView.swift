import SwiftUI
import SwiftData

struct LeaderboardView: View {
    @Query(sort: \User.elo, order: .reverse) private var users: [User]

    var body: some View {
        List(users) { user in
            HStack {
                Text(user.email)
                Spacer()
                Text("\(user.elo)")
            }
        }
        .navigationTitle("Leaderboard")
    }
}

#Preview {
    LeaderboardView()
} 