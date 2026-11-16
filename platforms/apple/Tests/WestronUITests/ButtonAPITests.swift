import Foundation
import SwiftUI
import Testing

@testable import WestronUI

/// The Button API generated from spec/components/button/button.spec.yaml (#20): the names equal the contract's, and the
/// tables match the conventions (spec/conventions.md).
@Suite("Button API")
struct ButtonAPITests {
    static let contractFile = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("spec/components/button/button.spec.yaml")

    /// The values of an enum option as the contract lists them: the first `values: [...]` after `  <option>:` in its
    /// `options` block. The root package has no YAML reader; the contract writes each list on one line.
    static func contractValues(_ option: String) throws -> [String] {
        let text = try String(contentsOf: contractFile, encoding: .utf8)
        let options = try #require(text.range(of: "\noptions:\n"))
        let start = try #require(text.range(of: "\n  \(option):\n", range: options.lowerBound..<text.endIndex))
        let values = try #require(text.range(of: "values: [", range: start.upperBound..<text.endIndex))
        let end = try #require(text.range(of: "]", range: values.upperBound..<text.endIndex))
        return text[values.upperBound..<end.lowerBound].split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespaces)
        }
    }

    /// The contract's `states: [...]` line.
    static func contractStates() throws -> [String] {
        let text = try String(contentsOf: contractFile, encoding: .utf8)
        let start = try #require(text.range(of: "\nstates: ["))
        let end = try #require(text.range(of: "]", range: start.upperBound..<text.endIndex))
        return text[start.upperBound..<end.lowerBound].split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespaces)
        }
    }

    @Test("the enums' cases are the contract's values, in its order, with the values as raw values")
    func enumsMatchTheContract() throws {
        #expect(ButtonVariant.allCases.map(\.rawValue) == ["primary", "secondary", "tertiary"])
        #expect(ButtonSize.allCases.map(\.rawValue) == ["s", "m", "l"])
        let variants = try Self.contractValues("variant")
        let sizes = try Self.contractValues("size")
        let states = try Self.contractStates()
        #expect(ButtonVariant.allCases.map(\.rawValue) == variants)
        #expect(ButtonSize.allCases.map(\.rawValue) == sizes)
        #expect(ButtonState.allCases.map(\.rawValue) == states)
        for variant in ButtonVariant.allCases { #expect(ButtonVariant(rawValue: variant.rawValue) == variant) }
    }

    @Test("a call without size: maps controlSize: mini and small → s, regular → m, large and extraLarge → l")
    func controlSizeMapping() {
        #expect(ButtonSize(.mini) == .s)
        #expect(ButtonSize(.small) == .s)
        #expect(ButtonSize(.regular) == .m)
        #expect(ButtonSize(.large) == .l)
        #expect(ButtonSize(.extraLarge) == .l)
    }

    @Test("every size and state is offered on macOS; the watch's fallback to m is compiled out here")
    func offeredOnMacOS() {
        #if os(macOS)
            #expect(ButtonSize.allCases.map(\.offered) == ButtonSize.allCases)
            #expect(ButtonVariant.allCases.map(\.offered) == ButtonVariant.allCases)
            #expect(ButtonState.allCases.map(\.isEntered) == ButtonState.allCases.map { _ in true })
        #endif
    }

    @Test("the overload takes a variant, an optional size and iconOnly; loading defaults to false")
    @MainActor
    func overload() {
        _ = Button("Save") {}.buttonStyle(.primary)
        _ = Button("Save") {}.buttonStyle(.secondary, size: .s)
        _ = Button("More") {}.buttonStyle(.tertiary, size: .l, iconOnly: true).loading(true)
        #expect(EnvironmentValues().isLoading == false)
    }
}
