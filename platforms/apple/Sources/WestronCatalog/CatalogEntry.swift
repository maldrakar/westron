import SwiftUI

/// One catalog entry: a component, a foundation sample or a utility page.
///
/// The catalog renders any entry in isolation by its `id` (the `-WestronEntry` launch argument),
/// so the `id` is stable and matches the component's `id` in its contract (`spec/components/<id>/`).
public struct CatalogEntry: Identifiable, Sendable {
    /// The catalog section that shows the entry.
    public enum Section: String, CaseIterable, Sendable {
        /// Components from `spec/components/`.
        case components
        /// Token samples: color, typography, spacing (they arrive in phase 1).
        case foundations
        /// Utility pages of the catalog.
        case utilities

        public var title: LocalizedStringKey {
            switch self {
            case .components: "Components"
            case .foundations: "Foundations"
            case .utilities: "Utilities"
            }
        }
    }

    public let id: String
    public let title: String
    public let section: Section
    private let makeContent: @MainActor @Sendable () -> AnyView

    public init<Content: View>(
        id: String,
        title: String,
        section: Section,
        @ViewBuilder content: @escaping @MainActor @Sendable () -> Content
    ) {
        self.id = id
        self.title = title
        self.section = section
        self.makeContent = { AnyView(content()) }
    }

    @MainActor
    public func content() -> AnyView {
        makeContent()
    }
}
