// Generated from spec/components/surface/surface.spec.yaml by `tools/westron generate`. Do not edit: change the
// contract and generate again (spec/conventions.md).
//
// Surface's API from its contract: the enums of its options. It is an own component, and the modifier
// `surface(_:outlined:)` is hand-written in WestronUI/Surface/; the API parity lint holds the signature to the contract
// (spec/conventions.md, "Own components").

/// Surface's option `variant`, from its contract.
///
/// No default: every use names its kind. The kinds differ by height: sunken lies below the canvas, raised barely lifts,
/// dragged is unmistakable (design-language/04, "Shadows").
public enum SurfaceVariant: String, CaseIterable, Sendable {
    case raised
    case dragged
    case sunken
}
