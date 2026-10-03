import Foundation

/// Encodes and decodes values using `PropertyListEncoder` and `PropertyListDecoder`.
///
/// Scalar roots use a keyed envelope because property lists require a container root.
/// Existing container data keeps its original representation and remains readable.
public struct PlistCoding: UserDefaultsCoding {
    /// Creates a property-list coder.
    public init() {}

    /// Encodes containers directly and wraps scalar roots in a keyed envelope.
    /// - Parameter value: The encodable value to persist.
    /// - Returns: Property-list bytes.
    /// - Throws: An encoding error if the value cannot be encoded.
    public func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = PropertyListEncoder()
        do { return try encoder.encode(value) } catch {
            // Property lists reject scalar roots, including raw-value Codable enums.
            // Preserve the existing representation for containers; wrap scalar roots only.
            return try encoder.encode(ScalarEnvelope(value: value))
        }
    }

    /// Decodes existing container data or an enveloped scalar root.
    /// - Parameters:
    ///   - type: The expected value type.
    ///   - data: Previously encoded property-list bytes.
    /// - Returns: The decoded value.
    /// - Throws: A decoding error for invalid or incompatible data.
    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = PropertyListDecoder()
        do { return try decoder.decode(type, from: data) } catch {
            return try decoder.decode(ScalarEnvelope<T>.self, from: data).value
        }
    }
}

extension UserDefaultsCoding where Self == PlistCoding {
    /// Property-list coding strategy using `PropertyListEncoder`/`PropertyListDecoder`.
    public static var plist: PlistCoding { PlistCoding() }
}

private struct ScalarEnvelope<Value> { let value: Value }

extension ScalarEnvelope: Encodable where Value: Encodable {}
extension ScalarEnvelope: Decodable where Value: Decodable {}
