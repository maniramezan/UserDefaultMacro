import Testing
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport

typealias DiagnosticSpec = SwiftSyntaxMacrosGenericTestSupport.DiagnosticSpec
typealias FixItSpec = SwiftSyntaxMacrosGenericTestSupport.FixItSpec
typealias NoteSpec = SwiftSyntaxMacrosGenericTestSupport.NoteSpec

private struct MacroExpansionFailure: Error, CustomStringConvertible {
    let message: String

    var description: String { message }
}

func assertMacroExpansion(
    _ originalSource: String,
    expandedSource expectedExpandedSource: String,
    diagnostics: [DiagnosticSpec] = [],
    macros: [String: Macro.Type],
    applyFixIts: [String]? = nil,
    fixedSource expectedFixedSource: String? = nil,
    testModuleName: String = "TestModule",
    testFileName: String = "test.swift",
    indentationWidth: Trivia = .spaces(4),
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
) {
    let specs = macros.mapValues { MacroSpec(type: $0) }

    SwiftSyntaxMacrosGenericTestSupport.assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        diagnostics: diagnostics,
        macroSpecs: specs,
        applyFixIts: applyFixIts,
        fixedSource: expectedFixedSource,
        testModuleName: testModuleName,
        testFileName: testFileName,
        indentationWidth: indentationWidth,
        failureHandler: { failure in
            let location = SourceLocation(
                fileID: failure.location.fileID,
                filePath: failure.location.filePath,
                line: failure.location.line,
                column: failure.location.column
            )
            Issue.record(MacroExpansionFailure(message: failure.message), sourceLocation: location)
        },
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )
}
