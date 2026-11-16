import SwiftUI
import WestronUI

extension CatalogEntry {
    /// The semantic colors on samples of different products: a task list, a table of deployments with their
    /// statuses, notices and buttons, in the catalog's theme. The owner approves the palette on this page and on the
    /// swatch pages (#10).
    static let colorInUse = CatalogEntry(id: "color-in-use", title: "Colors: in use", section: .foundations) {
        ColorInUsePage()
    }
}

/// Three samples built from semantic colors only, so that every color is seen against the colors it meets on a
/// screen. Each element names in a comment the tokens it shows.
private struct ColorInUsePage: View {
    var body: some View {
        TokenPage(
            title: "Colors in use",
            summary: "An everyday app and a technical one, drawn with the semantic colors in this screenshot's theme."
        ) {
            #if os(macOS)
                HStack(alignment: .top, spacing: .space150) {
                    TasksSample()
                        .frame(width: Metrics.tasksWidth)
                    VStack(alignment: .leading, spacing: .space150) {
                        DeploymentsSample()
                        NoticesSample()
                    }
                }
            #else
                VStack(alignment: .leading, spacing: .space150) {
                    TasksSample()
                    DeploymentsSample()
                    NoticesSample()
                }
            #endif
        }
    }
}

/// A raised card: background.surface with a soft shadow, and in high contrast a border.default outline, as every
/// raised surface gets one there.
private struct Card<Content: View>: View {
    @Environment(\.colorSchemeContrast) private var contrast
    @ViewBuilder let content: Content

    var body: some View {
        content
            .background(.background.surface, in: RoundedRectangle(cornerRadius: .radius.card))
            .clipShape(RoundedRectangle(cornerRadius: .radius.card))
            .shadow(.raised)
            .overlay {
                if contrast == .increased {
                    RoundedRectangle(cornerRadius: .radius.card)
                        .strokeBorder(.border.default, lineWidth: .stroke.thin)
                }
            }
    }
}

/// A task list: its title, the primary action, a search field and four tasks, one late, one selected, one done.
private struct TasksSample: View {
    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: .space100) {
                HStack(alignment: .center, spacing: .space100) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Inbox")
                            .textRole(.heading.medium)
                            .foregroundStyle(.text.primary)
                        Text("4 open, 1 done")
                            .textRole(.footnote.regular)
                            .foregroundStyle(.text.secondary)
                    }
                    Spacer(minLength: .space100)
                    FilledButton(title: "Task", icon: .plus, fill: .background.accent, label: .text.onAccent)
                }
                // text.placeholder in a field ringed in border.strong.
                Label("Find a task or a tag", icon: .magnifier)
                    .textRole(.footnote.regular)
                    .foregroundStyle(.text.placeholder)
                    .padding(.horizontal, .space100)
                    .frame(maxWidth: .infinity, minHeight: Metrics.control, alignment: .leading)
                    .overlay {
                        RoundedRectangle(cornerRadius: .radius.control)
                            .strokeBorder(.border.strong, lineWidth: .stroke.thin)
                    }
                VStack(spacing: 0) {
                    TaskRow(title: "Order the backsplash tiles") {
                        // status.danger.text: a missed deadline.
                        Label("Yesterday", icon: .flag)
                            .foregroundStyle(.status.danger.text)
                        Tag(title: "repair", category: .orange)
                    }
                    Rule()
                    // background.selected under text.primary and text.secondary.
                    TaskRow(title: "Call the electrician", selected: true) {
                        Text("14:00")
                            .foregroundStyle(.text.secondary)
                        Tag(title: "repair", category: .orange)
                    }
                    Rule()
                    TaskRow(title: "Plant garlic") {
                        Tag(title: "garden", category: .green)
                    }
                    Rule()
                    TaskRow(title: "Proofread chapter two", done: true) {
                        Tag(title: "book", category: .violet)
                    }
                }
            }
            .padding(.space150)
        }
    }
}

/// A task: its check, its title and a line of meta under it.
private struct TaskRow<Meta: View>: View {
    let title: String
    var selected = false
    var done = false
    @ViewBuilder let meta: Meta

    var body: some View {
        HStack(alignment: .top, spacing: .space100) {
            Check(done: done)
            VStack(alignment: .leading, spacing: .space25) {
                // A done title: text.secondary, struck through in icon.tertiary.
                Text(title)
                    .textRole(.body.regular)
                    .foregroundStyle(done ? Westron.Color.text.secondary : .text.primary)
                    .strikethrough(done, color: Color(.icon.tertiary))
                HStack(spacing: .space100) {
                    meta
                }
                .textRole(.footnote.regular)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, .space75)
        .padding(.vertical, .space50)
        .background(selected ? Color(.background.selected) : .clear, in: RoundedRectangle(cornerRadius: .radius.row))
    }
}

/// A task's check: open, a ring in border.strong; done, a disc in background.accent with its mark in text.on-accent.
private struct Check: View {
    let done: Bool

    var body: some View {
        ZStack {
            if done {
                Circle()
                    .fill(.background.accent)
                Image(Westron.Icon.check)
                    .font(Font(.caption.medium).weight(.bold))
                    .foregroundStyle(.text.onAccent)
            } else {
                Circle()
                    .strokeBorder(.border.strong, lineWidth: .stroke.regular)
            }
        }
        .frame(width: Metrics.check, height: Metrics.check)
    }
}

/// A tag: category.text on category.background.
private struct Tag: View {
    let title: String
    let category: Westron.Category

