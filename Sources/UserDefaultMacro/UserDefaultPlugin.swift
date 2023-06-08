import Foundation
import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct UserDefaultPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        UserDefaultDataStoreMacro.self,
        UserDefaultRecordMacro.self,
        UserDefaultPropertyMacro.self,
    ]
}
