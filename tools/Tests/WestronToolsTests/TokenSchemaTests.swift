import Foundation
import Testing
import WestronTools

/// A fixture of the official DTCG test suite (`Fixtures/dtcg-test-suite/`).
struct SuiteCase: Sendable, CustomTestStringConvertible {
    /// `format` or `resolver`.
    let module: String
    let id: String
    let input: String
    /// The fixture is valid DTCG.
    let positive: Bool
    /// The schema alone cannot decide it: references, type inheritance or `$extends` must be processed first.
    let needsPreprocessing: Bool

    var testDescription: String { id }

    func data() throws -> Data { try fixtureData("dtcg-test-suite/\(module)/\(input)") }

    /// The format module's fixtures.
    static let all = cases("format")

    /// The fixtures of a module, from its manifest.
    static func cases(_ module: String) -> [SuiteCase] {
        let manifest = try! JSON.parse(fixtureData("dtcg-test-suite/\(module)/manifest.json"))
        guard case .array(let tests) = manifest["tests"] else { fatalError("the manifest has no tests") }
        return tests.map { test in
            let features: [String] =
                if case .array(let list) = test["features"] { list.compactMap(\.string) } else { [] }
            return SuiteCase(
                module: module, id: test["id"]!.string!, input: test["input"]!.string!,
                positive: test["type"]?.string == "PositiveEvaluationTest",
                needsPreprocessing: features.contains("preprocessing-required"))
        }
    }
}

@Suite("DTCG schema and test suite")
struct TokenSchemaTests {
    /// Invalid fixtures the schema lets through, because swift-json-schema 0.15 reads the draft-07 DTCG schemas as
    /// draft 2020-12 (see `TokenSchema`). The reader rejects each of them (`readerRejectsEveryInvalidFixture`).
    static let schemaGaps: Set<String> = [
        // Tuple-form `items` is ignored: no range or type check per color component or cubic Bézier coordinate.
        "color-component-out-of-range", "color-mixed-none-and-invalid", "color-negative-component",
        "color-hsl-hue-equals-360", "color-hsl-negative-lightness", "color-hsl-saturation-over-100",
        "color-lab-lightness-over-100", "color-lch-negative-chroma", "color-oklab-lightness-over-1",
        "color-oklch-hue-equals-360", "cubicBezier-negative-x", "cubicBezier-string-value",
        "cubicBezier-x-out-of-range", "reference-cubicBezier-curly-brace-in-subvalue",
        // `format` only annotates in 2020-12: the JSON Pointer syntax of `$ref` is not checked.
        "reference-json-pointer-mixed-ref-syntax", "reference-json-pointer-space-in-path",
    ]

    /// Valid DTCG fixtures outside westron's subset: the reader rejects them, and only as unsupported.
    static let outsideSubset: Set<String> = [
        // Types westron does not support.
        "border-basic", "border-custom-dash", "border-dashed", "gradient-basic", "gradient-three-stop",
        "gradient-single-stop", "gradient-missing-start", "strokeStyle-solid", "strokeStyle-dashed",
        "strokeStyle-dotted", "strokeStyle-double", "strokeStyle-groove", "strokeStyle-ridge", "strokeStyle-inset",
        "strokeStyle-outset", "strokeStyle-custom-dash", "strokeStyle-custom-dash-butt-cap",
        "strokeStyle-custom-dash-square-cap",
        // $root and $extends.
        "group-root-token", "group-extends", "group-extends-nested-override", "group-multi-level-extends",
        // JSON Pointer references ($ref), often together with the types above.
        "reference-json-pointer-basic", "reference-json-pointer-subproperty", "reference-color-components-array-ref",
        "reference-strokestyle-dasharray-ref", "reference-color-components-ref-hsl",
        "reference-composite-subvalue-refs", "reference-nested-composite-refs", "reference-cross-composite-refs",
        "reference-multi-source-composite", "reference-gradient-array-refs", "reference-typography-property-refs",
    ]

    @Test("a valid file passes; an invalid one fails where the problem is")
    func validAndInvalid() throws {
        let schema = try officialSchema()
        for file in ["tokens/types.tokens.json", "tokens/aliases.tokens.json"] {
            let violations = try schema.validate(fixtureData(file))
            #expect(violations == [], "\(file)")
        }
        let violations = try schema.validate(Data(token("dimension", #"{ "value": 8, "unit": "pt" }"#).utf8))
        #expect(!violations.isEmpty)
        #expect(violations.allSatisfy { $0.instanceLocation.hasPrefix("/t/$value") })
        #expect(violations.contains { $0.message.contains("\"pt\"") })
    }

    /// A defect of the official schema, not of the validator: for a `$value` without its own `$type`, the schema
    /// requires exactly one type to match (`oneOf`), and a font weight name such as "bold" is also a valid font family
    /// name. So in westron files a font weight name carries its own `$type` (Tokens/README.md). If this test fails,
    /// the schema was fixed upstream and the rule can go.
    @Test("a font weight name whose type comes from its group fails the official schema; the reader accepts it")
    func inheritedFontWeightNameDefect() throws {
        let inherited = #"{ "weight": { "$type": "fontWeight", "bold": { "$value": "bold" } } }"#
        let violations = try officialSchema().validate(Data(inherited.utf8))
        #expect(!violations.isEmpty)
        #expect(violations.allSatisfy { $0.instanceLocation == "/weight/bold/$value" })
        #expect(problems(inherited) == [])
        let own = #"{ "weight": { "$type": "fontWeight", "bold": { "$type": "fontWeight", "$value": "bold" } } }"#
        #expect(try officialSchema().validate(Data(own.utf8)) == [])
    }

    @Test("a name the schema does not allow is reported at its location")
    func invalidName() throws {
        let violations = try officialSchema().validate(Data(#"{ "a.b": { "$type": "number", "$value": 1 } }"#.utf8))
        #expect(violations.map(\.instanceLocation) == ["/a.b"])
    }

    @Test("a directory without the format schema cannot be loaded")
    func missingSchema() {
        #expect(throws: TokenSchema.LoadError.self) {
            try TokenSchema(directory: fixture("tokens/theme").path)
        }
    }

    @Test("the schema agrees with the DTCG test suite except for the known gaps of the validator")
    func schemaConformance() throws {
        let schema = try officialSchema()
        var disagreements: Set<String> = []
        for test in SuiteCase.all where !test.needsPreprocessing {
            let valid = try schema.validate(test.data()).isEmpty
            if valid != test.positive { disagreements.insert(test.id) }
        }
        #expect(disagreements == Self.schemaGaps)
    }

    @Test("the reader rejects every invalid fixture, including those the schema lets through")
    func readerRejectsEveryInvalidFixture() throws {
        var accepted: [String] = []
        for test in SuiteCase.all where !test.positive {
            do {
                _ = try TokenTree.load(test.data(), source: test.input).resolve()
                accepted.append(test.id)
            } catch is TokenErrors {}
        }
        #expect(accepted == [])
    }

    @Test("the reader accepts every valid fixture in the subset and rejects the others only as unsupported")
    func readerOnValidFixtures() throws {
        var rejected: Set<String> = []
        for test in SuiteCase.all where test.positive {
            do {
                _ = try TokenTree.load(test.data(), source: test.input).resolve()
            } catch let errors as TokenErrors {
                rejected.insert(test.id)
                let kinds = Set(errors.errors.map(\.kind))
                #expect(kinds == [.unsupported], "\(test.id): \(errors)")
            }
        }
        #expect(rejected == Self.outsideSubset)
    }
}
