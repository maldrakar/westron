/// The static names of the system styles of each base control a contract may style (decisions/0003, "Constraint on
/// value names"). An option value with one of these names would make the call ambiguous: with a westron
/// `ButtonVariant.plain`, `.buttonStyle(.plain)` could be either.
///
/// A contract whose Apple strategy is `style-on-system-control` names its base here; a base without an entry is an
/// error, so the check never passes silently for a control nobody has looked at. Add the control's styles with it.
public enum SystemStyles {
    public static let byBase: [String: [String]] = [
        // The static members of ButtonStyle and PrimitiveButtonStyle on every Apple platform, those of newer OS
        // versions (glass, glassProminent) and of macOS only (link) included.
        "SwiftUI.Button": [
            "automatic", "bordered", "borderedProminent", "borderless", "glass", "glassProminent", "link", "plain",
        ]
    ]
}
