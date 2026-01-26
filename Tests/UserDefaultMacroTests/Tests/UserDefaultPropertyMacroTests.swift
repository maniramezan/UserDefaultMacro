import Foundation
import SwiftSyntaxMacros
import Testing

#if canImport(UserDefaultMacro)
    @testable import UserDefaultMacro

    @Suite
    struct UserDefaultPropertyMacroTests {

        private static let attributeName = "@\(UserDefaultPropertyMacro.attributeName)"

        let testMacros: [String: Macro.Type] = ["UserDefaultProperty": UserDefaultPropertyMacro.self]

        @Test
        func testDefaultValues() {
            for item in VariableType.allCases {
                let variable = createAttributedVariable(name: "varName", type: item)
                assertMacroExpansion(
                    variable.description,
                    expandedSource: BaseTestCase.expandedPropertySource(for: variable),
                    macros: testMacros
                )

                let optionalVariable = createAttributedVariable(name: "varName", type: .optional(wrappedType: item))
                assertMacroExpansion(
                    optionalVariable.description,
                    expandedSource: BaseTestCase.expandedPropertySource(for: optionalVariable),
                    macros: testMacros
                )
            }
        }

        @Test
        func testShortCustomUserDefaultsWithDefaultKey() {
            let variable = createAttributedVariable(userDefaults: BaseTestCase.customUserDefaultsName)
            assertMacroExpansion(
                variable.description,
                expandedSource: BaseTestCase.expandedPropertySource(for: variable),
                macros: testMacros
            )
        }

        @Test
        func testFullNameCustomUserDefaultsWithDefaultKey() {
            let variable = createAttributedVariable(userDefaults: BaseTestCase.customUserDefaultsName.asFullName)
            assertMacroExpansion(
                variable.description,
                expandedSource: BaseTestCase.expandedPropertySource(for: variable),
                macros: testMacros
            )
        }

        @Test
        func testCustomKeyWithDefaultUserDefaults() {
            let variable = createAttributedVariable(key: BaseTestCase.customStringLiteralKey)
            assertMacroExpansion(
                variable.description,
                expandedSource: BaseTestCase.expandedPropertySource(for: variable),
                macros: testMacros
            )
        }

        @Test
        func testCustomKeyAndCustomShortUserDefaults() {
            let variable = createAttributedVariable(
                userDefaults: BaseTestCase.customUserDefaultsName,
                key: BaseTestCase.customStringLiteralKey
            )
            assertMacroExpansion(
                variable.description,
                expandedSource: BaseTestCase.expandedPropertySource(for: variable),
                macros: testMacros
            )
        }

        @Test
        func testCustomKeyVariableAndCustomShortUserDefaults() {
            let variable = createAttributedVariable(
                userDefaults: BaseTestCase.customUserDefaultsName,
                key: BaseTestCase.customVariableKey
            )
            assertMacroExpansion(
                variable.description,
                expandedSource: BaseTestCase.expandedPropertySource(for: variable),
                macros: testMacros
            )
        }

        @Test
        func testLiteralDefaultValueWithDefaultKeyAndUserDefaults() {
            let variable = createAttributedVariable(defaultValue: BaseTestCase.literalDefaultValue)
            assertMacroExpansion(
                variable.description,
                expandedSource: BaseTestCase.expandedPropertySource(for: variable),
                macros: testMacros
            )
        }

        @Test
        func testVariableDefaultValueWithDefaultKeyAndUserDefaults() {
            let variable = createAttributedVariable(defaultValue: BaseTestCase.variableDefaultValue)
            assertMacroExpansion(
                variable.description,
                expandedSource: BaseTestCase.expandedPropertySource(for: variable),
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
