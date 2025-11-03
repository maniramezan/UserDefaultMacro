import Foundation
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport

#if canImport(UserDefaultMacro)
@testable import UserDefaultMacro

final class UserDefaultRecordMacroTests: BaseTestCase {

    private static let attributeName = "@\(UserDefaultRecordMacro.attributeName)"

    let testMacros: [String: Macro.Type] = [
        "UserDefaultRecord": UserDefaultRecordMacro.self,
    ]

    func testDefaultValues() {
        VariableType.allCases.forEach {
            let variable = createAttributedVariable(name: "varName", type: $0)
            assertMacroExpansion(
                variable.description,
                expandedSource: expandedRecordSource(for: variable),
                macros: testMacros
            )

            let optionalVariable = createAttributedVariable(name: "varName", type: .optional(wrappedType: $0))
            assertMacroExpansion(
                optionalVariable.description,
                expandedSource: expandedRecordSource(for: optionalVariable),
                macros: testMacros
            )
        }
    }

    func testCustomKeyWithDefaultUserDefaults() {
        let variable = createAttributedVariable(key: customStringLiteralKey)
        assertMacroExpansion(
            variable.description,
            expandedSource: expandedRecordSource(for: variable),
            macros: testMacros
        )
    }

    func testLiteralDefaultValueWithDefaultKeyAndUserDefaults() {
        let variable = createAttributedVariable(defaultValue: literalDefaultValue)
        assertMacroExpansion(
            variable.description,
            expandedSource: expandedRecordSource(for: variable),
            macros: testMacros
        )
    }

    func testVariableDefaultValueWithDefaultKeyAndUserDefaults() {
        let variable = createAttributedVariable(defaultValue: variableDefaultValue)
        assertMacroExpansion(
            variable.description,
            expandedSource: expandedRecordSource(for: variable),
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
