// Hand-written. Disclosure's look and behavior from its contract, spec/components/disclosure/disclosure.spec.yaml, on
// SwiftUI's own DisclosureGroup (decisions/0001, 0003): the collapse chevron of a group that folds. The generated
// `disclosureGroupStyle(_:)` (Generated/Disclosure+Contract.swift) applies it; the tokens it draws come from
// DisclosureTokens.swift. SwiftUI has no DisclosureGroup on watchOS, so nothing here exists there (the contract's
// `platforms.apple.watchos`).
//
// Only the chevron folds the group (decisions/0001, Q1): the label is the product's, drawn as it is, with whatever action
// it has. The chevron's cell is a system `Button` that toggles the binding, drawn by a `ButtonStyle`, since
// `DisclosureGroupStyleConfiguration` has no `isPressed`; to assistive technology the button is what the system's own
// disclosure group is on each OS (`accessibilityRepresentation`), named by the product's label: on macOS the system's
// DisclosureGroup on the same binding, a disclosure triangle valued expanded or collapsed; on iOS the system's Button,
// with the state as its value, "Expanded" or "Collapsed" (decisions/0001, Q4 and "Measured").
//
// Where the cell stands (decisions/0001, Q2): the style hands it to its label through ListRow's package-internal
// `listRowDisclosureCell`; a ListRow draws it as the last item at its end and says so through the preference
// `ListRowTookDisclosureCell`, and for any other label the style lays the cell out after the label itself.

