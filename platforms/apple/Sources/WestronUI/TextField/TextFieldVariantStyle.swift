// Hand-written. TextField's look and behavior from its contract, spec/components/text-field/text-field.spec.yaml, on
// SwiftUI's own TextField and SecureField (decisions/0001, 0003), with a glyph at its start or its end (decisions/0003,
// #115). The generated `textFieldStyle(_:size:leadingIcon:trailingIcon:)`
// (Generated/TextField+Contract.swift) applies it; the tokens it draws come from TextFieldTokens.swift.
//
// It is a `TextFieldStyle`, which SwiftUI declares with only the underscored requirement `_body(configuration:)`: the
// configuration is the system field itself, with its label, prompt, text, axis and input behavior. What the probe of
// #30 found with Xcode 27.1 (the contract's `platforms.apple` records it):
// - The requirement is not isolated to the main actor, and a view's initializer is, so the conformance is
//   `@preconcurrency` and the witness `@MainActor`: SwiftUI calls it on the main actor while it builds the view.
// - The configuration drawn inside a custom style is the platform's default field: on macOS a bezeled NSTextField with
//   the system's focus ring, which `focusEffectDisabled()` does not turn off. Drawn in the system's `.plain` style, it
//   has neither bezel nor ring, on iOS too, so the style draws it plain and draws its own fill, outline and ring.
// - Focus is read with a `@FocusState` the style binds to the field with `.focused(_:)`. `@Environment(\.isFocused)`
//   in the style describes the field's ancestors, not the field, and stays false. A product's own `.focused(_:)` on the
//   field keeps working beside the style's: both follow the field, and the product's still moves focus to it.
// - The prompt is drawn by the system in its own placeholder color: neither `foregroundStyle` (any level) nor `tint`
//   from the style reaches it. On iOS a color the product sets on its prompt `Text` reaches it; on macOS 26 not even
//   that. The contract's `platforms.apple` records it as a platform difference (decisions/0001, I1).
// - The system field with a prompt exposes no accessibility label from its title, styled or not, so the product
//   names the field with `.accessibilityLabel(_:)` (the contract's `platforms.apple`; decisions/0001, I2).
// - The field's axis, the contract's `lines`, has no public accessor: the style reads it from the configuration by
//   reflection (`TextFieldAxis`; decisions/0002).
// - On macOS SwiftUI can lay the field out at another font's line height (#99, #113); the style holds it to its own
//   lines from macOS 26 (`TextFieldLine`, the contract's `platforms.apple.macos`).

import SwiftUI

/// westron's TextField style, which the generated `textFieldStyle(_:size:leadingIcon:trailingIcon:)` applies
/// (decisions/0001, 0003).
struct TextFieldVariantStyle: @preconcurrency TextFieldStyle {
    let variant: TextFieldVariant
    /// nil: the size comes from `controlSize`.
    let size: TextFieldSize?
    /// The glyph at the field's start, the contract's `leadingIcon`; nil: none.
    var leadingIcon: Westron.Icon? = nil
    /// The glyph at the field's end, the contract's `trailingIcon`; nil: none.
    var trailingIcon: Westron.Icon? = nil

    @MainActor func _body(configuration: TextField<_Label>) -> some View {
        TextFieldBody(
            field: configuration, variant: variant, explicitSize: size,
            glyphs: TextFieldGlyphNames(leading: leadingIcon, trailing: trailingIcon))
    }
}

/// The glyphs a field draws at its start and its end, the contract's `leadingIcon` and `trailingIcon`.
struct TextFieldGlyphNames: Equatable, Sendable {
    var leading: Westron.Icon?
    var trailing: Westron.Icon?

    /// Whether the field draws no glyph: then the row leaves it all its room and reports no anchors (#115).
    var isEmpty: Bool { leading == nil && trailing == nil }
}

/// Reads the field's states and draws it from its tokens.
private struct TextFieldBody: View {
    let field: TextField<TextFieldVariantStyle._Label>
    let variant: TextFieldVariant
    let explicitSize: TextFieldSize?
    let glyphs: TextFieldGlyphNames

