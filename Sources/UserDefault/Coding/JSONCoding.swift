import Foundation

/// Encodes and decodes values using `JSONEncoder` and `JSONDecoder`.
public struct JSONCoding: UserDefaultsCoding {
    public init() {}

    public func encode<T: Encodable>(_ value: T) throws -> Data { try JSONEncoder().encode(value) }

    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try JSONDecoder().decode(type, from: data)
    }
}

extension UserDefaultsCoding where Self == JSONCoding {
    /// JSON coding strategy using `JSONEncoder`/`JSONDecoder`.
    public static var json: JSONCoding { JSONCoding() }
}
