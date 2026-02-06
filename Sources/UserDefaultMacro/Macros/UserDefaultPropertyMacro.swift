import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

public struct UserDefaultPropertyMacro: AccessorMacro {
    static let attributeName = "UserDefaultProperty"

    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        try expansion(
            of: node,
            providingAccessorsOf: declaration,
            in: context,
            userDefaults: .parseFromParams,
            skipRegisteringDefaultValue: false
        )
    }
}
