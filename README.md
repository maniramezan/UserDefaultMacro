# UserDefaults Macro

[![Swift](https://img.shields.io/badge/Swift-6.2-Green?style=flat-square)](https://img.shields.io/badge/Swift-6.2-green?style=flat-square)

This repo provides several macros to help reducing boilerplate code for using `UserDefaults` to store values.

## Why use this macro?

- Properly manages default values by using `register(defaults:)`
- Uses proper methods to fetch native-supported types like `integer`, `url` and etc.
- Reduces boilerplate code needed to handle `UserDefaults` for storage
- Totally customizable. Full control over modifying keys and user default instance to use

## Getting started

> 💡 **Quick Start**: Check out the [Examples/](Examples/) directory for ready-to-use code samples covering basic to advanced usage patterns.

### Add to your project

Add reference to this repo into your project. If using SwiftPM, you can use following template, otherwise, you can search for this repo in Xcode.

```swift
dependencies: [
    .package(url: "https://github.com/maniramezan/UserDefaultMacro.git", .upToNextMajor(from: "1.0.0")),
],
```

### Macros

This package includes three macros, two of which are intended to work together:

#### `UserDefaultDataStore`

This is a high-level macro intended to be used on `struct` and `class` types generally:

```swift
@UserDefaultDataStore
struct UserDefaultsStore {
}
```

This macro adds following codes to any entity it's attached:

1. Creates `userDefaults` property
2. Create `init(userDefaults:)` method

```swift
@UserDefaultDataStore
struct UserDefaultsStore {
    // START: Added by UserDefaultDataStore
    private let userDefaults: UserDefaults

    internal init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    // END
}
```

In addition, this macro marks any mutable variables `@UserDefaultRecord`. This expands these variables to computational variables which internally use `userDefaults` property defined above to store their values.

```swift
@UserDefaultDataStore
struct UserDefaultsStore {
    // START: Added by UserDefaultDataStore
    @UserDefaultRecord
    // END
    var isFirstTimeLaunching: Bool
    // START: Added by UserDefaultRecord
    {
        get {
            userDefaults.bool(forKey: "isFirstTimeLaunching")
        }
        set {
            userDefaults.set(newValue, forKey: "isFirstTimeLaunching")
        }
    }
    // END

    // ...
}
```

`@UserDefaultDataStore` macro defaults to `internal` for `init(userDefaults:)` method. Also, `UserDefaults.standard` is used as default value for `userDefaults` property. You can change these defaults by passing arguments to the macro:

```swift
extension UserDefaults {
    static let test = UserDefaults(suiteName: "test")!
}

@UserDefaultDataStore(using: .test, accessLevel: .public)
struct UserDefaultsStore {
    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .test) {
        self.userDefaults = userDefaults
    }
}
```

Same is true for `@UserDefaultRecord` macro. You can pass a custom key and default value to it:

```swift
@UserDefaultDataStore(using: .test, accessLevel: .public)
struct UserDefaultsStore {
    @UserDefaultRecord(key: "isInitialLaunch", defaultValue: true)
    var isFirstTimeLaunching: Bool
    {
        get {
            userDefaults.bool(forKey: "isInitialLaunch")
        }

        set {
            userDefaults.setValue(newValue, forKey: "isInitialLaunch")
        }
    }

    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .test) {
        self.userDefaults = userDefaults
        userDefaults.register(defaults: ["isInitialLaunch": true])
    }
}
```

Notice how adding `defaultValue` also modifies the `init(userDefaults:)` method to register default values for the entity.

#### `UserDefaultProperty`

This macro is less recommended and might be removed in future versions depending on feedback. This is very similar to `@UserDefaultRecord` macro, but it can be used standalone. You can pass `UserDefaults`, `key` and `defaultValue` to customize the generated computational property or simply use it without any arguments:

```swift
extension UserDefaults {
    static let test = UserDefaults(suiteName: "test")!
}

struct SomeEntity {
    static let key = "customized_key"
    @UserDefaultProperty(using: .test, key: Self.key, defaultValue: "Some default value")
    var randomGeneratedString: String
    {
        get {
            UserDefaults.test.register(defaults: [Self.key: "Some default value"])
            return UserDefaults.test.string(forKey: Self.key)!
        }

        set {
            UserDefaults.test.setValue(newValue, forKey: Self.key)
        }
    }
}
```

Notice as this supports default values as well, the generated computational property includes registering the default value in the getter. This assures that the default value is always registered in `UserDefaults` before fetching it.

## Migration Guide

If you're currently using a `@UserDefault` property wrapper pattern, migrating to this macro-based approach is straightforward:

### Before (Property Wrapper)

```swift
struct Settings {
    @UserDefault(key: "username", defaultValue: "Guest")
    var username: String

    @UserDefault(key: "isFirstLaunch", defaultValue: true)
    var isFirstLaunch: Bool

    @UserDefault(key: "loginCount", defaultValue: 0)
    var loginCount: Int
}
```

### After (Macro)

```swift
@UserDefaultDataStore
struct Settings {
    @UserDefaultRecord(key: "username", defaultValue: "Guest")
    var username: String

    @UserDefaultRecord(key: "isFirstLaunch", defaultValue: true)
    var isFirstLaunch: Bool

    @UserDefaultRecord(key: "loginCount", defaultValue: 0)
    var loginCount: Int
}
```

Or even simpler, using automatic `@UserDefaultRecord` application:

```swift
@UserDefaultDataStore
struct Settings {
    var username: String      // Auto-gets @UserDefaultRecord
    var isFirstLaunch: Bool   // Auto-gets @UserDefaultRecord
    var loginCount: Int       // Auto-gets @UserDefaultRecord
}
```

### Migration Steps

1. **Add the package** to your project dependencies
2. **Remove old property wrapper** implementations
3. **Add `@UserDefaultDataStore`** to your settings struct/class
4. **Replace `@UserDefault`** with `@UserDefaultRecord` (or remove for auto-application)
5. **Initialize properly** in your app startup:
```swift
let settings = Settings()  // Uses .standard by default
// Or with custom suite:
let settings = Settings(userDefaults: .init(suiteName: "group.com.app")!)
```

### Key Differences

- **No more property wrapper boilerplate** - macros generate it at compile time
- **Better performance** - uses native UserDefaults methods (`integer`, `bool`, etc.)
- **Automatic application** - `@UserDefaultDataStore` automatically marks properties
- **Type-safe** - Compile-time checking of supported types
- **Proper defaults** - Uses `register(defaults:)` in initializer

## Supported Types

### Primitive Types

The macros natively support these types with optimized `UserDefaults` methods:

- `Int`, `Double`, `Float` - Numeric types
- `Bool` - Boolean values
- `String` - Text
- `URL` - URLs
- `Data` - Binary data
- `[Type]` - Arrays (e.g., `[String]`, `[Int]`)
- `[Key: Value]` - Dictionaries (e.g., `[String: String]`)

### Optional Types

All primitive types can be optional (e.g., `String?`, `Int?`). Optional types return `nil` when no value is stored.

### Custom Types

Custom types (classes, structs, enums) are supported through `UserDefaults`' `object(forKey:)` method, which requires types to conform to:
- `NSCoding` (Objective-C objects)
- `Codable` (Swift types) - automatically converted to `Data`

```swift
struct UserPreferences: Codable {
    var theme: String
    var fontSize: Int
}

@UserDefaultDataStore
struct Settings {
    var preferences: UserPreferences  // Stored as Data internally
}
```

### Force Unwrapping Behavior

**Important:** When you declare a non-optional property type, you are explicitly opting into force-unwrap behavior.

```swift
@UserDefaultDataStore
struct Settings {
    var userName: String  // Non-optional = force unwrap in getter
    var userId: String?   // Optional = safe unwrap in getter
}
```

Generated code:
```swift
var userName: String {
    get {
        userDefaults.string(forKey: "userName")!  // Returns String, force unwrapped
    }
}

var userId: String? {
    get {
        userDefaults.string(forKey: "userId")   // Returns String?, not unwrapped
    }
}
```

**Best practices:**
1. Use non-optional types when you always provide a `defaultValue`
2. Use optional types when the value may not be set
3. Register default values in your app's initialization to prevent crashes

```swift
@UserDefaultDataStore
struct Settings {
    @UserDefaultRecord(defaultValue: "Guest")
    var userName: String  // Safe - default value ensures non-nil

    var lastLogin: Date?  // Safe - optional, can be nil
}
```

### Contact

If you have any questions, feature request, or reporting a bug, please feel free to use Issues in the repo or contact me on Twitter [@maniramezan](https://twitter.com/maniramezan).

### Contributing

If you have any idea to improve this repo, please feel free to fork and send a pull request. I'll be more than happy to review and merge it.

#### Code Style

This project uses Apple's official [swift-format](https://github.com/apple/swift-format) (integrated via SwiftPM plugin) to maintain consistent code formatting. The configuration is in `.swift-format` with the following key rules:
- Omit explicit `return` in single-expression functions
- 120 character line width
- 4-space indentation
- Single-line property getters
- Ordered imports

**No external installation required** - swift-format is included as a package dependency.

```bash
# Format code
swift package --allow-writing-to-package-directory format-source-code --recursive .

# Check formatting (CI)
swift package lint-source-code --recursive .
```

### License

This repo is licensed under MIT license. See [LICENSE](https://github.com/maniramezan/UserDefaultMacro/blob/main/LICENSE) for more info.

### References

Great thanks for [Jesse Squires](https://www.jessesquires.com/blog/2021/03/26/a-better-approach-to-writing-a-userdefaults-property-wrapper/) for his great article on writing a better `@UserDefault` property wrapper.
