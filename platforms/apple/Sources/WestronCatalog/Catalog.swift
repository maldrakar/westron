/// The registry of catalog entries.
///
/// A new component adds its entry here in the same pull request as its implementation.
/// The accessibility audit (`CatalogAccessibilityAuditTests`) iterates over the same entries, so the registry lives in
/// the package, not in the app. The snapshot matrix (#24) has a registry of its own, `ComponentMatrix.all`, generated
/// from the contracts, so its sheets are not audited.
public enum Catalog {
    public static let entries: [CatalogEntry] = [
        .button,
        .buttonDestructive,
        .buttonStates,
        .buttonStatesDestructive,
        .buttonStatesDestructiveDisabled,
        .buttonBehavior,
        .buttonFloating,
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
