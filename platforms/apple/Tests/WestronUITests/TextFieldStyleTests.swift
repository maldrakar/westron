import Foundation
import SwiftUI
import Testing

@testable import WestronUI

#if canImport(AppKit)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

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

        /// Whether a field matches: every condition holds; `state` holds when the field is in that state; `lines` is
        /// the field's axis, `multiple` the vertical one.
        func matches(variant: TextFieldVariant, size: TextFieldSize, axis: Axis, states: Set<TextFieldState>) -> Bool {
            when.allSatisfy { key, value in
                switch key {
                case "variant": value == variant.rawValue
                case "size": value == size.offered.rawValue
                case "lines": value == (axis == .vertical ? "multiple" : "single")
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
            "container.height", "container.shape", "container.radius", "container.paddingHorizontal",
            "container.paddingVertical", "container.background", "container.opacity", "text.font", "text.color",
            "focusRing.color", "focusRing.width",
        ]
        // A TextFieldStyle cannot color the system field's prompt (TextFieldTokens): the contract binds it for the
        // platforms that can, and its `platforms.apple` records the difference (decisions/0001, I1). A binding added
        // to the contract fails here until the style draws it.
        let notDrawn: Set = ["placeholder.color"]
        #expect(try Self.bindingNames() == drawn.union(notDrawn))
        withKnownIssue(
            "placeholder.color is not drawn on Apple: the system's placeholder color, a recorded platform difference"
        ) {
            #expect(drawn.isSuperset(of: notDrawn))
        }
    }

    @Test(
        "every variant × size × lines × combination of states draws the tokens the contract's cases give",
        arguments: TextFieldVariant.allCases, TextFieldSize.allCases)
    func tokensMatchTheContract(variant: TextFieldVariant, size: TextFieldSize) throws {
        for axis in [Axis.horizontal, .vertical] {
            try tokensMatchTheContract(variant: variant, size: size, axis: axis)
        }
    }

    func tokensMatchTheContract(variant: TextFieldVariant, size: TextFieldSize, axis: Axis) throws {
        let metrics = TextFieldMetrics(variant: variant, size: size, axis: axis)
        let bindings: [(name: String, drawn: (TextFieldTokens) -> String?)] = [
            ("container.height", { _ in metrics.height?.name }),
            ("container.shape", { _ in metrics.isCapsule ? "capsule" : nil }),
            ("container.radius", { _ in metrics.radius?.name }),
            ("container.paddingHorizontal", { _ in metrics.paddingHorizontal?.name }),
            ("container.paddingVertical", { _ in metrics.paddingVertical?.name }),
            ("container.background", { $0.background?.name }),
            ("container.opacity", { $0.opacity?.name }),
            ("text.font", { $0.textFont?.name }),
            ("text.color", { $0.textColor?.name }),
            ("focusRing.color", { $0.focusRingColor?.name }),
            ("focusRing.width", { $0.focusRingWidth?.name }),
        ]
        #expect(Self.stateCombinations.count == 4)
        for states in Self.stateCombinations {
            let tokens = TextFieldTokens(variant: variant, states: states, highContrast: false)
            for binding in bindings {
                let entered = states.filter(\.isEntered)
                let expected = try Self.cases(binding.name).first {
                    $0.matches(variant: variant, size: size, axis: axis, states: entered)
                }?.token
                #expect(
                    binding.drawn(tokens) == expected,
                    "\(binding.name), \(variant) \(size) \(axis), states \(states.map(\.rawValue).sorted())")
            }
        }
    }

    @Test("inline leaves the text role and the text color to its context, and has no frame, height or padding")
    func inlineTakesItsContext() {
        for size in TextFieldSize.allCases {
            for states in Self.stateCombinations {
                for highContrast in [false, true] {
                    let tokens = TextFieldTokens(variant: .inline, states: states, highContrast: highContrast)
                    #expect(tokens.textFont == nil)
                    #expect(tokens.textColor == nil)
                    #expect(tokens.background == nil)
                    #expect(tokens.borderColor == nil)
                }
            }
            for axis in [Axis.horizontal, .vertical] {
                let metrics = TextFieldMetrics(variant: .inline, size: size, axis: axis)
                #expect(metrics == TextFieldMetrics(variant: .inline, size: .m, axis: .horizontal))
                #expect(metrics.height == nil)
                #expect(metrics.paddingHorizontal == nil)
                #expect(metrics.paddingVertical == nil)
                #expect(!metrics.isCapsule && metrics.radius == nil)
            }
        }
        // framed sets body.regular in text.primary at every size (P3, P13).
        #expect(TextFieldTokens(variant: .framed, states: [], highContrast: false).textFont == .body.regular)
        #expect(TextFieldTokens(variant: .framed, states: [], highContrast: false).textColor == .text.primary)
    }

    @Test("a framed field is a capsule on one line and a rounded rectangle of radius.150 on several (decisions/0002)")
    func framedShape() {
        for size in TextFieldSize.allCases {
            let single = TextFieldMetrics(variant: .framed, size: size, axis: .horizontal)
            let multiple = TextFieldMetrics(variant: .framed, size: size, axis: .vertical)
            #expect(single.isCapsule && single.radius == nil && single.paddingVertical == nil)
            #expect(!multiple.isCapsule && multiple.radius == .radius150 && multiple.paddingVertical != nil)
            // The same height and padding across: a single and a multiple field of one size align their text.
            #expect(single.height == multiple.height)
            #expect(single.paddingHorizontal == multiple.paddingHorizontal)
        }
    }

    @Test("the style reads the field's axis, the contract's lines, by reflection; without one, a single line")
    @MainActor func axisOfTheSystemField() {
        #expect(TextFieldAxis.of(TextField("Notes", text: .constant(""), axis: .vertical)) == .vertical)
        #expect(
            TextFieldAxis.of(TextField("Notes", text: .constant(""), prompt: Text("Add a note"), axis: .vertical))
                == .vertical)
        #expect(TextFieldAxis.of(TextField("Name", text: .constant(""), axis: .horizontal)) == .horizontal)
        #expect(TextFieldAxis.of(TextField("Name", text: .constant(""))) == .horizontal)
        #expect(TextFieldAxis.of(TextField("Name", text: .constant(""), prompt: Text("Untitled"))) == .horizontal)
        #expect(TextFieldAxis.of(SecureField("Password", text: .constant(""))) == .horizontal)
        // A value with no stored axis.
        #expect(TextFieldAxis.of("not a field") == .horizontal)
    }

    /// The axes the westron style resolved for the fields of `view`, hosted in a window: what SwiftUI gave the style's
    /// `_body(configuration:)`, not a field the test built.
    @MainActor static func resolvedAxes(_ view: some View) -> [Axis] {
        let box = ResolvedAxes()
        show(view.onPreferenceChange(TextFieldResolvedAxes.self) { box.axes = $0 })
        return box.axes
    }

    @Test("the style resolves lines from the field SwiftUI hands it: vertical is multiple, anything else single")
    @MainActor func axisTheStyleResolves() {
        let notes = TextField("Notes", text: .constant("Milk"), axis: .vertical)
        #expect(Self.resolvedAxes(notes.textFieldStyle(.framed)) == [.vertical])
        #expect(Self.resolvedAxes(notes.lineLimit(1...4).padding().textFieldStyle(.framed)) == [.vertical])
        #expect(
            Self.resolvedAxes(TextField("Name", text: .constant("Groceries")).textFieldStyle(.framed)) == [.horizontal])
        #expect(
            Self.resolvedAxes(TextField("Name", text: .constant(""), axis: .horizontal).textFieldStyle(.inline))
                == [.horizontal])
        #expect(
            Self.resolvedAxes(SecureField("Password", text: .constant("")).textFieldStyle(.framed)) == [.horizontal])
    }

    // MARK: - Height

    /// The height a field takes when its layout offers it `height` and a width of 300, alone in a window.
    @MainActor static func height(_ field: some View, offered height: CGFloat?) -> CGFloat {
        fittingSize(Propose(proposal: ProposedViewSize(width: 300, height: height)) { field }).height
    }

    @Test(
        "a field keeps the height its text needs when a layout offers it less, at a large text size",
        arguments: TextFieldVariant.allCases, [Axis.horizontal, .vertical])
    @MainActor func keepsItsHeightWhenSqueezed(variant: TextFieldVariant, axis: Axis) {
        let field = TextField("Notes", text: .constant(axis == .vertical ? "Milk\nApples" : "Groceries"), axis: axis)
            .textFieldStyle(variant, size: .m)
            .textRole(.body.regular)
            .dynamicTypeSize(.accessibility5)
        let natural = Self.height(field, offered: nil)
        let squeezed = Self.height(field, offered: 8)
        #expect(natural > 8)
        #expect(squeezed >= natural - 0.5, "\(variant) \(axis): \(natural) offered nothing, \(squeezed) offered 8 pt")
    }

    @Test("in the high-contrast themes a framed field draws an outline in border.strong at stroke.thin, in every state")
    func highContrastOutline() {
        for variant in TextFieldVariant.allCases {
            for states in Self.stateCombinations {
                let standard = TextFieldTokens(variant: variant, states: states, highContrast: false)
                let high = TextFieldTokens(variant: variant, states: states, highContrast: true)
                // Only the outline differs; the standard themes draw none (the owner's accepted deviation).
                #expect(standard.borderColor == nil && standard.borderWidth == nil)
                var edgeless = high
                edgeless.borderColor = nil
                edgeless.borderWidth = nil
                #expect(edgeless == standard)
                if variant == .framed {
                    #expect(high.borderColor == .border.strong)
                    #expect(high.borderWidth == .stroke.thin)
                    #expect(high.background == .background.muted)
                } else {
                    #expect(high.borderColor == nil && high.borderWidth == nil)
                }
            }
        }
    }

    @Test("focus draws westron's ring on iOS and macOS; disabled dims the whole field; the watch never enters focus")
    func states() {
        for variant in TextFieldVariant.allCases {
            let focused = TextFieldTokens(variant: variant, states: [.focus], highContrast: false)
            let rest = TextFieldTokens(variant: variant, states: [], highContrast: false)
            #expect(rest.focusRingColor == nil)
            #expect(rest.opacity == nil)
            #expect(
                TextFieldTokens(variant: variant, states: [.disabled], highContrast: false).opacity == .opacity.disabled
            )
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
            // Chapter 08: 44 pt on iOS, iPadOS and watchOS.
            #expect(TextFieldMetrics.minimumHitHeight == 44)
        #endif
        #expect(TextFieldMetrics.minimumHitHeight == CGFloat(Westron.Dimension.size.target.minimum))
        // s is drawn below the target on every platform, so the field reaches around it; on iOS m is too (36 pt).
        #expect(CGFloat(Westron.Dimension.size.control.s) < TextFieldMetrics.minimumHitHeight)
        #if os(iOS)
            #expect(CGFloat(Westron.Dimension.size.control.m) < TextFieldMetrics.minimumHitHeight)
        #else
            #expect(CGFloat(Westron.Dimension.size.control.m) >= TextFieldMetrics.minimumHitHeight)
        #endif
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

/// What the style reported through `TextFieldResolvedAxes`, written from the preference's callback.
private final class ResolvedAxes: @unchecked Sendable {
    var axes: [Axis] = []
}

/// Offers its one subview `proposal` and takes the size the subview answers with.
private struct Propose: Layout {
    let proposal: ProposedViewSize

    func sizeThatFits(proposal _: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        subviews.first?.sizeThatFits(proposal) ?? .zero
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, proposal: proposal)
    }
}

