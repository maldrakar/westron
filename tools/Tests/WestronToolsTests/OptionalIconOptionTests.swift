import Foundation
import Testing
import WestronTools

/// A TextField-shaped contract with a glyph at its start and one at its end, each optional (#115): a style on a system
/// control, the one place the conventions derive an optional option whose values are icons.
private let fieldFixture = """
    id: text-field
    status: approved
    consumers: [todo-app/lists-screen]
    options:
      variant: { type: enum, values: [framed, inline] }
      size: { type: enum, values: [s, m, l], default: m }
      leadingIcon: { type: icons, optional: true }
      trailingIcon: { type: icons, optional: true }
    states: [focus, disabled]
    accessibility: { role: textField, label: required }
    platforms:
      apple: { strategy: style-on-system-control, base: SwiftUI.TextField }
      web: { status: planned }
      linux: { status: planned }
      android: { status: planned }

    """

private let fieldSource = "spec/components/text-field/text-field.spec.yaml"

/// An own view whose glyph is its first argument, as Icon's is.
private let viewFixture = """
    id: icon
    status: draft
    consumers: [todo-app/list-screen]
    options:
      glyph: { type: icons }
    accessibility: { role: image, label: optional }
    platforms:
      apple: { strategy: own-component, form: view }
      web: { status: planned }
      linux: { status: planned }
      android: { status: planned }

    """

private let viewSource = "spec/components/icon/icon.spec.yaml"

private let schema = try! ContractSchema(file: repositoryRoot.appendingPathComponent(ContractSchema.defaultFile).path)

private func problems(_ yaml: String, source: String) -> [String] {
    ContractCheck.check(yaml: yaml, source: source, schema: schema, tokens: ContractTokens(everywhere: []))
        .map { "\($0.place): \($0.message)" }
}

private func replacing(_ old: String, with new: String, in text: String) -> String {
    precondition(text.contains(old), old)
    return text.replacingOccurrences(of: old, with: new)
}

/// The hand-written style the generated overload applies, as the module would have it.
private let styleSwift = """
    import SwiftUI

    struct TextFieldVariantStyle: TextFieldStyle {
        let variant: TextFieldVariant
        let size: TextFieldSize?
        let leadingIcon: Westron.Icon?
        let trailingIcon: Westron.Icon?

        func _body(configuration: TextField<_Label>) -> some View {
            configuration
        }
    }

    """

private func lint(generated: String, yaml: String = fieldFixture) throws -> [String] {
    let contract = try ComponentContract(yaml: yaml, source: fieldSource)
    return APIParity.check(
        contracts: [APIParity.Contract(contract: contract, source: fieldSource, text: yaml)],
        files: [
            (path: "WestronUI/Generated/TextField+Contract.swift", text: generated),
            (path: "WestronUI/TextField/TextFieldVariantStyle.swift", text: styleSwift),
        ],
        sourceRoot: "WestronUI"
    ).problems.map(\.description)
}

private func generated(_ yaml: String = fieldFixture) throws -> String {
    try #require(try AppleComponents.file(for: ComponentContract(yaml: yaml, source: fieldSource), source: fieldSource))
        .contents
}

@Suite("Optional options whose values are icons")
struct OptionalIconOptionTests {
    @Test("the TextField-shaped fixture is valid; optional is a boolean of an icons option")
    func valid() {
        #expect(problems(fieldFixture, source: fieldSource) == [])
        let notBoolean = problems(
            replacing(
                "leadingIcon: { type: icons, optional: true }", with: "leadingIcon: { type: icons, optional: 1 }",
                in: fieldFixture), source: fieldSource)
        #expect(notBoolean.count == 1)
        #expect(notBoolean.first?.hasPrefix("options.leadingIcon") == true, "\(notBoolean)")
        // optional belongs to an icons option alone.
        let onEnum = problems(
            replacing(
                "size: { type: enum, values: [s, m, l], default: m }",
                with: "size: { type: enum, values: [s, m, l], default: m, optional: true }", in: fieldFixture),
            source: fieldSource)
        #expect(onEnum.count == 1)
        #expect(onEnum.first?.hasPrefix("options.size") == true, "\(onEnum)")
    }

