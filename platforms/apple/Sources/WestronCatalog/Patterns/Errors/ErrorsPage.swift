import SwiftUI
import WestronUI

// The catalog entry of the pattern spec/patterns/errors.md (decisions/0018, stage 2): the pattern's own example
// (Errors.swift) with three samples, on the canvas at the page margin.
//
// The first is the pilot's delete of a list (todo-app's lists screen, `ListsDialogs`): the list "Groceries" and the
// command that asks, here a destructive Button in the row's place of the pilot's menu item "Delete", so that a UI test
// presses it without a long press or a right click. It puts up the system's alert with the pilot's words; Delete takes
// the list away and records it, Cancel leaves everything as it was. The second is a technical product's screen whose
// read failed: the status line in the content's place, with "Try again". The first try fails again, after two
// seconds, and the line stays; the second succeeds, after two seconds, and the deployments take the line's place. The
// third is the pilot's write that failed, its sentence in a status line under the screen's content (todo-app,
// `TaskList.Problem`, drawn by the pilot under the content, `listsSentence`); it goes with the person's next action on
// the page, as the pilot's sentence does.
//
// No Rule parts the samples, as it does on the other pattern entries: drawn here, Rule would put this entry in the
// pull-request audit of every change to Rule, which already selects 4 entries, and take the last place under the limit
// (`fan_out_limit` in tools/apple/audit-scope.sh). The samples are told apart by their space.
//
// The alert is not up when the page appears, so that the screenshots and the audit see the page; launched with
// `-WestronErrorsAsks`, the page puts the confirmation up as it appears, for a screenshot of the alert.

extension CatalogEntry {
    static let errors = CatalogEntry(id: "errors", title: "Pattern: errors", section: .patterns) {
        ErrorsPage()
    }
}

/// The samples' words, as the pilot and the technical product write them.
enum ErrorsSample {
    /// The pilot's list and its confirmation (todo-app, `TaskViewList.confirmation(deleting:among:)`).
    static let list = "Groceries"
    static let question = "Delete “Groceries”?"
    static let message = "One list inside it goes with it. No task is deleted."
    static let action = "Delete"
    /// The technical product's read that failed, and what its retry brings.
    static let notLoaded = "The deployments could not be loaded."
    static let loaded = "3 deployments"
    static let retry = "Try again"
    /// The pilot's write that failed (todo-app, `TaskList.Problem.couldNotSave`).
    static let notSaved = "The change could not be saved, so nothing was written."
    /// Whether the page puts the confirmation up as it appears.
    static let asksOnAppear = ProcessInfo.processInfo.arguments.contains("-WestronErrorsAsks")
}

/// The three samples, live; what the confirmation did is recorded under them.
struct ErrorsPage: View {
    @State private var isListKept = true
    @State private var confirmation: Confirmation?
    @State private var readProblem: String? = ErrorsSample.notLoaded
    @State private var tries = 0
    @State private var saveProblem: String? = ErrorsSample.notSaved
    @State private var last: String?
    @Environment(\.dynamicTypeSize) private var textSize
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: .space.betweenGroups) {
                    if isListKept {
                        // The list and its command; one under the other at the accessibility text sizes, where
                        // the command's word would not fit beside the list's name.
                        listLayout {
                            Text(verbatim: ErrorsSample.list)
                                .textRole(.body.regular)
                                .foregroundStyle(.text.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Button(role: .destructive, action: askToDelete) {
                                Label("Delete", icon: .trash)
                            }
                            .buttonStyle(.secondary, size: .m)
                            .accessibilityLabel(ErrorsPageID.deleteCommand)
                        }
                    }
                    VStack(alignment: .leading, spacing: .space.withinGroup) {
                        Text(verbatim: "Deployments")
                            .textRole(.heading.small)
                            .foregroundStyle(.text.primary)
                            .accessibilityAddTraits(.isHeader)
                        if let readProblem {
                            StatusLine(
                                sentence: readProblem, action: StatusAction(title: "Try again", run: tryAgain))
                        } else {
                            Text(verbatim: ErrorsSample.loaded)
                                .textRole(.body.regular)
                                .foregroundStyle(.text.primary)
                        }
                    }
                    if let last {
                        // Only after an action, so that the screenshots show the pattern alone.
                        Text(verbatim: last)
                            .textRole(.footnote.regular)
                            .foregroundStyle(.text.secondary)
                            .accessibilityIdentifier(ErrorsPageID.last)
                    }
                }
                .padding(.horizontal, pageMargin)
                .padding(.vertical, .space.betweenGroups)
            }
            if let saveProblem {
                // Under the content, not over it: the content ends above the line.
                StatusLine(sentence: saveProblem)
                    .padding(.horizontal, pageMargin)
                    .padding(.bottom, .space.withinGroup)
            }
        }
        .background(.background.canvas)
        .confirmation($confirmation)
        .onAppear { if ErrorsSample.asksOnAppear { askToDelete() } }
    }

    /// The command that asks: it puts the question up and does nothing else.
    private func askToDelete() {
        saveProblem = nil  // the person's next action takes the pilot's sentence away
        confirmation = Confirmation(
            title: ErrorsSample.question, message: ErrorsSample.message, action: ErrorsSample.action
        ) {
            isListKept = false
            last = "Deleted “\(ErrorsSample.list)”"
        }
    }

    /// The deployments read again: after two seconds, the first try fails again and the second succeeds.
    private func tryAgain() async {
        saveProblem = nil
        tries += 1
        try? await Task.sleep(for: .seconds(2))
        readProblem = tries < 2 ? ErrorsSample.notLoaded : nil
    }

    private var listLayout: AnyLayout {
        textSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: .space.withinGroup))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: .space.withinGroup))
    }

    private var pageMargin: CGFloat {
        #if os(iOS)
            sizeClass == .compact ? .space.page.narrow : .space.page.wide
        #else
            .space.page.wide
        #endif
    }
}

/// Identifiers of the page's parts, which the catalog's UI tests read.
enum ErrorsPageID {
    static let last = "westron.catalog.errors.last"
    /// The accessible name of the command that asks: what it does, and to what (design-language/01).
    static let deleteCommand = "Delete “Groceries”"
}
