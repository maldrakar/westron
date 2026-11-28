// The Apple example of spec/patterns/errors.md, the pattern's code: below this comment, the document's swift block as
// it stands, which PatternExampleTests holds equal to this file. Change the two together.

import SwiftUI
import WestronUI

/// The question a product asks before something that cannot be undone, in its own words (design-language/01).
struct Confirmation {
    let title: String  // asks, and names the thing: "Delete “Groceries”?"
    let message: String  // what goes and what stays: "One list inside it goes with it. No task is deleted."
    let action: String  // the verb of what it does, the command's own word: "Delete"
    let confirm: () -> Void  // does it; Cancel, and every other way out of the alert, does nothing
}

extension View {
    /// The system's alert while `confirmation` holds a question: its title and message, the destructive action, then
    /// Cancel. Either button, or Esc, takes the question away.
    func confirmation(_ confirmation: Binding<Confirmation?>) -> some View {
        alert(
            confirmation.wrappedValue?.title ?? "",
            isPresented: Binding(
                get: { confirmation.wrappedValue != nil },
                set: { isUp in if !isUp { confirmation.wrappedValue = nil } }),
            presenting: confirmation.wrappedValue
        ) { asked in
            Button(asked.action, role: .destructive, action: asked.confirm)
            Button("Cancel", role: .cancel) {}  // the system sets it apart, and presses it for Esc
        } message: { asked in
            Text(asked.message)
        }
    }
}

/// The one action that can mend a failure, where there is one: the same request again.
struct StatusAction {
    let title: LocalizedStringKey  // a verb: "Try again"
    let run: () async -> Void  // asks again; the product takes the line away when it succeeds
}

/// A failure told where it happened: its glyph, the product's sentence and, where one makes sense, the action that
/// mends it; beside the sentence, and under it at the accessibility text sizes.
struct StatusLine: View {
    // What failed and what it left, in the product's words: "The change could not be saved, so nothing was written."
    // A String, not a key: the product makes it at run time, in the person's language.
    let sentence: String
    var action: StatusAction? = nil
    @State private var isRunning = false
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        // One layout or the other around the same views, so that they keep their identity as the text size changes.
        let layout =
            textSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: .space.withinGroup))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: .space.withinGroup))
        layout {
            HStack(alignment: .firstTextBaseline, spacing: .space100) {
                Icon(.xmarkCircleFill).foregroundStyle(.status.danger.icon)
                Text(sentence)
                    .foregroundStyle(.status.danger.text)
                    .fixedSize(horizontal: false, vertical: true)  // every word, though the room above gives way
            }
            .textRole(.body.regular)
            .frame(maxWidth: .infinity, alignment: .leading)
            if let action {
                Button(action.title) {
                    guard !isRunning else { return }
                    isRunning = true
                    Task {
                        await action.run()
                        isRunning = false
                    }
                }
                .buttonStyle(.secondary, size: .m)
                .loading(isRunning)
            }
        }
        .padding(.space.card)
        .background(.status.danger.background, in: RoundedRectangle(cornerRadius: .radius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: .radius.card, style: .continuous)
                .strokeBorder(.status.danger.border, lineWidth: .stroke.thin)
        }
        .onAppear(perform: announce)
        .onChange(of: sentence) { announce() }
        // An action that ended with the line still standing failed again: say so, though the words may be the same.
        .onChange(of: isRunning) { _, running in if !running { announce() } }
    }

    private func announce() {
        AccessibilityNotification.Announcement(sentence).post()
    }
}
