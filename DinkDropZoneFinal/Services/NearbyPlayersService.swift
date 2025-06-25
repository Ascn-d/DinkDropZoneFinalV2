import Foundation
import CoreLocation
import FirebaseAuth
import FirebaseFirestore

@Observable
@MainActor
final class NearbyPlayersService {
    // MARK: – Public Output
    private(set) var nearbyPlayers: [User] = []

    // MARK: – Internals
    private let firebase = FirebaseService.shared
    private let locationService: UserLocationService
    private var pollTask: Task<Void, Never>? = nil

    init(locationService: UserLocationService) {
        self.locationService = locationService
        locationService.request()
        startPolling()
    }

    // MARK: – Poll current location every 30 s
    private func startPolling() {
        pollTask = Task { [weak self] in
            await self?.pollLoop()
        }
    }

    @MainActor
    private func pollLoop() async {
        while !Task.isCancelled {
            if let loc = locationService.currentLocation {
                await syncLocation(loc)
            }
            try? await Task.sleep(for: .seconds(30))
        }
    }

    private func syncLocation(_ loc: CLLocation) async {
        // 1. Update my location in Firestore (ignore errors for now)
        try? await firebase.updateLocation(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude)
        // 2. Fetch neighbours
        await fetchNearby(center: loc)
    }

    // MARK: – Fetch nearby players
    func fetchNearby(center: CLLocation) async {
        do {
            let players = try await firebase.fetchNearbyPlayers(center: center.coordinate, radiusKm: 25)
            nearbyPlayers = players
        } catch {
            print("[NearbyPlayersService] fetch error: \(error)")
        }
    }
} 