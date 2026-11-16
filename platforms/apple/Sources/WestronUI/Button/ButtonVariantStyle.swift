// Hand-written. A SKELETON that #23 replaces with Button's look from its contract
// (spec/components/button/button.spec.yaml).
//
// It exists so that the API generated from the contract, Generated/Button+Contract.swift, compiles: the generated
// `buttonStyle(_:size:iconOnly:)` applies this style. It switches exhaustively over every generated enum, so a value
// renamed, added or removed in the contract fails the build here until this file follows it (#20).
//
// What it draws is the resting look of each variant and size, from the contract's tokens, and disabled. Not yet: hover
// and pressed tints, the press scale and its motion, loading's progress indicator and its refusal of presses, the
// icon-only square, the icon's layout and the minimum hit area. Those are #23.

import SwiftUI

/// westron's Button style, which the generated `buttonStyle(_:size:iconOnly:)` applies (decisions/0001, 0003).
struct ButtonVariantStyle: ButtonStyle {
    let variant: ButtonVariant
    /// nil: the size comes from `controlSize`.
    let size: ButtonSize?
    let iconOnly: Bool

    func makeBody(configuration: Configuration) -> some View {
        ButtonSkeleton(configuration: configuration, variant: variant, explicitSize: size, iconOnly: iconOnly)
    }
}

private struct ButtonSkeleton: View {
    let configuration: ButtonStyleConfiguration
    let variant: ButtonVariant
    let explicitSize: ButtonSize?
    let iconOnly: Bool

    @Environment(\.controlSize) private var controlSize
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @Environment(\.isLoading) private var isLoading
    @State private var isHovered = false

    /// An explicit size wins over `controlSize`; then the size this OS offers in its place.
    private var size: ButtonSize { (explicitSize ?? ButtonSize(controlSize)).offered }

    /// The role is SwiftUI's `ButtonRole`; any role other than destructive draws as default.
    private var isDestructive: Bool { configuration.role == .destructive }

    /// Whether the button is in a state of its contract, read where the system or westron's modifier keeps it.
    private func isIn(_ state: ButtonState) -> Bool {
        guard state.isEntered else { return false }
        switch state {
        case .hover: return isHovered
        case .focus: return isFocused
        case .pressed: return configuration.isPressed
        case .disabled: return !isEnabled
        case .loading: return isLoading
        }
    }

    var body: some View {
        label
            .textRole(textRole)
            .foregroundStyle(labelColor)
            .padding(.horizontal, padding)
            .frame(minHeight: height)
            .background {
                let shape = RoundedRectangle(cornerRadius: .radius.control, style: .continuous)
                switch variant.offered {
                case .primary: shape.fill(isDestructive ? .status.danger.fill : .background.accent)
                case .secondary:
                    shape.strokeBorder(isDestructive ? .status.danger.border : .border.strong, lineWidth: .stroke.thin)
                case .tertiary: EmptyView()
                }
            }
            .opacity(isIn(.disabled) ? .opacity.disabled : 1)
            #if !os(watchOS)
                .onHover { isHovered = $0 }
            #endif
    }

    @ViewBuilder private var label: some View {
        if iconOnly {
            configuration.label.labelStyle(.iconOnly)
        } else {
            configuration.label
        }
    }

    private var labelColor: Westron.Color {
        switch variant.offered {
        case .primary: isDestructive ? .status.danger.onFill : .text.onAccent
        case .secondary: isDestructive ? .status.danger.text : .text.primary
        case .tertiary: isDestructive ? .status.danger.text : .text.accent
        }
    }

    private var textRole: Westron.TextRole {
        switch size {
        case .s: .footnote.strong
        case .m, .l: .subheadline.strong
        }
    }

    private var height: CGFloat {
        switch size {
        case .s: .size.control.s
        case .m: .size.control.m
        case .l: .size.control.l
        }
    }

    private var padding: CGFloat {
        switch size {
        case .s: .space100
        case .m: .space150
        case .l: .space200
        }
    }
}
