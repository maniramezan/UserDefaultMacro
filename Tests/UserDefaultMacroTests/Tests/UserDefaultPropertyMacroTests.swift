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
        func testExpandsPropertyForAllVariableTypes() {
            for item in VariableType.allCases {
                let variable = createAttributedVariable(name: "varName", type: item)
                let diagnostics: [DiagnosticSpec] =
                    item.isPlistSafe
                    ? []
                    : [
                        DiagnosticSpec(
                            message:
                                "'\(item.swiftType)' is not directly storable in UserDefaults. Add a 'coding:' parameter to specify Codable encoding/decoding strategy, or ensure the type conforms to NSCoding.",
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
                    expandedSource: BaseTestCase.expandedPropertySource(for: variable),
                    diagnostics: diagnostics,
                    macros: testMacros
                )

                let optionalVariable = createAttributedVariable(name: "varName", type: .optional(wrappedType: item))
                let optionalDiagnostics: [DiagnosticSpec] =
                    item.isPlistSafe
                    ? []
                    : [
                        DiagnosticSpec(
                            message:
                                "'\(item.swiftType)?' is not directly storable in UserDefaults. Add a 'coding:' parameter to specify Codable encoding/decoding strategy, or ensure the type conforms to NSCoding.",
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
                    expandedSource: BaseTestCase.expandedPropertySource(for: optionalVariable),
                    diagnostics: optionalDiagnostics,
                    macros: testMacros
                )
            }
        }

        @Test
        func testExpandsPropertyWithShortUserDefaultsNameAndDefaultKey() {
            let variable = createAttributedVariable(userDefaults: BaseTestCase.customUserDefaultsName)
            assertMacroExpansion(
                variable.description,
                expandedSource: BaseTestCase.expandedPropertySource(for: variable),
                macros: testMacros
            )
        }

        @Test
        func testExpandsPropertyWithFullUserDefaultsNameAndDefaultKey() {
            let variable = createAttributedVariable(userDefaults: BaseTestCase.customUserDefaultsName.asFullName)
            assertMacroExpansion(
                variable.description,
                expandedSource: BaseTestCase.expandedPropertySource(for: variable),
                macros: testMacros
            )
        }

        @Test
        func testExpandsPropertyWithCustomKeyUsingDefaultUserDefaults() {
            let variable = createAttributedVariable(key: BaseTestCase.customStringLiteralKey)
            assertMacroExpansion(
                variable.description,
                expandedSource: BaseTestCase.expandedPropertySource(for: variable),
                macros: testMacros
            )
        }

        @Test
        func testExpandsPropertyWithCustomKeyAndShortUserDefaultsName() {
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
        func testExpandsPropertyWithVariableKeyAndShortUserDefaultsName() {
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
        func testExpandsPropertyWithLiteralDefaultValueUsingDefaultKey() {
            let variable = createAttributedVariable(defaultValue: BaseTestCase.literalDefaultValue)
            assertMacroExpansion(
                variable.description,
                expandedSource: BaseTestCase.expandedPropertySource(for: variable),
                macros: testMacros
            )
        }

        @Test
        func testExpandsPropertyWithVariableDefaultValueUsingDefaultKey() {
            let variable = createAttributedVariable(defaultValue: BaseTestCase.variableDefaultValue)
            assertMacroExpansion(
                variable.description,
                expandedSource: BaseTestCase.expandedPropertySource(for: variable),
                macros: testMacros
            )
        }

        // MARK: - Codable Tests

        @Test
        func testExpandsPropertyWithCodingPlistForObjectType() {
            let variable = Variable(
                name: "theme",
                type: .object(entityTypeName: "Theme"),
                attribute: .property(defaultValue: ".dark")
            )
            assertMacroExpansion(
                "@UserDefaultProperty(defaultValue: .dark, coding: .plist)\nvar theme: Theme",
                expandedSource: BaseTestCase.expandedPropertySource(for: variable, codingExpression: "PlistCoding()"),
                macros: testMacros
            )
        }

        @Test
        func testExpandsPropertyWithCodingJsonForObjectType() {
            let variable = Variable(
                name: "theme",
                type: .object(entityTypeName: "Theme"),
                attribute: .property(defaultValue: ".dark")
            )
            assertMacroExpansion(
                "@UserDefaultProperty(defaultValue: .dark, coding: .json)\nvar theme: Theme",
                expandedSource: BaseTestCase.expandedPropertySource(for: variable, codingExpression: "JSONCoding()"),
                macros: testMacros
            )
        }

        @Test
        func testExpandsPropertyWithOptionalObjectType() {
            let variable = Variable(
                name: "theme",
                type: .optional(wrappedType: .object(entityTypeName: "Theme")),
                attribute: .property()
            )
            assertMacroExpansion(
                "@UserDefaultProperty\nvar theme: Theme?",
                expandedSource: BaseTestCase.expandedPropertySource(for: variable),
                diagnostics: [
                    DiagnosticSpec(
                        message:
                            "'Theme?' is not directly storable in UserDefaults. Add a 'coding:' parameter to specify Codable encoding/decoding strategy, or ensure the type conforms to NSCoding.",
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
                fixedSource: "@UserDefaultProperty(coding: .plist)\nvar theme: Theme?"
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
