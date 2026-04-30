# ``UserDefault``

A Swift macro library that generates type-safe `UserDefaults` storage from plain property declarations.

## Overview

`UserDefault` replaces hand-written `UserDefaults` boilerplate with three macros that emit the right accessor for each Swift type, register defaults at initialization, and support custom encoding strategies for `Codable` types.

```swift
@UserDefaultDataStore
struct AppSettings {
    var isFirstLaunch: Bool

    @UserDefaultRecord(defaultValue: 75)
    var volume: Int

    @UserDefaultRecord(defaultValue: .dark, coding: .plist)
    var theme: Theme
}
```

The macros choose the correct underlying `UserDefaults` accessor for each property — `bool(forKey:)` for `Bool`, `integer(forKey:)` for `Int`, `url(forKey:)` for `URL`, and so on — instead of routing every read through `object(forKey:)`.

## Topics

### Essentials

- <doc:ChoosingMacros>
- <doc:StoringCodableTypes>

### Tutorials

- <doc:TableOfContents>

### Macros

- ``UserDefaultDataStore(using:accessLevel:)``
- ``UserDefaultRecord(key:defaultValue:)``
- ``UserDefaultRecord(key:defaultValue:coding:)``
- ``UserDefaultProperty(using:key:defaultValue:)``
- ``UserDefaultProperty(using:key:defaultValue:coding:)``

### Coding Strategies

- ``UserDefaultsCoding``
- ``PlistCoding``
- ``JSONCoding``

### Configuration

- ``AccessLevel``
