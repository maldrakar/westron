// The check that names the state of #99 in the macOS render: an AppKit text field laid out at a height other than the
// one AppKit itself gives for it.
//
// On the CI runner the macOS render has, on some runs, drawn the text-field sheets otherwise than every other run of
// the same code. A probe there (run 44932481160) caught the state: SwiftUI laid out the AppKit `NSTextField` under a
// SwiftUI `TextField` 17 pt high while the field's own `intrinsicContentSize` and `cell.cellSize` said 16 (font
// .SFNS-Regular 13), and on another runner a field in Onest 13, whose line is 17, was laid out 16. Once in it, the
// process stays in it, in every theme. Its cause is not known; it has never shown on a local Mac.
//
// What AppKit gives as a field's height is its cell's size at the field's width, `cell.cellSize(forBounds:)` with the
// laid-out width and no limit on the height: for a one-line field that is also `cell.cellSize` and
// `intrinsicContentSize`; for a multi-line one, whose text wraps, it is the height of its lines at that width, where
// the other two give one line however many it wraps to (a field 244 pt wide with a 400 pt line is laid out 32 pt high
// for its two lines, and `cellSize` and `intrinsicContentSize` say 16). In a normal render the laid-out height is that
// height for every field the matrix draws, and for every one-line field it is also the intrinsic height (measured over
// a full macOS render, which counts each field once in each picture that draws it: 432 fields in the 40 text-field
// pictures of the run's 196, and 48 more in the 4 text-field pictures among the 28 drawn again at the end; one-line
// fields with text and empty with a prompt, `SecureField`, multi-line fields of one and two lines, at every size, in
// SF 11 and 13 and Onest 13). So every picture's view tree is walked after its layout, before its draw, and a field
// laid out at a height that differs from AppKit's by more than half a pixel (the grid SwiftUI places frames on) is a
// finding. Not checked: an `NSTextView`, of which the matrix has none. A multi-line field whose text runs past its
// `lineLimit` would be laid out shorter than its lines by design; the matrix has none, and one added would show here
// as a finding, to exempt by that rule.
//
// It only reads: no picture changes. Not compiled for iOS, where no such state has been seen.

import CoreGraphics
import Foundation

/// What the check found in one draw: how many AppKit text fields it compared, and a description of each one laid out
/// at a height other than AppKit's.
struct FieldHeightReport: Equatable {
    var checked = 0
    var findings: [String] = []

    /// The issue a picture records when the check found something: it names the state and #99, says which picture and
    /// how far into the run, and describes each field.
    func issue(file: String, picture: Int, seconds: TimeInterval) -> String {
        String(
            format: "%@: the render was in the state of #99: %d of %d AppKit text fields laid out at a height other "
                + "than AppKit's own for them (picture %d of the run, %.1f s into it). The picture is compared with its "
                + "references as usual, and a difference there may be this state, not the code: ", file,
            findings.count, checked, picture, seconds) + findings.joined(separator: "; ")
    }
}

#if os(macOS)
    import AppKit

    @MainActor
    enum FieldHeights {
        /// Differences up to half a pixel at the render's scale of 2 are SwiftUI's rounding to the pixel grid.
        static let tolerance: CGFloat = 0.25

        /// Every `NSTextField` in a view tree, `NSSecureTextField` included, in the order of the tree.
        static func fields(in view: NSView) -> [NSTextField] {
            ((view as? NSTextField).map { [$0] } ?? []) + view.subviews.flatMap { fields(in: $0) }
        }

        /// Compares each field's laid-out height with its cell's height at its width and, for a field that does not
        /// wrap, with its `intrinsicContentSize`.
        static func check(_ root: NSView) -> FieldHeightReport {
            var report = FieldHeightReport()
            for field in fields(in: root) {
                guard let cell = field.cell else { continue }
                report.checked += 1
                let height = field.frame.height
                let intrinsic = field.intrinsicContentSize.height
                let oneLine = !cell.wraps && intrinsic != NSView.noIntrinsicMetric
                if abs(height - lines(of: field).height) > tolerance || (oneLine && abs(height - intrinsic) > tolerance)
                {
                    report.findings.append(describe(field))
                }
            }
            return report
        }

        /// The size AppKit gives a field's cell at the field's laid-out width, with no limit on its height.
        static func lines(of field: NSTextField) -> CGSize {
            field.cell?.cellSize(
                forBounds: CGRect(x: 0, y: 0, width: field.frame.width, height: .greatestFiniteMagnitude)) ?? .zero
        }

        /// A field as the issue gives it: its frame in the window, the sizes AppKit gives for it, its font and text.
        static func describe(_ field: NSTextField) -> String {
            let frame = field.convert(field.bounds, to: nil)
            let font = field.font.map {
                String(
                    format: "%@ %g (ascender %g, descender %g, leading %g)", $0.fontName, $0.pointSize, $0.ascender,
                    $0.descender, $0.leading)
            }
            let placeholder = field.placeholderString ?? field.placeholderAttributedString?.string ?? ""
            return "\(type(of: field)) laid out \(size(frame.size)) at \(point(frame.origin)) in the window, its "
                + "intrinsicContentSize \(size(field.intrinsicContentSize)), cell.cellSize "
                + "\(size(field.cell?.cellSize ?? .zero)), at its width \(size(lines(of: field))), wraps "
                + "\(field.cell?.wraps ?? false), font \(font ?? "none"), text \"\(field.stringValue)\", placeholder "
                + "\"\(placeholder)\""
        }

        static func size(_ size: CGSize) -> String { String(format: "%.3f × %.3f", size.width, size.height) }
        static func point(_ point: CGPoint) -> String { String(format: "(%.3f, %.3f)", point.x, point.y) }
    }
#endif
