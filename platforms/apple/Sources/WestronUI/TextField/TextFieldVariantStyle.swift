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

    /// Whether the field draws no glyph: then its view is the one it was before the glyphs (#115).
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
    /// field inside its padding: the field gives each its width and `container.gap` of its own room, and the glyph is
    /// drawn there, so that it stands at the field's horizontal padding and `container.gap` from its text, and the
    /// field's fill, ring and hit area take it in. A glyph's baseline is the field's first line's, on one line and on
    /// several (TextFieldGlyphTests). A glyph is `Icon(_:)`, decoration hidden
    /// from assistive technology: a search field's role is the product's to give (the trait `isSearchField`), and a
    /// microphone at the end is no button. It is drawn in `leadingIcon.color` in every state, disabled dimming it with
    /// the field, and in the field's text role, `framed`'s or on `inline` the context's, so that it scales with the
    /// text. The gap scales with Dynamic Type from its token, as the padding does. With no glyph the field is as it was
    /// before the glyphs: the same view and the same pixels.
    private struct TextFieldGlyphs: ViewModifier {
        let glyphs: TextFieldGlyphNames
        let tokens: TextFieldTokens
        @ScaledMetric private var gap: CGFloat
        /// Each glyph's drawn width, which the field leaves room for beside its text.
        @State private var leadingWidth: CGFloat = .zero
        @State private var trailingWidth: CGFloat = .zero

        init(glyphs: TextFieldGlyphNames, tokens: TextFieldTokens, metrics: TextFieldMetrics) {
            self.glyphs = glyphs
            self.tokens = tokens
            let textStyle = Font.TextStyle((tokens.textFont ?? .body.regular).textStyle)
            _gap = ScaledMetric(wrappedValue: CGFloat(metrics.gap), relativeTo: textStyle)
        }

        /// The glyphs are overlays on the field's own room, not siblings of it in a stack: a stack around the system
        /// field made its accessibility element the whole row, which the accessibility audit took for a field whose
        /// text is clipped (#115). An overlay keeps the field the one element, at its own frame, and adds no height.
        func body(content: Content) -> some View {
            if glyphs.isEmpty {
                content
            } else {
                content
                    .anchorPreference(key: TextFieldGlyphAnchors.self, value: .bounds) { [.field: $0] }
                    .padding(.leading, glyphs.leading == nil ? .zero : leadingWidth + gap)
                    .padding(.trailing, glyphs.trailing == nil ? .zero : trailingWidth + gap)
                    .overlay(alignment: .leadingFirstTextBaseline) {
                        if let leading = glyphs.leading {
                            glyph(leading, part: .leading, width: $leadingWidth)
                        }
                    }
                    .overlay(alignment: .trailingFirstTextBaseline) {
                        if let trailing = glyphs.trailing {
                            glyph(trailing, part: .trailing, width: $trailingWidth)
                        }
                    }
            }
        }

        private func glyph(
            _ icon: Westron.Icon, part: TextFieldGlyphAnchors.Part, width: Binding<CGFloat>
        ) -> some View {
            Icon(icon)
                .modifier(TextFieldGlyphRole(font: tokens.glyphFont))
                .foregroundStyle(tokens.glyphColor)
                .fixedSize()
                .onGeometryChange(for: CGFloat.self) {
                    $0.size.width
                } action: {
                    width.wrappedValue = $0
                }
                .anchorPreference(key: TextFieldGlyphAnchors.self, value: .bounds) { [part: $0] }
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
