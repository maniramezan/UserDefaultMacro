// swift-format-ignore-file
import Foundation
import UserDefault

extension UserDefaults {
    static let appGroup = UserDefaults(suiteName: "group.com.example.app")!
}

enum Theme: String, Codable {
    case light, dark, system
}

@UserDefaultDataStore(using: .appGroup, accessLevel: .public)
public struct AppSettings {
    @UserDefaultRecord(defaultValue: true)
    public var isFirstLaunch: Bool

    @UserDefaultRecord(defaultValue: 0)
    public var launchCount: Int

    @UserDefaultRecord(defaultValue: .system, coding: .plist)
    public var theme: Theme
}
