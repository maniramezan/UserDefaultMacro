import Foundation
import SwiftSyntax

indirect enum VariableType: CaseIterable, Sendable {
    static let allCases: [VariableType] = [
        .int, .double, .float, .bool, .string, .url, .data, .date, .array(elementType: .int),
        .dictionary(keyType: .int, valueType: .int), .object(entityTypeName: "SomeEntityName"),
    ]

    case int
    case double
    case float
    case bool
    case string
    case url
    case data
    case date
    case array(elementType: VariableType)
    case dictionary(keyType: VariableType, valueType: VariableType)
    case object(entityTypeName: String)
    case optional(wrappedType: VariableType)

    var userDefaultsMethodName: String {
        switch self {
        case .int: return "integer"
        case .double: return "double"
        case .float: return "float"
        case .bool: return "bool"
        case .string: return "string"
        case .url: return "url"
        case .data: return "data"
        case .date: return "object"
        case .array: return "array"
        case .dictionary: return "dictionary"
        case .optional(let wrappedType):
            if wrappedType.doesUserDefaultsMethodReturnNullableType { return wrappedType.userDefaultsMethodName }
            return "object"
        case .object: return "object"
        }
    }

    var doesUserDefaultsMethodReturnNullableType: Bool {
        switch self {
        case .object, .date, .dictionary, .array, .data, .url, .string, .optional: true
        default: false
        }
    }

    var swiftType: String {
        switch self {
        case .int: "Int"
        case .double: "Double"
        case .float: "Float"
        case .bool: "Bool"
        case .string: "String"
        case .url: "URL"
        case .data: "Data"
        case .date: "Date"
        case .array(let elementType): "[\(elementType.swiftType)]"
        case .dictionary(let keyType, let valueType): "[\(keyType.swiftType): \(valueType.swiftType)]"
        case .optional(let wrappedType): "\(wrappedType.swiftType)?"
        case .object(let entityTypeName): entityTypeName
        }
    }

    var isPlistSafe: Bool {
        switch self {
        case .int, .double, .float, .bool, .string, .data, .url, .date: true
        case .array(let elementType): elementType.isPlistSafe
        case .dictionary(let keyType, let valueType): keyType.isPlistSafe && valueType.isPlistSafe
        case .optional(let wrappedType): wrappedType.isPlistSafe
        case .object: false
        }
    }

    init(swiftTypeName: String) {
        switch swiftTypeName {
        case "Int": self = .int
        case "Double": self = .double
        case "Float": self = .float
        case "Bool": self = .bool
        case "String": self = .string
        case "URL": self = .url
        case "Data": self = .data
        case "Date": self = .date
        default: self = .object(entityTypeName: swiftTypeName)
        }
    }

    init(from typeSyntax: TypeSyntax) throws {
        if let optionalTypeSyntax = typeSyntax.as(OptionalTypeSyntax.self) {
            let wrappedType = try VariableType(from: optionalTypeSyntax.wrappedType)
            self = .optional(wrappedType: wrappedType)
            return
        }

        if let identifierTypeSyntax = typeSyntax.as(IdentifierTypeSyntax.self) {
            guard case .identifier(let typeName) = identifierTypeSyntax.name.tokenKind else {
                throw UserDefaultMacroError.failedRetrieveVariableTypeName(
                    typeSyntaxDescription: typeSyntax.debugDescription
                )
            }
            self = VariableType(swiftTypeName: typeName)
            return
        }

        if let dictionaryTypeSyntax = typeSyntax.as(DictionaryTypeSyntax.self) {
            let keyType = try VariableType(from: dictionaryTypeSyntax.key)
            let valueType = try VariableType(from: dictionaryTypeSyntax.value)
            self = .dictionary(keyType: keyType, valueType: valueType)
            return
        }

        if let arrayTypeSyntax = typeSyntax.as(ArrayTypeSyntax.self) {
            let elementType = try VariableType(from: arrayTypeSyntax.element)
            self = .array(elementType: elementType)
            return
        }

        throw UserDefaultMacroError.failedRetrieveVariableTypeName(typeSyntaxDescription: typeSyntax.debugDescription)
    }

    func castExpressionIfNeeded() -> String {
        // For nullable-returning UserDefaults accessors, unwrap/cast depends on whether the
        // declared property type is optional (skip) or non-optional (force).
        switch self {
        case .array, .dictionary, .object, .date: return " as! \(swiftType)"
        case .optional(let wrappedType):
            switch wrappedType {
            case .array, .dictionary, .object, .date: return " as? \(wrappedType.swiftType)"
            case .string, .url, .data: return ""
            default: return " as? \(wrappedType.swiftType)"
            }
        case .string, .url, .data: return "!"
        default: return ""
        }
    }
}
