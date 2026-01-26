import Foundation
import UserDefault

// MARK: - Basic Usage Example

/// Simple settings store using @UserDefaultDataStore macro
/// All properties are automatically marked with @UserDefaultRecord
@UserDefaultDataStore
struct AppSettings {
    // Primitives - stored directly
    var isFirstLaunch: Bool
    var userName: String
    var loginCount: Int
    var lastAppVersion: String

    // Optional values
    var userId: String?
    var lastLoginDate: Data?
}

// MARK: - Usage

func basicUsageExample() {
    // Create instance (uses UserDefaults.standard by default)
    let settings = AppSettings()

    // Write values
    settings.isFirstLaunch = false
    settings.userName = "John Doe"
    settings.loginCount = 5
    settings.lastAppVersion = "1.0.0"
    settings.userId = "user-123"

    // Read values
    print("User: \(settings.userName)")
    print("Login count: \(settings.loginCount)")
    print("User ID: \(settings.userId ?? "not set")")

    // Check first launch
    if settings.isFirstLaunch {
        print("Welcome! This is your first launch.")
    }
}

// MARK: - With Default Values

/// Settings with default values that are automatically registered
@UserDefaultDataStore
struct GameSettings {
    @UserDefaultRecord(defaultValue: "Easy")
    var difficulty: String

    @UserDefaultRecord(defaultValue: 100)
    var musicVolume: Int

    @UserDefaultRecord(defaultValue: 100)
    var sfxVolume: Int

    @UserDefaultRecord(defaultValue: true)
    var soundEnabled: Bool
}

func defaultValuesExample() {
    let settings = GameSettings()

    // On first access, default values are returned
    print("Difficulty: \(settings.difficulty)")  // "Easy"
    print("Music volume: \(settings.musicVolume)")  // 100

    // Change values
    settings.difficulty = "Hard"
    settings.musicVolume = 75

    // Values persist across app launches
}

// MARK: - Custom Keys

/// Using custom keys for UserDefaults storage
@UserDefaultDataStore
struct UserPreferences {
    // Use reverse-domain notation for keys
    @UserDefaultRecord(key: "com.myapp.user.name")
    var userName: String

    @UserDefaultRecord(key: "com.myapp.user.email")
    var userEmail: String

    // Default property name as key
    var theme: String
}

func customKeysExample() {
    let prefs = UserPreferences()

    prefs.userName = "Alice"
    prefs.userEmail = "alice@example.com"
    prefs.theme = "dark"

    // Stored as:
    // UserDefaults.standard.string(forKey: "com.myapp.user.name")
    // UserDefaults.standard.string(forKey: "com.myapp.user.email")
    // UserDefaults.standard.string(forKey: "theme")
}
