import Foundation

#if canImport(UserDefaultMacro)
    @testable import UserDefaultMacro

    struct SwiftAttribute: CustomStringConvertible, Hashable {

        enum ParamLabel: String {
            case userDefaults = "using"
            case key = "key"
            case defaultValue = "defaultValue"
            case accessLevel = "accessLevel"
        }

        enum Key: CustomStringConvertible {
            case string(String)
            case variable(String)

            var description: String {
                switch self {
                case .string(let key): return key.withDoubleQuotes
                case .variable(let key): return key
                }
            }
        }

        let name: String
        private let params: [ParamLabel: String]

        // MARK: - Initializer

        private init(name: String, params: [ParamLabel: String]) {
            self.name = name
            self.params = params
        }

        // MARK: - CustomStringConvertible

        var description: String {
            let paramListString: String
            if !params.isEmpty {
                paramListString =
                    "(" + params.map { key, value in "\(key.rawValue): \(value)" }.joined(separator: ", ") + ")"
            } else {
                paramListString = ""
            }
            return "@\(name)\(paramListString)"
        }

        // MARK: - Hashable

        func hash(into hasher: inout Hasher) { hasher.combine(name) }

        static func == (lhs: SwiftAttribute, rhs: SwiftAttribute) -> Bool { lhs.name == rhs.name }

        // MARK: - Initializer helper methods

        static func record(key: Key? = nil, defaultValue: String? = nil) -> SwiftAttribute {
            SwiftAttribute(
                name: UserDefaultRecordMacro.attributeName,
                params: convertToParamsDictionary(key: key?.description, defaultValue: defaultValue)
            )
        }

        static func property(userDefaults: UserDefaults.Name? = nil, key: Key? = nil, defaultValue: String? = nil)
            -> SwiftAttribute
        {
            SwiftAttribute(
                name: UserDefaultPropertyMacro.attributeName,
                params: convertToParamsDictionary(
                    userDefaults: userDefaults,
                    key: key?.description,
                    defaultValue: defaultValue
                )
            )
        }

        static func dataStore(userDefaults: UserDefaults.Name? = nil, key: Key? = nil, accessLevel: AccessLevel? = nil)
            -> SwiftAttribute
        {
            SwiftAttribute(
                name: UserDefaultDataStoreMacro.attributeName,
                params: convertToParamsDictionary(
                    userDefaults: userDefaults,
                    key: key?.description,
                    accessLevel: accessLevel
                )
            )
        }

        subscript(_ paramLabel: ParamLabel) -> String? { params[paramLabel] }

        // MARK: - Private methods

        private static func convertToParamsDictionary(
            userDefaults: UserDefaults.Name? = nil,
            key: String? = nil,
            defaultValue: String? = nil,
            accessLevel: AccessLevel? = nil
        ) -> [ParamLabel: String] {

            let keys: [ParamLabel] = [.userDefaults, .key, .defaultValue, .accessLevel]
            return zip(keys, [userDefaults?.description, key, defaultValue, accessLevel?.shortName]).reduce(into: [:]) {
                (result, pair) in
                guard let val = pair.1 else { return }
                result[pair.0] = val
            }
        }
    }
#endif
