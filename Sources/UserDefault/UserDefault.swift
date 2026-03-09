import Foundation

/// # ``UserDefaultMacro``

/// Generates `userDefaults` variable and `init(userDefaults:)` method for the type. It marks all mutable properties are also marked `@UserDefaultRecord`
/// This attribute can be used on type definitions like `class` and `struct`.
/// ```swift
/// @UserDefaultDataStore
/// struct UserDefaultsStore {
///     var myBoolean: Bool
/// }
/// ```
/// is expanded to:
///
/// ```swift
/// @UserDefaultDataStore
/// struct UserDefaultsStore {
///     // START: Added by UserDefaultDataStore
///     private let userDefaults: UserDefaults
///
///     init(userDefaults: UserDefaults = .standard) {
///         self.userDefaults = userDefaults
///     }
///     // END
///
///     @UserDefaultRecord
///     var myBoolean: Bool
/// }
/// ```
/// If the variable already has `@UserDefaultRecord`, it'll be ignored by this macro. Check  ``UserDefaultRecord(key:defaultValue:)``  for more details.
///
/// - Parameters:
///   - userDefaults: Instance of `UserDefaults` to use. Defaults to `.standard`
///   - accessLevel: Access level of the generated `init`. Defaults to `.internal`
@attached(member, names: named(userDefaults), named(init(userDefaults:)))
@attached(memberAttribute)
public macro UserDefaultDataStore(using userDefaults: UserDefaults = .standard, accessLevel: AccessLevel = .internal) =
    #externalMacro(module: "UserDefaultMacro", type: "UserDefaultDataStoreMacro")

/// Intended to be used on mutable properties with no body. This attribute relies on the type already attributed  by
/// ``UserDefaultDataStore(using:accessLevel:)`` and   used on any mutable property with no body.
///
/// This attribute allows overriding the key and default value when storing in `UserDefaults`. By default, it uses the variable name and the default value returned
/// by `UserDefaults` for the specified type.
///
/// Following shows an example of how this can be used with `@UserDefaultDataStore`:
/// ```swift
/// @UserDefaultDataStore
/// struct UserDefaultsStore {
///     @UserDefaultRecord(key: "isInitialLaunch", defaultValue: true)
///     var isFirstTimeLaunching: Bool
/// }
/// ```
/// is Expanded to:
/// ```swift
/// @UserDefaultDataStore
/// struct UserDefaultsStore {
///     @UserDefaultRecord(key: "isInitialLaunch", defaultValue: true)
///     var isFirstTimeLaunching: Bool {
///         get { userDefaults.bool(forKey: "isInitialLaunch") }
///         set { userDefaults.setValue(newValue, forKey: "isInitialLaunch") }
///     }
///
///     private let userDefaults: UserDefaults
///
///     init(userDefaults: UserDefaults = .standard) {
///         self.userDefaults = userDefaults
///         userDefaults.register(defaults: ["isInitialLaunch": true])
///     }
/// }
/// ```
///
/// - Parameters:
///   - key: Key to use for storing this variable. Defaults to the name of the variable
///   - defaultValue: Default value to use when the variable is not set. Defaults to what `UserDefaults` method returns for this type
@attached(accessor)
public macro UserDefaultRecord<T>(key: String? = nil, defaultValue: T? = Void.self) =
    #externalMacro(module: "UserDefaultMacro", type: "UserDefaultRecordMacro")

