extension AppleComponents {
    /// The API of a control with no drawn label (`accessibility.hiddenLabel`, spec/conventions.md, "A label that is not
    /// drawn"), as the conventions derive it from a style on a system control: two initializers of the base control in
    /// an extension constrained on the label westron gives it, an `EmptyView` that carries the accessible name, which
    /// the initializer requires:
    ///
    ///     extension Toggle where Label == ModifiedContent<EmptyView, AccessibilityAttachmentModifier> {
    ///         public init(isOn: Binding<Bool>, accessibilityLabel: LocalizedStringKey)
    ///         @_disfavoredOverload
    ///         public init<S: StringProtocol>(isOn: Binding<Bool>, accessibilityLabel: S)
    ///     }
    ///
    /// The parameters before the name are the control's own initializer's with a label view
    /// (`SystemStyles.Base.hiddenLabelParameters`); the name takes a localized key, and a string that is not localized
    /// in the twin, as `Icon(_:label:)` does. The label type is SwiftUI's own, what `EmptyView().accessibilityLabel(_:)`
    /// returns, so westron adds no type: the style lays out nothing for an `EmptyView`, and the system control of the
    /// accessibility representation takes its name from it (Checkbox's decisions/0002, measured on iOS 17.5 and 26.3).
    /// Hand-written in WestronUI; the API parity lint holds it to this.
    public struct HiddenLabel: Equatable, Sendable {
        /// `Toggle` for `SwiftUI.Toggle`: the type the extension extends.
        public let control: String
        /// The extension's `where` clause, as Swift's parser reads it.
        public let requirement: String
        public let initializers: [Own.Initializer]

        /// The label westron's initializer gives the control.
        public static let labelType = "ModifiedContent<EmptyView, AccessibilityAttachmentModifier>"
        /// The name of the parameter that takes the accessible name, after `.accessibilityLabel(_:)`.
        public static let parameter = "accessibilityLabel"

        /// - Returns: nil when the contract has no `accessibility.hiddenLabel`.
        /// - Throws: `ContractProblem` when it has one on a strategy or a base the conventions derive no initializer
        ///   for yet; `spec check` reports the same.
        public init?(_ contract: ComponentContract, source: String) throws(ContractProblem) {
            guard contract.hiddenLabel else { return nil }
            let path = DocumentPath.root.key("accessibility").key("hiddenLabel")
            guard let apple = contract.apple else { return nil }
            guard apple.strategy == AppleComponents.strategy, let base = apple.base,
                let parameters = SystemStyles.byBase[base]?.hiddenLabelParameters
            else {
                throw ContractProblem(
                    source: source, path: path, Self.notDerived(strategy: apple.strategy, base: apple.base))
            }
            control = String(base.split(separator: ".").last ?? Substring(base))
            requirement = "where Label == \(Self.labelType)"
            initializers = [
                Own.Initializer(parameters: parameters + [.init(label: Self.parameter, type: Own.labelType)]),
                Own.Initializer(
                    parameters: parameters + [.init(label: Self.parameter, type: Own.verbatimLabel.type)],
                    extras: Own.verbatimLabel.extras),
            ]
        }

        /// Why a contract's `hiddenLabel` gives no API on Apple yet.
        static func notDerived(strategy: String, base: String?) -> String {
            "the conventions derive the initializer of a control with no drawn label only for a "
                + "\(AppleComponents.strategy) on a base with its parameters in SystemStyles.Base.hiddenLabelParameters "
                + "(today SwiftUI.Toggle), not for \(strategy == AppleComponents.strategy ? (base ?? "no base") : strategy) "
                + "yet (spec/conventions.md, \"A label that is not drawn\")"
        }
    }
}
