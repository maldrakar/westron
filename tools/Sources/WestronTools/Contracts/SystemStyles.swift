/// The Apple base controls a contract may style (decisions/0003, "Constraint on value names"): for each, the modifier
/// that applies a style to it and the static names of its system styles. An option value with one of these names
/// would make the call ambiguous: with a westron `ButtonVariant.plain`, `.buttonStyle(.plain)` could be either.
///
/// A contract whose Apple strategy is `style-on-system-control` names its base here; a base without an entry is an
/// error, so the check never passes silently for a control nobody has looked at, and the generator never writes a
/// modifier the control does not have: `SwiftUI.Slider` and `SwiftUI.Stepper` have none, so a style cannot go on
/// them (#62). The modifier is not always named after the control: `SwiftUI.SecureField` has no `secureFieldStyle`
/// and takes `textFieldStyle`, as `SwiftUI.TextField` does; neither is here until a contract needs it. Add a control
/// with its modifier and its styles; on macOS, a test checks that the modifier exists in SwiftUI's interface
/// (`SwiftUITypesTests`).
public enum SystemStyles {
    public struct Base: Equatable, Sendable {
        /// The style modifier, `buttonStyle` for `SwiftUI.Button`: the generated overload has its name.
        public let modifier: String
        public let styles: [String]
    }

    public static let byBase: [String: Base] = [
        // The static members of ButtonStyle and PrimitiveButtonStyle on every Apple platform, those of newer OS
        // versions (glass, glassProminent) and of macOS only (link) included.
        "SwiftUI.Button": Base(
            modifier: "buttonStyle",
            styles: [
                "automatic", "bordered", "borderedProminent", "borderless", "glass", "glassProminent", "link", "plain",
            ])
    ]
}
