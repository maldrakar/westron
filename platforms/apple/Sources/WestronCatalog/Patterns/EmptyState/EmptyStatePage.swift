import SwiftUI
import WestronUI

// The catalog entry of the pattern spec/patterns/empty-state.md (decisions/0018, stage 2): the pattern's own example,
// `EmptyState` (EmptyState.swift), with two samples that hold every part of its "Parts" table.
//
// The first is the pilot's empty list as todo-app's list screen words it: the list's own tile in its color, and no
// action, since the pilot's "+" floats over that screen. The second is a screen with no other way to fill it, from a
// technical product (design-language/01's own example): the neutral tile and the one action. Each stands as a whole
// screen's content stands, the system's view laid out in the room it is given, on the canvas; one under the other
// they scroll, so that the largest text sizes keep both whole.
//
// The action counts its presses under the samples, where a product would run it, so that a UI test sees each press
// (EmptyStateTests); the count shows only after the first.

extension CatalogEntry {
    static let emptyState = CatalogEntry(id: "empty-state", title: "Pattern: an empty state", section: .patterns) {
        EmptyStatePage()
    }
}

/// The samples' words and marks.
enum EmptyStateSample {
    /// The pilot's manual list with nothing in it (todo-app, `TaskList.emptyWords`).
    static let list = (
        icon: Westron.Icon.list, category: Westron.Category?.some(.teal),
        title: "Nothing here yet", message: "Add a task here, or drag one in."
    )
    /// A technical product's screen of deployments, which only its action fills (design-language/01).
    static let deployments = (
        icon: Westron.Icon.tray, category: Westron.Category?.none,
        title: "No deployments yet", message: "Each deployment of this service will show up here.", action: "Deploy"
    )
}

/// The two samples, one under the other, on the canvas; the action counts its presses.
struct EmptyStatePage: View {
    @State private var presses = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                EmptyState(
                    icon: EmptyStateSample.list.icon, category: EmptyStateSample.list.category,
                    title: EmptyStateSample.list.title, message: EmptyStateSample.list.message)
                Rule()
                EmptyState(
                    icon: EmptyStateSample.deployments.icon, category: EmptyStateSample.deployments.category,
                    title: EmptyStateSample.deployments.title, message: EmptyStateSample.deployments.message,
                    action: EmptyAction(title: EmptyStateSample.deployments.action) { presses += 1 })
                if presses > 0 {
                    // Only after a press, so that the screenshots show the pattern alone.
                    Text(verbatim: "Pressed \(presses) times")
                        .textRole(.footnote.regular)
                        .foregroundStyle(.text.secondary)
                        .accessibilityIdentifier(EmptyStatePageID.presses)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .background(.background.canvas)
    }
}

/// Identifiers of the page's parts, which the catalog's UI tests read.
enum EmptyStatePageID {
    static let presses = "westron.catalog.empty-state.presses"
}
