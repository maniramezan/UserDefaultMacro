import Foundation

/// A protocol that defines how custom types are encoded to and decoded from `Data` for `UserDefaults` storage.
///
/// Built-in conformers:
/// - ``PlistCoding``: Uses `PropertyListEncoder`/`PropertyListDecoder` (default)
/// - ``JSONCoding``: Uses `JSONEncoder`/`JSONDecoder`
///
/// You can create custom conformers for specialized encoding needs.
public protocol UserDefaultsCoding {
    func encode<T: Encodable>(_ value: T) throws -> Data
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}
