/// Why a value could not be read. A nil `kind` means a referenced token failed and its own error is already
/// reported, so this one is not.
struct ValueFailure: Error {
    let kind: TokenError.Kind?
    let message: String

    init(_ kind: TokenError.Kind?, _ message: String) {
        self.kind = kind
        self.message = message
    }
}

/// Reads a `$value` of a known type into a `TokenValue`.
///
/// DTCG allows a curly-brace reference inside a value only as a sub-value of a composite type (Format, 9): a
/// typography, shadow or transition property, an element of a shadow list. Such a reference goes to `resolve`, which
/// returns the referenced token's value; it must be of the expected type. Anywhere else a reference is an error.
struct ValueDecoder {
    /// The value of the token at `reference`, which must be of `type`; `location` is where the reference is written.
    typealias Resolve = (_ reference: TokenPath, _ type: TokenType, _ location: String) throws -> TokenValue

    let resolve: Resolve

    /// A decoder for checking syntax before references can be resolved: each reference stands for a placeholder
    /// value of the expected type.
    static var syntaxOnly: ValueDecoder { ValueDecoder { _, type, _ in .placeholder(type) } }

    func decode(_ json: JSON, as type: TokenType, at location: String = "$value") throws -> TokenValue {
        switch type {
        case .color: .color(try color(json, at: location))
        case .dimension: .dimension(try dimension(json, at: location))
        case .number: .number(try number(json, at: location))
        case .duration: .duration(try duration(json, at: location))
        case .cubicBezier: .cubicBezier(try cubicBezier(json, at: location))
        case .fontFamily: .fontFamily(try fontFamily(json, at: location))
        case .fontWeight: .fontWeight(try fontWeight(json, at: location))
        case .typography: .typography(try typography(json, at: location))
        case .shadow: .shadow(try shadow(json, at: location))
        case .transition: .transition(try transition(json, at: location))
        }
    }

    // MARK: - Simple types

    private func color(_ json: JSON, at location: String) throws -> TokenValue.Color {
        let members = try object(
            json, at: location, required: ["colorSpace", "components"], optional: ["alpha", "hex"])
        let spaceName = try string(members["colorSpace"]!, at: location + ".colorSpace")
        guard let space = TokenValue.Color.Space(rawValue: spaceName) else {
            throw ValueFailure(.invalidValue, "\(location).colorSpace: unknown color space \"\(spaceName)\"")
        }
        guard case .array(let elements) = members["components"]! else {
            throw mismatch("an array", members["components"]!, at: location + ".components")
        }
        let ranges = space.componentRanges
        guard elements.count == ranges.count else {
            throw ValueFailure(
                .invalidValue,
                "\(location).components: \(space.rawValue) has \(ranges.count) components, found \(elements.count)")
        }
        var components: [TokenValue.Color.Component] = []
        for (index, (element, range)) in zip(elements, ranges).enumerated() {
            let componentLocation = "\(location).components[\(index)]"
            if element == .string("none") {
                components.append(.none)
                continue
            }
            let value = try number(element, at: componentLocation, expected: "a number or \"none\"")
            guard range.contains(value) else {
                throw ValueFailure(
                    .invalidValue,
                    "\(componentLocation): \(format(value)) is outside \(range.text) for \(space.rawValue)")
            }
            components.append(.number(value))
        }
        var alpha = 1.0
        if let json = members["alpha"] {
            alpha = try number(json, at: location + ".alpha")
            guard (0...1).contains(alpha) else {
                throw ValueFailure(.invalidValue, "\(location).alpha: \(format(alpha)) is outside [0, 1]")
            }
        }
        var hex: String?
        if let json = members["hex"] {
            let text = try string(json, at: location + ".hex")
            guard text.utf8.count == 7, text.first == "#", text.utf8.dropFirst().allSatisfy(JSON.isASCIIHexDigit) else {
                throw ValueFailure(
                    .invalidValue, "\(location).hex: expected #rrggbb (six hex digits), found \"\(text)\"")
            }
            hex = text
        }
        return TokenValue.Color(colorSpace: space, components: components, alpha: alpha, hex: hex)
    }

