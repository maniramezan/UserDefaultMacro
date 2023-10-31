import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct UserDefaultRecordMacro: AccessorMacro {
    static let attributeName = "UserDefaultRecord"
    
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        try expansion(
            of: node,
            providingAccessorsOf: declaration,
            in: context,
            userDefaults: .use(UserDefaultDataStoreMacro.userDefaultsVariableName),
            skipRegisteringDefaultValue: true)
    }
    
}
