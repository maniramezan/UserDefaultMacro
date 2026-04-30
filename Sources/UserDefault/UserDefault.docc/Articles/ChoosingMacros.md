# Choosing the Right Macro

Decide between `@UserDefaultDataStore` + `@UserDefaultRecord` and standalone `@UserDefaultProperty`.

## Overview

The package ships three macros, but you'll usually combine just two of them: `@UserDefaultDataStore` on the type, and `@UserDefaultRecord` on individual properties (often implicitly). The third, `@UserDefaultProperty`, is for the rare case where a single property in an arbitrary type needs to back to `UserDefaults`.

## When to use `@UserDefaultDataStore` + `@UserDefaultRecord`

Use this pair whenever you have a dedicated settings type — a `struct` or `class` whose entire job is to read and write `UserDefaults`.

```swift
@UserDefaultDataStore
struct AppSettings {
    var isFirstLaunch: Bool             // auto-marked @UserDefaultRecord
    @UserDefaultRecord(key: "user_id")
    var userID: String?                 // explicit attribute for custom key
}
```

`@UserDefaultDataStore` does three things:

1. Generates a `private let userDefaults: UserDefaults` stored property.
2. Generates `init(userDefaults: UserDefaults = .standard)` which also registers any declared default values.
3. Automatically applies `@UserDefaultRecord` to every mutable, body-less, initializer-less stored property — so most properties need no annotation at all.

`@UserDefaultRecord` then generates the get/set accessors for each property, using the `userDefaults` property emitted by the data store.

This is the recommended path because it:
- Keeps key strings and default values in one place.
- Lets you swap the underlying `UserDefaults` instance (e.g., a suite for an App Group) by passing it to the initializer.
- Calls `register(defaults:)` once, in `init`, instead of on every property access.

## When to use `@UserDefaultProperty`

`@UserDefaultProperty` is a self-contained accessor macro for properties on types that *aren't* dedicated data stores. It takes the `UserDefaults` instance, key, and default value all on the attribute itself.

```swift
struct DiagnosticsView {
    @UserDefaultProperty(using: .standard, key: "debug_overlay_visible", defaultValue: false)
    var isDebugOverlayVisible: Bool
}
```

Choose `@UserDefaultProperty` only when:

- You can't restructure the type to use `@UserDefaultDataStore`.
- The property lives next to non-`UserDefaults` properties of unrelated kinds.
- You want a one-off, fully self-contained declaration.

Be aware that `@UserDefaultProperty` calls `register(defaults:)` lazily inside the getter on every read (the macro has no `init` to register from). `register` is idempotent and cheap, but it is still a cost the data-store-based pair avoids.

## Customizing the data store

`@UserDefaultDataStore` accepts two parameters:

- `using:` — a different `UserDefaults` instance, e.g. for an App Group suite.
- `accessLevel:` — visibility of the generated `init(userDefaults:)`.

```swift
extension UserDefaults {
    static let appGroup = UserDefaults(suiteName: "group.com.example.app")!
}

@UserDefaultDataStore(using: .appGroup, accessLevel: .public)
public struct SharedSettings {
    public var lastSyncDate: Date?
}
```

The generated `init(userDefaults:)` then defaults the parameter to `.appGroup` instead of `.standard`, but you can still inject a different instance in tests.

## See Also

- <doc:StoringCodableTypes>
- ``UserDefaultDataStore(using:accessLevel:)``
- ``UserDefaultRecord(key:defaultValue:)``
- ``UserDefaultProperty(using:key:defaultValue:)``
