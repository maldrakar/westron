import Foundation
import SwiftUI
import Testing

@testable import WestronUI

/// Button's style against its contract, spec/components/button/button.spec.yaml: the tokens it draws for every variant,
/// role and combination of states, evaluated from the contract's own `cases` as the contract resolves them, so the code
/// cannot drift from the file; the per-size bindings; and how a size is chosen.
@Suite("Button style")
struct ButtonStyleTests {
    // MARK: - The contract's token bindings

    /// One case of a `cases` binding: its `when` conditions and its token, nil for `null`.
    struct Case {
        var when: [String: [String]]
        var token: String?

        /// Whether a button matches: every condition holds; `state` holds when the button is in any state it lists.
        func matches(variant: ButtonVariant, destructive: Bool, states: Set<ButtonState>) -> Bool {
            when.allSatisfy { key, values in
                switch key {
                case "variant": values.contains(variant.rawValue)
                case "role": values.contains(destructive ? "destructive" : "default")
                case "state": states.contains { values.contains($0.rawValue) }
                default: false
                }
            }
        }
    }

    static func contract() throws -> String {
        try String(contentsOf: ButtonAPITests.contractFile, encoding: .utf8)
    }

    /// The lines of the contract's `tokens:` block.
    static func tokenLines() throws -> [Substring] {
        let lines = try contract().split(separator: "\n", omittingEmptySubsequences: false)
        let start = try #require(lines.firstIndex(of: "tokens:"))
        let rest = lines[(start + 1)...]
        let end = rest.firstIndex { !$0.isEmpty && !$0.hasPrefix(" ") } ?? rest.endIndex
        return Array(rest[..<end])
    }

    /// Splits on commas outside brackets and braces.
    static func splitTopLevel(_ text: Substring) -> [Substring] {
        var parts: [Substring] = []
        var depth = 0
        var start = text.startIndex
        for index in text.indices {
            switch text[index] {
            case "[", "{": depth += 1
            case "]", "}": depth -= 1
            case "," where depth == 0:
                parts.append(text[start..<index])
                start = text.index(after: index)
            default: break
            }
        }
        parts.append(text[start...])
        return parts.map { $0.trimmingCharacters(in: .whitespaces)[...] }
    }