    private func dimension(_ json: JSON, at location: String) throws -> TokenValue.Dimension {
        let members = try object(json, at: location, required: ["value", "unit"])
        let value = try number(members["value"]!, at: location + ".value")
        let unitName = try string(members["unit"]!, at: location + ".unit")
        guard let unit = TokenValue.Dimension.Unit(rawValue: unitName) else {
            throw ValueFailure(.invalidValue, "\(location).unit: a dimension unit is px or rem, found \"\(unitName)\"")
        }
        return TokenValue.Dimension(value, unit)
    }

    private func duration(_ json: JSON, at location: String) throws -> TokenValue.Duration {
        let members = try object(json, at: location, required: ["value", "unit"])
        let value = try number(members["value"]!, at: location + ".value")
        let unitName = try string(members["unit"]!, at: location + ".unit")
        guard let unit = TokenValue.Duration.Unit(rawValue: unitName) else {
            throw ValueFailure(.invalidValue, "\(location).unit: a duration unit is ms or s, found \"\(unitName)\"")
        }
        return TokenValue.Duration(value, unit)
    }

    private func cubicBezier(_ json: JSON, at location: String) throws -> TokenValue.CubicBezier {
        guard case .array(let elements) = json else { throw mismatch("an array of four numbers", json, at: location) }
        guard elements.count == 4 else {
            throw ValueFailure(.invalidValue, "\(location): expected four numbers, found \(elements.count)")
        }
        var points: [Double] = []
        for (index, element) in elements.enumerated() {
            let value = try number(element, at: "\(location)[\(index)]")
            if index % 2 == 0, !(0...1).contains(value) {
                throw ValueFailure(
                    .invalidValue, "\(location)[\(index)]: an x coordinate must be in [0, 1], found \(format(value))")
            }
            points.append(value)
        }
        return TokenValue.CubicBezier(points[0], points[1], points[2], points[3])
    }

    private func fontFamily(_ json: JSON, at location: String) throws -> [String] {
        switch json {
        case .string(let name):
            return [try fontName(name, at: location)]
        case .array(let elements):
            guard !elements.isEmpty else {
                throw ValueFailure(.invalidValue, "\(location): a font family list cannot be empty")
            }
            return try elements.enumerated().map { index, element in
                let elementLocation = "\(location)[\(index)]"
                return try fontName(try string(element, at: elementLocation), at: elementLocation)
            }
        default:
            throw mismatch("a font name or a list of font names", json, at: location)
        }
    }

    private func fontName(_ name: String, at location: String) throws -> String {
        // A whole fontFamily value that is a reference never gets here; inside a list a reference is not allowed.
        if name.hasPrefix("{") || name.hasSuffix("}") {
            throw ValueFailure(
                .invalidValue, "\(location): a reference is not allowed inside a font family list, found \"\(name)\"")
        }
        guard !name.isEmpty else { throw ValueFailure(.invalidValue, "\(location): a font name cannot be empty") }
        return name
    }

    private func fontWeight(_ json: JSON, at location: String) throws -> TokenValue.FontWeight {
        switch json {
        case .number(let value):
            guard (1...1000).contains(value) else {
                throw ValueFailure(
                    .invalidValue, "\(location): a font weight must be in [1, 1000], found \(format(value))")
            }
            return TokenValue.FontWeight(value)
        case .string(let name):
            if let value = TokenValue.FontWeight.names[name] { return TokenValue.FontWeight(value, name: name) }
            throw ValueFailure(
                .invalidValue,
                "\(location): unknown font weight \"\(name)\"; the names are "
                    + TokenValue.FontWeight.names.keys.sorted().joined(separator: ", "))
        default:
            throw mismatch("a number in [1, 1000] or a font weight name", json, at: location)
        }
    }

    // MARK: - Composite types

