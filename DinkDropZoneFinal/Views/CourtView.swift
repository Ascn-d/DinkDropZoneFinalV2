import SwiftUI
import SwiftData
import CoreLocation

/// Minimalistic list of nearby courts (static sample for now). In the future wire to SwiftData / Location services.
struct CourtView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UserLocationService.self) private var locationService
    @Query(sort: \CourtLocation.name) private var allCourts: [CourtLocation]
    @State private var searchText = ""
    @State private var sortOption: SortOption = .distance

    private enum SortOption: String, CaseIterable, Identifiable { case distance = "Distance", courts = "Courts"; var id: Self { self } }

    // Explicit initializer so callers don't need to pass the synthesized @Query backing param.
    init() { }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedCourts.keys.sorted(), id: \.self) { city in
                    Section(city) {
                        ForEach(groupedCourts[city] ?? []) { court in
                            CourtRow(court: court, userLocation: locationService.currentLocation)
                                .listRowSeparator(.hidden)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Courts")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Picker("Sort", selection: $sortOption) {
                        ForEach(SortOption.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
            }
            .background(DS.Color.background)
            .searchable(text: $searchText, prompt: "Search courts")
            .onAppear { locationService.request() }
        }
    }

    private var filteredCourts: [CourtLocation] {
        guard !searchText.isEmpty else { return allCourts }
        return allCourts.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.city.localizedCaseInsensitiveContains(searchText) }
    }

    private var sortedCourts: [CourtLocation] {
        switch sortOption {
        case .distance:
            guard let userLoc = locationService.currentLocation else { return filteredCourts }
            return filteredCourts.sorted { $0.distance(from: userLoc) < $1.distance(from: userLoc) }
        case .courts:
            return filteredCourts.sorted { $0.courts > $1.courts }
        }
    }

    private var groupedCourts: [String: [CourtLocation]] {
        Dictionary(grouping: sortedCourts, by: { $0.city })
    }
}

// MARK: - Row

private struct CourtRow: View {
    let court: CourtLocation
    let userLocation: CLLocation?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(court.name)
                    .font(DS.Font.body)
                Text(court.address)
                    .font(DS.Font.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if let distanceString = distanceText {
                Text(distanceString)
                    .font(DS.Font.caption)
                    .foregroundColor(.secondary)
            }
            Image(systemName: court.hasLights ? "lightbulb.fill" : "moon")
                .foregroundColor(court.hasLights ? .yellow : .gray)
        }
        .dsCard()
    }

    private var distanceText: String? {
        guard let user = userLocation else { return nil }
        let loc = CLLocation(latitude: court.latitude, longitude: court.longitude)
        let meters = loc.distance(from: user)
        let miles = meters * 0.000621371
        return String(format: "%.1f mi", miles)
    }
}

// MARK: - Distance helper

private extension CourtLocation {
    func distance(from location: CLLocation) -> CLLocationDistance {
        CLLocation(latitude: latitude, longitude: longitude).distance(from: location)
    }
}

#Preview {
    CourtView()
        .modelContainer(for: CourtLocation.self, inMemory: true)
        .environment(UserLocationService())
} 