    /// `key: value` or `key: [a, b]` → the key and its values.
    static func keyValues(_ pair: Substring) throws -> (String, [String]) {
        let colon = try #require(pair.firstIndex(of: ":"))
        let key = pair[..<colon].trimmingCharacters(in: .whitespaces)
        var value = pair[pair.index(after: colon)...].trimmingCharacters(in: .whitespaces)
        if value.hasPrefix("[") && value.hasSuffix("]") {
            value = String(value.dropFirst().dropLast())
            return (key, value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
        }
        return (key, [value])
    }

    /// The cases of a binding, `  <name>:` followed by `    cases:` and one `- { when: {…}, token: … }` per line.
    static func cases(_ binding: String) throws -> [Case] {
        let lines = try tokenLines()
        let start = try #require(lines.firstIndex(of: "  \(binding):"[...]), "no binding \(binding) in the contract")
        #expect(lines[start + 1] == "    cases:")
        var result: [Case] = []
        for line in lines[(start + 2)...] {
            let text = line.trimmingCharacters(in: .whitespaces)
            if text.hasPrefix("#") { continue }
            guard text.hasPrefix("- {") else { break }
            let body = text.dropFirst(3).dropLast().trimmingCharacters(in: .whitespaces)
            var when: [String: [String]] = [:]
            var token: String?
            for part in splitTopLevel(body[...]) {
                if part.hasPrefix("when:") {
                    let inner = part.dropFirst("when:".count).trimmingCharacters(in: .whitespaces)
                    for condition in splitTopLevel(inner.dropFirst().dropLast()) {
                        let (key, values) = try keyValues(condition)
                        when[key] = values
                    }
                } else {
                    let (key, values) = try keyValues(part)
                    #expect(key == "token")
                    token = values[0] == "null" ? nil : values[0]
                }
            }
            result.append(Case(when: when, token: token))
        }
        #expect(!result.isEmpty, "no cases for \(binding)")
        return result
    }

    /// A per-size binding, `  <name>: { s: …, m: …, l: … }`.
    static func bySize(_ binding: String) throws -> [String: String] {
        let lines = try tokenLines()
        let line = try #require(lines.first { $0.hasPrefix("  \(binding): {") }, "no binding \(binding)")
        let body = try #require(line.split(separator: "{", maxSplits: 1).last).dropLast()
        var result: [String: String] = [:]
        for pair in splitTopLevel(body.trimmingCharacters(in: .whitespaces)[...]) {
            let (key, values) = try keyValues(pair)
            result[key] = values[0]
        }
        return result
    }

    /// A single-token binding, `  <name>: token`.
    static func single(_ binding: String) throws -> String {
        let lines = try tokenLines()
        let line = try #require(lines.first { $0.hasPrefix("  \(binding): ") }, "no binding \(binding)")
        return String(line.dropFirst("  \(binding): ".count))
    }

    /// Every combination of the contract's states, the empty one (rest) included.
    static let stateCombinations: [Set<ButtonState>] = ButtonState.allCases.reduce([[]]) { sets, state in
        sets + sets.map { $0.union([state]) }
    }

    @Test(
        "every variant × role × combination of states draws the tokens the contract's cases give, first match winning",
        arguments: ButtonVariant.allCases, [false, true])
    func tokensMatchTheContract(variant: ButtonVariant, destructive: Bool) throws {
        let bindings: [(name: String, cases: [Case], drawn: (ButtonTokens) -> String?)] = [
            ("container.background", try Self.cases("container.background"), { $0.background?.name }),
            ("container.borderColor", try Self.cases("container.borderColor"), { $0.borderColor?.name }),
            ("container.borderWidth", try Self.cases("container.borderWidth"), { $0.borderWidth?.name }),
            ("container.opacity", try Self.cases("container.opacity"), { $0.opacity?.name }),
            ("label.color", try Self.cases("label.color"), { $0.label.name }),
            ("icon.color", try Self.cases("icon.color"), { $0.icon.name }),
            ("progress.color", try Self.cases("progress.color"), { $0.progress.name }),
        ]
        #expect(Self.stateCombinations.count == 32)
        for states in Self.stateCombinations {
            let tokens = ButtonTokens(variant: variant, destructive: destructive, states: states)
            for binding in bindings {
                let expected = binding.cases.first {
                    $0.matches(variant: variant, destructive: destructive, states: states)
                }?.token
                #expect(
                    binding.drawn(tokens) == expected,
                    "\(binding.name), \(variant) \(destructive ? "destructive" : "default"), states \(states.map(\.rawValue).sorted())"
                )
            }
        }
    }

