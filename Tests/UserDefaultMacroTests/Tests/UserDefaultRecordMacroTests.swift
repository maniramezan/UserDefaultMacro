import Foundation
import SwiftSyntaxMacros
import Testing

#if canImport(UserDefaultMacro)
    @testable import UserDefaultMacro

    @Suite
    struct UserDefaultRecordMacroTests {

        private static let attributeName = "@\(UserDefaultRecordMacro.attributeName)"

        let testMacros: [String: Macro.Type] = ["UserDefaultRecord": UserDefaultRecordMacro.self]

        @Test
        func testDefaultValues() {
            for item in VariableType.allCases {
                let variable = createAttributedVariable(name: "varName", type: item)
                assertMacroExpansion(
                    variable.description,
                    expandedSource: BaseTestCase.expandedRecordSource(for: variable),
                    macros: testMacros
                )

                let optionalVariable = createAttributedVariable(name: "varName", type: .optional(wrappedType: item))
                assertMacroExpansion(
                    optionalVariable.description,
                    expandedSource: BaseTestCase.expandedRecordSource(for: optionalVariable),
                    macros: testMacros
                )
            }
        }

        @Test
        func testCustomKeyWithDefaultUserDefaults() {
            let variable = createAttributedVariable(key: BaseTestCase.customStringLiteralKey)
            assertMacroExpansion(
                variable.description,
                expandedSource: BaseTestCase.expandedRecordSource(for: variable),
                macros: testMacros
            )
        }

        @Test
        func testLiteralDefaultValueWithDefaultKeyAndUserDefaults() {
            let variable = createAttributedVariable(defaultValue: BaseTestCase.literalDefaultValue)
            assertMacroExpansion(
                variable.description,
                expandedSource: BaseTestCase.expandedRecordSource(for: variable),
                macros: testMacros
            )
        }

        @Test
        func testVariableDefaultValueWithDefaultKeyAndUserDefaults() {
            let variable = createAttributedVariable(defaultValue: BaseTestCase.variableDefaultValue)
            assertMacroExpansion(
                variable.description,
                expandedSource: BaseTestCase.expandedRecordSource(for: variable),
                macros: testMacros
            )
        }

        // MARK: - Private Methods

        private func createAttributedVariable(
            name: String = "varName",
            type: VariableType = .int,
            key: SwiftAttribute.Key? = nil,
            declaration: Variable.Declaration = .mutable,
            defaultValue: String? = nil
        ) -> Variable {
            Variable(
                name: name,
                type: type,
                declaration: declaration,
                attribute: .record(key: key, defaultValue: defaultValue)
            )
        }
    }
#endif
