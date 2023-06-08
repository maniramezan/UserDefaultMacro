import Foundation
import UserDefaultMacro

@attached(member, names: named(userDefaults), named(init(userDefaults:)))
@attached(memberAttribute)
public macro UserDefaultDataStore(using userDefaults: UserDefaults = .standard, accessLevel: AccessLevel = .internal) = #externalMacro(module: "UserDefaultMacro", type: "UserDefaultDataStoreMacro")

@attached(accessor)
public macro UserDefaultRecord<T>(key: String? = nil, defaultValue: T? = Void.self) = #externalMacro(module: "UserDefaultMacro", type: "UserDefaultRecordMacro")

@attached(accessor)
public macro UserDefaultProperty<T>(using userDefaults: UserDefaults = .standard, key: String? = nil, defaultValue: T? = Void.self) = #externalMacro(module: "UserDefaultMacro", type: "UserDefaultPropertyMacro")
