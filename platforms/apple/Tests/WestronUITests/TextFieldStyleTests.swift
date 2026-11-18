import Foundation
import SwiftUI
import Testing

@testable import WestronUI

/// TextField's style against its contract, spec/components/text-field/text-field.spec.yaml: the tokens it draws for
/// every variant, size and combination of states, evaluated from the contract's own `cases` as the contract resolves
/// them, so the code cannot drift from the file; how a size is chosen; the hit area's minimum; and the catalog's hook.
@Suite("TextField style")
struct TextFieldStyleTests {
    static let contractFile = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("spec/components/text-field/text-field.spec.yaml")

    // MARK: - The contract's token bindings

    /// One case of a `cases` binding: its `when` conditions and its token.
    struct Case {
        var when: [String: String]
        var token: String

        /// Whether a field matches: every condition holds; `state` holds when the field is in that state.
        func matches(variant: TextFieldVariant, size: TextFieldSize, states: Set<TextFieldState>) -> Bool {
            when.allSatisfy { key, value in
                switch key {
                case "variant": value == variant.rawValue
                case "size": value == size.offered.rawValue
                case "state": states.contains { $0.rawValue == value }
                default: false
                }
            }
        }
    }

    /// The lines of the contract's `tokens:` block.
    static func tokenLines() throws -> [Substring] {
        let lines = try String(contentsOf: contractFile, encoding: .utf8)
            .split(separator: "\n", omittingEmptySubsequences: false)
        let start = try #require(lines.firstIndex(of: "tokens:"))
        let rest = lines[(start + 1)...]
        let end = rest.firstIndex { !$0.isEmpty && !$0.hasPrefix(" ") } ?? rest.endIndex
        return Array(rest[..<end])
    }

    /// The cases of a binding: `  <name>:`, `    cases:`, then one `- { when: { k: v, … }, token: t }` per line. The
    /// contract writes each condition with a single value.
    static func cases(_ binding: String) throws -> [Case] {
        let lines = try tokenLines()
        let start = try #require(lines.firstIndex(of: "  \(binding):"[...]), "no binding \(binding) in the contract")
        #expect(lines[start + 1] == "    cases:")
        var result: [Case] = []
        for line in lines[(start + 2)...] {
            let text = line.trimmingCharacters(in: .whitespaces)
            guard text.hasPrefix("- {") else { break }
            let when = try #require(text.range(of: "when: {")).upperBound
            let close = try #require(text[when...].firstIndex(of: "}"))
            var conditions: [String: String] = [:]
            for pair in text[when..<close].split(separator: ",") {
                let parts = pair.split(separator: ":").map { $0.trimmingCharacters(in: .whitespaces) }
                conditions[parts[0]] = parts[1]
            }
            let token = try #require(text.range(of: "token: ")).upperBound
            let value = text[token...].trimmingCharacters(in: CharacterSet(charactersIn: " }"))
            result.append(Case(when: conditions, token: value))
        }
        #expect(!result.isEmpty, "no cases for \(binding)")
        return result
    }

    /// Every combination of the contract's states, the empty one (rest) included.
    static let stateCombinations: [Set<TextFieldState>] = TextFieldState.allCases.reduce([[]]) { sets, state in
        sets + sets.map { $0.union([state]) }
    }

    /// Every binding the contract's `tokens` block names, `  <name>:` or `  <name>: <token>`.
    static func bindingNames() throws -> Set<String> {
        Set(
            try tokenLines().compactMap { line -> String? in
                guard line.hasPrefix("  "), !line.hasPrefix("   "), let colon = line.firstIndex(of: ":") else {
                    return nil
                }
                return line[..<colon].trimmingCharacters(in: .whitespaces)
            })
    }

    @Test("every binding of the contract is drawn by the style, or is the one it cannot draw")
    func everyBindingIsKnown() throws {
        let drawn: Set = [
            "container.height", "container.radius", "container.paddingHorizontal", "container.borderColor",
            "container.borderWidth", "container.opacity", "text.font", "text.color", "focusRing.color",
            "focusRing.width",
        ]
        // A TextFieldStyle cannot color the system field's prompt (TextFieldTokens): the contract binds it, and who
        // applies it on Apple is an open question (#30). A binding added to the contract fails here until the style
        // draws it.
        let notDrawn: Set = ["placeholder.color"]
        #expect(try Self.bindingNames() == drawn.union(notDrawn))
        withKnownIssue("placeholder.color is not applied on Apple; an open question for the owner (#30)") {
            #expect(drawn.isSuperset(of: notDrawn))
        }
    }

