import Foundation
import UserDefault

extension UserDefaults {
    static let test = UserDefaults(suiteName: "test")!
}

@UserDefaultDataStore(using: .test, accessLevel: .public)
struct UserDefaultsStore {

    static let key = "customized_key"
    @UserDefaultProperty(using: .test, key: Self.key, defaultValue: "Some default value")
    var randomGeneratedString: String

}

@UserDefaultDataStore
class Foo {

    @UserDefaultProperty(using: .test)
    var b: String?

    var optionalDict: [String?: Int]?

    @UserDefaultRecord(defaultValue: ["foo": Boo()])
    var dict: [String?: Int]

    var optionalArray: [Int?]?

    @UserDefaultRecord(defaultValue: ["foo"])
    var arr: [String?]


    private static let foo = "static_key_name"
    private static let koo = "static_value_name"

    var d: Double = 13.2

    var c: Double {
        set {
            UserDefaults.standard.setValue(newValue, forKey: "c")
        }
        get {
            UserDefaults.standard.double(forKey: "c")
        }
    }

    @UserDefaultRecord(key: "custom_key")
    var a: Int?

    @UserDefaultProperty(defaultValue: 89)
    var f: Double

    var q: Double
}
