import SwiftUI
import WestronUI

extension CatalogEntry {
    /// The semantic colors where the pilot draws them: its sidebar and a list screen, in the catalog's theme. The owner
    /// approves the palette on this page and on the swatch pages (#10).
    static let colorInUse = CatalogEntry(id: "color-in-use", title: "Colors: in use", section: .foundations) {
        ColorInUsePage()
    }
}

/// A sidebar and a list screen after the pilot's, built from semantic colors only, so that every color is seen
/// against the colors it meets on a screen. Each element names in a comment the tokens it shows.
private struct ColorInUsePage: View {
    var body: some View {
        TokenPage(
            title: "Colors in use",
            summary: "The pilot's sidebar and list screen drawn with the semantic colors, in this screenshot's theme. "
                + "The list's color is amber."
        ) {
            #if os(macOS)
                HStack(alignment: .top, spacing: .space150) {
                    SidebarSample()
                        .frame(width: Metrics.sidebarWidth)
                    ListSample()
                }
            #else
                VStack(alignment: .leading, spacing: .space150) {
                    SidebarSample()
                    ListSample()
                }
            #endif
        }
    }
}

/// The sidebar: an area's caption, a list, the selected list in edit mode, a list being renamed, the edit bar.
private struct SidebarSample: View {
    var body: some View {
        VStack(alignment: .leading, spacing: .space25) {
            // text.secondary: the area caption, which the pilot draws in a color too light for words.
            Text("Home")
                .font(.headingOverline)
                .textCase(.uppercase)
                .foregroundStyle(.textSecondary)
                .padding(.horizontal, .space100)
                .padding(.bottom, .space25)
            ListRow(category: .blue, icon: .tray, title: "Inbox", count: "12")
            // background.selected under text.primary, text.secondary and the grip in icon.tertiary.
            ListRow(category: .amber, icon: .bag, title: "Groceries", count: "3", selected: true)
            RenameRow()
            // border.default: the rule above the edit bar.
            Rectangle()
                .fill(.borderDefault)
                .frame(height: .strokeThin)
                .padding(.vertical, .space50)
            // text.accent: the edit bar's actions.
            HStack(spacing: .space200) {
                Label("List", icon: .plus)
                Label("Area", icon: .plus)
            }
            .font(.footnoteStrong)
            .foregroundStyle(.textAccent)
            .padding(.horizontal, .space100)
        }
        .padding(.space100)
        .background(.backgroundSidebar, in: RoundedRectangle(cornerRadius: .radius150))
    }
}

/// A list in the sidebar: its tile, its title and the count of its open tasks.
private struct ListRow: View {
    let category: Westron.Category
    let icon: Westron.Icon
    let title: String
    let count: String
    var selected = false

    var body: some View {
        HStack(spacing: .space100) {
            Tile(category: category, icon: icon, side: Metrics.tile)
            Text(title)
                .font(selected ? .bodyStrong : .bodyRegular)
                .foregroundStyle(.textPrimary)
            Spacer(minLength: .space50)
            Text(count)
                .font(.footnoteRegular)
                .foregroundStyle(.textSecondary)
            if selected {
                Image(Westron.Icon.grip)
                    .font(.bodyRegular)
                    .foregroundStyle(.iconTertiary)
            }
        }
        .padding(.horizontal, .space100)
        .frame(height: Metrics.row)
        .background(selected ? Color.backgroundSelected : .clear, in: RoundedRectangle(cornerRadius: .radius100))
    }
}

/// A list being renamed: text.placeholder in a field on background.surface, ringed in border.accent.
private struct RenameRow: View {
    var body: some View {
        HStack(spacing: .space100) {
            Tile(category: .green, icon: .house, side: Metrics.tile)
            Text("Title")
                .font(.bodyRegular)
                .foregroundStyle(.textPlaceholder)
                .padding(.horizontal, .space100)
                .frame(maxWidth: .infinity, minHeight: Metrics.field, alignment: .leading)
                .background(.backgroundSurface, in: RoundedRectangle(cornerRadius: .radius100))
                .overlay {
                    RoundedRectangle(cornerRadius: .radius100)
                        .strokeBorder(.borderAccent, lineWidth: .strokeThick)
                }
        }
        .padding(.horizontal, .space100)
        .frame(height: Metrics.row)
    }
}

/// The list screen: its header, its tags, a block of tasks, an open task, a task swiped to delete, the add button.
private struct ListSample: View {
    private let list = Westron.Category.amber

