// swift-format-ignore-file
import Foundation
import UserDefault

@UserDefaultDataStore
struct AppSettings {
    var isFirstLaunch: Bool
    var launchCount: Int
}
