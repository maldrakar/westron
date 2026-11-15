import SwiftUI
import WestronUI

/// The frame of a token sample page: a title, a line on what the page shows, and the samples, on the canvas.
///
/// Each page fits one screenshot on an iPhone 17 in portrait and in the catalog's macOS window, so the owner can
/// review the tokens from screenshots (#17); the scroll view is only for smaller windows.
struct TokenPage<Content: View>: View {
    let title: String
    let summary: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SampleMetrics.pagePadding) {
                VStack(alignment: .leading, spacing: .space25) {
                    Text(title)
                        .font(.headingSmall)
                        .foregroundStyle(.textPrimary)
                    Text(summary)
                        .font(.footnoteRegular)
                        .foregroundStyle(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                content
            }
            .padding(SampleMetrics.pagePadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.backgroundCanvas)
    }
}

/// The sizes of the samples. The catalog's macOS window, 720 × 540, is wide and short; an iPhone in portrait is narrow
/// and tall. Each page fits both.
enum SampleMetrics {
    #if os(macOS)
        static let pagePadding: CGFloat = .space150
        static let rowSpacing: CGFloat = .space25
        static let cell = CGSize(width: 56, height: 24)
        /// A check, a disc, a ring.
        static let mark: CGFloat = 20
        /// A list's tile.
        static let tile: CGFloat = 24
    #else
        static let pagePadding: CGFloat = .space200
        static let rowSpacing: CGFloat = .space75
        static let cell = CGSize(width: 56, height: 32)
        static let mark: CGFloat = 22
        static let tile: CGFloat = 30
    #endif
}

/// A token's name, as the tokens write it, in a face that tells it from the samples.
struct TokenName: View {
    let name: String

    init(_ name: String) {
        self.name = name
    }

    var body: some View {
        Text(name)
            .font(.footnoteMedium.monospaced())
            .foregroundStyle(.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

/// A line of detail under a token's name.
struct TokenDetail: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.captionMedium)
            .foregroundStyle(.textSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

extension Westron.Theme {
    /// The column title of the theme.
    var title: String {
        switch self {
        case .light: "Light"
        case .dark: "Dark"
        case .lightHighContrast: "Light HC"
        case .darkHighContrast: "Dark HC"
        }
    }
}

extension View {
    /// Draws the view in a theme, whatever the catalog's: the colorsets resolve in the color scheme and the contrast
    /// of the environment, so a sample under this modifier shows the runtime switching itself.
    func theme(_ theme: Westron.Theme) -> some View {
        environment(\.colorScheme, theme.isDark ? .dark : .light)
            .environment(\._colorSchemeContrast, theme.isHighContrast ? .increased : .standard)
    }
}

extension Westron.Color {
    /// A semantic color by its token name.
    static func named(_ name: String) -> Westron.Color? {
        all.first { $0.name == name }
    }

    /// The name without the `color.` group: `text.secondary`.
    var shortName: String {
        name.hasPrefix("color.") ? String(name.dropFirst("color.".count)) : name
    }
}

/// A sample's ground: a stack of color tokens, top first, painted bottom up, as a translucent layer is laid on what it
/// covers.
struct ColorStack: View {
    let names: [String]

    var body: some View {
        ZStack {
            ForEach(names.reversed(), id: \.self) { name in
                if let color = Westron.Color.named(name) {
                    Rectangle().fill(Color(color))
                }
            }
        }
    }
}
