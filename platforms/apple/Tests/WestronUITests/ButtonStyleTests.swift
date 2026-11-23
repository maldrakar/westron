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
        func matches(variant: ButtonVariant, destructive: Bool, states: Set<ButtonState>, floating: Bool = false)
            -> Bool
        {
            when.allSatisfy { key, values in
                switch key {
                case "variant": values.contains(variant.rawValue)
                case "role": values.contains(destructive ? "destructive" : "default")
                case "state": states.contains { values.contains($0.rawValue) }
                case "floating": values.contains(String(floating))
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

    /// Whether the contract lets a button float: its constraints forbid a floating tertiary and a floating destructive
    /// secondary (`forbiddenFloatingFallsBack`).
    static func mayFloat(_ variant: ButtonVariant, destructive: Bool) -> Bool {
        variant == .primary || (variant == .secondary && !destructive)
    }

    @Test(
        "every variant × role × floating × combination of states draws the tokens the contract's cases give",
        arguments: ButtonVariant.allCases, [false, true])
    func tokensMatchTheContract(variant: ButtonVariant, destructive: Bool) throws {
        for floating in Self.mayFloat(variant, destructive: destructive) ? [false, true] : [false] {
            try tokensMatchTheContract(variant: variant, destructive: destructive, floating: floating)
        }
    }

    func tokensMatchTheContract(variant: ButtonVariant, destructive: Bool, floating: Bool) throws {
        let bindings: [(name: String, cases: [Case], drawn: (ButtonTokens) -> String?)] = [
            ("container.background", try Self.cases("container.background"), { $0.background?.name }),
            ("container.opacity", try Self.cases("container.opacity"), { $0.opacity?.name }),
            ("container.shadow", try Self.cases("container.shadow"), { $0.shadow?.name }),
            ("label.color", try Self.cases("label.color"), { $0.label.name }),
            ("icon.color", try Self.cases("icon.color"), { $0.icon.name }),
            ("progress.color", try Self.cases("progress.color"), { $0.progress.name }),
        ]
        #expect(Self.stateCombinations.count == 32)
        for states in Self.stateCombinations {
            let tokens = ButtonTokens(
                variant: variant, destructive: destructive, states: states, highContrast: false, floating: floating)
            for binding in bindings {
                let expected = binding.cases.first {
                    $0.matches(variant: variant, destructive: destructive, states: states, floating: floating)
                }?.token
                #expect(
                    binding.drawn(tokens) == expected,
                    "\(binding.name), \(variant) \(destructive ? "destructive" : "default")\(floating ? " floating" : ""), states \(states.map(\.rawValue).sorted())"
                )
            }
            // The contract binds no border (#85): in the standard themes no variant draws one.
            #expect(tokens.borderColor == nil && tokens.borderWidth == nil)
        }
        #expect(try Self.tokenLines().allSatisfy { !$0.hasPrefix("  container.border") })
    }

    @Test("secondary darkens further under text.primary than under the danger words (the owner's decision, 2026-11-20)")
    func secondaryFillsByRole() {
        func fill(_ destructive: Bool, _ states: Set<ButtonState>) -> Westron.Color? {
            ButtonTokens(variant: .secondary, destructive: destructive, states: states, highContrast: false).background
        }
        #expect(fill(false, []) == .background.muted && fill(true, []) == .background.muted)
        #expect(fill(false, [.hover]) == .background.mutedHover)
        #expect(fill(false, [.pressed]) == .background.mutedPressed)
        #expect(fill(true, [.hover]) == .background.mutedHoverColored)
        #expect(fill(true, [.pressed]) == .background.mutedPressedColored)
    }

    @Test(
        "in the high-contrast themes a secondary button draws its outline in every state, over the same fill",
        arguments: ButtonVariant.allCases, [false, true])
    func highContrastOutline(variant: ButtonVariant, destructive: Bool) {
        for states in Self.stateCombinations {
            let standard = ButtonTokens(variant: variant, destructive: destructive, states: states, highContrast: false)
            let high = ButtonTokens(variant: variant, destructive: destructive, states: states, highContrast: true)
            // Only the outline differs.
            var edgeless = high
            edgeless.borderColor = nil
            edgeless.borderWidth = nil
            #expect(edgeless == standard)
            if variant == .secondary {
                #expect(high.borderColor == (destructive ? .status.danger.border : .border.strong))
                #expect(high.borderWidth == .stroke.thin)
            } else {
                #expect(high.borderColor == nil && high.borderWidth == nil)
            }
        }
    }

    @Test("disabled and loading exclude hover and pressed: the resting fill holds and a press does not scale")
    func disabledAndLoadingExcludeHoverAndPressed() {
        for variant in ButtonVariant.allCases {
            for destructive in [false, true] {
                let rest = ButtonTokens(variant: variant, destructive: destructive, states: [], highContrast: false)
                for excluding in [ButtonState.disabled, .loading] {
                    for tint in [ButtonState.hover, .pressed] {
                        let tokens = ButtonTokens(
                            variant: variant, destructive: destructive, states: [excluding, tint], highContrast: false)
                        #expect(tokens.background == rest.background)
                    }
                    #expect(!ButtonTokens.scalesDown(states: [excluding, .pressed]))
                    #expect(!ButtonTokens.scalesDown(states: [excluding, .pressed], onGlass: true))
                }
                // Loading does not dim; disabled does.
                #expect(
                    ButtonTokens(variant: variant, destructive: destructive, states: [.loading], highContrast: false)
                        .opacity == nil)
                #expect(
                    ButtonTokens(variant: variant, destructive: destructive, states: [.disabled], highContrast: false)
                        .opacity
                        == .opacity.disabled)
            }
        }
        #expect(ButtonTokens.scalesDown(states: [.pressed]))
        #expect(ButtonTokens.scalesDown(states: [.pressed, .hover, .focus]))
        #expect(!ButtonTokens.scalesDown(states: [.hover]))
        // Reduce Motion drops the scale (chapter 05).
        #expect(!ButtonTokens.scalesDown(states: [.pressed], reduceMotion: true))
    }

    @Test("the per-size bindings are the contract's: height, padding, gap, label and icon fonts; the capsule")
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
        // The shape is the capsule, drawn with SwiftUI's `Capsule()` in the style; the icon is at the small scale.
        #expect(try Self.single("container.shape") == "capsule")
        #expect(ButtonMetrics.iconScale == .small)
        #expect(try Self.single("container.pressMotion") == Westron.Transition.press.name)
        #expect(try Self.single("container.hoverMotion") == Westron.Transition.fade.name)
    }

    // MARK: - Floating (decisions/0015)

    @Test(
        "the contract forbids a floating tertiary and a floating destructive secondary; one written anyway draws the same button not floating"
    )
    func forbiddenFloatingFallsBack() throws {
        let contract = try Self.contract()
        #expect(contract.contains("- when: { floating: true }\n    require: { variant: [primary, secondary] }"))
        #expect(contract.contains("- when: { floating: true, variant: secondary }\n    require: { role: [default] }"))
        for (variant, destructive) in [(ButtonVariant.tertiary, false), (.tertiary, true), (.secondary, true)] {
            #expect(!ButtonTokens.floats(variant, destructive: destructive, floating: true))
            #expect(
                !ButtonTokens.standsOnGlass(variant, destructive: destructive, floating: true, glassAvailable: true))
            for states in Self.stateCombinations {
                for highContrast in [false, true] {
                    #expect(
                        ButtonTokens(
                            variant: variant, destructive: destructive, states: states, highContrast: highContrast,
                            floating: true)
                            == ButtonTokens(
                                variant: variant, destructive: destructive, states: states,
                                highContrast: highContrast))
                }
            }
        }
        // A destructive primary floats, on its opaque fill.
        #expect(ButtonTokens.floats(.primary, destructive: true, floating: true))
    }

    @Test("not floating, every variant draws what it drew before the option: no shadow, the same tokens")
    func notFloatingIsUntouched() {
        for variant in ButtonVariant.allCases {
            for destructive in [false, true] {
                for states in Self.stateCombinations {
                    for highContrast in [false, true] {
                        let tokens = ButtonTokens(
                            variant: variant, destructive: destructive, states: states, highContrast: highContrast)
                        #expect(tokens.shadow == nil)
                        #expect(
                            tokens
                                == ButtonTokens(
                                    variant: variant, destructive: destructive, states: states,
                                    highContrast: highContrast, floating: false))
                    }
                }
                #expect(
                    !ButtonTokens.standsOnGlass(
                        variant, destructive: destructive, floating: false, glassAvailable: true))
            }
        }
    }

    @Test("before OS 26 a floating secondary stands on the surface, tinted as a row, outlined in high contrast")
    func floatingSecondaryWithoutGlass() {
        func tokens(_ states: Set<ButtonState>, highContrast: Bool = false) -> ButtonTokens {
            ButtonTokens(
                variant: .secondary, destructive: false, states: states, highContrast: highContrast, floating: true)
        }
        #expect(tokens([]).background == .background.surface)
        #expect(tokens([.hover]).background == .background.hover)
        #expect(tokens([.pressed]).background == .background.pressed)
        #expect(tokens([.disabled, .pressed]).background == .background.surface)
        #expect(tokens([.loading, .hover]).background == .background.surface)
        #expect(tokens([]).shadow == .overlay)
        #expect(tokens([]).label == .text.primary)
        #expect(tokens([]).borderColor == nil)
        #expect(tokens([], highContrast: true).borderColor == .border.strong)
        #expect(tokens([], highContrast: true).borderWidth == .stroke.thin)
        #expect(tokens([.disabled]).opacity == .opacity.disabled)
        #expect(
            !ButtonTokens.standsOnGlass(.secondary, destructive: false, floating: true, glassAvailable: false))
        // Pressed scales it down, as any button where there is no glass.
        #expect(ButtonTokens.scalesDown(states: [.pressed], onGlass: false))
    }

    @Test("on glass a floating secondary draws no ground of westron's: no fill, outline or shadow; its ink stays")
    func floatingSecondaryOnGlass() {
        #expect(ButtonTokens.standsOnGlass(.secondary, destructive: false, floating: true, glassAvailable: true))
        for destructive in [false] {
            for states in Self.stateCombinations {
                for highContrast in [false, true] {
                    let surface = ButtonTokens(
                        variant: .secondary, destructive: destructive, states: states, highContrast: highContrast,
                        floating: true)
                    let glass = surface.onGlass()
                    #expect(glass.background == nil && glass.shadow == nil)
                    #expect(glass.borderColor == nil && glass.borderWidth == nil)
                    #expect(glass.label == surface.label && glass.icon == surface.icon)
                    #expect(glass.progress == surface.progress)
                    // Disabled dims the whole button, glass included, at opacity.disabled.
                    #expect(glass.opacity == surface.opacity)
                }
            }
        }
    }

    @Test("on glass a press is the glass's: westron's press scale never applies, in any state")
    func noPressScaleOnGlass() {
        for states in Self.stateCombinations {
            #expect(!ButtonTokens.scalesDown(states: states, onGlass: true))
        }
    }

    @Test("the glass answers a touch or the pointer only while the button takes presses: not disabled, not loading")
    func glassIsInteractiveOnlyWhileItTakesPresses() {
        for states in Self.stateCombinations {
            #expect(ButtonTokens.glass(states: states, onGlass: false) == nil)
            let glass = ButtonTokens.glass(states: states, onGlass: true)
            let takesPresses = states.filter(\.isEntered).isDisjoint(with: [.disabled, .loading])
            #expect(glass == ButtonGlass(isInteractive: takesPresses), "\(states.map(\.rawValue).sorted())")
        }
    }

    @Test("a floating primary keeps its fills and casts shadow.overlay, with or without glass")
    func floatingPrimary() {
        for destructive in [false, true] {
            #expect(
                !ButtonTokens.standsOnGlass(
                    .primary, destructive: destructive, floating: true, glassAvailable: true))
        }
        for destructive in [false, true] {
            for states in Self.stateCombinations {
                let floating = ButtonTokens(
                    variant: .primary, destructive: destructive, states: states, highContrast: false, floating: true)
                var flat = floating
                flat.shadow = nil
                #expect(floating.shadow == .overlay)
                #expect(
                    flat
                        == ButtonTokens(
                            variant: .primary, destructive: destructive, states: states, highContrast: false)
                )
            }
        }
    }

    @Test("glass is the OS's from 26; the catalog's override draws the look before it on a newer OS")
    func glassAvailability() {
        if #available(iOS 26, macOS 26, watchOS 26, *) {
            #expect(ButtonGlass.isAvailable)
        } else {
            #expect(!ButtonGlass.isAvailable)
        }
        #expect(EnvironmentValues().drawsButtonsWithoutGlass == false)
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

    // MARK: - Strings

    @Test("loading's accessibility value comes from WestronUI's string table, in English")
    func loadingIsLocalizable() {
        // Without the table the fallback value would come back.
        #expect(Bundle.module.localizedString(forKey: "Loading", value: "no table", table: nil) == "Loading")
        #expect(Bundle.module.developmentLocalization == "en")
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
