import SwiftUI

/// Accessibility identifiers that tell the screenshot UI test (`CatalogUITests`)
/// that the isolated entry has rendered or that it cannot be shown.
public enum CatalogAccessibilityID {
    /// The container of the isolated entry.
    public static let entry = "westron.catalog.entry"
    /// The problem message; its `label` is the reason.
    public static let problem = "westron.catalog.problem"
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
                .modifier(DynamicTypeOverride(size: options.dynamicTypeSize))
        }
    }

    @ViewBuilder
    private func content(_ options: CatalogLaunchOptions) -> some View {
        if let id = options.entryID {
            if let entry = Catalog.entry(id: id) {
                entry.content()
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
