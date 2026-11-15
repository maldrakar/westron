import SwiftUI
import WestronUI

extension CatalogEntry {
    /// The motions as a table: a screenshot cannot show them move.
    static let motion = CatalogEntry(id: "motion", title: "Motion", section: .foundations) {
        MotionPage()
    }
}

private struct MotionPage: View {
    var body: some View {
        TokenPage(
            title: "Motion",
            summary: "motion.*: Apple runs the spring where a motion has one, otherwise the curve. The plot is the "
                + "token's curve, progress over time."
        ) {
            // The curve beside the numbers where the window is wide enough, under the name otherwise.
            ViewThatFits(in: .horizontal) {
                table(curveInline: true)
                table(curveInline: false)
            }
        }
    }

    private func table(curveInline: Bool) -> some View {
        Grid(alignment: .leading, horizontalSpacing: .space100, verticalSpacing: SampleMetrics.rowSpacing) {
            GridRow {
                TokenDetail("motion.*")
                TokenDetail("duration")
                TokenDetail("delay")
                TokenDetail("curve")
                    .gridCellColumns(curveInline ? 2 : 1)
            }
            ForEach(Westron.Transition.all, id: \.name) { transition in
                GridRow {
                    VStack(alignment: .leading, spacing: 0) {
                        TokenName(String(transition.name.dropFirst("motion.".count)))
                        if !curveInline {
                            Text(Self.describe(transition))
                                .font(.captionMedium)
                                .foregroundStyle(.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Text(Self.seconds(transition.duration))
                        .gridColumnAlignment(.trailing)
                    Text(transition.delay > 0 ? Self.seconds(transition.delay) : "–")
                        .gridColumnAlignment(.trailing)
                    CurvePlot(curve: transition.curve)
                        .stroke(.textAccent, lineWidth: .strokeRegular)
                        .frame(width: SampleMetrics.mark, height: SampleMetrics.mark)
                        .background(.backgroundMuted, in: RoundedRectangle(cornerRadius: .radius75))
                    if curveInline { Text(Self.describe(transition)).fixedSize() }
                }
                .font(.footnoteRegular.monospacedDigit())
                .foregroundStyle(.textPrimary)
            }
        }
    }

    static func seconds(_ value: Double) -> String {
        String(format: "%g s", value)
    }

    /// The curve's control points; for a motion with a spring, the spring Apple runs first and the curve after it,
    /// since the two can differ (decisions/0013).
    static func describe(_ transition: Westron.Transition) -> String {
        let curve = transition.curve
        let points = [curve.x1, curve.y1, curve.x2, curve.y2].map { String(format: "%g", $0) }.joined(separator: ", ")
        guard let spring = transition.spring else { return points }
        let duration = spring.duration == transition.duration ? "" : " \(seconds(spring.duration))"
        return "spring\(duration), bounce \(String(format: "%g", spring.bounce)) · curve \(points)"
    }
}

/// A cubic Bézier timing curve from (0, 0) to (1, 1), time to the right and progress upward. An overshoot leaves the
/// box, as it leaves the target.
private struct CurvePlot: Shape {
    let curve: Westron.Transition.Curve

    func path(in rect: CGRect) -> Path {
        let inset = rect.insetBy(dx: rect.width / 6, dy: rect.height / 6)
        func point(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: inset.minX + inset.width * x, y: inset.maxY - inset.height * y)
        }
        var path = Path()
        path.move(to: point(0, 0))
        path.addCurve(to: point(1, 1), control1: point(curve.x1, curve.y1), control2: point(curve.x2, curve.y2))
        return path
    }
}
