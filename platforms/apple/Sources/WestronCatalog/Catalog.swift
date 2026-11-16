/// The registry of catalog entries.
///
/// A new component adds its entry here in the same pull request as its implementation.
/// Snapshot tests (phase 2) iterate over the same entries, so the registry lives in the package, not in the app.
public enum Catalog {
    public static let entries: [CatalogEntry] = [
        .button,
        .buttonDestructive,
        .buttonStates,
        .buttonStatesDestructive,
        .buttonBehavior,
        .buttonLoadingLayouts,
        .buttonLoadingLayouts2,
        .colorBackgrounds,
        .colorForegrounds,
        .colorCategories,
        .colorStatus,
        .colorInUse,
        .typography,
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
