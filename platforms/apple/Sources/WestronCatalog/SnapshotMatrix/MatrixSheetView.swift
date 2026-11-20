import SwiftUI
import WestronUI

#if os(macOS)
    import AppKit
#elseif os(iOS)
    import UIKit
#endif

/// One sheet of a component's snapshot matrix: a title with the values the sheet fixes, the column option's values
/// across, and a row per state, rest first, or per value of the row option (`ComponentMatrix.rowOption`). Each cell is
/// the real component drawn by its `<Component>MatrixCell`, or, on a supplement's sheet, by the supplement's cell; such
/// a sheet is marked "Not a contract option".
///
/// The sheet is laid out to fit one screenshot with nothing cut off: on macOS the state names are a column of their
/// own, in the catalog's wide window; on an iPhone in portrait each state name is a line above its row, so the cells
/// have the full width. Only the cells follow the text size of the capture: the sheet's own text, its title, notes and
/// the names of columns and rows, stays at the default size, so that the room goes to the component and the sheet
/// says so. Core Animation is frozen in the sheet's window (`FrozenAnimations`), so that a loading indicator stands
/// still and two captures compare pixel for pixel.
struct MatrixSheetView: View {
    let matrix: ComponentMatrix
    let sheet: ComponentMatrix.Sheet

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.matrixSheetFrame) private var reportFrame

    var body: some View {
        VStack(alignment: .leading, spacing: SampleMetrics.pagePadding) {
            header
                .dynamicTypeSize(Self.ownTextSize)
            Grid(alignment: .leading, horizontalSpacing: .space150, verticalSpacing: .space100) {
                GridRow {
                    #if os(macOS)
                        Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                    #endif
                    ForEach(sheet.columns, id: \.self) { column in
                        TokenName(column)
                            .dynamicTypeSize(Self.ownTextSize)
                    }
                }
                ForEach(matrix.rows(of: sheet), id: \.self) { row in
                    #if os(macOS)
                        GridRow {
                            TokenDetail(row ?? "rest")
                                .dynamicTypeSize(Self.ownTextSize)
                            cells(row)
                        }
                    #else
                        GridRow {
                            TokenDetail(row ?? "rest")
                                .dynamicTypeSize(Self.ownTextSize)
                                .gridCellColumns(sheet.columns.count)
                        }
                        GridRow { cells(row) }
                    #endif
                }
            }
        }
        .padding(SampleMetrics.pagePadding)
        // The sheet's content, below the title bar and clear of the window's rounded corners: the macOS capture cuts
        // its picture around it, with a margin.
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(CatalogAccessibilityID.matrixSheet)
        // The in-process snapshot tests (platforms/apple/Tests/WestronSnapshotTests) cut their picture to the same
        // frame; they have no accessibility query to find it.
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            reportFrame?(frame)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.background.canvas)
        .background(FrozenAnimations())
    }

    /// The text size of the sheet's own text, whatever the capture's.
    private static let ownTextSize = DynamicTypeSize.large

    private var header: some View {
        VStack(alignment: .leading, spacing: .space25) {
            if matrix.supplement != nil {
                NotContractOptionMark()
            }
            Text("\(matrix.component) · \(matrix.title(of: sheet))")
                .textRole(.heading.small)
                .foregroundStyle(.text.primary)
            if let part = matrix.partTitle(of: sheet) {
                // A part is taken where the cells grow so large that a sheet does not fit: it says what it holds and
                // leaves the notes to the whole sheet, so that the room goes to the cells.
                note("\(textSizeNote ?? "") This picture is \(part). The notes are on the whole sheet.")
            } else {
                note(
                    matrix.supplement == nil
                        ? "Snapshot matrix from the contract: columns are \(matrix.columnName), rows are "
                            + "\(matrix.rowsName)."
                        : "Hand-written in the catalog on the contract's axes: columns are \(matrix.columnName), "
                            + "rows are \(matrix.rowsName).")
                if let supplement = matrix.supplement {
                    note(supplement.note)
                }
                if let note = matrix.unboundNote {
                    self.note(note)
                }
                if let textSize = textSizeNote {
                    note(textSize)
                }
            }
        }
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .textRole(.footnote.regular)
            .foregroundStyle(.text.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// The capture's text size, when it is not the default.
    private var textSizeNote: String? {
        guard dynamicTypeSize != Self.ownTextSize else { return nil }
        let name =
            CatalogLaunchOptions.dynamicTypeSizes.first { $0.size == dynamicTypeSize }?.name ?? "\(dynamicTypeSize)"
        return "Text size \(name): the cells follow it; the sheet's own text stays at the default."
    }

    @ViewBuilder
    private func cells(_ row: String?) -> some View {
        ForEach(sheet.columns, id: \.self) { column in
            switch matrix.cell(sheet, row: row, column: column) {
            case .drawn(let combination, let fallbacks, let advisedAgainst):
                VStack(alignment: .leading, spacing: .space25) {
                    matrix.content(combination)
                        .accessibilityIdentifier(CatalogAccessibilityID.matrixCell)
                    Group {
                        if let advisedAgainst {
                            TokenDetail("advised against: constraints[\(advisedAgainst)]")
                        }
                        if !fallbacks.isEmpty {
                            TokenDetail(
                                fallbacks.map { "\($0.option) \($0.value) draws \($0.drawn)" }.joined(separator: ", "))
                        }
                    }
                    .dynamicTypeSize(Self.ownTextSize)
                }
            case .excluded(let constraint):
                TokenDetail("excluded: constraints[\(constraint)]")
                    .dynamicTypeSize(Self.ownTextSize)
            }
        }
    }
}

extension EnvironmentValues {
    /// Called with the frame of a matrix sheet's content in its window, in points, whenever it changes: what the
    /// in-process snapshot tests cut their picture to (`@testable`; nothing in the catalog sets it).
    @Entry var matrixSheetFrame: (@MainActor (CGRect) -> Void)? = nil
}

/// The mark on a supplement's sheet: what it shows is not a contract option, and the sheet is written by hand.
private struct NotContractOptionMark: View {
    var body: some View {
        Text("Not a contract option")
            .textRole(.caption.medium)
            .foregroundStyle(.status.warning.text)
            .padding(.horizontal, .space100)
            .padding(.vertical, .space25)
            .background(.status.warning.background, in: Capsule())
            .overlay(Capsule().strokeBorder(.status.warning.border, lineWidth: .stroke.thin))
    }
}

/// Stops Core Animation in the window that holds it: the layer tree's time stands still, so an indicator that spins
/// forever shows one frame, the same on every capture. Only the matrix sheets use it; it changes nothing a component
/// draws, and SwiftUI's own animations have nothing to run on a sheet that does not change. On macOS it also sets the
/// window to the catalog's size.
private struct FrozenAnimations {}

#if os(iOS)
    extension FrozenAnimations: UIViewRepresentable {
        func makeUIView(context: Context) -> FreezingView { FreezingView() }
        func updateUIView(_ view: FreezingView, context: Context) {}

        final class FreezingView: UIView {
            override func didMoveToWindow() {
                super.didMoveToWindow()
                window?.layer.speed = 0
            }
        }
    }
#elseif os(macOS)
    extension FrozenAnimations: NSViewRepresentable {
        func makeNSView(context: Context) -> FreezingView { FreezingView() }
        func updateNSView(_ view: FreezingView, context: Context) {}

        final class FreezingView: NSView {
            override func viewDidMoveToWindow() {
                super.viewDidMoveToWindow()
                window?.contentView?.layer?.speed = 0
                // A window the system restores from an earlier run keeps that run's size; a sheet is captured in the
                // catalog's own size, the same on every run.
                window?.setContentSize(CatalogScene.windowSize)
            }
        }
    }
#else
    extension FrozenAnimations: View {
        var body: some View { EmptyView() }
    }
#endif
