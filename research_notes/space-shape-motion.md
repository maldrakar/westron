# Space, density, shape, elevation and motion: research for westron

Date: 2026-11-15. Scope: space and density, shape, elevation and layering, motion, and how these knobs can carry
three distinct visual directions on native platforms. Color and fonts are out of scope (researched separately), except
where density touches text size.

Method. Numbers come from primary sources wherever they could be read: published design-system pages, token
packages and component source code (Primer, Spectrum, Fluent, Material's Compose implementation, libadwaita and GTK),
Apple's documentation and HIG (read through Apple's documentation JSON), and W3C documents. Where a page could not be
read (m3.material.io and s2.spectrum.adobe.com render client-side), the numbers come from the system's own shipped
code, and the report says so. Spring conversions in section 4.7 were computed, not quoted. Everything that could not
be verified is collected in section 7.

---

## 0. Key findings

1. **No surveyed system rescales its whole space scale for density.** Density changes component-internal metrics:
   control and row heights, cell and inline padding, gaps inside groups. Page margins, section spacing and type sizes
   stay put. Typical compact rows are 20–25 % shorter than default rows, and cell padding roughly halves.
2. **The convergent web/desktop control ladder is 24 / 32 / 40 px** (Primer, Fluent, Spectrum desktop, Carbon's xs
   to md sizes), on a 4 px grid with an 8 px "100" step (Atlassian, Carbon, Spectrum). Touch platforms keep 44 pt
   (Apple) and 48 dp (Material) targets; WCAG 2.2 AA asks for 24 × 24 CSS px.
3. **Corners got rounder in 2024–2026, and the rule that holds them together is concentricity.** libadwaita raised
   button radii from 6 to 9 px and windows from 12 to 15 px, Spectrum 2 moved to size-dependent radii up to 16 px plus
   pills, Material 3 Expressive added 20/32/48 dp steps and shape morphing, and Apple built its Liquid Glass layout on
   "fixed, capsule, concentric" shapes. The pushback is real too: large radii cost density, and macOS 26's
   inconsistent window corners were being corrected in macOS 27.
4. **A useful single knob for "character" is the ratio of corner radius to element height**: about 0.12–0.19 in
   precise systems (Fluent, Primer), about 0.25–0.3 in neutral-soft ones (Spectrum 2, libadwaita, Material's square
   buttons), and 0.5 (capsules) in expressive ones (Apple's large controls, M3 Expressive's round buttons).
5. **Dark themes raise elevation by making surfaces lighter**, and make their shadows 2–5 times denser (Fluent ×2,
   Spectrum ×3, libadwaita ×5 for the card shade). **High-contrast modes turn borders into the boundary**: libadwaita
   raises its border opacity from 15 % to 50 % and outlines cards, macOS Increase Contrast adds borders, and CSS forced
   colors computes `box-shadow` to `none`.
6. **Springs are the shared motion primitive.** SwiftUI's springs, Compose's `spring()`, libadwaita's
   `AdwSpringAnimation` and Material's motion scheme all use the same physics. An Apple-style `(duration, bounce)`
   pair converts exactly to `(stiffness, damping ratio)`, and CSS can play the same spring through `linear()`, Baseline
   "widely available" since June 2026. GTK CSS is the one target without `linear()`.
7. **Material 3 Expressive's motion scheme is the best template for a token set**: fast, default and slow springs,
   each split into *spatial* (may bounce) and *effects* (color and opacity, never bounce), with a *standard* and an
   *expressive* tuning. That mirrors Carbon's older productive/expressive split.
8. **Reduce Motion converges across platforms**: no bounce (damping ratio 1), fades instead of travel, keep the
   delays that let people read. libadwaita 1.9 does exactly this in its own widgets.
9. **The three directions can stay native** if they vary only content-layer knobs (spacing rhythm, radius ratio,
   elevation strategy, spring tuning) and hold the platform-owned ones fixed (system controls, hit targets, corner
   curve, Liquid Glass, Dynamic Type, Reduce Motion behavior). Each direction will look most at home on a different
   platform; the specimens should show that honestly.

---

## 1. Space and density

### 1.1 What each system ships

