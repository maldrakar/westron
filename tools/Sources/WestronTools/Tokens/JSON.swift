import Foundation

/// A JSON value that keeps object members in document order.
///
/// Token files are read with this type instead of `JSONSerialization`, which loses the order of keys and keeps only
/// one of two duplicate keys. Here groups and tokens stay in the order of the file, and a duplicate key is an error.
public indirect enum JSON: Equatable, Sendable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSON])
    /// Members in document order; keys are unique.
    case object([Member])

    public struct Member: Equatable, Sendable {
        public let key: String
        public let value: JSON

        public init(_ key: String, _ value: JSON) {
            self.key = key
            self.value = value
        }
    }

    /// The value of an object member, or nil if this is not an object or has no such key.
    public subscript(key: String) -> JSON? {
        guard case .object(let members) = self else { return nil }
        return members.first { $0.key == key }?.value
    }

    public var string: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    public var number: Double? {
        if case .number(let value) = self { return value }
        return nil
    }

    public var members: [Member]? {
        if case .object(let members) = self { return members }
        return nil
    }

    /// The JSON type name, for error messages.
    var typeName: String {
        switch self {
        case .null: "null"
        case .bool: "a boolean"
        case .number: "a number"
        case .string: "a string"
        case .array: "an array"
        case .object: "an object"
        }
    }
}

extension JSON {
    /// A document that is not valid JSON (RFC 8259), with the position of the problem.
    public struct SyntaxError: Error, Equatable, Sendable, CustomStringConvertible {
        public let line: Int
        public let column: Int
        public let message: String

        public var description: String { "\(line):\(column): \(message)" }
    }

    /// Parses a JSON document (RFC 8259). A UTF-8 byte order mark is skipped.
    /// - Throws: `SyntaxError`, also for a duplicate key in an object and for a number that a `Double` cannot hold.
    public static func parse(_ data: Data) throws -> JSON {
        var parser = Parser(bytes: Array(data))
        return try parser.document()
    }

    public static func parse(_ text: String) throws -> JSON {
        try parse(Data(text.utf8))
    }
}

extension JSON {
    /// `0-9`, `A-F` or `a-f` as one UTF-8 byte; JSON escapes and hex colors take only these (RFC 8259 §7).
    static func isASCIIHexDigit(_ byte: UInt8) -> Bool {
        (0x30...0x39).contains(byte) || (0x41...0x46).contains(byte) || (0x61...0x66).contains(byte)
    }
}

private struct Parser {
    let bytes: [UInt8]
    var index = 0
    var depth = 0
    /// Deeper documents are rejected instead of overflowing the stack. Token files nest about ten levels; the limit
    /// stays low enough for the small stacks of worker and test threads, also for the code that walks the result.
    static let maxDepth = 64

    init(bytes: [UInt8]) {
        self.bytes = bytes
    }

    mutating func document() throws -> JSON {
        if bytes.starts(with: [0xEF, 0xBB, 0xBF]) { index = 3 }
        skipWhitespace()
        let value = try value()
        skipWhitespace()
        guard index == bytes.count else { throw error("unexpected text after the end of the document") }
        return value
    }

    private mutating func value() throws -> JSON {
        guard let byte = peek else { throw error("unexpected end of the document") }
        switch byte {
        case ascii("{"): return try object()
        case ascii("["): return try array()
        case ascii("\""): return .string(try string())
        case ascii("t"):
            try literal("true")
            return .bool(true)
        case ascii("f"):
            try literal("false")
            return .bool(false)
        case ascii("n"):
            try literal("null")
            return .null
        case ascii("-"), ascii("0")...ascii("9"): return .number(try number())
        default: throw error("unexpected character")
        }
    }

    private mutating func object() throws -> JSON {
        try enter()
        defer { depth -= 1 }
        index += 1
        var members: [JSON.Member] = []
        // By code point, as JSON compares names; Swift `String` equality would merge canonically equivalent keys.
        var keys: Set<[UInt8]> = []
        skipWhitespace()
        if peek == ascii("}") {
            index += 1
            return .object([])
        }
        while true {
            skipWhitespace()
            guard peek == ascii("\"") else { throw error("expected a string key") }
            let keyStart = index
            let key = try string()
            guard keys.insert(Array(key.utf8)).inserted else { throw error("duplicate key \"\(key)\"", at: keyStart) }
            skipWhitespace()
            guard peek == ascii(":") else { throw error("expected ':' after a key") }
            index += 1
            skipWhitespace()
            members.append(JSON.Member(key, try value()))
            skipWhitespace()
            switch peek {
            case ascii(","): index += 1
            case ascii("}"):
                index += 1
                return .object(members)
            default: throw error("expected ',' or '}' in an object")
            }
        }
    }

    private mutating func array() throws -> JSON {
        try enter()
        defer { depth -= 1 }
        index += 1
        var elements: [JSON] = []
        skipWhitespace()
        if peek == ascii("]") {
            index += 1
            return .array([])
        }
        while true {
            skipWhitespace()
            elements.append(try value())
            skipWhitespace()
            switch peek {
            case ascii(","): index += 1
            case ascii("]"):
                index += 1
                return .array(elements)
            default: throw error("expected ',' or ']' in an array")
            }
        }
    }