    private func typography(_ json: JSON, at location: String) throws -> TokenValue.Typography {
        let members = try object(
            json, at: location, required: ["fontFamily", "fontSize", "fontWeight", "letterSpacing", "lineHeight"])
        guard
            case .fontFamily(let family) = try subValue(
                members["fontFamily"]!, .fontFamily, at: location + ".fontFamily"),
            case .dimension(let size) = try subValue(members["fontSize"]!, .dimension, at: location + ".fontSize"),
            case .fontWeight(let weight) = try subValue(
                members["fontWeight"]!, .fontWeight, at: location + ".fontWeight"),
            case .dimension(let spacing) = try subValue(
                members["letterSpacing"]!, .dimension, at: location + ".letterSpacing"),
            case .number(let lineHeight) = try subValue(members["lineHeight"]!, .number, at: location + ".lineHeight")
        else { throw ValueFailure(.typeMismatch, "\(location): a reference resolved to a value of another type") }
        return TokenValue.Typography(
            fontFamily: family, fontSize: size, fontWeight: weight, letterSpacing: spacing, lineHeight: lineHeight)
    }

    private func shadow(_ json: JSON, at location: String) throws -> [TokenValue.Shadow] {
        guard case .array(let elements) = json else { return [try shadowLayer(json, at: location)] }
        guard !elements.isEmpty else { throw ValueFailure(.invalidValue, "\(location): a shadow list cannot be empty") }
        return try elements.enumerated().map { index, element in
            let elementLocation = "\(location)[\(index)]"
            guard case .string(let text) = element, let path = try reference(text, at: elementLocation) else {
                return try shadowLayer(element, at: elementLocation)
            }
            // A reference in a list stands for one shadow; the list is not flattened (Format, 9.1).
            guard case .shadow(let layers) = try resolve(path, .shadow, elementLocation) else {
                throw ValueFailure(.typeMismatch, "\(elementLocation): {\(path)} is not a shadow")
            }
            guard layers.count == 1 else {
                throw ValueFailure(
                    .typeMismatch,
                    "\(elementLocation): a reference in a shadow list must point to a single shadow, "
                        + "{\(path)} has \(layers.count) layers")
            }
            return layers[0]
        }
    }

    private func shadowLayer(_ json: JSON, at location: String) throws -> TokenValue.Shadow {
        let members = try object(
            json, at: location, required: ["color", "offsetX", "offsetY", "blur", "spread"], optional: ["inset"])
        guard
            case .color(let color) = try subValue(members["color"]!, .color, at: location + ".color"),
            case .dimension(let offsetX) = try subValue(members["offsetX"]!, .dimension, at: location + ".offsetX"),
            case .dimension(let offsetY) = try subValue(members["offsetY"]!, .dimension, at: location + ".offsetY"),
            case .dimension(let blur) = try subValue(members["blur"]!, .dimension, at: location + ".blur"),
            case .dimension(let spread) = try subValue(members["spread"]!, .dimension, at: location + ".spread")
        else { throw ValueFailure(.typeMismatch, "\(location): a reference resolved to a value of another type") }
        var inset = false
        if let json = members["inset"] {
            guard case .bool(let value) = json else { throw mismatch("true or false", json, at: location + ".inset") }
            inset = value
        }
        return TokenValue.Shadow(
            color: color, offsetX: offsetX, offsetY: offsetY, blur: blur, spread: spread, inset: inset)
    }

    private func transition(_ json: JSON, at location: String) throws -> TokenValue.Transition {
        let members = try object(json, at: location, required: ["duration", "delay", "timingFunction"])
        guard
            case .duration(let duration) = try subValue(members["duration"]!, .duration, at: location + ".duration"),
            case .duration(let delay) = try subValue(members["delay"]!, .duration, at: location + ".delay"),
            case .cubicBezier(let curve) = try subValue(
                members["timingFunction"]!, .cubicBezier, at: location + ".timingFunction")
        else { throw ValueFailure(.typeMismatch, "\(location): a reference resolved to a value of another type") }
        return TokenValue.Transition(duration: duration, delay: delay, timingFunction: curve)
    }

