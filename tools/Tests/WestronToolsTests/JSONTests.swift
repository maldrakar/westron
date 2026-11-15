import Foundation
import Testing
import WestronTools

@Suite("JSON reader")
struct JSONTests {
    @Test("reads every kind of value and keeps object members in document order")
    func valuesAndOrder() throws {
        let json = try JSON.parse(
            #"{ "z": 1, "a": [true, false, null], "m": { "y": "text", "b": -0.5e2 }, "e": {}, "x": [] }"#)
        #expect(
            json
                == .object([
                    .init("z", .number(1)),
                    .init("a", .array([.bool(true), .bool(false), .null])),
                    .init("m", .object([.init("y", .string("text")), .init("b", .number(-50))])),
                    .init("e", .object([])),
                    .init("x", .array([])),
                ]))
        #expect(json.members?.map(\.key) == ["z", "a", "m", "e", "x"])
        #expect(json["m"]?["y"]?.string == "text")
        #expect(json["missing"] == nil)
    }

    @Test("decodes escapes, including surrogate pairs, and skips a byte order mark")
    func escapesAndBOM() throws {
        #expect(try JSON.parse(#""a\"b\\c\/d\n\té😀""#) == .string("a\"b\\c/d\n\té😀"))
        #expect(try JSON.parse(Data([0xEF, 0xBB, 0xBF] + Array("[1]".utf8))) == .array([.number(1)]))
    }

    @Test("a duplicate key is an error at the second key")
    func duplicateKey() {
        let error = #expect(throws: JSON.SyntaxError.self) {
            try JSON.parse("{\n  \"a\": 1,\n  \"a\": 2\n}")
        }
        #expect(error?.message == #"duplicate key "a""#)
        #expect(error?.line == 3)
        #expect(error?.column == 3)
    }

    @Test(
        "rejects what RFC 8259 does not allow",
        arguments: [
            "", "{", "[1,]", "{\"a\" 1}", "{a: 1}", "01", "1.", ".5", "+1", "1e", "NaN", "tru", "\"a", "[1] 2",
            "\"\u{1}\"", #""\x""#, #""\ud800""#, #""\udc00""#, "1e400", "'a'",
        ])
    func rejects(_ text: String) {
        #expect(throws: JSON.SyntaxError.self) { try JSON.parse(text) }
    }

    @Test("rejects a string that is not valid UTF-8")
    func invalidUTF8() {
        #expect(throws: JSON.SyntaxError.self) { try JSON.parse(Data([0x22, 0xFF, 0x22])) }
    }

    @Test("rejects nesting deeper than its limit instead of overflowing the stack")
    func depthLimit() {
        #expect(throws: JSON.SyntaxError.self) { try JSON.parse(String(repeating: "[", count: 100_000)) }
    }
}
