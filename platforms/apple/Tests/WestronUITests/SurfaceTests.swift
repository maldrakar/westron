import Foundation
import SwiftUI
import Testing

@testable import WestronUI

/// Surface against its contract, spec/components/surface/surface.spec.yaml: the tokens each kind draws in the standard
/// themes, read from the contract's own `cases`, so the code cannot drift from the file; the high-contrast line its
/// description adds; and that it adds no padding.
@Suite("Surface")
@MainActor
struct SurfaceTests {
    static let contractFile = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("spec/components/surface/surface.spec.yaml")

    /// One case of a `cases` binding: its `when` conditions and its token.
    struct Case {
        var when: [String: [String]]
        var token: String

        func matches(variant: SurfaceVariant, outlined: Bool) -> Bool {
            when.allSatisfy { key, values in
                switch key {
                case "variant": values.contains(variant.rawValue)
                case "outlined": values.contains(String(outlined))
                default: false
                }
            }
        }
    }

    /// The cases of a binding in the contract's `tokens:` block, each written on one line,
    /// `- { when: { variant: [raised, dragged] }, token: color.background.surface }`. The root package has no YAML
    /// reader.
    static func cases(_ binding: String) throws -> [Case] {
        let text = try String(contentsOf: contractFile, encoding: .utf8)
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        let tokens = try #require(lines.firstIndex(of: "tokens:"))
        let start = try #require(lines[tokens...].firstIndex(of: "  \(binding):"))
        var result: [Case] = []
        for line in lines[(start + 1)...] {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "cases:" { continue }
            guard trimmed.hasPrefix("- { when: { ") else { break }
            let body = trimmed.dropFirst("- { when: { ".count)
            let parts = body.components(separatedBy: " }, token: ")
            let condition = parts[0].split(separator: ":", maxSplits: 1).map {
                $0.trimmingCharacters(in: .whitespaces)
            }
            let values = condition[1].trimmingCharacters(in: CharacterSet(charactersIn: "[]")).split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
            let token = parts[1].trimmingCharacters(in: CharacterSet(charactersIn: " }"))
            result.append(Case(when: [condition[0]: values], token: token))
        }
        try #require(!result.isEmpty, "no cases for \(binding)")
        return result
    }

    /// The token the contract's binding gives a surface: its first matching case; nil when none matches.
    static func bound(_ binding: String, variant: SurfaceVariant, outlined: Bool) throws -> String? {
        try cases(binding).first { $0.matches(variant: variant, outlined: outlined) }?.token
    }

    @Test(
        "in the standard themes each kind draws the tokens the contract binds",
        arguments: SurfaceVariant.allCases, [false, true])
    func standardThemes(variant: SurfaceVariant, outlined: Bool) throws {
        let tokens = SurfaceTokens(variant: variant, outlined: outlined, highContrast: false)
        #expect(
            tokens.background.name == (try Self.bound("container.background", variant: variant, outlined: outlined)))
        #expect(tokens.shadow?.name == (try Self.bound("container.shadow", variant: variant, outlined: outlined)))
        #expect(
            tokens.borderColor?.name == (try Self.bound("container.borderColor", variant: variant, outlined: outlined)))
        #expect(
            tokens.borderWidth?.name == (try Self.bound("container.borderWidth", variant: variant, outlined: outlined)))
    }

    @Test("every kind draws the radius the contract binds, container.radius")
    func radius() throws {
        let text = try String(contentsOf: Self.contractFile, encoding: .utf8)
        let line = try #require(text.split(separator: "\n").first { $0.hasPrefix("  container.radius:") })
        #expect(SurfaceTokens.radius.name == line.split(separator: ":")[1].trimmingCharacters(in: .whitespaces))
    }

    @Test("the kinds' grounds and shadows, as the contract names them")
    func kinds() {
        let raised = SurfaceTokens(variant: .raised, outlined: false, highContrast: false)
        let dragged = SurfaceTokens(variant: .dragged, outlined: false, highContrast: false)
        let sunken = SurfaceTokens(variant: .sunken, outlined: false, highContrast: false)
        #expect(raised.background == .background.surface && raised.shadow == .raised)
        #expect(dragged.background == .background.surface && dragged.shadow == .dragged)
        #expect(sunken.background == .background.sunken && sunken.shadow == nil)
        #expect([raised, dragged, sunken].allSatisfy { $0.borderColor == nil && $0.borderWidth == nil })
    }

    @Test(
        "in high contrast raised and dragged draw stroke.thin, outlined or not; a well only its hairline",
        arguments: SurfaceVariant.allCases, [false, true])
    func highContrast(variant: SurfaceVariant, outlined: Bool) {
        let tokens = SurfaceTokens(variant: variant, outlined: outlined, highContrast: true)
        let standard = SurfaceTokens(variant: variant, outlined: outlined, highContrast: false)
        // The ground and the shadow are the standard themes' tokens; their values switch with the theme.
        #expect(tokens.background == standard.background && tokens.shadow == standard.shadow)
        switch variant {
        case .raised, .dragged:
            #expect(tokens.borderColor == .border.default)
            #expect(tokens.borderWidth == .stroke.thin)
        case .sunken:
            #expect(tokens.borderColor == (outlined ? .border.default : nil))
            #expect(tokens.borderWidth == (outlined ? .stroke.hairline : nil))
        }
    }

    @Test("a surface adds no padding: the content keeps its size", arguments: SurfaceVariant.allCases, [false, true])
    func noPadding(variant: SurfaceVariant, outlined: Bool) {
        let content = Text("Card").textRole(.body.regular)
        #expect(fittingSize(content.surface(variant, outlined: outlined)) == fittingSize(content))
    }
}

/// The size a view takes when it is offered `proposal`, laid out off screen.
@MainActor
func fittingSize<V: View>(_ view: V, in proposal: CGSize = CGSize(width: 1000, height: 1000)) -> CGSize {
    #if canImport(AppKit)
        NSHostingController(rootView: view).sizeThatFits(in: proposal)
    #else
        UIHostingController(rootView: view).sizeThatFits(in: proposal)
    #endif
}