    /// A sub-value of a composite type: a reference to a token of `type`, or a value of that type.
    private func subValue(_ json: JSON, _ type: TokenType, at location: String) throws -> TokenValue {
        if case .string(let text) = json, let path = try reference(text, at: location) {
            return try resolve(path, type, location)
        }
        return try decode(json, as: type, at: location)
    }

    // MARK: - JSON helpers

    private func reference(_ text: String, at location: String) throws -> TokenPath? {
        do throws(Reference.Problem) {
            return try Reference.parse(text)
        } catch {
            throw error.failure(at: location)
        }
    }

    /// The members of a value object. A `$ref` member is a JSON Pointer reference, which westron does not support.
    private func object(
        _ json: JSON, at location: String, required: [String], optional: [String] = []
    ) throws -> [String: JSON] {
        guard case .object(let list) = json else { throw mismatch("an object", json, at: location) }
        if list.contains(where: { $0.key == "$ref" }) {
            throw ValueFailure(.unsupported, "\(location): \(Unsupported.pointer)")
        }
        var members: [String: JSON] = [:]
        for member in list {
            guard required.contains(member.key) || optional.contains(member.key) else {
                throw ValueFailure(
                    .unknownProperty,
                    "\(location): unknown property \"\(member.key)\"; allowed: "
                        + (required + optional).joined(separator: ", "))
            }
            members[member.key] = member.value
        }
        for key in required where members[key] == nil {
            throw ValueFailure(.invalidValue, "\(location): missing \"\(key)\"")
        }
        return members
    }

    private func number(_ json: JSON, at location: String, expected: String = "a number") throws -> Double {
        guard case .number(let value) = json else { throw mismatch(expected, json, at: location) }
        return value
    }

    private func string(_ json: JSON, at location: String) throws -> String {
        guard case .string(let value) = json else { throw mismatch("a string", json, at: location) }
        return value
    }

    /// A value of the wrong JSON type. A reference where none is allowed gets its own explanation.
    private func mismatch(_ expected: String, _ json: JSON, at location: String) -> ValueFailure {
        if case .string(let text) = json, text.hasPrefix("{"), text.hasSuffix("}") {
            return ValueFailure(
                .invalidValue,
                "\(location): a reference is allowed only as a whole $value or as a sub-value of a composite type "
                    + "(typography, shadow, transition), found \"\(text)\"")
        }
        if case .object(let list) = json, list.contains(where: { $0.key == "$ref" }) {
            return ValueFailure(.unsupported, "\(location): \(Unsupported.pointer)")
        }
        return ValueFailure(.invalidValue, "\(location): expected \(expected), found \(json.typeName)")
    }

    /// A number for a message: `2`, not `2.0`.
    private func format(_ value: Double) -> String {
        value == value.rounded() && abs(value) < 1e15 ? String(Int(value)) : String(value)
    }
}

extension TokenValue {
    /// A value of a type, standing for a reference while only the syntax around it is checked.
    static func placeholder(_ type: TokenType) -> TokenValue {
        let zero = Dimension(0, .px)
        let black = Color(colorSpace: .srgb, components: [.number(0), .number(0), .number(0)])
        return switch type {
        case .color: .color(black)
        case .dimension: .dimension(zero)
        case .number: .number(0)
        case .duration: .duration(Duration(0, .ms))
        case .cubicBezier: .cubicBezier(CubicBezier(0, 0, 1, 1))
        case .fontFamily: .fontFamily(["placeholder"])
        case .fontWeight: .fontWeight(FontWeight(400))
        case .typography:
            .typography(
                Typography(
                    fontFamily: ["placeholder"], fontSize: zero, fontWeight: FontWeight(400), letterSpacing: zero,
                    lineHeight: 1))
        case .shadow: .shadow([Shadow(color: black, offsetX: zero, offsetY: zero, blur: zero, spread: zero)])
        case .transition:
            .transition(
                Transition(duration: Duration(0, .ms), delay: Duration(0, .ms), timingFunction: CubicBezier(0, 0, 1, 1))
            )
        }
    }
}