| System | Base unit and scale | Control heights | Table / list rows | Dense body text | Density mechanism |
|---|---|---|---|---|---|
| IBM Carbon | "Multiples of two, four, and eight": 2, 4, 8, 12, 16, 24, 32, 40, 48, 64, 80, 96, 160 px ([spacing](https://carbondesignsystem.com/elements/spacing/overview/)) | Buttons 24 (xs), 32 (sm), 40 (md), 48 (lg), 64, 80 px ([button style](https://carbondesignsystem.com/components/button/style/)) | Data table rows 24 / 32 / 40 / 48 / 64 px (xs–xl); header row matches row size ([data table style](https://carbondesignsystem.com/components/data-table/style/)) | Productive set: `body-compact-01` 14/18 px, `body-01` 14/20, `code-01` 12/16 ([type sets](https://carbondesignsystem.com/elements/typography/type-sets/)) | Size variants per component; productive (14 px base) vs expressive (16 px base) type sets |
| GitHub Primer | `base-size-*`: 2, 4, 6, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 64, 80, 96, 112, 128 px ([size primitives](https://primer.style/product/primitives/size/)) | xsmall 24, small 28, medium 32, large 40, xlarge 48 px; inline padding condensed / normal / spacious = 8 / 12 / 16 px ([size primitives](https://primer.style/product/primitives/size/)) | DataTable cell padding condensed 4/8, normal 8/12, spacious 12/16 px with 12 px text on a 20 px line, so rows of about 28 / 36 / 44 px plus a 1 px rule ([Table.module.css](https://github.com/primer/react/blob/main/packages/react/src/DataTable/Table.module.css)) | 12 px in tables; 14 px elsewhere | Named padding modes on tokens (`stack-gap-condensed/normal/spacious` = 8 / 16 / 24 px) and on components (`cellPadding`) |
| Atlassian | 8 px base: `space.025` 2 … `space.100` 8 … `space.1000` 80, in small (0–8), medium (12–24) and large (32–80) ranges ([spacing](https://atlassian.design/foundations/spacing)) | Buttons: "Default spacing is used for most use cases, compact for tables" ([button](https://atlassian.design/components/button/examples)); the compiled CSS carries heights of 2rem and 1.5rem ([button-base.compiled.css](https://unpkg.com/@atlaskit/button@25.8.1/dist/cjs/new-button/variants/shared/button-base.compiled.css)) | — | — | Small-range spacing for "badges, icon buttons, and table cells"; compact component props |
| Adobe Spectrum 2 | 1, 2, 4, 6, 8, 12, 16, 20, 24, 32, 40, 48, 64, 80, 96 px ([layout.json](https://github.com/adobe/spectrum-design-data/blob/main/packages/tokens/src/layout.json)) | `component-height-50…500`: desktop 20, 24, 32, 40, 48, 56, 64; mobile 26, 30, 40, 50, 60, 70, 80 px ([layout.json](https://github.com/adobe/spectrum-design-data/blob/main/packages/tokens/src/layout.json)) | Table rows per size × density: medium 40 regular, 32 compact, 48 spacious (desktop); mobile ×1.25 ([table.json](https://github.com/adobe/spectrum-design-data/blob/main/packages/tokens/src/table.json)) | `font-size-100` 14 px desktop, 17 px mobile ([typography.json](https://github.com/adobe/spectrum-design-data/blob/main/packages/tokens/src/typography.json)) | A *platform scale* (desktop vs mobile, 1.25×) plus per-component compact/regular/spacious tokens |
| Material 3 (Compose) | 4 dp increments (not re-verified, see section 7) | M3 Expressive buttons XS 32, S 40, M 56, L 96, XL 136 dp ([ButtonSmallTokens.kt and siblings](https://github.com/androidx/androidx/tree/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens)) | List items 56 / 72 / 88 dp for one, two and three lines ([ListTokens.kt](https://github.com/androidx/androidx/blob/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/ListTokens.kt)); no data table | `bodyMedium` 14/20, `bodySmall` 12/16 ([Compose M3 guide](https://developer.android.com/develop/ui/compose/designsystems/material3)) | No density system found in M3; M2/MDC had a density scale of −4 dp per step ([@material/density](https://cdn.jsdelivr.net/npm/@material/density@14.0.0/README.md)); the 48 dp minimum is enforced by `minimumInteractiveComponentSize` ([Compose a11y defaults](https://developer.android.com/develop/ui/compose/accessibility/api-defaults)) |
| Microsoft Fluent 2 | 2, 4, 6, 8, 10, 12, 16, 20, 24, 32 px (with "nudge" steps at 6 and 10) ([spacings.ts](https://github.com/microsoft/fluentui/blob/master/packages/tokens/src/global/spacings.ts)) | Buttons small 24, medium 32, large 40 px (line height plus padding plus border, from [useButtonStyles](https://github.com/microsoft/fluentui/blob/master/packages/react-components/react-button/library/src/components/Button/useButtonStyles.styles.ts)) | Table rows medium 44, small 34, extra-small 24 px ([useTableRowStyles](https://github.com/microsoft/fluentui/blob/master/packages/react-components/react-table/library/src/components/TableRow/useTableRowStyles.styles.ts)) | 14/20 base, 12/16 small | Size variants |
| GNOME libadwaita | No published scale; the stylesheet works in 6 px steps: 6 px menu margin, 12 px padding, 6/12 px `border-spacing` ([_common.scss](https://github.com/GNOME/libadwaita/blob/main/src/stylesheet/_common.scss)) | Buttons 34 px (24 px min-height + 5 px padding); circular buttons 34 × 34 ([_buttons.scss](https://github.com/GNOME/libadwaita/blob/main/src/stylesheet/widgets/_buttons.scss)) | Boxed-list rows min 50 px, rich-list rows min 32 px ([_lists.scss](https://github.com/GNOME/libadwaita/blob/main/src/stylesheet/widgets/_lists.scss)); column-view cells 8 × 6 px padding, shrunk to 2 px vertical by the `.data-table` style class ([_column-view.scss](https://github.com/GNOME/libadwaita/blob/main/src/stylesheet/widgets/_column-view.scss)) | — | One style class (`.data-table`) for dense tables; no global density |
| Apple | No published grid. Spacing advice: about 12 pt around bezeled elements, 24 pt around unbezeled ones ([HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)) | `ControlSize` mini, small, regular, large, extraLarge cascades through the environment ([controlSize](https://developer.apple.com/documentation/swiftui/view/controlsize(_:))) | Lists use `defaultMinListRowHeight`, a minimum, never a fixed height ([docs](https://developer.apple.com/documentation/swiftui/environmentvalues/defaultminlistrowheight)) | iOS Body 17/22 pt, macOS Body 13/16 pt ([HIG Typography](https://developer.apple.com/design/human-interface-guidelines/typography)) | `controlSize` per subtree; the Mac is denser by platform, not by mode |
| Linear | No published numbers. The March 2026 refresh aimed at "preserving that rich density of information without letting the interface feel overwhelming", with fewer separators and softer contrast ([Linear, 2026-03-12](https://linear.app/now/behind-the-latest-design-refresh)) | — | — | — | Visual-weight reduction rather than metric changes |

Two macOS details from WWDC25 matter for density: "Mini, Small, and Medium controls will continue using rounded
rectangles, making them a great fit for compact, high-density layouts like inspector panels. Large controls will now
use capsule shapes, alongside with the new X-Large size" ([WWDC25 session 356](https://developer.apple.com/videos/play/wwdc2025/356/)).
Capsules "bring focus and clarity to touch-friendly layouts, but in dense desktop environments, they're best used for
standout actions" (same session).

### 1.2 Patterns behind the numbers

Six ways of doing density show up, and they combine:

| Pattern | Example | What it changes |
|---|---|---|
| Size variants | Carbon xs–xl buttons and rows; Fluent small/medium/large | The component's height, chosen per instance |
| Padding modes | Primer condensed/normal/spacious | Inline padding and gaps, not the scale |
| Platform scale | Spectrum desktop vs mobile, 1.25× | Every component dimension, by input type |
| Density steps | Material 2: −4 dp per step, with touch targets disabled when density is applied ([@material/density](https://cdn.jsdelivr.net/npm/@material/density@14.0.0/README.md)) | Height, in fixed steps |
| Style class | libadwaita `.data-table` | Only vertical cell padding, 8 → 2 px |
| Environment cascade | SwiftUI `controlSize` | System controls in a subtree |

What they share:

- **The base scale never changes.** Density picks different steps or different role tokens; nobody redefines what
  "16 px" means in compact mode. Carbon even keeps its spacing tokens the same across screen sizes and asks you to
  step down the scale at breakpoints instead ([spacing](https://carbondesignsystem.com/elements/spacing/overview/)).
- **Compact is about 20–25 % shorter.** Spectrum medium rows 40 → 32 (−20 %), Primer table rows about 37 → 29
  (−22 %), Carbon md → sm buttons 40 → 32 (−20 %), Fluent table rows 44 → 34 (−23 %). libadwaita's `.data-table`
  goes further (about −33 %).
- **Padding halves; height drops one step of 8 px.** Primer's normal → condensed cell padding is 8/12 → 4/8;
  libadwaita's is 8 → 2 vertical.
- **Type size is not the density lever.** Dense components choose a smaller *role* (Primer's 12 px table text,
  Carbon's 14 px productive set); Carbon tightens line height instead (`body-compact-01` 14/18 against `body-01`
  14/20). westron's principle that density never changes text sizes matches this.
- **Touch targets are a floor that density must not break.** Material 2 explicitly turned touch targets off when
  density was applied, which is the trap to avoid.

### 1.3 Minimum hit targets

| Platform | Default | Minimum | Source |
|---|---|---|---|
| iOS, iPadOS | 44 × 44 pt | 28 × 28 pt | [HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility) |
| macOS | 28 × 28 pt | 20 × 20 pt | same |
| watchOS | 44 × 44 pt | 28 × 28 pt | same |
| visionOS | 60 × 60 pt | 28 × 28 pt | same |
| Android (Material) | 48 × 48 dp, enforced by `minimumInteractiveComponentSize` | — | [Compose a11y defaults](https://developer.android.com/develop/ui/compose/accessibility/api-defaults) |
| Web, WCAG 2.2 AA (2.5.8) | 24 × 24 CSS px, or 24 px spacing circles | — | [Understanding 2.5.8](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html) |
| Web, WCAG 2.5.5 (enhanced) | 44 × 44 CSS px | — | same page |
| Primer | `minTarget` fine pointer 16 px, coarse pointer 44 px | — | [size-fine](https://github.com/primer/primitives/blob/main/src/tokens/functional/size/size-fine.json5), [size-coarse](https://github.com/primer/primitives/blob/main/src/tokens/functional/size/size-coarse.json5) |
| GNOME | "Click targets should be large enough to be comfortably used with different pointing devices" (no number) | — | [GNOME HIG Pointer & Touch](https://developer.gnome.org/hig/guidelines/pointer-touch.html) |

Note an inconsistency inside the HIG: the Buttons page says "a button needs a hit region of at least 44x44 pt — in
visionOS, 60x60 pt" ([HIG Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons)), while the
Accessibility table gives macOS 28 × 28. The platform table is the better source for a pointer platform.

---

## 2. Shape

### 2.1 Radius scales in 2024–2026

| System | Scale | What changed recently |
|---|---|---|
| Apple (iOS/macOS 26+) | No published radius scale. Three shape types: "fixed shapes have a constant corner radius. Capsules use a radius that's half the height of the container. And concentric shapes calculate their radius by subtracting padding from the parent's" ([WWDC25 356](https://developer.apple.com/videos/play/wwdc2025/356/)) | Capsules everywhere on touch; on macOS large controls become capsules, smaller ones stay rounded rectangles (same session). Window corner radii on macOS 26 varied by window style and drew criticism for wasting space ([Michael Tsai's roundup](https://mjtsai.com/blog/2025/10/16/tahoe-window-corners)); coverage of the WWDC26 betas says "All apps in macOS 27 will feature a consistent corner radius" ([Cult of Mac, 2026-06-09](https://www.cultofmac.com/news/liquid-glass-changes-ios-27-macos-27)) |
| Material 3 Expressive | none 0, extra-small 4, small 8, medium 12, large 16, large-increased 20, extra-large 28, extra-large-increased 32, extra-extra-large 48 dp, full ([ShapeTokens.kt](https://github.com/androidx/androidx/blob/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/ShapeTokens.kt)) | The three "increased" steps; 35 named `MaterialShapes` (Cookie, Clover, Sunny, Pill…) for morphing ([MaterialShapes.kt](https://github.com/androidx/androidx/blob/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/MaterialShapes.kt)); buttons morph to a smaller radius when pressed |
| Spectrum 2 | 0, 3, 4, 5, 6, 7, 8, 9, 10, 16 px and full; radius chosen by component size: "medium" radius 6 / 7 / 8 / 9 / 10 px for XS–XL, "small" radius 3 / 4 / 5 / 6 px ([layout.json](https://github.com/adobe/spectrum-design-data/blob/main/packages/tokens/src/layout.json)) | Rounder than Spectrum 1, plus full rounding for emphasis (search fields) |
| libadwaita 1.7+ | Buttons 9, cards 12, menus 9, popovers 15 (= menu radius + 6), dialogs and windows 15 px ([_common.scss](https://github.com/GNOME/libadwaita/blob/main/src/stylesheet/_common.scss)) | Commit "Increase border radii of various widgets" (2024-10-21) raised buttons from 6 to 9 px and windows from 12 to 15 px, keeping checks and expanders as before ([commit d450cb3](https://github.com/GNOME/libadwaita/commit/d450cb30c5)) |
| Fluent 2 | 0, 2, 4, 6, 8, 12, 16, 24, 32, 40 px, circular ([borderRadius.ts](https://github.com/microsoft/fluentui/blob/master/packages/tokens/src/global/borderRadius.ts)) | Buttons stay at 4 px for every size |
| Primer | small 3, medium 6, large 12 px, full ([size primitives](https://primer.style/product/primitives/size/)) | Unchanged |
| Linear | No numbers; the 2026 refresh gave tabs and even separators rounded ends ([Linear](https://linear.app/now/behind-the-latest-design-refresh)) | Softer, fewer lines |

### 2.2 The concentric rule

The rule: **an inner corner's radius equals the outer radius minus the gap between them**, so both arcs share one
center. Apple states it as concentric shapes that "calculate their radius by subtracting padding from the parent's",
and adds a practical clause: for a component that appears both nested and standalone, "use a concentric shape with a
fallback radius. The concentric value adapts when nested, and the fallback kicks in when the component stands alone"
([WWDC25 356](https://developer.apple.com/videos/play/wwdc2025/356/)).

How the platforms express it:

- **SwiftUI, OS 26+:** `ConcentricRectangle` computes each corner from the nearest container shape (the device's
  corners or any `containerShape(_:)`), with corner styles `.concentric`, `.concentric(minimum:)`, `.fixed(_:)` and
  uniform variants. When a corner is far from the container's corner, "the corner radius the system calculates may be
  zero", which is why `concentric(minimum:)` exists ([ConcentricRectangle](https://developer.apple.com/documentation/swiftui/concentricrectangle)).
  It requires iOS/macOS/watchOS 26.
- **SwiftUI, iOS 17 / macOS 14 (westron's floor):** `ContainerRelativeShape` (iOS 14+) is "an inset version of the
  current container shape", and a plain rectangle if there is none ([docs](https://developer.apple.com/documentation/swiftui/containerrelativeshape)).
  It has no minimum radius, so for westron's own nesting a radius computed from tokens is more predictable.
- **libadwaita** applies the rule by hand: popover radius = menu-item radius + menu margin (9 + 6 = 15 px), and window
  radius = button radius + 6 ([_common.scss](https://github.com/GNOME/libadwaita/blob/main/src/stylesheet/_common.scss)).
- **CSS and Compose** have no concentric primitive; the value has to be computed (in tokens or at runtime).

Pitfalls:

- When `outer − inset ≤ 0` the inner shape goes square. Clamp to a floor (Apple's `minimum:`) or switch to a fixed
  small radius.
- When padding shrinks in compact density, `outer − inset` *grows*, so nested highlights get rounder in a denser
  layout. Either accept it or reduce the container radius in compact as well.
- Large outer radii push content away from the corners. Critics of macOS 26 call large radii "a reduction in
  information density" ([Tsai roundup](https://mjtsai.com/blog/2025/10/16/tahoe-window-corners)). Tools for dense
  data should keep container radii modest.

### 2.3 Radius against size and density

Radius divided by height, from the numbers above:

| Element | Height | Radius | Ratio |
|---|---|---|---|
| Fluent medium button | 32 px | 4 px | 0.13 |
| Primer medium control | 32 px | 6 px | 0.19 |
| Spectrum 2 medium component | 32 px | 8 px | 0.25 |
| libadwaita button | 34 px | 9 px | 0.26 |
| M3 Expressive small button (square shape) | 40 dp | 12 dp | 0.30 |
| M3 Expressive medium button (square shape) | 56 dp | 16 dp | 0.29 |
| Apple macOS large control, iOS 26 buttons | any | capsule | 0.50 |

Systems that scale radius with size (Spectrum 2's per-size tokens, M3 Expressive's per-size button shapes, Apple's
"capsule only for large on macOS") keep this ratio roughly constant; systems that do not (Fluent, Primer) keep one
radius for every size, which reads as more technical. **Density therefore affects radius only through control
height**: a 24 px compact control with the same ratio gets a smaller radius than a 32 px one. Container radii (cards,
sheets) do not need to change with density.

### 2.4 Squircle (continuous) or circular corners

| Platform | Native corner | Notes |
|---|---|---|
| Apple | Continuous. `RoundedRectangle(cornerRadius:style:)` defaults to `.continuous` ([docs](https://developer.apple.com/documentation/swiftui/roundedrectangle/init(cornerradius:style:))) | System controls and glass use continuous corners |
| Web | Circular `border-radius`. `corner-shape: squircle` (superellipse) ships only in Chrome/Edge 139+ (August 2025); Firefox and Safari have positive positions but no support ([web-features: corner-shape](https://web-platform-dx.github.io/web-features-explorer/features/corner-shape)) | A superellipse is not the same curve as Apple's continuous corner, and it changes the perceived radius |
| GTK / libadwaita | Circular only; GTK CSS documents `border-radius` with no corner-shape support ([GTK CSS properties](https://docs.gtk.org/gtk4/css-properties.html)) | — |
| Android / Compose | `RoundedCornerShape` is circular. `androidx.graphics.shapes.CornerRounding(radius, smoothing)` can smooth corners (0 = circular arc, 1 = no arc) ([CornerRounding](https://developer.android.com/reference/kotlin/androidx/graphics/shapes/CornerRounding)) | Material itself uses circular corners |

The corner curve is a platform trait, not a brand trait: emulating squircles on GTK or in non-Chromium browsers is
not possible natively, and on Android it would make westron's shapes disagree with Material's.

---

## 3. Elevation and layering

### 3.1 The three tools

Systems combine **surface tone** (a lighter or darker fill), **shadow**, and **border/outline**:

| System | Light | Dark | High contrast |
|---|---|---|---|
| Apple | System backgrounds and materials; "standard materials help with visual differentiation within the content layer", while Liquid Glass "forms a distinct functional layer for controls and navigation" and should not be used in the content layer ([HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials)) | Two background sets, *base* and *elevated*: "The base colors are dimmer, making background interfaces appear to recede, and the elevated colors are brighter, making foreground interfaces appear to advance" ([HIG Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode)) | Increase Contrast increases "the contrast of items on the screen (such as borders around buttons or boxes)" ([Mac Help](https://support.apple.com/guide/mac-help/unac089)); custom colors need an increased-contrast variant ([HIG Color](https://developer.apple.com/design/human-interface-guidelines/color)) |
| Material 3 | Elevation levels 0, 1, 3, 6, 8, 12 dp ([ElevationTokens.kt](https://github.com/androidx/androidx/blob/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/ElevationTokens.kt)); "elevation mainly using tonal color overlays … in addition to shadows" ([Compose M3 guide](https://developer.android.com/develop/ui/compose/designsystems/material3)) | Surface containers from neutral tone 4 (lowest) through 6 (surface), 10, 12, 17, to 22 (highest) ([ColorDarkTokens.kt](https://github.com/androidx/androidx/blob/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/ColorDarkTokens.kt)) | Contrast levels on the color scheme (outside this scope) |
| libadwaita | Window `#fafafb`, view and cards `#ffffff`; a card is a 1 px outline at 3 % plus two soft shadow layers at 7 % and 3 % ([_misc.scss](https://github.com/GNOME/libadwaita/blob/main/src/stylesheet/widgets/_misc.scss), [_colors.scss](https://github.com/GNOME/libadwaita/blob/main/src/stylesheet/_colors.scss)) | View `#1d1d20` < window `#222226` < header bar and sidebar `#2e2e32` < dialog and popover `#36363a`; cards are white at 8 %; card shade 7 % → 36 % ([_colors.scss](https://github.com/GNOME/libadwaita/blob/main/src/stylesheet/_colors.scss)) | Border opacity 15 % → 50 %; under `prefers-contrast: more` a card's 3 % outline becomes the full border color ([_colors.scss](https://github.com/GNOME/libadwaita/blob/main/src/stylesheet/_colors.scss), [_misc.scss](https://github.com/GNOME/libadwaita/blob/main/src/stylesheet/widgets/_misc.scss)) |
| Atlassian | Sunken, default, raised and overlay surfaces; raised and overlay pair a surface token with a shadow token ([elevation](https://atlassian.design/foundations/elevation)) | "The higher the elevation, the lighter the surface looks"; shadows are kept "for depth and consistency" (same page) | — |
| Carbon | "Layers alternate between White and Gray 10" ([color](https://carbondesignsystem.com/elements/color/overview/)) | "Layers become one step lighter with each added layer" (same page) | — |
| Fluent 2 | Two-layer shadows (ambient + key): `shadow4` = `0 0 2px` ambient, `0 2px 4px` key … `shadow64` ([shadows.ts](https://github.com/microsoft/fluentui/blob/master/packages/tokens/src/utils/shadows.ts)); ambient 12 %, key 14 % ([lightColor.ts](https://github.com/microsoft/fluentui/blob/master/packages/tokens/src/alias/lightColor.ts)) | Same geometry, ambient 24 %, key 28 %: ×2 ([darkColor.ts](https://github.com/microsoft/fluentui/blob/master/packages/tokens/src/alias/darkColor.ts)) | Windows forced colors (see 3.3) |
| Spectrum 2 | Three-layer shadows (ambient, transition, key): emphasized, elevated, dragged; e.g. elevated = `0 4 12` + `0 2 6` + `0 0 2` ([color-aliases.json](https://github.com/adobe/spectrum-design-data/blob/main/packages/tokens/src/color-aliases.json)) | Same geometry, opacities ×3 (8 % → 24 %, 12 % → 36 %, 16 % → 48 %) | — |
| Linear | Fewer separators with softer contrast, after borders had "quietly proliferated across the platform" ([Linear](https://linear.app/now/behind-the-latest-design-refresh)) | — | — |

### 3.2 Dark themes

All surveyed systems that document dark layering agree: **higher surfaces are lighter**, in steps of roughly 3–6 %
lightness (libadwaita's `#1d1d20` → `#36363a`, M3's tones 4 → 22). Shadows stay, but they are made several times
denser because a black shadow on a near-black surface barely shows (Fluent ×2, Spectrum ×3, libadwaita's card shade
×5). The visible cue of height in dark mode is the surface step; the shadow is a supporting cue.

M3 is the odd one in light mode: its surface containers get *darker* from lowest to highest (neutral tone 100, 96,
94, 92, 90; [ColorLightTokens.kt](https://github.com/androidx/androidx/blob/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/ColorLightTokens.kt)),
because in M3 they express a container's emphasis rather than physical height. westron should not copy that for
elevation.

### 3.3 High contrast

- **Borders become the boundary.** libadwaita's 15 % → 50 % border opacity and its card outline under
  `prefers-contrast: more`; macOS Increase Contrast adds borders around buttons and boxes.
- **Shadows cannot carry meaning.** In CSS forced-colors mode `box-shadow` and `text-shadow` "compute to none"
  ([CSS Color Adjust 1, CR 2025-12-16](https://www.w3.org/TR/css-color-adjust-1/)). Anything a shadow marks (a raised
  card, a focus ring drawn as a shadow) disappears unless there is also a border or outline. The standard workaround
  is a transparent border that forced colors paints in a system color ([Frontend Masters](https://frontendmasters.com/blog/you-want-border-color-transparent-not-border-none/)).
- **The contrast target for boundaries is 3:1** against adjacent colors when the boundary is the only thing that
  identifies a control, and always for focus indicators ([Understanding 1.4.11](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html)).

### 3.4 What the native platforms draw themselves

- **Apple:** sheets, popovers, menus and every Liquid Glass surface bring their own shadow and dark-mode elevated
  colors. westron draws only content-layer depth (cards, dragged items).
- **libadwaita:** the `.card` style class gives the native card shadow, dark variant and high-contrast outline for
  free. Using it is more native than reproducing it with tokens.
- **Material:** `Surface(tonalElevation, shadowElevation)` handles both cues; a westron theme on Android should map
  its surface levels onto the surface-container roles.

### 3.5 What DTCG allows

DTCG 2025.10 allows a shadow token's value to be **an array of shadows** ([Format 2025.10](https://www.designtokens.org/tr/2025.10/format/)),
so the two- and three-layer shadows of Fluent, Spectrum and libadwaita can be expressed directly.

---

## 4. Motion

### 4.1 IBM Carbon: productive and expressive

Productive motion "creates a sense of efficiency and responsiveness, while remaining subtle and out of the way"
(button states, dropdowns, data tables); expressive motion is "enthusiastic, vibrant, and highly visible", for
significant moments ([Carbon motion](https://carbondesignsystem.com/elements/motion/overview/)).

| Curve | Productive | Expressive |
|---|---|---|
| Standard | `cubic-bezier(0.2, 0, 0.38, 0.9)` | `cubic-bezier(0.4, 0.14, 0.3, 1)` |
| Entrance | `cubic-bezier(0, 0, 0.38, 0.9)` | `cubic-bezier(0, 0, 0.3, 1)` |
| Exit | `cubic-bezier(0.2, 0, 1, 0.9)` | `cubic-bezier(0.4, 0.14, 1, 1)` |

Durations: fast-01 70 ms, fast-02 110, moderate-01 150, moderate-02 240, slow-01 400, slow-02 700 ms (background
dimming). "Productive motion is significantly faster than expressive motion" (same page).

### 4.2 Material 3 and M3 Expressive

The pre-Expressive token set (still shipped): durations short 50–200, medium 250–400, long 450–600, extra-long
700–1000 ms in 50/100 ms steps; easings standard `(0.2, 0, 0, 1)`, standard decelerate `(0, 0, 0, 1)`, standard
accelerate `(0.3, 0, 1, 1)`, emphasized decelerate `(0.05, 0.7, 0.1, 1)`, emphasized accelerate `(0.3, 0, 0.8, 0.15)`
([Motion.md](https://github.com/material-components/material-components-android/blob/master/docs/theming/Motion.md)).

M3 Expressive replaces most of this with a **motion scheme of springs**. Compose's `MotionScheme` has six specs —
`fast`, `default`, `slow` × `Spatial`, `Effects` — where spatial specs are for animations "that may change the shape
or bounds of the component" and effects specs are for "color or alpha animations", ensuring "non-spatial" motion. The
*standard* scheme is "for utilitarian UI elements and recurring interactions"; the *expressive* scheme is
"recommended … for prominent UI elements and hero interactions" ([MotionScheme.kt](https://github.com/androidx/androidx/blob/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/MotionScheme.kt)).

| Spring | Standard (damping ratio / stiffness) | Expressive |
|---|---|---|
| fast spatial | 0.9 / 1400 | 0.6 / 800 |
| default spatial | 0.9 / 700 | 0.8 / 380 |
| slow spatial | 0.9 / 300 | 0.8 / 200 |
| fast effects | 1.0 / 3800 | 1.0 / 3800 |
| default effects | 1.0 / 1600 | 1.0 / 1600 |
| slow effects | 1.0 / 800 | 1.0 / 800 |

Sources: [StandardMotionTokens.kt](https://github.com/androidx/androidx/blob/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/StandardMotionTokens.kt),
[ExpressiveMotionTokens.kt](https://github.com/androidx/androidx/blob/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/ExpressiveMotionTokens.kt)
(token version v0_14_0). Note that **effects springs never bounce**, in either scheme; only spatial motion gets the
expressive bounce.

Shape and motion combine in M3 Expressive buttons: a medium button's square shape is 16 dp and its pressed shape
12 dp; a small button's 12 → 8 dp; large and extra-large 28 → 16 dp ([button tokens](https://github.com/androidx/androidx/tree/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens)).
The morph is driven by the motion scheme.

Google's case for expressiveness: 46 studies with more than 18,000 participants, and key elements spotted "up to four
times faster" in an eye-tracking study, but "it's not a one-size-fits-all solution", unfamiliarity limited the gains,
and "a strong minority of users preferred calmer designs" ([Google Design](https://design.google/library/expressive-material-design-google-research)).

### 4.3 Apple: SwiftUI springs and the HIG

- **Springs are the default.** "We now use them as the default animation in SwiftUI, so all you need to do is call
  withAnimation to start with a spring" ([WWDC23 "Animate with springs"](https://developer.apple.com/videos/play/wwdc2023/10158/)).
- **Two parameters.** `spring(duration: 0.5, bounce: 0.0, blendDuration: 0)`; duration is "the perceptual duration,
  which defines the pace of the spring"; bounce 0 is critically damped, positive values bounce up to 1.0, negative
  values are overdamped down to −1.0 ([docs](https://developer.apple.com/documentation/swiftui/animation/spring(duration:bounce:blendduration:))).
- **Presets** (all 0.5 s by default): `.smooth` bounce 0, `.snappy` base bounce 0.15
  ([docs](https://developer.apple.com/documentation/swiftui/animation/snappy(duration:extrabounce:))), `.bouncy`
  base bounce 0.3 ([docs](https://developer.apple.com/documentation/swiftui/animation/bouncy(duration:extrabounce:))).
- **Guidance on bounce.** "A small bounce, like around 15%, doesn't feel very bouncy yet, but the long tail feels a
  little more brisk … for larger bounce values like 30%, you do start to feel some noticeable bounciness … be cautious
  about using values higher than around 0.4"; "When you're not sure, use a spring with bounce 0" (WWDC23).
- **Why springs.** "Springs are the only type of animation that maintains continuity both for static cases and cases
  with an initial velocity" (WWDC23).
- **`Spring` type** (iOS 17 / macOS 14 / watchOS 10) converts between representations:
  `Spring(duration: 0.5, bounce: 0.3)` has mass 1, stiffness 157.9, damping 17.6 ([Spring](https://developer.apple.com/documentation/swiftui/spring)).
- **HIG Motion:** "Add motion purposefully"; "In apps, generally avoid adding motion to UI interactions that occur
  frequently"; "Let people cancel motion" ([HIG Motion](https://developer.apple.com/design/human-interface-guidelines/motion),
  updated 2025-09-09 for Liquid Glass).
- **Reduce Motion (HIG Accessibility):** reduce "automatic and repetitive animations, including zooming, scaling, and
  peripheral motion", by "tightening animation springs to reduce bounce effects", "tracking animations directly with
  people's gestures", "avoiding animating depth changes in z-axis layers", "replacing transitions in x-, y-, and
  z-axes with fades", and "avoiding animating into and out of blurs" ([HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)).

### 4.4 libadwaita and GTK

- **`AdwSpringAnimation`** is "driven by a physical model of a spring described by AdwSpringParams"; springs "don't
  have a fixed duration" and expose an `estimated-duration`; `clamp` prevents overshoot; initial velocity "adjusts the
  curve without changing the duration" ([SpringAnimation](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/class.SpringAnimation.html)).
  `AdwSpringParams` is built from mass, stiffness and a damping ratio (or raw damping) ([SpringParams](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/struct.SpringParams.html)).
- **`AdwTimedAnimation` takes only named easings** (`AdwEasing`): quad, cubic, quart, quint, sine, expo, circ,
  elastic, back, bounce, plus `EASE`, `EASE_IN`, `EASE_OUT`, `EASE_IN_OUT` since 1.7 ([Easing](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/enum.Easing.html)).
  **There is no arbitrary cubic-bezier**, so a westron curve must map to the nearest named easing, or the timed
  animation must run linear with a custom interpolation in code.
- **GTK CSS transitions** accept `cubic-bezier()` and `steps()` but **not `linear()`** ([gtkcsseasevalue.c](https://github.com/GNOME/gtk/blob/main/gtk/gtkcsseasevalue.c)).
  Springs cannot be expressed in GTK CSS; they belong in code.
- **libadwaita's own springs** (computed equivalents in 4.7): navigation view damping ratio 1, mass 1, stiffness 1000
  ([adw-navigation-view.c](https://github.com/GNOME/libadwaita/blob/main/src/adw-navigation-view.c)); bottom sheet
  0.8 / 1 / 400 ([adw-bottom-sheet.c](https://github.com/GNOME/libadwaita/blob/main/src/adw-bottom-sheet.c)); floating
  sheet 0.62 / 1 / 500 ([adw-floating-sheet.c](https://github.com/GNOME/libadwaita/blob/main/src/adw-floating-sheet.c));
  overlay split view 1 / 0.5 / 500 ([adw-overlay-split-view.c](https://github.com/GNOME/libadwaita/blob/main/src/adw-overlay-split-view.c)).
  Button hover and press transitions are CSS: 200 ms with an ease-out-quad curve ([_common.scss](https://github.com/GNOME/libadwaita/blob/main/src/stylesheet/_common.scss)).
- **Reduced motion.** GTK 4.22 added `GtkSettings:gtk-interface-reduced-motion`, "Whether animations should be reduced
  to essential motions" ([GTK docs](https://docs.gtk.org/gtk4/property.Settings.gtk-interface-reduced-motion.html)),
  and CSS media queries (since GTK 4.20) include `prefers-reduced-motion` and `prefers-contrast` ([GTK CSS properties](https://docs.gtk.org/gtk4/css-properties.html)).
  The GNOME setting "offers alternative animations that avoid discomfort or distraction without turning animations off
  entirely" ([This Week in GNOME #224](https://thisweek.gnome.org/posts/2025/11/twig-224/)). In libadwaita 1.9 (GNOME
  50) "most widgets now automatically support the new system-wide reduced motion preference" ([GNOME 50 for developers](https://release.gnome.org/50/developers/)).
  The source shows how: the bottom sheet sets its damping ratio to 1.0 under reduced motion, and the floating and bottom
  sheets switch to fades ([adw-bottom-sheet.c](https://github.com/GNOME/libadwaita/blob/main/src/adw-bottom-sheet.c)).
  The older global switch, `gtk-enable-animations`, still skips animations entirely when off
  ([follow-enable-animations-setting](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/property.Animation.follow-enable-animations-setting.html)).

### 4.5 Web

- **`linear()`** easing can encode any sampled curve, including a spring; it is Baseline "widely available" since
  2026-06-11 (Chrome 113, Firefox 112, Safari 17.2) ([web-features: linear-easing](https://web-platform-dx.github.io/web-features-explorer/features/linear-easing/)).
- **Primer's motion tokens** are a good minimal web set: durations micro 100, short 200, medium 300, long 500 ms;
  easings ease, easeIn `(0.7, 0.1, 0.75, 0.9)`, easeOut `(0.3, 0.8, 0.6, 1)`, easeInOut `(0.6, 0, 0.2, 1)`, written as
  DTCG cubic-bezier arrays; the rule for agents: "MUST keep UI interactions ≤300ms … NEVER exceed 500ms for UI
  interactions" ([motion.json5](https://github.com/primer/primitives/blob/main/src/tokens/functional/motion/motion.json5),
  [easing.json5](https://github.com/primer/primitives/blob/main/src/tokens/base/motion/easing.json5)).
- **Fluent 2:** durations ultraFast 50, faster 100, fast 150, normal 200, gentle 250, slow 300, slower 400, ultraSlow
  500 ms; curves in accelerate / decelerate / easy-ease families, e.g. decelerateMid `(0, 0, 0, 1)`, easyEase
  `(0.33, 0, 0.67, 1)` ([durations.ts](https://github.com/microsoft/fluentui/blob/master/packages/tokens/src/global/durations.ts),
  [curves.ts](https://github.com/microsoft/fluentui/blob/master/packages/tokens/src/global/curves.ts)).

### 4.6 Android reduced motion

Android has no "reduce motion" flag of its own; the "Remove animations" setting sets the animator duration scale to
0, and Compose (1.2+) honors that scale through `MotionDurationScale`, so animations end on the next frame
([Eeva-Jonna Panula](https://dev.to/eevajonnapanula/android-animations-and-reduced-motion-2em2),
[MotionDurationScale](https://developer.android.com/reference/kotlin/androidx/compose/ui/MotionDurationScale)). That
is "no motion", not "less motion": a westron Compose layer must read the setting itself if it wants fades instead.

### 4.7 One spring, four platforms

Apple's own example fixes the conversion. With mass 1, `Spring(duration: d, bounce: b)` has stiffness
`k = (2π / d)²` and damping ratio `ζ = 1 − b` for `b ≥ 0` (check: d = 0.5, b = 0.3 gives k = 157.9 and damping
`2ζ√k` = 17.6, Apple's numbers). Compose's `spring(dampingRatio, stiffness)` and libadwaita's
`AdwSpringParams(damping_ratio, mass, stiffness)` take the same physics, so the mapping is exact, not approximate.

Platform springs expressed as Apple-style `(duration, bounce)` (computed; "settle" is the time to stay within 1 % of
the target):

| Source spring | Duration | Bounce | Settles in | Overshoot |
|---|---|---|---|---|
| M3 standard fast spatial (0.9 / 1400) | 0.17 s | 0.10 | 0.14 s | 0.2 % |
| M3 standard default spatial (0.9 / 700) | 0.24 s | 0.10 | 0.19 s | 0.2 % |
| M3 standard slow spatial (0.9 / 300) | 0.36 s | 0.10 | 0.30 s | 0.2 % |
| M3 fast / default / slow effects (1.0 / 3800, 1600, 800) | 0.10 / 0.16 / 0.22 s | 0 | 0.11 / 0.17 / 0.23 s | 0 |
| M3 expressive fast spatial (0.6 / 800) | 0.22 s | 0.40 | 0.22 s | 9.5 % |
| M3 expressive default spatial (0.8 / 380) | 0.32 s | 0.20 | 0.33 s | 1.5 % |
| M3 expressive slow spatial (0.8 / 200) | 0.44 s | 0.20 | 0.45 s | 1.5 % |
| libadwaita navigation view (1 / 1 / 1000) | 0.20 s | 0 | 0.21 s | 0 |
| libadwaita bottom sheet (0.8 / 1 / 400) | 0.31 s | 0.20 | 0.32 s | 1.5 % |
| libadwaita floating sheet (0.62 / 1 / 500) | 0.28 s | 0.38 | 0.28 s | 8.4 % |
| SwiftUI `.smooth` / `.snappy` / `.bouncy` (0.5 s) | 0.50 s | 0 / 0.15 / 0.30 | 0.53 / 0.36 / 0.52 s | 0 / 0.6 / 4.6 % |

Two things follow. First, Apple's default spring (0.5 s) is about twice as slow as Material's and libadwaita's
everyday springs (0.17–0.32 s); a westron token should state its duration rather than lean on `withAnimation`'s
default. Second, "bounce" in the token is the parity-safe number: with it, the web, GNOME, Android and Apple all
overshoot by the same amount.

For CSS, sample the spring at build time into `linear()` and use the settle time as `transition-duration`. Example,
spring 0.35 s / bounce 0.15, settling to 0.1 % in 487 ms:
`linear(0, 0.109, 0.322, 0.534, 0.707, 0.83, 0.911, 0.96, 0.987, 1, 1.005, 1.006, 1.005, 1.004, 1.003, 1.002, 1)`.
CSS transitions cannot carry velocity across an interruption, so on the web a spring is a curve, not physics. That is
acceptable for content-layer motion, and a Web Animations API runtime spring remains an option.

### 4.8 What a cross-platform motion token set needs

From the systems above, the minimum that maps natively everywhere:

1. **Durations** for timed motion (fades, color changes, delays): a short ladder, 50–500 ms, with a stated ceiling.
2. **Cubic-bezier curves**: standard, enter (decelerate), exit (accelerate), linear. Exit-accelerate and
   enter-decelerate are in every system (Carbon, Material, Fluent, Primer).
3. **Springs** as `(duration, bounce)` in `$extensions` (DTCG has no spring type, [Format 2025.10](https://www.designtokens.org/tr/2025.10/format/)),
   in a fast/default/slow × spatial/effects grid; effects never bounce.
4. **Semantic motions named by what moves**, each pointing to either a spring or a transition (duration, delay,
   curve), plus a **reduced-motion behavior**: `fade`, `instant`, or `keep`, and whether the delay survives.
5. **Per-platform fallbacks generated, not authored**: `linear()` for CSS, the nearest `AdwEasing` for libadwaita
   timed animations, `cubic-bezier()` for GTK CSS transitions.

---

## 5. Three directions that stay native

### 5.1 Which knobs are free and which are fixed

Free (content layer, westron's own): spacing rhythm and generosity; control and row heights *above* the platform
floor; radius ratio and container radii; whether separation is drawn with borders, shadows or tone; spring tuning and
durations; press feedback (tint, scale, morph).

Fixed by the platform (identical in all directions): system controls and their sizes (`controlSize`, Adwaita widgets,
M3 components); hit-target floors; the corner curve (continuous on Apple, circular elsewhere); Liquid Glass and
system-drawn overlays; Dynamic Type and text scaling; high-contrast behavior; Reduce Motion behavior; the density
deltas (a dense table is a function, not a brand).

### 5.2 How visible each knob is

- **Radius ratio and spacing** are visible in a static screenshot at once.
- **Elevation strategy** (borders vs soft shadows vs tone) is visible, more so in dark mode.
- **Motion** is invisible in a static specimen. The specimens need a way to replay interactions (check a task, open a
  card, drag a row, sort a table), or the motion part of each direction will not be judged at all.

### 5.3 The archetypes and their nearest native kin

| Direction | Character | Nearest existing systems | Where it looks most native | Where it needs care |
|---|---|---|---|---|
| Precise (cool) | Tight 4 px rhythm, small radii, hairline borders, no bounce | Primer, Fluent, Carbon productive, Linear | Web, macOS inspectors | iOS 26 (small radii beside glass capsules look sharp); GNOME (6 px cards inside 15 px windows) |
| Humanist (warm) | 8 px rhythm, generous padding, radius ratio about 0.25, soft shadows, light bounce | libadwaita (9/12/15 px), Apple grouped lists, Spectrum 2 | GNOME, iOS, macOS | Dense tables (needs the compact mode to stay credible) |
| Expressive (bold) | Large controls, capsules, big container radii, tonal surfaces, spatial bounce, press morph | M3 Expressive, Apple's large controls | Android, iOS | macOS (in dense desktop layouts capsules are "best used for standout actions"); data-heavy screens |

---

## 6. Recommendations for westron

These are proposals for the owner's review, to be checked with catalog screenshots against native controls on each
platform. They depart from the current drafts (`decisions/0013`, `design-language/04`–`06`) in places; section 6.10
lists where.

### 6.1 Base unit and space scale

- **A 4 px grid with an 8 px base step**, named by multiplier as today (`space.100` = 8 px). This is exactly
  Atlassian's naming and Carbon's and Spectrum's values.
- **Ladder:** `space.0` 0, `25` 2, `50` 4, `75` 6, `100` 8, `125` 10, `150` 12, `200` 16, `250` 20, `300` 24,
  `400` 32, `500` 40, `600` 48, `800` 64. Compared with the current draft: add 32 and 64 (every surveyed system has
  them; they are the section and page gaps), drop 14 (a pilot artifact), keep 10 (Fluent's `mNudge`; needed for
  compact inline padding).
- **The ladder does not change with density.** Density sets role tokens (6.2). Page margins and section gaps use the
  ladder directly and stay the same in both densities.

### 6.2 The density model

**Two contexts**, `comfortable` (default) and `compact`. The repository currently calls them `regular` and `compact`;
either name works, but pick one before #33.

**What compact changes, and by how much:**

| Role token | Comfortable → compact | Basis |
|---|---|---|
| `size.control.{sm,md,lg}` (westron-drawn controls: chips, inline buttons, segmented filters, fields on web) | one 8 px step down, about −20–25 % | Carbon, Spectrum, Primer |
| `size.row.list`, `size.row.table` | about −20 % (8 px less) on pointer platforms; touch rows only down to the target floor | Spectrum, Primer, Fluent |
| `space.inset.cell` (block / inline) | 8 / 12 → 4 / 8 | Primer `cellPadding` |
| `space.inset.control` (inline) | 12 → 8 | Primer `paddingInline` |
| `space.gap.inline`, `space.gap.stack` (inside a group) | 8 → 4, 16 → 8 | Primer `stack-gap` |
| `radius.control.*` | follows control height through the direction's ratio, so usually one step smaller | Spectrum 2 per-size radii |
| Icon size in rows | 20 → 16 | — |

**What compact does not change:** text roles (a dense table picks a smaller role itself), page margins and section
gaps, container radii, hit-target floors, stroke widths, focus rings, motion.

**How it stays orthogonal to `platform`.** Decision 0010 forbids two modifiers setting one token. Control and row
heights differ by both platform and density, so split them: the **platform** file supplies both columns under raw
names, and the **density** file only picks a column by alias. For example, `platform/macos.tokens.json` sets
`size.raw.compact.control.md` = 24 px and `size.raw.comfortable.control.md` = 28 px; `density/compact.tokens.json`
sets `size.control.md` = `{size.raw.compact.control.md}`. No path is set twice, and the generator can emit both
columns per platform with the runtime density choosing one.

**How each platform applies it:**

- **Apple:** density also sets `.controlSize(.small)` (compact) or `.regular` on the subtree, so system controls follow
  natively; westron's tokens size only westron's own content.
- **Web:** density is a CSS class or attribute on a container that swaps the custom properties; westron's Lit
  components read them.
- **GNOME:** Adwaita widgets have no density; compact applies to westron's content and adds libadwaita's own
  `.data-table` class to column views.
- **Android (later):** M3 components keep their sizes; compact affects westron content and may choose M3 Expressive's
  smaller button sizes (XS 32 dp). `minimumInteractiveComponentSize` stays on.

### 6.3 Control and row heights

Comfortable / compact, in pt (Apple), px (web, GNOME) and dp (Android). Values on Apple and GNOME are starting points
to be measured against native controls in the catalog.

| Token | iOS / iPadOS | watchOS | macOS | Web (fine pointer) | Web (coarse pointer) | GNOME | Android |
|---|---|---|---|---|---|---|---|
| `size.control.sm` | 32 / 28 (hit 44) | system | 22 / 20 | 24 / 20 | 36 / 32 (hit 44) | 28 / 24 | 32 / 32 (hit 48) |
| `size.control.md` | 44 / 36 (hit 44) | system | 28 / 24 | 32 / 24 | 44 / 40 | 34 / 28 | 40 / 32 (hit 48) |
| `size.control.lg` | 52 / 44 | system | 32 / 28 | 40 / 32 | 52 / 44 | 40 / 34 | 56 / 40 |
| `size.row.list` (task row, calm) | 52 / 44 | 44 / 44 | 32 / 28 | 44 / 36 | 52 / 44 | 50 / 40 | 56 / 48 |
| `size.row.table` (data table) | 48 / 44 | — | 28 / 24 | 36 / 28 | 48 / 44 | 36 / 26 | 52 / 48 |
| `size.row.header` (section/table header) | 36 / 32 | — | 28 / 24 | 32 / 24 | 36 / 32 | 32 / 24 | 40 / 36 |

Notes: this table is the neutral baseline (closest to direction B); directions A and C move content rows within the
platform floors as 6.8 shows. Rows are **minimum** heights that grow with Dynamic Type and text scaling (as chapter 06
already requires).
GNOME's 34 and 50 match Adwaita's buttons and boxed-list rows so westron content sits level with them; its compact
table row matches `.data-table` (2 px cell padding on a text line). The web's 32 / 24 control pair is the industry
default (Primer, Fluent, Spectrum desktop); the web's 36 / 28 table row sits between Primer's normal and condensed.

### 6.4 Hit targets

`size.target.min`, set by `platform`, never by density: iOS / iPadOS / watchOS 44 pt; macOS 28 pt (20 pt floor);
web 24 px under `(pointer: fine)` and 44 px under `(pointer: coarse)`; GNOME 24 px (no published number; Adwaita's own
controls are 34 px); Android 48 dp. A drawn element may be smaller than its hit area; compact on touch shrinks the
drawing, never the target.

### 6.5 Radius scale and the concentric rule

- **Primitive ladder (on the space ladder, as today):** `radius.0` 0, `radius.25` 2, `radius.50` 4, `radius.75` 6,
  `radius.100` 8, `radius.150` 12, `radius.200` 16, `radius.300` 24, `radius.400` 32, and `radius.full`, which each
  platform renders as its capsule (`Capsule()`, `9999px`, `CircleShape`).
- **Semantic radii, set by the direction:** `radius.control` (as a ratio of control height, snapped to the ladder),
  `radius.row` (selection and hover highlights), `radius.card`, `radius.overlay` (web-drawn popovers and menus),
  `radius.sheet`, `radius.tag` (usually `full`).
- **The concentric rule as a token rule:** for each nesting westron defines (card → row highlight, overlay → menu
  item, sheet → field, tile → thumbnail), the inner radius is `max(outer − inset, radius.50)`; if `outer − inset` is
  below 2 px, use `radius.50` or 0 for full-bleed content. Compute the result in the generator and store it, so every
  platform draws the same number. On Apple 26+, use `ConcentricRectangle` with `.concentric(minimum:)` only where
  westron content meets the device or window edge.
- **Corner curve per platform:** continuous on Apple (`RoundedRectangle(..., style: .continuous)`, matching system
  controls), circular on web, GNOME and Android. Do not emulate squircles with `corner-shape` (Chromium-only) or
  graphics-shapes smoothing. Record this in each contract's `platforms` block.
- **Density:** control radius follows control height; container radius does not change; nested radii follow the rule
  (they grow slightly as compact padding shrinks, which is acceptable and consistent with libadwaita's approach).

### 6.6 Elevation in the four themes

Four levels: `surface.sunken` (wells, code blocks, board backdrop), `surface.base`, `surface.raised` (cards, rows that
float), `surface.overlay` (web-drawn popovers and menus only), plus `shadow.dragged`. Surface colors come from the
color research; the rules are:

| Theme | Surface | Shadow | Border |
|---|---|---|---|
| `light` | Raised is white on a slightly tinted base (as libadwaita `#fafafb` / `#fff`) | Two layers, key + ambient (below) | Hairline only where tone alone does not separate (card on card) |
| `dark` | Each level one step lighter (about 3–5 % lightness), never darker | Same geometry, opacity ×3 | Hairline at low alpha of white on raised surfaces, optional |
| `light-hc` | Same tones, may collapse to fewer steps | Kept, but carries no meaning | Every raised and overlay surface gets a 1 px border at ≥ 3:1 against its neighbor |
| `dark-hc` | Same as `dark` | Kept, carries no meaning | As `light-hc` |

Shadow tokens (DTCG arrays; Apple halves blur into `radius` and stacks two `.shadow` modifiers):

| Token | Light | Dark (×3 opacity) |
|---|---|---|
| `shadow.raised` | `0 1px 2px rgb(0 0 0 / 6%)`, `0 1px 3px rgb(0 0 0 / 10%)` | 18 %, 30 % |
| `shadow.overlay` | `0 4px 12px rgb(0 0 0 / 8%)`, `0 12px 32px rgb(0 0 0 / 12%)` | 24 %, 36 % |
| `shadow.dragged` | `0 8px 16px rgb(0 0 0 / 10%)`, `0 16px 40px rgb(0 0 0 / 16%)` | 30 %, 48 % |

Platform rules: on Apple, never shadow what the system draws (sheets, popovers, menus, glass); on GNOME, raised cards
use Adwaita's `.card` class (native shadow, dark and high-contrast handling) and westron's tokens cover only what
Adwaita has no class for; on the web, every element with a shadow also has a `border: 1px solid transparent` (or the
HC border color) so forced-colors mode keeps its edge; focus is an outline, never a shadow.

### 6.7 Motion tokens and their mapping

**Primitives:**

- `duration.*`: 0, 50, 100, 150, 200, 250, 300, 400, 500 ms. Rule for components and agents: feedback ≤ 200 ms,
  movement ≤ 400 ms, nothing in the content layer above 500 ms except a deliberate "read this" delay.
- `easing.*` (cubic-bezier arrays): `standard` `[0.2, 0, 0, 1]`, `enter` `[0, 0, 0, 1]`, `exit` `[0.3, 0, 1, 1]`,
  `linear` `[0, 0, 1, 1]`, `ease` `[0.25, 0.1, 0.25, 1]` (CSS's and GTK's `ease`, libadwaita's `ADW_EASE`) for color
  fades.
- `spring.{fast,default,slow}.{spatial,effects}` in `$extensions.dev.westron.spring` as `{duration, bounce}`.
  Effects springs always have bounce 0. Values come from the direction (6.8).

**Semantic:** keep `motion.<what-moves>` (check, fold, row-leave, …). Each points to a spring or a transition and adds
`$extensions.dev.westron.reducedMotion`: `{ "mode": "fade" | "instant" | "keep", "keepDelay": true }`.

**Mapping:**

| Token | SwiftUI (iOS 17 / macOS 14) | CSS + Lit | libadwaita (Rust) | Compose |
|---|---|---|---|---|
| spring `{d, b}` | `.spring(duration: d, bounce: b)` | `transition: <prop> <settle>ms linear(…)`, sampled at build time | `adw::SpringAnimation` with `adw::SpringParams::new(1.0 - b, 1.0, (2π/d)²)`; `clamp = true` for effects | `spring(dampingRatio = 1 - b, stiffness = (2π/d)²)`; or a custom `MotionScheme` so M3 components move with westron's springs |
| transition `{duration, delay, curve}` | `.timingCurve(x1, y1, x2, y2, duration:)` + `.delay(_:)` | `transition-duration`, `transition-delay`, `cubic-bezier()` | GTK CSS `cubic-bezier()` for style changes; in code, `adw::TimedAnimation` with the nearest named `adw::Easing`, chosen by eye in the catalog (candidates: `standard` and `ease` → `Ease`, `enter` → `EaseOutQuint`, `exit` → `EaseInCubic`) | `tween(durationMillis, delayMillis, CubicBezierEasing(…))` |
| reduced motion | `@Environment(\.accessibilityReduceMotion)` | `@media (prefers-reduced-motion: reduce)` | `GtkSettings:gtk-interface-reduced-motion` (GTK 4.22) and the CSS media query; `gtk-enable-animations` for "off" | Animator duration scale (Remove animations) read at runtime |

**Reduce Motion rules (all platforms):** spatial springs become bounce 0 and travel becomes a fade of at most
`duration.150`; scale and z-depth changes are dropped; color fades stay; delays that let a person read stay even when
the duration is zero (the pilot's bug); "off" (`gtk-enable-animations = false`, animator scale 0) means instant. This
is what the HIG recommends and what libadwaita 1.9 does.

### 6.8 The three directions, concretely

All values are comfortable density; compact applies the same deltas (6.2) in every direction. Pointer-platform values
are given; touch platforms keep the floors in 6.3–6.4.

| Knob | A. Precise (cool) | B. Humanist (warm) | C. Expressive (bold) |
|---|---|---|---|
| Rhythm | 4 px grid, tight | 8 px grid, generous | 8 px grid, large |
| Card padding | 12 | 16 | 24 |
| Gap inside a group / between groups | 8 / 16 | 12 / 24 | 16 / 32 |
| Page margin (narrow / wide) | 16 / 24 | 20 / 32 | 24 / 40 |
| Web control md / list row / table row | 32 / 36 / 32 | 32 / 44 / 36 | 40 / 52 / 40 |
| Radius ratio (controls) | about 0.15 | about 0.25 | 0.5 (capsule) for buttons and chips, 0.3 for fields |
| `radius.control` md (32 px) | 4 | 8 | `full` (fields 12) |
| `radius.row` | 4 | 8 | 12 |
| `radius.card` | 6 (8 on iOS) | 12 | 24 |
| `radius.overlay` / `radius.sheet` | 8 / 12 | 12 / 16 | 20 / 28 |
| macOS controls | rounded rectangles | rounded rectangles | rounded rectangles for sm/md, capsule for lg only (Apple's rule) |
| Separation, light | Hairline borders and visible dividers; shadows only for overlay and drag | Soft two-layer shadows on cards, no border; dividers inset and faint | Tonal surfaces (accent-tinted containers); strong shadows only on floating elements |
| Separation, dark | Borders plus one surface step | Surface steps, shadows on overlay only | Tonal steps, stronger tint |
| High contrast | Borders thicken in color only | Borders appear on every raised surface | Borders appear; tint reduced |
| Springs fast / default / slow spatial `(d, b)` | 0.20 / 0, 0.28 / 0, 0.40 / 0 | 0.25 / 0.10, 0.35 / 0.15, 0.50 / 0.10 | 0.25 / 0.30, 0.32 / 0.20, 0.44 / 0.20 |
| Effects springs fast / default / slow | 0.10, 0.15, 0.22 s, bounce 0 | 0.15, 0.20, 0.30 s, bounce 0 | 0.10, 0.16, 0.22 s, bounce 0 (M3's values) |
| Timed fades | 100–150 ms, `standard` | 200 ms, `ease` | 150–250 ms, `standard` |
| Overshoot | none | check pop only (b = 0.2) | check, drop, card open |
| Press feedback | tint | tint + scale 0.98 | tint + radius morph one step smaller (M3 Expressive) |
| Kin | Primer, Fluent, Linear | libadwaita, Apple grouped lists, Spectrum 2 | M3 Expressive, Apple large controls |

Expressive's fast spatial bounce stays at 0.3, below Apple's caution at about 0.4 and below M3 Expressive's own 0.4.
Precise's card radius is one step larger on iOS so it does not look sharp beside Liquid Glass capsules; that is a
`platform` entry and a recorded parity difference.

### 6.9 Showing them as specimens

- Build each direction as a set of semantic-token overrides on the same sample screens, so the only differences are
  the knobs in 6.8.
- Show every screen in light and dark, and the data table and log view in both densities: the compact table should
  look nearly the same in all three directions, which demonstrates that density is shared.
- Add an interaction replay (check, reorder, open card, sort, toggle density) to each sample; motion is a third of the
  difference between the directions and cannot be seen otherwise.
- Shoot them on iOS and macOS first (the catalog already supports both), so the "where it looks native" column in
  5.3 is judged on real controls.

### 6.10 Where this differs from the current drafts

1. **Density sets role tokens, not the ladder** (chapter 06 says a density "can change what a step is worth"). No
   surveyed system rescales its scale, and page margins should not shrink in compact.
2. **Platform supplies, density selects** (6.2), so `size.*` tokens can differ by both without breaking decision
   0010's orthogonality rule.
3. **The space ladder gains 32 and 64 and loses 14.**
4. **Shadows get two layers and a dark variant** (chapter 04, open question 1). Fluent, Spectrum and libadwaita all
   change shadow opacity by theme; one black layer for both themes is the outlier.
5. **High-contrast themes outline raised surfaces** (chapter 04, open question 4): yes, as libadwaita, macOS and
   forced colors all do.
6. **Corners are continuous on Apple** (chapter 04, open question 2), matching the system rather than the canvas's CSS.
7. **Overshoot parity** (chapter 05, open question 1): store the bounce in the spring token and generate CSS
   `linear()` from it, so Apple, web, GNOME and Android overshoot by the same amount; no hand-made cubic overshoot is
   needed except for GTK CSS transitions.
8. **Fades under Reduce Motion stay** (chapter 05, open question 2): the HIG recommends replacing travel with fades,
   and libadwaita 1.9 does exactly that.

---

## 7. What could not be verified, and other caveats

1. **Material's guideline site (m3.material.io) renders client-side and could not be read.** All M3 numbers here come
   from Google's own Compose implementation (androidx-main, token version v0_14_0) and the Material Components for
   Android docs. Whether M3 has a density system at all was not confirmed; the −4 dp density scale is M2/MDC-era
   ([@material/density](https://cdn.jsdelivr.net/npm/@material/density@14.0.0/README.md), not fetched in full). The
   "4 dp grid" statement for M3 is from memory.
2. **Spectrum 2's documentation site** (s2.spectrum.adobe.com) could not be read. Values are from the
   `@adobe/spectrum-tokens` 15.7.0 sources on the main branch, which carry the size-dependent S2 radius tokens. The
   Spectrum "1.25× mobile" ratio is confirmed by the token pairs, not by prose.
3. **macOS 26/27 native control heights** (mini to extra large) were not found in Apple's documentation. The
   `ControlSize.extraLarge` page says it "resolves to `ControlSize.large` on platforms other than visionOS"
   ([docs](https://developer.apple.com/documentation/swiftui/controlsize/extralarge)), which conflicts with WWDC25's
   mention of a new macOS X-Large size. The macOS values in 6.3 must be measured in the catalog.
4. **macOS 27's "consistent corner radius"** is from press coverage of the June 2026 betas
   ([Cult of Mac](https://www.cultofmac.com/news/liquid-glass-changes-ios-27-macos-27)), not from Apple's docs. The
   HIG Layout page changed on 2026-09-09 ("Updated guidance to reflect current best practices"); the change was not
   diffed.
5. **macOS list and table row heights** (`NSTableView` row size styles, SwiftUI `List` defaults) were not found as
   numbers; `defaultMinListRowHeight` documents no default.
6. **GNOME publishes no spacing scale.** The 6 px rhythm is inferred from libadwaita's stylesheet.
7. **GTK's reduced-motion keyword:** the GTK CSS properties page lists the values as `no-preference, reduced`, while
   the `GtkCssProvider` source comment and This Week in GNOME use `prefers-reduced-motion: reduce` (the web keyword).
   Test which one GTK 4.22 parses.
8. **libadwaita's reduced-motion behavior** is confirmed in source for the bottom sheet, floating sheet and
   navigation view; the full list of widgets comes from secondary coverage of libadwaita 1.9. Whether the internal
   `adw_get_reduce_motion` helper is public API was not checked; apps should read `gtk-interface-reduced-motion`.
9. **Compose honoring "Remove animations"** rests on the `MotionDurationScale` docs and developer reports, some of
   them conflicting.
10. **Atlassian control heights:** the compiled CSS contains `height: 2rem` and `1.5rem`; mapping them to default and
    compact is an inference.
11. **Linear** publishes no numbers; third-party "13 px on a 4 px grid" claims were not used.
12. **The `(duration, bounce)` → `(stiffness, damping ratio)` formula** is derived and checked against Apple's one
    worked example for positive bounce. The negative-bounce mapping was not verified; westron should not use negative
    bounce.
13. **The CSS `linear()` example** was sampled with 17 points; a production generator should sample adaptively and
    check the error against the analytic spring.
14. **Apple's continuous corner versus CSS `superellipse()`**: that they are different curves is widely reported but
    was not verified from a primary source here.
15. **The recommended numbers in section 6** are syntheses, not quotations. They need catalog screenshots against
    native controls before they become tokens.
