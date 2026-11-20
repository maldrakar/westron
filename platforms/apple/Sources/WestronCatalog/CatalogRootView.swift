import SwiftUI

/// Accessibility identifiers that tell the screenshot UI test (`CatalogUITests`)
/// that the isolated entry has rendered or that it cannot be shown.
public enum CatalogAccessibilityID {
    /// The container of the isolated entry.
    public static let entry = "westron.catalog.entry"
    /// The problem message; its `label` is the reason.
    public static let problem = "westron.catalog.problem"
    /// Each drawn cell of a snapshot matrix sheet, for a UI query or the Accessibility Inspector. The UI-test capture
    /// counted them; the in-process snapshot tests (#92) draw the cells by construction and need no query.
    public static let matrixCell = "westron.matrix.cell"
    /// The content of a snapshot matrix sheet. The UI-test capture cut its macOS picture around it; the in-process
    /// snapshot tests take the same frame from `EnvironmentValues.matrixSheetFrame`.
    public static let matrixSheet = "westron.matrix.sheet"
}

/// The root view of the catalog.
///
/// Without `-WestronEntry` it shows navigation over all entries. With it, it shows one entry on the whole screen,
/// without navigation: this is how `tools/apple/catalog-screenshot.sh` captures it.
public struct CatalogRootView: View {
    private let options: Result<CatalogLaunchOptions, CatalogLaunchOptions.ParseError>

    public init(options: Result<CatalogLaunchOptions, CatalogLaunchOptions.ParseError> = CatalogLaunchOptions.current) {
        self.options = options
    }

    public var body: some View {
        switch options {
        case .failure(let error):
            CatalogProblemView(message: error.description)
        case .success(let options):
            content(options)
                .preferredColorScheme(options.appearance?.colorScheme)
                .modifier(ContrastOverride(contrast: options.contrast?.colorSchemeContrast))
                .modifier(DynamicTypeOverride(size: options.dynamicTypeSize))
                .modifier(LegibilityWeightOverride(weight: options.legibilityWeight?.legibilityWeight))
        }
    }

    @ViewBuilder
    private func content(_ options: CatalogLaunchOptions) -> some View {
        if let key = options.matrixSheet {
            if let found = ComponentMatrix.sheet(key: key) {
                MatrixSheetView(matrix: found.matrix, sheet: found.sheet)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(CatalogAccessibilityID.entry)
            } else {
                let known = ComponentMatrix.all.flatMap { matrix in matrix.sheets.map(matrix.key(of:)) }
                CatalogProblemView(
                    message: "No snapshot matrix sheet \"\(key)\". Available: \(known.joined(separator: ", "))")
            }
        } else if let id = options.entryID {
            if let entry = Catalog.entry(id: id) {
                entry.content()
                    .modifier(ScrollAnchor(anchor: options.scrollAnchor))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(CatalogAccessibilityID.entry)
            } else {
                let known = Catalog.entries.map(\.id).joined(separator: ", ")
                CatalogProblemView(message: "No catalog entry \"\(id)\". Available: \(known)")
            }
        } else {
            CatalogBrowser()
        }
    }
}

/// SwiftUI has no `preferredColorSchemeContrast`, so the contrast goes into the environment of the whole tree: colors
/// from colorsets take their high-contrast variant, as they do when the system's Increase Contrast is on.
private struct ContrastOverride: ViewModifier {
    let contrast: ColorSchemeContrast?

    func body(content: Content) -> some View {
        if let contrast {
            content.environment(\._colorSchemeContrast, contrast)
        } else {
            content
        }
    }
}

/// The point of an entry's scroll content held in view, for `-WestronScrollAnchor`.
private struct ScrollAnchor: ViewModifier {
    let anchor: Double?

    func body(content: Content) -> some View {
        if let anchor {
            content.defaultScrollAnchor(UnitPoint(x: 0.5, y: anchor))
        } else {
            content
        }
    }
}

private struct DynamicTypeOverride: ViewModifier {
    let size: DynamicTypeSize?

    func body(content: Content) -> some View {
        if let size {
            content.dynamicTypeSize(size)
        } else {
            content
        }
    }
}

/// The system's Bold Text, as SwiftUI passes it down: the environment's `legibilityWeight`, which the system font and
/// westron's text roles read.
private struct LegibilityWeightOverride: ViewModifier {
    let weight: LegibilityWeight?

    func body(content: Content) -> some View {
        if let weight {
            content.environment(\.legibilityWeight, weight)
        } else {
            content
        }
    }
}

private struct CatalogBrowser: View {
    @State private var selection: String?

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(CatalogEntry.Section.allCases, id: \.self) { section in
                    let entries = Catalog.entries(in: section)
                    Section(section.title) {
                        if entries.isEmpty {
                            Text("Empty for now")
                                .foregroundStyle(.secondary)
                        }
                        ForEach(entries) { entry in
                            NavigationLink(entry.title, value: entry.id)
                        }
                    }
                }
            }
            .navigationTitle("Westron")
        } detail: {
            if let selection, let entry = Catalog.entry(id: selection) {
                entry.content()
                    .navigationTitle(entry.title)
            } else {
                ContentUnavailableView("Select an entry", systemImage: "square.grid.2x2")
            }
        }
    }
}

private struct CatalogProblemView: View {
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label("The catalog cannot show the entry", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(message))
        .accessibilityIdentifier(CatalogAccessibilityID.problem)
    }
}
