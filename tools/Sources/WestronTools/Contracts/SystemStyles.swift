/// The Apple base controls a contract may style (decisions/0003, "Constraint on value names"): for each, the modifier
/// that applies a style to it and the static names of its system styles. An option value with one of these names
/// would shadow the system style: with a westron `ButtonVariant.plain`, `.buttonStyle(.plain)` compiles and silently
/// takes westron's overload, so existing code changes meaning without a diagnostic (decisions/0003, note of
/// 2026-11-18).
///
/// A contract whose Apple strategy is `style-on-system-control` names its base here; a base without an entry is an
/// error, so the check never passes silently for a control nobody has looked at, and the generator never writes a
/// modifier the control does not have: `SwiftUI.Slider` and `SwiftUI.Stepper` have none, so a style cannot go on
/// them (#62). The modifier is not always named after the control: `SwiftUI.SecureField` has no `secureFieldStyle`
/// and takes `textFieldStyle`, as `SwiftUI.TextField` does; it is not here until a contract needs it. Add a control
/// with its modifier, its style protocols, its styles and the states it carries; on macOS, a test checks that the
/// modifier exists in SwiftUI's interface and that the styles are the static styles the protocols declare there for
/// iOS, macOS or watchOS (`SwiftUITypesTests`).
///
/// A contract whose Apple strategy is `extension-on-system-control` names a base in `withoutStyle`: a control or view
/// that SwiftUI gives no style modifier, so westron adds extensions to it instead of a style (decisions/0003, point
/// 1). A base in `byBase` takes a style, and one in neither is an error, as above.
public enum SystemStyles {
    /// The Apple strategy of a component that adds extensions to a system view with no style.
    public static let extensionStrategy = "extension-on-system-control"

    /// The Apple bases with no style modifier that an `extension-on-system-control` may extend. On macOS, a test
    /// checks that SwiftUI's interface declares no `<control>Style` modifier for them (`SwiftUITypesTests`): for
    /// `SwiftUI.Text`, no `textStyle`; for `SwiftUI.Image`, no `imageStyle`.
    public static let withoutStyle: Set<String> = ["SwiftUI.Image", "SwiftUI.Text"]

    /// The bases of `withoutStyle` whose own modifiers return the base, as `Text.font(_:)` returns a `Text`: an
    /// extension of one adds its modifier on the base too, returning the base, so that a part of a text keeps its own
    /// role inside Text interpolation (spec/conventions.md, "Extensions of a system view").
    public static let returningBase: Set<String> = ["SwiftUI.Text"]

    public struct Base: Equatable, Sendable {
        /// The style modifier, `buttonStyle` for `SwiftUI.Button`: the generated overload has its name.
        public let modifier: String
        /// The style protocols whose static members are the control's system styles, as SwiftUI's interface names
        /// them: `ButtonStyle` and `PrimitiveButtonStyle` for `SwiftUI.Button`.
        public let protocols: [String]
        /// The static styles the protocols declare for iOS, macOS or watchOS, those of newer OS versions and of one
        /// OS only included.
        public let styles: [String]
        /// The states the control carries itself, which its style reads from the system: no westron modifier sets
        /// them (spec/conventions.md, "States the system control has"). A contract's other states each get the shared
        /// modifier named as the state, such as `.loading(_:)`; the API parity lint (#21) expects it.
        public let states: [String]
        /// The parameters of the control's own initializer with a label view, without the label, for westron's
        /// initializer of a control with no drawn label (`AppleComponents.HiddenLabel`): `isOn: Binding<Bool>` for
        /// `SwiftUI.Toggle`, as in `Toggle(isOn:label:)`. nil where no contract has needed one yet: a contract with
        /// `accessibility.hiddenLabel` on such a base fails `spec check` as not derived yet.
        public var hiddenLabelParameters: [SwiftDeclarations.Parameter]? = nil
    }

    public static let byBase: [String: Base] = [
        "SwiftUI.Button": Base(
            modifier: "buttonStyle", protocols: ["ButtonStyle", "PrimitiveButtonStyle"],
            // accessoryBar and accessoryBarAction are macOS only; card, tvOS only, is left out.
            styles: [
                "accessoryBar", "accessoryBarAction", "automatic", "bordered", "borderedProminent", "borderless",
                "glass", "glassProminent", "link", "plain",
            ],
            // configuration.isPressed, onHover, @Environment(\.isFocused), @Environment(\.isEnabled).
            states: ["pressed", "hover", "focus", "disabled"]),
        // SecureField takes the same modifier and styles; it gets its own entry when a contract names it.
        "SwiftUI.TextField": Base(
            modifier: "textFieldStyle", protocols: ["TextFieldStyle"],
            // roundedBorder is not on watchOS, squareBorder is macOS only, bordered is OS 27 and later.
            styles: ["automatic", "bordered", "plain", "roundedBorder", "squareBorder"],
            // The field's own focus, onHover, @Environment(\.isEnabled).
            states: ["focus", "hover", "disabled"]),
        "SwiftUI.Toggle": Base(
            modifier: "toggleStyle", protocols: ["ToggleStyle"],
            // checkbox is macOS only.
            styles: ["automatic", "button", "checkbox", "switch"],
            // configuration.isOn and isMixed; a press, which the style follows itself as it follows hover with
            // onHover, since ToggleStyleConfiguration has no isPressed; @Environment(\.isFocused) and
            // @Environment(\.isEnabled).
            states: ["checked", "mixed", "pressed", "hover", "focus", "disabled"],
            // Toggle(isOn:label:), the label left to westron's initializer (Checkbox, #86).
            hiddenLabelParameters: [.init(label: "isOn", type: "Binding<Bool>")]),
        // A view with a style and no states of its own: Chip's static form (#117). Its style cascades to every Label
        // below the modifier, as the system's label styles do.
        "SwiftUI.Label": Base(
            modifier: "labelStyle", protocols: ["LabelStyle"],
            styles: ["automatic", "iconOnly", "titleAndIcon", "titleOnly"],
            states: []),
    ]
}
