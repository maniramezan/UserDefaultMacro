import SwiftSyntax

@testable import UserDefaultMacro

struct Variable: CustomStringConvertible {
    enum Declaration {
        case mutable
        case immutable
        case computational(String)
    }
    
    let name: String
    let type: VariableType
    let initValue: String?
    let declaration: Declaration
    let attribute: SwiftAttribute?

    // MARK: - Initializers

    init(
        name: String,
        type: VariableType,
        initValue: String? = nil,
        declaration: Declaration = .mutable,
        attribute: SwiftAttribute? = nil
    ) {
        self.name = name
        self.type = type
        self.initValue = initValue
        self.declaration = declaration
        self.attribute = attribute
    }

    // MARK: - CustomStringConvertible

    var description: String {
        declaration()
    }

    var declarationKeyword: String {
        if case .immutable = declaration {
            return "let"
        }
        return "var"
    }

    var isMutable: Bool {
        if case .mutable = declaration {
            return true
        }
        return false
    }

    func declaration(
        currentIndent: Trivia = .spaces(0),
        extraAttribute: SwiftAttribute? = nil
    ) -> String {
        let attributes = Set([attribute, extraAttribute].compactMap { $0 })
        let attributeString = attributes
            .map { attribute in
                "\(attribute.description)\n\(currentIndent.description)"
            }.joined()
        
        return "\(attributeString)\(declarationKeyword) \(name): \(type.swiftType)\(initializer)\(body)"
    }

    // MARK: - Private members

    private var body: String {
        guard case .computational(let body) = declaration else {
            return ""
        }

        return """
         {
        \(body)
            }
        """
    }

    private var initializer: String {
        guard let initValue = initValue else {
            return ""
        }

        return " = \(initValue)"
    }
}
