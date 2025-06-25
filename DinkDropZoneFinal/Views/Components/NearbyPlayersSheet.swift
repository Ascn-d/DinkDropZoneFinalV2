import SwiftUI
import CoreLocation

struct NearbyPlayersSheet: View {
    let players: [User]
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                if players.isEmpty {
                    emptyStateView
                } else {
                    playerListView
                }
            }
            .navigationTitle("Nearby Players")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 50))
                .foregroundColor(DS.Color.secondary)
            
            Text("No players nearby")
                .font(DS.Font.headline)
                .foregroundColor(DS.Color.primary)
            
            Text("We couldn't find any players in your area. Try again later or expand your search radius.")
                .font(DS.Font.body)
                .foregroundColor(DS.Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                // Request location permissions if needed
                appState.locationService?.request()
            } label: {
                Text("Refresh Location")
                    .font(DS.Font.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(DS.Color.accent)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var playerListView: some View {
        List {
            Section {
                ForEach(players) { player in
                    playerRow(player)
                }
            } header: {
                Text("Players within 25km")
            } footer: {
                Text("Location data is only used to find nearby players and is never shared with third parties.")
                    .font(DS.Font.caption)
                    .foregroundColor(DS.Color.secondary)
            }
        }
    }
    
    private func playerRow(_ player: User) -> some View {
        HStack(spacing: 12) {
            // Avatar
            if let imageURL = player.profileImageURL, !imageURL.isEmpty {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(DS.Color.accent.opacity(0.2))
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: DS.Color.accent))
                        )
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(DS.Color.accent.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(player.displayName.prefix(1).uppercased())
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(DS.Color.accent)
                    )
            }
            
            // Player info
            VStack(alignment: .leading, spacing: 4) {
                Text(player.displayName)
                    .font(DS.Font.headline)
                    .foregroundColor(DS.Color.primary)
                
                HStack(spacing: 12) {
                    Label(
                        "\(calculateDistance(to: player) ?? 0, specifier: "%.1f") km",
                        systemImage: "location.fill"
                    )
                    .font(DS.Font.caption)
                    .foregroundColor(DS.Color.secondary)
                    
                    Label(
                        "ELO \(player.elo)",
                        systemImage: "star.fill"
                    )
                    .font(DS.Font.caption)
                    .foregroundColor(DS.Color.secondary)
                }
            }
            
            Spacer()
            
            // Action buttons
            Button {
                // In the future, implement invite functionality
            } label: {
                Text("Invite")
                    .font(DS.Font.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DS.Color.accent)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func calculateDistance(to user: User) -> Double? {
        guard let currentUser = appState.currentUser,
              let myLat = currentUser.lat,
              let myLon = currentUser.lon,
              let theirLat = user.lat,
              let theirLon = user.lon else {
            return nil
        }
        
        // Haversine formula for distance calculation
        let earthRadius = 6371.0 // Earth radius in kilometers
        
        let dLat = (theirLat - myLat) * .pi / 180
        let dLon = (theirLon - myLon) * .pi / 180
        
        let a = sin(dLat/2) * sin(dLat/2) +
                cos(myLat * .pi / 180) * cos(theirLat * .pi / 180) *
                sin(dLon/2) * sin(dLon/2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        let distance = earthRadius * c
        
        return distance
    }
}

#Preview {
    NearbyPlayersSheet(players: [
        User(
            email: "player1@example.com",
            password: "",
            displayName: "Sarah Chen",
            location: "San Francisco",
            profileImageURL: nil,
            elo: 1650,
            lat: 37.7749,
            lon: -122.4194
        ),
        User(
            email: "player2@example.com",
            password: "",
            displayName: "Mike Johnson",
            location: "Oakland",
            profileImageURL: nil,
            elo: 1580,
            lat: 37.8044,
            lon: -122.2711
        ),
        User(
            email: "player3@example.com",
            password: "",
            displayName: "Emma Wilson",
            location: "Berkeley",
            profileImageURL: nil,
            elo: 1720,
            lat: 37.8715,
            lon: -122.2730
        )
    ])
    .environmentObject(AppState())
} 