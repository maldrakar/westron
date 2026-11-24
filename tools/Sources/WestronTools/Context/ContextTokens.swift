import Foundation

/// The token pages of the agent context (`AgentContext`): every semantic token a product lays its own views out
/// with (decisions/0014 leaves composition to products), how SwiftUI reaches it, and what it is for. The names and the
/// Swift members are the Apple token generator's (`AppleTokenModel`), so a page cannot name an accessor WestronUI does
/// not have; the adapters that take them are the reviewed ones of `WestronUI/TokenAdapters.swift`
/// (`APIParity.adapters`). Every name the pages' own prose writes is a placeholder that `ContextNames` looks up.
enum ContextTokens {
    struct Page {
        /// Inside the bundle.
        let path: String
        let title: String
        /// One line for the index.
        let summary: String
        let contents: String
    }

    typealias Doc = AppleTokenModel.Doc

    /// One token: its path, its Swift member as SwiftUI writes it after a dot, its value where it helps to choose,
    /// and its doc.
    struct Entry {
        let path: TokenPath
        let swift: String
        let value: String?
        let doc: Doc
    }

    /// - Throws: `ContextNames.Missing` when the prose names a token or an adapter WestronUI does not declare.
    static func pages(_ model: AppleTokenModel, names: ContextNames) throws -> [Page] {
        var pages: [Page] = []
        let colors = model.colors.map {
            Entry(path: $0.path, swift: AppleTokensSwift.reference($0.members), value: nil, doc: $0.doc)
        }
        var colorBody = section(colors, depth: 2)
        var categoryCount = 0
        if let categories = model.categories {
            categoryCount = categories.categories.count
            colorBody += ["", "## List colors: `\(categories.group)`", ""]
            colorBody += ContextMarkdown.wrap(
                try names.fill(
                    "A list's color is a `Westron.Category`, kept by its name and read back with "
                        + "`Westron.Category(rawValue: list.color)`: "
                        + categories.categories.map { "`\($0.rawValue)`" }.joined(separator: ", ") + ". "
                        + "`.{api:category}(_:)` on a control or on any view around it draws in that color the westron "
                        + "controls that read it, whose cards show it in their call; nil keeps each control's own "
                        + "default. A product's own drawing reads a role of the category, a `Westron.Color`, by what "
                        + "the call draws: `.{adapter:View.foregroundStyle}(category.{category:text})` for text, "
                        + "`.{adapter:View.background}(category.{category:background})` for a ground. The roles:"))
            colorBody.append("")
            for role in categories.roles {
                colorBody += ContextMarkdown.item("`.\(role.name)`: " + text(role.doc))
            }
        }
        pages.append(
            page(
                "tokens/color.md", title: "Colors",
                summary: try names.fill(
                    "\(model.colors.count) semantic colors, `Westron.Color`: "
                        + "`.{adapter:View.foregroundStyle}(.{token:color.text.primary})`, "
                        + "`.{adapter:View.background}(.{token:color.background.surface})`; \(categoryCount) list "
                        + "colors, `Westron.Category`"),
                intro: try names.fill(
                    "A semantic color is a `Westron.Color`, named after its path without `color.`: "
                        + "`color.text.primary` is `.{token:color.text.primary}`. WestronUI takes one where SwiftUI "
                        + "takes a color: `.{adapter:View.foregroundStyle}(.{token:color.text.primary})`, "
                        + "`.{adapter:View.background}(.{token:color.background.surface})`, "
                        + "`.{adapter:View.background}(.{token:color.background.muted}, in: Capsule())`, "
                        + "`.{adapter:View.tint}(.{token:color.text.accent})`, "
                        + "`shape.{adapter:Shape.fill}(.{token:color.background.surface})`, "
                        + "`shape.{adapter:Shape.stroke}(.{token:color.border.default}, lineWidth: "
                        + ".{token:stroke.thin})`, `shape.{adapter:InsettableShape.strokeBorder}(…)`, "
                        + "`Text(…).{adapter:Text.foregroundStyle}(…)`, and `Color(.{token:color.text.primary})` "
                        + "where only a SwiftUI `Color` fits{!adapter:Color.init}. Each switches with the light and "
                        + "dark themes and increased contrast by itself. A color is chosen by its role, which its "
                        + "entry names (\"Use for\", \"Avoid\"); never a raw color, a hex value or an opacity laid on a "
                        + "token to make a new color. The design language: `../design-language/02-color.md`."),
                body: colorBody, model: model))

        let roles = model.textRoles.map { role in
            Entry(
                path: role.path, swift: AppleTokensSwift.reference(role.members),
                value: "\(role.textStyle), \(role.font ?? "the system font")", doc: role.doc)
        }
        pages.append(
            page(
                "tokens/typography.md", title: "Text roles",
                summary: try names.fill(
                    "\(roles.count) text roles, `Westron.TextRole`: `.{api:textRole}(.{token:typography.body.regular})`"
                ),
                intro: try names.fill(
                    "A text role is a `Westron.TextRole`, named after its path without `typography.`: "
                        + "`typography.body.regular` is `.{token:typography.body.regular}`. It sets a text's font and "
                        + "its tracking: `.{api:textRole}(.{token:typography.heading.medium})` on any view, and on a "
                        + "part of a text inside interpolation, `Text(\"\\(title) \\(Text(count).{api:textRole}("
                        + ".{token:typography.footnote.medium}))\")`. `Font(.{token:typography.body.regular})` is its "
                        + "font alone, without the tracking{!adapter:Font.init}. Each role follows Dynamic Type through "
                        + "its text style, named in its entry with the font it draws. A role is chosen by what the text "
                        + "is, never by its size; no `.font(.system(size:))` and no font of the product's own. A "
                        + "heading role does not make a heading for assistive technology: add "
                        + "`.accessibilityAddTraits(.isHeader)` where the screen has one. The design language: "
                        + "`../design-language/03-typography.md`."),
                body: section(roles, depth: 2), model: model))

        let dimensions = model.dimensions.map { scalar in
            Entry(
                path: scalar.path, swift: AppleTokensSwift.reference(scalar.members),
                value: values(scalar, unit: " pt"), doc: scalar.doc)
        }
        let numbers = model.numbers.map { scalar in
            Entry(
                path: scalar.path, swift: AppleTokensSwift.reference(scalar.members), value: values(scalar, unit: ""),
                doc: scalar.doc)
        }
        var layoutBody = section(dimensions, depth: 1)
        if !numbers.isEmpty {
            layoutBody += ["", "## Numbers, `Double`", ""]
            layoutBody += ContextMarkdown.wrap(
                try names.fill("`Double` statics{!adapter:Double.init}: `.opacity(.{token:opacity.disabled})`."))
            layoutBody += [""] + numbers.flatMap(item)
        }
        pages.append(
            page(
                "tokens/layout.md", title: "Space, size, radius, stroke and opacity",
                summary: try names.fill(
                    "\(dimensions.count) lengths, `CGFloat` in points: `.padding(.{token:space.card})`, "
                        + "`VStack(spacing: .{token:space.within-group})`, `.{token:radius.card}`, "
                        + "`.{token:stroke.thin}`, `.{token:size.target.minimum}`; \(numbers.count) "
                        + "number\(numbers.count == 1 ? "" : "s"), `Double`: `.{token:opacity.disabled}`"),
                intro: try names.fill(
                    "A length is a `CGFloat` static in points{!adapter:CGFloat.init}, named after its path: "
                        + "`space.card` is `.{token:space.card}`, the step `space.200` is `.{token:space.200}`: "
                        + "`.padding(.{token:space.card})`, `.padding(.horizontal, .{token:space.page.narrow})`, "
                        + "`VStack(spacing: .{token:space.within-group})`, `RoundedRectangle(cornerRadius: "
                        + ".{token:radius.card}, style: .continuous)`, "
                        + "`.frame(minHeight: .{token:size.target.minimum})`, `lineWidth: .{token:stroke.thin}`. A "
                        + "role name (`space.card`, `space.within-group`, `space.between-groups`, `space.page.narrow`, "
                        + "`radius.card`) comes before a step of the ladder, which is for a gap no role names"
                        + "{!token:space.between-groups}. A value that differs by platform is the current platform's, "
                        + "chosen when the product builds. Never a number of the product's own for a padding, a gap, a "
                        + "radius, a line or a size. The design language: `../design-language/06-layout.md`, "
                        + "`../design-language/04-shape.md`."),
                body: layoutBody, model: model))

        let transitions = model.transitions.map { transition in
            Entry(
                path: transition.path, swift: AppleTokensSwift.reference(transition.members),
                value: AppleTokensSwift.number(transition.duration) + " s"
                    + (transition.spring == nil ? "" : ", a spring"),
                doc: transition.doc)
        }
        let shadows = model.shadows.map {
            Entry(path: $0.path, swift: AppleTokensSwift.reference($0.members), value: nil, doc: $0.doc)
        }
        var motionBody: [String] = []
        if !transitions.isEmpty {
            motionBody += ["", "## Motion, `Animation`", ""]
            motionBody += ContextMarkdown.wrap(
                try names.fill(
                    "A motion is a SwiftUI `Animation` static{!adapter:Animation.init}, named after its path "
                        + "without `motion.`: `.animation(.{token:motion.fade}, value: isSelected)`, "
                        + "`withAnimation(.{token:motion.move}) { … }`. Never a duration, a curve or a spring of the "
                        + "product's own. The design language: `../design-language/05-motion.md`."))
            motionBody += [""] + transitions.flatMap(item)
        }
        if !shadows.isEmpty {
            motionBody += ["", "## Shadows, `Westron.Shadow`", ""]
            motionBody += ContextMarkdown.wrap(
                try names.fill(
                    "A shadow is a `Westron.Shadow`, named after its path without `shadow.`: "
                        + "`card.{adapter:View.shadow}(.{token:shadow.raised})`. It follows the theme. Never a "
                        + "`.shadow(color:radius:x:y:)` of the product's own."))
            motionBody += [""] + shadows.flatMap(item)
        }
        pages.append(
            page(
                "tokens/motion-and-shadow.md", title: "Motion and shadows",
                summary: try names.fill(
                    "\(transitions.count) motions, SwiftUI `Animation`: `.animation(.{token:motion.fade}, value: …)`; "
                        + "\(shadows.count) shadows, `Westron.Shadow`: "
                        + "`.{adapter:View.shadow}(.{token:shadow.raised})`"),
                intro: nil, body: motionBody, model: model))
        return pages
    }

