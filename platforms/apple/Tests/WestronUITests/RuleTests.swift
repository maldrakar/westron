import Foundation
import SwiftUI
import Testing

@testable import WestronUI

/// Rule against its contract, spec/components/rule/rule.spec.yaml: `stroke.thin` across its axis, the length it is
/// offered along it, and `horizontal` by default.
@Suite("Rule")
@MainActor
struct RuleTests {
    static let offered = CGSize(width: 240, height: 120)

    @Test("a horizontal rule spans the width it is offered and is stroke.thin tall")
    func horizontal() {
        #expect(fittingSize(Rule(axis: .horizontal), in: Self.offered) == CGSize(width: 240, height: .stroke.thin))
    }

    @Test("a vertical rule spans the height it is offered and is stroke.thin wide")
    func vertical() {
        #expect(fittingSize(Rule(axis: .vertical), in: Self.offered) == CGSize(width: .stroke.thin, height: 120))
    }

    @Test("the default axis is the contract's, horizontal")
    func defaultAxis() {
        #expect(Rule().axis == .horizontal)
        #expect(fittingSize(Rule(), in: Self.offered) == fittingSize(Rule(axis: .horizontal), in: Self.offered))
    }

    @Test("a vertical rule in a row that fixes its height is as tall as the row's text, and adds only its width")
    func inARow() {
        let text = Text("Left").textRole(.body.regular)
        let row = HStack(spacing: 0) {
            text
            Rule(axis: .vertical)
        }
        .fixedSize(horizontal: false, vertical: true)
        let alone = fittingSize(text, in: Self.offered)
        #expect(fittingSize(row, in: Self.offered) == CGSize(width: alone.width + .stroke.thin, height: alone.height))

        // The rule's own frame, where the row places it: as tall as the text, not its own ideal length.
        let placed = PlacedSize()
        let probed = HStack(spacing: 0) {
            text
            SizeProbe(placed: placed) { Rule(axis: .vertical) }
        }
        .fixedSize(horizontal: false, vertical: true)
        laidOut(probed, in: Self.offered)
        #expect(placed.size == CGSize(width: .stroke.thin, height: alone.height))
    }

    @Test("the default purpose is the contract's, separator")
    func defaultPurpose() {
        #expect(Rule().purpose == .separator)
        #expect(Rule(axis: .vertical).purpose == .separator)
    }

    @Test("an insertion rule is stroke.thick across its axis and spans the length it is offered")
    func insertion() {
        #expect(
            fittingSize(Rule(axis: .horizontal, purpose: .insertion), in: Self.offered)
                == CGSize(width: 240, height: .stroke.thick))
        #expect(
            fittingSize(Rule(axis: .vertical, purpose: .insertion), in: Self.offered)
                == CGSize(width: .stroke.thick, height: 120))
    }

    @Test("a labelled rule is a horizontal separator, by either initializer")
    func labelledShape() {
        let localized = Rule("WORK")
        let verbatim = Rule(String("Garden"))
        for rule in [localized, verbatim] {
            #expect(rule.axis == .horizontal && rule.purpose == .separator && rule.label != nil)
        }
        #expect(Rule().label == nil)
    }

    @Test("a labelled rule spans the width it is offered and is as tall as its label's line")
    func labelledSize() {
        let label = Text("WORK").textRole(.heading.overline)
        let height = fittingSize(label, in: Self.offered).height
        #expect(fittingSize(Rule("WORK"), in: Self.offered) == CGSize(width: 240, height: height))
    }

    @Test("a label longer than the rule truncates on one line rather than widen or wrap it")
    func longLabel() {
        let long = "HOUSEHOLD ERRANDS, REPAIRS AND EVERYTHING FOR THE GARDEN"
        let oneLine = fittingSize(Text("WORK").textRole(.heading.overline), in: Self.offered).height
        #expect(fittingSize(Rule(long), in: Self.offered) == CGSize(width: 240, height: oneLine))
    }
}

/// The size a `SizeProbe` was placed at.
final class PlacedSize: @unchecked Sendable {
    var size: CGSize?
}

/// A layout that passes everything to its one subview and records the bounds it places it in.
struct SizeProbe: Layout {
    let placed: PlacedSize

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        subviews.first?.sizeThatFits(proposal) ?? .zero
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        placed.size = bounds.size
        subviews.first?.place(at: bounds.origin, proposal: ProposedViewSize(bounds.size))
    }
}

/// Lays a view out in a host of the given size, off screen, so that its layouts place their subviews.
@MainActor
func laidOut<V: View>(_ view: V, in size: CGSize) {
    #if canImport(AppKit)
        let host = NSHostingView(rootView: view.frame(width: size.width, height: size.height, alignment: .topLeading))
        host.frame = CGRect(origin: .zero, size: size)
        host.layoutSubtreeIfNeeded()
    #else
        let host = UIHostingController(
            rootView: view.frame(width: size.width, height: size.height, alignment: .topLeading))
        // Off a window, a hosting controller measures but does not place its subviews.
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = host
        window.isHidden = false
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        window.isHidden = true
    #endif
}
