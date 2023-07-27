# UserDefaults Macro

[![Swift](https://img.shields.io/badge/Swift-5.9-Orange?style=flat-square)](https://img.shields.io/badge/Swift-5.9-orange?style=flat-square)

This repo provides several macros to help reducing boilerplate code for using `UserDefaults` to store values.

## Why use this macro?

- Properly manages default values by using `register(defaults:)`
- Uses proper methods to fetch native-supported types like `integer`, `url` and etc.
- Reduces boilerplate code needed to handle `UserDefaults` for storage
- Totally customizable. Full control over modifying keys and user default instance to use

## Getting started

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

### Contact

If you have any questions, feature request, or reporting a bug, please feel free to use Issues in the repo or contact me on Twitter [@maniramezan](https://twitter.com/maniramezan).

### Contributing

If you have any idea to improve this repo, please feel free to fork and send a pull request. I'll be more than happy to review and merge it.

### License

This repo is licensed under MIT license. See [LICENSE](https://github.com/maniramezan/UserDefaultMacro/blob/main/LICENSE) for more info.

### References

Great thanks for [Jesse Squires](https://www.jessesquires.com/blog/2021/03/26/a-better-approach-to-writing-a-userdefaults-property-wrapper/) for his great article on writing a better `@UserDefault` property wrapper.