    private mutating func string() throws -> String {
        let start = index
        index += 1
        var buffer: [UInt8] = []
        while true {
            guard let byte = peek else { throw error("unterminated string", at: start) }
            switch byte {
            case ascii("\""):
                index += 1
                var text = String.UnicodeScalarView()
                var iterator = buffer.makeIterator()
                var decoder = UTF8()
                while true {
                    switch decoder.decode(&iterator) {
                    case .scalarValue(let scalar): text.append(scalar)
                    case .emptyInput: return String(text)
                    case .error: throw error("a string is not valid UTF-8", at: start)
                    }
                }
            case ascii("\\"):
                index += 1
                try escape(into: &buffer)
            case 0x00..<0x20:
                throw error("a control character must be escaped in a string")
            default:
                buffer.append(byte)
                index += 1
            }
        }
    }

    private mutating func escape(into buffer: inout [UInt8]) throws {
        guard let byte = peek else { throw error("unterminated escape") }
        index += 1
        switch byte {
        case ascii("\""), ascii("\\"), ascii("/"): buffer.append(byte)
        case ascii("b"): buffer.append(0x08)
        case ascii("f"): buffer.append(0x0C)
        case ascii("n"): buffer.append(0x0A)
        case ascii("r"): buffer.append(0x0D)
        case ascii("t"): buffer.append(0x09)
        case ascii("u"):
            var code = try hex4()
            if (0xD800..<0xDC00).contains(code) {
                guard bytes[index...].starts(with: [ascii("\\"), ascii("u")]) else {
                    throw error("a high surrogate must be followed by a low surrogate")
                }
                index += 2
                let low = try hex4()
                guard (0xDC00..<0xE000).contains(low) else { throw error("invalid low surrogate") }
                code = 0x10000 + ((code - 0xD800) << 10) + (low - 0xDC00)
            } else if (0xDC00..<0xE000).contains(code) {
                throw error("a low surrogate without a high surrogate")
            }
            guard let scalar = Unicode.Scalar(code) else { throw error("invalid Unicode escape") }
            buffer.append(contentsOf: Array(String(Character(scalar)).utf8))
        default: throw error("invalid escape")
        }
    }

    private mutating func hex4() throws -> UInt32 {
        guard index + 4 <= bytes.count,
            bytes[index..<index + 4].allSatisfy(JSON.isASCIIHexDigit),
            let code = UInt32(String(decoding: bytes[index..<index + 4], as: UTF8.self), radix: 16)
        else { throw error("expected four hexadecimal digits after \\u") }
        index += 4
        return code
    }

    private mutating func number() throws -> Double {
        let start = index
        if peek == ascii("-") { index += 1 }
        if peek == ascii("0") {
            index += 1
        } else {
            guard digits() > 0 else { throw error("invalid number", at: start) }
        }
        if peek == ascii(".") {
            index += 1
            guard digits() > 0 else { throw error("invalid number: digits must follow '.'", at: start) }
        }
        if peek == ascii("e") || peek == ascii("E") {
            index += 1
            if peek == ascii("+") || peek == ascii("-") { index += 1 }
            guard digits() > 0 else { throw error("invalid number: digits must follow the exponent", at: start) }
        }
        let text = String(decoding: bytes[start..<index], as: UTF8.self)
        guard let value = Double(text), value.isFinite else { throw error("number out of range: \(text)", at: start) }
        return value
    }

    private mutating func digits() -> Int {
        let start = index
        while let byte = peek, (ascii("0")...ascii("9")).contains(byte) { index += 1 }
        return index - start
    }

    private mutating func literal(_ word: String) throws {
        guard bytes[index...].starts(with: Array(word.utf8)) else { throw error("unexpected character") }
        index += word.utf8.count
    }

    private mutating func enter() throws {
        depth += 1
        guard depth <= Self.maxDepth else { throw error("nesting deeper than \(Self.maxDepth) levels") }
    }

    private mutating func skipWhitespace() {
        while let byte = peek, byte == 0x20 || byte == 0x0A || byte == 0x0D || byte == 0x09 { index += 1 }
    }

    private var peek: UInt8? { index < bytes.count ? bytes[index] : nil }

    private func ascii(_ scalar: Unicode.Scalar) -> UInt8 { UInt8(ascii: scalar) }

    /// An error at a byte offset, with a 1-based line and a 1-based column counted in bytes.
    private func error(_ message: String, at offset: Int? = nil) -> JSON.SyntaxError {
        let offset = min(offset ?? index, bytes.count)
        let before = bytes[..<offset]
        let line = before.reduce(1) { $1 == 0x0A ? $0 + 1 : $0 }
        let lineStart = before.lastIndex(of: 0x0A).map { $0 + 1 } ?? 0
        return JSON.SyntaxError(line: line, column: offset - lineStart + 1, message: message)
    }
}