    var body: some View {
        VStack(alignment: .leading, spacing: .space100) {
            header
            tags
            block
            TaskRow(category: list, title: "Oat milk") {
                // text.danger: a due deadline.
                Label("Today", icon: .flag)
                    .font(.footnoteRegular)
                    .foregroundStyle(.textDanger)
            }
            // background.highlight: under a task that has just been dropped.
            TaskRow(category: list, title: "Bread") {
                Text("Bakery")
                    .font(.footnoteRegular)
                    .foregroundStyle(.textSecondary)
            }
            .background(.backgroundHighlight, in: RoundedRectangle(cornerRadius: .radius150))
            TaskRow(category: list, title: "Coffee beans", done: true) {
                EmptyView()
            }
            OpenCard(category: list)
            SwipedRow(category: list)
            addRow
        }
        .padding(.space150)
        .overlay {
            // border.default: the frame that sets the sample apart from the page, both on background.canvas.
            RoundedRectangle(cornerRadius: .radius150)
                .strokeBorder(.borderDefault, lineWidth: .strokeThin)
        }
    }

    /// The list's tile, its title in text.primary, the counts in text.secondary and a glass button.
    private var header: some View {
        HStack(spacing: .space150) {
            Tile(category: list, icon: .bag, side: Metrics.headerTile)
            VStack(alignment: .leading, spacing: 0) {
                Text("Groceries")
                    .font(.headingMedium)
                    .foregroundStyle(.textPrimary)
                Text("3 open, 1 done")
                    .font(.footnoteRegular)
                    .foregroundStyle(.textSecondary)
            }
            Spacer(minLength: 0)
            GlassButton()
        }
    }

    /// A lit tag chip in the list's fill and an unlit one on background.muted.
    private var tags: some View {
        HStack(spacing: .space75) {
            Chip(title: "weekly", lit: list)
            Chip(title: "market", lit: nil)
        }
    }

    /// A block's title in the list's text color, its date, and the rule under it in border.default.
    private var block: some View {
        VStack(alignment: .leading, spacing: .space50) {
            HStack(alignment: .firstTextBaseline, spacing: .space100) {
                Text("This week")
                    .font(.headingSmall)
                    .foregroundStyle(.categoryText(list))
                Text("Nov 10–16")
                    .font(.footnoteRegular)
                    .foregroundStyle(.textSecondary)
            }
            Rectangle()
                .fill(.borderDefault)
                .frame(height: .strokeThin)
        }
    }

    /// The add row in text.secondary and the floating add button: text.on-accent on background.accent.
    private var addRow: some View {
        HStack(spacing: .space100) {
            Label("Add task", icon: .plus)
                .font(.footnoteMedium)
                .foregroundStyle(.textSecondary)
            Spacer(minLength: 0)
            Image(Westron.Icon.plus)
                .font(.headingSmall)
                .foregroundStyle(.textOnAccent)
                .frame(width: Metrics.floating, height: Metrics.floating)
                .background(.backgroundAccent, in: Circle())
        }
    }
}

/// A task: its check, its title, and its meta beside the title.
private struct TaskRow<Meta: View>: View {
    let category: Westron.Category
    let title: String
    var done = false
    @ViewBuilder let meta: Meta

    var body: some View {
        HStack(spacing: .space100) {
            Check(category: category, done: done)
            // A done title: text.secondary, struck through in icon.tertiary.
            Text(title)
                .font(.bodyRegular)
                .foregroundStyle(done ? Color.textSecondary : .textPrimary)
                .strikethrough(done, color: .iconTertiary)
            Spacer(minLength: .space50)
            meta
        }
        .padding(.horizontal, .space75)
        .frame(minHeight: Metrics.row)
    }
}

/// An open task on background.surface with the raised shadow: a placeholder for the notes and two pills on
/// background.muted, one of them a due deadline in text.danger.
private struct OpenCard: View {
    let category: Westron.Category

    var body: some View {
        VStack(alignment: .leading, spacing: .space50) {
            HStack(spacing: .space100) {
                Check(category: category, done: false)
                Text("Apples")
                    .font(.bodyStrong)
                    .foregroundStyle(.textPrimary)
            }
            Text("Notes")
                .font(.footnoteRegular)
                .foregroundStyle(.textPlaceholder)
                .padding(.leading, Metrics.check + .space100)
            HStack(spacing: .space75) {
                Pill(icon: .sun, title: "Today", style: .textPrimary)
                Pill(icon: .flag, title: "Fri", style: .textDanger)
            }
            .padding(.leading, Metrics.check + .space100)
        }
        .padding(.space100)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.backgroundSurface, in: RoundedRectangle(cornerRadius: .radius175))
        .shadow(.raised)
    }
}

