// Generated from spec/components/surface/surface.spec.yaml by `tools/westron generate`. Do not edit: change the
// contract and generate again (spec/conventions.md).
//
// Surface's vocabulary from its contract: the enums of its options. WestronContract imports nothing, so that a
// product's shared code names them without SwiftUI; WestronUI re-exports it and adds the SwiftUI side (decisions/0017).

/// Surface's option `variant`, from its contract.
///
/// No default: every use names its kind. The kinds differ by height: sunken lies below the canvas, raised barely lifts,
/// dragged is unmistakable (design-language/04, "Shadows").
public enum SurfaceVariant: String, CaseIterable, Sendable {
    case raised
    case dragged
    case sunken
}
