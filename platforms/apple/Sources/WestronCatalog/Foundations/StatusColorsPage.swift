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
    let background: Color
    let border: Color
    let iconColor: Color
    let text: Color
    let fill: Color
    let onFill: Color

    static let danger = StatusSample(
        name: "danger", word: "Failed", icon: .xmarkCircleFill, background: .statusDangerBackground,
        border: .statusDangerBorder, iconColor: .statusDangerIcon, text: .statusDangerText, fill: .statusDangerFill,
        onFill: .statusDangerOnFill)
    static let warning = StatusSample(
        name: "warning", word: "Slow", icon: .exclamationTriangleFill, background: .statusWarningBackground,
        border: .statusWarningBorder, iconColor: .statusWarningIcon, text: .statusWarningText,
        fill: .statusWarningFill, onFill: .statusWarningOnFill)
    static let success = StatusSample(
        name: "success", word: "Succeeded", icon: .checkCircleFill, background: .statusSuccessBackground,
        border: .statusSuccessBorder, iconColor: .statusSuccessIcon, text: .statusSuccessText,
        fill: .statusSuccessFill, onFill: .statusSuccessOnFill)
    static let info = StatusSample(
        name: "info", word: "Running", icon: .infoCircleFill, background: .statusInfoBackground,
        border: .statusInfoBorder, iconColor: .statusInfoIcon, text: .statusInfoText, fill: .statusInfoFill,
        onFill: .statusInfoOnFill)
    static let neutral = StatusSample(
        name: "neutral", word: "Cancelled", icon: .checkCircle, background: .statusNeutralBackground,
        border: .statusNeutralBorder, iconColor: .statusNeutralIcon, text: .statusNeutralText,
        fill: .statusNeutralFill, onFill: .statusNeutralOnFill)

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
        .font(.captionMedium)
        .padding(.horizontal, .space75)
        .frame(height: StatusMetrics.badge)
        .background(status.background, in: Capsule())
    }
}

/// A row per status, a column per role; then the chart series as bars on one scale.
private struct StatusColorsPage: View {
    private static let roles = ["badge", "border", "fill, on-fill"]
    /// The heights of the bars, as parts of the tallest.
    private static let values: [Double] = [1, 0.82, 0.66, 0.9, 0.48, 0.74, 0.58, 0.4]
    private static let series: [Color] = [.chart1, .chart2, .chart3, .chart4, .chart5, .chart6, .chart7, .chart8]

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
                            .font(.footnoteRegular)
                            .foregroundStyle(status.text)
                            .padding(.horizontal, .space100)
                            .frame(height: StatusMetrics.badge)
                            .overlay {
                                RoundedRectangle(cornerRadius: .radius100)
                                    .strokeBorder(status.border, lineWidth: .strokeThin)
                            }
                        Text(status.word)
                            .font(.captionMedium)
                            .foregroundStyle(status.onFill)
                            .padding(.horizontal, .space100)
                            .frame(height: StatusMetrics.badge)
                            .background(status.fill, in: RoundedRectangle(cornerRadius: .radius100))
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