    @Environment(\.controlSize) private var controlSize
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.forcedTextFieldStates) private var forcedStates
    @Environment(\.colorSchemeContrast) private var contrast
    @FocusState private var isFocused: Bool

    /// Whether the field is in a state of its contract, read where the system keeps it, or forced by the catalog
    /// (`forcedTextFieldStates`). The switch is exhaustive over the generated `TextFieldState`, so a state added to or
    /// renamed in the contract fails the build here until the style follows it (#20).
    private func isIn(_ state: TextFieldState) -> Bool {
        guard state.isEntered else { return false }
        if forcedStates.contains(state) { return true }
        switch state {
        case .focus: return isFocused
        case .disabled: return !isEnabled
        }
    }

    var body: some View {
        let states = Set(TextFieldState.allCases.filter(isIn))
        let tokens = TextFieldTokens(variant: variant, states: states, highContrast: contrast == .increased)
        #if os(watchOS)
            // The watch's field is the system's as it is, in both variants and at every size (the contract's
            // `watchos` block); a tap opens the system's text input, and there is no focus to draw. It draws no glyph
            // until the watch's look is settled (#34; the contract's `watchos` block).
            field
                .opacity(tokens.opacity.map(Double.init) ?? 1)
        #else
            let axis = TextFieldAxis.of(field)
            let metrics = TextFieldMetrics(
                variant: variant, size: .resolved(explicit: explicitSize, controlSize: controlSize), axis: axis)
            TextFieldSurface(
                field: field, variant: variant, lineAxis: TextFieldAxis.read(field), tokens: tokens, metrics: metrics,
                glyphs: glyphs, isFocused: $isFocused
            )
            // What the style resolved, for the tests (`TextFieldResolvedAxes`).
            .preference(key: TextFieldResolvedAxes.self, value: [axis])
        #endif
    }
}