    @Test(
        "every variant × size × combination of states draws the tokens the contract's cases give, first match winning",
        arguments: TextFieldVariant.allCases, TextFieldSize.allCases)
    func tokensMatchTheContract(variant: TextFieldVariant, size: TextFieldSize) throws {
        let metrics = TextFieldMetrics(variant: variant, size: size)
        let bindings: [(name: String, drawn: (TextFieldTokens) -> String?)] = [
            ("container.height", { _ in metrics.height?.name }),
            ("container.radius", { _ in metrics.radius?.name }),
            ("container.paddingHorizontal", { _ in metrics.paddingHorizontal?.name }),
            ("container.borderColor", { $0.borderColor?.name }),
            ("container.borderWidth", { $0.borderWidth?.name }),
            ("container.opacity", { $0.opacity?.name }),
            ("text.font", { $0.textFont?.name }),
            ("text.color", { $0.textColor?.name }),
            ("focusRing.color", { $0.focusRingColor?.name }),
            ("focusRing.width", { $0.focusRingWidth?.name }),
        ]
        #expect(Self.stateCombinations.count == 4)
        for states in Self.stateCombinations {
            let tokens = TextFieldTokens(variant: variant, states: states)
            for binding in bindings {
                let entered = states.filter(\.isEntered)
                let expected = try Self.cases(binding.name).first {
                    $0.matches(variant: variant, size: size, states: entered)
                }?.token
                #expect(
                    binding.drawn(tokens) == expected,
                    "\(binding.name), \(variant) \(size), states \(states.map(\.rawValue).sorted())")
            }
        }
    }

    @Test("inline leaves the text role and the text color to its context, and has no frame, height or padding")
    func inlineTakesItsContext() {
        for size in TextFieldSize.allCases {
            for states in Self.stateCombinations {
                let tokens = TextFieldTokens(variant: .inline, states: states)
                #expect(tokens.textFont == nil)
                #expect(tokens.textColor == nil)
                #expect(tokens.borderColor == nil)
            }
            #expect(TextFieldMetrics(variant: .inline, size: size) == TextFieldMetrics(variant: .inline, size: .m))
            #expect(TextFieldMetrics(variant: .inline, size: size).height == nil)
            #expect(TextFieldMetrics(variant: .inline, size: size).paddingHorizontal == nil)
        }
        // framed sets body.regular in text.primary at every size (P3, P13).
        #expect(TextFieldTokens(variant: .framed, states: []).textFont == .body.regular)
        #expect(TextFieldTokens(variant: .framed, states: []).textColor == .text.primary)
    }

    @Test("focus draws westron's ring on iOS and macOS; disabled dims the whole field; the watch never enters focus")
    func states() {
        for variant in TextFieldVariant.allCases {
            let focused = TextFieldTokens(variant: variant, states: [.focus])
            let rest = TextFieldTokens(variant: variant, states: [])
            #expect(rest.focusRingColor == nil)
            #expect(rest.opacity == nil)
            #expect(TextFieldTokens(variant: variant, states: [.disabled]).opacity == .opacity.disabled)
            #if os(watchOS)
                #expect(!TextFieldState.focus.isEntered)
                #expect(focused == rest)
            #else
                #expect(TextFieldState.focus.isEntered)
                #expect(focused.focusRingColor == .border.focus)
                #expect(focused.focusRingWidth == .stroke.thick)
            #endif
        }
    }

    // MARK: - Size

    @Test("an explicit size wins over controlSize; without one, controlSize decides; then the OS's offered size")
    func sizeResolution() {
        let controlSizes: [ControlSize] = [.mini, .small, .regular, .large, .extraLarge]
        for controlSize in controlSizes {
            for size in TextFieldSize.allCases {
                #expect(TextFieldSize.resolved(explicit: size, controlSize: controlSize) == size.offered)
            }
            #expect(
                TextFieldSize.resolved(explicit: nil, controlSize: controlSize) == TextFieldSize(controlSize).offered)
        }
        #expect(TextFieldSize(.mini) == .s)
        #expect(TextFieldSize(.small) == .s)
        #expect(TextFieldSize(.regular) == .m)
        #expect(TextFieldSize(.large) == .l)
        #expect(TextFieldSize(.extraLarge) == .l)
        #if os(watchOS)
            // The watch offers only m (the contract's `watchos` block): every size draws m's metrics.
            #expect(TextFieldSize.allCases.map(\.offered) == [.m, .m, .m])
        #else
            #expect(TextFieldSize.allCases.map(\.offered) == TextFieldSize.allCases)
            #expect(TextFieldSize.resolved(explicit: .s, controlSize: .large) == .s)
        #endif
    }

    // MARK: - Hit area

    @Test("a framed field takes touches and clicks in at least the platform's recommended height")
    func hitAreaMinimum() {
        #if os(macOS)
            // Chapter 08: 28 pt on macOS; the contract records no exception like Button's.
            #expect(TextFieldMetrics.minimumHitHeight == 28)
        #else
            // Chapter 08: 44 pt on iOS, iPadOS and watchOS, which is size.control.m there.
            #expect(TextFieldMetrics.minimumHitHeight == 44)
            #expect(TextFieldMetrics.minimumHitHeight == CGFloat(Westron.Dimension.size.control.m))
        #endif
        // Every size but s is drawn at the target or above it; s is drawn below it, so the field reaches around it.
        #expect(CGFloat(Westron.Dimension.size.control.s) < TextFieldMetrics.minimumHitHeight)
        #expect(CGFloat(Westron.Dimension.size.control.m) >= TextFieldMetrics.minimumHitHeight)
    }

    // MARK: - The catalog's hook

    @Test("the catalog's states are the contract's, in its order")
    func catalogStates() throws {
        let text = try String(contentsOf: Self.contractFile, encoding: .utf8)
        let line = try #require(text.split(separator: "\n").first { $0.hasPrefix("states: [") })
        let states = line.dropFirst("states: [".count).dropLast().split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespaces)
        }
        #expect(TextFieldCatalogState.all.map(\.name) == states)
        #expect(TextFieldCatalogState(named: "focus")?.isForced == true)
        #expect(TextFieldCatalogState(named: "disabled")?.isDisabled == true)
        #expect(TextFieldCatalogState(named: "hover") == nil)
        #expect(EnvironmentValues().forcedTextFieldStates.isEmpty)
    }
}
