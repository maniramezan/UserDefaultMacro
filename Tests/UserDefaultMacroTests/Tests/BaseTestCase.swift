import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import XCTest

#if canImport(UserDefaultMacro)
    @testable import UserDefaultMacro

    class BaseTestCase: XCTestCase {

        // MARK: - Static properties

        static let userDefaultsString = "UserDefaults"
        static let customUserDefaultsName: UserDefaults.Name = .shorten("test")

        // MARK: - Shared properties

        let customStringLiteralKey: SwiftAttribute.Key = .string("variable_key")
        let customVariableKey: SwiftAttribute.Key = .variable("Self.customKey")
        let literalDefaultValue = "default_value".withDoubleQuotes
        let variableDefaultValue = "Self.defaultValue"

        // MARK: - Helper methods

        func expandedPropertySource(for variable: Variable) -> String {
            let storageKey = variable.attribute?[.key]?.description ?? variable.name.withDoubleQuotes

            let defaultValue = variable.attribute?[.defaultValue]
            let getterSuffixString = variable.type.castExpressionIfNeeded(with: defaultValue)

            let userDefaultsInstanceString: String
            if let userDefault = variable.attribute?[.userDefaults] {
                let parts = userDefault.split(separator: ".", omittingEmptySubsequences: true)
                if parts.count == 1, let shortNameSubstring = parts.first {
                    userDefaultsInstanceString =
                        UserDefaults.Name.shorten(String(shortNameSubstring)).asFullName.description
                } else {
                    userDefaultsInstanceString = userDefault
                }
            } else {
                userDefaultsInstanceString = UserDefaults.standardFullName.description
            }

            let registerDefaultValue =
                if let defaultValue {
                    "\(userDefaultsInstanceString).register(defaults: [\(storageKey): \(defaultValue)])\n\(Trivia.spaces(8))return "
                } else { "" }

            return """
                var \(variable.name): \(variable.type.swiftType) {
                    get {
                        \(registerDefaultValue)\(userDefaultsInstanceString).\(variable.type.userDefaultsMethodName)(forKey: \(storageKey))\(getterSuffixString)
                    }
                    set {
                        \(userDefaultsInstanceString).setValue(newValue, forKey: \(storageKey))
                    }
                }
                """
        }

        func expandedRecordSource(for variable: Variable) -> String {
            let storageKey = variable.attribute?[.key]?.description ?? variable.name.withDoubleQuotes

            let defaultValue = variable.attribute?[.defaultValue]
            let getterSuffixString = variable.type.castExpressionIfNeeded(with: defaultValue)
            let userDefaultsInstanceString = UserDefaultDataStoreMacro.userDefaultsVariableName

            return """
                var \(variable.name): \(variable.type.swiftType) {
                    get {
                        \(userDefaultsInstanceString).\(variable.type.userDefaultsMethodName)(forKey: \(storageKey))\(getterSuffixString)
                    }
                    set {
                        \(userDefaultsInstanceString).setValue(newValue, forKey: \(storageKey))
                    }
                }
                """
        }
    }
#endif
