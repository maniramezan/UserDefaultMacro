# Storing Codable Types

Persist custom `Codable` values in `UserDefaults` with the `coding:` parameter.

## Overview

`UserDefaults` natively stores property-list types: `Int`, `Double`, `Bool`, `String`, `Date`, `Data`, and arrays/dictionaries of those. Anything else — your own `enum`s, `struct`s, or `class`es — needs to be encoded to `Data` first.

The `coding:` parameter on `@UserDefaultRecord` and `@UserDefaultProperty` tells the macro how to do that encoding. You can use one of the bundled strategies or supply your own.

## Built-in coding strategies

Two strategies ship with the package:

- ``PlistCoding`` — uses `PropertyListEncoder` / `PropertyListDecoder`. Available as `.plist`.
- ``JSONCoding`` — uses `JSONEncoder` / `JSONDecoder`. Available as `.json`.

```swift
enum Theme: String, Codable {
    case light
    case dark
    case system
}

@UserDefaultDataStore
struct AppSettings {
    @UserDefaultRecord(defaultValue: .system, coding: .plist)
    var theme: Theme

    @UserDefaultRecord(coding: .json)
    var lastUser: User?
}
```

`PlistCoding` is the better default for small fixtures (enums, configuration) because property-list encoding is compact and integrates with the rest of the property list in `UserDefaults`. Use `JSONCoding` when you need round-trip compatibility with a JSON payload coming from your server, or when the encoded value will be inspected by humans.

## Optional vs non-optional Codable types

The generated accessor depends on whether the property is optional and whether you supplied a `defaultValue:`.

| Declaration | Behavior when no value is stored |
|---|---|
| `var theme: Theme?` (no default) | Getter returns `nil`. |
| `var theme: Theme?` (with default) | Getter returns the default. |
| `var theme: Theme` (no default) | Getter force-unwraps — **caller opted into a crash on missing value**. |
| `var theme: Theme` (with default) | Getter returns the default if decode fails or no value is stored. |

Because `register(defaults:)` only accepts property-list values, the macro can't pre-register a `Codable` default the way it can for `Int` or `String`. Instead, it inlines the default into the getter as a fallback:

```swift
@UserDefaultRecord(defaultValue: .dark, coding: .plist)
var theme: Theme

// Generated:
get {
    guard let data = userDefaults.data(forKey: "theme"),
          let value = try? PlistCoding().decode(Theme.self, from: data)
    else { return .dark }
    return value
}
```

Same pattern for non-optional values without a default — the getter force-unwraps. If you don't want a crash, declare the property optional or supply a `defaultValue:`.

## Diagnostics and fix-its

If you forget the `coding:` parameter on a custom type, the macro emits a warning at the property's `var` keyword and offers two fix-its:

1. *Add `coding: .plist` to use Plist encoding* — adds the parameter to the existing attribute.
2. *Add `@UserDefaultRecord(coding: .plist)` to use Plist encoding* — adds an explicit attribute when the property was being auto-marked by `@UserDefaultDataStore`.

Either one resolves the warning.

## Custom coding strategies

When neither plist nor JSON fits — for example, you need a specific `JSONEncoder` strategy, or you're integrating with a third-party serializer — implement ``UserDefaultsCoding`` and pass an instance to `coding:`.

```swift
struct ISO8601JSONCoding: UserDefaultsCoding {
    func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(value)
    }

    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: data)
    }
}

@UserDefaultDataStore
struct AppSettings {
    @UserDefaultRecord(coding: ISO8601JSONCoding())
    var lastSync: SyncMetadata?
}
```

## See Also

- <doc:ChoosingMacros>
- ``UserDefaultsCoding``
- ``PlistCoding``
- ``JSONCoding``
- ``UserDefaultRecord(key:defaultValue:coding:)``
