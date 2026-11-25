// The Apple example of spec/patterns/choice-list-sheet.md, the pattern's code: below this comment, the document's
// swift block as it stands, which PatternExampleTests holds equal to this file. Change the two together.

import SwiftUI
import WestronUI

struct Choice: Identifiable {  // the product's model: words, a level and westron's vocabulary
    enum Kind { case item(Westron.Icon, Westron.Category?), section, heading }
    let id: String
    let kind: Kind
    let title: String  // a section's in capitals
    var level = 0
    var isCurrent = false
    var isAvailable = true
}

struct ChoiceSheet: View {
    let title: String
    let hint: String
    let choices: [Choice]  // "Top level" first, then the tree in order
    let choose: (Choice) -> Void
    let cancel: () -> Void
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    Text(hint)
                        .textRole(.footnote.regular)
                        .foregroundStyle(.text.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, .space.withinGroup)
                    ForEach(choices) { row($0) }
                }
                .padding(.horizontal, pageMargin)
            }
            .navigationTitle(title)
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", role: .cancel, action: cancel) }
            }
        }
        #if os(macOS)
            // westron-lint: allow the Mac sheet's least size, no token yet (spec/patterns/choice-list-sheet, G4, #172)
            .frame(minWidth: 320, minHeight: 400)
        #endif
    }

    @ViewBuilder private func row(_ choice: Choice) -> some View {
        switch choice.kind {
        case .item(let icon, let category):
            ListRow(level: choice.level, guides: false, action: { choose(choice) }) {
                Text(choice.title)
            } leading: {
                IconTile(icon).category(category)
            } trailing: {
                check(choice)
            }
            .selected(choice.isCurrent)
            .disabled(!choice.isAvailable)
        case .section:
            ListRow(level: choice.level, guides: false, action: { choose(choice) }) {
                Rule(choice.title)
            } trailing: {
                check(choice)
            }
            .selected(choice.isCurrent)
            .disabled(!choice.isAvailable)
        case .heading:
            ListRow(level: choice.level, guides: false) { Rule(choice.title) }
        }
    }

    @ViewBuilder private func check(_ choice: Choice) -> some View {
        if choice.isCurrent { Icon(.check).foregroundStyle(.text.primary) }
    }

    private var pageMargin: CGFloat {
        #if os(iOS)
            sizeClass == .compact ? .space.page.narrow : .space.page.wide
        #else
            .space.page.wide
        #endif
    }
}
