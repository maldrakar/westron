import Foundation
import SwiftUI
import Testing

@testable import WestronUI

/// ListRow against its contract, spec/components/list-row/list-row.spec.yaml: the tokens it draws in every
/// combination of states of each form, read from the contract's own bindings, and every binding drawn; a disabled row
/// that never tints; the selected row's bar; the drop target's ring; the motion; the metrics; the indent per level and
/// the horizontal spacing that stops growing at xxxLarge; the guides, their place and their width; the slots on the
/// title's first line; the trailing slot under the text at the accessibility sizes; right to left; the insertion mark;
/// the level as more content; and the Disclosure chevron's cell, with a stand-in.
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

    /// The lines of the contract's `tokens:` block, each binding's own line and its indented lines.
    static func tokenLines() throws -> [Substring] {
        let lines = try String(contentsOf: contractFile, encoding: .utf8).split(
            separator: "\n", omittingEmptySubsequences: false)
        let block = try #require(lines.firstIndex(of: "tokens:"))
        let rest = lines[(block + 1)...]
        let end = rest.firstIndex { !$0.isEmpty && !$0.hasPrefix(" ") } ?? rest.endIndex
        return Array(rest[..<end])
    }

    /// The names of every binding of the contract's `tokens:` block, in its order.
    static func bindingNames() throws -> [String] {
        try tokenLines().compactMap { line in
            guard line.hasPrefix("  "), !line.hasPrefix("   "), let colon = line.firstIndex(of: ":") else { return nil }
            return String(line[line.index(line.startIndex, offsetBy: 2)..<colon])
        }
    }

    /// A binding of the contract's `tokens:` block: `  <name>: token`, or `  <name>:` with an optional `token:` line and
    /// `cases:` of `- { when: { state: <one state> }, token: … }`, each on one line.
    static func binding(_ name: String) throws -> Binding {
        let lines = try tokenLines()
        let start = try #require(
            lines.firstIndex { $0 == "  \(name):" || $0.hasPrefix("  \(name): ") }, "no binding \(name)")
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
        let barColor = try Self.binding("bar.color")
        let barWidth = try Self.binding("bar.width")
        let opacity = try Self.binding("container.opacity")
        let title = try Self.binding("title.font")
        for form in ListRowForm.allCases {
            for states in Self.stateCombinations {
                let tokens = ListRowTokens(form: form, states: states)
                let drawn = ListRowTokens.effective(states, form: form)
                let what = "\(form) in \(states.map(\.rawValue).sorted())"
                #expect(tokens.background?.name == background.resolve(drawn), "\(what)")
                #expect(tokens.ringColor?.name == ringColor.resolve(drawn), "\(what)")
                #expect(tokens.ringWidth?.name == ringWidth.resolve(drawn), "\(what)")
                #expect(tokens.barColor?.name == barColor.resolve(drawn), "\(what)")
                #expect(tokens.barWidth?.name == barWidth.resolve(drawn), "\(what)")
                #expect(tokens.opacity?.name == opacity.resolve(drawn), "\(what)")
                #expect(tokens.titleFont.name == title.resolve(drawn), "\(what)")
            }
        }
    }

    @Test("every binding of the contract is one the row draws, with the contract's token")
    func everyBindingIsDrawn() throws {
        // The bindings that depend on the states are compared case by case above; these are the single ones.
        let single: [String: String] = [
            "container.minHeight": "size.target.minimum",
            "container.paddingHorizontal": ListRowMetrics.paddingHorizontal.name,
            "container.paddingVertical": ListRowMetrics.paddingVertical.name,
            "container.gap": ListRowMetrics.gap.name,
            "container.trailingGap": ListRowMetrics.trailingGap.name,
            "container.indent": ListRowMetrics.indent.name,
            "container.radius": ListRowMetrics.radius.name,
            "container.pressMotion": "motion.press",
            "container.highlightMotion": "motion.fade",
            "title.color": ListRowMetrics.titleColor.name,
            "subtitle.font": ListRowMetrics.subtitleFont.name,
            "subtitle.color": ListRowMetrics.subtitleColor.name,
            "subtitle.gap": ListRowMetrics.subtitleGap.name,
            "guide.color": ListRowMetrics.guideColor.name,
            "guide.width": "stroke.thin",
        ]
        let bycase: Set<String> = [
            "container.background", "container.opacity", "ring.color", "ring.width", "bar.color", "bar.width",
            "title.font",
        ]
        let names = try Self.bindingNames()
        #expect(Set(names) == Set(single.keys).union(bycase), "\(names)")
        for (name, token) in single {
            #expect(try Self.binding(name).token == token, "\(name)")
        }
        #expect(ListRowMetrics.minHeight == .size.target.minimum)
        #expect(ListRowMetrics.guideWidth(compact: false) == .stroke.thin)
        #expect(ListRowMetrics.guideWidth(compact: true) == .stroke.regular)
    }

    @Test("a disabled row never tints: no hover, pressed or drop target, in either form, and it is dimmed")
    func disabledNeverTints() {
        for form in ListRowForm.allCases {
            for states in Self.stateCombinations where states.contains(.disabled) {
                let tokens = ListRowTokens(form: form, states: states)
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
        let still = ListRowTokens(form: .static, states: [.hover, .pressed])
        #expect(still.background == nil)
    }

    @Test("pressed over selected; a selected row keeps its highlight under the pointer")
    func stateOrder() {
        #expect(ListRowTokens(form: .pressable, states: [.selected, .pressed]).background == .background.pressed)
        #expect(ListRowTokens(form: .pressable, states: [.selected, .hover]).background == .background.selected)
        #expect(
            ListRowTokens(form: .pressable, states: [.selected, .dropTarget]).background == .background.accentSubtle)
    }

    @Test("a selected row draws its bar and no ring; the ring is a drop target's alone")
    func barAndRing() {
        for form in ListRowForm.allCases {
            for states in Self.stateCombinations {
                let tokens = ListRowTokens(form: form, states: states)
                let drawn = ListRowTokens.effective(states, form: form)
                #expect((tokens.barColor == .border.focus) == drawn.contains(.selected))
                #expect((tokens.ringColor == .border.insertion) == drawn.contains(.dropTarget))
                #expect(tokens.ringColor != .border.focus)
            }
        }
    }

    // MARK: - Drawn

    /// Shows a view in a window `width` wide and lets it lay out, with a probe for the row's parts.
    func show(_ view: some View, width: CGFloat = 320, height: CGFloat = 600) -> ListRowProbe {
        let probe = ListRowProbe()
        let probed = view.environment(\.listRowProbe, probe).frame(
            width: width, height: height, alignment: .topLeading)
        #if canImport(AppKit)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: width, height: height), styleMask: [.titled],
                backing: .buffered, defer: false)
            window.contentView = NSHostingView(rootView: probed)
            window.orderFront(nil)
            defer { window.orderOut(nil) }
            for _ in 0..<3 {
                window.contentView?.layoutSubtreeIfNeeded()
                RunLoop.main.run(until: Date().addingTimeInterval(0.05))
            }
        #else
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: height))
            window.rootViewController = UIHostingController(rootView: probed)
            window.isHidden = false
            defer { window.isHidden = true }
            for _ in 0..<3 {
                window.layoutIfNeeded()
                RunLoop.main.run(until: Date().addingTimeInterval(0.05))
            }
        #endif
        return probe
    }

    /// Also when the product sets the title's role, and right to left.
    @Test("the bar: at the highlight's leading edge, stroke.thick wide, inset by the radius, in light and dark")
    func barDrawn() throws {
        for scheme in [ColorScheme.light, .dark] {
            for ownRole in [false, true] {
                let probe = show(
                    ListRow(action: {}) {
                        if ownRole { Text("Inbox").textRole(.callout.regular) } else { Text("Inbox") }
                    }
                    .selected(true)
                    .frame(width: 320)
                    .environment(\.colorScheme, scheme))
                let bar = try #require(probe["bar"], "\(scheme) \(ownRole)")
                let highlight = try #require(probe["highlight"])
                let radius = CGFloat(ListRowMetrics.radius)
                #expect(abs(bar.minX - highlight.minX) < 0.5, "\(bar) \(highlight)")
                #expect(abs(bar.width - CGFloat(Westron.Dimension.stroke.thick)) < 0.5, "\(bar)")
                #expect(abs(bar.minY - (highlight.minY + radius)) < 0.5, "\(bar) \(highlight)")
                #expect(abs(bar.maxY - (highlight.maxY - radius)) < 0.5, "\(bar) \(highlight)")
                #expect(probe["ring"] == nil)
            }
        }
        // Right to left, the bar is at the right.
        let mirrored = show(
            ListRow(action: {}) { Text("Inbox") }.selected(true).frame(width: 320)
                .environment(\.layoutDirection, .rightToLeft))
        let bar = try #require(mirrored["bar"])
        let highlight = try #require(mirrored["highlight"])
        #expect(abs(bar.maxX - highlight.maxX) < 0.5, "\(bar) \(highlight)")
        // A row at rest draws none.
        #expect(show(ListRow(action: {}) { Text("Inbox") }.frame(width: 320))["bar"] == nil)
    }

    @Test("a press tints and never scales: the pressed row's highlight is as large as the row")
    func pressNeverScales() throws {
        let rest = show(ListRow(action: {}) { Text("Inbox") }.selected(true).frame(width: 320))
        let pressed = show(
            ListRow(action: {}) { Text("Inbox") }
                .environment(\.forcedListRowStates, [.pressed]).frame(width: 320))
        let still = try #require(rest["highlight"])
        let press = try #require(pressed["highlight"])
        #expect(still.size == press.size, "\(still) \(press)")
        #expect(abs(press.width - 320) < 0.5)
    }

    @Test("the drop target's ring is drawn over the row's content, and the guides stay under it")
    func ringOverContent() throws {
        let probe = show(ListRow(level: 2, action: {}) { Text("Inbox") }.dropTarget(true).frame(width: 320))
        let ring = try #require(probe["ring"])
        #expect(abs(ring.width - 320) < 0.5)
        #expect(probe["guide 0"] != nil)
    }

    @Test("the highlight and the mark change in their motion tokens, which Reduce Motion keeps")
    func motion() {
        #expect(ListRowMotion.press == .press)
        #expect(ListRowMotion.highlight == .fade)
        #expect(ListRowMotion.mark == .fade)
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

    @Test("each level indents the row by container.indent, scaled with the text up to xxxLarge")
    func indent() {
        let step = idealWidth(level: 1) - idealWidth(level: 0)
        #expect(abs(step - CGFloat(ListRowMetrics.indent)) < 0.5, "\(step)")
        #expect(abs(idealWidth(level: 3) - idealWidth(level: 0) - 3 * step) < 0.5)
        // macOS has no Dynamic Type: its text, and so the indent, keeps one size.
        #if os(iOS)
            let largest = idealWidth(level: 1, size: .xxxLarge) - idealWidth(level: 0, size: .xxxLarge)
            #expect(largest > step + 0.5, "the indent scales with the text: \(largest) at xxxLarge, \(step) at large")
            for size in [DynamicTypeSize.accessibility1, .accessibility3, .accessibility5] {
                let capped = idealWidth(level: 1, size: size) - idealWidth(level: 0, size: size)
                #expect(abs(capped - largest) < 0.5, "the indent stops at xxxLarge: \(capped) at \(size)")
            }
            let small = idealWidth(level: 1, size: .xSmall) - idealWidth(level: 0, size: .xSmall)
            #expect(small < step - 0.5, "\(small) at xSmall")
        #endif
        // A negative level is the top level.
        #expect(idealWidth(level: -2) == idealWidth(level: 0))
    }

    @Test("the horizontal spacing stops at xxxLarge; the vertical spacing and the text grow on")
    func spacingStopsAtTheStructureLimit() throws {
        #if os(iOS)
            func words(_ size: DynamicTypeSize) throws -> CGRect {
                let probe = show(ListRow(action: {}) { Text("Inbox") }.frame(width: 320).dynamicTypeSize(size))
                return try #require(probe["words"])
            }
            let largest = try words(.xxxLarge)
            let accessibility = try words(.accessibility5)
            // The padding at the start is the same; the words' column is taller.
            #expect(abs(largest.minX - accessibility.minX) < 0.5, "\(largest) \(accessibility)")
            #expect(accessibility.height > largest.height + 10, "\(largest) \(accessibility)")
        #endif
        #expect(ListRowMetrics.structureLimit == .xxxLarge)
    }

    @Test("at accessibility5 a row at level 4 on a phone's width keeps a column for its words")
    func wordsColumnAtDepth() throws {
        #if os(iOS)
            var widths: [Int: CGFloat] = [:]
            for level in 1...4 {
                let probe = show(
                    ListRow(level: level, action: {}) {
                        Text("Groceries")
                    } leading: {
                        Icon(.folder)
                    }
                    .frame(width: 402)
                    .dynamicTypeSize(.accessibility5), width: 402, height: 900)
                widths[level] = try #require(probe["words"]).width
                let leading = try #require(probe["leading"])
                print("list-row: accessibility5, level \(level): words \(widths[level] ?? 0), leading \(leading.width)")
            }
            #expect((widths[4] ?? 0) > 100, "\(widths)")
            #expect((widths[1] ?? 0) > (widths[4] ?? 0))
        #endif
    }

    @Test("guides: one per ancestor level, under that level's slot, never closer than half the gap to the next level's")
    func guides() {
        let spacing = ListRowSpacing(indent: 24, padding: 12, gap: 12, trailingGap: 8)
        #expect(ListRowMetrics.guideCentres(level: 0, spacing: spacing, slotWidth: 20).isEmpty)
        #expect(ListRowMetrics.guideCentres(level: 3, spacing: spacing, slotWidth: 20) == [22, 46, 70])
        // A row's own slot starts where its level's guide would be centred, less half its width.
        #expect(ListRowMetrics.slotStart(level: 3, indent: 24, padding: 12) == 84)
        // A row without a leading slot draws them at each ancestor level's slot start.
        #expect(ListRowMetrics.guideCentres(level: 1, spacing: spacing, slotWidth: 0) == [12])
        // A slot wider than the indent allows: the guide stops half the gap before the next level's slot.
        #expect(ListRowMetrics.guideCentres(level: 2, spacing: spacing, slotWidth: 60) == [30, 54])
        #expect(ListRowMetrics.guideOffset(indent: 24, gap: 12, slotWidth: 60) == 18)
        #expect(ListRowMetrics.guides(level: 2, enabled: false, spacing: spacing, slotWidth: 20).isEmpty)
    }

    @Test("the drawn guides stand under the slot and clear of the row's own slot, in the size class's width")
    func guidesDrawn() throws {
        for compact in [false, true] {
            let probe = show(
                ListRow(level: 2) {
                    Text("Seeds")
                } leading: {
                    Color.clear.frame(width: 60, height: 20)
                }
                .frame(width: 320)
                #if os(iOS)
                    .environment(\.horizontalSizeClass, compact ? .compact : .regular)
                #endif
            )
            let first = try #require(probe["guide 0"])
            let second = try #require(probe["guide 1"])
            let leading = try #require(probe["leading"])
            #expect(probe["guide 2"] == nil)
            let spacing = ListRowSpacing.base
            // Each guide stands half the gap before the next level's slot, as the 60 pt slot is wider than the indent.
            #expect(abs(second.midX - (leading.minX - spacing.gap / 2)) < 0.5, "\(second) \(leading)")
            #expect(abs(second.midX - first.midX - spacing.indent) < 0.5)
            #if os(iOS)
                let width: CGFloat = compact ? .stroke.regular : .stroke.thin
            #else
                let width: CGFloat = .stroke.thin
            #endif
            #expect(abs(first.width - width) < 0.01, "\(first) compact \(compact)")
        }
        let off = show(ListRow(level: 2, guides: false) { Text("Seeds") }.frame(width: 320))
        #expect(off["guide 0"] == nil)
    }

    @Test("the leading slot stands on the title's first line, centred on it")
    func slotsOnTheFirstLine() throws {
        let frames = Frames()
        TextFieldStyleTests.show(
            ListRow {
                Text("Call the plumber about the kitchen tap that drips at night").recordingFrame("title", in: frames)
            } leading: {
                Icon(.folder).recordingFrame("leading", in: frames)
            }
            .frame(width: 200))
        let title = try #require(frames["title"])
        let leading = try #require(frames["leading"])
        let line = fittingSize(Text("Call").textRole(.body.regular)).height
        #expect(title.height > line * 1.5, "the title wraps: \(title)")
        #expect(abs(leading.midY - (title.minY + line / 2)) < 2.5, "\(leading) \(title) \(line)")
    }

    @Test("a row with a check at the start is as high as the check's hit area: 44 pt on iOS, 32 on macOS")
    func checkRowHeight() {
        let size = fittingSize(
            ListRow {
                Text("Call the plumber")
            } leading: {
                Toggle(isOn: .constant(false), accessibilityLabel: "Call the plumber").toggleStyle(.check)
            },
            in: CGSize(width: 320, height: 1000))
        #if os(macOS)
            #expect(abs(size.height - .size.control.m) < 0.5, "\(size)")
        #else
            #expect(abs(size.height - .size.target.minimum) < 0.5, "\(size)")
        #endif
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

    // MARK: - The insertion mark

    @Test("the mark: over the edge it names, from its level's slot start to the row's trailing padding, centred on it")
    func insertionMark() throws {
        let spacing = ListRowSpacing.base
        for edge in ListRowInsertionEdge.allCases {
            for level in [0, 2] {
                let probe = show(
                    VStack(spacing: 0) {
                        ListRow(level: 1, action: {}) { Text("Garden") }
                            .listRowProbed("row")
                            .insertionMark(edge, level: level)
                        ListRow(level: 1, action: {}) { Text("Seeds") }.selected(true)
                    }
                    .frame(width: 320))
                let mark = try #require(probe["mark"], "\(edge) \(level)")
                let row = try #require(probe["row"])
                let start = ListRowMetrics.slotStart(level: level, indent: spacing.indent, padding: spacing.padding)
                #expect(abs(mark.minX - (row.minX + start)) < 0.5, "\(mark) \(row)")
                #expect(abs(mark.maxX - (row.maxX - spacing.padding)) < 0.5, "\(mark) \(row)")
                let line = edge == .top ? row.minY : row.maxY
                #expect(abs(mark.midY - line) < 0.5, "\(edge): \(mark) \(row)")
            }
        }
        #expect(show(ListRow(action: {}) { Text("Garden") }.insertionMark(nil).frame(width: 320))["mark"] == nil)
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

    @Test("a leaf's empty cell puts its trailing slot in the branch's column")
    func leafLinesUpWithBranch() throws {
        let frames = Frames()
        TextFieldStyleTests.show(
            VStack(spacing: 0) {
                ListRow(action: {}) {
                    Text("Work")
                } trailing: {
                    Text("4").recordingFrame("branch", in: frames)
                }
                .listRowDisclosureCell { Color.clear.frame(width: .size.target.minimum, height: 20) }
                ListRow(action: {}) {
                    Text("Errands")
                } trailing: {
                    HStack(spacing: 0) {
                        Text("7").recordingFrame("leaf", in: frames)
                        ListRowEmptyCell()
                    }
                }
            }
            .frame(width: 320))
        let branch = try #require(frames["branch"])
        let leaf = try #require(frames["leaf"])
        #expect(abs(branch.maxX - leaf.maxX) < 0.5, "\(branch) \(leaf)")
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

    @Test("the level is more content from level 1 on, counted from 1: a row at level 1 carries Level 2")
    func spokenLevel() {
        #expect(ListRowMetrics.spokenLevel(0) == nil)
        #expect(ListRowMetrics.spokenLevel(1) == 2)
        #expect(ListRowMetrics.spokenLevel(3) == 4)
        // The representation's words carry it: the pressable row's and the static row's.
        let parts = ListRowParts(
            title: Text("Today"), subtitle: EmptyView(), leading: EmptyView(), trailing: EmptyView())
        for words in [ListRowWords.button(action: {}, selected: false), .text(selected: false)] {
            let probe = show(ListRowContent(level: 1, guides: false, parts: parts, cell: nil, words: words))
            #expect(probe.marks == ["level 2"])
            let top = show(ListRowContent(level: 0, guides: false, parts: parts, cell: nil, words: words))
            #expect(top.marks.isEmpty)
        }
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
