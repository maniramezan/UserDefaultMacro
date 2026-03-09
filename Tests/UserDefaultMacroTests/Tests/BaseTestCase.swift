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

        static func expandedPropertySource(for variable: Variable, codingExpression: String? = nil) -> String {
            let storageKey = variable.attribute?[.key]?.description ?? variable.name.withDoubleQuotes

            let defaultValue = variable.attribute?[.defaultValue]

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

            if !variable.type.isPlistSafe, let codingExpression {
                return codableExpandedSource(
                    for: variable,
                    storageKey: storageKey,
                    defaultValue: defaultValue,
                    codingExpression: codingExpression,
                    userDefaultsInstanceString: userDefaultsInstanceString
                )
            }

            let getterSuffixString = variable.type.castExpressionIfNeeded()

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

        static func expandedRecordSource(for variable: Variable, codingExpression: String? = nil) -> String {
            let storageKey = variable.attribute?[.key]?.description ?? variable.name.withDoubleQuotes

            let defaultValue = variable.attribute?[.defaultValue]
            let userDefaultsInstanceString = UserDefaultDataStoreMacro.userDefaultsVariableName

            if !variable.type.isPlistSafe, let codingExpression {
                return codableExpandedSource(
                    for: variable,
                    storageKey: storageKey,
                    defaultValue: defaultValue,
                    codingExpression: codingExpression,
                    userDefaultsInstanceString: userDefaultsInstanceString
                )
            }

            let getterSuffixString = variable.type.castExpressionIfNeeded()

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

        // MARK: - Private helper for codable types

        private static func codableExpandedSource(
            for variable: Variable,
            storageKey: String,
            defaultValue: String?,
            codingExpression: String,
            userDefaultsInstanceString: String
        ) -> String {
            let ud = userDefaultsInstanceString
            let isOptional: Bool
            let innerTypeName: String

            switch variable.type {
            case .optional(let wrappedType):
                isOptional = true
                innerTypeName = wrappedType.swiftType
            default:
                isOptional = false
                innerTypeName = variable.type.swiftType
            }

            let getter: String
            if let defaultValue {
                // register(defaults:) only accepts plist-safe values; for codable types
                // we always return the default directly.
                getter =
                    "get {\n" + "        guard let data = \(ud).data(forKey: \(storageKey)),\n"
                    + "              let value = try? \(codingExpression).decode(\(innerTypeName).self, from: data)\n"
                    + "        else {\n" + "            return \(defaultValue)\n" + "        }\n"
                    + "        return value\n" + "    }"
            } else if isOptional {
                getter =
                    "get {\n" + "        guard let data = \(ud).data(forKey: \(storageKey)),\n"
                    + "              let value = try? \(codingExpression).decode(\(innerTypeName).self, from: data)\n"
                    + "        else {\n" + "            return nil\n" + "        }\n" + "        return value\n"
                    + "    }"
            } else {
                getter =
                    "get {\n" + "        let data = \(ud).data(forKey: \(storageKey))!\n"
                    + "        return try! \(codingExpression).decode(\(innerTypeName).self, from: data)\n" + "    }"
            }

            let setter: String
            if isOptional {
                setter =
                    "set {\n" + "        if let newValue, let data = try? \(codingExpression).encode(newValue) {\n"
                    + "            \(ud).set(data, forKey: \(storageKey))\n" + "        } else {\n"
                    + "            \(ud).removeObject(forKey: \(storageKey))\n" + "        }\n" + "    }"
            } else {
                setter =
                    "set {\n" + "        if let data = try? \(codingExpression).encode(newValue) {\n"
                    + "            \(ud).set(data, forKey: \(storageKey))\n" + "        }\n" + "    }"
            }

            return """
                var \(variable.name): \(variable.type.swiftType) {
                    \(getter)
                    \(setter)
                }
                """
        }
    }
#endif
