/// The Apple base controls a contract may style (decisions/0003, "Constraint on value names"): for each, the modifier
/// that applies a style to it and the static names of its system styles. An option value with one of these names
/// would make the call ambiguous: with a westron `ButtonVariant.plain`, `.buttonStyle(.plain)` could be either.
///
/// A contract whose Apple strategy is `style-on-system-control` names its base here; a base without an entry is an
/// error, so the check never passes silently for a control nobody has looked at, and the generator never writes a
/// modifier the control does not have: `SwiftUI.Slider` and `SwiftUI.Stepper` have none, so a style cannot go on
/// them (#62). The modifier is not always named after the control: `SwiftUI.SecureField` has no `secureFieldStyle`
/// and takes `textFieldStyle`, as `SwiftUI.TextField` does; neither is here until a contract needs it. Add a control
/// with its modifier, its styles and the states it carries; on macOS, a test checks that the modifier exists in SwiftUI's interface
/// (`SwiftUITypesTests`).
///
/// A contract whose Apple strategy is `extension-on-system-control` names a base in `withoutStyle`: a control or view
/// that SwiftUI gives no style modifier, so westron adds extensions to it instead of a style (decisions/0003, point
/// 1). A base in `byBase` takes a style, and one in neither is an error, as above.
public enum SystemStyles {
    /// The Apple strategy of a component that adds extensions to a system view with no style.
    public static let extensionStrategy = "extension-on-system-control"

    /// The Apple bases with no style modifier that an `extension-on-system-control` may extend. On macOS, a test
    /// checks that SwiftUI's interface declares no `<control>Style` modifier for them (`SwiftUITypesTests`): for
    /// `SwiftUI.Text`, no `textStyle`.
    public static let withoutStyle: Set<String> = ["SwiftUI.Text"]

    /// The bases of `withoutStyle` whose own modifiers return the base, as `Text.font(_:)` returns a `Text`: an
    /// extension of one adds its modifier on the base too, returning the base, so that a part of a text keeps its own
    /// role inside Text interpolation (spec/conventions.md, "Extensions of a system view").
    public static let returningBase: Set<String> = ["SwiftUI.Text"]

    public struct Base: Equatable, Sendable {
        /// The style modifier, `buttonStyle` for `SwiftUI.Button`: the generated overload has its name.
        public let modifier: String
        public let styles: [String]
        /// The states the control carries itself, which its style reads from the system: no westron modifier sets
        /// them (spec/conventions.md, "States the system control has"). A contract's other states each get the shared
        /// modifier named as the state, such as `.loading(_:)`; the API parity lint (#21) expects it.
        public let states: [String]
    }

    public static let byBase: [String: Base] = [
        // The static members of ButtonStyle and PrimitiveButtonStyle on every Apple platform, those of newer OS
        // versions (glass, glassProminent) and of macOS only (link) included.
        "SwiftUI.Button": Base(
            modifier: "buttonStyle",
            styles: [
                "automatic", "bordered", "borderedProminent", "borderless", "glass", "glassProminent", "link", "plain",
            ],
            // configuration.isPressed, onHover, @Environment(\.isFocused), @Environment(\.isEnabled).
            states: ["pressed", "hover", "focus", "disabled"])
    ]
}
