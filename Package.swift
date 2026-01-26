// swift-tools-version: 6.2

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "UserDefaultMacro",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        .library(
            name: "UserDefault",
            targets: ["UserDefault"]
        ),
        .executable(
            name: "UserDefaultClient",
            targets: ["UserDefaultClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "602.0.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.5"),
        .package(url: "https://github.com/apple/swift-format.git", exact: "602.0.0"),
    ],
    targets: [
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "UserDefaultMacro",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ],
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(name: "UserDefault", dependencies: ["UserDefaultMacro"]),

        // A client of the library, which is able to use the macro in its own code.
        .executableTarget(name: "UserDefaultClient", dependencies: ["UserDefault"]),

        // A test target used to develop the macro implementation.
        .testTarget(
            name: "UserDefaultTests",
            dependencies: [
                "UserDefaultMacro",
                .product(name: "SwiftSyntaxMacroExpansion", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
            ]
        ),
    ],
)
