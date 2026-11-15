// Generated from spec/icons/icons.yaml by `tools/westron generate`. Do not edit: change the registry and generate again
// (decisions/0011).
//
// The SF Symbol of every westron icon. `Image(_:)` and `Label(_:icon:)` in TokenAdapters.swift draw it.

import WestronTokens

extension Westron.Icon {
    /// The name of the SF Symbol the icon draws, for the SwiftUI calls that take `systemImage:`, such as
    /// `Button(_:systemImage:action:)`. Each symbol exists on iOS 17, macOS 14 and watchOS 10 (decisions/0011).
    public var systemName: String {
        switch self {
        case .tray: "tray"
        case .sun: "sun.max"
        case .calendar: "calendar"
        case .week: "calendar.badge.clock"
        case .logbook: "text.book.closed"
        case .trash: "trash"
        case .briefcase: "briefcase"
        case .house: "house"
        case .hourglass: "hourglass"
        case .pen: "pencil"
        case .bag: "bag"
        case .wrench: "wrench"
        case .book: "book"
        case .folder: "folder"
        case .list: "checklist"
        case .bullets: "list.bullet"
        case .ellipsis: "ellipsis"
        case .plus: "plus"
        case .check: "checkmark"
        case .chevron: "chevron.down"
        case .grip: "line.3.horizontal"
        case .magnifier: "magnifyingglass"
        case .microphone: "mic"
        case .newWindow: "macwindow.badge.plus"
        case .checkCircle: "checkmark.circle"
        case .divider: "rectangle.split.1x2"
        case .flag: "flag"
        case .hash: "number"
        case .note: "note.text"
        case .expand: "arrow.up.left.and.arrow.down.right"
        case .columns: "rectangle.split.3x1"
        case .chevronLeft: "chevron.left"
        }
    }
}
