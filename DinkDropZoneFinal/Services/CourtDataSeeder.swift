import Foundation
import SwiftData

struct CourtDataSeeder {
    static func seedIfNeeded(modelContext: ModelContext) {
        if let existing = try? modelContext.fetch(FetchDescriptor<CourtLocation>()), !existing.isEmpty {
            return // already seeded
        }

        // Attempt to load bundled JSON
        guard let url = Bundle.main.url(forResource: "courts_la_sample", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([CourtLocationDTO].self, from: data) else {
            // Try CSV fallback
            if let csvURL = Bundle.main.url(forResource: "courts_la_sample", withExtension: "csv") {
                seedFromCSV(csvURL, context: modelContext)
            } else {
                print("No court seed file found in bundle – inserting minimal fallback data")
                insertFallbackCourts(into: modelContext)
            }
            return
        }

        for dto in decoded {
            let court = CourtLocation(name: dto.name,
                                      address: dto.address,
                                      city: dto.city,
                                      latitude: dto.latitude,
                                      longitude: dto.longitude,
                                      courts: dto.courts,
                                      hasLights: dto.hasLights)
            modelContext.insert(court)
        }
        try? modelContext.save()
        print("Seeded \(decoded.count) court locations")
    }
}

private struct CourtLocationDTO: Codable {
    let name: String
    let address: String
    let city: String
    let latitude: Double
    let longitude: Double
    let courts: Int
    let hasLights: Bool
}

// MARK: - CSV

extension CourtDataSeeder {
    private static func seedFromCSV(_ url: URL, context: ModelContext) {
        guard let raw = try? String(contentsOf: url, encoding: .utf8) else { return }
        let rows = raw.split(separator: "\n")
        guard let header = rows.first else { return }
        let columns = header.split(separator: ",")
        // Expecting specific headers
        let nameIdx = columns.firstIndex(of: "name") ?? 0
        let streetIdx = columns.firstIndex(of: "addr.street") ?? 1
        let cityIdx = columns.firstIndex(of: "addr.city") ?? 2
        let stateIdx = columns.firstIndex(of: "addr.state") ?? 3
        let zipIdx = columns.firstIndex(of: "addr.postcode") ?? 4
        let latIdx = columns.firstIndex(of: "@lat") ?? 5
        let lonIdx = columns.firstIndex(of: "@lon") ?? 6

        for row in rows.dropFirst() {
            let fields = splitCSVRow(String(row))
            guard fields.count > lonIdx else { continue }

            let name = fields[nameIdx]
            let street = fields[streetIdx]
            let city = fields[cityIdx]
            let state = fields[stateIdx]
            let zip = fields[zipIdx]
            let lat = Double(fields[latIdx]) ?? 0
            let lon = Double(fields[lonIdx]) ?? 0

            let address = "\(street), \(city), \(state) \(zip)"

            let location = CourtLocation(name: name,
                                         address: address,
                                         city: city,
                                         latitude: lat,
                                         longitude: lon,
                                         courts: 0,
                                         hasLights: false)
            context.insert(location)
        }
        try? context.save()
        print("Seeded courts from CSV")
    }

    // naive CSV splitter handling quoted commas minimal
    private static func splitCSVRow(_ row: String) -> [String] {
        var result: [String] = []
        var current = ""
        var insideQuotes = false
        for char in row {
            if char == "\"" { insideQuotes.toggle(); continue }
            if char == "," && !insideQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current)
        return result
    }

    // MARK: - Fallback sample
    private static func insertFallbackCourts(into context: ModelContext) {
        let samples = [
            CourtLocation(name: "Peck Park Courts",
                          address: "560 N Western Ave, Los Angeles, CA 90732",
                          city: "Los Angeles",
                          latitude: 33.7517,
                          longitude: -118.3061,
                          courts: 4,
                          hasLights: true),
            CourtLocation(name: "Peninsula Racquet Club",
                          address: "30850 Hawthorne Blvd, Rancho Palos Verdes, CA 90275",
                          city: "Rancho Palos Verdes",
                          latitude: 33.7452,
                          longitude: -118.4008,
                          courts: 6,
                          hasLights: false)
        ]
        samples.forEach { context.insert($0) }
        try? context.save()
    }
} 