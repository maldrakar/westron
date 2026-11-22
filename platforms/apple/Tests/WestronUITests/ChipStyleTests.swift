import Foundation
import SwiftUI
import Testing

@testable import WestronUI

/// Chip's styles against its contract, spec/components/chip/chip.spec.yaml: the tokens they draw in every combination
/// of states, read from the contract's own bindings, cases that require several states at once included; the list
/// color of the context; the high-contrast outline; the press; the metrics; the hit area of each form; and the label's
/// one truncated line.
@Suite("Chip style")
@MainActor
struct ChipStyleTests {
    static let contractFile = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("spec/components/chip/chip.spec.yaml")

    // MARK: - The contract's token bindings

    /// A binding: its default token (nil when it has none) and its cases, each the states it names, whether it needs
    /// all of them (`state: { all: [...] }`) or any, and its token.
    struct Binding {
        var token: String?
        var cases: [(states: [String], all: Bool, token: String?)] = []

        /// The token for a chip in `states`: the first case that matches, else the default.
        func resolve(_ states: Set<ChipState>) -> String? {
            let names = Set(states.map(\.rawValue))
            for item in cases {
                let matches =
                    item.all ? item.states.allSatisfy(names.contains) : item.states.contains(where: names.contains)
                if matches { return item.token }
            }
            return token
        }
    }

