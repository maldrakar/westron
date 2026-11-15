import Foundation
import Testing
import WestronTools

/// A small valid registry; tests replace parts of it.
let iconRegistryFixture = """
    # A comment.
    default: bullets

    icons:
      - name: tray
        description: An open tray.
        apple: tray
      - name: bullets
        description: Lines of text, each with a dot before it.
        apple: list.bullet
      - name: newWindow
        description: A window with a plus badge.
        apple: macwindow.badge.plus
    """

/// The problems of reading a registry written inline, as `line: message`.
private func problems(_ yaml: String, sourceLocation: SourceLocation = #_sourceLocation) -> [String] {
    do {
        _ = try IconRegistry(yaml: yaml, source: "icons.yaml")
        Issue.record("the registry was read without problems", sourceLocation: sourceLocation)
        return []
    } catch let problems as IconRegistry.Problems {
        return problems.problems.map { "\($0.line.map(String.init) ?? "-"): \($0.message)" }
    } catch {
        Issue.record("unexpected error: \(error)", sourceLocation: sourceLocation)
        return []
    }
}

/// The fixture with one text replaced, which must occur in it.
private func replacing(_ old: String, with new: String) -> String {
    precondition(iconRegistryFixture.contains(old), old)
    return iconRegistryFixture.replacingOccurrences(of: old, with: new)
}

