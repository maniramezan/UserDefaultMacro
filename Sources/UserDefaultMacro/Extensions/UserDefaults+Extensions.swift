import Foundation

extension UserDefaults {
    static var userDefaultsClassName: String { "UserDefaults" }

    enum Name: CustomStringConvertible {
        case full(String)
        case shorten(String)

        var asShortenName: Name {
            switch self {
            case .full(let fullName):
                guard let shortName = fullName.split(separator: ".").last else {
                    assertionFailure("Unexpected user defaults full name.")
                    return UserDefaults.standardName
                }
                return .shorten(String(shortName))
            case .shorten: return self
            }
        }

        var asFullName: Name {
            switch self {
            case .full: self
            case .shorten(let shortName): .full("\(userDefaultsClassName).\(shortName)")
            }
        }

        var description: String {
            switch self {
            case .full(let fullName): fullName
            case .shorten(let shortName): ".\(shortName)"
            }
        }
    }

    static let standardFullName: Name = standardName.asFullName

    static let standardName: Name = .shorten("standard")
}
