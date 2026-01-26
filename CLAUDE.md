# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

UserDefaultMacro is a Swift macro package that generates boilerplate code for `UserDefaults` storage. Built using SwiftSyntax and the Swift Compiler Plugin architecture, it provides three macros:

- `@UserDefaultDataStore`: Attached member + member attribute macro that generates `userDefaults` property and `init(userDefaults:)` on structs/classes
- `@UserDefaultRecord`: Attached accessor macro for properties within `@UserDefaultDataStore` types
- `@UserDefaultProperty`: Standalone attached accessor macro (less recommended, may be deprecated)

## Build & Test Commands

### Using Makefile (Recommended)

```bash
# Format all Swift files
make format

# Check formatting (without changes)
make format-check

# Build the package
make build

# Run all tests
make test

# Generate documentation
make docc

# Format, build, and test
make all

# Clean build artifacts
make clean

# Show all available commands
make help
```

### Using SwiftPM Plugin Directly

```bash
# Format all Swift files (requires permission)
swift package --allow-writing-to-package-directory format-source-code --recursive .

# Check formatting without making changes
swift package lint-source-code --recursive .
```

### Using Swift Commands Directly

```bash
# Build the package
swift build

# Build with verbose output
swift build -v

# Run all tests
swift test

# Run tests with verbose output
swift test -v

# Run specific test
swift test --filter UserDefaultPropertyMacroTests

# Generate documentation
swift package generate-documentation --target UserDefault

# Build DocC for static hosting
./build-docc.sh
```

### Code Formatting

This project uses Apple's **swift-format** (integrated via SwiftPM plugin) for consistent code style:
- Maximum line width: 160 characters
- Omit explicit `return` in single-expression functions
- 4-space indentation
- Single-line property getters
- Ordered imports

Configuration is in `.swift-format` file (JSON format).

**Before committing**, run:
```bash
make format
# or
swift package --allow-writing-to-package-directory format-source-code --recursive .
```

**No external installation required** - swift-format is included as a package dependency.

## Package Structure

The package follows standard SwiftPM layout with three main targets:

1. **UserDefaultMacro** (macro target): Implements the macro transformation logic
   - Entry point: `UserDefaultPlugin.swift` - defines the `CompilerPlugin` and registers all macros
   - Core macros: `UserDefaultDataStoreMacro`, `UserDefaultRecordMacro`, `UserDefaultPropertyMacro`
   - Models: `UserDefaultsType`, `AccessLevel`, `VariableType`, `UserDefaultMacroError`
   - Extensions: SwiftSyntax helper methods for extracting macro parameters

2. **UserDefault** (library target): Public API that exposes the macros
   - `UserDefault.swift`: Macro declarations using `#externalMacro`

3. **UserDefaultClient** (executable target): Example usage for testing

## Macro Architecture

### How the Macros Work Together

`@UserDefaultDataStore` is a composite macro with two roles:

1. **MemberMacro**: Generates `userDefaults` property and `init(userDefaults:)` initializer
   - Scans all `@UserDefaultRecord` properties to extract default values
   - Registers defaults in the initializer: `userDefaults.register(defaults: [...])`

2. **MemberAttributeMacro**: Automatically applies `@UserDefaultRecord` to mutable variables without accessors
   - Filters out variables that already have `@UserDefaultRecord` or `@UserDefaultProperty`
   - Only applies to `var` properties with no body and no initializer

`@UserDefaultRecord` is an AccessorMacro that:
- Generates getter/setter using the parent type's `userDefaults` property
- Uses type-specific UserDefaults methods (`bool(forKey:)`, `integer(forKey:)`, etc.)
- Determined by `VariableType` enum which maps Swift types to UserDefaults methods

### Type System

`VariableType` enum in `Sources/UserDefaultMacro/Models/VariableType.swift` defines supported types:
- Maps Swift types (Bool, Int, String, URL, Data, etc.) to UserDefaults getter methods
- Handles optionals vs non-optionals
- Provides casting logic when default values are specified

### Parameter Extraction

The `LabeledExprElementListSyntax+Extensions.swift` file contains helper methods to parse macro arguments:
- `extractUserDefaultsParam()`: Extracts `using:` parameter
- `extractKeyParam()`: Extracts `key:` parameter
- `extractDefaultValueParam()`: Extracts `defaultValue:` parameter
- `extractAccessLevelParam()`: Extracts `accessLevel:` parameter

## Testing

Tests use `SwiftSyntaxMacrosTestSupport` framework:
- `BaseTestCase`: Shared test infrastructure with helper methods
- Test models: `Variable`, `SwiftAttribute` - represent macro inputs for test cases
- Tests verify expanded source code matches expected output

### Test Structure

- **UserDefaultDataStoreMacroTests**: Tests the composite macro (9 tests)
- **UserDefaultRecordMacroTests**: Tests accessor macro behavior (4 tests)
- **UserDefaultPropertyMacroTests**: Tests standalone macro (8 tests)
- **ErrorHandlingTests**: Verifies error diagnostics (7 tests)
- **IntegrationTests**: End-to-end scenarios with full expansion (6 tests)

Total: 34 tests with 100% pass rate

## Swift Version Requirements

- Requires Swift 6.2 (specified in Package.swift)
- Uses swift-syntax 602.0.0 (exact version)
- Uses swift-format 602.0.0 (exact version, matched to swift-syntax)
- Supports macOS 10.15+, iOS 13+, tvOS 13+, watchOS 6+, macCatalyst 13+

## CI/CD

- Uses GitHub Actions with macOS-26 runner
- Installs Swift 6.2 via Swiftly
- Runs formatting checks, build, tests, and DocC generation on PRs to main branch
- Uses swift-format plugin (no external tool installation required)

## Examples

The `Examples/` directory contains:
- `BasicUsage.swift`: Simple settings stores, default values, custom keys
- `AdvancedUsage.swift`: Custom suites, collections, Codable types, thread safety
- `README.md`: Common patterns and best practices

## Important Design Decisions

### Force Unwrapping
When users declare non-optional types, they explicitly opt into force-unwrap behavior:
```swift
var userName: String  // Generates: userDefaults.string(forKey:) with force unwrap
var userId: String?   // Generates: userDefaults.string(forKey:) without unwrap
```
This is intentional - users control unwrapping behavior through type annotations.

### Automatic @UserDefaultRecord Application
`@UserDefaultDataStore` automatically applies `@UserDefaultRecord` to:
- Properties declared with `var` (not `let`)
- Properties without accessors
- Properties without initializers
- Properties not already marked with `@UserDefaultRecord` or `@UserDefaultProperty`

### Type Support
- Primitive types: Int, Double, Float, Bool, String, URL, Data
- Collections: Arrays and Dictionaries
- Custom types: Must conform to Codable/NSCoding
- All types support optional variants
