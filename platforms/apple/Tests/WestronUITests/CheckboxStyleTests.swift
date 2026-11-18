import Foundation
import SwiftUI
import Testing

@testable import WestronUI

#if canImport(AppKit)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

/// Checkbox's style against its contract, spec/components/checkbox/checkbox.spec.yaml: the tokens it draws in every
/// combination of states, read from the contract's own bindings; the list color of the context; what Reduce Motion
/// drops; the hit area; and the circle following the text role of its label.
@Suite("Checkbox style")
@MainActor
struct CheckboxStyleTests {
    static let contractFile = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("spec/components/checkbox/checkbox.spec.yaml")

    // MARK: - The contract's token bindings

    /// A binding: its default token (nil when it has none or `null`) and its cases, each a state list and a token.
    struct Binding {
        var token: String?
        var cases: [(states: [String], token: String?)] = []

        /// The token for a check in `states`: the first case whose states it is in, else the default.
        func resolve(_ states: Set<CheckboxState>) -> String? {
            for item in cases where states.contains(where: { item.states.contains($0.rawValue) }) {
                return item.token
            }
            return token
        }
    }

    /// A binding of the contract's `tokens:` block: `  <name>: token`, or `  <name>:` with an optional `token:` line
    /// and `cases:` of `- { when: { state: … }, token: … }`, each on one line.
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
                binding.token = Self.token(text.dropFirst("token:".count))
            } else if text.hasPrefix("- {") {
                let state = try #require(text.range(of: "state: "))
                let afterState = text[state.upperBound...]
                let states: [String]
                if afterState.hasPrefix("[") {
                    let close = try #require(afterState.firstIndex(of: "]"))
                    states = afterState.dropFirst()[..<close].split(separator: ",").map {
                        $0.trimmingCharacters(in: .whitespaces)
                    }
                } else {
                    states = [String(afterState.prefix { $0 != " " && $0 != "}" })]
                }
                let token = try #require(text.range(of: "token: ", options: .backwards))
                binding.cases.append((states, Self.token(text[token.upperBound...].dropLast(2))))
            }
        }
        return binding
    }

    private static func token(_ text: Substring) -> String? {
        let value = text.trimmingCharacters(in: .whitespaces)
        return value == "null" ? nil : value
    }

    /// Every combination of the contract's states, the empty one (rest) included.
    static let stateCombinations: [Set<CheckboxState>] = CheckboxState.allCases.reduce([[]]) { sets, state in
        sets + sets.map { $0.union([state]) }
    }

    @Test("every combination of states draws the tokens the contract's bindings give, in the accent")
    func tokensMatchTheContract() throws {
        let bindings: [(name: String, binding: Binding, drawn: (CheckboxTokens) -> String?)] = [
            ("ring.color", try Self.binding("ring.color"), { $0.ringColor?.name }),
            ("ring.width", try Self.binding("ring.width"), { $0.ringWidth?.name }),
            ("disc.background", try Self.binding("disc.background"), { $0.disc?.name }),
            ("mark.color", try Self.binding("mark.color"), { $0.mark?.name }),
            ("container.opacity", try Self.binding("container.opacity"), { $0.opacity?.name }),
        ]
        #expect(Self.stateCombinations.count == 16)
        for states in Self.stateCombinations {
            let tokens = CheckboxTokens(category: nil, states: states)
            for item in bindings {
                // A state the current OS never enters draws as if absent.
                let expected = item.binding.resolve(states.filter(\.isEntered))
                #expect(
                    item.drawn(tokens) == expected, "\(item.name), states \(states.map(\.rawValue).sorted())")
            }
        }
        // The motions the contract binds are the ones the style runs.
        #expect(try Self.binding("mark.checkMotion").token == Westron.Transition.check.name)
        #expect(try Self.binding("disc.uncheckMotion").token == Westron.Transition.fade.name)
        #expect(try Self.binding("container.pressMotion").token == Westron.Transition.press.name)
    }

    @Test(
        "a list's color fills the checked disc with its control and draws the mark in its on-control; no list, the accent"
    )
    func listColor() {
        for states in Self.stateCombinations {
            let accent = CheckboxTokens(category: nil, states: states)
            for category in Westron.Category.allCases {
                let tokens = CheckboxTokens(category: category, states: states)
                if states.contains(.checked) {
                    #expect(tokens.disc == category.control, "\(category)")
                    #expect(tokens.mark == category.onControl, "\(category)")
                } else {
                    #expect(tokens.disc == nil && tokens.mark == nil)
                }
                // The ring and the opacity are the same for every list.
                #expect(tokens.ringColor == accent.ringColor && tokens.ringWidth == accent.ringWidth)
                #expect(tokens.opacity == accent.opacity)
            }
        }
        let checked = CheckboxTokens(category: nil, states: [.checked])
        #expect(checked.disc == .background.accent && checked.mark == .text.onAccent)
        #expect(CheckboxTokens(category: nil, states: []).ringColor == .border.strong)
    }

    @Test("the environment carries the list color, nil (the accent) by default")
    func categoryEnvironment() {
        #expect(EnvironmentValues().category == nil)
        var values = EnvironmentValues()
        values.category = .amber
        #expect(values.category == .amber)
    }

    // MARK: - Motion

    @Test("checking pops from 80 % on motion.check, a press scales to 98 %; Reduce Motion drops both, keeps the fade")
    func reduceMotion() {
        let full = CheckboxMotion(reduceMotion: false)
        #expect(full.popScale == 0.8)
        #expect(full.check == .check)
        #expect(full.uncheck == .fade)
        #expect(full.scale(pressed: true) == 0.98)
        #expect(full.scale(pressed: false) == 1)

        let reduced = CheckboxMotion(reduceMotion: true)
        #expect(reduced.popScale == 1)
        #expect(reduced.check == .fade, "the fill still appears, as a fade")
        #expect(reduced.uncheck == .fade)
        #expect(reduced.scale(pressed: true) == 1)
    }

    @Test("a press scales the check unless it is disabled")
    func pressScale() {
        #expect(CheckboxTokens.scalesDown(states: [.pressed]))
        #expect(CheckboxTokens.scalesDown(states: [.pressed, .checked, .focus]))
        #expect(!CheckboxTokens.scalesDown(states: [.pressed, .disabled]))
        #expect(!CheckboxTokens.scalesDown(states: [.checked]))
    }

    // MARK: - Size and hit area

    @Test("the hit area is at least the platform's target: 44 pt on iOS and watchOS, 28 on macOS")
    func hitAreaMinimum() {
        #if os(macOS)
            #expect(CheckboxMetrics.minimumHitSide >= 28)
        #else
            #expect(CheckboxMetrics.minimumHitSide >= 44)
        #endif
        #expect(CheckboxMetrics.minimumHitSide == .size.control.m)
        #expect(CheckboxMetrics.hitSide(diameter: 10) == CheckboxMetrics.minimumHitSide)
        #expect(CheckboxMetrics.hitSide(diameter: 100) == 100)

        // A check with the smallest text and no label beside it still takes the whole target.
        let small = fittingSize(
            Toggle("Done", isOn: .constant(false)).toggleStyle(.check).labelsHidden().textRole(.caption.medium))
        #expect(small.width >= CheckboxMetrics.minimumHitSide && small.height >= CheckboxMetrics.minimumHitSide)
    }

    @Test("labelsHidden hides the label beside the circle, where the OS tells a style (iOS 18, macOS 15)")
    func labelsHidden() throws {
        guard #available(iOS 18, macOS 15, watchOS 11, *) else { return }
        let toggle = { Toggle("Write the report", isOn: .constant(false)).toggleStyle(.check) }
        let hidden = fittingSize(toggle().labelsHidden().textRole(.body.regular))
        let shown = fittingSize(toggle().textRole(.body.regular))
        #expect(abs(hidden.width - CheckboxMetrics.minimumHitSide) < 0.5, "\(hidden)")
        #expect(shown.width > hidden.width + 40)
    }

    @Test(
        "the circle's diameter follows the line of its label's text role",
        arguments: [Westron.TextRole.caption.medium, .body.regular, .subheadline.regular, .heading.large])
    func diameterFollowsTheTextRole(role: Westron.TextRole) {
        let line = fittingSize(Text(verbatim: "X").textRole(role)).height
        let cell = fittingSize(CheckboxCell().textRole(role))
        let expected = CheckboxMetrics.hitSide(diameter: CheckboxMetrics.diameter(lineHeight: line))
        #expect(abs(cell.width - expected) < 0.5 && abs(cell.height - expected) < 0.5, "\(role.name): \(cell)")
    }

    @Test("a larger text role draws a larger circle, past the least hit area")
    func largerRoleLargerCircle() {
        let body = fittingSize(CheckboxCell().textRole(.body.regular))
        let heading = fittingSize(CheckboxCell().textRole(.heading.large))
        #expect(heading.height > CheckboxMetrics.minimumHitSide, "heading.large's circle grows past the hit area")
        #expect(heading.height > body.height)
    }

    #if os(iOS)
        @Test("the circle grows with Dynamic Type")
        func growsWithDynamicType() {
            let large = fittingSize(CheckboxCell().textRole(.body.regular).dynamicTypeSize(.large))
            let accessibility = fittingSize(CheckboxCell().textRole(.body.regular).dynamicTypeSize(.accessibility3))
            #expect(accessibility.height > large.height)
            #expect(accessibility.height > CheckboxMetrics.minimumHitSide)
        }
    #endif

    /// The check's cell alone: a hidden line of the environment's text and a circle.
    private struct CheckboxCell: View {
        var body: some View {
            CheckboxCellLayout {
                Text(verbatim: "X").hidden()
                Circle()
            }
        }
    }

    private func fittingSize(_ view: some View) -> CGSize {
        #if os(macOS)
            let host = NSHostingView(rootView: view)
            host.layoutSubtreeIfNeeded()
            return host.fittingSize
        #elseif os(iOS)
            return UIHostingController(rootView: view).sizeThatFits(in: CGSize(width: 1000, height: 1000))
        #else
            return .zero
        #endif
    }
}
