// swift-format-ignore-file
import Foundation
import UserDefault

enum Theme: String, Codable {
    case light, dark, system
}

@UserDefaultDataStore
struct AppSettings {
    @UserDefaultRecord(defaultValue: true)
    var isFirstLaunch: Bool

    @UserDefaultRecord(defaultValue: 0)
    var launchCount: Int

    @UserDefaultRecord(defaultValue: .system, coding: .plist)
    var theme: Theme
}
