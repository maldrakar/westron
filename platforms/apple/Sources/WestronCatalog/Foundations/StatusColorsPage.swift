import SwiftUI
import WestronUI

extension CatalogEntry {
    /// The five statuses with their six roles, and the eight chart series, in the catalog's theme.
    static let colorStatus = CatalogEntry(
        id: "color-status", title: "Colors: statuses and charts", section: .foundations
    ) {
        StatusColorsPage()
    }
}

/// A status's colors, its icon and its word: the semantic tokens `color.status.<name>.*`.
struct StatusSample {
    let name: String
    let word: String
    let icon: Westron.Icon
    let background: Westron.Color
    let border: Westron.Color
    let iconColor: Westron.Color
    let text: Westron.Color
    let fill: Westron.Color
    let onFill: Westron.Color

    static let danger = StatusSample(
        name: "danger", word: "Failed", icon: .xmarkCircleFill, background: .status.danger.background,
        border: .status.danger.border, iconColor: .status.danger.icon, text: .status.danger.text,
        fill: .status.danger.fill,
        onFill: .status.danger.onFill)
    static let warning = StatusSample(
        name: "warning", word: "Slow", icon: .exclamationTriangleFill, background: .status.warning.background,
        border: .status.warning.border, iconColor: .status.warning.icon, text: .status.warning.text,
        fill: .status.warning.fill, onFill: .status.warning.onFill)
    static let success = StatusSample(
        name: "success", word: "Succeeded", icon: .checkCircleFill, background: .status.success.background,
        border: .status.success.border, iconColor: .status.success.icon, text: .status.success.text,
        fill: .status.success.fill, onFill: .status.success.onFill)
    static let info = StatusSample(
        name: "info", word: "Running", icon: .infoCircleFill, background: .status.info.background,
        border: .status.info.border, iconColor: .status.info.icon, text: .status.info.text, fill: .status.info.fill,
        onFill: .status.info.onFill)
    static let neutral = StatusSample(
        name: "neutral", word: "Cancelled", icon: .checkCircle, background: .status.neutral.background,
        border: .status.neutral.border, iconColor: .status.neutral.icon, text: .status.neutral.text,
        fill: .status.neutral.fill, onFill: .status.neutral.onFill)

    static let all: [StatusSample] = [.danger, .warning, .success, .info, .neutral]
}

/// A status badge: the icon in status.<name>.icon and the word in status.<name>.text on status.<name>.background.
struct StatusBadge: View {
    let status: StatusSample

    var body: some View {
        HStack(spacing: .space50) {
            Image(status.icon)
                .foregroundStyle(status.iconColor)
            Text(status.word)
                .foregroundStyle(status.text)
        }
        .textRole(.caption.medium)
        .padding(.horizontal, .space75)
        .frame(minHeight: StatusMetrics.badge)
        .background(status.background, in: Capsule())
        // A badge keeps its word on one line; the columns beside it give way.
        .fixedSize(horizontal: true, vertical: false)
    }
}

/// A row per status, a column per role; then the chart series as bars on one scale.
private struct StatusColorsPage: View {
    private static let roles = ["badge", "border", "fill, on-fill"]
    /// The heights of the bars, as parts of the tallest.
    private static let values: [Double] = [1, 0.82, 0.66, 0.9, 0.48, 0.74, 0.58, 0.4]
    private static let series: [Westron.Color] = [
        .chart1, .chart2, .chart3, .chart4, .chart5, .chart6, .chart7, .chart8,
    ]

    var body: some View {
        TokenPage(
            title: "Statuses and charts",
            summary: "color.status.<name>.<role> drawn as a badge, a field's border and a solid fill; then "
                + "color.chart.1–8 in order, on the canvas."
        ) {
            Grid(alignment: .leading, horizontalSpacing: .space150, verticalSpacing: SampleMetrics.rowSpacing) {
                GridRow {
                    TokenDetail("status.*")
                    ForEach(Self.roles, id: \.self) { TokenDetail($0) }
                }
                ForEach(StatusSample.all, id: \.name) { status in
                    GridRow {
                        TokenName(status.name)
                        StatusBadge(status: status)
                        Text("Aa")
                            .textRole(.footnote.regular)
                            .foregroundStyle(status.text)
                            .padding(.horizontal, .space100)
                            .frame(minHeight: StatusMetrics.badge)
                            .overlay {
                                RoundedRectangle(cornerRadius: .radius100)
                                    .strokeBorder(status.border, lineWidth: .stroke.thin)
                            }
                        Text(status.word)
                            .textRole(.caption.medium)
                            .foregroundStyle(status.onFill)
                            .padding(.horizontal, .space100)
                            .frame(minHeight: StatusMetrics.badge)
                            .background(status.fill, in: RoundedRectangle(cornerRadius: .radius100))
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
            }
            HStack(alignment: .bottom, spacing: .space100) {
                ForEach(Self.series.indices, id: \.self) { index in
                    VStack(spacing: .space25) {
                        RoundedRectangle(cornerRadius: .radius75)
                            .fill(Self.series[index])
                            .frame(width: StatusMetrics.bar, height: StatusMetrics.chart * Self.values[index])
                        TokenDetail("\(index + 1)")
                    }
                }
            }
        }
    }
}

private enum StatusMetrics {
    #if os(macOS)
        static let badge: CGFloat = 20
        static let bar: CGFloat = 28
        static let chart: CGFloat = 120
    #else
        static let badge: CGFloat = 24
        static let bar: CGFloat = 30
        static let chart: CGFloat = 160
    #endif
}
