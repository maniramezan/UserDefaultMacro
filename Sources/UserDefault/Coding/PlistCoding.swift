import Foundation

/// Encodes and decodes values using `PropertyListEncoder` and `PropertyListDecoder`.
public struct PlistCoding: UserDefaultsCoding {
    public init() {}

    public func encode<T: Encodable>(_ value: T) throws -> Data { try PropertyListEncoder().encode(value) }

    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try PropertyListDecoder().decode(type, from: data)
    }
}

extension UserDefaultsCoding where Self == PlistCoding {
    /// Property-list coding strategy using `PropertyListEncoder`/`PropertyListDecoder`.
    public static var plist: PlistCoding { PlistCoding() }
}
