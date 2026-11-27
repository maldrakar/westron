/// The registry of catalog entries.
///
/// A new component adds its entry here in the same pull request as its implementation, and so does a pattern with its
/// Apple example (decisions/0018, stage 2).
/// The accessibility audit (`CatalogAccessibilityAuditTests`) iterates over the same entries, so the registry lives in
/// the package, not in the app. The snapshot matrix (#24) has a registry of its own, `ComponentMatrix.all`, generated
/// from the contracts, so its sheets are not audited.
public enum Catalog {
    /// Every entry on the current OS: a component an OS lacks has no entry there (Disclosure on watchOS).
    public static let entries: [CatalogEntry] = {
        var entries: [CatalogEntry] = [
            .button,
            .buttonDestructive,
            .buttonStates,
            .buttonStatesDestructive,
            .buttonStatesDestructiveDisabled,
            .buttonBehavior,
            .buttonFloating,
            .buttonFloatingSizes,
            .buttonFloatingStates,
            .buttonFloatingBefore26,
            .text,
            .icon,
            .iconTile,
            .surface,
            .rule,
            .checkbox,
            .checkboxInList,
            .chip,
            .listRow,
            .listRowInList,
        ]
        #if !os(watchOS)
            entries.append(.disclosure)
        #endif
        entries.append(contentsOf: rest)
        return entries
    }()

    /// The entries after the components that some OS lacks: the last components, the patterns, then the rest.
    private static let rest: [CatalogEntry] = [
        .textField,
        .textFieldGlyphs,
        .textFieldBehavior,
        .textFieldFocusFramed,
        .textFieldFocusInline,
        .choiceListSheet,
        .emptyState,
        .form,
        .colorBackgrounds,
        .colorForegrounds,
        .colorCategories,
        .colorStatus,
        .colorInUse,
        .typography,
        .typographyInText,
        .space,
        .shape,
        .controls,
        .motion,
        .icons,
        .environment,
    ]

    public static func entry(id: String) -> CatalogEntry? {
        entries.first { $0.id == id }
    }

    public static func entries(in section: CatalogEntry.Section) -> [CatalogEntry] {
        entries.filter { $0.section == section }
    }
}
