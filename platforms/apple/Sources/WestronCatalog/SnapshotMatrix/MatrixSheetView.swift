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
/// The sheet is laid out to fit one screenshot with nothing cut off (one that does not fit at a text size, or whose cells
/// do not fit side by side, is taken in parts, `ComponentMatrix.pictures(of:at:columns:)`, each with a short header):
/// on macOS the state names are a column of their own, in the catalog's wide window; on an iPhone in portrait each
/// state name is a line above its row, so the cells have the full width. Only the cells follow the text size of the capture: the sheet's own text, its title, notes and
/// the names of columns and rows, stays at the default size, so that the room goes to the component and the sheet
/// says so. Core Animation is frozen in the sheet's window (`FrozenAnimations`), so that a loading indicator stands
/// still and two captures compare pixel for pixel.
struct MatrixSheetView: View {
    let matrix: ComponentMatrix
    let sheet: ComponentMatrix.Sheet

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.matrixSheetProbe) private var probe

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
        // The sheet's content: the snapshot tests cut their picture to it.
        .frame(maxWidth: .infinity, alignment: .leading)
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            probe?.sheet = frame
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
            if let part = matrix.partTitle(of: sheet), dynamicTypeSize.isAccessibilitySize {
                // At an accessibility size a part is taken where the cells grow so large that a sheet does not fit:
                // it says what it holds and leaves the notes to the whole sheet, so that the room goes to the cells.
                note("\(textSizeNote ?? "") This picture is \(part). The notes are on the whole sheet.")
            } else if let part = matrix.partTitle(of: sheet) {
                // Elsewhere a part is taken where the sheet's columns side by side would squeeze its cells below the
                // width they need (SnapshotMatrixRenderTests): no picture at this text size holds the whole sheet, and
                // a supplement's sheet with its notes all but fills an iPhone's screen, so a part says what it holds
                // and why, and leaves the notes to the review page, which has them.
                note(
                    [
                        textSizeNote,
                        "This picture is \(part). Side by side the columns would squeeze the cells. The notes are on "
                            + "the review page.",
                    ].compactMap { $0 }.joined(separator: " "))
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
                        // A cell that draws nothing has no frame, and the snapshot tests count it as missing.
                        .onGeometryChange(for: CGRect.self) { proxy in
                            proxy.frame(in: .global)
                        } action: { frame in
                            probe?.cells[combination] = frame
                        }
                        .background {
                            if let probe {
                                // The width the cell needs, for the snapshot tests alone: a copy at its ideal size,
                                // hidden, behind the cell, so that it draws nothing and takes no room.
                                matrix.content(combination)
                                    .fixedSize()
                                    .onGeometryChange(for: CGFloat.self) { proxy in
                                        proxy.size.width
                                    } action: { width in
                                        probe.needs[combination] = width
                                    }
                                    .onPreferenceChange(MatrixCellTakesOfferedWidth.self) { takes in
                                        MainActor.assumeIsolated {
                                            if takes { probe.takeOfferedWidth.insert(combination) }
                                        }
                                    }
                                    .hidden()
                            }
                        }
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

/// What a matrix sheet reports of its own layout, in its window's points, for the in-process snapshot tests
/// (platforms/apple/Tests/WestronSnapshotTests, `@testable`), which have no accessibility query: the frame of the
/// sheet's content, which they cut their picture to, the frame of each cell drawn, which they count against the matrix
/// and check against the window, and the width each cell needs, which they check its frame against. Nothing in the
/// catalog sets it, and only with it does the sheet measure what a cell needs.
@MainActor
final class MatrixSheetProbe {
    var sheet = CGRect.zero
    var cells: [ComponentMatrix.Combination: CGRect] = [:]
    /// By cell, its ideal width: what it takes when nothing squeezes it, such as a button's label on one line.
    var needs: [ComponentMatrix.Combination: CGFloat] = [:]
    /// The cells that take the width they are offered by design (`matrixCellTakesOfferedWidth()`): their ideal width
    /// is not a need.
    var takeOfferedWidth: Set<ComponentMatrix.Combination> = []

    /// The cells drawn narrower than their ideal width, by more than half a point, with both widths, in the order of
    /// the sheet's cells; a cell that takes the width it is offered by design is not among them.
    var squeezed: [(combination: ComponentMatrix.Combination, width: CGFloat, needs: CGFloat)] {
        cells.sorted { ($0.value.minY, $0.value.minX) < ($1.value.minY, $1.value.minX) }
            .compactMap { combination, frame in
                guard !takeOfferedWidth.contains(combination), let needs = needs[combination],
                    frame.width > 0, frame.width < needs - 0.5
                else { return nil }
                return (combination, frame.width, needs)
            }
    }
}

/// Whether a matrix cell takes the width it is offered by design (`matrixCellTakesOfferedWidth()`).
struct MatrixCellTakesOfferedWidth: PreferenceKey {
    static let defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) { value = value || nextValue() }
}

extension View {
    /// Marks a matrix cell whose content takes the width it is offered by design: running text that wraps between its
    /// words (Text's roles, a surface's sample text) or a field that fills its row. The snapshot tests check every
    /// other cell against its ideal width, so that a sheet never squeezes a control below the width it needs, such as
    /// a button until its label breaks inside a word (the Button contract leaves that width unsupported); a cell
    /// marked with this is not checked so. It changes nothing drawn.
    func matrixCellTakesOfferedWidth() -> some View {
        preference(key: MatrixCellTakesOfferedWidth.self, value: true)
    }
}

extension EnvironmentValues {
    @Entry var matrixSheetProbe: MatrixSheetProbe? = nil
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
