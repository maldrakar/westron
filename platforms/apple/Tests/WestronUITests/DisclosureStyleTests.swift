#if !os(watchOS)
    import Foundation
    import SwiftUI
    import Testing

    @testable import WestronUI

    /// Disclosure's style against its contract, spec/components/disclosure/disclosure.spec.yaml: the tokens the chevron's
    /// cell draws in every combination of states, read from the contract's own bindings; the chevron's direction; the
    /// motion and Reduce Motion; the cell's place, at a ListRow's end or after any other label, drawn once; its hit area;
    /// the content shown only while expanded; and the leaf alignment of `.disclosureAlignsLeaves()`.
    @Suite("Disclosure style")
    @MainActor
    struct DisclosureStyleTests {
        static let contractFile = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("spec/components/disclosure/disclosure.spec.yaml")

        // MARK: - The contract's token bindings

        /// A binding: its default token (nil when it has none) and its cases, each a state and its token, nil for
        /// `null`.
        struct Binding {
            var token: String?
            var cases: [(state: String, token: String?)] = []

            /// The token for a cell in `states`: the first case that matches, else the default.
            func resolve(_ states: Set<DisclosureState>) -> String? {
                let names = Set(states.map(\.rawValue))
                for item in cases where names.contains(item.state) { return item.token }
                return token
            }
        }

        /// A binding of the contract's `tokens:` block: `  <name>: token`, or `  <name>:` with `cases:` of
        /// `- { when: { state: … }, token: … }`, each on one line.
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
                guard text.hasPrefix("- {") else { continue }
                let state = try #require(text.range(of: "state: "))
                let name = String(text[state.upperBound...].prefix { $0 != " " && $0 != "}" })
                let token = try #require(text.range(of: "token: ", options: .backwards))
                let value = text[token.upperBound...].dropLast(2).trimmingCharacters(in: .whitespaces)
                binding.cases.append((name, value == "null" ? nil : value))
            }
            return binding
        }

        /// Every combination of the contract's states, the empty one (rest) included.
        static let stateCombinations: [Set<DisclosureState>] = DisclosureState.allCases.reduce([[]]) { sets, state in
            sets + sets.map { $0.union([state]) }
        }

        @Test("every combination of states draws the tokens the contract's bindings give")
        func tokensMatchTheContract() throws {
            let bindings: [(name: String, binding: Binding, drawn: (DisclosureTokens) -> String?)] = [
                ("chevron.color", try Self.binding("chevron.color"), { $0.chevron.name }),
                ("indicator.background", try Self.binding("indicator.background"), { $0.indicator?.name }),
                ("indicator.opacity", try Self.binding("indicator.opacity"), { $0.opacity?.name }),
            ]
            #expect(try Self.binding("indicator.background").cases.count == 3)
            #expect(Self.stateCombinations.count == 32)
            for states in Self.stateCombinations {
                let tokens = DisclosureTokens(states: states)
                for item in bindings {
                    // A state the current OS never enters draws as if absent, and disabled excludes hover and pressed.
                    let expected = item.binding.resolve(DisclosureTokens.effective(states))
                    #expect(item.drawn(tokens) == expected, "\(item.name), states \(states.map(\.rawValue).sorted())")
                }
            }
        }

        @Test("disabled excludes hover and pressed; expanded changes no token")
        func effectiveStates() {
            #expect(DisclosureTokens.effective([.disabled, .hover, .pressed, .expanded]) == [.disabled, .expanded])
            #expect(DisclosureTokens(states: [.expanded]) == DisclosureTokens(states: []))
            #expect(DisclosureTokens.scalesDown(states: [.pressed]))
            #expect(!DisclosureTokens.scalesDown(states: [.pressed, .disabled]))
        }

        // MARK: - Direction and motion

        @Test("the chevron points down while expanded, to the trailing side while collapsed, mirrored right to left")
        func direction() {
            #expect(DisclosureMetrics.angle(expanded: true, layoutDirection: .leftToRight) == .zero)
            #expect(DisclosureMetrics.angle(expanded: true, layoutDirection: .rightToLeft) == .zero)
            // The glyph points down; a turn of -90° (counterclockwise on screen) points it right.
            #expect(DisclosureMetrics.angle(expanded: false, layoutDirection: .leftToRight) == .degrees(-90))
            #expect(DisclosureMetrics.angle(expanded: false, layoutDirection: .rightToLeft) == .degrees(90))
        }

        @Test("a toggle moves in motion.move and turns the chevron; under Reduce Motion nothing moves")
        func motion() {
            let full = DisclosureMotion(reduceMotion: false)
            #expect(full.toggle == .move)
            #expect(full.turns)
            #expect(full.scale(pressed: true) == 0.98)
            #expect(full.press == .press && full.hover == .fade)
            let reduced = DisclosureMotion(reduceMotion: true)
            #expect(reduced.toggle == nil, "under Reduce Motion something slides")
            #expect(!reduced.turns)
            #expect(reduced.scale(pressed: true) == 1)
            // A press keeps its tint under Reduce Motion.
            #expect(reduced.press == .press && reduced.hover == .fade)
        }

        @Test("the cell's metrics come from the contract: size.control.s, size.target.minimum, xxxLarge as ListRow's")
        func metrics() {
            #expect(DisclosureMetrics.indicatorSize == .size.control.s)
            #expect(DisclosureMetrics.minimumHitSide == .size.target.minimum)
            #expect(DisclosureMetrics.structureLimit == ListRowMetrics.structureLimit)
            #expect(DisclosureMetrics.chevronScale == .small)
        }

        // MARK: - Layout

        /// A group with `label`, collapsed or expanded, its content a recorded frame.
        private func group(
            expanded: Bool, frames: Frames, @ViewBuilder label: () -> some View
        ) -> some View {
            DisclosureGroup(isExpanded: .constant(expanded)) {
                Color.clear.frame(height: 20).recordingFrame("content", in: frames)
            } label: {
                label()
            }
            .disclosureGroupStyle(.chevron)
            .recordingFrame("group", in: frames)
            .frame(width: 320, alignment: .leading)
        }

        @Test("a ListRow label draws the cell at its end, once: the header is the row, with no cell beside it")
        func cellInTheRow() throws {
            let frames = Frames()
            TextFieldStyleTests.show(
                group(expanded: false, frames: frames) {
                    ListRow(action: {}) {
                        Text("Work")
                    } trailing: {
                        Text("4").recordingFrame("trailing", in: frames)
                    }
                    .recordingFrame("row", in: frames)
                })
            let row = try #require(frames["row"])
            let group = try #require(frames["group"])
            let trailing = try #require(frames["trailing"])
            #expect(abs(row.width - group.width) < 0.5, "a second cell stands beside the row: \(row) \(group)")
            // The cell is in the row, after the trailing slot: the slot ends a cell and a gap before the row's padding.
            let padding = CGFloat(ListRowMetrics.paddingHorizontal)
            let gap = CGFloat(ListRowMetrics.trailingGap)
            #expect(
                abs(trailing.maxX - (row.maxX - padding - DisclosureMetrics.minimumHitSide - gap)) < 0.5,
                "\(trailing) \(row)")
            #expect(frames["content"] == nil, "the collapsed group shows its content")
        }

        @Test("any other label: the cell after the label, at the header's trailing edge, at least the target high")
        func cellAfterAnyOtherLabel() throws {
            let frames = Frames()
            TextFieldStyleTests.show(
                group(expanded: true, frames: frames) {
                    Text("Today").recordingFrame("label", in: frames)
                })
            let label = try #require(frames["label"])
            let group = try #require(frames["group"])
            let content = try #require(frames["content"], "the expanded group hides its content")
            let side = DisclosureMetrics.minimumHitSide
            // The label's frame is its text's; the header spans the group, the cell standing at its end.
            #expect(label.maxX <= group.maxX - side + 0.5, "the cell does not stand after the label: \(label) \(group)")
            #expect(content.minY >= label.maxY - 0.5, "the content is not under the header")
            #expect(abs(content.minX - group.minX) < 0.5, "the content is indented: \(content) \(group)")
            #expect(content.minY - group.minY >= side - 0.5, "the header is lower than the target: \(content) \(group)")
        }

        @Test("right to left, the cell after any other label stands at the left")
        func cellRightToLeft() throws {
            let frames = Frames()
            TextFieldStyleTests.show(
                group(expanded: false, frames: frames) {
                    Text("Today").recordingFrame("label", in: frames)
                }
                .environment(\.layoutDirection, .rightToLeft))
            let label = try #require(frames["label"])
            let group = try #require(frames["group"])
            #expect(label.minX >= group.minX + DisclosureMetrics.minimumHitSide - 0.5, "\(label) \(group)")
        }

        /// Disabled is the group's (the contract's disabled): the cell takes its enabled state from the group, so a label
        /// disabled alone leaves the fold available whatever the label is, a ListRow, pressable or static, or a text;
        /// a disabled group disables its cell whatever the label is. The cells drawn enabled are counted
        /// (`DisclosureCellsEnabled`); that the enabled cell inside a disabled row takes a press is
        /// DisclosureBehaviorTests.testDisabledRowStillFolds.
        @Test("a label disabled alone leaves the chevron enabled, a ListRow as any other; a disabled group disables it")
        func disabledLabelKeepsTheFold() {
            func enabledCells(groupDisabled: Bool = false, @ViewBuilder _ label: () -> some View) -> Int {
                let record = Record()
                TextFieldStyleTests.show(
                    DisclosureGroup(isExpanded: .constant(false)) {
                        EmptyView()
                    } label: {
                        label()
                    }
                    .disclosureGroupStyle(.chevron)
                    .disabled(groupDisabled)
                    .onPreferenceChange(DisclosureCellsEnabled.self) { record.cells.append($0) }
                    .frame(width: 320))
                return record.cells.last ?? -1
            }
            #expect(enabledCells { ListRow(action: {}) { Text("Work") } } == 1)
            #expect(
                enabledCells { ListRow(action: {}) { Text("Work") }.disabled(true) } == 1, "a disabled pressable row")
            #expect(enabledCells { ListRow { Text("Work") }.disabled(true) } == 1, "a disabled static row")
            #expect(enabledCells { Text("Work").disabled(true) } == 1, "a disabled text label")
            #expect(enabledCells(groupDisabled: true) { ListRow(action: {}) { Text("Work") } } == 0)
            #expect(enabledCells(groupDisabled: true) { Text("Work") } == 0)
        }

        @Test("a row inside a branch's content is no label: it draws no chevron, and no empty cell by default")
        func contentRowsDrawNoCell() throws {
            let frames = Frames()
            TextFieldStyleTests.show(
                DisclosureGroup(isExpanded: .constant(true)) {
                    ListRow(action: {}) {
                        Text("Errands")
                    } trailing: {
                        Text("7").recordingFrame("leaf", in: frames)
                    }
                } label: {
                    ListRow(action: {}) { Text("Work") }
                }
                .disclosureGroupStyle(.chevron)
                .frame(width: 320))
            let leaf = try #require(frames["leaf"])
            #expect(abs(leaf.maxX - (320 - CGFloat(ListRowMetrics.paddingHorizontal))) < 0.5, "\(leaf)")
        }

        /// A branch that appears as its parent unfolds, the way a tree's branches do in a lazy stack: in no update, not
        /// even its first, does the style draw a second cell beside the branch's row (the cells drawn, counted in every
        /// update), and the row keeps its width from its first update (where its trailing slot ends, recorded in every
        /// update). With a product's modifier on the row that hides the row's layout value (`onGeometryChange`), still
        /// no second cell: the row may be narrower for its first update, an empty place where the cell would stand.
        @Test(
            "a branch appearing in an unfolding parent never draws a second cell beside its row, not for one update",
            arguments: [false, true])
        func noSecondCellOnFirstAppearance(rowHidesLayoutValue: Bool) throws {
            let record = Record()
            let expanded = ExpandedBox()
            let host = Host(
                rootView: UnfoldingParent(expanded: expanded, record: record, rowHidesLayoutValue: rowHidesLayoutValue))
            host.layout()
            #expect(record.slotEnds.isEmpty, "the collapsed parent lays out its content")
            expanded.value = true
            for _ in 0..<5 { host.layout() }
            #expect(!record.slotEnds.isEmpty, "the unfolded parent shows no branch")
            // The parent's cell after its text label, and the branch's in its row.
            #expect(record.cells.last == 2, "the cells drawn over the updates: \(record.cells)")
            #expect(record.cells.allSatisfy { $0 <= 2 }, "a second cell in some update: \(record.cells)")
            if !rowHidesLayoutValue {
                let first = try #require(record.slotEnds.first)
                #expect(
                    record.slotEnds.allSatisfy { abs($0 - first) < 0.5 },
                    "the row's trailing slot over the updates: \(record.slotEnds)")
            }
        }

        /// What the branch's updates showed, in order.
        final class Record: @unchecked Sendable {
            /// Where the row's trailing slot ends.
            var slotEnds: [CGFloat] = []
            /// How many chevron cells the tree draws.
            var cells: [Int] = []
        }

        /// The parent's expansion, which the test flips between updates.
        @Observable final class ExpandedBox: @unchecked Sendable {
            var value = false
        }

        struct UnfoldingParent: View {
            let expanded: ExpandedBox
            let record: Record
            let rowHidesLayoutValue: Bool

            var body: some View {
                VStack(spacing: 0) {
                    DisclosureGroup(isExpanded: .constant(expanded.value)) {
                        DisclosureGroup(isExpanded: .constant(true)) {
                            Text("Garden")
                        } label: {
                            let row = ListRow(action: {}) {
                                Text("Projects")
                            } trailing: {
                                Color.clear.frame(width: 1, height: 1)
                                    .onGeometryChange(for: CGFloat.self) {
                                        $0.frame(in: .global).maxX
                                    } action: {
                                        record.slotEnds.append($0)
                                    }
                            }
                            if rowHidesLayoutValue {
                                row.onGeometryChange(for: CGFloat.self) {
                                    $0.size.width
                                } action: { _ in
                                }
                            } else {
                                row
                            }
                        }
                    } label: {
                        Text("Work")
                    }
                    Spacer(minLength: 0)
                }
                .disclosureGroupStyle(.chevron)
                .frame(width: 320, height: 320, alignment: .topLeading)
                .onPreferenceChange(DisclosureCellsDrawn.self) { count in
                    record.cells.append(count)
                }
            }
        }

        /// A window that hosts a view and lays it out on demand, one update at a time.
        @MainActor final class Host {
            #if canImport(AppKit)
                let window: NSWindow
            #else
                let window: UIWindow
            #endif

            init(rootView: some View) {
                #if canImport(AppKit)
                    window = NSWindow(
                        contentRect: NSRect(x: 0, y: 0, width: 400, height: 400), styleMask: [.titled],
                        backing: .buffered, defer: false)
                    window.contentView = NSHostingView(rootView: rootView)
                    window.orderFront(nil)
                #else
                    window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
                    window.rootViewController = UIHostingController(rootView: rootView)
                    window.isHidden = false
                #endif
            }

            /// One pass of layout and the run loop's turn after it.
            func layout() {
                #if canImport(AppKit)
                    window.contentView?.layoutSubtreeIfNeeded()
                #else
                    window.layoutIfNeeded()
                #endif
                RunLoop.main.run(until: Date().addingTimeInterval(0.02))
            }

            deinit {
                #if canImport(AppKit)
                    MainActor.assumeIsolated { window.orderOut(nil) }
                #else
                    MainActor.assumeIsolated { window.isHidden = true }
                #endif
            }
        }
    }
#endif