    @Test("disabled and loading exclude hover and pressed: the resting fill holds and a press does not scale")
    func disabledAndLoadingExcludeHoverAndPressed() {
        for variant in ButtonVariant.allCases {
            for destructive in [false, true] {
                let rest = ButtonTokens(variant: variant, destructive: destructive, states: [])
                for excluding in [ButtonState.disabled, .loading] {
                    for tint in [ButtonState.hover, .pressed] {
                        let tokens = ButtonTokens(
                            variant: variant, destructive: destructive, states: [excluding, tint])
                        #expect(tokens.background == rest.background)
                    }
                    #expect(!ButtonTokens.scalesDown(states: [excluding, .pressed]))
                }
                // Loading does not dim; disabled does.
                #expect(ButtonTokens(variant: variant, destructive: destructive, states: [.loading]).opacity == nil)
                #expect(
                    ButtonTokens(variant: variant, destructive: destructive, states: [.disabled]).opacity
                        == .opacity.disabled)
            }
        }
        #expect(ButtonTokens.scalesDown(states: [.pressed]))
        #expect(ButtonTokens.scalesDown(states: [.pressed, .hover, .focus]))
        #expect(!ButtonTokens.scalesDown(states: [.hover]))
    }

    @Test("the per-size bindings are the contract's: height, padding, gap, label and icon fonts; one radius")
    func metricsMatchTheContract() throws {
        let height = try Self.bySize("container.height")
        let padding = try Self.bySize("container.paddingHorizontal")
        let gap = try Self.bySize("container.gap")
        let labelFont = try Self.bySize("label.font")
        let iconFont = try Self.bySize("icon.font")
        for size in ButtonSize.allCases {
            let metrics = ButtonMetrics(size)
            let key = size.offered.rawValue
            #expect(metrics.height.name == height[key])
            #expect(metrics.paddingHorizontal.name == padding[key])
            #expect(metrics.gap.name == gap[key])
            #expect(metrics.labelFont.name == labelFont[key])
            #expect(metrics.iconFont.name == iconFont[key])
        }
        #expect(ButtonMetrics.radius.name == (try Self.single("container.radius")))
        #expect(try Self.single("container.pressMotion") == Westron.Transition.press.name)
        #expect(try Self.single("container.hoverMotion") == Westron.Transition.fade.name)
    }

    // MARK: - Size

    @Test("an explicit size wins over controlSize; without one, controlSize decides; then the OS's offered size")
    func sizeResolution() {
        let controlSizes: [ControlSize] = [.mini, .small, .regular, .large, .extraLarge]
        for controlSize in controlSizes {
            for size in ButtonSize.allCases {
                #expect(ButtonSize.resolved(explicit: size, controlSize: controlSize) == size.offered)
            }
            #expect(ButtonSize.resolved(explicit: nil, controlSize: controlSize) == ButtonSize(controlSize).offered)
        }
        #if os(watchOS)
            // The watch offers only m (the contract's platforms block).
            #expect(ButtonSize.allCases.map(\.offered) == [.m, .m, .m])
        #else
            #expect(ButtonSize.resolved(explicit: nil, controlSize: .mini) == .s)
            #expect(ButtonSize.resolved(explicit: nil, controlSize: .regular) == .m)
            #expect(ButtonSize.resolved(explicit: nil, controlSize: .extraLarge) == .l)
            #expect(ButtonSize.resolved(explicit: .s, controlSize: .large) == .s)
        #endif
    }

    // MARK: - Hit area

    @Test("the hit area grows to the recommended target around what is drawn, and never shrinks it")
    func hitArea() {
        let target = CGFloat(ButtonMetrics.minimumTarget)
        let small = CGRect(x: 10, y: 20, width: target / 2, height: target / 2)
        let grown = MinimumTargetShape.target(around: small, minSide: target)
        #expect(grown.width == target && grown.height == target)
        #expect(grown.midX == small.midX && grown.midY == small.midY)
        let large = CGRect(x: 0, y: 0, width: target * 3, height: target * 2)
        #expect(MinimumTargetShape.target(around: large, minSide: target) == large)
        #if os(macOS)
            // The Mac's recommended target is 28 (chapter 08); size.control.m is 32 there.
            #expect(target >= 28)
        #elseif os(iOS) || os(watchOS)
            #expect(target == 44)
        #endif
    }

    // MARK: - The catalog's hook

    @Test("the catalog's states are the contract's, in its order")
    func catalogStates() throws {
        #expect(ButtonCatalogState.all.map(\.name) == (try ButtonAPITests.contractStates()))
        #expect(ButtonCatalogState(named: "hover")?.name == "hover")
        #expect(ButtonCatalogState(named: "glowing") == nil)
        #expect(EnvironmentValues().forcedButtonStates.isEmpty)
    }
}
