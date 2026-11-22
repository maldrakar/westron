import Foundation
import SwiftUI
import Testing

@testable import WestronUI

#if canImport(AppKit)
    import AppKit
    private typealias PlatformField = NSTextField
    private typealias PlatformView = NSView
#else
    import UIKit
    private typealias PlatformField = UITextField
    private typealias PlatformView = UIView
#endif

/// A field whose glyphs a product changes while the person types, such as a glyph shown only while the field is empty,
/// keeps the same system field and its focus (the contract's `platforms.apple`; decisions/0003, second revision). A
/// style that drew the field in one view without glyphs and in another with them made SwiftUI build a new system field
/// when the first glyph came or the last went, and the person lost the field mid-word (the review of #115).
@Suite("TextField glyphs keep the field")
@MainActor
struct TextFieldGlyphIdentityTests {
    struct Glyphs: Sendable, CustomTestStringConvertible {
        var leading: Westron.Icon?
        var trailing: Westron.Icon?

        static let none = Glyphs()
        static let leading = Glyphs(leading: .magnifier)
        static let both = Glyphs(leading: .magnifier, trailing: .hash)

        var testDescription: String {
            switch (leading, trailing) {
            case (nil, nil): "none"
            case (_, nil): "leading"
            case (nil, _): "trailing"
            default: "both"
            }
        }
    }

    @Test(
        "the field and its focus stay when glyphs come or go",
        arguments: [
            (Glyphs.none, Glyphs.leading), (.leading, .none), (.none, .both), (.both, .none), (.leading, .both),
        ])
    func fieldStays(from: Glyphs, to: Glyphs) throws {
        let model = Model(glyphs: from)
        let host = Host(Field(model: model))
        defer { host.close() }
        let before = try #require(host.fields.first, "no system field")
        #expect(host.fields.count == 1)
        host.focus(before)
        #expect(host.isFocused(before), "the field took no focus before the change")
        model.glyphs = to
        host.settle()
        let after = try #require(host.fields.first, "no system field after the change")
        #expect(after === before, "a new system field after \(from.testDescription) → \(to.testDescription)")
        #expect(host.isFocused(after), "the field lost its focus after \(from.testDescription) → \(to.testDescription)")
    }

    @Test("the first layout leaves a glyph its room: the field's text never starts under the glyph")
    func firstLayout() throws {
        let host = Host(Field(model: Model(glyphs: .leading)), settles: false)
        defer { host.close() }
        let field = try #require(host.fields.first, "no system field")
        // One layout pass, before the run loop has turned: the glyph and its gap, at least 17 + 8 pt, are already at
        // the field's start, inside the padding of 15.
        let frame = field.convert(field.bounds, to: host.root)
        let metrics = TextFieldMetrics(variant: .framed, size: .m, axis: .horizontal)
        let padding = metrics.paddingHorizontal.map(CGFloat.init) ?? .zero
        #expect(frame.minX > padding + CGFloat(metrics.gap) + 10, "\(frame) on the first layout")
    }
}

@MainActor
private final class Model: ObservableObject {
    @Published var glyphs: TextFieldGlyphIdentityTests.Glyphs

    init(glyphs: TextFieldGlyphIdentityTests.Glyphs) {
        self.glyphs = glyphs
    }
}

private struct Field: View {
    @ObservedObject var model: Model
    @State private var text = "Groceries"

    var body: some View {
        TextField("Search", text: $text)
            .textFieldStyle(.framed, size: .m, leadingIcon: model.glyphs.leading, trailingIcon: model.glyphs.trailing)
            .frame(width: 300)
    }
}

/// A key window holding a view, and the system fields in it.
@MainActor
private final class Host {
    #if canImport(AppKit)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 120), styleMask: [.titled], backing: .buffered,
            defer: false)
    #else
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 120))
    #endif
    let root: PlatformView

    init(_ view: some View, settles: Bool = true) {
        #if canImport(AppKit)
            let hosting = NSHostingView(rootView: view)
            window.contentView = hosting
            window.makeKeyAndOrderFront(nil)
            root = hosting
        #else
            let controller = UIHostingController(rootView: view)
            window.rootViewController = controller
            window.makeKeyAndVisible()
            root = controller.view
        #endif
        if settles {
            settle()
        } else {
            layOut()
        }
    }

    func layOut() {
        #if canImport(AppKit)
            root.layoutSubtreeIfNeeded()
        #else
            window.layoutIfNeeded()
        #endif
    }

    func settle() {
        for _ in 0..<5 {
            layOut()
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
    }

    var fields: [PlatformField] { Self.fields(in: root) }

    private static func fields(in view: PlatformView) -> [PlatformField] {
        (view as? PlatformField).map { [$0] } ?? view.subviews.flatMap { fields(in: $0) }
    }

    func focus(_ field: PlatformField) {
        #if canImport(AppKit)
            window.makeFirstResponder(field)
        #else
            field.becomeFirstResponder()
        #endif
        settle()
    }

    /// On macOS a field being edited hands its keys to the window's field editor, whose delegate it is.
    func isFocused(_ field: PlatformField) -> Bool {
        #if canImport(AppKit)
            ((window.firstResponder as? NSTextView)?.delegate as AnyObject?) === field
        #else
            field.isFirstResponder
        #endif
    }

    func close() {
        #if canImport(AppKit)
            window.orderOut(nil)
        #else
            window.isHidden = true
        #endif
    }
}
