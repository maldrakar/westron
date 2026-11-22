/// The registry of catalog entries.
///
/// A new component adds its entry here in the same pull request as its implementation.
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

    /// The entries after the components that some OS lacks.
    private static let rest: [CatalogEntry] = [
        .textField,
        .textFieldBehavior,
        .textFieldFocusFramed,
        .textFieldFocusInline,
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
