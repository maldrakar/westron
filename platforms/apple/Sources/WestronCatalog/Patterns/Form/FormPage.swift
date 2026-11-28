import SwiftUI
import WestronUI

// The catalog entry of the pattern spec/patterns/form.md (decisions/0018, stage 2): the pattern's own example
// (Forms.swift) with three samples, one under the other on the canvas, at the page margin, as a sheet's or a screen's
// content stands. A sample is not presented in a sheet: a sheet would be modal and hide the entry from the
// accessibility audit and the screenshot, which find an entry by its container (`CatalogAccessibilityID.entry`).
//
// The first is the pilot's quick entry (todo-app, `QuickEntryView`), live: Add or Return with an empty title shows the
// module's sentence, "A title cannot be empty.", and a title it takes is cleared, where a product would close the
// sheet. The second is a technical product's form of several labelled fields, opened as it stands after a Create the
// product refused: the repository's error in its hint's place. It is live too: Return moves through its fields, and a
// draft the page takes is saved for two seconds with the button loading, the save recorded as it begins. The third is
// the pilot's task card's title and notes, inline, without the card's ground, the pilot's raised Surface: drawn here,
// Surface would put this entry in the pull-request audit of every change to Surface, which already selects 5 entries,
// the limit (`fan_out_limit` in tools/apple/audit-scope.sh), and would go past it.
//
// Every action is recorded under the samples, where a product would close the sheet, so that a UI test sees it
// (FormTests); the line shows only after the first. Neither form takes the keyboard focus when the page appears, so
// that the screenshots and the audit see the page without the keyboard: launched with `-WestronFormFocusOnAppear`, the
// quick entry does, as the pattern's forms do in a product. Launched with `-WestronFormSheet`, the page starts with a
// button that presents quick entry in a system `.sheet` over the page, as the pilot presents it over its window: on
// macOS that is the case in which the form's focus set in `onAppear` holds, since there one set in `onAppear` of a
// window's first content is dropped (spec/patterns/form.md, rule 12). The button is drawn only then, so that the
// screenshots and the audit see the pattern alone.

extension CatalogEntry {
    static let form = CatalogEntry(id: "form", title: "Pattern: a form", section: .patterns) {
        FormPage()
    }
}

/// The samples' words and the checks the page makes in the product's place.
enum FormSample {
    /// The pilot's refusal of an empty title (todo-app, `QuickEntry.Problem.emptyTitle`).
    static let emptyTitle = "A title cannot be empty."
    static let emptyName = "A name cannot be empty."
    static let notHTTPS = "Enter an address that starts with https://."
    /// The technical sample as it opens: a draft whose address the product refused.
    static let service = ServiceDraft(name: "billing", repository: "http://git.example.com/billing")
    static let serviceErrors: [ServiceDraft.Field: String] = [.repository: notHTTPS]
    /// A stored task's card (todo-app's list screen, the open card).
    static let card = (title: "Buy groceries", notes: "Milk, bread and apples")
    /// Whether the quick entry takes the keyboard focus when the page appears.
    static let focusesOnAppear = ProcessInfo.processInfo.arguments.contains("-WestronFormFocusOnAppear")
    /// Whether the page starts with a button that presents quick entry in a sheet.
    static let opensASheet = ProcessInfo.processInfo.arguments.contains("-WestronFormSheet")
}

/// The three samples, live; what their actions did is recorded under them.
struct FormPage: View {
    @State private var title = ""
    @State private var problem: String?
    @State private var service = FormSample.service
    @State private var serviceErrors = FormSample.serviceErrors
    @State private var cardTitle = FormSample.card.title
    @State private var notes = FormSample.card.notes
    @State private var last: String?
    @State private var isAdding = false  // quick entry's sheet, with `-WestronFormSheet`
    @State private var sheetTitle = ""
    @State private var sheetProblem: String?
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .space.betweenGroups) {
                if FormSample.opensASheet {
                    // First, so that it is in view without a scroll.
                    Button(FormPageID.openSheet) { isAdding = true }
                }
                TaskEntryForm(
                    title: $title, problem: $problem, focusesOnAppear: FormSample.focusesOnAppear, add: add,
                    cancel: { cancel("quick entry") })
                Rule()
                ServiceForm(
                    draft: $service, errors: $serviceErrors, focusesOnAppear: false, check: check, save: save,
                    cancel: { cancel("the service") })
                Rule()
                TaskCardFields(title: $cardTitle, notes: $notes)
                if let last {
                    // Only after an action, so that the screenshots show the pattern alone.
                    Text(verbatim: last)
                        .textRole(.footnote.regular)
                        .foregroundStyle(.text.secondary)
                        .accessibilityIdentifier(FormPageID.last)
                }
            }
            .padding(.horizontal, pageMargin)
            .padding(.vertical, .space.betweenGroups)
        }
        .background(.background.canvas)
        .sheet(isPresented: $isAdding) {
            // As the pattern's "Apple" section presents it: the form in a scroll view at the page margin.
            ScrollView {
                TaskEntryForm(
                    title: $sheetTitle, problem: $sheetProblem, add: addInSheet,
                    cancel: {
                        cancel("quick entry in a sheet")
                        isAdding = false
                    }
                )
                .padding(pageMargin)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(FormPageID.sheet)
            #if os(macOS)
                // The Mac sheet's least size, no token yet (spec/patterns/choice-list-sheet, G4, #172).
                .frame(minWidth: 320, minHeight: 240)
            #endif
        }
    }

    /// Quick entry's Add, as the pilot's module answers it: an empty title is refused, any other is taken.
    private func add() -> String? {
        take($title)
    }

    /// The sheet's Add: the same, and a title taken closes the sheet, as the pilot's does.
    private func addInSheet() -> String? {
        let refusal = take($sheetTitle)
        if refusal == nil { isAdding = false }
        return refusal
    }

    private func take(_ draft: Binding<String>) -> String? {
        let trimmed = draft.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return FormSample.emptyTitle }
        last = "Added “\(trimmed)”"
        draft.wrappedValue = ""
        return nil
    }

    /// The service's Create: each field's rule.
    private func check() -> [ServiceDraft.Field: String] {
        var errors: [ServiceDraft.Field: String] = [:]
        if service.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { errors[.name] = FormSample.emptyName }
        if !service.repository.hasPrefix("https://") { errors[.repository] = FormSample.notHTTPS }
        return errors
    }

    /// A save that takes two seconds. Its start is recorded at once and stays until the next action: the form loads
    /// Create only for the save it starts, so a UI test that reads no start knows that Create never loaded, however
    /// briefly.
    private func save() async {
        last = "Saving “\(service.name)”"
        try? await Task.sleep(for: .seconds(2))
        last = "Created “\(service.name)”"
    }

    private func cancel(_ form: String) {
        last = "Cancelled \(form)"
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
enum FormPageID {
    static let last = "westron.catalog.form.last"
    /// The container of quick entry's sheet, with `-WestronFormSheet`.
    static let sheet = "westron.catalog.form.sheet"
    /// The words of the button that presents it.
    static let openSheet = "Open quick entry in a sheet"
}
