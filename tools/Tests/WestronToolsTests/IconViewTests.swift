import Foundation
import Testing
import WestronTools

/// An Icon-shaped own view: the glyph from the icon registry, the system's scale, a spoken label (#28). It follows
/// westron's Icon contract, but it is not that contract.
private let iconViewYAML = """
    id: icon
    status: approved
    consumers: [todo-app/list-screen]
    options:
      glyph: { type: icons }
      scale: { type: enum, values: [small, medium, large], default: medium }
    slots: [label]
    accessibility: { role: image, label: optional }
    platforms:
      apple:
        strategy: own-component
        form: view
        systemOptions: { scale: SwiftUI.Image.Scale }
      web: { status: planned }
      linux: { status: planned }
      android: { status: planned }

    """

private let iconViewSource = "spec/components/icon/icon.spec.yaml"

private let iconNames = ["tray", "sun", "calendar", "week", "logbook", "trash", "briefcase", "house"]

private func iconContract(_ yaml: String = iconViewYAML) throws -> ComponentContract {
    try ComponentContract(yaml: yaml, source: iconViewSource)
}

private func replacing(_ old: String, with new: String, in text: String = iconViewYAML) -> String {
    precondition(text.contains(old), old)
    return text.replacingOccurrences(of: old, with: new)
}

/// The hand-written view the contract gives.
private let iconSwift = """
    import SwiftUI

    public struct Icon: View {
        let icon: Westron.Icon
        let label: Text?

        public init(_ icon: Westron.Icon) {
            self.icon = icon
            label = nil
        }

        public init(_ icon: Westron.Icon, label: LocalizedStringKey) {
            self.icon = icon
            self.label = Text(label)
        }

        @_disfavoredOverload
        public init<S: StringProtocol>(_ icon: Westron.Icon, label: S) {
            self.icon = icon
            self.label = Text(label)
        }

        public var body: some View {
            Image(icon).accessibilityHidden(label == nil)
        }
    }

    """

private func parity(_ swift: String, yaml: String = iconViewYAML) throws -> [String] {
    APIParity.check(
        contracts: [APIParity.Contract(contract: try iconContract(yaml), source: iconViewSource, text: yaml)],
        files: [("WestronUI/Icon/Icon.swift", swift)], sourceRoot: "WestronUI"
    ).problems.map(\.description)
}