    @Test("rule: optional only on a style on a system control; an own view's glyph is always named")
    func onlyOnAStyle() {
        let message =
            "an optional glyph is derived only for a style-on-system-control, as an argument of its overload that "
            + "defaults to none (spec/conventions.md); an own-component names its glyph in every use: remove optional"
        #expect(
            problems(
                replacing("glyph: { type: icons }", with: "glyph: { type: icons, optional: true }", in: viewFixture),
                source: viewSource) == ["options.glyph.optional: \(message)"])
        // optional: false is the default, and allowed anywhere.
        #expect(
            problems(
                replacing("glyph: { type: icons }", with: "glyph: { type: icons, optional: false }", in: viewFixture),
                source: viewSource) == [])
    }

    @Test("reading: the option is read as optional")
    func reading() throws {
        let contract = try ComponentContract(yaml: fieldFixture, source: fieldSource)
        #expect(contract.options.map(\.kind).suffix(2) == [.icons(optional: true), .icons(optional: true)])
        let required = try ComponentContract(yaml: viewFixture, source: viewSource)
        #expect(required.options.map(\.kind) == [.icons(optional: false)])
    }

    @Test("generation: an optional glyph is a labeled Westron.Icon? = nil, in the contract's order, given to the style")
    func overload() throws {
        let swift = try generated()
        #expect(swift.contains("leadingIcon: Westron.Icon? = nil"), "\(swift)")
        #expect(swift.contains("trailingIcon: Westron.Icon? = nil"))
        let signature = try #require(swift.range(of: "public func textFieldStyle("))
        let body = swift[signature.lowerBound...]
        let variant = try #require(body.range(of: "_ variant: TextFieldVariant"))
        let size = try #require(body.range(of: "size: TextFieldSize? = nil"))
        let leading = try #require(body.range(of: "leadingIcon: Westron.Icon? = nil"))
        let trailing = try #require(body.range(of: "trailingIcon: Westron.Icon? = nil"))
        #expect(variant.lowerBound < size.lowerBound)
        #expect(size.lowerBound < leading.lowerBound)
        #expect(leading.lowerBound < trailing.lowerBound)
        #expect(swift.contains("let style = TextFieldVariantStyle("))
        #expect(
            swift.contains("        leadingIcon: leadingIcon,\n            trailingIcon: trailingIcon)"), "\(swift)")
        // Its parameter documentation names the registry's type and the default.
        #expect(swift.contains("A name of `Westron.Icon`; by default `nil`, none."))
        // Not an enum of westron's: the registry's type is the icon generator's.
        #expect(!swift.contains("enum TextFieldLeadingIcon"))
    }

    @Test("the matrix: an optional glyph is no axis, and needs no registry")
    func matrix() throws {
        let contract = try ComponentContract(yaml: fieldFixture, source: fieldSource)
        let matrix = try SnapshotMatrix(contract, source: fieldSource)
        #expect(matrix.axes.map(\.name) == ["variant", "size"])
        #expect(matrix.optionCombinations == 6)
        #expect(matrix.combinations.count == 18)
        let hasIconAxis = matrix.axes.contains { $0.isIcons }
        #expect(!hasIconAxis)
        let files = try AppleSnapshotMatrix.files(for: [(contract, fieldSource)])
        #expect(files.contains { $0.path.hasSuffix("TextField+Matrix.swift") })
        let swift = try #require(files.first { $0.path.hasSuffix("TextField+Matrix.swift") }).contents
        #expect(!swift.contains("leadingIcon"))
    }

    @Test("the lint expects the arguments: the generated file passes, one without a glyph's argument fails")
    func lintExpectsTheArguments() throws {
        let swift = try generated()
        #expect(try lint(generated: swift) == [])
        // A hand edit that drops the trailing glyph's argument is reported, not skipped.
        let dropped = swift.replacingOccurrences(of: ", trailingIcon: Westron.Icon? = nil", with: "")
            .replacingOccurrences(of: "trailingIcon: Westron.Icon? = nil", with: "")
        #expect(dropped != swift)
        let found = try lint(generated: dropped)
        #expect(!found.isEmpty)
        #expect(found.contains { $0.contains("textFieldStyle") }, "\(found)")
        // A glyph of another type is reported too.
        let retyped = swift.replacingOccurrences(
            of: "leadingIcon: Westron.Icon? = nil", with: "leadingIcon: String? = nil")
        #expect(retyped != swift)
        let retypedFound = try lint(generated: retyped)
        #expect(retypedFound.contains { $0.contains("textFieldStyle") }, "\(retypedFound)")
    }
}