#if !os(watchOS)
    /// The shape of a framed field, which is a capsule on one line and a rounded rectangle on several, both with
    /// continuous corners; nil `radius`: the capsule. Insetting it, as `strokeBorder` does, takes the inset off the
    /// corners too, so a stroke stays concentric with the fill; `outset(by:)` grows them, for the ring outside.
    struct TextFieldShape: InsettableShape {
        /// The corners' radius; nil: the capsule.
        var radius: CGFloat?
        var inset: CGFloat = .zero

        func path(in rect: CGRect) -> Path {
            let rect = rect.insetBy(dx: inset, dy: inset)
            if let radius {
                return RoundedRectangle(cornerRadius: max(.zero, radius - inset), style: .continuous).path(in: rect)
            }
            return Capsule(style: .continuous).path(in: rect)
        }

        func inset(by amount: CGFloat) -> TextFieldShape {
            var shape = self
            shape.inset += amount
            return shape
        }

        /// The same shape around this one, `amount` outside it on every side.
        func outset(by amount: CGFloat) -> TextFieldShape {
            TextFieldShape(radius: radius.map { $0 + amount })
        }
    }

    /// The drawn field: the system field in its plain style, in the text role and color of `framed` or of the context,
    /// its padding, height, fill, high-contrast outline, focus ring, hit area and opacity. The horizontal padding scales
    /// with Dynamic Type from its token, relative to the field's text style; the vertical one does not.
    private struct TextFieldSurface: View {
        let field: TextField<TextFieldVariantStyle._Label>
        let variant: TextFieldVariant
        /// The field's axis as reflection reads it, nil where it does not (`TextFieldLine`).
        let lineAxis: Axis?
        let tokens: TextFieldTokens
        let metrics: TextFieldMetrics
        let glyphs: TextFieldGlyphNames
        let isFocused: FocusState<Bool>.Binding
        @ScaledMetric private var padding: CGFloat
        /// The padding above and below a multiline framed field's text, which holds its lines off the field's edges.
        /// It stands in for the centering a single line gets from the minimum height, which does not grow with the
        /// text either, so it is the token's value at every text size: a field at a large text size stays compact.
        private var verticalPadding: CGFloat { metrics.paddingVertical.map(CGFloat.init) ?? .zero }
        /// The height the field is drawn at, which grows past its minimum with its text.
        @State private var drawnHeight: CGFloat = .zero

        init(
            field: TextField<TextFieldVariantStyle._Label>, variant: TextFieldVariant, lineAxis: Axis?,
            tokens: TextFieldTokens, metrics: TextFieldMetrics, glyphs: TextFieldGlyphNames,
            isFocused: FocusState<Bool>.Binding
        ) {
            self.field = field
            self.variant = variant
            self.lineAxis = lineAxis
            self.tokens = tokens
            self.metrics = metrics
            self.glyphs = glyphs
            self.isFocused = isFocused
            let textStyle = Font.TextStyle((tokens.textFont ?? .body.regular).textStyle)
            _padding = ScaledMetric(
                wrappedValue: metrics.paddingHorizontal.map(CGFloat.init) ?? .zero, relativeTo: textStyle)
        }

        var body: some View {
            // A framed field's shape: the capsule on one line, the rounded rectangle on several (`container.shape`,
            // `container.radius`); on `inline`, which has none, the corners its ring takes.
            let shape = TextFieldShape(
                radius: metrics.isCapsule ? nil : CGFloat(metrics.radius ?? TextFieldMetrics.ringRadius))

            field
                .textFieldStyle(.plain)
                // Inside the text role, so that it sees the field's font: on macOS, the field held to its own lines
                // against SwiftUI's defect of #113 (TextFieldLine.swift).
                .modifier(TextFieldLine(axis: lineAxis))
                .modifier(TextFieldText(font: tokens.textFont, color: tokens.textColor))
                .focused(isFocused)
                .modifier(TextFieldGlyphs(glyphs: glyphs, tokens: tokens, metrics: metrics))
                .padding(.horizontal, padding)
                .padding(.vertical, verticalPadding)
                .frame(minHeight: metrics.height.map(CGFloat.init))
                // The field's height is its own, its text's and padding's or its minimum height, whichever is more: a
                // layout that offers less does not squeeze it below its lines (the contract's description). Without
                // this, the field took any height offered down to its minimum, measured in TextFieldStyleTests at
                // accessibility5 on iOS 26.3: a framed field of one line 36 pt for its 65, a framed multiline one 36
                // for 142, an inline multiline one 8 for 126. Its lines are as many as its text and the product's
                // `lineLimit` give; past them the system field scrolls.
                .fixedSize(horizontal: false, vertical: true)
                .background {
                    if let background = tokens.background {
                        shape.fill(background)
                    }
                    if let borderColor = tokens.borderColor, let borderWidth = tokens.borderWidth {
                        shape.strokeBorder(borderColor, lineWidth: CGFloat(borderWidth))
                    }
                }
                .overlay {
                    if let ringColor = tokens.focusRingColor, let ringWidth = tokens.focusRingWidth {
                        ring(shape: shape, color: ringColor, width: ringWidth)
                    }
                }
                .onGeometryChange(for: CGFloat.self) {
                    $0.size.height
                } action: {
                    drawnHeight = $0
                }
                .modifier(TextFieldHitArea(extra: hitAreaExtra, isFocused: isFocused))
                .opacity(tokens.opacity.map(Double.init) ?? 1)
        }

        /// westron's focus ring, which replaces the system's (the contract), drawn outside the field's frame, so the
        /// field keeps its laid out size (`TextFieldMetrics.ringRadius` says where): on `framed` just outside the
        /// field's edge, touching it, following its shape; on `inline`, which has no shape, around the field, clear of
        /// its text.
        @ViewBuilder
        private func ring(shape: TextFieldShape, color: Westron.Color, width: Westron.Dimension) -> some View {
            switch variant.offered {
            case .framed:
                // The ring's inner edge is the field's edge: the shape grown by the ring's width, stroked inside.
                let outset = CGFloat(width)
                shape.outset(by: outset)
                    .strokeBorder(color, lineWidth: outset)
                    .padding(-outset)
            case .inline:
                shape.strokeBorder(color, lineWidth: CGFloat(width))
                    .padding(.horizontal, -CGFloat(TextFieldMetrics.inlineRingOutsetHorizontal))
                    .padding(.vertical, -CGFloat(TextFieldMetrics.inlineRingOutsetVertical))
            }
        }

        /// How far the area that takes clicks reaches above and below a `framed` field drawn lower than the platform's
        /// recommended target, so that it is the target's height (chapter 08; the contract's `size`), measured in
        /// CatalogUITests/TextFieldBehaviorTests:
        /// - macOS: a click lands only where a view is, so a field at s, drawn 24 pt high, reaches 2 pt past each edge,
        ///   28 pt in all, and no farther. The contract takes the overlap with a neighbor closer than 2 pt (P12).
        /// - iOS: the touch tolerance of the style's tap gesture (`TextFieldHitArea`) already takes a tap 8 pt past the
        ///   drawn edge of a field at s, drawn 28 pt high, at the 44 pt target (a one-off probe found it ending between
        ///   16 and 18 pt), so westron grows no frame, as for Button: it would only take more taps meant for a neighbor.
        ///   At m, drawn 36 pt high, the target is 4 pt past each edge, within the same tolerance.
        private var hitAreaExtra: CGFloat {
            #if os(macOS)
                guard metrics.height != nil else { return .zero }
                return max(.zero, (TextFieldMetrics.minimumHitHeight - drawnHeight) / 2)
            #else
                return .zero
            #endif
        }
    }

    /// The glyphs at the field's start and its end (the contract's `leadingIcon` and `trailingIcon`, #115), beside the
    /// system field inside its padding, in one layout (`TextFieldGlyphRow`) that offers the field the row's width less
    /// each glyph and its gap and sizes the row by the field alone: so a glyph stands at the field's horizontal padding
    /// and `container.gap` from its text, and the field's fill, ring and hit area take it in. A glyph stands on the
    /// field's first text baseline, on one line and on several (TextFieldGlyphTests). A glyph is `Icon(_:)`, decoration hidden from assistive technology: a search
    /// field's role is the product's to give (the trait `isSearchField`), and a glyph names what the field is for, never
    /// an action (decisions/0003, second revision). It is drawn in `leadingIcon.color` in every state, disabled dimming
    /// it with the field, and in the field's text role, `framed`'s or on `inline` the context's, so that it scales with
    /// the text, at the image scale `medium` whatever its context's (`TextFieldGlyph`); the gap scales with Dynamic Type
    /// from its token, as the padding does, on the curve of `framed`'s text style, body's, which is `inline`'s too: a
    /// text field style cannot read its context's text style. Both stop growing at
    /// `TextFieldGlyph.largestTextSize`, while the field's text grows on (decisions/0003, "Revision: the glyphs stop at
    /// xxxLarge"); past it, at the accessibility sizes, a glyph is centred on the first line (`TextFieldGlyphRow`). A
    /// glyph never draws past a framed field's fill, nor past an inline field's first line: one that would is fitted
    /// to that room (`TextFieldGlyphRoom`; decisions/0003, "A glyph fitted to its room").
    ///
    /// The system field is the row's first view whether there are glyphs or not, so adding or removing one keeps the
    /// same field, its focus and its editing (TextFieldGlyphIdentityTests); with no glyph the row lays the field out as
    /// it would alone, to the same pixels.
    private struct TextFieldGlyphs: ViewModifier {
        let glyphs: TextFieldGlyphNames
        let tokens: TextFieldTokens
        let metrics: TextFieldMetrics
        @Environment(\.dynamicTypeSize) private var dynamicTypeSize
        @Environment(\.displayScale) private var displayScale

        init(glyphs: TextFieldGlyphNames, tokens: TextFieldTokens, metrics: TextFieldMetrics) {
            self.glyphs = glyphs
            self.tokens = tokens
            self.metrics = metrics
        }

        /// The glyphs are placed by a layout that sizes the row by the field alone, not by a stack: a stack added a
        /// pixel to a multi-line field whose glyph reaches higher than its first line (decisions/0003). The layout
        /// measures each glyph in the same pass as it lays out the field, so a field never draws its text under a
        /// glyph waiting for the glyph's width.
        func body(content: Content) -> some View {
            // macOS has no Dynamic Type, so a glyph there always stands on the baseline.
            #if os(macOS)
                let centred = false
            #else
                let centred = !glyphs.isEmpty && dynamicTypeSize > TextFieldGlyph.largestTextSize
            #endif
            let room: TextFieldGlyphRoom =
                metrics.height == nil
                ? .firstLine
                : .fill(
                    verticalPadding: metrics.paddingVertical.map(CGFloat.init) ?? .zero,
                    minimumHeight: metrics.height.map(CGFloat.init) ?? .zero)
            TextFieldGlyphRow(centredOnTheFirstLine: centred, room: room, displayScale: max(displayScale, 1)) {
                content
                    .anchorPreference(key: TextFieldGlyphAnchors.self, value: .bounds) {
                        glyphs.isEmpty ? [:] : [.field: $0]
                    }
                if let leading = glyphs.leading {
                    glyph(leading, part: .leading)
                }
                if let trailing = glyphs.trailing {
                    glyph(trailing, part: .trailing)
                }
                if !glyphs.isEmpty {
                    // A line of the field's text role at the text's size, never drawn: the lowest first baseline the
                    // field can have, the box a glyph is centred on, and on inline the room a glyph is fitted to.
                    Text(verbatim: "A")
                        .modifier(TextFieldGlyphRole(font: tokens.glyphFont))
                        .fixedSize()
                        .hidden()
                        .accessibilityHidden(true)
                        .layoutValue(key: TextFieldGlyphRow.Role.self, value: .line)
                }
            }
        }

        private func glyph(_ icon: Westron.Icon, part: TextFieldGlyphAnchors.Part) -> some View {
            TextFieldGlyph(icon: icon, part: part, tokens: tokens, metrics: metrics)
                .dynamicTypeSize(...TextFieldGlyph.largestTextSize)
                .layoutValue(key: TextFieldGlyphRow.Role.self, value: part == .leading ? .leading : .trailing)
        }
    }

    /// Where a glyph may draw, the room it is fitted to (decisions/0003, "A glyph fitted to its room"), in the row's
    /// height: on `framed` the field's fill, which reaches past the row, the system field, by the field's vertical
    /// padding and, where the field's minimum height is more than the row and its padding, half the rest, since the
    /// row is centred in that height (`TextFieldSurface`); on `inline`, which has no fill, the field's first line, the
    /// box of a line of its text role on its first baseline, within the row.
    enum TextFieldGlyphRoom: Equatable {
        case fill(verticalPadding: CGFloat, minimumHeight: CGFloat)
        case firstLine
    }

    /// The one rule that places a glyph in its room (decisions/0003, "A glyph fitted to its room", revision "One
    /// rule, by the edges"), which the row and the tests both call, so that they cannot disagree. Everything follows
    /// from where the glyph would stand, its natural frame, and the room, at the screen's scale:
    /// - each edge within a pixel of the room: the glyph is left as it is, where it stands and at its own size (scaled
    ///   down by a pixel it would only blur, and a symbol's ink stops short of its frame);
    /// - otherwise, if it can stand within a pixel of each edge at its own size (it is at most two pixels taller than
    ///   the room), it is moved the least that puts it there;
    /// - otherwise it is scaled down, its proportions kept, to the room's height, and stands in the room.
    /// A glyph moved or scaled is fitted; its width stays its own.
    enum TextFieldGlyphFitting {
        /// What a glyph may reach past its room, at each edge, and still be left alone: a pixel of the screen, and the
        /// margin no comparison sits on.
        static func slack(displayScale: CGFloat) -> CGFloat {
            let pixel = pixel(displayScale: displayScale)
            return pixel + margin(pixel: pixel)
        }

        /// A pixel of the screen, in points.
        static func pixel(displayScale: CGFloat) -> CGFloat {
            1 / max(displayScale, 1)
        }

        /// Laid out on a screen, a glyph and its room stand on its pixels, so lengths that differ differ by a pixel;
        /// what is less is floating point, which a glyph exactly a pixel taller than its room shows
        /// (20.666666666666664 against 20.333333333333332 + 1/3 at three pixels a point). An eighth of a pixel keeps
        /// every comparison clear of that boundary and far below the next pixel.
        static func margin(pixel: CGFloat) -> CGFloat {
            pixel / 8
        }

        /// Where a glyph whose natural frame is `natural` is placed in `room`, and whether it was fitted: moved or
        /// scaled from where it would stand.
        static func place(natural: CGRect, room: CGRect, displayScale: CGFloat) -> (frame: CGRect, fitted: Bool) {
            let pixel = pixel(displayScale: displayScale)
            let slack = slack(displayScale: displayScale)
            if natural.minY >= room.minY - slack && natural.maxY <= room.maxY + slack {
                return (natural, false)
            }
            var frame = natural
            if natural.height <= room.height + 2 * slack {
                // At its own size, a pixel past the room at most at each edge, from where it stood.
                frame.origin.y = min(max(natural.minY, room.minY - pixel), room.maxY + pixel - natural.height)
            } else {
                frame.origin.y = room.minY
                frame.size.height = room.height
            }
            return (frame, true)
        }
    }

    /// The field and its glyphs in a row: the field is offered the row's width less each glyph's, and the row is the
    /// field's height, which a glyph does not change even where it reaches higher than the field's first line. A glyph
    /// stands on the field's first baseline; at the accessibility sizes, where it is smaller than its text, it is
    /// centred on the field's first line instead, the box of a line of the field's text role (decisions/0003, second
    /// revision). A glyph that would then reach past its room (`TextFieldGlyphRoom`) by more than a pixel at an edge
    /// is fitted to it, moved or scaled down (`TextFieldGlyphFitting.place`); one within a pixel at each edge stands
    /// where it would. The row's baselines are the field's. SwiftUI mirrors the places right to left.
    private struct TextFieldGlyphRow: Layout {
        /// What a view of the row is: the field, a glyph, or the line a glyph is centred on.
        enum Role: LayoutValueKey {
            case field, leading, trailing, line
            static let defaultValue = Role.field
        }

        let centredOnTheFirstLine: Bool
        let room: TextFieldGlyphRoom
        /// The screen's pixels to a point, which a centred glyph is placed on.
        let displayScale: CGFloat

        private struct Parts {
            var field: LayoutSubview?
            var leading: LayoutSubview?
            var trailing: LayoutSubview?
            var line: LayoutSubview?

            init(_ subviews: Subviews) {
                for subview in subviews {
                    switch subview[Role.self] {
                    case .field: field = field ?? subview
                    case .leading: leading = subview
                    case .trailing: trailing = subview
                    case .line: line = subview
                    }
                }
            }

            /// The width each glyph takes, its gap included: a glyph keeps its own width whatever it is offered.
            var leadingWidth: CGFloat { leading?.sizeThatFits(.unspecified).width ?? .zero }
            var trailingWidth: CGFloat { trailing?.sizeThatFits(.unspecified).width ?? .zero }

            /// What the field is offered: what the row is offered less the glyphs' widths.
            func fieldProposal(_ proposal: ProposedViewSize) -> ProposedViewSize {
                ProposedViewSize(
                    width: proposal.width.map { max(.zero, $0 - leadingWidth - trailingWidth) },
                    height: proposal.height)
            }
        }

        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let parts = Parts(subviews)
            guard let field = parts.field else { return .zero }
            let size = field.sizeThatFits(parts.fieldProposal(proposal))
            return CGSize(width: size.width + parts.leadingWidth + parts.trailingWidth, height: size.height)
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            let parts = Parts(subviews)
            guard let field = parts.field else { return }
            let fieldProposal = parts.fieldProposal(proposal)
            field.place(
                at: CGPoint(x: bounds.minX + parts.leadingWidth, y: bounds.minY), anchor: .topLeading,
                proposal: fieldProposal)
            // The field's first baseline, never above that of a line of its text role at its top: on iOS an empty
            // field of several lines, showing its prompt, gives one near its top, which set its glyphs above its fill
            // and its prompt (decisions/0003, "A glyph fitted to its room").
            let fieldBaseline = field.dimensions(in: fieldProposal)[.firstTextBaseline]
            let baseline = max(
                fieldBaseline, parts.line?.dimensions(in: .unspecified)[.firstTextBaseline] ?? fieldBaseline)
            // The box of the field's first line, in the row: where a glyph is centred at the accessibility sizes, and
            // on inline its room.
            let lineBox = parts.line.map { line -> (top: CGFloat, height: CGFloat) in
                let dimensions = line.dimensions(in: .unspecified)
                return (baseline - dimensions[.firstTextBaseline], dimensions.height)
            }
            let lineMiddle = lineBox.map { $0.top + $0.height / 2 }
            if let line = parts.line {
                line.place(at: bounds.origin, anchor: .topLeading, proposal: .unspecified)
            }
            let room = glyphRoom(in: bounds, firstLine: lineBox)
            for (glyph, x, anchor) in [
                (parts.leading, bounds.minX, UnitPoint.topLeading),
                (parts.trailing, bounds.maxX, UnitPoint.topTrailing),
            ] {
                guard let glyph else { continue }
                let dimensions = glyph.dimensions(in: .unspecified)
                let y =
                    if centredOnTheFirstLine, let lineMiddle {
                        // On the pixel, so that the glyph keeps its drawn size: from the middle of a line its top falls
                        // between pixels, and a glyph snapped at both edges came out a pixel taller.
                        ((bounds.minY + lineMiddle - dimensions.height / 2) * displayScale).rounded() / displayScale
                    } else {
                        bounds.minY + baseline - dimensions[.firstTextBaseline]
                    }
                // Left where it would stand, moved, or scaled to the room's height; its width stays its own, so the
                // field's text keeps its place (`TextFieldGlyphFit` scales the drawing).
                let natural = CGRect(
                    x: anchor == .topLeading ? x : x - dimensions.width, y: y, width: dimensions.width,
                    height: dimensions.height)
                let (frame, fitted) = TextFieldGlyphFitting.place(
                    natural: natural, room: room, displayScale: displayScale)
                glyph.place(
                    at: CGPoint(x: x, y: frame.minY), anchor: anchor,
                    proposal: fitted ? ProposedViewSize(width: nil, height: frame.height) : .unspecified)
            }
        }

        /// The room a glyph may draw in (`TextFieldGlyphRoom`), in the row's coordinates.
        private func glyphRoom(in bounds: CGRect, firstLine: (top: CGFloat, height: CGFloat)?) -> CGRect {
            switch room {
            case .fill(let verticalPadding, let minimumHeight):
                let beyond = verticalPadding + max(.zero, (minimumHeight - bounds.height - 2 * verticalPadding) / 2)
                return bounds.insetBy(dx: .zero, dy: -beyond)
            case .firstLine:
                guard let firstLine else { return bounds }
                let line = CGRect(
                    x: bounds.minX, y: bounds.minY + firstLine.top, width: bounds.width, height: firstLine.height)
                return line.intersection(bounds)
            }
        }

        func explicitAlignment(
            of guide: VerticalAlignment, in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews,
            cache: inout ()
        ) -> CGFloat? {
            let parts = Parts(subviews)
            guard let field = parts.field else { return nil }
            return bounds.minY + field.dimensions(in: parts.fieldProposal(proposal))[guide]
        }
    }

    /// One glyph and its gap to the field's text, at the text size of its context up to `largestTextSize`, which
    /// `TextFieldGlyphs` holds it to.
    struct TextFieldGlyph: View {
        /// The largest text size a glyph and its gap follow, the largest one that is not an accessibility size. Inside
        /// a field the width is what the person types into and the glyph is decoration, so at accessibility1 to 5 the
        /// glyph, its gap and the room the field leaves them stay as they are at xxxLarge while the field's text grows
        /// on: a named exception to an icon scaling with the text beside it (design-language/07; decisions/0003,
        /// "Revision: the glyphs stop at xxxLarge"). macOS has no Dynamic Type, so nothing changes there.
        static let largestTextSize = DynamicTypeSize.xxxLarge

        let icon: Westron.Icon
        let part: TextFieldGlyphAnchors.Part
        let tokens: TextFieldTokens
        @ScaledMetric private var gap: CGFloat

        init(icon: Westron.Icon, part: TextFieldGlyphAnchors.Part, tokens: TextFieldTokens, metrics: TextFieldMetrics) {
            self.icon = icon
            self.part = part
            self.tokens = tokens
            // On `inline` the context's text style is out of reach (SwiftUI's font is opaque, and `.textRole(_:)` sets
            // no value a style reads), so the gap scales on body's curve there: the contract's `platforms.apple`.
            let textStyle = Font.TextStyle((tokens.textFont ?? .body.regular).textStyle)
            _gap = ScaledMetric(wrappedValue: CGFloat(metrics.gap), relativeTo: textStyle)
        }

        /// The coordinate space of the room `TextFieldGlyphFit` gives the glyph, which the glyph's drawing reads.
        nonisolated static let fitSpace = "westron.textField.glyphFit"

        var body: some View {
            TextFieldGlyphFit {
                Icon(icon)
                    // The text's own scale, fixed: a context's `.imageScale(_:)` changes neither the glyph nor the room
                    // the field leaves it, as Button and Chip fix their icons' (the contract's description).
                    .imageScale(.medium)
                    .modifier(TextFieldGlyphRole(font: tokens.glyphFont))
                    .foregroundStyle(tokens.glyphColor)
                    .fixedSize()
                    // Drawn at its own size, or, in a room the row fitted it to that is lower, scaled down to it,
                    // centred in it, its proportions kept: a scale of the drawing alone, which the layout has placed.
                    .visualEffect { content, proxy in
                        let room = proxy.bounds(of: .named(TextFieldGlyph.fitSpace))?.height ?? proxy.size.height
                        return content.scaleEffect(
                            proxy.size.height > room && proxy.size.height > .zero ? room / proxy.size.height : 1)
                    }
            }
            .coordinateSpace(.named(Self.fitSpace))
            .anchorPreference(key: TextFieldGlyphAnchors.self, value: .bounds) { [part: $0] }
            // Between the glyph and the text: after the glyph at the start, before the one at the end.
            .padding(part == .trailing ? .leading : .trailing, gap)
        }
    }

    /// The room of one glyph: its own size, or, offered a lower height by the row (`TextFieldGlyphRow`), that height at
    /// the glyph's own width, the glyph centred in it. Its baselines are the glyph's where it is placed.
    private struct TextFieldGlyphFit: Layout {
        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            guard let glyph = subviews.first else { return .zero }
            let size = glyph.sizeThatFits(.unspecified)
            guard let height = proposal.height, height < size.height else { return size }
            return CGSize(width: size.width, height: height)
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            guard let glyph = subviews.first else { return }
            // By its top leading corner, which at the glyph's own size is the room's: placed by its centre, a glyph
            // between pixels was rounded to another pixel than at its corner.
            let size = glyph.sizeThatFits(.unspecified)
            let top = bounds.height < size.height ? bounds.midY - size.height / 2 : bounds.minY
            glyph.place(at: CGPoint(x: bounds.minX, y: top), anchor: .topLeading, proposal: .unspecified)
        }

        func explicitAlignment(
            of guide: VerticalAlignment, in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews,
            cache: inout ()
        ) -> CGFloat? {
            guard guide == .firstTextBaseline || guide == .lastTextBaseline, let glyph = subviews.first else {
                return nil
            }
            let dimensions = glyph.dimensions(in: .unspecified)
            return bounds.midY - dimensions.height / 2 + dimensions[guide]
        }
    }

    /// A glyph's text role: `framed`'s, or on `inline`, where it is nil, the context's.
    private struct TextFieldGlyphRole: ViewModifier {
        let font: Westron.TextRole?

        func body(content: Content) -> some View {
            if let font {
                content.textRole(font)
            } else {
                content
            }
        }
    }

    /// The text role and the text color of `framed`; on `inline`, where both are nil, the context's stay.
    private struct TextFieldText: ViewModifier {
        let font: Westron.TextRole?
        let color: Westron.Color?

        func body(content: Content) -> some View {
            if let font, let color {
                content.textRole(font).foregroundStyle(color)
            } else {
                content
            }
        }
    }

    /// The field takes a touch or a click anywhere in what it draws, its padding included, and `extra` above and below
    /// it: the area is grown inside and the layout given back outside, so the field keeps its drawn and laid out size,
    /// as Button measured on macOS (its ButtonVariantStyle). A touch or a click there focuses the field; inside its
    /// text, the system field takes it itself, and places the caret. On iOS this tap gesture is also what takes a tap
    /// on the padding and past the drawn edge: without it, both missed (CatalogUITests/TextFieldBehaviorTests, #30).
    private struct TextFieldHitArea: ViewModifier {
        let extra: CGFloat
        let isFocused: FocusState<Bool>.Binding

        func body(content: Content) -> some View {
            content
                .padding(.vertical, extra)
                .contentShape(.interaction, Rectangle())
                .simultaneousGesture(TapGesture().onEnded { isFocused.wrappedValue = true })
                .padding(.vertical, -extra)
        }
    }
#endif
