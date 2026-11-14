import SwiftUI

/// Аргументы запуска каталога. Их передаёт UI-тест скриншотов по просьбе `tools/apple/catalog-screenshot.sh`.
///
/// ```
/// -WestronEntry <id>                 показать одну запись изолированно, без навигации
/// -WestronAppearance light|dark      оформление
/// -WestronDynamicType <размер>       xSmall … xxxLarge, accessibility1 … accessibility5
/// ```
///
/// Незнакомые аргументы пропускаются: Xcode и система добавляют свои.
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

    public enum ParseError: Error, Equatable, CustomStringConvertible {
        case missingValue(flag: String)
        case invalidValue(flag: String, value: String, allowed: [String])

        public var description: String {
            switch self {
            case .missingValue(let flag):
                "\(flag): нет значения"
            case .invalidValue(let flag, let value, let allowed):
                "\(flag): недопустимое значение «\(value)»; допустимы: \(allowed.joined(separator: ", "))"
            }
        }
    }

    public var entryID: String?
    public var appearance: Appearance?
    public var dynamicTypeSize: DynamicTypeSize?

    public init(entryID: String? = nil, appearance: Appearance? = nil, dynamicTypeSize: DynamicTypeSize? = nil) {
        self.entryID = entryID
        self.appearance = appearance
        self.dynamicTypeSize = dynamicTypeSize
    }

    /// Разбирает аргументы процесса без первого элемента (пути к исполняемому файлу).
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
            case "-WestronDynamicType":
                guard let parsed = Self.dynamicTypeSizes.first(where: { $0.name == value })?.size else {
                    throw .invalidValue(flag: flag, value: value, allowed: Self.dynamicTypeSizes.map(\.name))
                }
                dynamicTypeSize = parsed
            default:
                break
            }
            index = valueIndex + 1
        }
    }

    /// Аргументы текущего процесса.
    public static var current: Result<CatalogLaunchOptions, ParseError> {
        Result { () throws(ParseError) in
            try CatalogLaunchOptions(arguments: Array(ProcessInfo.processInfo.arguments.dropFirst()))
        }
    }

    static let flags: Set<String> = ["-WestronEntry", "-WestronAppearance", "-WestronDynamicType"]

    /// Имена размеров совпадают с именами случаев `DynamicTypeSize`.
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
