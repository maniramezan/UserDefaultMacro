import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

extension AccessorMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext,
        userDefaults: UserDefaultsType,
        skipRegisteringDefaultValue: Bool
    ) throws -> [AccessorDeclSyntax] {
        guard let variableDeclSyntax = declaration.as(VariableDeclSyntax.self),
            variableDeclSyntax.bindingSpecifier.tokenKind == .keyword(.var)
        else { throw UserDefaultMacroError.immutableVariable }

        let labeledExprElementListSyntax = node.arguments?.as(LabeledExprListSyntax.self)
        let userDefinedKey = labeledExprElementListSyntax?.extractKeyParam()
        let defaultValue = labeledExprElementListSyntax?.extractDefaultValueParam()
        let userDefaultsString: String =
            switch userDefaults {
            case .use(let useUserDefaultsString): useUserDefaultsString
            case .parseFromParams:
                labeledExprElementListSyntax?.extractUserDefaultsParam() ?? UserDefaults.standardFullName.description
            }

        guard variableDeclSyntax.bindings.count == 1 else { throw UserDefaultMacroError.multipleVariableDeclaration }

        guard let patternBindingSyntax = variableDeclSyntax.bindings.first,
            let identifierPatternSyntax = patternBindingSyntax.pattern.as(IdentifierPatternSyntax.self)
        else {
            let description =
                variableDeclSyntax.bindings.first?.pattern.debugDescription
                ?? variableDeclSyntax.bindings.debugDescription
            throw UserDefaultMacroError.unexpectedBindingPattern(patternBindingDescription: description)
        }

        let variableName = identifierPatternSyntax.identifier.text

        guard let typeAnnotationSyntax = patternBindingSyntax.typeAnnotation else {
            throw UserDefaultMacroError.failedRetrieveVariableType(
                nodeDescription: patternBindingSyntax.debugDescription
            )
        }

        let variableType = try parseTypeSyntax(typeAnnotationSyntax.type)

        let key = userDefinedKey ?? variableName.withDoubleQuotes

        let registerDefaultValue =
            if !skipRegisteringDefaultValue, let defaultValue {
                "\(userDefaultsString).register(defaults: [\(key): \(defaultValue)])\nreturn "
            } else { "" }

        let getterSuffixString = variableType.castExpressionIfNeeded(with: defaultValue)

        return [
            "get { \(raw: registerDefaultValue)\(raw: userDefaultsString).\(raw: variableType.userDefaultsMethodName)(forKey: \(raw: key))\(raw: getterSuffixString) }",
            "set { \(raw: userDefaultsString).setValue(newValue, forKey: \(raw: key)) }",
        ]
    }

    // MARK: - Private methods

    private static func parseTypeSyntax(_ typeSyntax: TypeSyntax?) throws -> VariableType {
        guard let typeSyntax else {
            throw UserDefaultMacroError.failedRetrieveVariableTypeName(typeSyntaxDescription: "No typeSyntax found.")
        }

        if let optionalTypeSyntax = typeSyntax.as(OptionalTypeSyntax.self) {
            let wrappedType = try parseTypeSyntax(optionalTypeSyntax.wrappedType)
            return .optional(wrappedType: wrappedType)
        }

        if let simpleTypeIdentifierSyntax = typeSyntax.as(IdentifierTypeSyntax.self) {
            guard case .identifier(let typeName) = simpleTypeIdentifierSyntax.name.tokenKind else {
                throw UserDefaultMacroError.failedRetrieveVariableTypeName(
                    typeSyntaxDescription: typeSyntax.debugDescription
                )
            }
            return VariableType(swiftTypeName: typeName)
        }

        if let dictionaryTypeSyntax = typeSyntax.as(DictionaryTypeSyntax.self) {
            let keyType = try parseTypeSyntax(dictionaryTypeSyntax.key)
            let valueType = try parseTypeSyntax(dictionaryTypeSyntax.value)
            return .dictionary(keyType: keyType, valueType: valueType)
        }

        if let arrayTypeSyntax = typeSyntax.as(ArrayTypeSyntax.self) {
            let elementTypeName = try parseTypeSyntax(arrayTypeSyntax.element)
            return .array(elementType: elementTypeName)
        }

        throw UserDefaultMacroError.failedRetrieveVariableTypeName(typeSyntaxDescription: typeSyntax.debugDescription)
    }
}
