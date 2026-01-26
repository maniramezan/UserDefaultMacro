# Examples

This directory contains practical examples of using the UserDefaults macros.

## Files

### BasicUsage.swift
Demonstrates fundamental usage patterns:
- Simple settings store
- Properties with default values
- Custom storage keys
- Reading and writing values

### AdvancedUsage.swift
Shows advanced techniques:
- Custom UserDefaults suites (App Groups)
- Public API design
- Mixed property types (stored, computed, constant)
- Collections (arrays, dictionaries)
- Codable custom types
- Thread safety with actors
- Testing strategies

## Running the Examples

These examples are provided for reference and illustration. To use them:

1. Copy the relevant code into your project
2. Import the UserDefault module
3. Adapt the examples to your specific needs

## Common Patterns

### App Settings
```swift
@UserDefaultDataStore
struct AppSettings {
    @UserDefaultRecord(defaultValue: true)
    var isFirstLaunch: Bool

    var userName: String?
    var lastLoginDate: Date?
}
```

### Feature Flags
```swift
@UserDefaultDataStore
struct FeatureFlags {
    @UserDefaultRecord(defaultValue: false)
    var betaFeaturesEnabled: Bool

    @UserDefaultRecord(defaultValue: false)
    var debugModeEnabled: Bool
}
```

### User Preferences
```swift
@UserDefaultDataStore
struct UserPreferences {
    @UserDefaultRecord(defaultValue: "light")
    var theme: String

    @UserDefaultRecord(defaultValue: 14)
    var fontSize: Int

    @UserDefaultRecord(defaultValue: true)
    var notificationsEnabled: Bool
}
```

## Best Practices

1. **Use default values** for non-optional properties
2. **Use optional types** when values may not be set
3. **Use custom keys** for public storage to avoid conflicts
4. **Use custom suites** for App Groups or isolation
5. **Test with temporary suites** to avoid polluting real data
6. **Document your keys** especially for shared storage
