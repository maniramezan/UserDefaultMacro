import Foundation
import UserDefault

enum Theme: String, Codable {
    case light
    case dark
}

@UserDefaultDataStore
struct AppSettings {
    var isFirstLaunch: Bool

    @UserDefaultRecord(defaultValue: 75)
    var volume: Int

    @UserDefaultRecord(defaultValue: Theme.dark, coding: .plist)
    var theme: Theme

    var optionalTheme: Theme?
}
