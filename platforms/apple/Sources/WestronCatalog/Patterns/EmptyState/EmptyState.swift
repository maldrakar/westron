// The Apple example of spec/patterns/empty-state.md, the pattern's code: below this comment, the document's swift
// block as it stands, which PatternExampleTests holds equal to this file. Change the two together.

import SwiftUI
import WestronUI

struct EmptyAction {  // the one action that fills the screen, where the screen shows no other way to
    let title: String  // a verb: "Add task", "Deploy"
    let run: () -> Void
}

struct EmptyState: View {
    let icon: Westron.Icon  // the empty thing's own glyph, as the product stores it
    let category: Westron.Category?  // its list color; nil draws the neutral tile
    let title: String  // names the state: "Nothing here yet"
    let message: String  // says what will fill it
    var action: EmptyAction? = nil

    var body: some View {
        ContentUnavailableView {
            Label {
                Text(title)
                    .textRole(.heading.medium)
                    .foregroundStyle(.text.primary)
            } icon: {
                IconTile(icon)
                    .imageScale(.large)
                    .category(category)
            }
        } description: {
            Text(message)
                .textRole(.subheadline.regular)
                .foregroundStyle(.text.secondary)
        } actions: {
            if let action {
                Button(action.title, action: action.run)
                    .buttonStyle(.primary, size: .m)
            }
        }
    }
}