    private static func page(
        _ path: String, title: String, summary: String, intro: String?, body: [String], model: AppleTokenModel
    ) -> Page {
        var out = ContextMarkdown.header([model.resolver])
        out += ["", "# \(title)", ""]
        out += ContextMarkdown.wrap(
            "From westron's semantic tokens, `import WestronUI`. Each entry: the token's path, its Swift member as "
                + "SwiftUI writes it after a dot, and what it is for.")
        if let intro { out += [""] + ContextMarkdown.wrap(intro) }
        out += body
        return Page(path: path, title: title, summary: summary, contents: out.joined(separator: "\n") + "\n")
    }

    /// The entries under a heading per group: the first `depth` names of the path.
    private static func section(_ entries: [Entry], depth: Int) -> [String] {
        var groups: [(name: String, entries: [Entry])] = []
        for entry in entries {
            let name = entry.path.names.prefix(depth).joined(separator: ".")
            if let index = groups.firstIndex(where: { $0.name == name }) {
                groups[index].entries.append(entry)
            } else {
                groups.append((name, [entry]))
            }
        }
        return groups.flatMap { group in ["", "## `\(group.name)`", ""] + group.entries.flatMap(item) }
    }

    private static func item(_ entry: Entry) -> [String] {
        var text = "`\(entry.path)` → `.\(entry.swift)`"
        if let value = entry.value { text += " (\(value))" }
        let doc = Self.text(entry.doc)
        if !doc.isEmpty { text += ": " + doc }
        return ContextMarkdown.item(text)
    }

    /// The description, then where to use the token and where not.
    static func text(_ doc: Doc) -> String {
        var parts: [String] = []
        if let description = doc.description { parts.append(description) }
        if let usage = doc.usage {
            parts.append("Use for: \(usage.use.joined(separator: ", ")). Avoid: \(usage.avoid)")
        }
        return parts.joined(separator: " ")
    }

    /// `16 pt`, or `iOS 36 pt, macOS 32 pt, watchOS 44 pt` where the platforms differ.
    static func values(_ scalar: AppleTokenModel.Scalar, unit: String) -> String {
        let base = scalar.values[0]
        guard scalar.values.count == AppleTokenModel.platforms.count, scalar.values.contains(where: { $0 != base })
        else { return AppleTokensSwift.number(base) + unit }
        return zip(AppleTokenModel.platforms, scalar.values).map { platform, value in
            "\(AppleComponents.osNames[platform]!) \(AppleTokensSwift.number(value))\(unit)"
        }.joined(separator: ", ")
    }
}