#if !os(watchOS)
    import SwiftUI

    /// westron's Disclosure style, which the generated `disclosureGroupStyle(_:)` applies (decisions/0001, 0003).
    struct DisclosureVariantStyle: DisclosureGroupStyle {
        let variant: DisclosureVariant

        func makeBody(configuration: Configuration) -> some View {
            // The only variant draws the chevron; a new one fails the build here until it is drawn.
            switch variant.offered {
            case .chevron: DisclosureBody(configuration: configuration, style: self)
            }
        }
    }

    /// The header, the label and the chevron's cell, and under it the content while the group is expanded.
    private struct DisclosureBody: View {
        let configuration: DisclosureGroupStyleConfiguration
        let style: DisclosureVariantStyle

        /// Whether the label is a ListRow that drew the cell at its end; until it says so, the style draws it after the
        /// label.
        @State private var labelTookCell = false

        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            let cell = DisclosureCell(isExpanded: configuration.$isExpanded) {
                configuration.label
            }
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    configuration.label
                        .environment(\.listRowDisclosureCell, AnyView(cell))
                        .onPreferenceChange(ListRowTookDisclosureCell.self) { took in
                            labelTookCell = took
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if !labelTookCell {
                        cell
                    }
                }
                if configuration.isExpanded {
                    // The content fades in where it stands while the group's height grows from the header's bottom edge,
                    // in the toggle's transaction, motion.move; under Reduce Motion the height jumps and the content
                    // fades on its own in motion.fade (`DisclosureMotion`).
                    configuration.content
                        // SwiftUI gives a group's content the automatic style again (measured on iOS 26: a branch inside
                        // a branch drew the system's chevron), so the style passes itself on to the groups inside.
                        .disclosureGroupStyle(style)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(DisclosureMotion(reduceMotion: reduceMotion).contentTransition)
                }
            }
        }
    }

    /// The chevron's cell: a system Button that toggles the group, its look `DisclosureCellLook`, and the system's own
    /// DisclosureGroup that assistive technology meets in its place.
    struct DisclosureCell<Label: View>: View {
        let isExpanded: Binding<Bool>
        @ViewBuilder let label: Label

        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @Environment(\.layoutDirection) private var layoutDirection
        @Environment(\.disclosureToggleObserver) private var toggleObserver
        @Environment(\.listRowDisclosureCellName) private var rowTitle

        var body: some View {
            Button {
                toggle(to: !isExpanded.wrappedValue)
            } label: {
                DisclosureChevron(
                    expanded: isExpanded.wrappedValue, turns: DisclosureMotion(reduceMotion: reduceMotion).turns)
            }
            .buttonStyle(DisclosureCellLook())
            #if os(macOS)
                // An outline's disclosure triangle: Right expands and Left collapses, mirrored right to left.
                .onMoveCommand { direction in
                    let forward: MoveCommandDirection = layoutDirection == .rightToLeft ? .left : .right
                    let backward: MoveCommandDirection = layoutDirection == .rightToLeft ? .right : .left
                    if direction == forward, !isExpanded.wrappedValue { toggle(to: true) }
                    if direction == backward, isExpanded.wrappedValue { toggle(to: false) }
                }
            #endif
            .accessibilityRepresentation {
                DisclosureCellFrame {
                    #if os(macOS)
                        // The system's own style, not westron's, which the environment still holds here: an outline's
                        // disclosure triangle, its value 1 expanded and 0 collapsed, named by the product's label. Its
                        // activation toggles through the cell's own path, in the cell's motion.
                        DisclosureGroup(
                            isExpanded: Binding(get: { isExpanded.wrappedValue }, set: { toggle(to: $0) })
                        ) {
                            EmptyView()
                        } label: {
                            // macOS gives the element its label's frame, and a text's is its words': the label is one
                            // element as large as the cell, so that the disclosure stands where the cell takes a press.
                            ZStack {
                                Color.clear
                                name
                            }
                            .accessibilityElement(children: .combine)
                        }
                        .disclosureGroupStyle(.automatic)
                    #else
                        // On iOS the system's DisclosureGroup is a button named by its label (measured with XCUITest on
                        // iOS 26), and inside a representation it loses the button, so the cell is the system's button
                        // on the same label. Its state, which the system's own may carry in a status SwiftUI does not
                        // offer, is its value, read after its name, as Button's loading is: "Projects, Expanded, button".
                        Button {
                            toggle(to: !isExpanded.wrappedValue)
                        } label: {
                            name
                        }
                        .buttonStyle(.automatic)
                        .accessibilityValue(
                            isExpanded.wrappedValue
                                ? Text(
                                    "Expanded", bundle: .module,
                                    comment: "A disclosure's state while its content shows: its accessibility value.")
                                : Text(
                                    "Collapsed", bundle: .module,
                                    comment:
                                        "A disclosure's state while its content is folded: its accessibility value."))
                    #endif
                }
            }
        }

        /// What names the disclosure: the row's title when a ListRow draws the cell, else the group's label.
        @ViewBuilder private var name: some View {
            if let rowTitle {
                rowTitle
            } else {
                label
            }
        }

        private func toggle(to expanded: Bool) {
            withAnimation(DisclosureMotion(reduceMotion: reduceMotion).toggle) {
                isExpanded.wrappedValue = expanded
            }
            toggleObserver?(expanded)
        }
    }

    /// Lays the representation out in exactly the cell's frame, so that assistive technology and a UI test meet the
    /// disclosure where the chevron is drawn: a label wider than the cell, a ListRow, would otherwise set its frame.
    private struct DisclosureCellFrame: Layout {
        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            proposal.replacingUnspecifiedDimensions()
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            for subview in subviews {
                subview.place(at: bounds.origin, proposal: ProposedViewSize(bounds.size))
            }
        }
    }

    /// The registry's chevron, pointing down while expanded and to the trailing side while collapsed, turning between
    /// them in the toggle's transaction unless Reduce Motion is on; decorative, as the disclosure announces its value.
    private struct DisclosureChevron: View {
        let expanded: Bool
        let turns: Bool

        @Environment(\.layoutDirection) private var layoutDirection

        var body: some View {
            Image(Westron.Icon.chevron)
                .imageScale(DisclosureMetrics.chevronScale)
                .rotationEffect(DisclosureMetrics.angle(expanded: expanded, layoutDirection: layoutDirection))
                .transaction { transaction in
                    if !turns { transaction.animation = nil }
                }
                .accessibilityRepresentation {
                    EmptyView()
                }
                .accessibilityHidden(true)
        }
    }

    /// Draws the cell from its tokens, in the states the system and the catalog report.
    private struct DisclosureCellLook: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            DisclosureCellBody(label: configuration.label, isPressed: configuration.isPressed)
        }
    }

    private struct DisclosureCellBody<Label: View>: View {
        let label: Label
        let isPressed: Bool

        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.isFocused) private var isFocused
        @Environment(\.dynamicTypeSize) private var dynamicTypeSize
        @Environment(\.forcedDisclosureStates) private var forcedStates
        @Environment(\.disclosureHoverObserver) private var hoverObserver
        @State private var isHovered = false

        var body: some View {
            DisclosureCellFace(
                label: label, isPressed: isPressed, isHovered: isHovered, isFocused: isFocused, isEnabled: isEnabled,
                forcedStates: forcedStates,
                onHover: { hovering in isHovered = hovering && DisclosureState.hover.isEntered }
            )
            // The cell stops growing with the text where a ListRow's structure stops, so that a leaf's empty cell keeps
            // the branch's width (`DisclosureMetrics.structureLimit`).
            .environment(\.dynamicTypeSize, min(dynamicTypeSize, DisclosureMetrics.structureLimit))
            // A disabled view may receive no hover events, as Chip's style says.
            .onChange(of: isEnabled) { _, enabled in
                if !enabled { isHovered = false }
            }
            // The catalog's readout of hover (`onDisclosureHover`); nil in a product.
            .onChange(of: isHovered) { _, hovered in
                hoverObserver?(hovered)
            }
        }
    }

    /// The circle and the chevron in the cell, at the capped text size.
    private struct DisclosureCellFace<Label: View>: View {
        let label: Label
        let isPressed: Bool
        let isHovered: Bool
        let isFocused: Bool
        let isEnabled: Bool
        let forcedStates: Set<DisclosureState>
        let onHover: (Bool) -> Void

        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @ScaledMetric(relativeTo: DisclosureMetrics.textStyle) private var diameter = CGFloat(
            DisclosureMetrics.indicatorSize)

        /// Whether the cell is in a state of its contract, read where the system keeps it, or forced by the catalog
        /// (`forcedDisclosureStates`). The switch is exhaustive over the generated `DisclosureState`, so a state added to
        /// or renamed in the contract fails the build here until the style follows it. `expanded` is the chevron's
        /// direction, not a token: the cell's tokens do not change with it.
        private func isIn(_ state: DisclosureState) -> Bool {
            guard state.isEntered else { return false }
            if forcedStates.contains(state) { return true }
            switch state {
            case .expanded: return false
            case .hover: return isHovered
            case .focus: return isFocused
            case .pressed: return isPressed
            case .disabled: return !isEnabled
            }
        }

        var body: some View {
            let states = Set(DisclosureState.allCases.filter(isIn))
            let effective = DisclosureTokens.effective(states)
            let tokens = DisclosureTokens(states: states)
            let motion = DisclosureMotion(reduceMotion: reduceMotion)
            let scalesDown = DisclosureTokens.scalesDown(states: states)
            let shape = Circle()

            label
                .foregroundStyle(tokens.chevron)
                .frame(width: diameter, height: diameter)
                .background {
                    ZStack {
                        if let indicator = tokens.indicator {
                            shape.fill(indicator)
                        }
                    }
                    // The tint of a press in `motion.press`; of the pointer in `motion.fade`.
                    .animation(motion.hover, value: effective.contains(.hover))
                    .animation(motion.press, value: effective.contains(.pressed))
                }
                .modifier(DisclosureHover(diameter: diameter, onHover: onHover))
                // The accessibility shape is the drawn circle, not the hit area around it.
                .contentShape(.accessibility, shape)
                #if os(macOS)
                    // The system's focus ring follows the drawn circle, not the hit area around it.
                    .contentShape(.focusEffect, shape)
                #endif
                .opacity(tokens.opacity.map(Double.init) ?? 1)
                // The press's motion reaches the scale alone, never the chevron's turn when a press ends in the update
                // that folds the group.
                .animation(motion.press) { $0.scaleEffect(motion.scale(pressed: scalesDown)) }
                // The hit area: at least size.target.minimum high and across, laid out, every point of it taking the
                // press, so that the cell never hands its presses to the label beside it nor takes the label's.
                .frame(minWidth: DisclosureMetrics.minimumHitSide, minHeight: DisclosureMetrics.minimumHitSide)
                .contentShape(Rectangle())
        }
    }

    /// Tracks the pointer over the drawn circle, not over the hit area around it nor the corners of the circle's frame,
    /// as Chip's `ChipHover` tracks its capsule: `onHover` reports the whole frame whatever the content shape.
    private struct DisclosureHover: ViewModifier {
        let diameter: CGFloat
        let onHover: (Bool) -> Void

        func body(content: Content) -> some View {
            content
                .onContinuousHover(coordinateSpace: .local) { phase in
                    switch phase {
                    case .active(let location):
                        let frame = CGRect(origin: .zero, size: CGSize(width: diameter, height: diameter))
                        onHover(Circle().path(in: frame).contains(location))
                    case .ended:
                        onHover(false)
                    }
                }
        }
    }

    // MARK: - Leaf alignment

    extension View {
        /// Lines the leaves of a tree up with its branches: every westron ListRow below that is no Disclosure's label
        /// keeps the chevron's cell empty, the same frame after the same gap as a branch's, so that the trailing slots
        /// stand in one column (the contract's `context`, alignsLeaves). Set it once on the tree; off by default.
        ///
        ///     LazyVStack(spacing: 0) {
        ///         ForEach(roots) { Branch(node: $0) }
        ///     }
        ///     .disclosureGroupStyle(.chevron)
        ///     .disclosureAlignsLeaves()
        ///
        /// - Parameter alignsLeaves: Whether the leaves keep the empty cell; `false` turns it off for a subtree.
        public func disclosureAlignsLeaves(_ alignsLeaves: Bool = true) -> some View {
            environment(\.listRowLeafCell, alignsLeaves ? AnyView(DisclosureLeafCell()) : nil)
        }
    }

    /// A leaf's empty cell: the chevron's cell, hidden, so that it takes exactly the cell's width at every text size, and
    /// nothing to assistive technology or the pointer.
    private struct DisclosureLeafCell: View {
        var body: some View {
            DisclosureCell(isExpanded: .constant(false)) {
                EmptyView()
            }
            // Never a stop for the keyboard's focus, whatever `.hidden()` does to it.
            .disabled(true)
            .hidden()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
#endif
