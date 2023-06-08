import Foundation

enum UserDefaultMacroError: Error, CustomStringConvertible {
    case multipleVariableDeclaration
    case immutableVariable
    case missingUserDefaults
    case noAttributeFound(attributeName: String, modelDescription: String)
    case failedRetrieveVariableType(nodeDescription: String)
    case failedRetrieveVariableTypeName(typeSyntaxDescription: String)
    case unexpectedBindingPattern(patternBindingDescription: String)
    case oops
    case custom(String)

    var description: String {
        switch self {
        case .multipleVariableDeclaration:
            return "Can't be applied to multi-declaration variable in one line"
        case .immutableVariable:
            return "Array should be defined at mutable, `var`"
        case .missingUserDefaults:
            return "UserDefaults is missing from parameters"
        case .noAttributeFound(let attributeName, let modelDescription):
            return "Expected \(attributeName), but no such attribute found on the model tree: \(modelDescription)"
        case .failedRetrieveVariableType(let nodeDescription):
            return "Failed to retrieve variable type: \(nodeDescription)"
        case .failedRetrieveVariableTypeName(let typeSyntaxDescription):
            return "Failed to retrieve variable type name from typeSyntax: \(typeSyntaxDescription)"
        case .unexpectedBindingPattern(let patternBindingDescription):
            return "Unexpected pattern binding: \(patternBindingDescription)"
        case .oops:
            return "Oops, something went wrong!"
        case .custom(let msg):
            return msg
        }
    }
}
