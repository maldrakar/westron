// The Apple example of spec/patterns/form.md, the pattern's code: below this comment, the document's swift block as it
// stands, which PatternExampleTests holds equal to this file. Change the two together.

import SwiftUI
import WestronUI

/// A framed field with what stands around it: its visible label above it, and under it its error, or its hint.
struct FormField<Field: View>: View {
    var label: String? = nil  // nil where the form's title names its one field
    var hint: String? = nil  // what a person needs to fill it, kept while they type
    var error: String? = nil  // the product's sentence refusing what it holds; stands in the hint's place
    @ViewBuilder let field: Field  // the TextField, named with the label's words

    var body: some View {
        VStack(alignment: .leading, spacing: .space75) {
            if let label {
                Text(label)
                    .textRole(.footnote.medium)
                    .foregroundStyle(.text.secondary)
                    .accessibilityHidden(true)  // the field carries the same words as its name
            }
            field
            if let error {
                HStack(alignment: .firstTextBaseline, spacing: .space50) {
                    Icon(.xmarkCircleFill).foregroundStyle(.status.danger.icon)
                    Text(error).foregroundStyle(.status.danger.text)
                }
                .textRole(.footnote.regular)
            } else if let hint {
                Text(hint)
                    .textRole(.footnote.regular)
                    .foregroundStyle(.text.secondary)
            }
        }
    }
}

/// The end of a form that is submitted: Cancel, then its one primary action; one under the other at the accessibility
/// text sizes.
struct FormActions: View {
    let primary: String  // a verb for what the form does: "Add", "Create"
    var isLoading = false  // while the product saves
    let submit: () -> Void
    let cancel: () -> Void
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        // One layout or the other around the same buttons, so that they keep their identity as the text size changes.
        let layout =
            textSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .trailing, spacing: .space.withinGroup))
            : AnyLayout(HStackLayout(spacing: .space.withinGroup))
        layout {
            Button("Cancel", action: cancel)
                .buttonStyle(.secondary, size: .m)
                #if !os(watchOS)
                    .keyboardShortcut(.cancelAction)  // Esc
                #endif
            Button(primary, action: submit)
                .buttonStyle(.primary, size: .m)
                .loading(isLoading)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

/// The form's title, the first thing it reads.
struct FormTitle: View {
    let text: String  // what the form makes: "New task"

    var body: some View {
        Text(text)
            .textRole(.heading.medium)
            .foregroundStyle(.text.primary)
            .accessibilityAddTraits(.isHeader)
    }
}

/// The pilot's quick entry: one field that names a new task, and Add.
struct TaskEntryForm: View {
    @Binding var title: String
    @Binding var problem: String?  // the product's sentence refusing the title: "A title cannot be empty."
    var focusesOnAppear = true  // it opens to be typed in
    let add: () -> Void  // keeps the task and closes the sheet, or sets `problem`
    let cancel: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: .space.withinGroup) {
            FormTitle(text: "New task")
            FormField(error: problem) {
                TextField("Title", text: $title, prompt: Text("Title").foregroundStyle(.text.placeholder))
                    .textFieldStyle(.framed)
                    .accessibilityLabel("Title")
                    .focused($focused)
                    .submitLabel(.done)
                    .onSubmit(submit)
            }
            FormActions(primary: "Add", submit: submit, cancel: cancel)
                .padding(.top, .space.withinGroup)
        }
        .onChange(of: title) { problem = nil }  // a keystroke takes the sentence away
        .onAppear { if focusesOnAppear { focused = true } }
    }

    private func submit() {
        add()
        if let problem {
            AccessibilityNotification.Announcement(problem).post()
            focused = true
        }
    }
}

/// A technical product's form of several fields: a label on each, a hint, an optional field, and a save that waits.
struct ServiceDraft {
    enum Field: CaseIterable { case name, repository, branch }  // in the form's order
    var name = ""
    var repository = ""
    var branch = ""  // optional: the repository's default branch when empty
}

struct ServiceForm: View {
    @Binding var draft: ServiceDraft
    @Binding var errors: [ServiceDraft.Field: String]  // the product's sentences, by field
    var focusesOnAppear = true
    let create: () async -> Void  // saves and closes the sheet, or sets `errors`
    let cancel: () -> Void
    @State private var isSaving = false
    @FocusState private var focused: ServiceDraft.Field?

    var body: some View {
        VStack(alignment: .leading, spacing: .space.withinGroup) {
            FormTitle(text: "New service")
            FormField(label: "Name", error: errors[.name]) {
                TextField("Name", text: $draft.name, prompt: Text("billing").foregroundStyle(.text.placeholder))
                    .textFieldStyle(.framed)
                    .accessibilityLabel("Name")
                    .focused($focused, equals: .name)
                    .submitLabel(.next)
                    .onSubmit { focused = .repository }
            }
            FormField(label: "Repository", hint: "Deployments build from this address.", error: errors[.repository]) {
                TextField(
                    "Repository", text: $draft.repository,
                    prompt: Text("https://git.example.com/billing").foregroundStyle(.text.placeholder)
                )
                .textFieldStyle(.framed)
                .accessibilityLabel("Repository")
                #if os(iOS)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()
                .focused($focused, equals: .repository)
                .submitLabel(.next)
                .onSubmit { focused = .branch }
            }
            FormField(label: "Branch (optional)", hint: "Without one, the repository’s default branch.") {
                TextField("Branch", text: $draft.branch, prompt: Text("main").foregroundStyle(.text.placeholder))
                    .textFieldStyle(.framed)
                    .accessibilityLabel("Branch (optional)")
                    .autocorrectionDisabled()
                    .focused($focused, equals: .branch)
                    .submitLabel(.done)
                    .onSubmit(submit)
            }
            FormActions(primary: "Create", isLoading: isSaving, submit: submit, cancel: cancel)
                .padding(.top, .space.withinGroup)
        }
        .onChange(of: draft.name) { errors[.name] = nil }
        .onChange(of: draft.repository) { errors[.repository] = nil }
        .onAppear { if focusesOnAppear { focused = .name } }
    }

    private func submit() {
        guard !isSaving else { return }  // Return while it saves
        isSaving = true
        Task {
            await create()
            isSaving = false
            // The first field in error takes the caret, and its sentence is announced.
            if let field = ServiceDraft.Field.allCases.first(where: { errors[$0] != nil }), let error = errors[field] {
                AccessibilityNotification.Announcement(error).post()
                focused = field
            }
        }
    }
}

/// The pilot's task card: the task's own title and notes, typed where they stand and kept as they are typed.
struct TaskCardFields: View {
    @Binding var title: String
    @Binding var notes: String
    var isNew = false  // a task just added: its empty title takes the caret
    @FocusState private var titleFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: .space100) {
            TextField("Title", text: $title, prompt: Text("New task").foregroundStyle(.text.placeholder))
                .textFieldStyle(.inline)
                .accessibilityLabel("Title")
                .textRole(.heading.small)
                .foregroundStyle(.text.primary)
                .focused($titleFocused)
            TextField(
                "Notes", text: $notes, prompt: Text("Notes").foregroundStyle(.text.placeholder), axis: .vertical
            )
            .textFieldStyle(.inline)
            .accessibilityLabel("Notes")
            .textRole(.subheadline.regular)
            .foregroundStyle(.text.secondary)
        }
        .onAppear { if isNew { titleFocused = true } }
    }
}
