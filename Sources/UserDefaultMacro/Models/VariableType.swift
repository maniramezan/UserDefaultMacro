import Foundation

indirect enum VariableType: CaseIterable {
    static var allCases: [VariableType] = [
        .int,
        .double,
        .float,
        .bool,
        .string,
        .url,
        .data,
        .array(elementType: .int),
        .dictionary(keyType: .int, valueType: .int),
        .object(entityTypeName: "SomeEntityName"),
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
        case .int:
            return "integer"
        case .double:
            return "double"
        case .float:
            return "float"
        case .bool:
            return "bool"
        case .string:
            return "string"
        case .url:
            return "url"
        case .data:
            return "data"
        case .array:
            return "array"
        case .dictionary:
            return "dictionary"
        case .optional(let wrappedType):
            if wrappedType.doesUserDefaultsMethodReturnNullableType {
                return wrappedType.userDefaultsMethodName
            }
            return "object"
        case .object:
            return "object"
        }
    }

    var doesUserDefaultsMethodReturnNullableType: Bool {
        switch self {
        case .object,
                .dictionary,
                .array,
                .data,
                .url,
                .string,
                .optional:
            return true
        default:
            return false
        }
    }

    var swiftType: String {
        switch self {
        case .int:
            return "Int"
        case .double:
            return "Double"
        case .float:
            return "Float"
        case .bool:
            return "Bool"
        case .string:
            return "String"
        case .url:
            return "URL"
        case .data:
            return "Data"
        case .array(let elementType):
            return "[\(elementType.swiftType)]"
        case .dictionary(let keyType, let valueType):
            return "[\(keyType.swiftType): \(valueType.swiftType)]"
        case .optional(let wrappedType):
            return "\(wrappedType.swiftType)?"
        case .object(let entityTypeName):
            return entityTypeName
        }
    }

    init(swiftTypeName: String) {
        switch swiftTypeName {
        case "Int":
            self = .int
        case "Double":
            self = .double
        case "Float":
            self = .float
        case "Bool":
            self = .bool
        case "String":
            self = .string
        case "URL":
            self = .url
        case "Data":
            self = .data
        default:
            self = .object(entityTypeName: swiftTypeName)
        }
    }

    func castExpressionIfNeeded(with defaultValue: String?, enforceUnwrap: Bool = false) -> String {
            let shouldForceUnwrap = doesUserDefaultsMethodReturnNullableType && !(defaultValue?.isEmpty ?? true)

            /// Decides whether it should force-unwrap the return value or not. This decision is made based on
            /// - `defaultValue` is set for this attribute
            /// - The return value is not optional
            switch self {
            case .array,
                    .dictionary,
                    .object:
                return " as\(shouldForceUnwrap ? "!" : "?") \(swiftType)"
            case .optional(let wrappedType):
                if wrappedType.doesUserDefaultsMethodReturnNullableType {
                    return wrappedType.castExpressionIfNeeded(with: defaultValue, enforceUnwrap: false)
                }
                return " as? \(wrappedType.swiftType)"
            default:
                return shouldForceUnwrap ? "!" : ""
            }
        }
}
