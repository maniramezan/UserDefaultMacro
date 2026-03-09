import Foundation
import Testing

#if canImport(UserDefaultMacro)
    @testable import UserDefaultMacro

    @Suite
    struct UserDefaultsNameTests {

        // MARK: - asShortenName

        @Test
        func testAsShortenNameOnFullNameExtractsLastComponent() {
            let name = UserDefaults.Name.full("UserDefaults.standard")
            #expect(name.asShortenName == .shorten("standard"))
        }

        @Test
        func testAsShortenNameOnShortenNameReturnsSelf() {
            let name = UserDefaults.Name.shorten("standard")
            #expect(name.asShortenName == .shorten("standard"))
        }

        // MARK: - asFullName

        @Test
        func testAsFullNameOnShortenNamePrependsClassName() {
            let name = UserDefaults.Name.shorten("standard")
            #expect(name.asFullName == .full("UserDefaults.standard"))
        }

        @Test
        func testAsFullNameOnFullNameReturnsSelf() {
            let name = UserDefaults.Name.full("UserDefaults.standard")
            #expect(name.asFullName == .full("UserDefaults.standard"))
        }

        // MARK: - description

        @Test
        func testDescriptionForFullName() {
            let name = UserDefaults.Name.full("UserDefaults.standard")
            #expect(name.description == "UserDefaults.standard")
        }

        @Test
        func testDescriptionForShortenName() {
            let name = UserDefaults.Name.shorten("standard")
            #expect(name.description == ".standard")
        }

        // MARK: - Static properties

        @Test
        func testStandardName() {
            #expect(UserDefaults.standardName == .shorten("standard"))
        }

        @Test
        func testStandardFullName() {
            #expect(UserDefaults.standardFullName == .full("UserDefaults.standard"))
        }
    }

    extension UserDefaults.Name: Equatable {
        public static func == (lhs: UserDefaults.Name, rhs: UserDefaults.Name) -> Bool {
            lhs.description == rhs.description
        }
    }
#endif
