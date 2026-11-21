// PROBE ONLY (#99): describes every AppKit text view in a picture's view tree.
#if os(macOS)
    import AppKit

    @testable import WestronCatalog

    @MainActor
    enum FieldProbe {
        static var modes: Set<String> {
            Set(
                (ProcessInfo.processInfo.environment["WESTRON_PROBE_MODE"] ?? "").split(separator: ",").map(String.init)
            )
        }

        static func fields(_ view: NSView) -> [NSTextField] {
            ((view as? NSTextField).map { [$0] } ?? []) + view.subviews.flatMap { fields($0) }
        }

        static func force(_ window: NSWindow, capture: ComponentMatrix.Capture) {
            let modes = modes
            let hc = capture.theme == .lightHighContrast || capture.theme == .darkHighContrast
            if modes.contains("hcAppearance"), hc {
                window.appearance = NSAppearance(
                    named: capture.theme.isDark ? .accessibilityHighContrastDarkAqua : .accessibilityHighContrastAqua)
            }
            if modes.contains("appHC") {
                NSApplication.shared.appearance = NSAppearance(
                    named: capture.theme.isDark ? .accessibilityHighContrastDarkAqua : .accessibilityHighContrastAqua)
            }
            if modes.contains("firstResponder"), let field = fields(window.contentView!).first {
                print("probe: makeFirstResponder \(window.makeFirstResponder(field))")
            }
            if modes.contains("busy") {
                let end = Date().addingTimeInterval(1)
                while Date() < end {}
            }
        }

        static func forceAfterSettle(_ window: NSWindow, capture: ComponentMatrix.Capture) {
            let modes = modes
            if modes.contains("lateFirstResponder"), let field = fields(window.contentView!).first {
                print("probe: makeFirstResponder late \(window.makeFirstResponder(field))")
            }
            if modes.contains("busyAfter") {
                let end = Date().addingTimeInterval(1)
                while Date() < end {}
            }
        }

        static func font(_ font: NSFont?) -> String {
            guard let font else { return "nil" }
            let ct = font as CTFont
            return String(
                format: "%@ %.17g asc %.17g desc %.17g lead %.17g lm %.17g", font.fontName, font.pointSize,
                CTFontGetAscent(ct), CTFontGetDescent(ct), CTFontGetLeading(ct),
                NSLayoutManager().defaultLineHeight(for: font))
        }

        static func attributes(_ string: NSAttributedString?) -> String {
            guard let string, string.length > 0 else { return "none" }
            var parts: [String] = []
            string.enumerateAttributes(in: NSRange(location: 0, length: string.length)) { attrs, range, _ in
                let described = attrs.sorted { $0.key.rawValue < $1.key.rawValue }.map { key, value -> String in
                    if let font = value as? NSFont { return "\(key.rawValue)=\(FieldProbe.font(font))" }
                    if let style = value as? NSParagraphStyle {
                        return "\(key.rawValue)={min \(style.minimumLineHeight) max \(style.maximumLineHeight) "
                            + "multiple \(style.lineHeightMultiple) spacing \(style.lineSpacing) before "
                            + "\(style.paragraphSpacingBefore) after \(style.paragraphSpacing) break "
                            + "\(style.lineBreakMode.rawValue)}"
                    }
                    return "\(key.rawValue)=\(String(describing: value).prefix(60))"
                }
                let size = string.attributedSubstring(from: range).size()
                parts.append("\(range): \(described.joined(separator: " ")) size \(size)")
            }
            return parts.joined(separator: " | ")
        }

        static func report(_ root: NSView) -> [String] {
            var lines: [String] = []
            func walk(_ view: NSView, depth: Int) {
                let frame = view.convert(view.bounds, to: nil)
                let f = String(
                    format: "(%.3f, %.3f, %.3f × %.3f)", frame.minX, frame.minY, frame.width, frame.height)
                if let field = view as? NSTextField {
                    let cell = field.cell
                    lines.append(
                        "\(type(of: field)) \(f) intrinsic \(field.intrinsicContentSize) fitting \(field.fittingSize) "
                            + "cell \(type(of: cell).self) \(cell?.cellSize ?? .zero) "
                            + "font \(font(field.font)) bezeled \(field.isBezeled) bordered \(field.isBordered) "
                            + "single \(field.usesSingleLineMode) wraps \(cell?.wraps ?? false) "
                            + "editable \(field.isEditable) text \"\(field.stringValue)\" placeholder "
                            + "\"\(field.placeholderString ?? field.placeholderAttributedString?.string ?? "")\" "
                            + "appearance \(field.appearance?.name.rawValue ?? "nil") effective "
                            + "\(field.effectiveAppearance.name.rawValue) editor \(field.currentEditor() != nil) "
                            + "firstResponder \(field.window?.firstResponder === field)")
                    if FieldProbe.modes.contains("attrs") {
                        lines.append("  value attrs: \(attributes(field.attributedStringValue))")
                        lines.append("  placeholder attrs: \(attributes(field.placeholderAttributedString))")
                    }
                } else if let text = view as? NSTextView {
                    lines.append(
                        "\(type(of: text)) \(f) font \(font(text.font)) tk2 \(text.textLayoutManager != nil) "
                            + "inset \(text.textContainerInset) appearance \(text.appearance?.name.rawValue ?? "nil") "
                            + "effective \(text.effectiveAppearance.name.rawValue) intrinsic \(text.intrinsicContentSize)"
                    )
                }
                for sub in view.subviews { walk(sub, depth: depth + 1) }
            }
            walk(root, depth: 0)
            return lines
        }
    }
#endif
