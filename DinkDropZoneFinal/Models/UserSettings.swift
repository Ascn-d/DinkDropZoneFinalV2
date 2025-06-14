import Foundation
import SwiftData

@Model
final class UserSettings {
    var notificationsEnabled: Bool
    var matchReminders: Bool
    var soundEffects: Bool
    var darkMode: Bool
    var language: String
    var timezone: String
    var privacySettings: [String: Bool]
    

    
    init(
        notificationsEnabled: Bool = true,
        matchReminders: Bool = true,
        soundEffects: Bool = true,
        darkMode: Bool = false,
        language: String = "en",
        timezone: String = TimeZone.current.identifier,
        privacySettings: [String: Bool] = [
            "showProfile": true,
            "showStats": true,
            "showActivity": true
        ]
    ) {
        self.notificationsEnabled = notificationsEnabled
        self.matchReminders = matchReminders
        self.soundEffects = soundEffects
        self.darkMode = darkMode
        self.language = language
        self.timezone = timezone
        self.privacySettings = privacySettings
    }
    

} 