    var body: some View {
        Text(title)
            .textRole(.caption.medium)
            .foregroundStyle(category.text)
            .padding(.horizontal, .space75)
            .frame(minHeight: Metrics.tag)
            .background(category.background, in: Capsule())
    }
}

/// A separator in border.default.
private struct Rule: View {
    var body: some View {
        Rectangle()
            .fill(.border.default)
            .frame(height: .stroke.thin)
    }
}

/// A table of deployments: a header on background.sunken, monospaced names, a status badge per row, commits in
/// text.accent. At an accessibility size the three columns do not fit across, and each deployment becomes a stack.
private struct DeploymentsSample: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let rows: [(service: String, status: StatusSample, commit: String)] = [
        ("api-gateway", .success, "a1f3c9e"),
        ("billing-worker", .info, "7be02d1"),
        ("search-indexer", .warning, "c4d8e17"),
        ("auth-service", .danger, "0e9a6b4"),
        ("notifications", .neutral, "91cc3e0"),
    ]

    var body: some View {
        Card {
            if dynamicTypeSize.isAccessibilitySize {
                stacks
            } else {
                table
            }
        }
    }

    private var stacks: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Service, status, commit")
                .textRole(.caption.medium)
                .foregroundStyle(.text.secondary)
                .padding(.horizontal, .space150)
                .padding(.vertical, .space75)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.background.sunken)
            ForEach(rows, id: \.service) { row in
                Rule()
                VStack(alignment: .leading, spacing: .space50) {
                    Text(row.service)
                        .foregroundStyle(.text.primary)
                    StatusBadge(status: row.status)
                    Text(row.commit)
                        .foregroundStyle(.text.accent)
                }
                .textRole(.code.regular)
                .padding(.horizontal, .space150)
                .padding(.vertical, .space75)
            }
        }
    }

    private var table: some View {
        Grid(alignment: .leading, horizontalSpacing: .space150, verticalSpacing: 0) {
            GridRow {
                Text("Service")
                Text("Status")
                Text("Commit")
            }
            .textRole(.caption.medium)
            .foregroundStyle(.text.secondary)
            .frame(minHeight: Metrics.header)
            ForEach(rows, id: \.service) { row in
                Rule()
                    .gridCellColumns(3)
                GridRow {
                    Text(row.service)
                        .foregroundStyle(.text.primary)
                    StatusBadge(status: row.status)
                    Text(row.commit)
                        .foregroundStyle(.text.accent)
                }
                .textRole(.code.regular)
                .frame(minHeight: Metrics.tableRow)
            }
        }
        .padding(.horizontal, .space150)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .top) {
            Rectangle()
                .fill(.background.sunken)
                .frame(height: Metrics.header)
        }
    }
}

/// Two notices on their status backgrounds, then the buttons: the accent, a secondary one, a destructive one, a link.
private struct NoticesSample: View {
    var body: some View {
        VStack(alignment: .leading, spacing: .space100) {
            Notice(status: .warning, title: "Storage almost full", detail: "92% of the attachment space is used.")
            Notice(status: .danger, title: "Report not sent", detail: "The webhook returned 404. Check its address.")
            HStack(spacing: .space100) {
                FilledButton(title: "Save", icon: nil, fill: .background.accent, label: .text.onAccent)
                // A secondary button: text.primary on background.surface, ringed in border.strong.
                Text("Cancel")
                    .textRole(.footnote.strong)
                    .foregroundStyle(.text.primary)
                    .padding(.horizontal, .space150)
                    .frame(minHeight: Metrics.control)
                    .background(.background.surface, in: RoundedRectangle(cornerRadius: .radius.control))
                    .overlay {
                        RoundedRectangle(cornerRadius: .radius.control)
                            .strokeBorder(.border.strong, lineWidth: .stroke.thin)
                    }
                FilledButton(title: "Delete", icon: .trash, fill: .status.danger.fill, label: .status.danger.onFill)
                Text("Webhook help")
                    .textRole(.footnote.strong)
                    .underline()
                    .foregroundStyle(.text.accent)
            }
        }
    }
}

/// A notice: the status icon, a title in status.<name>.text and a line in text.secondary on the status background.
private struct Notice: View {
    let status: StatusSample
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: .space100) {
            Image(status.icon)
                .foregroundStyle(status.iconColor)
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .textRole(.footnote.strong)
                    .foregroundStyle(status.text)
                Text(detail)
                    .textRole(.footnote.regular)
                    .foregroundStyle(.text.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.space100)
        .background(status.background, in: RoundedRectangle(cornerRadius: .radius.control))
    }
}

/// A button with a solid fill and its label.
private struct FilledButton: View {
    let title: String
    let icon: Westron.Icon?
    let fill: Westron.Color
    let label: Westron.Color

    var body: some View {
        HStack(spacing: .space50) {
            if let icon { Image(icon) }
            Text(title)
        }
        .textRole(.footnote.strong)
        .foregroundStyle(label)
        .padding(.horizontal, .space150)
        .frame(minHeight: Metrics.control)
        .background(fill, in: RoundedRectangle(cornerRadius: .radius.control))
    }
}

/// The sizes of the samples on a Mac and on a phone. A control's or a row's height is its least: it grows with its
/// text at a large Dynamic Type size, so the text is never clipped.
private enum Metrics {
    #if os(macOS)
        static let tasksWidth: CGFloat = 300
        static let control: CGFloat = 28
        static let check: CGFloat = 16
        static let tag: CGFloat = 18
        static let header: CGFloat = 24
        static let tableRow: CGFloat = 28
    #else
        static let control: CGFloat = 36
        static let check: CGFloat = 22
        static let tag: CGFloat = 22
        static let header: CGFloat = 28
        static let tableRow: CGFloat = 32
    #endif
}
