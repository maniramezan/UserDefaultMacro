import Foundation
import SwiftSyntaxMacros
import Testing

#if canImport(UserDefaultMacro)
    @testable import UserDefaultMacro

    @Suite
    struct UserDefaultRecordMacroTests {

        let testMacros: [String: Macro.Type] = ["UserDefaultRecord": UserDefaultRecordMacro.self]

        @Test
        func testExpandsRecordForAllVariableTypes() {
            for item in VariableType.allCases {
                let variable = createAttributedVariable(name: "varName", type: item)
                let diagnostics: [DiagnosticSpec] =
                    item.isPlistSafe
                    ? []
                    : [
                        DiagnosticSpec(
                            message: "'\(item.swiftType)' is not directly storable in UserDefaults. Add a 'coding:' parameter to specify Codable encoding/decoding strategy, or ensure the type conforms to NSCoding.",
                            line: 2,
                            column: 1,
                            severity: .warning,
                            fixIts: [
                                FixItSpec(message: "Add 'coding: .plist' to use Plist encoding"),
                                FixItSpec(message: "Add '@UserDefaultRecord(coding: .plist)' to use Plist encoding"),
                            ]
                        )
                    ]
                assertMacroExpansion(
                    variable.description,
                    expandedSource: BaseTestCase.expandedRecordSource(for: variable),
                    diagnostics: diagnostics,
                    macros: testMacros
                )

                let optionalVariable = createAttributedVariable(name: "varName", type: .optional(wrappedType: item))
                let optionalDiagnostics: [DiagnosticSpec] =
                    item.isPlistSafe
                    ? []
                    : [
                        DiagnosticSpec(
                            message: "'\(item.swiftType)?' is not directly storable in UserDefaults. Add a 'coding:' parameter to specify Codable encoding/decoding strategy, or ensure the type conforms to NSCoding.",
                            line: 2,
                            column: 1,
                            severity: .warning,
                            fixIts: [
                                FixItSpec(message: "Add 'coding: .plist' to use Plist encoding"),
                                FixItSpec(message: "Add '@UserDefaultRecord(coding: .plist)' to use Plist encoding"),
                            ]
                        )
                    ]
                assertMacroExpansion(
                    optionalVariable.description,
                    expandedSource: BaseTestCase.expandedRecordSource(for: optionalVariable),
                    diagnostics: optionalDiagnostics,
                    macros: testMacros
                )
            }
        }

        @Test
        func testExpandsRecordWithCustomKeyUsingDefaultUserDefaults() {
            let variable = createAttributedVariable(key: BaseTestCase.customStringLiteralKey)
            assertMacroExpansion(
                variable.description,
                expandedSource: BaseTestCase.expandedRecordSource(for: variable),
                macros: testMacros
            )
        }

        @Test
        func testExpandsRecordWithLiteralDefaultValueUsingDefaultKey() {
            let variable = createAttributedVariable(defaultValue: BaseTestCase.literalDefaultValue)
            assertMacroExpansion(
                variable.description,
                expandedSource: BaseTestCase.expandedRecordSource(for: variable),
                macros: testMacros
            )
        }

        @Test
        func testExpandsRecordWithVariableDefaultValueUsingDefaultKey() {
            let variable = createAttributedVariable(defaultValue: BaseTestCase.variableDefaultValue)
            assertMacroExpansion(
                variable.description,
                expandedSource: BaseTestCase.expandedRecordSource(for: variable),
                macros: testMacros
            )
        }

        // MARK: - Codable Tests

        @Test
        func testExpandsRecordWithCodingPlistForObjectType() {
            let variable = Variable(
                name: "theme",
                type: .object(entityTypeName: "Theme"),
                attribute: .record(defaultValue: ".dark")
            )
            assertMacroExpansion(
                "@UserDefaultRecord(defaultValue: .dark, coding: .plist)\nvar theme: Theme",
                expandedSource: BaseTestCase.expandedRecordSource(for: variable, codingExpression: "PlistCoding()"),
                macros: testMacros
            )
        }

        @Test
        func testExpandsRecordWithCodingJsonForObjectType() {
            let variable = Variable(
                name: "theme",
                type: .object(entityTypeName: "Theme"),
                attribute: .record(defaultValue: ".dark")
            )
            assertMacroExpansion(
                "@UserDefaultRecord(defaultValue: .dark, coding: .json)\nvar theme: Theme",
                expandedSource: BaseTestCase.expandedRecordSource(for: variable, codingExpression: "JSONCoding()"),
                macros: testMacros
            )
        }

        @Test
        func testExpandsRecordWithCustomCodingExpression() {
            let variable = Variable(
                name: "theme",
                type: .object(entityTypeName: "Theme"),
                attribute: .record(defaultValue: ".dark")
            )
            assertMacroExpansion(
                "@UserDefaultRecord(defaultValue: .dark, coding: MyCoding())\nvar theme: Theme",
                expandedSource: BaseTestCase.expandedRecordSource(for: variable, codingExpression: "MyCoding()"),
                macros: testMacros
            )
        }

        @Test
        func testExpandsRecordWithOptionalObjectType() {
            let variable = Variable(
                name: "theme",
                type: .optional(wrappedType: .object(entityTypeName: "Theme")),
                attribute: .record()
            )
            assertMacroExpansion(
                "@UserDefaultRecord\nvar theme: Theme?",
                expandedSource: BaseTestCase.expandedRecordSource(for: variable),
                diagnostics: [
                    DiagnosticSpec(
                        message: "'Theme?' is not directly storable in UserDefaults. Add a 'coding:' parameter to specify Codable encoding/decoding strategy, or ensure the type conforms to NSCoding.",
                        line: 2,
                        column: 1,
                        severity: .warning,
                        fixIts: [
                            FixItSpec(message: "Add 'coding: .plist' to use Plist encoding"),
                            FixItSpec(message: "Add '@UserDefaultRecord(coding: .plist)' to use Plist encoding"),
                        ]
                    )
                ],
                macros: testMacros,
                applyFixIts: ["Add 'coding: .plist' to use Plist encoding"],
                fixedSource: "@UserDefaultRecord(coding: .plist)\nvar theme: Theme?"
            )
        }

        @Test
        func testCodingIgnoredForPlistSafeType() {
            // For plist-safe types, coding parameter is parsed but behavior unchanged
            let variable = createAttributedVariable(name: "count", type: .int)
            assertMacroExpansion(
                "@UserDefaultRecord(coding: .json)\nvar count: Int",
                expandedSource: BaseTestCase.expandedRecordSource(for: variable),
                macros: testMacros
            )
        }

        @Test
        func testExpandsRecordWithUnknownCodingShorthand() {
            // Unknown shorthand like .custom cannot be resolved in generated code without type context.
            // The macro should emit an error directing the user to use a fully-qualified type.
            assertMacroExpansion(
                "@UserDefaultRecord(defaultValue: .dark, coding: .custom)\nvar theme: Theme",
                expandedSource: "var theme: Theme",
                diagnostics: [
                    DiagnosticSpec(
                        message: "Shorthand coding syntax '.custom' cannot be resolved without type context in the generated accessor. Use the fully-qualified type instead (e.g., 'MyCoding.custom').",
                        line: 1,
                        column: 1,
                        severity: .error
                    )
                ],
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
