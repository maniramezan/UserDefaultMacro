import Foundation
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport

#if canImport(UserDefaultMacro)
    @testable import UserDefaultMacro

    final class UserDefaultPropertyMacroTests: BaseTestCase {

        private static let attributeName = "@\(UserDefaultPropertyMacro.attributeName)"

        let testMacros: [String: Macro.Type] = ["UserDefaultProperty": UserDefaultPropertyMacro.self]

        func testDefaultValues() {
            for item in VariableType.allCases {
                let variable = createAttributedVariable(name: "varName", type: item)
                assertMacroExpansion(
                    variable.description,
                    expandedSource: expandedPropertySource(for: variable),
                    macros: testMacros
                )

                let optionalVariable = createAttributedVariable(name: "varName", type: .optional(wrappedType: item))
                assertMacroExpansion(
                    optionalVariable.description,
                    expandedSource: expandedPropertySource(for: optionalVariable),
                    macros: testMacros
                )
            }
        }

        func testShortCustomUserDefaultsWithDefaultKey() {
            let variable = createAttributedVariable(userDefaults: Self.customUserDefaultsName)
            assertMacroExpansion(
                variable.description,
                expandedSource: expandedPropertySource(for: variable),
                macros: testMacros
            )
        }

        func testFullNameCustomUserDefaultsWithDefaultKey() {
            let variable = createAttributedVariable(userDefaults: Self.customUserDefaultsName.asFullName)
            assertMacroExpansion(
                variable.description,
                expandedSource: expandedPropertySource(for: variable),
                macros: testMacros
            )
        }

        func testCustomKeyWithDefaultUserDefaults() {
            let variable = createAttributedVariable(key: customStringLiteralKey)
            assertMacroExpansion(
                variable.description,
                expandedSource: expandedPropertySource(for: variable),
                macros: testMacros
            )
        }

        func testCustomKeyAndCustomShortUserDefaults() {
            let variable = createAttributedVariable(
                userDefaults: Self.customUserDefaultsName,
                key: customStringLiteralKey
            )
            assertMacroExpansion(
                variable.description,
                expandedSource: expandedPropertySource(for: variable),
                macros: testMacros
            )
        }

        func testCustomKeyVariableAndCustomShortUserDefaults() {
            let variable = createAttributedVariable(userDefaults: Self.customUserDefaultsName, key: customVariableKey)
            assertMacroExpansion(
                variable.description,
                expandedSource: expandedPropertySource(for: variable),
                macros: testMacros
            )
        }

        func testLiteralDefaultValueWithDefaultKeyAndUserDefaults() {
            let variable = createAttributedVariable(defaultValue: literalDefaultValue)
            assertMacroExpansion(
                variable.description,
                expandedSource: expandedPropertySource(for: variable),
                macros: testMacros
            )
        }

        func testVariableDefaultValueWithDefaultKeyAndUserDefaults() {
            let variable = createAttributedVariable(defaultValue: variableDefaultValue)
            assertMacroExpansion(
                variable.description,
                expandedSource: expandedPropertySource(for: variable),
                macros: testMacros
            )
        }

        // MARK: - Private Methods

        private func createAttributedVariable(
            name: String = "varName",
            type: VariableType = .int,
            userDefaults: UserDefaults.Name? = nil,
            key: SwiftAttribute.Key? = nil,
            declaration: Variable.Declaration = .mutable,
            defaultValue: String? = nil
        ) -> Variable {
            Variable(
                name: name,
                type: type,
                declaration: declaration,
                attribute: .property(userDefaults: userDefaults, key: key, defaultValue: defaultValue)
            )
        }
    }
#endif
