import SwiftUI
import WestronUI

#if os(macOS)
    import AppKit
#elseif os(iOS)
    import UIKit
#endif

/// One sheet of a component's snapshot matrix: a title with the values the sheet fixes, the column option's values
/// across, and a row per state, rest first. Each cell is the real component drawn by its `<Component>MatrixCell`.
///
/// The sheet is laid out to fit one screenshot with nothing cut off: on macOS the state names are a column of their
/// own, in the catalog's wide window; on an iPhone in portrait each state name is a line above its row, so the cells
/// have the full width. Core Animation is frozen in the sheet's window (`FrozenAnimations`), so that a loading
/// indicator stands still and two captures compare pixel for pixel.
struct MatrixSheetView: View {
    let matrix: ComponentMatrix
    let sheet: ComponentMatrix.Sheet

    var body: some View {
        VStack(alignment: .leading, spacing: SampleMetrics.pagePadding) {
            VStack(alignment: .leading, spacing: .space25) {
                Text("\(matrix.component) · \(matrix.title(of: sheet))")
                    .textRole(.heading.small)
                    .foregroundStyle(.text.primary)
                Text(
                    "Snapshot matrix from the contract: columns are \(matrix.columnName), rows are rest and each state "
                        + "alone."
                )
                .textRole(.footnote.regular)
                .foregroundStyle(.text.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            Grid(alignment: .leading, horizontalSpacing: .space150, verticalSpacing: .space100) {
                GridRow {
                    #if os(macOS)
                        Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                    #endif
                    ForEach(sheet.columns, id: \.self) { column in
                        TokenName(column)
                    }
                }
                ForEach(matrix.rows(of: sheet), id: \.self) { row in
                    #if os(macOS)
                        GridRow {
                            TokenDetail(row ?? "rest")
                            cells(row)
                        }
                    #else
                        GridRow {
                            TokenDetail(row ?? "rest")
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.background.canvas)
        .background(FrozenAnimations())
    }

    @ViewBuilder
    private func cells(_ row: String?) -> some View {
        ForEach(sheet.columns, id: \.self) { column in
            switch matrix.cell(sheet, row: row, column: column) {
            case .drawn(let combination, let fallbacks):
                VStack(alignment: .leading, spacing: .space25) {
                    matrix.content(combination)
                        .accessibilityIdentifier(CatalogAccessibilityID.matrixCell)
                    if !fallbacks.isEmpty {
                        TokenDetail(
                            fallbacks.map { "\($0.option) \($0.value) draws \($0.drawn)" }.joined(separator: ", "))
                    }
                }
            case .excluded(let constraint):
                TokenDetail("excluded: constraints[\(constraint)]")
            }
        }
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
