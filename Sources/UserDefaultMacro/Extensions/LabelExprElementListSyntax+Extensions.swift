import Foundation
import SwiftSyntax

extension LabeledExprListSyntax {
    private static let userDefaultsParamLabel = "using"
    private static let keyParamLabel = "key"
    private static let defaultValueLabel = "defaultValue"
    private static let accessLevelLabel = "accessLevel"

    func tupleExprElementSyntaxLabeled(_ label: String) -> LabeledExprSyntax? { first { $0.label?.text == label } }

    func extractUserDefaultsParam(canReturnShortenVersion: Bool = false) -> String? {
        guard let tupleExprElementSyntax = tupleExprElementSyntaxLabeled(Self.userDefaultsParamLabel),
            let memberAccessExprSyntax = tupleExprElementSyntax.expression.as(MemberAccessExprSyntax.self)
        else { return nil }

        if memberAccessExprSyntax.base == nil, !canReturnShortenVersion {
            return "UserDefaults\(memberAccessExprSyntax.description)"
        }
        return memberAccessExprSyntax.description
    }

    func extractKeyParam() -> String? {
        guard let tupleExprElementSyntax = tupleExprElementSyntaxLabeled(Self.keyParamLabel) else { return nil }

        if let stringLiteralExprSyntax = tupleExprElementSyntax.expression.as(StringLiteralExprSyntax.self),
            let stringValue = stringLiteralExprSyntax.segments.first?.description
        {
            return stringValue.withDoubleQuotes
        } else if let memberAccessExprSyntax = tupleExprElementSyntax.expression.as(MemberAccessExprSyntax.self) {
            return memberAccessExprSyntax.description
        }

        return nil
    }

    func extractDefaultValueParam() -> String? {
        guard let tupleExprElementSyntax = tupleExprElementSyntaxLabeled(Self.defaultValueLabel) else { return nil }

        return tupleExprElementSyntax.expression.description
    }

    func extractAccessLevelParam() -> AccessLevel? {
        guard let tupleExprElementSyntax = tupleExprElementSyntaxLabeled(Self.accessLevelLabel),
            let memberAccessExprSyntax = tupleExprElementSyntax.expression.as(MemberAccessExprSyntax.self)
        else { return nil }

        let accessLevelString =
            memberAccessExprSyntax.base == nil
            ? memberAccessExprSyntax.description.dropFirst()
            : memberAccessExprSyntax.description.dropFirst(String(describing: AccessLevel.self).count)
        return AccessLevel(rawValue: String(accessLevelString))
    }
}
