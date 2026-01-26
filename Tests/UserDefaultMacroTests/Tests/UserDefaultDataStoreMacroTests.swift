import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import Testing

#if canImport(UserDefaultMacro)
    @testable import UserDefaultMacro

    @Suite
    struct UserDefaultDataStoreMacroTests {
        private enum EntityType: String, CaseIterable {
            case `class`
            case `struct`
        }

        let testMacros: [String: Macro.Type] = ["UserDefaultDataStore": UserDefaultDataStoreMacro.self]

        private static let defaultEntityName = "EntityName"

        private let computationalVariableBody: String = """
                    get {
                        return 0
                    }
                    set {
                        print(newValue)
                    }
            """

        @Test
        func testExpandsDataStoreWithDefaultValues() {
            assertMacroExpansion(originalSource(), expandedSource: expandedSource(), macros: testMacros)
        }

        @Test
        func testExpandsDataStoreWithCustomAccessLevel() {
            let accessLevel: AccessLevel = .public
            assertMacroExpansion(
                originalSource(accessLevel: accessLevel),
                expandedSource: expandedSource(accessLevel: accessLevel),
                macros: testMacros
            )
        }

        @Test
        func testExpandsDataStoreWithShortUserDefaultsName() {
            let userDefaults = BaseTestCase.customUserDefaultsName
            assertMacroExpansion(
                originalSource(userDefaults: userDefaults),
                expandedSource: expandedSource(userDefaults: userDefaults),
                macros: testMacros
            )
        }

        @Test
        func testExpandsDataStoreWithFullUserDefaultsName() {
            let userDefaults = BaseTestCase.customUserDefaultsName.asFullName
            assertMacroExpansion(
                originalSource(userDefaults: userDefaults),
                expandedSource: expandedSource(userDefaults: userDefaults),
                macros: testMacros
            )
        }

        @Test
        func testMarksMutableStoredPropertiesWithRecordAttribute() {
            let variable = Variable(name: "varName", type: .int)
            assertMacroExpansion(
                originalSource(variables: [variable]),
                expandedSource: expandedSource(variables: [variable]),
                macros: testMacros
            )
        }

        @Test
        func testSkipsComputedPropertiesForRecordAttribute() {
            let variable = Variable(name: "varName", type: .int, declaration: .computational(computationalVariableBody))
            assertMacroExpansion(
                originalSource(variables: [variable]),
                expandedSource: expandedSource(variables: [variable]),
                macros: testMacros
            )
        }

        @Test
        func testRegistersDefaultValueForDefaultKeyInInit() {
            let variable = Variable(name: "varName", type: .int, attribute: .record(defaultValue: "2"))
            assertMacroExpansion(
                originalSource(variables: [variable]),
                expandedSource: expandedSource(variables: [variable]),
                macros: testMacros
            )
        }

        @Test
        func testRegistersDefaultValueForCustomLiteralKeyInInit() {
            let variable = Variable(
                name: "varName",
                type: .int,
                attribute: .record(key: BaseTestCase.customStringLiteralKey, defaultValue: "2")
            )
            assertMacroExpansion(
                originalSource(variables: [variable]),
                expandedSource: expandedSource(variables: [variable]),
                macros: testMacros
            )
        }

        @Test
        func testRegistersDefaultValueForCustomVariableKeyInInit() {
            let variable = Variable(
                name: "varName",
                type: .int,
                attribute: .record(key: BaseTestCase.customVariableKey, defaultValue: "2")
            )
            assertMacroExpansion(
                originalSource(variables: [variable]),
                expandedSource: expandedSource(variables: [variable]),
                macros: testMacros
            )
        }

        // MARK: - Private methods

        private func originalSource(
            userDefaults: UserDefaults.Name? = nil,
            accessLevel: AccessLevel? = nil,
            entityType: EntityType = .struct,
            variables: [Variable] = []
        ) -> String {
            let variableListString = variables.isEmpty ? "" : "\(variables.variableList(currentIndent: .spaces(4)))"

            let attribute: SwiftAttribute = .dataStore(userDefaults: userDefaults, accessLevel: accessLevel)

            return """
                \(attribute.description)
                \(entityType.rawValue) \(Self.defaultEntityName) {\n\(variableListString)}
                """
        }

        private func expandedSource(
            userDefaults: UserDefaults.Name = UserDefaults.standardName,
            accessLevel: AccessLevel = .internal,
            entityType: EntityType = .struct,
            variables: [Variable] = []
        ) -> String {
            let userDefaultsParamName = UserDefaultDataStoreMacro.userDefaultsVariableName
            let keyValueDefaultValues = variables.compactMap { variable -> String? in
                guard let attribute = variable.attribute, attribute.name == UserDefaultRecordMacro.attributeName,
                    let defaultValue = attribute[.defaultValue]
                else { return nil }
                let key = attribute[.key]
                return "\(key?.description ?? variable.name.withDoubleQuotes): \(defaultValue)"
            }.joined(separator: ", ")

            let defaultValueRegisteringStatement =
                if !keyValueDefaultValues.isEmpty {
                    "\n\(Trivia.spaces(8))\(userDefaultsParamName).register(defaults: [\(keyValueDefaultValues)])"
                } else { "" }

            return """
                \(entityType.rawValue) \(Self.defaultEntityName) {
                \(variables.variableList(attributed: .record(), currentIndent: .spaces(4)))
                \(Trivia.spaces(4))private let \(userDefaultsParamName): \(BaseTestCase.userDefaultsString)

                    \(accessLevel.rawValue) init(\(userDefaultsParamName): \(BaseTestCase.userDefaultsString) = \(userDefaults.description)) {
                        self.\(userDefaultsParamName) = \(userDefaultsParamName)\(defaultValueRegisteringStatement)
                    }
                }
                """
        }
    }

    extension [Variable] {
        fileprivate func variableList(attributed attribute: SwiftAttribute? = nil, currentIndent: Trivia = .spaces(0))
            -> String
        {
            map { variable in
                """
                \(currentIndent)\(variable.declaration(currentIndent: currentIndent, extraAttribute: variable.isMutable ? attribute : nil))

                """
            }.joined()
        }
    }

    extension AccessLevel { var shortName: String { ".\(rawValue)" } }
#endif
