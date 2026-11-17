import SwiftUI

/// Catalog launch arguments. The screenshot UI test passes them at the request of
/// `tools/apple/catalog-screenshot.sh`.
///
/// ```
/// -WestronEntry <id>                 show one entry in isolation, without navigation
/// -WestronAppearance light|dark      appearance
/// -WestronContrast standard|high     contrast: high is the system's increased contrast, the -hc themes
/// -WestronDynamicType <size>         xSmall … xxxLarge, accessibility1 … accessibility5
/// -WestronScrollAnchor <0…1>         the point of the entry's scroll content held in view, 0 top, 1 bottom
/// ```
///
/// Unknown arguments are skipped: Xcode and the system add their own.
public struct CatalogLaunchOptions: Equatable, Sendable {
    public enum Appearance: String, CaseIterable, Sendable {
        case light, dark

        public var colorScheme: ColorScheme {
            switch self {
            case .light: .light
            case .dark: .dark
            }
        }
    }

    public enum Contrast: String, CaseIterable, Sendable {
        case standard, high

        public var colorSchemeContrast: ColorSchemeContrast {
            switch self {
            case .standard: .standard
            case .high: .increased
            }
        }
    }

    public enum ParseError: Error, Equatable, CustomStringConvertible {
        case missingValue(flag: String)
        case invalidValue(flag: String, value: String, allowed: [String])

        public var description: String {
            switch self {
            case .missingValue(let flag):
                "\(flag): no value"
            case .invalidValue(let flag, let value, let allowed):
                "\(flag): invalid value \"\(value)\"; allowed: \(allowed.joined(separator: ", "))"
            }
        }
    }

    public var entryID: String?
    public var appearance: Appearance?
    public var contrast: Contrast?
    public var dynamicTypeSize: DynamicTypeSize?
    /// The point of the entry's scroll content, from 0 at the top to 1 at the bottom, that the scroll view shows
    /// first and holds in place when the content grows. The accessibility audit (#25) enlarges the text of the page:
    /// a scroll view without an anchor goes back to the top, and the audit would measure only the top of the page.
    public var scrollAnchor: Double?

    public init(
        entryID: String? = nil, appearance: Appearance? = nil, contrast: Contrast? = nil,
        dynamicTypeSize: DynamicTypeSize? = nil, scrollAnchor: Double? = nil
    ) {
        self.entryID = entryID
        self.appearance = appearance
        self.contrast = contrast
        self.dynamicTypeSize = dynamicTypeSize
        self.scrollAnchor = scrollAnchor
    }

    /// Parses the process arguments without the first element (the path to the executable).
    public init(arguments: [String]) throws(ParseError) {
        self.init()
        var index = arguments.startIndex
        while index < arguments.endIndex {
            let flag = arguments[index]
            guard Self.flags.contains(flag) else {
                index += 1
                continue
            }
            let valueIndex = index + 1
            guard valueIndex < arguments.endIndex, !Self.flags.contains(arguments[valueIndex]) else {
                throw .missingValue(flag: flag)
            }
            let value = arguments[valueIndex]
            switch flag {
            case "-WestronEntry":
                entryID = value
            case "-WestronAppearance":
                guard let parsed = Appearance(rawValue: value) else {
                    throw .invalidValue(flag: flag, value: value, allowed: Appearance.allCases.map(\.rawValue))
                }
                appearance = parsed
            case "-WestronContrast":
                guard let parsed = Contrast(rawValue: value) else {
                    throw .invalidValue(flag: flag, value: value, allowed: Contrast.allCases.map(\.rawValue))
                }
                contrast = parsed
            case "-WestronDynamicType":
                guard let parsed = Self.dynamicTypeSizes.first(where: { $0.name == value })?.size else {
                    throw .invalidValue(flag: flag, value: value, allowed: Self.dynamicTypeSizes.map(\.name))
                }
                dynamicTypeSize = parsed
            case "-WestronScrollAnchor":
                guard let parsed = Double(value), parsed >= 0, parsed <= 1 else {
                    throw .invalidValue(flag: flag, value: value, allowed: ["a number from 0 to 1"])
                }
                scrollAnchor = parsed
            default:
                break
            }
            index = valueIndex + 1
        }
    }

    /// The arguments of the current process.
    public static var current: Result<CatalogLaunchOptions, ParseError> {
        Result { () throws(ParseError) in
            try CatalogLaunchOptions(arguments: Array(ProcessInfo.processInfo.arguments.dropFirst()))
        }
    }

    static let flags: Set<String> = [
        "-WestronEntry", "-WestronAppearance", "-WestronContrast", "-WestronDynamicType", "-WestronScrollAnchor",
    ]

    /// The size names match the names of the `DynamicTypeSize` cases.
    static let dynamicTypeSizes: [(name: String, size: DynamicTypeSize)] = [
        ("xSmall", .xSmall),
        ("small", .small),
        ("medium", .medium),
        ("large", .large),
        ("xLarge", .xLarge),
        ("xxLarge", .xxLarge),
        ("xxxLarge", .xxxLarge),
        ("accessibility1", .accessibility1),
        ("accessibility2", .accessibility2),
        ("accessibility3", .accessibility3),
        ("accessibility4", .accessibility4),
        ("accessibility5", .accessibility5),
    ]
}
