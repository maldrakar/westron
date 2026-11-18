import Foundation
import SwiftUI
import Testing

@testable import WestronUI

#if canImport(AppKit)
    import AppKit
#endif

/// The icons generated from spec/icons/icons.yaml: the names products store, and the SF Symbols they draw (decisions/0011).
@Suite("Icons")
struct IconTests {
    /// The names released so far, which products store: the pilot keeps a list's icon by its name. A released name is
    /// never renamed or removed, so each must still read as its icon; a new icon is added here when it is released.
    static let releasedNames = [
        "tray", "sun", "calendar", "week", "logbook", "trash", "briefcase", "house", "hourglass", "pen", "bag",
        "wrench",
        "book", "folder", "list", "bullets", "ellipsis", "plus", "check", "chevron", "grip", "magnifier", "microphone",
        "newWindow", "checkCircle", "divider", "flag", "hash", "note", "expand", "columns", "chevronLeft",
    ]

    @Test("every released name still reads as its icon")
    func releasedNamesRead() {
        for name in Self.releasedNames {
            #expect(Westron.Icon(rawValue: name)?.rawValue == name, "\(name)")
        }
    }

    @Test("every icon reads back from its raw value")
    func rawValuesRoundTrip() {
        #expect(Westron.Icon.allCases.count == 36)
        for icon in Westron.Icon.allCases {
            #expect(Westron.Icon(rawValue: icon.rawValue) == icon, "\(icon)")
        }
    }

    @Test("a name this version does not know reads as nil and draws the fallback, bullets")
    func unknownNames() {
        for name in ["no-such-icon", "", "sun.max", "Sun", "new-window"] {
            #expect(Westron.Icon(rawValue: name) == nil, "\(name)")
        }
        #expect(Westron.Icon.fallback == .bullets)
        #expect((Westron.Icon(rawValue: "no-such-icon") ?? .fallback) == .bullets)
    }

    @Test("every icon draws a symbol of its own")
    func distinctSymbols() {
        let symbols = Westron.Icon.allCases.map(\.systemName)
        #expect(Set(symbols).count == symbols.count)
        #expect(Westron.Icon.sun.systemName == "sun.max")
        #expect(Westron.Icon.newWindow.systemName == "macwindow.badge.plus")
    }

    @Test("an icon's image is its SF Symbol; a label takes the icon, hidden beside its title")
    @MainActor
    func adapters() {
        for icon in Westron.Icon.allCases {
            #expect(Image(icon) == Image(systemName: icon.systemName), "\(icon)")
        }
        // The icon's type is the hidden image: assistive technology reads the title alone (design-language/07, 08).
        let localized: Label<Text, ModifiedContent<Image, AccessibilityAttachmentModifier>> = Label(
            "Rename", icon: .pen)
        let verbatim: Label<Text, ModifiedContent<Image, AccessibilityAttachmentModifier>> = Label(
            String("Work"), icon: .folder)
        _ = (localized, verbatim)
    }

    @Test("Icon: without a label it is decorative; with one, the label is what it means")
    @MainActor
    func iconLabels() {
        let decorative = Icon(.tray)
        #expect(decorative.icon == .tray && decorative.label == nil)

        let localized = Icon(.sun, label: "Today")
        #expect(localized.icon == .sun && localized.label == Text("Today"))

        // A name the person gave is not looked up as a key: the verbatim initializer takes a String.
        let title = "Garden"
        let verbatim = Icon(.folder, label: title)
        #expect(verbatim.label == Text(verbatim: "Garden"))

        // A stored name that this version does not know draws the fallback.
        #expect(Icon(Westron.Icon(rawValue: "no-such-icon") ?? .fallback).icon == .bullets)
    }

    #if canImport(AppKit)
        /// A symbol that does not exist draws nothing and says nothing, so the system is asked for every one.
        @Test("every symbol exists on this Mac")
        func symbolsExist() {
            for icon in Westron.Icon.allCases {
                #expect(
                    NSImage(systemSymbolName: icon.systemName, accessibilityDescription: nil) != nil,
                    "\(icon): \(icon.systemName)")
            }
        }

        /// This Mac is newer than the minimum, so a symbol can exist here and not on iOS 17, macOS 14 or watchOS 10
        /// (decisions/0008). SF Symbols records the release that brought each symbol in `name_availability.plist`.
        @Test("every symbol is available on iOS 17, macOS 14 and watchOS 10")
        func symbolsAvailableOnTheMinimum() throws {
            let url = URL(
                fileURLWithPath:
                    "/System/Library/CoreServices/CoreGlyphs.bundle/Contents/Resources/name_availability.plist")
            let plist = try #require(NSDictionary(contentsOf: url))
            let symbols = try #require(plist["symbols"] as? [String: String])
            let releases = try #require(plist["year_to_release"] as? [String: [String: String]])
            let minimum = ["iOS": "17.0", "macOS": "14.0", "watchOS": "10.0"]
            for icon in Westron.Icon.allCases {
                let year = try #require(symbols[icon.systemName], "\(icon): \(icon.systemName) is not in SF Symbols")
                let release = try #require(releases[year], "\(icon): no release for \(year)")
                for (platform, version) in minimum {
                    let since = try #require(release[platform], "\(icon): no \(platform) release for \(year)")
                    #expect(
                        !Self.version(version).lexicographicallyPrecedes(Self.version(since)),
                        "\(icon): \(icon.systemName) arrived in \(platform) \(since)")
                }
            }
        }

        /// `"10.15"` → `[10, 15, 0]`.
        static func version(_ text: String) -> [Int] {
            (text.split(separator: ".").compactMap { Int($0) } + [0, 0, 0]).prefix(3).map { $0 }
        }
    #endif
}