/// Variant of ``UserDefaultRecord(key:defaultValue:)`` for values that are not stored directly by `UserDefaults`.
///
/// This overload encodes the value to `Data` using the supplied coding strategy before writing it to `UserDefaults`,
/// and decodes it again when reading. Use it for custom types that need `Codable`-style persistence.
///
/// Supported coding options:
/// - `.plist`: uses ``PlistCoding``
/// - `.json`: uses ``JSONCoding``
/// - Any custom instance conforming to ``UserDefaultsCoding``
///
/// Following shows examples of how this overload can be used with `@UserDefaultDataStore`:
/// ```swift
/// @UserDefaultDataStore
/// struct UserDefaultsStore {
///     @UserDefaultRecord(defaultValue: .dark, coding: .plist)
///     var theme: Theme
///
///     @UserDefaultRecord(key: "cached_profile", coding: .json)
///     var profile: Profile?
///
///     @UserDefaultRecord(defaultValue: .guest, coding: CustomCoding())
///     var userRole: UserRole
/// }
/// ```
///
/// - Parameters:
///   - key: Key to use for storing this variable. Defaults to the name of the variable
///   - defaultValue: Default value to use when the variable is not set or decoding fails
///   - coding: Coding strategy used to encode and decode the value
@attached(accessor)
public macro UserDefaultRecord<T, C: UserDefaultsCoding>(key: String? = nil, defaultValue: T? = Void.self, coding: C) =
    #externalMacro(module: "UserDefaultMacro", type: "UserDefaultRecordMacro")

/// This attribute can be used on any mutable property with no body. This attribute creates the computational body needed to store the value in `UserDefaults`.
///
/// Similar to ``UserDefaultRecord(key:defaultValue:)``, unless specified, it uses variable name as the key and no default value. `UserDefaults.standard` is the
/// default storage unless defined as well.
///
/// Following shows an example of how this can be used:
/// ```swift
/// extension UserDefaults {
///     static let test = UserDefaults(suiteName: "test")!
/// }
///
/// struct SomeEntity {
///     static let key = "customized_key"
///     @UserDefaultProperty(using: .test, key: Self.key, defaultValue: "Some default value")
///     var randomGeneratedString: String
/// }
/// ```
/// The property above expands to:
/// ```swift
/// var randomGeneratedString: String {
///     get {
///         UserDefaults.test.register(defaults: [Self.key: "Some default value"])
///         return UserDefaults.test.string(forKey: Self.key)!
///     }
///     set {
///         UserDefaults.test.setValue(newValue, forKey: Self.key)
///     }
/// }
/// ```
/// - Parameters:
///   - using: Instance of `UserDefaults` to use. Defaults to `.standard`
///   - key: Key to use for storing this variable. Defaults to the name of the variable
///   - defaultValue: Default value to use when the variable is not set. Defaults to what `UserDefaults` method returns for this type
@attached(accessor)
public macro UserDefaultProperty<T>(
    using userDefaults: UserDefaults = .standard,
    key: String? = nil,
    defaultValue: T? = Void.self
) = #externalMacro(module: "UserDefaultMacro", type: "UserDefaultPropertyMacro")

/// Variant of ``UserDefaultProperty(using:key:defaultValue:)`` for values that need to be encoded before storage.
///
/// This overload stores the value as `Data` in `UserDefaults` using the supplied coding strategy, which makes it
/// suitable for custom `Codable`-style types that are not property-list compatible on their own.
///
/// Supported coding options:
/// - `.plist`: uses ``PlistCoding``
/// - `.json`: uses ``JSONCoding``
/// - Any custom instance conforming to ``UserDefaultsCoding``
///
/// Following shows examples of how this overload can be used:
/// ```swift
/// extension UserDefaults {
///     static let test = UserDefaults(suiteName: "test")!
/// }
///
/// struct SomeEntity {
///     @UserDefaultProperty(using: .test, defaultValue: .dark, coding: .plist)
///     var theme: Theme
///
///     @UserDefaultProperty(using: .test, key: "cached_profile", coding: .json)
///     var profile: Profile?
///
///     @UserDefaultProperty(using: .test, defaultValue: .guest, coding: CustomCoding())
///     var userRole: UserRole
/// }
/// ```
///
/// - Parameters:
///   - using: Instance of `UserDefaults` to use. Defaults to `.standard`
///   - key: Key to use for storing this variable. Defaults to the name of the variable
///   - defaultValue: Default value to use when the variable is not set or decoding fails
///   - coding: Coding strategy used to encode and decode the value
@attached(accessor)
public macro UserDefaultProperty<T, C: UserDefaultsCoding>(
    using userDefaults: UserDefaults = .standard,
    key: String? = nil,
    defaultValue: T? = Void.self,
    coding: C
) = #externalMacro(module: "UserDefaultMacro", type: "UserDefaultPropertyMacro")
