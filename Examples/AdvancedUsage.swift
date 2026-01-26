import Foundation
import UserDefault

// MARK: - Custom UserDefaults Suite

extension UserDefaults {
    /// Shared UserDefaults for App Groups
    static let appGroup = UserDefaults(suiteName: "group.com.example.app")!

    /// Separate suite for testing
    static let testing = UserDefaults(suiteName: "testing")!
}

/// Settings stored in a custom UserDefaults suite (e.g., for App Groups)
@UserDefaultDataStore(using: .appGroup)
struct SharedSettings {
    var lastSyncTimestamp: Double
    var syncEnabled: Bool
    var deviceId: String
}

func customSuiteExample() {
    // Automatically uses UserDefaults.appGroup
    let settings = SharedSettings()

    settings.syncEnabled = true
    settings.lastSyncTimestamp = Date().timeIntervalSince1970

    // Can also explicitly pass a different suite at runtime
    let testSettings = SharedSettings(userDefaults: .testing)
}

// MARK: - Public API

/// Public settings struct with public initializer
@UserDefaultDataStore(using: .standard, accessLevel: .public)
public struct PublicSettings {
    var apiEndpoint: URL
    var apiKey: String
    var timeout: Double
}

// Usage in another module:
// let settings = PublicSettings()

// MARK: - Mixed Property Types

/// Store with computed properties, constants, and stored properties
@UserDefaultDataStore
struct MixedStore {
    // Stored in UserDefaults
    var storedValue: Int

    // Not stored - computed property
    var computedValue: String {
        return "Value: \(storedValue)"
    }

    // Not stored - constant
    let constantValue = "unchanging"

    // Stored in UserDefaults
    var anotherStored: Bool
}

func mixedPropertiesExample() {
    let store = MixedStore()

    // Only storedValue and anotherStored are persisted
    store.storedValue = 42
    store.anotherStored = true

    // Computed properties work normally
    print(store.computedValue)  // "Value: 42"
    print(store.constantValue)  // "unchanging"
}

// MARK: - Complex Types

/// Working with arrays and dictionaries
@UserDefaultDataStore
struct CollectionSettings {
    var favoriteItems: [String]
    var scores: [Int]
    var metadata: [String: String]
    var settings: [String: Int]
}

func collectionsExample() {
    let settings = CollectionSettings()

    settings.favoriteItems = ["Apple", "Banana", "Cherry"]
    settings.scores = [100, 200, 300]
    settings.metadata = ["version": "1.0", "build": "42"]

    // Collections are automatically serialized/deserialized
    print(settings.favoriteItems.count)  // 3
}

// MARK: - Codable Types

struct UserProfile: Codable {
    var name: String
    var age: Int
    var email: String
}

@UserDefaultDataStore
struct ProfileStore {
    // Custom Codable types are stored as Data
    var currentProfile: UserProfile

    // Optional custom types
    var cachedProfile: UserProfile?
}

func codableTypesExample() {
    let store = ProfileStore()

    // Create profile
    let profile = UserProfile(name: "John", age: 30, email: "john@example.com")

    // Store it (automatically encoded to Data)
    store.currentProfile = profile

    // Retrieve it (automatically decoded)
    print(store.currentProfile.name)  // "John"
}

// MARK: - Thread Safety

/// UserDefaults is thread-safe, but consider using actors for complex logic
actor ThreadSafeSettings {
    @UserDefaultDataStore
    private struct InternalSettings {
        var counter: Int
        var timestamp: Double
    }

    private let settings = InternalSettings()

    func incrementCounter() {
        settings.counter += 1
        settings.timestamp = Date().timeIntervalSince1970
    }

    func getCounter() -> Int {
        return settings.counter
    }
}

func threadSafetyExample() async {
    let settings = ThreadSafeSettings()

    // Safe to call from multiple tasks
    await settings.incrementCounter()
    let count = await settings.getCounter()
    print("Count: \(count)")
}

// MARK: - Testing

func testingExample() {
    // Create a test suite
    let testDefaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!

    // Use it for testing
    let settings = AppSettings(userDefaults: testDefaults)
    settings.userName = "Test User"

    // Clean up after test
    testDefaults.removeSuite(named: testDefaults.suiteName!)
}

// Reference to AppSettings from BasicUsage.swift
@UserDefaultDataStore
fileprivate struct AppSettings {
    var userName: String
}
