import Foundation
import Testing

#if canImport(UserDefaultMacro)
    @testable import UserDefaultMacro

    @Suite
    struct UserDefaultMacroErrorTests {

        @Test
        func testMultipleVariableDeclarationDescription() {
            let error = UserDefaultMacroError.multipleVariableDeclaration
            #expect(
                error.description
                    == "Macro cannot be applied to multiple variable declarations in a single line. Declare each property separately."
            )
        }

        @Test
        func testImmutableVariableDescription() {
            let error = UserDefaultMacroError.immutableVariable
            #expect(error.description == "Macro can only be applied to mutable properties. Use 'var' instead of 'let'.")
        }

        @Test
        func testMissingUserDefaultsDescription() {
            let error = UserDefaultMacroError.missingUserDefaults
            #expect(error.description == "UserDefaults instance is missing from macro parameters")
        }

        @Test
        func testNoAttributeFoundDescription() {
            let error = UserDefaultMacroError.noAttributeFound(
                attributeName: "UserDefaultDataStore",
                modelDescription: "SomeModel"
            )
            #expect(
                error.description
                    == "Expected attribute 'UserDefaultDataStore' was not found on: SomeModel"
            )
        }

        @Test
        func testFailedRetrieveVariableTypeDescription() {
            let error = UserDefaultMacroError.failedRetrieveVariableType(nodeDescription: "someNode")
            #expect(
                error.description
                    == "Failed to retrieve property type annotation. Ensure the property has an explicit type: someNode"
            )
        }

        @Test
        func testFailedRetrieveVariableTypeNameDescription() {
            let error = UserDefaultMacroError.failedRetrieveVariableTypeName(typeSyntaxDescription: "SomeType")
            #expect(
                error.description
                    == "Failed to parse property type. Unsupported type syntax: SomeType"
            )
        }

        @Test
        func testUnexpectedBindingPatternDescription() {
            let error = UserDefaultMacroError.unexpectedBindingPattern(patternBindingDescription: "somePattern")
            #expect(
                error.description
                    == "Unexpected variable binding pattern. Use simple property declarations: somePattern"
            )
        }

        @Test
        func testCustomDescription() {
            let message = "Something went wrong"
            let error = UserDefaultMacroError.custom(message)
            #expect(error.description == message)
        }
    }
#endif
