// Hand-written. Rule from its contract, spec/components/rule/rule.spec.yaml: westron's straight line between two
// groups. It is an own component in the form of a view (`platforms.apple.form`): the generated `RuleAxis`
// (Generated/Rule+Contract.swift) names its axes, and the API parity lint holds `Rule` and `init(axis:)` to the
// contract (spec/conventions.md, "Own components"). It is not named Divider, which would collide with SwiftUI's in
// every file that imports SwiftUI (decisions/0003, point 3).

import SwiftUI

/// westron's rule: a straight line in `color.border.default`, `stroke.thin` across its axis, that fills the length it
/// is offered along it. `Rule()` runs along the width and separates groups stacked one above the other;
/// `Rule(axis: .vertical)` runs along the height and separates groups side by side. Unlike the system `Divider`, it
/// takes its axis from the argument, not from its stack. The product gives it its length and the space around it with
/// its stack and spacing tokens. It is decorative, so it is hidden from assistive technology.
public struct Rule: View {
    let axis: RuleAxis

    /// - Parameter axis: See `RuleAxis`; by default `.horizontal`.
    public init(axis: RuleAxis = .horizontal) {
        self.axis = axis
    }

    public var body: some View {
        // A filled rectangle, as the pilot draws its rules, rather than a stroked path: its thickness is exact.
        Rectangle()
            .fill(.border.default)
            .frame(
                width: axis == .vertical ? .stroke.thin : nil,
                height: axis == .horizontal ? .stroke.thin : nil
            )
            .accessibilityHidden(true)
    }
}
