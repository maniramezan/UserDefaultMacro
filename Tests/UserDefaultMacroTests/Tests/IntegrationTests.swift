import Foundation
import SwiftSyntaxMacros
import Testing

#if canImport(UserDefaultMacro)
    @testable import UserDefaultMacro

    @Suite
    struct IntegrationTests {

        let testMacros: [String: Macro.Type] = [
            "UserDefaultDataStore": UserDefaultDataStoreMacro.self, "UserDefaultRecord": UserDefaultRecordMacro.self,
        ]

        // MARK: - Integration Tests

        // These tests verify complete macro expansion including automatic @UserDefaultRecord application

        @Test
        func testExpandsCompleteUserSettingsStore() {
            assertMacroExpansion(
                """
                @UserDefaultDataStore
                struct UserSettings {
                    var isFirstLaunch: Bool
                    var userName: String
                    var loginCount: Int
                }
                """,
                expandedSource: """
                    struct UserSettings {
                        var isFirstLaunch: Bool {
                            get {
                                userDefaults.bool(forKey: "isFirstLaunch")
                            }
                            set {
                                userDefaults.setValue(newValue, forKey: "isFirstLaunch")
                            }
                        }
                        var userName: String {
                            get {
                                userDefaults.string(forKey: "userName")
                            }
                            set {
                                userDefaults.setValue(newValue, forKey: "userName")
                            }
                        }
                        var loginCount: Int {
                            get {
                                userDefaults.integer(forKey: "loginCount")
                            }
                            set {
                                userDefaults.setValue(newValue, forKey: "loginCount")
                            }
                        }

                        private let userDefaults: UserDefaults

                        internal init(userDefaults: UserDefaults = .standard) {
                            self.userDefaults = userDefaults
                        }
                    }
                    """,
                macros: testMacros
            )
        }

        @Test
        func testExpandsStoreWithDefaultValues() {
            assertMacroExpansion(
                """
                @UserDefaultDataStore
                struct GameSettings {
                    @UserDefaultRecord(defaultValue: "Easy")
                    var difficulty: String
                    @UserDefaultRecord(defaultValue: 100)
                    var volume: Int
                }
                """,
                expandedSource: """
                    struct GameSettings {
                        var difficulty: String {
                            get {
                                userDefaults.string(forKey: "difficulty")!
                            }
                            set {
                                userDefaults.setValue(newValue, forKey: "difficulty")
                            }
                        }
                        var volume: Int {
                            get {
                                userDefaults.integer(forKey: "volume")
                            }
                            set {
                                userDefaults.setValue(newValue, forKey: "volume")
                            }
                        }

                        private let userDefaults: UserDefaults

                        internal init(userDefaults: UserDefaults = .standard) {
                            self.userDefaults = userDefaults
                            userDefaults.register(defaults: ["difficulty": "Easy", "volume": 100])
                        }
                    }
                    """,
                macros: testMacros
            )
        }

        @Test
        func testExpandsStoreWithCustomKeys() {
            assertMacroExpansion(
                """
                @UserDefaultDataStore
                struct Settings {
                    @UserDefaultRecord(key: "user_name")
                    var userName: String
                    var email: String
                }
                """,
                expandedSource: """
                    struct Settings {
                        var userName: String {
                            get {
                                userDefaults.string(forKey: "user_name")
                            }
                            set {
                                userDefaults.setValue(newValue, forKey: "user_name")
                            }
                        }
                        var email: String {
                            get {
                                userDefaults.string(forKey: "email")
                            }
                            set {
                                userDefaults.setValue(newValue, forKey: "email")
                            }
                        }

                        private let userDefaults: UserDefaults

                        internal init(userDefaults: UserDefaults = .standard) {
                            self.userDefaults = userDefaults
                        }
                    }
                    """,
                macros: testMacros
            )
        }

        @Test
        func testExpandsStoreWithPublicAccessLevel() {
            assertMacroExpansion(
                """
                @UserDefaultDataStore(accessLevel: .public)
                public struct PublicSettings {
                    var apiKey: String
                }
                """,
                expandedSource: """
                    public struct PublicSettings {
                        var apiKey: String {
                            get {
                                userDefaults.string(forKey: "apiKey")
                            }
                            set {
                                userDefaults.setValue(newValue, forKey: "apiKey")
                            }
                        }

                        private let userDefaults: UserDefaults

                        public init(userDefaults: UserDefaults = .standard) {
                            self.userDefaults = userDefaults
                        }
                    }
                    """,
                macros: testMacros
            )
        }

        @Test
        func testExpandsStoreWithStoredAndComputedProperties() {
            assertMacroExpansion(
                """
                @UserDefaultDataStore
                struct MixedSettings {
                    var storedValue: Int

                    var computedValue: String {
                        return "computed"
                    }

                    let constantValue = 42
                }
                """,
                expandedSource: """
                    struct MixedSettings {
                        var storedValue: Int {
                            get {
                                userDefaults.integer(forKey: "storedValue")
                            }
                            set {
                                userDefaults.setValue(newValue, forKey: "storedValue")
                            }
                        }

                        var computedValue: String {
                            return "computed"
                        }

                        let constantValue = 42

                        private let userDefaults: UserDefaults

                        internal init(userDefaults: UserDefaults = .standard) {
                            self.userDefaults = userDefaults
                        }
                    }
                    """,
                macros: testMacros
            )
        }

        @Test
        func testExpandsStoreWithOptionalTypes() {
            assertMacroExpansion(
                """
                @UserDefaultDataStore
                struct OptionalSettings {
                    var optionalString: String?
                    var optionalInt: Int?
                }
                """,
                expandedSource: """
                    struct OptionalSettings {
                        var optionalString: String? {
                            get {
                                userDefaults.string(forKey: "optionalString")
                            }
                            set {
                                userDefaults.setValue(newValue, forKey: "optionalString")
                            }
                        }
                        var optionalInt: Int? {
                            get {
                                userDefaults.object(forKey: "optionalInt") as? Int
                            }
                            set {
                                userDefaults.setValue(newValue, forKey: "optionalInt")
                            }
                        }

                        private let userDefaults: UserDefaults

                        internal init(userDefaults: UserDefaults = .standard) {
                            self.userDefaults = userDefaults
                        }
                    }
                    """,
                macros: testMacros
            )
        }
    }
#endif