/// A task swiped open: text.on-danger on background.danger.
private struct SwipedRow: View {
    let category: Westron.Category

    var body: some View {
        HStack(spacing: .space75) {
            TaskRow(category: category, title: "Pears") {
                EmptyView()
            }
            Text("Delete")
                .font(.footnoteStrong)
                .foregroundStyle(.textOnDanger)
                .frame(width: Metrics.deleteWidth, height: Metrics.row)
                .background(.backgroundDanger, in: RoundedRectangle(cornerRadius: .radius150))
        }
    }
}

/// A list's tile: its glyph in category.text on category.background.
private struct Tile: View {
    let category: Westron.Category
    let icon: Westron.Icon
    let side: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: side > Metrics.tile ? .radius125 : .radius100)
            .fill(.categoryBackground(category))
            .overlay {
                Image(icon)
                    .font(side > Metrics.tile ? .headingSmall : .footnoteMedium)
                    .foregroundStyle(.categoryText(category))
            }
            .frame(width: side, height: side)
    }
}

/// A task's check: open, a ring in category.border; done, a disc in category.fill with its mark in category.on-fill.
private struct Check: View {
    let category: Westron.Category
    let done: Bool

    var body: some View {
        ZStack {
            if done {
                Circle()
                    .fill(.categoryFill(category))
                Image(Westron.Icon.check)
                    .font(.captionMedium.weight(.bold))
                    .foregroundStyle(.categoryOnFill(category))
            } else {
                Circle()
                    .strokeBorder(.categoryBorder(category), lineWidth: .strokeRegular)
            }
        }
        .frame(width: Metrics.check, height: Metrics.check)
    }
}

/// A tag chip. Lit, its text is category.on-fill on category.fill; unlit, text.primary with the hash in
/// text.secondary on background.muted. The lit chip's contrast is the chip's to solve (#32).
private struct Chip: View {
    let title: String
    let lit: Westron.Category?

    var body: some View {
        HStack(spacing: .space50) {
            Image(Westron.Icon.hash)
                .foregroundStyle(lit.map { Color.categoryOnFill($0) } ?? .textSecondary)
            Text(title)
                .foregroundStyle(lit.map { Color.categoryOnFill($0) } ?? .textPrimary)
        }
        .font(.footnoteStrong)
        .padding(.horizontal, .space125)
        .frame(height: Metrics.chip)
        .background(lit.map { Color.categoryFill($0) } ?? .backgroundMuted, in: Capsule())
    }
}

/// A pill on an open task: a glyph and a word on background.muted.
private struct Pill: View {
    let icon: Westron.Icon
    let title: String
    let style: Color

    var body: some View {
        Label(title, icon: icon)
            .font(.footnoteMedium)
            .foregroundStyle(style)
            .padding(.horizontal, .space100)
            .frame(height: Metrics.chip)
            .background(.backgroundMuted, in: Capsule())
    }
}

/// The glass "…" button: text.primary on background.glass, ringed by border.glass.
private struct GlassButton: View {
    var body: some View {
        Image(Westron.Icon.ellipsis)
            .font(.bodyStrong)
            .foregroundStyle(.textPrimary)
            .frame(width: Metrics.glass, height: Metrics.glass)
            .background(.backgroundGlass, in: Circle())
            .overlay {
                Circle()
                    .strokeBorder(.borderGlass, lineWidth: .strokeHairline)
            }
    }
}

/// The sizes of the sample, the pilot's on a phone and on a Mac (research_notes/pilot-inventory.md, section 4).
private enum Metrics {
    #if os(macOS)
        static let sidebarWidth: CGFloat = 230
        static let row: CGFloat = 28
        static let field: CGFloat = 22
        static let tile: CGFloat = 20
        static let headerTile: CGFloat = 32
        static let check: CGFloat = 16
        static let chip: CGFloat = 22
        static let glass: CGFloat = 28
        static let floating: CGFloat = 30
        static let deleteWidth: CGFloat = 64
    #else
        static let row: CGFloat = 38
        static let field: CGFloat = 30
        static let tile: CGFloat = 28
        static let headerTile: CGFloat = 38
        static let check: CGFloat = 22
        static let chip: CGFloat = 28
        static let glass: CGFloat = 36
        static let floating: CGFloat = 44
        static let deleteWidth: CGFloat = 78
    #endif
}