    /// A binding of the contract's `tokens:` block: `  <name>: token`, or `  <name>:` with an optional `token:` line
    /// and `cases:` of `- { when: { state: … }, token: … }`, each on one line; the state one name, a list, or
    /// `{ all: [...] }`.
    static func binding(_ name: String) throws -> Binding {
        let lines = try String(contentsOf: contractFile, encoding: .utf8).split(
            separator: "\n", omittingEmptySubsequences: false)
        let block = try #require(lines.firstIndex(of: "tokens:"))
        let start = try #require(
            lines[block...].firstIndex { $0 == "  \(name):" || $0.hasPrefix("  \(name): ") }, "no binding \(name)")
        if lines[start].hasPrefix("  \(name): ") {
            return Binding(token: String(lines[start].dropFirst("  \(name): ".count)))
        }
        var binding = Binding()
        for line in lines[(start + 1)...] {
            let text = line.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix("    ") else { break }
            if text.hasPrefix("token:") {
                binding.token = text.dropFirst("token:".count).trimmingCharacters(in: .whitespaces)
            } else if text.hasPrefix("- {") {
                let state = try #require(text.range(of: "state: "))
                var rest = text[state.upperBound...]
                let all = rest.hasPrefix("{ all: ")
                if all { rest = rest.dropFirst("{ all: ".count) }
                let states: [String]
                if rest.hasPrefix("[") {
                    let close = try #require(rest.firstIndex(of: "]"))
                    states = rest.dropFirst()[..<close].split(separator: ",").map {
                        $0.trimmingCharacters(in: .whitespaces)
                    }
                } else {
                    states = [String(rest.prefix { $0 != " " && $0 != "}" })]
                }
                let token = try #require(text.range(of: "token: ", options: .backwards))
                binding.cases.append(
                    (states, all, text[token.upperBound...].dropLast(2).trimmingCharacters(in: .whitespaces)))
            }
        }
        return binding
    }

    /// Every combination of the contract's states, the empty one (rest) included.
    static let stateCombinations: [Set<ChipState>] = ChipState.allCases.reduce([[]]) { sets, state in
        sets + sets.map { $0.union([state]) }
    }

    @Test("the contract's container.background has cases that require two states at once, and the parser reads them")
    func allStatesCasesAreRead() throws {
        let background = try Self.binding("container.background")
        #expect(background.cases.count == 5)
        #expect(background.cases[0].all && background.cases[0].states == ["checked", "pressed"])
        #expect(background.cases[1].all && background.cases[1].states == ["checked", "hover"])
        #expect(!background.cases[2].all)
    }

    @Test("every combination of states draws the tokens the contract's bindings give, in the accent")
    func tokensMatchTheContract() throws {
        let bindings: [(name: String, binding: Binding, drawn: (ChipTokens) -> String?)] = [
            ("container.background", try Self.binding("container.background"), { $0.background.name }),
            ("container.opacity", try Self.binding("container.opacity"), { $0.opacity?.name }),
            ("label.color", try Self.binding("label.color"), { $0.label.name }),
            ("icon.color", try Self.binding("icon.color"), { $0.icon.name }),
        ]
        #expect(Self.stateCombinations.count == 32)
        for states in Self.stateCombinations {
            let tokens = ChipTokens(category: nil, states: states, highContrast: false)
            for item in bindings {
                // A state the current OS never enters draws as if absent, and disabled excludes hover and pressed
                // (the contract's description).
                let expected = item.binding.resolve(ChipTokens.effective(states))
                #expect(item.drawn(tokens) == expected, "\(item.name), states \(states.map(\.rawValue).sorted())")
            }
        }
        // The tints of a lit chip, which only cases over two states can say.
        #expect(
            ChipTokens(category: nil, states: [.checked, .pressed, .hover], highContrast: false).background
                == .background.accentPressed)
        #expect(
            ChipTokens(category: nil, states: [.checked, .hover], highContrast: false).background
                == (ChipState.hover.isEntered ? .background.accentHover : .background.accent))
    }

    @Test("disabled excludes hover and pressed, and a state the OS never enters is dropped")
    func effectiveStates() {
        #expect(ChipTokens.effective([.disabled, .hover, .pressed, .checked]) == [.disabled, .checked])
        #if os(watchOS)
            #expect(ChipTokens.effective([.hover, .focus, .pressed]) == [.pressed])
        #else
            #expect(ChipTokens.effective([.hover, .focus, .pressed]) == [.hover, .focus, .pressed])
        #endif
    }

    @Test("lit in a list's color: its fill and on-fill, the same under the pointer and pressed; unlit, as the accent's")
    func listColor() {
        for states in Self.stateCombinations {
            let accent = ChipTokens(category: nil, states: states, highContrast: false)
            for category in Westron.Category.allCases {
                let tokens = ChipTokens(category: category, states: states, highContrast: false)
                if states.contains(.checked) {
                    #expect(tokens.background == category.fill, "\(category)")
                    #expect(tokens.label == category.onFill && tokens.icon == category.onFill, "\(category)")
                } else {
                    #expect(tokens == accent, "\(category), \(states.map(\.rawValue).sorted())")
                }
                #expect(tokens.opacity == accent.opacity)
            }
        }
    }

    @Test("in high contrast every chip draws border.strong at stroke.thin, in every state and color")
    func highContrastOutline() {
        for states in Self.stateCombinations {
            for category in [nil] + Westron.Category.allCases.map(Optional.some) {
                let standard = ChipTokens(category: category, states: states, highContrast: false)
                let high = ChipTokens(category: category, states: states, highContrast: true)
                #expect(standard.borderColor == nil && standard.borderWidth == nil)
                #expect(high.borderColor == .border.strong && high.borderWidth == .stroke.thin)
                var outlineless = high
                outlineless.borderColor = nil
                outlineless.borderWidth = nil
                #expect(outlineless == standard)
            }
        }
    }

    @Test("a press scales the chip to 98 % unless it is disabled; the motions are the contract's")
    func press() throws {
        #expect(ChipTokens.scalesDown(states: [.pressed]))
        #expect(ChipTokens.scalesDown(states: [.pressed, .checked]))
        #expect(!ChipTokens.scalesDown(states: [.pressed, .disabled]))
        #expect(!ChipTokens.scalesDown(states: [.checked, .hover]))
        #expect(ChipTokens.pressScale == 0.98)
        #expect(try Self.binding("container.pressMotion").token == Westron.Transition.press.name)
        #expect(try Self.binding("container.hoverMotion").token == Westron.Transition.fade.name)
        #expect(try Self.binding("container.checkMotion").token == Westron.Transition.fade.name)
    }

    @Test("the metrics are the contract's single bindings")
    func metrics() throws {
        #expect(try Self.binding("container.height").token == ChipMetrics.height.name)
        #expect(try Self.binding("container.paddingHorizontal").token == ChipMetrics.paddingHorizontal.name)
        #expect(try Self.binding("container.gap").token == ChipMetrics.gap.name)
        #expect(try Self.binding("label.font").token == ChipMetrics.labelFont.name)
        #expect(try Self.binding("icon.font").token == ChipMetrics.iconFont.name)
    }

    // MARK: - Layout

    @Test("the selectable and pressable forms lay out a hit area at least size.target.minimum high; static does not")
    func hitArea() {
        let label = { Label("Work", icon: .hash) }
        let selectable = fittingSize(Toggle(isOn: .constant(false)) { label() }.toggleStyle(.chip))
        let pressable = fittingSize(
            Button {
            } label: {
                label()
            }.buttonStyle(.chip))
        let still = fittingSize(label().labelStyle(.chip))
        #expect(selectable.height >= .size.target.minimum, "\(selectable)")
        #expect(pressable.height >= .size.target.minimum, "\(pressable)")
        #expect(abs(selectable.height - pressable.height) < 0.5)
        // The static chip is the drawn capsule: at least size.control.s, and lower than the target where it is.
        #expect(still.height >= .size.control.s - 0.5, "\(still)")
        if CGFloat.size.control.s < .size.target.minimum {
            #expect(still.height < .size.target.minimum, "\(still)")
        }
        // Across, every form is the chip's width.
        #expect(abs(selectable.width - still.width) < 0.5 && abs(pressable.width - still.width) < 0.5)
    }

    @Test("a long label stays one line, truncated, in the width it is given")
    func truncation() {
        let width: CGFloat = 120
        let short = fittingSize(Label("Work", icon: .hash).labelStyle(.chip))
        let long = fittingSize(
            Label("A tag whose name runs much longer than its chip", icon: .hash).labelStyle(.chip),
            in: CGSize(width: width, height: 1000))
        #expect(long.width <= width + 0.5, "\(long)")
        #expect(abs(long.height - short.height) < 0.5, "one line: \(long) against \(short)")
    }

    #if os(iOS)
        @Test("the chip grows with Dynamic Type")
        func growsWithDynamicType() {
            let chip = { Label("Work", icon: .hash).labelStyle(.chip) }
            let large = fittingSize(chip().dynamicTypeSize(.large))
            let accessibility = fittingSize(chip().dynamicTypeSize(.accessibility3))
            #expect(accessibility.height > large.height)
            #expect(accessibility.width > large.width)
        }
    #endif

    @Test("the catalog names the contract's states, and which form enters each")
    func catalogStates() {
        #expect(ChipCatalogState.all.map(\.name) == ["checked", "hover", "focus", "pressed", "disabled"])
        let checked = ChipCatalogState(named: "checked")
        #expect(checked?.isEntered(by: .selectable) == true)
        #expect(checked?.isEntered(by: .pressable) == false)
        #expect(ChipCatalogState.all.allSatisfy { !$0.isEntered(by: .static) })
    }
}