@Suite("An own view whose option is the icon registry's names")
struct IconViewTests {
    @Test("the contract is valid, and gives API on Apple")
    func valid() throws {
        let schema = try ContractSchema(
            file: repositoryRoot.appendingPathComponent(ContractSchema.defaultFile).path)
        #expect(
            ContractCheck.check(
                yaml: iconViewYAML, source: iconViewSource, schema: schema, tokens: ContractTokens(everywhere: []))
                == [])
        #expect(AppleComponents.givesAPI(try iconContract()))
        #expect(try iconContract().accessibilityLabel == "optional")
    }

    @Test("its API: the glyph as Westron.Icon, unlabeled first; a decorative, a localized and a verbatim initializer")
    func api() throws {
        let api = try AppleComponents.Own(try iconContract(), source: iconViewSource)
        #expect(api.form == .view && api.name == "Icon" && api.enums.isEmpty)
        #expect(AppleIcons.iconType == "Westron.Icon")
        #expect(
            api.initializers.map(\.declaration) == [
                "public init(_: Westron.Icon)",
                "public init(_: Westron.Icon, label: LocalizedStringKey)",
                "@_disfavoredOverload public init<S: StringProtocol>(_: Westron.Icon, label: S)",
            ])
        // scale is the system's .imageScale(_:): no parameter and no enum.
        #expect(!api.initializers.flatMap(\.parameters).contains { $0.label == "scale" })
        // No enum, so no generated file.
        #expect(try AppleComponents.files(for: [(try iconContract(), iconViewSource)]) == [])
    }

    @Test("a required label leaves out the decorative initializer")
    func requiredLabel() throws {
        let api = try AppleComponents.Own(
            try iconContract(replacing("label: optional", with: "label: required")), source: iconViewSource)
        #expect(api.initializers.count == 2)
        #expect(api.initializers.allSatisfy { $0.parameters.last?.label == "label" })
    }

    @Test("without the label slot, only the decorative initializer")
    func withoutLabelSlot() throws {
        let api = try AppleComponents.Own(
            try iconContract(replacing("slots: [label]\n", with: "")), source: iconViewSource)
        #expect(api.initializers.map(\.declaration) == ["public init(_: Westron.Icon)"])
    }

    @Test("shapes not derived yet fail, and say which")
    func notDerived() throws {
        func failure(_ yaml: String) -> String? {
            do {
                _ = try AppleComponents.Own(try iconContract(yaml), source: iconViewSource)
                return nil
            } catch {
                return "\(error)"
            }
        }
        let notYet = "the conventions do not derive an own-component's API for it yet"
        #expect(
            failure(replacing("form: view", with: "form: modifier"))?.contains(
                "options.glyph: a modifier with an option whose values are icons: \(notYet)") == true)
        #expect(
            failure(replacing("  scale:", with: "  badge: { type: icons }\n  scale:"))?.contains(
                "options.badge: a second option whose values are icons") == true)
        #expect(
            failure(replacing("slots: [label]", with: "slots: [label, detail]"))?.contains(
                "slots: a glyph's view with several slots") == true)
    }

    @Test("the lint accepts the view, and reports a missing or changed initializer")
    func lint() throws {
        #expect(try parity(iconSwift) == [])

        let missingVerbatim = try parity(
            iconSwift.replacingOccurrences(
                of: """
                        @_disfavoredOverload
                        public init<S: StringProtocol>(_ icon: Westron.Icon, label: S) {
                            self.icon = icon
                            self.label = Text(label)
                        }

                    """, with: ""))
        #expect(
            missingVerbatim == [
                "\(iconViewSource):12: missing: `@_disfavoredOverload public init<S: StringProtocol>(_: Westron.Icon, "
                    + "label: S)` in Icon, which Icon's contract (\(iconViewSource)) gives"
            ])

        // Without the attribute, the verbatim initializer would compete with the localized one for a literal.
        let favored = try parity(iconSwift.replacingOccurrences(of: "    @_disfavoredOverload\n", with: ""))
        #expect(favored.count == 1)
        #expect(favored.first?.contains("Icon's initializer differs from the contract") == true)

        let changedLabel = try parity(
            iconSwift.replacingOccurrences(of: "label: LocalizedStringKey", with: "label: Text"))
        #expect(changedLabel.count == 1)
        #expect(
            changedLabel.first?.contains(
                "Icon's initializer differs from the contract: expected `init(_: Westron.Icon, label: "
                    + "LocalizedStringKey)`, found `init(_: Westron.Icon, label: Text)") == true)

        let scaleArgument = try parity(
            iconSwift
                + "extension Icon {\n    public init(_ icon: Westron.Icon, scale: Image.Scale) { self.init(icon) }\n}\n"
        )
        #expect(scaleArgument.count == 1)
        #expect(scaleArgument.first?.contains("Icon.init is a member of Icon's API") == true)
    }

    @Test("the matrix: glyphs down the rows, the system's scale across, six rows to a sheet")
    func matrix() throws {
        let matrix = try SnapshotMatrix(try iconContract(), source: iconViewSource, icons: iconNames)
        #expect(matrix.rowAxis == "glyph" && matrix.columnAxis == "scale")
        #expect(matrix.axes.map(\.name) == ["glyph", "scale"])
        #expect(matrix.axes[0].isIcons && matrix.axes[0].accessor == "Westron.Icon")
        #expect(matrix.axes[1].systemType == "SwiftUI.Image.Scale")
        #expect(matrix.combinations.count == iconNames.count * 3)
        #expect(matrix.sheets.map(\.id) == ["all_rows-1", "all_rows-2"])
        #expect(matrix.sheets[0].rows == ["tray", "sun", "calendar", "week", "logbook", "trash"])
        #expect(matrix.sheets[1].rows == ["briefcase", "house"])
        #expect(matrix.sheets.allSatisfy { $0.columns == ["small", "medium", "large"] && $0.fixed.isEmpty })

        // With states, the glyphs are not the rows: the states are.
        let withStates = try SnapshotMatrix(
            try iconContract(replacing("slots: [label]", with: "slots: [label]\nstates: [disabled]")),
            source: iconViewSource, icons: iconNames)
        #expect(withStates.rowAxis == nil && withStates.columnAxis == "glyph")

        let files = try AppleSnapshotMatrix.files(for: [(try iconContract(), iconViewSource)], icons: iconNames)
        let swift = try #require(files.first).contents
        #expect(swift.contains("        columns: \"scale\",\n        rows: \"glyph\",\n"))
        #expect(swift.contains("    private let glyph: Westron.Icon\n"))
        #expect(swift.contains("        self.glyph = Westron.Icon(rawValue: combination.values[0])!\n"))
        #expect(swift.contains("(the contract has no states; glyph runs down the rows)"))
        #expect(swift.contains(") { IconMatrixCell(IconMatrixValues($0)) }"))
    }

    @Test("the registry's real names: six sheets, and a row list too long for a line packed as swift format packs it")
    func realRegistry() throws {
        let registry = try IconRegistry.load(
            file: repositoryRoot.appendingPathComponent(IconRegistry.defaultFile).path)
        let names = registry.icons.map(\.name)
        let files = try AppleSnapshotMatrix.files(for: [(try iconContract(), iconViewSource)], icons: names)
        let swift = try #require(files.first).contents
        #expect(swift.split(separator: "\n").allSatisfy { $0.count <= 120 })
        #expect(
            swift.contains(
                """
                                rows: [
                                    "columns", "chevronLeft", "checkCircleFill", "xmarkCircleFill", "exclamationTriangleFill",
                                    "infoCircleFill",
                                ]

                """))
        #expect(try SnapshotMatrix(try iconContract(), source: iconViewSource, icons: names).sheets.count == 6)
    }
}
