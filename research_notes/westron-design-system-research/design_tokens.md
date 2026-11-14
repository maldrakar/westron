# Design tokens: standards, architecture and multi-platform generation pipelines (state as of mid-November 2026)

Scope note: these notes cover the W3C DTCG format and its modules, token transformation tooling, token architecture, theming/modes, and the color, type, spacing and motion foundations as they map to SwiftUI, CSS, Compose and GTK/libadwaita or Qt. Research date: 2026-11-14. Version numbers and dates were checked live against GitHub, npm and the spec sites where noted.

---

## 1. DTCG Design Tokens Format Module: status, coverage, gaps

### Takeaway
DTCG published its first stable release, **2025.10**, on 28 Oct 2025 as three Final Community Group Reports: Format, Color and Resolver. As of Nov 2026 no newer stable version exists. Since then the group has only done maintenance: JSON Schemas, test fixtures, erratum PRs, and a "preview draft" dated 08 Sep 2026 that says not to implement it. The format covers primitives, composites, aliases, `$extends`/`$root` groups, 14 color spaces and resolver-based theming. It still lacks spring/keyframe motion, boolean/string types, `em`/`pt`/`dp`/`sp` units, percentage, font style, and any first-class "platform" concept.

### Cited Findings
**Status and governance**
- The designtokens.org banner reads "First stable version 2025.10 now available" and points to a living draft at designtokens.org/TR/drafts — [designtokens.org](https://www.designtokens.org/)
- The W3C CG page lists three final modules, all dated 28 Oct 2025: Format, Color and Resolver (2025.10). The last editors' draft before that was the Third Editors' Draft (20 Jul 2025) — [W3C DTCG CG page](https://www.w3.org/community/design-tokens/)
- These are Community Group Reports. They are not W3C Standards and are not on the W3C Standards Track — [Resolver Final CG Report 2025.10](https://www.w3.org/community/reports/design-tokens/CG-FINAL-resolver-20251028/)
- The 28 Oct 2025 announcement's headline features: theming/multi-brand (light/dark, accessibility variants, brand themes "without duplicating files"); modern color (Display P3, OKLCH, CSS Color 4 spaces); token relationships (inheritance, aliases, component-level references); and cross-platform output to iOS, Android, web and Flutter. It names the reference implementations as Style Dictionary, Tokens Studio and Terrazzo. It says more than 10 tools support or are implementing the spec, including Penpot, Figma, Sketch, Framer, Knapsack, Supernova and zeroheight. Editors come from Adobe, Google, Microsoft, Meta, Shopify and others — [W3C announcement, 2025-10-28](https://www.w3.org/community/design-tokens/2025/10/28/design-tokens-specification-reaches-first-stable-version/)
- The only 2026 post on the CG page is "Thank you, Jina and Val" (17 Jun 2026). Jina Anne and Val Head become chairs emeritus, Kaelig Deloumeau-Prigent stays on as chair, and the post promises a co-chair election, the return of meetings, and "more to share soon". It gives no roadmap for the next version — [W3C DTCG CG page](https://www.w3.org/community/design-tokens/)
- Spec activity in 2026 is maintenance. In Jan 2026 a JSON Schema for resolver documents was merged, described as not changing behavior or syntax — [public-design-tokens-log, Jan 2026](https://lists.w3.org/Archives/Public/public-design-tokens-log/2026Jan/0011.html). Open PRs as of Nov 2026 include "Sync the Resolver 2025.10 table of contents", "Include the resolver version in the bundling examples" and test-suite fixtures for the hex fallback — [design-tokens/community-group repo](https://github.com/design-tokens/community-group/pulls)
- Known schema bug: the 2025.10 format JSON Schema's `curlyBraceReference` pattern rejects valid `{group.$root}` references (issue #448, opened Sep 2026, fix PR #449 still open) — [issue #448](https://github.com/design-tokens/community-group/issues/448)
- The drafts page is labeled "Draft Community Group Report 08 September 2026", calls itself a "preview draft" and says not to implement it. The latest published version is still 2025.10 — [Format draft](https://www.designtokens.org/tr/drafts/format/)

**File format and syntax (Format module)**
- Files are JSON. The media type is `application/design-tokens+json` (preferred) or `application/json`, and the extension is `.tokens` (preferred) or `.tokens.json` — [Format draft](https://www.designtokens.org/tr/drafts/format/)
- A token is an object with `$value`. Optional properties are `$type`, `$description`, `$extensions` and `$deprecated` (boolean or string). `$type` can be inherited from the parent group. Tools must not guess a type from the value. Names must not begin with `$` or contain `{`, `}` or `.` — [Format draft](https://www.designtokens.org/tr/drafts/format/)
- Groups are objects without `$value`. `$root` gives a group a base token, referenced as `{color.accent.$root}`. `$extends` inherits from another group by deep merge, "equivalent to JSON Schema `$ref`". It cannot target a token and cannot be circular — [Format draft](https://www.designtokens.org/tr/drafts/format/)
- There are two reference syntaxes:
  - Curly-brace aliases (`"{colors.blue}"`) always resolve to a whole token's `$value`.
  - JSON Pointer `{"$ref": "#/colors/blue/$value/components/0"}` can target any sub-property, and tools must support it.

  Chains are allowed, and circular references are errors — [Format draft](https://www.designtokens.org/tr/drafts/format/)
- Primitive types:
  - `color`
  - `dimension`: `{"value": 16, "unit": "px"}`. Units are **only `px` and `rem`**, and the unit is required even when the value is 0.
  - `fontFamily`: a string or an array of strings.
  - `fontWeight`: 1–1000 or a named alias such as `"bold"`.
  - `duration`: `{"value": 200, "unit": "ms"}`, units `ms` or `s`.
  - `cubicBezier`: `[P1x, P1y, P2x, P2y]` with x in [0,1].
  - `number`

  — [Format draft](https://www.designtokens.org/tr/drafts/format/)
- Composite types:
  - `strokeStyle`: keywords, or `{dashArray, lineCap}`.
  - `border`: `{color, width, style}`.
  - `transition`: `{duration, delay, timingFunction}`.
  - `shadow`: one object or an array of `{color, offsetX, offsetY, blur, spread, inset?}`.
  - `gradient`: an array of `{color, position}` stops. Positions are clamped to [0,1], and there is no linear/radial kind (issue 101).
  - `typography`: `{fontFamily, fontSize, fontWeight, letterSpacing, lineHeight}`. `lineHeight` is a number that "SHOULD" be read as a multiplier of `fontSize`. Issue 102 asks whether it should become a dimension.

  — [Format draft](https://www.designtokens.org/tr/drafts/format/)
- Types still undocumented ("planned"): font style, percentage/ratio and file — [Format draft](https://www.designtokens.org/tr/drafts/format/)
- Example (alias plus dimension object):
  ```json
  { "spacing": { "base": { "$type": "dimension", "$value": { "value": 16, "unit": "px" } } },
    "layout":  { "gap":  { "$type": "dimension", "$value": "{spacing.base}" } } }
  ```
  — [Format draft](https://www.designtokens.org/tr/drafts/format/)

**Color module**
- A color value is an object: `colorSpace` (required), `components` (required; an array of numbers or `"none"`), `alpha` (optional, default 1) and `hex` (optional 6-digit sRGB fallback) — [Color draft](https://www.designtokens.org/tr/drafts/color/)
- Supported spaces: `"srgb", "srgb-linear", "hsl", "hwb", "lab", "lch", "oklab", "oklch", "display-p3", "a98-rgb", "prophoto-rgb", "rec2020", "xyz-d65", "xyz-d50"` — [Color draft](https://www.designtokens.org/tr/drafts/color/)
- Gamut mapping is non-normative. Tools "MAY" pick any algorithm, and authors should validate converted output. A `none` hue may render or interpolate differently from 0 — [Color draft](https://www.designtokens.org/tr/drafts/color/)
- Example: `{"$type":"color","$value":{"colorSpace":"srgb","components":[1,0,1],"alpha":1,"hex":"#ff00ff"}}`, with `$schema: https://www.designtokens.org/schemas/2025.10/format.json` — [Color draft](https://www.designtokens.org/tr/drafts/color/)

**Resolver module (themes/modes)**
- A resolver document (extension `.resolver.json`, required `version: "2025.10"`) has these parts:
  - `sets`: named token collections, each with `sources` (inline tokens or `$ref`s; later sources win).
  - `modifiers`: named conditions, each with a `contexts` map and an optional `default`.
  - `resolutionOrder` (required): an ordered array of sets and modifiers, where later entries override earlier ones.

  — [Resolver draft](https://www.designtokens.org/tr/drafts/resolver/)
- An input is a string map such as `{"theme": "dark"}`. Omitting a modifier that has no default is an error. The number of permutations is the product of context counts. For each input a tool validates the input, flattens `resolutionOrder`, then resolves aliases — [Resolver draft](https://www.designtokens.org/tr/drafts/resolver/)
- The spec defines no special "platform" concept. Platform- or device-like variation is an ordinary modifier, like the spec's own `size` example (mobile/tablet/desktop) — [Resolver draft](https://www.designtokens.org/tr/drafts/resolver/)
- Shape:
  ```json
  { "version": "2025.10",
    "sets": { "foundation": { "sources": [{ "$ref": "foundation.json" }] } },
    "modifiers": { "theme": { "contexts": {
        "light": [{ "$ref": "themes/light.json" }], "dark": [{ "$ref": "themes/dark.json" }] },
        "default": "light" } },
    "resolutionOrder": [{ "$ref": "#/sets/foundation" }, { "$ref": "#/modifiers/theme" }] }
  ```
  — [Resolver draft](https://www.designtokens.org/tr/drafts/resolver/); the composition property was renamed to `resolutionOrder` in 2025 after feedback — [search summary of DTCG log](https://lists.w3.org/Archives/Public/public-design-tokens-log/2025Sep/0004.html)

**Open gaps tracked in DTCG issues (all open as of Nov 2026)**
- Motion beyond `transition`: issue #429 (Jun 2026, active Nov 2026) asks about spring/physics tokens (stiffness/damping/mass or response/bounce), keyframe sequences and named motion patterns. It notes that "springs are now the default in a lot of modern systems (SwiftUI, Framer Motion, CSS `linear()`-approximated springs)" and "there's no token type that captures a spring today" — [issue #429](https://github.com/design-tokens/community-group/issues/429); see also #158 "Animation description by solely Bezier Curve is inadequate" — [issue #158](https://github.com/design-tokens/community-group/issues/158)
- `em` units for dimension: issue #390 (Jan 2026) — [issue #390](https://github.com/design-tokens/community-group/issues/390); expanded dimension units: #245 — [issue #245](https://github.com/design-tokens/community-group/issues/245)
- High contrast colors: #91 — [issue #91](https://github.com/design-tokens/community-group/issues/91); "Native modes and theming support" #210 (60 comments) — [issue #210](https://github.com/design-tokens/community-group/issues/210); color modifications (rgba/opacity of a referenced color): #88 — [issue #88](https://github.com/design-tokens/community-group/issues/88)
- Typography type feedback: #102 (45 comments) — [issue #102](https://github.com/design-tokens/community-group/issues/102); "Using target platforms to guide the specification": #190 — [issue #190](https://github.com/design-tokens/community-group/issues/190)

### Inferences
- Use DTCG 2025.10 as westron's canonical format. It is stable, has three reference implementations, and is exported by Figma. Teams that need unsupported data (springs, booleans, platform overrides, AI usage notes) put it in `$extensions` under a reverse-DNS key (e.g. `dev.westron.*`), the way Figma (`com.figma`) and Primer (`org.primer.*`) do (see §2 and §4).
- Because `dimension` allows only px/rem, the source of truth should hold unitless or px values, and the converters should derive pt (Apple), dp/sp (Android) and rem (web).
- Resolver files are the standards-track way to express light/dark/high-contrast/density/brand/platform. "Platform" just becomes another modifier.

### Gaps
- No public roadmap for a 2026.x release was found. The June 2026 post only promised "more to share soon".
- The 08 Sep 2026 preview draft could not be diffed against 2025.10 in this session, so its exact changes are unknown.

---

## 2. Tooling comparison: DTCG support, native outputs, custom targets

### Takeaway
**Style Dictionary 5.x** (5.8.0, 3 Nov 2026) is the most widely used and most extensible engine. It has built-in Swift (UIKit-oriented), Compose, Android XML, CSS and Flutter formats, and has steadily added DTCG 2025.10 support: color objects, dimension objects, duration, `$root`. **Resolver support is not in core yet.** **Terrazzo 2.x** (2.10.0, 21 Oct 2026) is DTCG-native and resolver-first, but its native outputs are weak: the Swift plugin is experimental and colors-only, and there is no Kotlin/Compose plugin. Tokens Studio and Figma are authoring and sync sources. Theo is archived and Diez is dead. I found no off-the-shelf GTK CSS, QML or Rust target in either engine, so those need custom formats. Qt's own Figma-to-QML tooling is the only Linux-adjacent option.

### Cited Findings
**Style Dictionary (SD)**
- Latest is v5.8.0 (2026-11-03). Recent releases: 5.7.1 (10-24), 5.7.0 (10-16), 5.6.0 (10-03). Repo has 4,883 stars and is active — [SD releases](https://github.com/style-dictionary/style-dictionary/releases); npm `style-dictionary` 5.8.0 — [npm](https://www.npmjs.com/package/style-dictionary)
- v5.0.0 (2025-05-16) is "a drop-in replacement for the majority of users". It requires Node ≥ 22, forbids references to non-token nodes, and fixes the reference syntax to DTCG `{a.b}` — [SD v5 migration](https://styledictionary.com/versions/v5/migration/); [CHANGELOG](https://github.com/style-dictionary/style-dictionary/blob/main/CHANGELOG.md)
- DTCG 2025.10 support landed incrementally — [CHANGELOG](https://github.com/style-dictionary/style-dictionary/blob/main/CHANGELOG.md):
  - 5.1.0 (2025-10-01): new `size/compose/{sp,dp}` transforms.
  - 5.3.0 (2026-02-09): structured color objects in all color transforms, all 14 DTCG color spaces, new `color/oklch`, `color/oklab`, `color/p3` (outputs `color(display-p3 …)`) and `color/lch` transforms. The `hex` field is used as the fallback when a color is out of sRGB gamut.
  - 5.4.0 (2026-03-22): DTCG dimension object values in all built-in transforms, including the typography/border/shadow CSS shorthands. Also fixed `size/remToPt` (it previously emitted iOS float `f`), with a new `size/remToFloat` now used by the `ios` transformGroup.
  - 5.7.0 (2026-10-16): DTCG `duration` objects. Trailing `$root` segments are ignored in name transforms (`--color-text-warning` instead of `…-root`).
  - 5.8.0: exposes `stripMetaProps`, `formatJS` and `isColor` utilities for custom formats, plus `StopTransformError`.
- The SD docs still say "the latest format 2025.10 does not have full support yet", with full support listed as work in progress — [SD DTCG page](https://styledictionary.com/info/dtcg/)
- The 2025.10 tracking issue #1590 (opened Nov 2025) marks color, border, shadow and dimension ✅, gradient 🚧, duration (since shipped in 5.7.0), and **resolvers not done**. In Aug–Oct 2026, Autodesk's Weave design system reported "running DTCG resolver modifiers in production on SD 5.x" through its own parser layer (~180 lines) and offered to upstream it. The maintainer (jorenbroekema) is discussing a `resolver` config as an alternative to `source`, producing every permutation from one instance, with per-permutation output paths — [SD issue #1590](https://github.com/style-dictionary/style-dictionary/issues/1590)
- Built-in native formats — [SD predefined formats](https://styledictionary.com/reference/hooks/formats/predefined/):
  - `ios-swift/class.swift`, `ios-swift/enum.swift` and `ios-swift/any.swift` (configurable `objectType`, e.g. `struct`). Options are `accessControl` (default `public`), `import` (default `UIKit`) and `className`. The documented examples emit `UIColor(red:green:blue:alpha:)`. Several Obj-C formats are listed as "Todo".
  - `compose/object` emits a Kotlin `object` with `val colorBaseRed5 = Color(0xFFFAF3F2)`. Default imports are `androidx.compose.ui.graphics.Color` and `androidx.compose.ui.unit.*`. Options are `className`, `packageName`, `accessControl` and `objectType`.
  - `android/resources` (XML) is recommended over the single-purpose `android/colors|dimens|…` formats.
  - `css/variables` takes `selector` (string or array for nesting), `outputReferences`, `outputReferenceFallbacks` and `sort`.
  - `flutter/class.dart`.
- SD added a transform for SwiftUI's `Color` in 3.1.0 (2021) — [CHANGELOG](https://github.com/style-dictionary/style-dictionary/blob/main/CHANGELOG.md)
- Custom targets: `StyleDictionary.registerFormat({ name, format: ({dictionary, file, options, platform}) => string })`. The dictionary exposes `allTokens`, `tokens` and `tokenMap`. Helpers `usesReferences` and `getReferences` (from `style-dictionary/utils`) let a format emit references instead of resolved values (use `token.original.value`). Since v4, formats may return non-string data for `formatPlatform`/`formatAllPlatforms` — [SD formats hooks](https://styledictionary.com/reference/hooks/formats/)

**Terrazzo (formerly Cobalt UI)**
- Monorepo release 2.10.0 (2026-10-21) for `@terrazzo/cli`, `plugin-css`, `plugin-js`, `plugin-sass`, `plugin-tailwind` and `plugin-vanilla-extract`. `@terrazzo/plugin-swift` is only 0.3.4 (2026-10-14). The repo has 491 stars — [Terrazzo GitHub](https://github.com/terrazzoapp/terrazzo); [npm @terrazzo/plugin-swift](https://www.npmjs.com/package/@terrazzo/plugin-swift)
- Packages: `cli, parser, plugin-css, plugin-css-in-js, plugin-js, plugin-sass, plugin-swift, plugin-tailwind, plugin-token-listing, plugin-vanilla-extract, storybook, token-lab, token-tools, use-color, react-color-picker, json-schema-tools, fonts, icons, tiles`. **There is no Android/Kotlin/Compose plugin** — [Terrazzo packages dir](https://github.com/terrazzoapp/terrazzo/tree/main/packages)
- The CLI has `init`, `build` (which also lints), `lint`, `check` and `bundle` (combines a resolver's referenced files into one JSON). Integrations: CSS, CSS-in-JS, Sass, JS/TS, Storybook, Swift, Tailwind, Vanilla Extract, Custom. There is an "Import from Figma" guide — [Terrazzo docs](https://terrazzo.app/docs/)
- Terrazzo 2.x supports DTCG resolvers, which replace the legacy Terrazzo/Cobalt-only `$extensions.mode`. Each CSS plugin permutation takes an `input` and a `prepare()` wrapper (e.g. `:root{}` for light, `@media (prefers-color-scheme: dark){:root{}}` for dark). Legacy modes map to a "secret modifier called `tzMode`". The docs recommend orthogonal modifiers (no two modifiers touching the same tokens), ideally one modifier per `$type` — [Terrazzo resolvers guide](https://terrazzo.app/docs/guides/resolvers/)
- The Swift plugin is "still **experimental**" and generates `Tokens.xcassets` — [Terrazzo Swift docs](https://terrazzo.app/docs/integrations/swift/). Its source handles only `$type: color` ("TODO: other types"). It gamut-maps every color into P3 (colorjs.io) and writes one `<id>.colorset/Contents.json` per token with `"color-space": "display-p3"`. A dark variant comes only from the legacy `mode: 'dark'`, emitted as `"appearances":[{"appearance":"luminosity","value":"dark"}]`. No Swift source code is generated — [plugin-swift/src/index.ts](https://github.com/terrazzoapp/terrazzo/blob/main/packages/plugin-swift/src/index.ts)
- Terrazzo plugin API shape (seen in the Swift plugin): `{ name, transform({tokens, setTransform}), build({getTransforms, outputFile}) }`, with transforms keyed by `format` and `mode` — [plugin-swift source](https://github.com/terrazzoapp/terrazzo/blob/main/packages/plugin-swift/src/index.ts)

**Tokens Studio**
- The Figma plugin supports two formats per project or branch: "Legacy" (the default) and "W3C DTCG" (`$`-prefixed). Switching converts the JSON and can open a Git branch (e.g. `w3c-dtcg-conversion`). The docs don't mention 2025.10, color objects or resolvers, and say additional DTCG types will come "in future releases" — [Tokens Studio docs: token format](https://docs.tokens.studio/manage-settings/token-format)
- `@tokens-studio/sd-transforms` (Style Dictionary preprocessor and transforms for Tokens Studio output) is at v2.0.3 (2025-12-10) — [sd-transforms releases](https://github.com/tokens-studio/sd-transforms/releases)
- Penpot's token export uses the Tokens Studio multi-set format, "not what DTCG 2025.10 defines" — [Penpot community thread](https://community.penpot.app/t/token-export-is-tokens-studio-format-not-dtcg-2025-10/10544)

**Figma (native)**
- Figma Schema 2025 previewed native variable export/import "aligned with the DTCG token standard", together with extended variable collections. Rollout was still in progress in early Dec 2025 (community support: "it's still being rolled out") — [Figma forum thread](https://forum.figma.com/ask-the-community-7/native-variable-export-feature-47831)
- Third-party description (Oct 2026), not official Figma docs:
  - Export uses `$value`/`$type`/`{a.b}` aliases (aliases preserved) and puts Figma IDs, scopes and codeSyntax under `$extensions.com.figma`. Boolean and string variables rely on those extensions because DTCG has no such types.
  - Exporting a whole collection gives a ZIP with **one JSON file per mode**.
  - Text styles, shadows and gradients are styles, not variables, so they are not exported.
  - Import overwrites rather than merges.

  — [atomize.tools blog](https://atomize.tools/blog/figma-variables-export-json/)
- Forum users report the DTCG export omits `$description`, and one post says composite tokens aren't covered — [search summary: Figma forum / DEV](https://dev.to/slafleche/even-figma-isnt-sure-about-its-own-design-tokens-4mko)

**Legacy and commercial tools**
- **Theo** (Salesforce) GitHub repo is **archived** (last push June 2025) — [salesforce-ux/theo](https://github.com/salesforce-ux/theo)
- **Diez**: last push Dec 2022, so effectively abandoned — [diez/diez](https://github.com/diez/diez)
- **Supernova**: official exporters include an iOS Token & Style Exporter, an Android Token & Style Exporter and a Style Dictionary exporter — [Supernova exporter-ios](https://www.github.com/Supernova-Studio/exporter-ios); [exporter-style-dictionary](https://www.github.com/Supernova-Studio/exporter-style-dictionary). Supernova and **Knapsack** are listed among tools supporting or implementing DTCG — [W3C announcement](https://www.w3.org/community/design-tokens/2025/10/28/design-tokens-specification-reaches-first-stable-version/)
- **Specify**: a hosted token platform with its own "Specify Design Token Format" (2.0). Its current status is unclear, since a Sept 2026 profile describes it in the past tense — [specifyapp.com](https://specifyapp.com); [DevTune profile](https://devtune.ai/verticals/design-systems-and-component-libraries/specify.md)

**Big-system tooling worth copying**
- Adobe Spectrum's `spectrum-design-data` monorepo (very active, releases on 2026-11-14) ships tokens, component schemas, a normative "Design Data Specification" (JSON Schemas plus a validation rule catalog), MCP servers, a Claude Code skill (`tools/design-data-skill`), and a `design-data` CLI/TUI that validates, resolves, diffs, queries and migrates tokens — [spectrum-design-data README](https://github.com/adobe/spectrum-design-data). The CLI's `resolve` can emit `--format dtcg` for Style Dictionary or Terrazzo (core in Rust: `sdk/core/src/dtcg.rs`) — [Spectrum multi-platform SDK strategy](https://github.com/adobe/spectrum-design-data/blob/main/SPECTRUM_MULTIPLATFORM_SDK_STRATEGY.md)
- Spectrum's source format is **not DTCG**. It uses `value`, per-token `uuid`, `$schema` type URLs and inline `sets` (see §4) — [Spectrum layout.json](https://github.com/adobe/spectrum-design-data/blob/main/packages/tokens/src/layout.json)

**Linux targets (GTK and Qt) and Rust**
- No GTK, libadwaita, QML or Rust format exists in Style Dictionary's predefined format list — [SD predefined formats](https://styledictionary.com/reference/hooks/formats/predefined/). Terrazzo has no such plugin — [Terrazzo packages](https://github.com/terrazzoapp/terrazzo/tree/main/packages). An npm search for "style-dictionary gtk", "style-dictionary qml" and "design tokens rust" found no dedicated packages (search run on 2026-11-14 via npm CLI; negative result).
- **Qt (official tooling exists, but it's Figma-centric and not DTCG):**
  - *Figma to Qt* converts Figma variables into a QML module `DesignTokens` with "a QML singleton for each variable collection". "The modes of the collection become theme objects", switched through the collection's `activeTheme` property — [Figma to Qt: variables](https://doc.qt.io/figmatoqt/figmatoqt-how-to-variables.html)
  - *Qt Design Studio* has an **experimental** Design Tokens view. You use the generated library with `import Generated.DesignSystem` — [Qt Design Studio Design Tokens view](https://doc.qt.io/qtdesignstudio/studio-design-tokens-view.html)
  - Qt's agentic "qt-figma-token-extraction" skill (v1.0, Qt 6.5+) emits a custom (non-DTCG) `design-tokens.json` with `colors`, `semanticColors`, `typography`, `spacing`, `radii` and `shadows` sections. Multi-mode values sit under `modes` (e.g. Light/Dark). It then generates QML singletons `Primitives.qml`, `Theme.qml` (semantic, referencing Primitives), `Spacing.qml` and `FontInterface.qml`, registered with `QT_QML_SINGLETON_TYPE TRUE` — [Qt agentic skill](https://doc.qt.io/agentictools/skills/qt-figma-token-extraction/)
- **GTK/libadwaita** has no token tooling, but its CSS variable layer is a natural target (see §4 and §7) — [libadwaita CSS variables](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/css-variables.html)

### Inferences
- For westron (one developer plus an AI agent, with SwiftUI, web and Linux as targets and Android later), the most practical engine today is **Style Dictionary 5.x with custom formats**. It has the broadest built-in Swift/Compose/CSS coverage, is the most extensible, and already handles DTCG color/dimension/duration objects. Resolver input can be handled with a small pre-pass, as Weave did (~180 lines), until SD ships native support.
- Terrazzo is the better fit if you want strict DTCG and resolver semantics and lint for web. However, you would write your own Swift, Compose, GTK and QML plugins (the plugin API is small).
- Either way, plan to own the generators for SwiftUI `Color`/`Font`/`CGFloat` code, the colorset catalog, GTK CSS, QML singletons and Rust consts. They are small templating jobs that suit an AI agent.
- Spectrum's MCP/skill tooling and Primer's `org.primer.llm` extension (§3) suggest that token data with usage rules for AI agents is becoming common practice.

### Gaps
- I did not confirm from an official Figma help page which DTCG types and fields the native export covers, or which plan tiers get it. The evidence is forum posts and a third-party blog.
- Tokens Studio's level of 2025.10 compliance (color objects, resolver) is not documented.
- I did not evaluate Knapsack's or Supernova's 2026 DTCG import/export depth from primary docs.

---

## 3. Token architecture: tiers, naming, how many tiers for a small team

### Takeaway
The large systems all use about three tiers: raw/primitive → semantic/functional → component. Material calls them `ref` → `sys` → `comp`, Primer calls them `base` → `functional` → `component`, and Spectrum has global → alias → per-component files. Nathan Curtis's taxonomy (namespace / object / base / modifier) is the de facto naming grammar. For small teams the consensus is **two tiers (primitive + semantic)**, with component tokens added only where a real override need exists.

### Cited Findings
- Nathan Curtis's taxonomy — [Curtis, "Naming Tokens in Design Systems"](https://nathanacurtis.substack.com/p/naming-tokens-in-design-systems-9e86c7444676):
  - **Namespace**: system (`$esds-color-text-primary`), theme (`$aads-ocean-color-primary`) or domain (`$esds-consumer-color-marquee-text-primary`).
  - **Object**: component (`$esds-input-color-border`), element (`$esds-input-left-icon-color-fill`) or component group (`$esds-forms-color-border`).
  - **Base**: category (color, font, space, size, elevation…), concept (feedback, action, heading…) and property (background, text, border, fill, line-height…).
  - **Modifier**: variant (primary, success…), state (hover, disabled…), scale (enumerated `heading-size-1`, bounded `neutral-42`, proportion `space-1-x`) and mode (`…-on-dark`).
- Curtis's rules — [Curtis](https://nathanacurtis.substack.com/p/naming-tokens-in-design-systems-9e86c7444676):
  - Order is namespace → object → base → modifier.
  - "Avoid dogmatically including all levels possible."
  - A single team can skip the namespace.
  - Assume a default mode and suffix only the alternates (e.g. `on-dark`).
  - Keep component decisions local and promote to global only when 3+ components need them.
  - Alias object-level tokens to concept-level tokens (`$ui-controls-color-text-error = $color-feedback-error`) to hedge.
- **Primer (GitHub)** uses three tiers — [Primer token names](https://primer.style/product/primitives/token-names):
  - *Base* (`base-size-4`, `base-color-green-5`, `base-fontWeight-semibold`)
  - *Functional* (`bgColor-inset`, `borderColor-default`, `boxShadow-inset-thick`)
  - *Component/pattern* (`control-danger-borderColor-rest`, `button-primary-bgColor-hover`)

  Names have up to seven blocks: prefix, namespace, pattern, variant, property, variant, scale. Color variants are `default`, `muted` and `emphasis`. Scales cover t-shirt sizes, density (`condensed/normal/spacious`) and viewport (`narrow/regular/wide`).
- Primer's source tree mirrors the tiers: `src/tokens/base/{color/light,color/dark,motion/easing,motion/timing,size,typography}`, `src/tokens/functional/{color/bgColor,fgColor,borderColor,…,motion,border}`, and about 27 `src/tokens/component/*.json5` files. Tokens are compiled with Style Dictionary — [primer/primitives repo](https://github.com/primer/primitives); latest `@primer/primitives` 11.10.0 (2026-07-30) — [releases](https://github.com/primer/primitives/releases)
- Primer's token JSON is DTCG-style (`$value`, `$type`, `$description`) and uses rich `$extensions` — [bgColor.json5](https://github.com/primer/primitives/blob/main/src/tokens/functional/color/bgColor.json5):
  - `org.primer.figma`: collection, scopes, `codeSyntax.web`.
  - `org.primer.overrides`: per-mode values.
  - `org.primer.llm`: `usage: ['page-background', …]`, `rules: 'Use as the primary background… Do NOT use for emphasis'`.
- **Material Design** uses a three-tier prefix scheme visible in Material Web's token sources: `_md-ref-palette`, `_md-sys-color`, `_md-sys-typescale`, `_md-sys-shape`, `_md-sys-motion`, `_md-sys-elevation`, `_md-comp-elevation`. It emits CSS custom properties `--md-sys-color-*`, with separate `values-light`/`values-dark` — [material-web/tokens](https://github.com/material-components/material-web/tree/main/tokens)
- **Outdated:** the official `material-foundation/material-tokens` repo (Material tokens as an Adobe DSP package) is **archived** (last push Aug 2023) — [material-tokens](https://github.com/material-foundation/material-tokens)
- **Spectrum 2** keeps about 90 per-component token files (`button.json`, `tooltip.json`, …) alongside `color-aliases.json`, `layout.json`, `typography.json` and `semantic-color-palette.json`. It is a heavy component-token architecture — [spectrum-design-data packages/tokens/src](https://github.com/adobe/spectrum-design-data/tree/main/packages/tokens/src); `@adobe/spectrum-tokens` 15.7.0 (2026-11-11) — [npm](https://www.npmjs.com/package/@adobe/spectrum-tokens)
- Small-team guidance (secondary sources):
  - Use two tiers (primitive + semantic) for teams with fewer than ~5 designers. Component-level tokens "add indirection that makes debugging harder" and are rarely needed — [Design Systems Collective, "You Don't Need All Those Tokens (Yet)"](https://www.designsystemscollective.com/you-dont-need-all-those-tokens-yet-df9e78a157d2); [Vantage, design tokens for small teams](https://vantage-design-project.pages.dev/resources/design-tokens-for-small-teams)
  - A Spectrum-based analysis argues full component tokens pay off only with many framework implementations or a centralized design team — [Nate Baldwin, "Component-level design tokens: are they worth it?"](https://medium.com/@NateBaldwin/component-level-design-tokens-are-they-worth-it-d1ae4c6b19d4) (via search summary; not fetched)

### Inferences
- Recommended for westron: **two authored tiers**.
  1. Primitives: `color.palette.blue.500`, `space.4`, `radius.2`, `duration.200`, generated from formulas (§5).
  2. Semantic tokens: `color.bg.default`, `color.fg.muted`, `color.accent.emphasis`, `space.inset.md`, `radius.control`, `motion.spatial.default`.

  Add a thin, *opt-in* component tier only for components whose values really differ by platform (e.g. `control.height` on watchOS vs macOS) or need per-component theming.
- Use Primer-style `default/muted/emphasis` variants and `rest/hover/pressed/disabled` states. Skip the namespace (single team) unless westron is distributed as a third-party library for web.
- A modifier vocabulary of `light/dark`, `contrast: standard/high`, `density`, `platform` maps cleanly onto resolver modifiers (§4).
- Copy Primer's idea of storing AI-readable `usage`/`rules` in `$extensions`. This directly helps the AI coding agent pick the correct semantic token.

### Gaps
- Brad Frost's and Donnie D'Amato's 2025–2026 writing on tiers and naming was not retrieved.
- I didn't verify the Material 3 official "how to read tokens" page (m3.material.io is JS-rendered); the tier names come from Material Web source files.

---

## 4. Theming and modes, including per-platform values

### Takeaway
Three models coexist:
1. **Resolver/permutation files**: the DTCG standard, adopted by Terrazzo 2.x and coming to Style Dictionary.
2. **Per-token inline variants**: Spectrum's `sets` (light/dark/wireframe, desktop/mobile) and Primer's `$extensions.org.primer.overrides`.
3. **Per-mode files**: Figma's export, Primer's override files.

Per-platform values are usually handled either as another modifier/set or as a platform overlay that patches a resolved foundation (Spectrum's platform `manifest.json`). Native runtimes then switch modes themselves: CSS `light-dark()`/media queries, asset-catalog appearances, libadwaita `style-dark.css`/`prefers-contrast`, Compose CompositionLocals.

### Cited Findings
- DTCG resolver: modifiers with `contexts`, one active context per modifier, output = product of contexts. Platform variation is a regular modifier — [Resolver draft](https://www.designtokens.org/tr/drafts/resolver/)
- Terrazzo builds CSS per permutation (`input: {theme: "dark"}` wrapped in `@media (prefers-color-scheme: dark)`) and recommends orthogonal modifiers so `resolutionOrder` never changes the result — [Terrazzo resolvers](https://terrazzo.app/docs/guides/resolvers/)
- Proposed SD resolver output: output paths must vary per permutation, e.g. a template like `'{color-mode}/{density}/variables.css'`. Weave nests directories in modifier order (`dark/high.json`) and bundles the per-permutation CSS into one stylesheet — [SD issue #1590](https://github.com/style-dictionary/style-dictionary/issues/1590)
- **Spectrum** inline sets — [Spectrum color-aliases.json](https://github.com/adobe/spectrum-design-data/blob/main/packages/tokens/src/color-aliases.json); [layout.json](https://github.com/adobe/spectrum-design-data/blob/main/packages/tokens/src/layout.json):
  - Color tokens use `color-set` with `sets: {light, dark, wireframe}`, each an alias (e.g. `accent-background-color-default` → light `{accent-color-900}`, dark `{accent-color-800}`).
  - Layout tokens use `scale-set` with `sets: {desktop: "20px", mobile: "14px"}`.
- **Spectrum per-platform overrides:** a platform team keeps a "platform manifest repo" that pins the foundation version. Its `manifest.json` "cascades over whatever source resolved" via `include`/`exclude` query filters and `overrides`, with CI validation and diff gating — [Spectrum multi-platform SDK strategy](https://github.com/adobe/spectrum-design-data/blob/main/SPECTRUM_MULTIPLATFORM_SDK_STRATEGY.md)
- The iOS manifest is an "incubating proof of concept". It imports 1,118 token records plus iOS state and contrast crosswalks, and three UUID-targeted overrides. Spectrum iOS today merges Figma-derived and hand-authored JSON with an internal `tokentool`, then generates Swift — [Spectrum platforms/ios README](https://github.com/adobe/spectrum-design-data/blob/main/platforms/ios/README.md); [strategy doc](https://github.com/adobe/spectrum-design-data/blob/main/SPECTRUM_MULTIPLATFORM_SDK_STRATEGY.md)
- **Primer** modes — [primer/primitives README](https://github.com/primer/primitives); [bgColor.json5](https://github.com/primer/primitives/blob/main/src/tokens/functional/color/bgColor.json5):
  - "two main color modes: `light` and `dark`" plus accessibility modes built on them, with override files registered in `themes.config.ts`.
  - The published CSS themes are light, light-high-contrast, light-colorblind, light-tritanopia, dark, dark-dimmed, dark-high-contrast, dark-colorblind and dark-tritanopia.
  - Per-token mode overrides sit in `$extensions['org.primer.overrides']` (`dark`, `dark-dimmed`, `dark-high-contrast`, `dark-tritanopia-high-contrast`, …).
- **Figma**: a mode is a column of a variable collection, and export gives one JSON per mode — [atomize.tools](https://atomize.tools/blog/figma-variables-export-json/). In Qt, Figma modes become QML theme objects switched by `activeTheme` — [Figma to Qt](https://doc.qt.io/figmatoqt/figmatoqt-how-to-variables.html)
- **Web runtime:** `light-dark()` is Baseline 2024 (May 2024) and needs `color-scheme: light dark` on `:root`. It also accepts two images — [MDN light-dark()](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/light-dark)
- **Apple runtime:** SwiftUI's `colorSchemeContrast` environment value reports standard or increased contrast from user settings and is read-only — [Apple: colorSchemeContrast](https://developer.apple.com/documentation/swiftui/environmentvalues/colorschemecontrast). A constant SwiftUI `Color(red:green:blue:)` "doesn't have distinct light and dark appearances, unlike… a color that you load from an Asset Catalog" — [Apple: Color.init](https://developer.apple.com/documentation/swiftui/color/init(_:red:green:blue:opacity:)). Asset-catalog colorsets carry variants via `appearances` (e.g. `{"appearance":"luminosity","value":"dark"}`) and `display-gamut` — [Terrazzo plugin-swift source](https://github.com/terrazzoapp/terrazzo/blob/main/packages/plugin-swift/src/index.ts); [Apple Named Color format](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_ref-Asset_Catalog_Format/Named_Color.html)
- **GTK/libadwaita runtime** — [libadwaita styles & appearance](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/styles-and-appearance.html); [libadwaita CSS variables](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/css-variables.html):
  - `AdwApplication` auto-loads `style.css`, `style-dark.css`, `style-hc.css` and `style-hc-dark.css` from the app's resource base path.
  - The docs recommend `@media (prefers-color-scheme: dark)` and `prefers-contrast: more` for mode-specific CSS.
  - High contrast is largely automatic through helper variables: `--border-opacity` 15%→50%, `--dim-opacity` 55%→90%, `--disabled-opacity` 50%→40%. These "should not be overridden".
  - Apps follow the system accent by default. You override it with `:root { --accent-bg-color: … }`, and per-widget overrides must also set `--accent-color`.
- **Compose runtime:** theme values are provided via `staticCompositionLocalOf` plus `CompositionLocalProvider`, with `@Immutable` data classes. The docs suggest a theme class rather than `isSystemInDarkTheme()` extension properties when you have multiple themes — [Android: custom design systems in Compose](https://developer.android.com/develop/ui/compose/designsystems/custom)

### Inferences
- Suggested westron resolver: one foundation set plus orthogonal modifiers:
  - `appearance` (light/dark)
  - `contrast` (standard/high)
  - `platform` (apple-ios/apple-macos/apple-watch/web/gnome/android)
  - optionally `density` and `brand`

  Keep `platform` and `appearance` on disjoint token subsets: platform affects dimension/typography/motion, appearance affects color. That avoids order-dependence and keeps the permutation count manageable.
- **Don't generate one binary per permutation for runtime-switchable modes.** Emit all appearance and contrast values together in each platform's native switching mechanism:
  - CSS: `light-dark()` or `@media (prefers-color-scheme)` plus `prefers-contrast` blocks.
  - Apple: colorset `appearances` (luminosity × contrast).
  - libadwaita: `style-dark.css`/`style-hc.css`.
  - Compose: light and dark `ColorScheme` instances.

  Build-time-only modifiers like `platform` select which file set gets generated.
- A Spectrum-style "platform overlay" (a small per-platform overrides file applied after the foundation) is the simplest way to model "value differs on watch vs iOS vs web" without forking tokens.

### Gaps
- The Apple asset-catalog JSON keys for the high-contrast appearance (`"appearance": "contrast", "value": "high"`) were not confirmed from an Apple primary source in this session. The archived Named Color page doesn't list appearances.
- I found no published example of a major system expressing watchOS-specific token values.

---

## 5. Color: perceptual palettes, wide gamut, contrast, native mapping

### Takeaway
The current toolchain is OKLCH- or HCT-based palette generation with P3-capable output and sRGB fallback, checked against **WCAG 2.x contrast**. APCA is not part of WCAG 3, whose contrast algorithm is still undecided as of April 2026. DTCG can now store OKLCH/P3 values natively with a hex fallback, and Style Dictionary 5.3+ converts them to `oklch()`/`color(display-p3)` on the web. On Apple, P3 colors go into colorsets (`display-p3`) or SwiftUI `Color(.displayP3, …)`. GTK 4.16+ understands `oklab()`/`oklch()`, `color-mix()` and relative colors.

### Cited Findings
- **DTCG** stores `oklch`, `display-p3`, `rec2020` and others natively with an optional `hex` sRGB fallback. Gamut mapping is left to tools — [DTCG Color draft](https://www.designtokens.org/tr/drafts/color/)
- **Style Dictionary 5.3.0** has `color/oklch`, `color/oklab`, `color/p3` and `color/lch` transforms and uses `hex` as the out-of-gamut fallback — [SD CHANGELOG](https://github.com/style-dictionary/style-dictionary/blob/main/CHANGELOG.md). Terrazzo's Swift plugin gamut-maps everything into P3 (colorjs.io) before writing colorsets — [plugin-swift source](https://github.com/terrazzoapp/terrazzo/blob/main/packages/plugin-swift/src/index.ts)
- **Tailwind v4**'s default palette is defined in OKLCH as CSS variables in `@theme`, e.g. `--color-blue-500: oklch(62.3% 0.214 259.815)`, with 11 steps (50, 100…900, 950). You customize it by overriding `--color-*` (`--color-*: initial` clears the palette) — [Tailwind colors docs](https://tailwindcss.com/docs/colors)
- **Radix Colors** use 12 steps with fixed semantics — [Radix: understanding the scale](https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale):
  - 1–2: app/subtle backgrounds.
  - 3–5: component backgrounds (default/hover/pressed).
  - 6–8: borders (subtle → focus rings).
  - 9–10: solid fills (9 is the highest chroma; 10 is its hover).
  - 11–12: text. These are guaranteed APCA Lc 60 and Lc 90 on step 2 of the same scale.

  For dark mode, Radix uses a different app-background alias.
- Radix v3.0.0 CSS ships sRGB hex plus P3 overrides inside `@supports (color: color(display-p3 1 1 1)) { @media (color-gamut: p3) { --blue-1: color(display-p3 0.986 0.992 0.999); … } }` — [@radix-ui/colors@3.0.0 blue.css](https://unpkg.com/@radix-ui/colors@3.0.0/blue.css)
- **Adobe Leonardo** generates swatches "by target contrast ratios" (or target lightness) in a choice of color spaces. Adaptive themes produce dark mode by adjusting brightness. It exports parameters for `@adobe/leonardo-contrast-colors`, CSS custom properties and "Design Tokens" — [leonardocolor.io](https://leonardocolor.io/); the repo was active in 2026 (last push Jul 2026) — [adobe/leonardo](https://github.com/adobe/leonardo)
- **Material Color Utilities** — [material-color-utilities README](https://github.com/material-foundation/material-color-utilities):
  - HCT ("hue, chrome, tone", based on CAM16 × L*).
  - Tonal and core palettes.
  - `scheme` (static and dynamic schemes from one color).
  - `dynamiccolor` (adapts to dark theme, contrast level and other preferences).
  - `contrast` utilities.

  Official ports exist for C++, Dart, Java, Kotlin, Swift and TypeScript. The repo is active (pushed Nov 2026).
- **Contrast standard status (April 2026):** "The contrast algorithm used in WCAG 3 is yet to be determined." APCA was marked for removal in early 2023 and dropped from the July 2023 WCAG 3 working draft. WCAG 3 is "years away… perhaps 2030". The advice is to keep meeting WCAG 2 contrast, document any deliberate deviations, and not treat APCA as "WCAG 3" — [Adrian Roselli, "WCAG3 Contrast as of April 2026"](https://adrianroselli.com/2026/04/wcag3-contrast-as-of-april-2026.html). Many blogs still claim APCA is "coming with WCAG 3"; these are outdated — [search summary incl. Roselli](https://adrianroselli.com/2026/04/wcag3-contrast-as-of-april-2026.html)
- **SwiftUI:** `Color` uses an extended sRGB space, so component values outside 0–1 are allowed, which "makes it possible to create colors using the [display P3] color space that make full use of the wider gamut" — [Apple: Color.init(_:red:green:blue:opacity:)](https://developer.apple.com/documentation/swiftui/color/init(_:red:green:blue:opacity:)); `Color.RGBColorSpace` "specifies how to interpret a color value for display" — [Apple: RGBColorSpace](https://developer.apple.com/documentation/swiftui/color/rgbcolorspace)
- **Asset catalogs:** a colorset `Contents.json` holds `colors[]` entries with `idiom`, an optional `display-gamut` (`sRGB` / `display-P3`) and `color.color-space` (`srgb`, `display-p3`, …) with float `components` — [Apple Named Color format (archived)](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_ref-Asset_Catalog_Format/Named_Color.html)
- **GTK/libadwaita:** GTK supports CSS custom properties and `var()` "since 4.16"; `@define-color` is superseded — [GTK CSS properties](https://docs.gtk.org/gtk4/css-properties.html) (via search snippet). GTK lists "hwb(), oklab(), oklch(), color(), color-mix() and relative colors" as supported — [GTK CSS properties](https://docs.gtk.org/gtk4/css-properties.html). The libadwaita 1.6 release notes say: "GTK now supports CSS variables, as well as color-mix(), relative colors, as well as new color spaces, most importantly Oklab and Oklch" — [Alice Mikhaylenko, Libadwaita 1.6](https://blogs.gnome.org/alicem/2024/09/)
- libadwaita derives standalone accent colors in Oklab: `--accent-color: oklab(from var(--accent-bg-color) var(--standalone-color-oklab))`, with `min(l, 0.5)` in light and `max(l, 0.85)` in dark. Such colors "need to be gamut mapped" — [libadwaita CSS variables](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/css-variables.html)

### Inferences
- Westron palette approach:
  1. Author or generate primitives in **OKLCH** (Tailwind-style even lightness steps, or Radix-style 12-step semantic scales). Use HCT/Material Color Utilities if you want Material-style dynamic schemes on Android later.
  2. Store them as DTCG color objects with `colorSpace: "oklch"` plus a `hex` fallback.
  3. Emit `oklch()`/`color(display-p3)` with an sRGB fallback on the web, `display-p3` colorsets on Apple, and `oklch()`/hex in GTK CSS. libadwaita accepts oklch, but most GNOME displays are sRGB, so emit hex or gamut-mapped values.
- Run **WCAG 2.x contrast checks in CI** on every semantic fg/bg pair in every mode. APCA Lc can be added as an advisory metric, as Radix does, but it is not a compliance standard.
- Use one color-math library everywhere (colorjs.io is what Terrazzo uses) so gamut mapping is consistent across targets.

### Gaps
- Android wide-gamut handling (Compose `Color` with `ColorSpaces.DisplayP3`, and Android resource limits) was not verified from primary docs in this session.
- Leonardo's supported interpolation spaces and contrast formulas weren't listed on the fetched page.
- Radix's dark-scale P3 specifics weren't checked beyond the blue light file.

---

## 6. Typography, spacing, radius, elevation and motion across platforms

### Takeaway
DTCG gives you px/rem dimensions, a `typography` composite (lineHeight as a multiplier), `duration`, `cubicBezier` and `transition`. Converting them to each platform's conventions is the generator's job:
- rem → pt via SD's `size/remToPt` or `size/remToFloat` on Apple.
- `size/compose/sp|dp` on Android.
- Dynamic Type scaling via `Font.custom(_:size:relativeTo:)` and `@ScaledMetric` in SwiftUI.
- pt-based font sizes in libadwaita.

Springs are the main gap. SwiftUI and Material 3 Expressive (Compose `MotionScheme`) are spring-first, but DTCG has no spring type (issue #429), so spring tokens must live in `$extensions` or as `number` groups.

### Cited Findings
- DTCG `dimension` units are `px` and `rem` only. `typography` = `{fontFamily, fontSize, fontWeight, letterSpacing, lineHeight}`, with lineHeight a number "read as a multiplier of fontSize". Motion primitives are `duration`, `cubicBezier` and `transition` — [Format draft](https://www.designtokens.org/tr/drafts/format/)
- Style Dictionary conversions — [SD CHANGELOG](https://github.com/style-dictionary/style-dictionary/blob/main/CHANGELOG.md):
  - `size/compose/{sp,dp}` (5.1.0).
  - `size/remToPt` (fixed in 5.4.0) and `size/remToFloat` (iOS transformGroup).
  - `time/seconds` handles DTCG duration objects with minimal decimals, and `transition/css/shorthand` handles them too (5.7.0).
- **Apple:**
  - `Font.custom(_:size:relativeTo:)` creates "a custom font with the given name and size that scales relative to the given textStyle" (iOS 14, macOS 11, watchOS 7, visionOS 1) — [Apple docs](https://developer.apple.com/documentation/swiftui/font/custom(_:size:relativeto:))
  - `@ScaledMetric` is "a dynamic property that scales a numeric value", usable for Dynamic Type-aware spacing and radius (same OS minimums) — [Apple: ScaledMetric](https://developer.apple.com/documentation/swiftui/scaledmetric)
  - `Font.TextStyle` is "a dynamic text style to use for fonts" — [Apple: Font.TextStyle](https://developer.apple.com/documentation/swiftui/font/textstyle)
  - SwiftUI has `Animation.spring(duration:bounce:blendDuration:)`, a persistent spring that preserves velocity when retargeted — [Apple: spring(duration:bounce:blendDuration:)](https://developer.apple.com/documentation/swiftui/animation/spring(duration:bounce:blendduration:))
- **Android/Compose:**
  - Compose design systems express type in `sp` and sizes and elevation in `dp`, e.g. `TextStyle(fontSize = 16.sp)` and `CustomElevation(default = 4.dp, pressed = 8.dp)`. Elevation can be a custom theme subsystem — [Android: custom design systems](https://developer.android.com/develop/ui/compose/designsystems/custom)
  - Material 3's `MotionScheme` (material3, common code) provides `standard()` ("linear motion feel", for utilitarian UI) and `expressive()` ("visually engaging", for hero interactions). Each has six specs: `{fast,default,slow}SpatialSpec` (for bounds or shape changes) and `{fast,default,slow}EffectsSpec` (color/alpha, "non-spatial") — [Android: MotionScheme](https://developer.android.com/reference/kotlin/androidx/compose/material3/MotionScheme)
  - Community sources give **conflicting** M3 Expressive spring values. For expressive default spatial: stiffness 380 with damping 0.73 vs 0.8. Others give fast spatial 800/0.6 or 1400/0.9. None of these is an official Google source — [search summary: pub.dev material_expressive and others](https://pub.dev/documentation/material_expressive/0.8.0/)
- **Web:** springs are approximated with CSS `linear()`, per the DTCG motion issue — [DTCG issue #429](https://github.com/design-tokens/community-group/issues/429). Primer keeps `base/motion/easing.json5` and `base/motion/timing.json5` primitives plus functional motion tokens — [primer/primitives tree](https://github.com/primer/primitives/tree/main/src/tokens)
- **GNOME:**
  - libadwaita font variables: `--document-font-family` (Adwaita Sans), `--document-font-size` (12pt), `--monospace-font-family` (Adwaita Mono) and `--monospace-font-size` (11pt). Use family and size together.
  - Radius: `--window-radius: 15px`.

  — [libadwaita CSS variables](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/css-variables.html)
- **Platform-scale dimensions in practice:** Spectrum's `scale-set` gives desktop vs mobile values (e.g. 20px vs 14px horizontal padding at 2x-large) — [Spectrum layout.json](https://github.com/adobe/spectrum-design-data/blob/main/packages/tokens/src/layout.json). Primer has density and viewport scale modifiers — [Primer token names](https://primer.style/product/primitives/token-names)

### Inferences
- **Typography:** don't tokenize absolute font sizes as the cross-platform truth. Tokenize **semantic text roles** (`text.body`, `text.title`, `text.caption`…), each with:
  - a base size (px)
  - a lineHeight multiplier
  - weight, tracking and family
  - an Apple `relativeTo` text-style mapping in `$extensions` (e.g. `"dev.westron.apple": {"textStyle": "body"}`)

  Generate SwiftUI `Font.custom(..., relativeTo:)` (or the system font with `.body` etc.), rem on the web, `sp` on Compose, and pt in GTK CSS.
- **Spacing and radius:** a numeric scale (4- or 8-based) in px. Generate `CGFloat` constants (optionally wrapped by `@ScaledMetric` at call sites), rem/px in CSS and dp in Compose. Put per-platform deltas (e.g. watchOS tighter insets, macOS denser controls) in the `platform` modifier.
- **Motion:** model `motion.spring.{fast,default,slow}.{spatial,effects}` as a group of `number` tokens (`stiffness`, `dampingRatio` or `response`/`bounce`) under a westron `$extensions` type until DTCG adds a spring type. Generate `Animation.spring(...)` / `Spring` on Apple, `spring(dampingRatio, stiffness)` / a custom `MotionScheme` on Compose, and `linear()` approximations or `cubicBezier` fallbacks on the web and GTK. Also keep plain `duration` and `cubicBezier` tokens for reduced-motion and CSS fallbacks.
- **Elevation:** keep it semantic (`elevation.raised`, `elevation.overlay`) and map it per platform: DTCG `shadow` on web and GTK, `dp` + tonal surface on Compose. Apple mostly uses materials and shadows sparingly, so mapping needs per-platform decisions rather than one value.

### Gaps
- Apple's 2025 design-language changes (Liquid Glass materials) and how teams tokenize materials and blur were not researched here.
- No official M3 Expressive spring numbers were obtained (m3.material.io is JS-rendered, and the androidx source wasn't read).
- `SwiftUI.Spring`/`spring(duration:bounce:)` minimum OS versions weren't verified (the JSON doc metadata returned an aggregate of iOS 13).

---

## 7. Consuming tokens natively: Swift, Compose, CSS, Linux; build integration

### Takeaway
Native-first teams usually **commit generated, platform-idiomatic code**: Swift files and/or asset catalogs in a Swift Package, a Kotlin `object` or CompositionLocal theme in a Gradle module, and CSS custom properties in an npm package. All are produced by a Node-based generator (Style Dictionary/Terrazzo) run in CI. Asset catalogs are the Apple-native way to get light/dark/high-contrast and P3 switching for free. Generated Swift code is better for non-color tokens and for a typed API. A hybrid of colorsets plus generated Swift accessors is common, but needs care because Xcode's generated asset symbols are `internal`.

### Cited Findings
- **Swift options in existing tools:**
  - SD `ios-swift/*` formats generate a `public class|enum|struct` of static UIKit values (`import UIKit` by default) — [SD predefined formats](https://styledictionary.com/reference/hooks/formats/predefined/)
  - Terrazzo generates an `.xcassets` catalog of colorsets only — [Terrazzo Swift](https://terrazzo.app/docs/integrations/swift/); [source](https://github.com/terrazzoapp/terrazzo/blob/main/packages/plugin-swift/src/index.ts)
  - Spectrum iOS uses an in-house `tokentool generate-source-code` to emit Swift — [Spectrum strategy doc](https://github.com/adobe/spectrum-design-data/blob/main/SPECTRUM_MULTIPLATFORM_SDK_STRATEGY.md)
- **Asset catalogs in Swift packages:**
  - Since Xcode 15, Xcode generates asset symbols: colors become static properties on `ColorResource` (images on `ImageResource`), plus SwiftUI/UIKit/AppKit extensions — [sarunw](https://sarunw.com/posts/swift-symbols-for-asset-catalog/); [Use Your Loaf](https://useyourloaf.com/blog/disabling-xcode-asset-symbol-generation/)
  - Generated symbols are **internal only**, so a design-system package must write its own `public` accessors (e.g. via `Bundle.module`). Xcode 16 added a per-catalog "Asset Symbols" inspector setting, and `ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOLS=NO` disables generation — [Apple Developer Forums thread 734387](https://developer.apple.com/forums/thread/734387); [Use Your Loaf](https://useyourloaf.com/blog/disabling-xcode-asset-symbol-generation/)
  - SwiftPM creates a resource bundle per target, accessed as `Bundle.module`. Cross-package test access to another package's `Bundle.module` has known pitfalls — [Swift Forums](https://forums.swift.org/t/does-spm-support-colors-in-asset-catalogs/54941)
- **Compose:** SD `compose/object` gives a Kotlin `object` of `Color`/`dp`/`sp` vals — [SD predefined formats](https://styledictionary.com/reference/hooks/formats/predefined/). Google's guidance for a non-Material system:
  - `@Immutable` data classes per subsystem (colors, typography, elevation).
  - `staticCompositionLocalOf` defaults.
  - A `CustomTheme { CompositionLocalProvider(...) }` composable.
  - An `object CustomTheme { val colors @Composable get() = LocalCustomColors.current }` accessor.
  - Wrap Material components, or build from scratch when you introduce new types (e.g. gradients as `List<Color>`).

  — [Android: custom design systems in Compose](https://developer.android.com/develop/ui/compose/designsystems/custom)
- **CSS:**
  - SD `css/variables` with `selector` and `outputReferences` (emits `var(--x)` chains) — [SD predefined formats](https://styledictionary.com/reference/hooks/formats/predefined/)
  - Terrazzo CSS permutations wrap each mode in a selector or media query — [Terrazzo resolvers](https://terrazzo.app/docs/guides/resolvers/)
  - Primer ships per-theme CSS files (`@primer/primitives/dist/css/functional/themes/light.css`, `dark-high-contrast.css`, …) via npm — [primer/primitives README](https://github.com/primer/primitives)
  - Material Web emits `--md-sys-color-*` properties with fallbacks `var(--md-sys-color-#{$token}, #{$value})` — [material-web tokens](https://github.com/material-components/material-web/blob/main/tokens/_md-sys-color.scss)
- **GTK/libadwaita consumption:**
  - Ship `style.css`, `style-dark.css` and `style-hc.css` in the app's GResource base path, loaded automatically by `AdwApplication` — [libadwaita styles & appearance](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/styles-and-appearance.html)
  - Override libadwaita's named variables (`--accent-bg-color`, `--window-bg-color`, `--view-bg-color`, `--card-bg-color`, `--headerbar-*`, `--popover-*`, `--dialog-*`, palette `--blue-1…5` etc.) on `:root`. Don't override the helper opacities — [libadwaita CSS variables](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/css-variables.html)
  - Requires GTK ≥ 4.16 for `var()` — [GTK CSS properties](https://docs.gtk.org/gtk4/css-properties.html)
- **Qt consumption:** QML singletons per collection (`DesignTokens` module, or `Primitives.qml`/`Theme.qml`/`Spacing.qml`) registered as `QT_QML_SINGLETON_TYPE` in CMake; Qt 6.5+ for the Qt skill — [Qt agentic skill](https://doc.qt.io/agentictools/skills/qt-figma-token-extraction/); [Figma to Qt](https://doc.qt.io/figmatoqt/figmatoqt-how-to-variables.html)
- **Build tooling constraints:**
  - Style Dictionary 5 requires Node ≥ 22 — [SD v5 migration](https://styledictionary.com/versions/v5/migration/)
  - Terrazzo needs Node and `npx tz build` — [plugin-swift README](https://github.com/terrazzoapp/terrazzo/blob/main/packages/plugin-swift/README.md)
  - Spectrum lists native FFI distribution (Swift Package via UniFFI, Android AAR via JNI, Qt/C++ via FFI) as "future" or aspirational, so today it distributes data plus CLI rather than native binaries — [Spectrum strategy doc](https://github.com/adobe/spectrum-design-data/blob/main/SPECTRUM_MULTIPLATFORM_SDK_STRATEGY.md)

### Inferences
- Recommended westron pipeline:
  1. `tokens/*.tokens.json` (DTCG 2025.10) plus `westron.resolver.json`.
  2. A Node script (SD 5 with custom formats, or Terrazzo 2 with custom plugins) resolves the build-time permutations, mainly `platform`.
  3. It writes into each platform package:
     - **Apple:** a Swift Package containing `Colors.xcassets` (colorsets with any/dark × standard/high-contrast appearances, display-p3 + sRGB) and generated `Tokens.swift` with `public` static accessors. Colors use `Color("name", bundle: .module)`; spacing, radius and durations are `CGFloat`/`Double` constants; fonts use `Font.custom(..., relativeTo:)`; springs are `Animation` factories.
     - **Web:** an npm package with CSS custom properties (light-dark()/media blocks) plus typed TS constants.
     - **GNOME:** a `westron-gtk` data dir with `style.css`/`style-dark.css`/`style-hc.css` mapping westron semantics onto libadwaita variables.
     - **Qt (optional):** QML singletons.
     - **Rust (optional):** a `consts.rs` for native Linux code.
     - **Android (later):** a Gradle module with a CompositionLocal-based `WestronTheme`.
  4. Commit generated outputs, so SwiftPM/Gradle consumers don't need Node, and gate PRs with a CI diff check.
- Avoid running Node inside a SwiftPM build-tool plugin. Committed artifacts keep Xcode builds hermetic and fast. This is an inference: I found no primary source on SwiftPM plugin sandboxing for Node in this session.
- Generate an "AI usage" doc or JSON from `$description` plus `$extensions` usage rules (the Primer `org.primer.llm` pattern) so the coding agent picks semantic tokens rather than primitives.

### Gaps
- No primary documentation was retrieved for SwiftPM build-tool plugins running token generators, or for Gradle plugins wrapping Style Dictionary.
- Apple's official colorset `appearances` schema for high contrast and its asset-catalog behavior on watchOS were not confirmed.
- No libadwaita version-introduction date for CSS variables was found on the docs pages themselves. The "GTK 4.16 / libadwaita 1.6" attribution comes from the GTK docs and the libadwaita 1.6 blog via search snippets.