extension TextFieldStyleTests {
    /// The size a view takes, laid out on its own.
    @MainActor static func fittingSize(_ view: some View) -> CGSize {
        #if canImport(AppKit)
            let host = NSHostingView(rootView: view)
            host.layoutSubtreeIfNeeded()
            return host.fittingSize
        #else
            return UIHostingController(rootView: view).sizeThatFits(in: CGSize(width: 1000, height: 1000))
        #endif
    }

    /// Shows a view in a window and lets it lay out a few times, so that its preferences reach the callbacks.
    @MainActor static func show(_ view: some View) {
        #if canImport(AppKit)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 320, height: 320), styleMask: [.titled], backing: .buffered,
                defer: false)
            window.contentView = NSHostingView(rootView: view.frame(width: 320, height: 320, alignment: .topLeading))
            window.orderFront(nil)
            defer { window.orderOut(nil) }
            for _ in 0..<3 {
                window.contentView?.layoutSubtreeIfNeeded()
                RunLoop.main.run(until: Date().addingTimeInterval(0.05))
            }
        #else
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 320))
            window.rootViewController = UIHostingController(
                rootView: view.frame(width: 320, height: 320, alignment: .topLeading))
            window.isHidden = false
            defer { window.isHidden = true }
            for _ in 0..<3 {
                window.layoutIfNeeded()
                RunLoop.main.run(until: Date().addingTimeInterval(0.05))
            }
        #endif
    }
}