@Suite("Icon registry")
struct IconRegistryTests {
    @Test("reads the icons in order, with the default")
    func valid() throws {
        let registry = try IconRegistry(yaml: iconRegistryFixture, source: "icons.yaml")
        #expect(
            registry
                == IconRegistry(
                    icons: [
                        .init(name: "tray", description: "An open tray.", apple: "tray"),
                        .init(
                            name: "bullets", description: "Lines of text, each with a dot before it.",
                            apple: "list.bullet"),
                        .init(
                            name: "newWindow", description: "A window with a plus badge.", apple: "macwindow.badge.plus"
                        ),
                    ],
                    fallback: "bullets"))
    }

    @Test("westron's registry: the pilot's 32 names, then the four statuses, with bullets for an unknown name")
    func realRegistry() throws {
        let file = repositoryRoot.appendingPathComponent(IconRegistry.defaultFile).path
        let registry = try IconRegistry.load(file: file)
        #expect(registry.icons.count == 36)
        #expect(registry.fallback == "bullets")
        #expect(
            registry.icons.map(\.name) == [
                "tray", "sun", "calendar", "week", "logbook", "trash", "briefcase", "house", "hourglass", "pen", "bag",
                "wrench", "book", "folder", "list", "bullets", "ellipsis", "plus", "check", "chevron", "grip",
                "magnifier", "microphone", "newWindow", "checkCircle", "divider", "flag", "hash", "note", "expand",
                "columns", "chevronLeft", "checkCircleFill", "xmarkCircleFill", "exclamationTriangleFill",
                "infoCircleFill",
            ])
        #expect(
            registry.icons.map(\.apple) == [
                "tray", "sun.max", "calendar", "calendar.badge.clock", "text.book.closed", "trash", "briefcase",
                "house",
                "hourglass", "pencil", "bag", "wrench", "book", "folder", "checklist", "list.bullet", "ellipsis",
                "plus",
                "checkmark", "chevron.down", "line.3.horizontal", "magnifyingglass", "mic", "macwindow.badge.plus",
                "checkmark.circle", "rectangle.split.1x2", "flag", "number", "note.text",
                "arrow.up.left.and.arrow.down.right", "rectangle.split.3x1", "chevron.left", "checkmark.circle.fill",
                "xmark.circle.fill", "exclamationmark.triangle.fill", "info.circle.fill",
            ])
    }

    @Test("a file that cannot be read is a problem")
    func unreadable() {
        #expect(throws: IconRegistry.Problems.self) { try IconRegistry.load(file: "no/such/icons.yaml") }
    }

    @Test("invalid YAML is a problem with its line")
    func syntax() {
        #expect(
            problems(replacing("  - name: tray", with: "  - name: [tray")).first?.hasPrefix("6: invalid YAML") == true)
    }

    @Test("a repeated key is a problem")
    func duplicateKey() {
        #expect(
            problems(replacing("apple: tray", with: "apple: tray\n    apple: tray")).map { $0.contains("\"apple\"") }
                == [true])
    }

    @Test("the registry must be a mapping with default and icons, and nothing else")
    func topLevel() {
        #expect(problems("- tray") == ["1: the registry must be a mapping with the keys default, icons"])
        #expect(problems("") == ["-: the registry must be a mapping with the keys default, icons"])
        #expect(
            problems(replacing("default: bullets", with: "default: bullets\nversion: 1")) == [
                "3: the registry: unknown key \"version\"; the keys are default, icons"
            ])
        #expect(problems(replacing("default: bullets", with: "")) == ["4: the registry: default is missing"])
        #expect(problems("default: bullets") == ["1: the registry: icons is missing"])
        #expect(problems("default: bullets\nicons: []") == ["2: icons must be a non-empty list"])
        #expect(problems("default: bullets\nicons: tray") == ["2: icons must be a non-empty list"])
    }

    @Test("default must name an icon of the registry")
    func defaultIcon() {
        #expect(
            problems(replacing("default: bullets", with: "default: dots")) == [
                "2: default names \"dots\", which is no icon of the registry"
            ])
        #expect(
            problems(replacing("default: bullets", with: "default: [bullets]")) == [
                "2: default must be a string; quote it if YAML reads it as another type"
            ])
    }

    @Test("an icon is a mapping of name, description and apple, and nothing else")
    func iconKeys() {
        #expect(
            problems(replacing("  - name: tray\n", with: "  - tray\n  - name: tray\n")) == [
                "5: icon 1: must be a mapping with the keys name, description, apple"
            ])
        #expect(
            problems(replacing("apple: tray", with: "apple: tray\n    web: inbox")) == [
                "8: icon \"tray\": unknown key \"web\"; the keys are name, description, apple"
            ])
        #expect(
            problems(replacing("    description: An open tray.\n", with: "")) == [
                "5: icon \"tray\": description is missing"
            ])
        #expect(problems(replacing("    apple: tray\n", with: "")) == ["5: icon \"tray\": apple is missing"])
        #expect(
            problems(replacing("  - name: tray\n    description", with: "  - description")) == [
                "5: icon 1: name is missing"
            ])
    }

    @Test("every value is a non-empty string, one line for a description")
    func values() {
        #expect(
            problems(replacing("description: An open tray.", with: "description:")) == [
                "6: icon \"tray\": description must be a string; quote it if YAML reads it as another type"
            ])
        #expect(
            problems(replacing("description: An open tray.", with: "description: \" \"")) == [
                "6: icon \"tray\": description is empty"
            ])
        #expect(
            problems(replacing("description: An open tray.", with: "description: |\n      An open\n      tray.")) == [
                "6: icon \"tray\": the description must be one line"
            ])
        #expect(
            problems(replacing("name: tray", with: "name: true")) == [
                "5: icon \"true\": name must be a string; quote it if YAML reads it as another type"
            ])
    }

    @Test("a name is a lowerCamelCase Swift identifier, no keyword or member of Westron.Icon, and unique")
    func names() {
        let identifier =
            "the name must be a lowerCamelCase Swift identifier (ASCII letters and digits, a lowercase letter first)"
        for name in ["new-window", "NewWindow", "new_window", "1up", "\"\u{00E9}t\u{00E9}\""] {
            let label = name.hasPrefix("\"") ? "\u{00E9}t\u{00E9}" : name
            #expect(
                problems(replacing("name: newWindow", with: "name: \(name)")) == [
                    "11: icon \"\(label)\": \(identifier)"
                ])
        }
        for name in ["default", "fallback", "rawValue", "systemName"] {
            #expect(
                problems(replacing("name: newWindow", with: "name: \(name)")) == [
                    "11: icon \"\(name)\": the name is a Swift keyword or a member of Westron.Icon"
                ])
        }
        #expect(
            problems(replacing("name: newWindow", with: "name: tray")) == ["11: icon \"tray\": the name repeats icon 1"]
        )
    }

    @Test("a symbol has the form of an SF Symbol name and is drawn by one icon only")
    func symbols() {
        for symbol in ["List.Bullet", "list bullet", "list..bullet", ".list", "list-bullet"] {
            #expect(
                problems(replacing("apple: list.bullet", with: "apple: \"\(symbol)\"")) == [
                    "10: icon \"bullets\": \"\(symbol)\" is not an SF Symbol name (lowercase words and digits joined by "
                        + "dots)"
                ])
        }
        #expect(
            problems(replacing("apple: list.bullet", with: "apple: tray")) == [
                "10: icon \"bullets\": the symbol tray is already drawn by icon \"tray\""
            ])
    }

    @Test("every problem is reported, in the order of the file")
    func allProblems() {
        let yaml = replacing("name: tray", with: "name: Tray")
            .replacingOccurrences(of: "apple: macwindow.badge.plus", with: "apple: Mac")
            .replacingOccurrences(of: "default: bullets", with: "default: dots")
        #expect(problems(yaml).map { String($0.prefix(while: { $0 != ":" })) } == ["2", "5", "13"])
    }
}
