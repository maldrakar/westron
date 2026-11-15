# 0011. Icons and fonts

Date: 2026-11-15. Status: accepted.

## Context

SF Pro and SF Symbols are licensed for Apple platforms only. The pilot sets headings in the system's rounded face
(SF Pro Rounded) and body text in the system font, and draws every icon with an SF Symbol (decisions/0006). westron
has no platform other than Apple yet.

## Decision

### Fonts

- westron ships no font files. Every platform uses its system font: SF Pro on Apple, Adwaita Sans on GNOME, Roboto on
  Android, `system-ui` on the web.
- On Apple, headings use the system's rounded design (`Font.Design.rounded`), as the pilot does. On other platforms
  headings use the system font; the brand holds through weight and size, not through a face.
- Text roles map to the platform's text styles, so that the text scales with the person's setting (Dynamic Type on
  Apple). On Apple a role becomes `Font.system(_:design:weight:)`, not `Font.custom`, because there is no custom face.

### Icons

- Icons have westron names that say what the glyph draws (`tray`, `sun`, `chevron`, `magnifier`), kept as the pilot
  names them, because the pilot's store keeps a list's icon by that name.
- On Apple each name maps to an SF Symbol available on iOS 17, macOS 14 and watchOS 10. A custom symbol is drawn only
  when SF Symbols has no fitting glyph.
- The registry of names and their Apple glyphs is a westron source, and the Apple generator produces the icon
  enumeration and its SwiftUI adapter from it, so the pilot can delete its own `DesignSystem.Icon`.
- The icon set for the other platforms is chosen with the first of them (phase 6). Candidates: Lucide (ISC),
  Phosphor (MIT), Tabler (MIT), or our own SVG masters on one grid. The names do not change with that choice; each
  platform maps them to its own glyphs.

## Why

- The HIG asks for the system font in body text and allows a brand face for headings. On Apple the rounded system
  design gives the pilot's look with no font to license, ship or update.
- Outside Apple there is no free face close enough to SF Pro Rounded to be worth a dependency, and GNOME asks to keep
  custom styling to a minimum.
- Choosing a cross-platform icon set now would be a decision without a consumer (decisions/0005, rule 6). Stable names
  keep that choice cheap later.

## Consequences

- Typography tokens hold the cross-platform values (size in px, weight, line height) and, in
  `$extensions.dev.westron.apple`, the Apple text style and design. The rule in `.claude/rules/apple.md` about
  `Font.custom` changes to `Font.system`.
- Phase 6 opens a decision on the icon set for the web, GNOME and Android.
