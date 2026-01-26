import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

#if canImport(UserDefaultMacro)
    @testable import UserDefaultMacro

    enum BaseTestCase {

        // MARK: - Static properties

        static let userDefaultsString = "UserDefaults"
        static let customUserDefaultsName: UserDefaults.Name = .shorten("test")

        // MARK: - Shared properties

        static let customStringLiteralKey: SwiftAttribute.Key = .string("variable_key")
        static let customVariableKey: SwiftAttribute.Key = .variable("Self.customKey")
        static let literalDefaultValue = "default_value".withDoubleQuotes
        static let variableDefaultValue = "Self.defaultValue"

        // MARK: - Helper methods

        static func expandedPropertySource(for variable: Variable) -> String {
            let storageKey = variable.attribute?[.key]?.description ?? variable.name.withDoubleQuotes

            let defaultValue = variable.attribute?[.defaultValue]
            let getterSuffixString = variable.type.castExpressionIfNeeded()

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

        static func expandedRecordSource(for variable: Variable) -> String {
            let storageKey = variable.attribute?[.key]?.description ?? variable.name.withDoubleQuotes

            let defaultValue = variable.attribute?[.defaultValue]
            let getterSuffixString = variable.type.castExpressionIfNeeded()
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
