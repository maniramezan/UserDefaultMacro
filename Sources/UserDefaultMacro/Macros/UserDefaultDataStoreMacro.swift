import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct UserDefaultDataStoreMacro: MemberMacro, MemberAttributeMacro {
    static let attributeName = "UserDefaultDataStore"
    static let userDefaultsVariableName = "userDefaults"

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let attributeSyntax = declaration.attributes.attributeSyntax(named: attributeName) else {
            throw UserDefaultMacroError.noAttributeFound(
                attributeName: attributeName,
                modelDescription: declaration.debugDescription)
        }

        let labeledExprElementListSyntax = attributeSyntax.arguments?.as(LabeledExprListSyntax.self)
        let userDefaultsString = labeledExprElementListSyntax?.extractUserDefaultsParam(canReturnShortenVersion: true) ?? UserDefaults.standardName.description

        let mutableVariableDeclSyntaxes = declaration.memberBlock.members
            .compactMap { member in
                member.decl.as(VariableDeclSyntax.self)
            }.filter { variableDeclSyntax in
                variableDeclSyntax.bindingSpecifier.tokenKind == .keyword(.var)
            }

        let attributedVariables = mutableVariableDeclSyntaxes.compactMap { variableDeclSyntax -> (String, String)? in

            let attributeSyntax = variableDeclSyntax.attributes.attributeSyntax(named: UserDefaultRecordMacro.attributeName)

            guard
                let variableIdentifierSyntax = variableDeclSyntax.bindings
                    .compactMap({ patternBindingSyntax in patternBindingSyntax.pattern.as(IdentifierPatternSyntax.self) })
                    .first,
                let labeledExprElementListSyntax = attributeSyntax?.arguments?.as(LabeledExprListSyntax.self),
                let defaultValue = labeledExprElementListSyntax.extractDefaultValueParam()
            else {
                return nil
            }

            let key = labeledExprElementListSyntax.extractKeyParam() ?? variableIdentifierSyntax.identifier.text.withDoubleQuotes

            return (
                "\(key)",
                defaultValue
            )
        }

        let accessLevel = labeledExprElementListSyntax?.extractAccessLevelParam() ?? .internal

        let variableDefaultValues = attributedVariables.map { (variableName, defaultValue) in
            "\(variableName): \(defaultValue)"
        }.joined(separator: ", ")
        let variableDefaultValuesString: String
        if !variableDefaultValues.isEmpty {
            variableDefaultValuesString = "\n\(userDefaultsVariableName).register(defaults: [\(variableDefaultValues)])"
        } else {
            variableDefaultValuesString = ""
        }
        return [
            "private let \(raw: userDefaultsVariableName): \(raw: UserDefaults.userDefaultsClassName)",
            """
            \(raw: accessLevel.rawValue) init(\(raw: userDefaultsVariableName): \(raw: UserDefaults.userDefaultsClassName) = \(raw: userDefaultsString)) {
                self.\(raw: userDefaultsVariableName) = \(raw: userDefaultsVariableName)\(raw: variableDefaultValuesString)
            }
            """
        ]
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        guard
            let variableDeclSyntax = member.as(VariableDeclSyntax.self),
            variableDeclSyntax.bindingSpecifier.tokenKind == .keyword(.var)
        else {
            return []
        }

        guard
            variableDeclSyntax.attributes.attributeSyntax(named: UserDefaultRecordMacro.attributeName) == nil,
            variableDeclSyntax.attributes.attributeSyntax(named: UserDefaultPropertyMacro.attributeName) == nil
        else {
            return []
        }

        guard
            variableDeclSyntax.bindings.count == 1,
            !variableDeclSyntax.bindings
                .contains(where: { patternBindingSyntax in
                    patternBindingSyntax.accessorBlock != nil ||
                    patternBindingSyntax.initializer != nil
                })
        else {
            return []
        }

        return [
            "@\(raw: UserDefaultRecordMacro.attributeName)"
        ]
    }
}
