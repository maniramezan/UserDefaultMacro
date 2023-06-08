import Foundation
import SwiftSyntax

extension AttributeListSyntax {
    func attributeSyntax(named name: String) -> AttributeSyntax? {
        compactMap { attributeListSyntaxElement -> AttributeSyntax? in
                guard case .attribute(let attributeSyntax) = attributeListSyntaxElement else {
                    return nil
                }
                guard
                    let simpleTypeIdentifierSyntax = attributeSyntax.attributeName.as(SimpleTypeIdentifierSyntax.self),
                    simpleTypeIdentifierSyntax.name.text == name
                else {
                    return nil
                }

                return attributeSyntax
        }.first
    }
}
