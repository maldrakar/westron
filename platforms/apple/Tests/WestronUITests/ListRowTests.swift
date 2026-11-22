import Foundation
import SwiftUI
import Testing

@testable import WestronUI

/// ListRow against its contract, spec/components/list-row/list-row.spec.yaml: the tokens it draws in every
/// combination of states of each form, read from the contract's own bindings; a disabled row that never tints; the
/// high-contrast ring; the motion with and without Reduce Motion; the metrics; the indent per level and its scaling;
/// the guides; the trailing slot under the text at the accessibility sizes; right to left; and the Disclosure
/// chevron's cell, with a stand-in.
@Suite("ListRow")
@MainActor
struct ListRowTests {
    static let contractFile = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("spec/components/list-row/list-row.spec.yaml")

    // MARK: - The contract's token bindings

    /// A binding: its default token (nil when it has none) and its cases, each the states it names and its token.
    struct Binding {
        var token: String?
        var cases: [(states: [String], token: String)] = []

        /// The token for a row in `states`: the first case that matches, else the default.
        func resolve(_ states: Set<ListRowState>) -> String? {
            let names = Set(states.map(\.rawValue))
            return cases.first { $0.states.contains(where: names.contains) }?.token ?? token
        }
    }

    /// A binding of the contract's `tokens:` block: `  <name>: token`, or `  <name>:` with an optional `token:` line and
    /// `cases:` of `- { when: { state: <one state> }, token: … }`, each on one line.
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
            guard line.hasPrefix("    ") else { break }
            let text = line.trimmingCharacters(in: .whitespaces)
            if text.hasPrefix("token:") {
                binding.token = text.dropFirst("token:".count).trimmingCharacters(in: .whitespaces)
            } else if text.hasPrefix("- {") {
                let state = try #require(text.range(of: "state: "))
                let name = text[state.upperBound...].prefix { $0 != " " && $0 != "}" }
                let token = try #require(text.range(of: "token: ", options: .backwards))
                binding.cases.append(
                    ([String(name)], text[token.upperBound...].dropLast(2).trimmingCharacters(in: .whitespaces)))
            }
        }
        return binding
    }

    /// Every combination of the contract's states, the empty one (rest) included.
    static let stateCombinations: [Set<ListRowState>] = ListRowState.allCases.reduce([[]]) { sets, state in
        sets + sets.map { $0.union([state]) }
    }

    @Test("every combination of states of each form draws the tokens the contract's bindings give")
    func tokensMatchTheContract() throws {
        let background = try Self.binding("container.background")
        let ringColor = try Self.binding("ring.color")
        let ringWidth = try Self.binding("ring.width")
        let opacity = try Self.binding("container.opacity")
        let title = try Self.binding("title.font")
        for form in ListRowForm.allCases {
            for states in Self.stateCombinations {
                let tokens = ListRowTokens(form: form, states: states, highContrast: false)
                let drawn = ListRowTokens.effective(states, form: form)
                let what = "\(form) in \(states.map(\.rawValue).sorted())"
                #expect(tokens.background?.name == background.resolve(drawn), "\(what)")
                #expect(tokens.ringColor?.name == ringColor.resolve(drawn), "\(what)")
                #expect(tokens.ringWidth?.name == ringWidth.resolve(drawn), "\(what)")
                #expect(tokens.opacity?.name == opacity.resolve(drawn), "\(what)")
                #expect(tokens.titleFont.name == title.resolve(drawn), "\(what)")
            }
        }
    }

    @Test("a disabled row never tints: no hover, pressed or drop target, in either form, and it is dimmed")
    func disabledNeverTints() {
        for form in ListRowForm.allCases {
            for states in Self.stateCombinations where states.contains(.disabled) {
                let tokens = ListRowTokens(form: form, states: states, highContrast: false)
                let drawn = ListRowTokens.effective(states, form: form)
                #expect(drawn.isDisjoint(with: [.hover, .pressed, .dropTarget]))
                #expect(tokens.background != .background.hover)
                #expect(tokens.background != .background.pressed)
                #expect(tokens.background != .background.accentSubtle)
                #expect(tokens.ringColor != .border.insertion)
                #expect(tokens.opacity == .opacity.disabled)
            }
        }
    }

    @Test("the static form enters neither hover, focus nor pressed; the pressable form enters every state")
    func formsEnterTheirStates() {
        #expect(ListRowForm.static.states == [.selected, .disabled, .dropTarget])
        #expect(ListRowForm.pressable.states == Set(ListRowState.allCases))
        #expect(!ListRowForm.static.takesAction && ListRowForm.pressable.takesAction)
        let still = ListRowTokens(form: .static, states: [.hover, .pressed], highContrast: false)
        #expect(still.background == nil)
    }

    @Test("pressed over selected; a selected row keeps its highlight under the pointer")
    func stateOrder() {
        #expect(
            ListRowTokens(form: .pressable, states: [.selected, .pressed], highContrast: false).background
                == .background.pressed)
        #expect(
            ListRowTokens(form: .pressable, states: [.selected, .hover], highContrast: false).background
                == .background.selected)
        #expect(
            ListRowTokens(form: .pressable, states: [.selected, .dropTarget], highContrast: false).background
                == .background.accentSubtle)
    }

    @Test("in high contrast a selected row draws border.focus at stroke.thick; a drop target keeps its insertion ring")
    func highContrastRing() {
        for form in ListRowForm.allCases {
            let selected = ListRowTokens(form: form, states: [.selected], highContrast: true)
            #expect(selected.ringColor == .border.focus && selected.ringWidth == .stroke.thick)
            let standard = ListRowTokens(form: form, states: [.selected], highContrast: false)
            #expect(standard.ringColor == nil && standard.ringWidth == nil)
            let target = ListRowTokens(form: form, states: [.selected, .dropTarget], highContrast: true)
            #expect(target.ringColor == .border.insertion)
            let rest = ListRowTokens(form: form, states: [], highContrast: true)
            #expect(rest.ringColor == nil)
        }
    }

    @Test("a press tints in motion.press and never scales; the highlight and the mark fade; Reduce Motion keeps both")
    func motion() throws {
        #expect(try Self.binding("container.pressMotion").token == "motion.press")
        #expect(try Self.binding("container.highlightMotion").token == "motion.fade")
        for reduce in [false, true] {
            let motion = ListRowMotion(reduceMotion: reduce)
            #expect(motion.scale(pressed: true) == 1)
            #expect(motion.press == .press)
            #expect(motion.highlight == .fade)
            #expect(motion.mark == .fade)
        }
    }

    @Test("the metrics are the contract's single bindings")
    func metrics() throws {
        #expect(try Self.binding("container.minHeight").token == "size.target.minimum")
        #expect(ListRowMetrics.minHeight == .size.target.minimum)
        let single: [(String, Westron.Dimension)] = [
            ("container.paddingHorizontal", ListRowMetrics.paddingHorizontal),
            ("container.paddingVertical", ListRowMetrics.paddingVertical),
            ("container.gap", ListRowMetrics.gap),
            ("container.trailingGap", ListRowMetrics.trailingGap),
            ("container.indent", ListRowMetrics.indent),
            ("container.radius", ListRowMetrics.radius),
            ("subtitle.gap", ListRowMetrics.subtitleGap),
        ]
        for (name, value) in single {
            #expect(try Self.binding(name).token == value.name, "\(name)")
        }
        #expect(try Self.binding("subtitle.font").token == ListRowMetrics.subtitleFont.name)
        #expect(try Self.binding("guide.width").token == "stroke.thin")
        #expect(ListRowMetrics.guideWidth(compact: false) == .stroke.thin)
        #expect(ListRowMetrics.guideWidth(compact: true) == .stroke.regular)
    }

    // MARK: - Layout

    @Test("a row is at least size.target.minimum high, its whole frame the hit area")
    func minimumHeight() {
        let size = fittingSize(ListRow(action: {}) { Text("Inbox") }, in: CGSize(width: 320, height: 1000))
        #expect(size.height >= .size.target.minimum - 0.5, "\(size)")
        #expect(size.width == 320)
    }

    /// The width a row needs at its ideal size, at a text size.
    func idealWidth(level: Int, size: DynamicTypeSize = .large) -> CGFloat {
        fittingSize(
            ListRow(level: level) {
                Text("Inbox")
            } leading: {
                Color.clear.frame(width: 20, height: 20)
            }
            .fixedSize()
            .dynamicTypeSize(size)
        )
        .width
    }

    @Test("each level indents the row by container.indent, scaled with the text")
    func indent() {
        let step = idealWidth(level: 1) - idealWidth(level: 0)
        #expect(abs(step - CGFloat(ListRowMetrics.indent)) < 0.5, "\(step)")
        #expect(abs(idealWidth(level: 3) - idealWidth(level: 0) - 3 * step) < 0.5)
        // macOS has no Dynamic Type: its text, and so the indent, keeps one size.
        #if os(iOS)
            let large = idealWidth(level: 1, size: .accessibility3) - idealWidth(level: 0, size: .accessibility3)
            #expect(large > step + 0.5, "the indent scales with the text: \(large) at accessibility3, \(step) at large")
            let small = idealWidth(level: 1, size: .xSmall) - idealWidth(level: 0, size: .xSmall)
            #expect(small < step - 0.5, "\(small) at xSmall")
        #endif
        // A negative level is the top level.
        #expect(idealWidth(level: -2) == idealWidth(level: 0))
    }

    @Test("guides: one per ancestor level, centred under that level's leading slot; none at level 0")
    func guides() {
        let indent: CGFloat = 24
        let padding: CGFloat = 12
        #expect(ListRowMetrics.guideCentres(level: 0, indent: indent, padding: padding, slotWidth: 20).isEmpty)
        #expect(
            ListRowMetrics.guideCentres(level: 3, indent: indent, padding: padding, slotWidth: 20) == [22, 46, 70])
        // A row's own slot starts where its level's guide would be centred, less half its width.
        #expect(ListRowMetrics.slotStart(level: 3, indent: indent, padding: padding) == 84)
        #expect(ListRowMetrics.guideCentres(level: 1, indent: indent, padding: padding, slotWidth: 0) == [12])
    }

    @Test("a row draws its guides only at level 1 or deeper, and only with guides on")
    func guidesDrawn() {
        #expect(ListRowMetrics.guides(level: 2, enabled: true, indent: 24, padding: 12, slotWidth: 20).count == 2)
        #expect(ListRowMetrics.guides(level: 2, enabled: false, indent: 24, padding: 12, slotWidth: 20).isEmpty)
        #expect(ListRowMetrics.guides(level: 0, enabled: true, indent: 24, padding: 12, slotWidth: 20).isEmpty)
    }

    @Test("at the accessibility sizes the trailing slot moves under the text; at the others it stays on the first line")
    func trailingStacks() {
        #expect(!ListRowMetrics.stacksTrailing(.xxxLarge))
        #expect(ListRowMetrics.stacksTrailing(.accessibility1))
        #expect(ListRowMetrics.stacksTrailing(.accessibility5))
        func height(_ size: DynamicTypeSize, trailing: Bool) -> CGFloat {
            fittingSize(
                Group {
                    if trailing {
                        ListRow {
                            Text("Inbox")
                        } trailing: {
                            Text("12")
                        }
                    } else {
                        ListRow { Text("Inbox") }
                    }
                }
                .dynamicTypeSize(size), in: CGSize(width: 320, height: 2000)
            ).height
        }
        #expect(abs(height(.large, trailing: true) - height(.large, trailing: false)) < 0.5)
        #expect(height(.accessibility5, trailing: true) > height(.accessibility5, trailing: false) + 10)
    }

    @Test("right to left, the leading slot is at the right and the trailing slot and the chevron's cell at the left")
    func rightToLeft() throws {
        for direction in [LayoutDirection.leftToRight, .rightToLeft] {
            let frames = Frames()
            TextFieldStyleTests.show(
                ListRow(level: 1) {
                    Text("Inbox")
                } leading: {
                    Color.clear.frame(width: 20, height: 20).recordingFrame("leading", in: frames)
                } trailing: {
                    Color.clear.frame(width: 20, height: 20).recordingFrame("trailing", in: frames)
                }
                .listRowDisclosureCell { Color.clear.frame(width: 30, height: 30).recordingFrame("cell", in: frames) }
                .frame(width: 320)
                .environment(\.layoutDirection, direction))
            let leading = try #require(frames["leading"])
            let trailing = try #require(frames["trailing"])
            let cell = try #require(frames["cell"])
            let padding = CGFloat(ListRowMetrics.paddingHorizontal)
            let start = ListRowMetrics.slotStart(level: 1, indent: CGFloat(ListRowMetrics.indent), padding: padding)
            if direction == .leftToRight {
                #expect(abs(leading.minX - start) < 0.5, "\(leading)")
                #expect(leading.maxX < trailing.minX && trailing.maxX < cell.minX)
                #expect(abs(cell.maxX - (320 - padding)) < 0.5, "\(cell)")
            } else {
                #expect(abs(leading.maxX - (320 - start)) < 0.5, "\(leading)")
                #expect(leading.minX > trailing.maxX && trailing.minX > cell.maxX)
                #expect(abs(cell.minX - padding) < 0.5, "\(cell)")
            }
        }
    }

    // MARK: - The Disclosure chevron's cell

    @Test("the chevron's cell, a stand-in, stands after the trailing slot by container.trailingGap, inside the row")
    func disclosureCell() throws {
        let frames = Frames()
        TextFieldStyleTests.show(
            ListRow(action: {}) {
                Text("Work")
            } trailing: {
                Color.clear.frame(width: 20, height: 20).recordingFrame("trailing", in: frames)
            }
            .listRowDisclosureCell { Color.clear.frame(width: 30, height: 30).recordingFrame("cell", in: frames) }
            .frame(width: 320))
        let trailing = try #require(frames["trailing"])
        let cell = try #require(frames["cell"])
        #expect(abs(cell.minX - trailing.maxX - CGFloat(ListRowMetrics.trailingGap)) < 0.5, "\(trailing) \(cell)")
        #expect(abs(cell.maxX - (320 - CGFloat(ListRowMetrics.paddingHorizontal))) < 0.5, "\(cell)")
        // Without the cell, nothing is reserved: the trailing slot ends at the padding.
        let alone = Frames()
        TextFieldStyleTests.show(
            ListRow(action: {}) {
                Text("Work")
            } trailing: {
                Color.clear.frame(width: 20, height: 20).recordingFrame("trailing", in: alone)
            }
            .frame(width: 320))
        let end = try #require(alone["trailing"])
        #expect(abs(end.maxX - (320 - CGFloat(ListRowMetrics.paddingHorizontal))) < 0.5, "\(end)")
    }

    @Test("the cell is the row's own: a row inside one of its slots draws none")
    func disclosureCellIsTheRows() {
        let cells = Counter()
        TextFieldStyleTests.show(
            ListRow {
                Text("Outer")
            } subtitle: {
                ListRow { Text("Inner") }
            }
            .listRowDisclosureCell {
                Color.clear.frame(width: 30, height: 30).onAppear { cells.value += 1 }
            }
            .frame(width: 320))
        #expect(cells.value == 1)
    }

    // MARK: - Accessibility

    @Test("the level is more content from level 1 on, counted from 1")
    func spokenLevel() {
        #expect(ListRowMetrics.spokenLevel(0) == nil)
        #expect(ListRowMetrics.spokenLevel(1) == 2)
        #expect(ListRowMetrics.spokenLevel(3) == 4)
    }

    @Test("the catalog names the contract's states, and which form enters each")
    func catalogStates() {
        #expect(ListRowCatalogState.all.map(\.name) == ListRowState.allCases.map(\.rawValue))
        #expect(ListRowCatalogState.all.filter(\.isForced).map(\.name) == ["hover", "focus", "pressed"])
        #expect(
            ListRowCatalogState.all.filter { $0.isEntered(by: .static) }.map(\.name)
                == ["selected", "disabled", "dropTarget"])
    }
}

/// A count kept across a view's callbacks.
final class Counter: @unchecked Sendable {
    var value = 0
}

/// The frames of named views in the global space, recorded as they lay out.
final class Frames: @unchecked Sendable {
    private var frames: [String: CGRect] = [:]

    subscript(name: String) -> CGRect? { frames[name] }
    var count: Int { frames.count }
    var names: [String] { frames.keys.sorted() }

    func record(_ name: String, _ frame: CGRect) { frames[name] = frame }
}

extension View {
    /// Records the view's frame in the global space under `name`.
    func recordingFrame(_ name: String, in frames: Frames) -> some View {
        onGeometryChange(for: CGRect.self) {
            $0.frame(in: .global)
        } action: {
            frames.record(name, $0)
        }
    }
}
