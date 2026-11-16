# 0011. Icons and fonts

Date: 2026-11-15. Status: accepted. Revised the same day: the owner chose Onest for headings, and system icons with
westron's own for domain icons, on the direction specimens.

## Context

westron serves several products on several platforms, and its look is its own, not the pilot's (decisions/0006).
SF Pro and SF Symbols are licensed for Apple platforms only. The research is in `research_notes/type-and-icons.md`:

- which open fonts have Cyrillic, which the owner's products need;
- how systems pair a brand face with the system font;
- what bundling a font costs on each platform;
- which icon sets a product may build on.

## Decision

### Fonts

| Role | Font | License |
|---|---|---|
| Headings | Onest | SIL OFL 1.1 |
| Body text and controls | the system font: SF Pro on Apple, Adwaita Sans on GNOME, Roboto on Android, `system-ui` on the web | the platform's |
| Code, logs, identifiers | Geist Mono | SIL OFL 1.1 |

- **Brand face in headings only.** Body text and controls stay in the system font, so they read like the platform.
- **Static instances.** westron ships the weights it uses: Onest SemiBold and Bold, Geist Mono Regular and
  SemiBold. They are cut from the variable fonts on Google Fonts (Onest 2.001, Geist Mono 1.701) with fontTools
  4.55.3 (`varLib.instancer`, names updated). Neither license reserves a font name, so the instances keep their names.
- **Names.** A font's PostScript name is its family without spaces and the weight's name: `Onest-Bold`,
  `GeistMono-Regular`. The Apple generator derives it from the token's family and weight.
- **Fallback.** A family token names the system family to fall back on (`["Onest", "system-ui"]`). Where the font is
  missing, the text is set in the system font, not in an arbitrary one.
- **On Apple.**
  - The fonts live in `WestronUI/Fonts`, each with its license, about 400 KB in all.
  - They are registered for the process the first time a text role needs one, so a product sets up nothing.
  - A role becomes `Font.custom(_:size:relativeTo:)` with its text style, so it follows Dynamic Type.
  - If registration fails, the role uses the system font.
  - A test checks that every font a role names is registered and draws Cyrillic.
- **Other platforms.** The web, GNOME and Android get the same fonts with their phases: a subset WOFF2 on the web, the
  font in the Flatpak and one CSS rule on GNOME, `res/font` on Android.

### Icons

- **Two sources.**
  - Standard actions and states use the platform's own icons: SF Symbols, Adwaita icons, Material Symbols. These
    include add, delete, search, share, close and the statuses.
  - Domain icons are westron's own set, drawn on one grid. The set starts from Lucide (ISC), with Tabler (MIT) for
    its gaps. Remix Icon is out: its 2026 license forbids building an icon set on it.
- **Names.** A westron name says what the glyph draws: `tray`, `sun`, `magnifier`. Products store these names, so a
  released name is never renamed or removed. The pilot's 32 names stay as they are. Four status glyphs are added:
  `checkCircleFill`, `xmarkCircleFill`, `exclamationTriangleFill`, `infoCircleFill`.
- **The registry.** `spec/icons/icons.yaml` maps each name to its glyph per platform. The Apple generator produces
  the icon enumeration and its SwiftUI adapter from it.
- **Apple.** On Apple a name maps to an SF Symbol available on iOS 17, macOS 14 and watchOS 10. A domain icon from
  westron's own set becomes a custom symbol. Converting the masters with SwiftDraw needs a spike first, with the
  first domain icon a product needs.

## Why

- **Onest.** The owner chose it on the specimens. It was one of the fonts with full Cyrillic that were shown: Inter,
  Geist, Onest, IBM Plex and Unbounded. Half of the fashionable grotesques have no Cyrillic: Mona Sans, Instrument
  Sans, Figtree, Bricolage, Google Sans Flex.
- **Headings only.** A brand face in headings with the system font for text is what Linear does and what the HIG
  allows. It costs one font and a few hundred kilobytes, not a whole UI out of tune with the platform.
- **Geist Mono.** It has Cyrillic and box-drawing characters, which logs and tables of code need. Commit Mono has no
  Cyrillic, and Martian Mono no box drawing.
- **System icons for standard actions.** People recognize them, and they follow the platform's weight and size.
  Domain icons are where a product's character shows, and no system set has them.

## Consequences

- The rule in `.claude/rules/apple.md` changes. A view takes a text role (`.textRole(.heading.large)`, or
  `Font(.body.regular)`) and never calls `Font.custom` or `Font.system` with a size of its own. A shipped font takes
  the size the platform gives its text style, so headings keep their proportion to the system font on the Mac.
- decisions/0007 lists the fonts under the SIL OFL.
- Updating a font means cutting the instances again with the command above and checking the catalog's typography page.
- The platform phases map the icon names: phase 6 (web) to westron's own set, phase 7 (GNOME) to Adwaita icons, phase 8
  (Android) to Material Symbols. The web has no platform icon set, so there westron's own set covers standard actions
  too. The first of these phases draws the domain icons on westron's grid.
