import Foundation

enum UserDefaultMacroError: Error, CustomStringConvertible {
    case multipleVariableDeclaration
    case immutableVariable
    case missingUserDefaults
    case noAttributeFound(attributeName: String, modelDescription: String)
    case failedRetrieveVariableType(nodeDescription: String)
    case failedRetrieveVariableTypeName(typeSyntaxDescription: String)
    case unexpectedBindingPattern(patternBindingDescription: String)
    case custom(String)

    var description: String {
        switch self {
        case .multipleVariableDeclaration:
            "Macro cannot be applied to multiple variable declarations in a single line. Declare each property separately."
        case .immutableVariable: "Macro can only be applied to mutable properties. Use 'var' instead of 'let'."
        case .missingUserDefaults: "UserDefaults instance is missing from macro parameters"
        case .noAttributeFound(let attributeName, let modelDescription):
            "Expected attribute '\(attributeName)' was not found on: \(modelDescription)"
        case .failedRetrieveVariableType(let nodeDescription):
            "Failed to retrieve property type annotation. Ensure the property has an explicit type: \(nodeDescription)"
        case .failedRetrieveVariableTypeName(let typeSyntaxDescription):
            "Failed to parse property type. Unsupported type syntax: \(typeSyntaxDescription)"
        case .unexpectedBindingPattern(let patternBindingDescription):
            "Unexpected variable binding pattern. Use simple property declarations: \(patternBindingDescription)"
        case .custom(let msg): msg
        }
    }
}
