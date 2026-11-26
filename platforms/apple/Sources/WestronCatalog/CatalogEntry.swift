import SwiftUI

/// One catalog entry: a component, a pattern, a foundation sample or a utility page.
///
/// The catalog renders any entry in isolation by its `id` (the `-WestronEntry` launch argument),
/// so the `id` is stable: a component's entry starts with the component's `id` in its contract
/// (`spec/components/<id>/`), and a pattern's is the pattern's `id`, `spec/patterns/<id>.md` (decisions/0018).
public struct CatalogEntry: Identifiable, Sendable {
    /// The catalog section that shows the entry.
    public enum Section: String, CaseIterable, Sendable {
        /// Components from `spec/components/`.
        case components
        /// Patterns from `spec/patterns/`: each the pattern's Apple example, run (decisions/0018, stage 2). A pattern
        /// has no contract, so no generated matrix: its entry is its only picture.
        case patterns
        /// Token samples: color, typography, space, shape, motion.
        case foundations
        /// Utility pages of the catalog.
        case utilities

        public var title: LocalizedStringKey {
            switch self {
            case .components: "Components"
            case .patterns: "Patterns"
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
