import SwiftUI
import WestronUI

// The catalog entry of the pattern spec/patterns/choice-list-sheet.md (decisions/0018, stage 2): the pattern's own
// example, `ChoiceSheet` (ChoiceSheet.swift), with sample choices that hold every part of its "Parts" table.
//
// On iOS the entry is the sheet's content as the sheet shows it, its NavigationStack, inline title and Cancel included,
// not a `.sheet` presented over a page: the sheet's page would be modal and hide the entry from the accessibility
// audit and the screenshot, which find an entry by its container (`CatalogAccessibilityID.entry`). On an iPhone the
// sheet is as wide as the screen, so the rows stand as they do in it; what is not drawn is the system's presentation
// around them, the sheet's rounded top and the page dimmed behind it, nor the system's sheet ground: so on iOS the
// contrast the audit and the screenshots see is against the page's ground, not a sheet's.
//
// On macOS a NavigationStack that is the window's content gives its title and toolbar to the window, and the entry's
// container is lost with it, so there the entry is a page that presents the sheet, a real `.sheet` with the pattern's
// least size (its rule 7): the Mac draws it as a sheet of its own over the window, which is how the pattern looks
// there. Cancel closes it, as a product's does, and the page's button opens it again.
//
// A choice taken moves the current mark to it, where a product would close the sheet, and Cancel puts the first back:
// so a UI test sees each press (ChoiceListSheetTests).

extension CatalogEntry {
    static let choiceListSheet = CatalogEntry(
        id: "choice-list-sheet", title: "Pattern: a list of choices in a sheet", section: .patterns
    ) {
        ChoiceListSheetPage()
    }
}

/// The sample: the pilot's "Move to…" sheet for a list named Core, which stands inside Project.
enum ChoiceListSheetSample {
    static let title = "Move “Core” to…"
    static let hint = "Choose where the list goes. It cannot go inside itself."
    /// The current choice when the sheet opens: where Core stands now.
    static let current = "project"

    /// Every part of the pattern's table, in the tree's order: the option that stands apart (a neutral tile, level 0),
    /// an item at level 0, a section that can be chosen, items at levels 1 and 2 in list colors, the current choice,
    /// the item itself (disabled), and a section that is only a heading with its items.
    static func choices(current: String) -> [Choice] {
        let choices = [
            Choice(id: "top", kind: .item(.divider, nil), title: "Top level"),
            Choice(id: "inbox", kind: .item(.tray, .blue), title: "Inbox"),
            Choice(id: "work", kind: .section, title: "WORK"),
            Choice(id: "project", kind: .item(.folder, .violet), title: "Project", level: 1),
            Choice(id: "core", kind: .item(.list, .teal), title: "Core", level: 2, isAvailable: false),
            Choice(id: "website", kind: .item(.list, .amber), title: "Website", level: 2),
            Choice(id: "clients", kind: .item(.briefcase, .orange), title: "Clients", level: 1),
            Choice(id: "personal", kind: .heading, title: "PERSONAL"),
            Choice(id: "home", kind: .item(.house, .green), title: "Home", level: 1),
            Choice(id: "reading", kind: .item(.book, .pink), title: "Reading", level: 1),
        ]
        return choices.map { choice in
            var choice = choice
            choice.isCurrent = choice.id == current
            return choice
        }
    }
}

/// The sheet with the sample, live: a choice taken becomes the current one, and Cancel restores the first.
struct ChoiceListSheetPage: View {
    @State private var current = ChoiceListSheetSample.current
    #if os(macOS)
        @State private var isPresented = true
    #endif

    var body: some View {
        #if os(macOS)
            VStack(spacing: .space.withinGroup) {
                Text(verbatim: "The pattern's sheet opens over this page.")
                    .textRole(.body.regular)
                    .foregroundStyle(.text.secondary)
                Button("Open the sheet") { isPresented = true }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .sheet(isPresented: $isPresented) { sheet }
        #else
            sheet
        #endif
    }

    private var sheet: some View {
        ChoiceSheet(
            title: ChoiceListSheetSample.title,
            hint: ChoiceListSheetSample.hint,
            choices: ChoiceListSheetSample.choices(current: current),
            choose: { current = $0.id },
            cancel: {
                current = ChoiceListSheetSample.current
                #if os(macOS)
                    isPresented = false
                #endif
            }
        )
    }
}
