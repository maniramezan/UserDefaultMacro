// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0-swift-5.9-DEVELOPMENT-SNAPSHOT-2023-04-25-b"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
    ],
    targets: [
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "UserDefaultMacro",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
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
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
