// swift-format-ignore-file
import Foundation
import UserDefault

@UserDefaultDataStore
struct AppSettings {
    @UserDefaultRecord(defaultValue: true)
    var isFirstLaunch: Bool

    @UserDefaultRecord(defaultValue: 0)
    var launchCount: Int
}
