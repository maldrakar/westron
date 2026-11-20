// Hand-written. TextField's look and behavior from its contract, spec/components/text-field/text-field.spec.yaml, on
// SwiftUI's own TextField and SecureField (decisions/0001, 0003). The generated `textFieldStyle(_:size:)`
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

import SwiftUI

/// westron's TextField style, which the generated `textFieldStyle(_:size:)` applies (decisions/0001, 0003).
struct TextFieldVariantStyle: @preconcurrency TextFieldStyle {
    let variant: TextFieldVariant
    /// nil: the size comes from `controlSize`.
    let size: TextFieldSize?

    @MainActor func _body(configuration: TextField<_Label>) -> some View {
        TextFieldBody(field: configuration, variant: variant, explicitSize: size)
    }
}

/// Reads the field's states and draws it from its tokens.
private struct TextFieldBody: View {
    let field: TextField<TextFieldVariantStyle._Label>
    let variant: TextFieldVariant
    let explicitSize: TextFieldSize?

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
            // `watchos` block); a tap opens the system's text input, and there is no focus to draw.
            field
                .opacity(tokens.opacity.map(Double.init) ?? 1)
        #else
            let metrics = TextFieldMetrics(
                variant: variant, size: .resolved(explicit: explicitSize, controlSize: controlSize),
                axis: TextFieldAxis.of(field))
            TextFieldSurface(field: field, variant: variant, tokens: tokens, metrics: metrics, isFocused: $isFocused)
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
    /// its padding, height, fill, high-contrast outline, focus ring, hit area and opacity. The padding scales with
    /// Dynamic Type from its token, relative to the field's text style.
    private struct TextFieldSurface: View {
        let field: TextField<TextFieldVariantStyle._Label>
        let variant: TextFieldVariant
        let tokens: TextFieldTokens
        let metrics: TextFieldMetrics
        let isFocused: FocusState<Bool>.Binding
        @ScaledMetric private var padding: CGFloat
        /// The padding above and below a multiline framed field's text, which holds its lines off the field's edges.
        @ScaledMetric private var verticalPadding: CGFloat
        /// The height the field is drawn at, which grows past its minimum with its text.
        @State private var drawnHeight: CGFloat = .zero

        init(
            field: TextField<TextFieldVariantStyle._Label>, variant: TextFieldVariant, tokens: TextFieldTokens,
            metrics: TextFieldMetrics, isFocused: FocusState<Bool>.Binding
        ) {
            self.field = field
            self.variant = variant
            self.tokens = tokens
            self.metrics = metrics
            self.isFocused = isFocused
            let textStyle = Font.TextStyle((tokens.textFont ?? .body.regular).textStyle)
            _padding = ScaledMetric(
                wrappedValue: metrics.paddingHorizontal.map(CGFloat.init) ?? .zero, relativeTo: textStyle)
            _verticalPadding = ScaledMetric(
                wrappedValue: metrics.paddingVertical.map(CGFloat.init) ?? .zero, relativeTo: textStyle)
        }

        var body: some View {
            // A framed field's shape: the capsule on one line, the rounded rectangle on several (`container.shape`,
            // `container.radius`); on `inline`, which has none, the corners its ring takes.
            let shape = TextFieldShape(
                radius: metrics.isCapsule ? nil : CGFloat(metrics.radius ?? TextFieldMetrics.ringRadius))

            field
                .textFieldStyle(.plain)
                .modifier(TextFieldText(font: tokens.textFont, color: tokens.textColor))
                .focused(isFocused)
                .padding(.horizontal, padding)
                .padding(.vertical, verticalPadding)
                .frame(minHeight: metrics.height.map(CGFloat.init))
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
        /// field keeps its laid out size (`TextFieldMetrics.ringRadius` says where): on `framed` outside the field's
        /// edge, following its shape; on `inline`, which has no shape, around the field, clear of its text.
        @ViewBuilder
        private func ring(shape: TextFieldShape, color: Westron.Color, width: Westron.Dimension) -> some View {
            switch variant.offered {
            case .framed:
                let outset = CGFloat(TextFieldMetrics.framedRingGap) + CGFloat(width)
                shape.outset(by: outset)
                    .strokeBorder(color, lineWidth: CGFloat(width))
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
