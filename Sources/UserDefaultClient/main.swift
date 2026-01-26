import Foundation
import UserDefault

#if canImport(UserDefaultMacro)
    extension UserDefaults { static let test = UserDefaults(suiteName: "test")! }
#endif
