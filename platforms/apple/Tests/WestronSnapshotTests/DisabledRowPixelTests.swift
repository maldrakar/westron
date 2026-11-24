// A disabled ListRow dims what it holds once (spec/components/list-row, the contract's disabled), measured by the
// pixels of Core Animation's own renderer, the one the snapshot matrix draws with on macOS (SnapshotRenderer): the
// layers as the screen composites them, beside `ImageRenderer`'s measure in WestronUITests (ListRowTests), which
// misdraws system controls. The probe is the most opaque pixel on a transparent ground, in the control's place. macOS
// only, in every `swift test`, as ButtonFloatingPixelTests.
#if os(macOS)

    import AppKit
    import CoreGraphics
    import Foundation
    import SwiftUI
    import Testing
    import WestronUI

    @testable import WestronCatalog

    @Suite("A disabled row dims its content once, by its pixels", .enabled(if: snapshotOutput == nil), .serialized)
    @MainActor
    struct DisabledRowPixelTests {
        static let width: CGFloat = 320

        /// The most opaque pixel's alpha, 0 to 1, of `view` drawn at the window's top leading corner, `width` wide, in the
        /// columns from `minX` to `maxX`, in points.
        static func maxAlpha(_ view: some View, fromX minX: CGFloat = 0, toX maxX: CGFloat = width) async throws
            -> Double
        {
            let window = try SnapshotRenderer.show(
                view.frame(width: width).environment(\.colorScheme, .light)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading), dark: false)
            defer { SnapshotRenderer.hide(window) }
            await SnapshotRenderer.pause(0.3)
            let hosting = try #require(window.contentView)
            hosting.layoutSubtreeIfNeeded()
            hosting.displayIfNeeded()
            let image = try #require(try SnapshotRenderer.caRender(hosting, size: CatalogScene.windowSize))
            let context = try #require(SnapshotRenderer.context(width: image.width, height: image.height, alpha: true))
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            let data = try #require(context.data).assumingMemoryBound(to: UInt8.self)
            let scale = SnapshotRenderer.scale
            let first = Int(minX * scale)
            let last = min(image.width, Int((maxX * scale).rounded(.up)))
            // The row and the group stand in the top 100 points.
            let rows = min(image.height, Int(100 * scale))
            var most: UInt8 = 0
            for row in 0..<rows {
                for column in first..<last {
                    most = max(most, data[(row * image.width + column) * 4 + 3])
                }
            }
            return Double(most) / 255
        }

        /// Two alphas of the same drawing: within two 8-bit steps of rounding.
        static let tolerance = 2.0 / 255 + 0.005

        /// The reference is the same control disabled alone: dimmed once, by itself, the contract's opacity.disabled.
        @Test("a Checkbox at the start of a disabled row draws as a disabled Checkbox alone")
        func checkDimmedOnce() async throws {
            func check() -> some View {
                Toggle(isOn: .constant(false), accessibilityLabel: "Call the plumber").toggleStyle(.check)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            func row(disabled: Bool) -> some View {
                ListRow {
                    Text("Call the plumber")
                } leading: {
                    Toggle(isOn: .constant(false), accessibilityLabel: "Call the plumber").toggleStyle(.check)
                }
                .disabled(disabled)
            }
            let end = CGFloat.space150 + max(CGFloat.size.target.minimum, .size.control.m)
            let alone = try await Self.maxAlpha(check())
            let aloneDisabled = try await Self.maxAlpha(check().disabled(true))
            let inRow = try await Self.maxAlpha(row(disabled: false), toX: end)
            let inDisabledRow = try await Self.maxAlpha(row(disabled: true), toX: end)
            print(
                String(
                    format: "MEASURE pixels: check alone %.3f, alone disabled %.3f, in a row %.3f, in a disabled row "
                        + "%.3f", alone, aloneDisabled, inRow, inDisabledRow))
            #expect(alone > 0.9, "no check drawn: \(alone)")
            #expect(abs(inRow - alone) < Self.tolerance, "\(inRow) against \(alone)")
            #expect(abs(inDisabledRow - aloneDisabled) < Self.tolerance, "\(inDisabledRow) against \(aloneDisabled)")
        }

        /// The chevron's look follows its group's state, whatever the label: the references are the chevron after a
        /// text label disabled alone (enabled, whole) and in a disabled group (dimmed once, by itself).
        @Test("the Disclosure chevron in a disabled row is drawn as after a text label: whole, or dimmed once")
        func chevronDimmedOnce() async throws {
            func group(groupDisabled: Bool = false, @ViewBuilder _ label: () -> some View) -> some View {
                DisclosureGroup(isExpanded: .constant(false)) {
                    EmptyView()
                } label: {
                    label()
                }
                .disclosureGroupStyle(.chevron)
                .disabled(groupDisabled)
            }
            let cellStart = Self.width - CGFloat.space150 - CGFloat.size.target.minimum - 1
            let enabled = try await Self.maxAlpha(group { ListRow(action: {}) { Text("Work") } }, fromX: cellStart)
            let textDisabled = try await Self.maxAlpha(group { Text("Work").disabled(true) }, fromX: cellStart)
            let alone = try await Self.maxAlpha(group(groupDisabled: true) { Text("Work") }, fromX: cellStart)
            let rowDisabled = try await Self.maxAlpha(
                group { ListRow(action: {}) { Text("Work") }.disabled(true) }, fromX: cellStart)
            let groupDisabled = try await Self.maxAlpha(
                group(groupDisabled: true) { ListRow(action: {}) { Text("Work") } }, fromX: cellStart)
            print(
                String(
                    format: "MEASURE pixels: chevron enabled %.3f, after a disabled text label %.3f, a disabled "
                        + "group's after a text %.3f, in a disabled row %.3f, in a disabled group's row %.3f", enabled,
                    textDisabled, alone, rowDisabled, groupDisabled))
            #expect(enabled > 0.9, "no chevron drawn: \(enabled)")
            #expect(abs(rowDisabled - textDisabled) < Self.tolerance, "\(rowDisabled) against \(textDisabled)")
            #expect(abs(groupDisabled - alone) < Self.tolerance, "\(groupDisabled) against \(alone)")
        }
    }
#endif
