import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct UserDefaultDataStoreMacro: MemberMacro, MemberAttributeMacro {
    static let attributeName = "UserDefaultDataStore"
    static let userDefaultsVariableName = "userDefaults"

    public static func expansion(
        of _: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let attributeSyntax = declaration.attributes.attributeSyntax(named: attributeName) else {
            throw UserDefaultMacroError.noAttributeFound(
                attributeName: attributeName,
                modelDescription: declaration.debugDescription
            )
        }

        let labeledArgs = attributeSyntax.arguments?.as(LabeledExprListSyntax.self)
        let userDefaultsString =
            labeledArgs?.extractUserDefaultsParam(canReturnShortenVersion: true)
            ?? UserDefaults.standardName.description
        let accessLevel = labeledArgs?.extractAccessLevelParam() ?? .internal

        let registrations = defaultValueRegistrations(from: declaration)
        let registerStatement = registrationStatement(from: registrations, userDefaultsVariable: userDefaultsVariableName)

        return [
            "private let \(raw: userDefaultsVariableName): \(raw: UserDefaults.userDefaultsClassName)",
            """
            \(raw: accessLevel.rawValue) init(\(raw: userDefaultsVariableName): \(raw: UserDefaults.userDefaultsClassName) = \(raw: userDefaultsString)) {
                self.\(raw: userDefaultsVariableName) = \(raw: userDefaultsVariableName)\(raw: registerStatement)
            }
            """,
        ]
    }

    public static func expansion(
        of _: AttributeSyntax,
        attachedTo _: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        guard let variableDecl = member.as(VariableDeclSyntax.self),
            variableDecl.bindingSpecifier.tokenKind == .keyword(.var)
        else { return [] }

        guard variableDecl.attributes.attributeSyntax(named: UserDefaultRecordMacro.attributeName) == nil,
            variableDecl.attributes.attributeSyntax(named: UserDefaultPropertyMacro.attributeName) == nil
        else { return [] }

        guard variableDecl.bindings.count == 1,
            !variableDecl.bindings.contains(where: { $0.accessorBlock != nil || $0.initializer != nil })
        else { return [] }

        return ["@\(raw: UserDefaultRecordMacro.attributeName)"]
    }

    // MARK: - Private helpers

    /// Collects (key, defaultValue) pairs for all `@UserDefaultRecord`-annotated mutable variables
    /// that have a `defaultValue:` and a plist-safe type. Non-plist-safe types are excluded because
    /// `UserDefaults.register(defaults:)` cannot store them directly.
    private static func defaultValueRegistrations(from declaration: some DeclGroupSyntax) -> [(key: String, value: String)] {
        let mutableVars = declaration.memberBlock.members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .filter { $0.bindingSpecifier.tokenKind == .keyword(.var) }

        return mutableVars.compactMap { variableDecl in
            defaultValueRegistration(from: variableDecl)
        }
    }

    private static func defaultValueRegistration(from variableDecl: VariableDeclSyntax) -> (key: String, value: String)? {
        guard
            let attr = variableDecl.attributes.attributeSyntax(named: UserDefaultRecordMacro.attributeName),
            let labeledArgs = attr.arguments?.as(LabeledExprListSyntax.self),
            let defaultValue = labeledArgs.extractDefaultValueParam()
        else { return nil }

        // Only plist-safe types can be registered — custom types would crash at runtime.
        if let typeAnnotation = variableDecl.bindings.first?.typeAnnotation,
            let variableType = try? VariableType(from: typeAnnotation.type),
            !variableType.isPlistSafe
        { return nil }

        guard let identifier = variableDecl.bindings.compactMap({ $0.pattern.as(IdentifierPatternSyntax.self) }).first
        else { return nil }

        let key = labeledArgs.extractKeyParam() ?? identifier.identifier.text.withDoubleQuotes
        return (key, defaultValue)
    }

    private static func registrationStatement(from registrations: [(key: String, value: String)], userDefaultsVariable: String) -> String {
        guard !registrations.isEmpty else { return "" }
        let pairs = registrations.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        return "\n\(userDefaultsVariable).register(defaults: [\(pairs)])"
    }
}
