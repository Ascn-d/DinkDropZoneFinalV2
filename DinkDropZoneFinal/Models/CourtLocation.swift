import Foundation
import SwiftData

@Model
final class CourtLocation: Identifiable {
    @Attribute(.unique) var id: String
    var name: String
    var address: String
    var city: String
    var latitude: Double
    var longitude: Double
    var courts: Int
    var hasLights: Bool

    init(id: String = UUID().uuidString,
         name: String,
         address: String,
         city: String,
         latitude: Double,
         longitude: Double,
         courts: Int,
         hasLights: Bool) {
        self.id = id
        self.name = name
        self.address = address
        self.city = city
        self.latitude = latitude
        self.longitude = longitude
        self.courts = courts
        self.hasLights = hasLights
    }
} 