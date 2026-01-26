import Foundation

indirect enum VariableType: CaseIterable {
    static let allCases: [VariableType] = [
        .int, .double, .float, .bool, .string, .url, .data, .array(elementType: .int),
        .dictionary(keyType: .int, valueType: .int), .object(entityTypeName: "SomeEntityName"),
    ]

    case int
    case double
    case float
    case bool
    case string
    case url
    case data
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
        case .object, .dictionary, .array, .data, .url, .string, .optional: true
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
        case .array(let elementType): "[\(elementType.swiftType)]"
        case .dictionary(let keyType, let valueType): "[\(keyType.swiftType): \(valueType.swiftType)]"
        case .optional(let wrappedType): "\(wrappedType.swiftType)?"
        case .object(let entityTypeName): entityTypeName
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
        default: self = .object(entityTypeName: swiftTypeName)
        }
    }

    func castExpressionIfNeeded(with defaultValue: String?) -> String {
        _ = defaultValue

        // For nullable-returning UserDefaults accessors, unwrap/cast depends on whether the
        // declared property type is optional (skip) or non-optional (force).
        switch self {
        case .array, .dictionary, .object: return " as! \(swiftType)"
        case .optional(let wrappedType):
            switch wrappedType {
            case .array, .dictionary, .object: return " as? \(wrappedType.swiftType)"
            case .string, .url, .data: return ""
            default: return " as? \(wrappedType.swiftType)"
            }
        case .string, .url, .data: return "!"
        default: return ""
        }
    }
}
