import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

extension AccessorMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext,
        userDefaults: UserDefaultsType,
        skipRegisteringDefaultValue: Bool
    ) throws -> [AccessorDeclSyntax] {
        guard let variableDecl = declaration.as(VariableDeclSyntax.self),
            variableDecl.bindingSpecifier.tokenKind == .keyword(.var)
        else { throw UserDefaultMacroError.immutableVariable }

        let labeledArgs = node.arguments?.as(LabeledExprListSyntax.self)
        let userDefinedKey = labeledArgs?.extractKeyParam()
        let defaultValue = labeledArgs?.extractDefaultValueParam()
        let codingExpression = try labeledArgs?.extractCodingParam()
        let userDefaultsString = resolveUserDefaultsString(from: labeledArgs, userDefaults: userDefaults)

        let (variableName, variableType) = try extractVariableInfo(from: variableDecl)
        let key = userDefinedKey ?? variableName.withDoubleQuotes

        if !variableType.isPlistSafe {
            if let codingExpression {
                return codableAccessors(
                    variableType: variableType,
                    key: key,
                    defaultValue: defaultValue,
                    codingExpression: codingExpression,
                    userDefaultsString: userDefaultsString
                )
            }
            emitNoCodingWarning(for: variableType, node: node, variableDecl: variableDecl, in: context)
        }

        return standardAccessors(
            for: variableType,
            key: key,
            defaultValue: defaultValue,
            skipRegistering: skipRegisteringDefaultValue,
            userDefaultsString: userDefaultsString
        )
    }

    // MARK: - Argument parsing

    private static func resolveUserDefaultsString(from labeledArgs: LabeledExprListSyntax?, userDefaults: UserDefaultsType) -> String {
        switch userDefaults {
        case .use(let string): string
        case .parseFromParams: labeledArgs?.extractUserDefaultsParam() ?? UserDefaults.standardFullName.description
        }
    }

    // MARK: - Variable extraction

    private static func extractVariableInfo(from variableDecl: VariableDeclSyntax) throws -> (name: String, type: VariableType) {
        guard variableDecl.bindings.count == 1 else { throw UserDefaultMacroError.multipleVariableDeclaration }

        guard let patternBinding = variableDecl.bindings.first,
            let identifierPattern = patternBinding.pattern.as(IdentifierPatternSyntax.self)
        else {
            let description =
                variableDecl.bindings.first?.pattern.debugDescription ?? variableDecl.bindings.debugDescription
            throw UserDefaultMacroError.unexpectedBindingPattern(patternBindingDescription: description)
        }

        guard let typeAnnotation = patternBinding.typeAnnotation else {
            throw UserDefaultMacroError.failedRetrieveVariableType(nodeDescription: patternBinding.debugDescription)
        }

        return (identifierPattern.identifier.text, try VariableType(from: typeAnnotation.type))
    }

    // MARK: - Accessor generation

    private static func standardAccessors(
        for variableType: VariableType,
        key: String,
        defaultValue: String?,
        skipRegistering: Bool,
        userDefaultsString: String
    ) -> [AccessorDeclSyntax] {
        let registerPrefix: String
        if !skipRegistering, let defaultValue {
            registerPrefix = "\(userDefaultsString).register(defaults: [\(key): \(defaultValue)])\nreturn "
        } else {
            registerPrefix = ""
        }
        let castSuffix = variableType.castExpressionIfNeeded()
        return [
            "get { \(raw: registerPrefix)\(raw: userDefaultsString).\(raw: variableType.userDefaultsMethodName)(forKey: \(raw: key))\(raw: castSuffix) }",
            "set { \(raw: userDefaultsString).setValue(newValue, forKey: \(raw: key)) }",
        ]
    }

    private static func codableAccessors(
        variableType: VariableType,
        key: String,
        defaultValue: String?,
        codingExpression: String,
        userDefaultsString: String
    ) -> [AccessorDeclSyntax] {
        let isOptional: Bool
        let innerTypeName: String
        if case .optional(let wrapped) = variableType {
            isOptional = true
            innerTypeName = wrapped.swiftType
        } else {
            isOptional = false
            innerTypeName = variableType.swiftType
        }
        return [
            codableGetter(
                isOptional: isOptional,
                innerTypeName: innerTypeName,
                key: key,
                defaultValue: defaultValue,
                codingExpression: codingExpression,
                userDefaultsString: userDefaultsString
            ),
            codableSetter(
                isOptional: isOptional,
                key: key,
                codingExpression: codingExpression,
                userDefaultsString: userDefaultsString
            ),
        ]
    }

    private static func codableGetter(
        isOptional: Bool,
        innerTypeName: String,
        key: String,
        defaultValue: String?,
        codingExpression: String,
        userDefaultsString: String
    ) -> AccessorDeclSyntax {
        if let defaultValue {
            // Has a default — decode with fallback to default value.
            // register(defaults:) only accepts plist-safe values, so for Codable types
            // we return the default directly rather than registering it.
            return """
                get {
                    guard let data = \(raw: userDefaultsString).data(forKey: \(raw: key)),
                          let value = try? \(raw: codingExpression).decode(\(raw: innerTypeName).self, from: data)
                    else { return \(raw: defaultValue) }
                    return value
                }
                """
        } else if isOptional {
            // Optional without default — return nil when data is absent or decode fails.
            return """
                get {
                    guard let data = \(raw: userDefaultsString).data(forKey: \(raw: key)),
                          let value = try? \(raw: codingExpression).decode(\(raw: innerTypeName).self, from: data)
                    else { return nil }
                    return value
                }
                """
        } else {
            // Non-optional without default — caller opted into force-unwrap via type annotation.
            return """
                get {
                    let data = \(raw: userDefaultsString).data(forKey: \(raw: key))!
                    return try! \(raw: codingExpression).decode(\(raw: innerTypeName).self, from: data)
                }
                """
        }
    }

    private static func codableSetter(
        isOptional: Bool,
        key: String,
        codingExpression: String,
        userDefaultsString: String
    ) -> AccessorDeclSyntax {
        if isOptional {
            return """
                set {
                    if let newValue, let data = try? \(raw: codingExpression).encode(newValue) {
                        \(raw: userDefaultsString).set(data, forKey: \(raw: key))
                    } else {
                        \(raw: userDefaultsString).removeObject(forKey: \(raw: key))
                    }
                }
                """
        } else {
            return """
                set {
                    if let data = try? \(raw: codingExpression).encode(newValue) {
                        \(raw: userDefaultsString).set(data, forKey: \(raw: key))
                    }
                }
                """
        }
    }

    // MARK: - Diagnostic

    private static func emitNoCodingWarning(
        for variableType: VariableType,
        node: AttributeSyntax,
        variableDecl: VariableDeclSyntax,
        in context: some MacroExpansionContext
    ) {
        // Attach the diagnostic to `bindingSpecifier` (the `var` keyword), which is always in
        // the user's source regardless of whether @UserDefaultRecord was explicitly written or
        // auto-applied by @UserDefaultDataStore. Two fix-its cover both cases:
        //   1. Add `coding:` to the existing attribute — for explicit @UserDefaultRecord/@UserDefaultProperty.
        //   2. Add an explicit @UserDefaultRecord(coding:) before the property — for the auto-applied case.
        context.diagnose(
            Diagnostic(
                node: Syntax(variableDecl.bindingSpecifier),
                message: NoCodingParameterWarning(typeName: variableType.swiftType),
                fixIts: [
                    FixIt(
                        message: AddCodingParameterFixIt(),
                        changes: [.replace(oldNode: Syntax(node), newNode: Syntax(addCodingParameter(to: node)))]
                    ),
                    FixIt(
                        message: AddExplicitRecordWithCodingFixIt(),
                        changes: [.replace(oldNode: Syntax(variableDecl), newNode: Syntax(addExplicitRecord(to: variableDecl)))]
                    ),
                ]
            )
        )
    }

    // MARK: - Fix-it builders

    private static func plistCodingArgument() -> LabeledExprSyntax {
        LabeledExprSyntax(
            label: .identifier("coding"),
            colon: .colonToken(trailingTrivia: .space),
            expression: ExprSyntax(".plist")
        )
    }

    private static func addCodingParameter(to node: AttributeSyntax) -> AttributeSyntax {
        let codingArg = plistCodingArgument()
        if let existingArgs = node.arguments?.as(LabeledExprListSyntax.self), !existingArgs.isEmpty {
            var arr = Array(existingArgs)
            arr[arr.index(before: arr.endIndex)] = arr[arr.index(before: arr.endIndex)].with(
                \.trailingComma, .commaToken(trailingTrivia: .space)
            )
            arr.append(codingArg)
            return node.with(\.arguments, .argumentList(LabeledExprListSyntax(arr)))
        } else {
            return node
                .with(\.leftParen, .leftParenToken())
                .with(\.arguments, .argumentList(LabeledExprListSyntax([codingArg])))
                .with(\.rightParen, .rightParenToken())
        }
    }

    private static func addExplicitRecord(to declaration: VariableDeclSyntax) -> VariableDeclSyntax {
        let recordAttr = AttributeSyntax(
            atSign: .atSignToken(),
            attributeName: IdentifierTypeSyntax(name: .identifier("UserDefaultRecord")),
            leftParen: .leftParenToken(),
            arguments: .argumentList(LabeledExprListSyntax([plistCodingArgument()])),
            rightParen: .rightParenToken()
        )

        // Move the original leading trivia (newline + indent) to the new attribute.
        // The var keyword then keeps only the indentation (no leading newline).
        let leadingTrivia = declaration.leadingTrivia
        let indentTrivia = Trivia(pieces: leadingTrivia.pieces.filter {
            if case .spaces = $0 { return true }
            if case .tabs = $0 { return true }
            return false
        })
        let attrElement = AttributeListSyntax.Element.attribute(
            recordAttr.with(\.leadingTrivia, leadingTrivia).with(\.trailingTrivia, .newline)
        )
        var newAttrs = Array(declaration.attributes)
        newAttrs.insert(attrElement, at: 0)
        return declaration
            .with(\.attributes, AttributeListSyntax(newAttrs))
            .with(\.bindingSpecifier, declaration.bindingSpecifier.with(\.leadingTrivia, indentTrivia))
    }
}

// MARK: - Diagnostic types

private struct NoCodingParameterWarning: DiagnosticMessage {
    let typeName: String

    var message: String {
        "'\(typeName)' is not directly storable in UserDefaults. Add a 'coding:' parameter to specify Codable encoding/decoding strategy, or ensure the type conforms to NSCoding."
    }

    var diagnosticID: MessageID { MessageID(domain: "UserDefaultMacro", id: "noCodingParameter") }
    var severity: DiagnosticSeverity { .warning }
}

private struct AddCodingParameterFixIt: FixItMessage {
    var message: String { "Add 'coding: .plist' to use Plist encoding" }
    var fixItID: MessageID { MessageID(domain: "UserDefaultMacro", id: "addCodingParameter") }
}

private struct AddExplicitRecordWithCodingFixIt: FixItMessage {
    var message: String { "Add '@UserDefaultRecord(coding: .plist)' to use Plist encoding" }
    var fixItID: MessageID { MessageID(domain: "UserDefaultMacro", id: "addExplicitRecordWithCoding") }
}
