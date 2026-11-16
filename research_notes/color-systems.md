# Color for westron: how mature systems build palettes, and three directions worth specimens

Research date: 2026-11-15. Scope: color only. The report is written for the owner and the agents of westron. It
compares how mature design systems build palettes, semantic colors, dark and high-contrast themes, status and
categorical colors, and what an accent has to satisfy on Apple, GNOME and Android. It ends with recommendations and
three palette directions with concrete OKLCH anchors.

How to read the numbers. Every contrast ratio written as "my check" was computed by me with WCAG 2.x relative
luminance on gamma-encoded sRGB, the same method as westron's CI. OKLCH values were converted with Björn Ottosson's
OKLab matrices. Colors outside sRGB were gamut-mapped by lowering chroma at constant L and H. Color-vision-deficiency
(CVD) checks use the Machado et al. (2009) simulation matrices at full severity, with distance measured as Euclidean
ΔE in OKLab. The scripts were throwaway and are not kept in the repository. Section 7 lists what I could not
verify.

## Key findings

1. **Every mature system names steps by job, not by color.** Radix has 12 steps with a fixed job for each step
   ([Radix](https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale)). Geist has 10
   ([Geist](https://vercel.com/geist/colors)), Spectrum 16 ([Spectrum](https://spectrum.adobe.com/page/color-system/)),
   Atlassian 12 ([Atlassian palette](https://atlassian.design/foundations/color/color-palette)) and Carbon 10
   ([Carbon](https://carbondesignsystem.com/elements/color/overview/)). The step count matters less than whether
   each step has one job in every theme.
2. **Dark themes are re-solved, not inverted.** Apple says Dark Mode colors "aren't necessarily inversions"
   ([HIG Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode)). In Spectrum's dark
   theme a higher index is *lighter*: blue-900 is `rgb(86,129,255)` and blue-800 `rgb(64,105,253)`. So the index
   tracks contrast against the theme's background, not lightness
   ([spectrum-design-data](https://github.com/adobe/spectrum-design-data/blob/main/packages/tokens/src/color-palette.json)).
   Atlassian uses a simple symmetry, light 700 becomes dark 400
   ([Atlassian palette](https://atlassian.design/foundations/color/color-palette)).
3. **Contrast is guaranteed only by luminance-based construction plus a CI audit.** USWDS grades and Material's HCT
   tone are luminance-based, so a fixed step difference guarantees a ratio for any hue: tone difference 40 gives
   3:1 and 50 gives 4.5:1 ([USWDS](https://designsystem.digital.gov/design-tokens/color/overview/);
   [Material blog](https://material.io/blog/science-of-color-design)). OKLCH lightness is *not* such a guarantee.
   In my check, OKLCH `L 0.60, C 0.15` gives 3.70 to 4.23 against white, depending on hue.
4. **Radix's guarantees are APCA guarantees, not WCAG 2 guarantees.** In my check, step 11 on step 2 gives
   4.43 (amber) and 4.49 (green) under WCAG 2, so both fail 4.5:1. Step 8, the "focus ring" step, gives 1.8 to 2.3
   on step 2 in light, which fails the 3:1 non-text target.
5. **APCA is not WCAG 3.** The WCAG 3 Working Draft of 10 September 2026 still says "The contrast algorithm used
   in WCAG 3 is yet to be determined" ([WCAG 3 WD](https://www.w3.org/TR/wcag-3.0/);
   [history](https://www.w3.org/standards/history/wcag-3.0)). Keep WCAG 2.x as the gate.
6. **Platform accents are tuned below westron's 4.5:1 text target.** GNOME's nine accent backgrounds give 3.0 to
   3.9:1 with their white labels, except red at 4.36 and purple at 5.91 (my check). iOS 26 default system blue
   `#0088FF` gives 3.52 against white. Ten of Apple's twelve *Increased Contrast* light variants land at 4.54 to
   4.59 against white; indigo and purple are higher (my check, values from the
   [HIG Color specifications](https://developer.apple.com/design/human-interface-guidelines/color)). So westron's
   accent fill has to be darker than the platform defaults to pass its own CI.
7. **GNOME derives the text accent by clamping Oklab lightness.** The rule is `min(l, 0.5)` in light and
   `max(l, 0.85)` in dark, keeping a and b
   ([libadwaita CSS variables](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/1-latest/css-variables.html)).
   Blue and violet cannot hold their chroma at L 0.85 in sRGB, so they clip and drift in hue. In my check a cobalt
   accent drifts from 262° to 242°, a violet from 298° to 314°. A blue or violet westron accent needs an explicit
   dark `--accent-color`.
8. **Material uses one role, `primary`, both as a fill and as text.** In dark it is a light color with a dark
   on-color (tone 80 over tone 20,
   [color_spec_2021.ts](https://github.com/material-foundation/material-color-utilities/blob/main/typescript/dynamiccolor/color_spec_2021.ts)).
   Apple and GNOME keep a mid-tone fill with a white label in dark. Mapping westron to Material forces either a
   recorded parity difference or westron adopting the Material convention for dark fills.
9. **Classic red and green status fills are nearly identical under deuteranopia.** In my check same-lightness red
   and green give ΔE 0.02 to 0.05. A bluish green (hue about 168°) with a darker red raises that to about 0.10, as
   Okabe-Ito's `#009E73` does.
10. **Charts: eight colors is the practical ceiling** if each mark must keep 3:1 against the canvas and stay
    distinguishable under CVD. In my check Tableau 10 collapses to ΔE 0.007 under deuteranopia (red/green), and
    three of Okabe-Ito's seven colors fall under 3:1 on white (1.32 to 2.31). An optimized 8-color set reaches
    3:1 for every color and ΔE ≥ 0.075 under protan and deutan (section 4.4).

---

## 1. How mature systems build palettes and semantic colors

### 1.1 Radix Colors

- **Steps and jobs.** 12 steps per scale ([Radix](https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale)):
  - 1–2: app and subtle backgrounds;
  - 3–5: component backgrounds (normal, hover, pressed or selected);
  - 6: subtle borders on non-interactive elements;
  - 7: subtle borders on interactive elements;
  - 8: strong borders and focus rings;
  - 9–10: solid backgrounds, where step 9 is "the purest step" with the highest chroma, and step 10 is its hover;
  - 11: low-contrast text;
  - 12: high-contrast text.
- **Scales.** 6 grays (Gray, Mauve, Slate, Sage, Olive, Sand) and 25 color scales. Each scale has alpha variants
  and P3 versions ([Radix Colors](https://www.radix-ui.com/colors)).
- **Color space and guarantee.** "Contrast targets are based on the modern APCA contrast algorithm." Steps 11 and 12
  are "guaranteed to Lc 60 and Lc 90" on step 2. The scales are hand-tuned, not generated. The custom generator
  makes 12 steps plus alpha and wide-gamut values from "a couple reference colors" and promises contrast "similar to
  what Radix Colors provide" ([custom palettes](https://www.radix-ui.com/colors/docs/overview/custom-palettes)).
- **Dark theme.** Separate hand-tuned dark scales, where step 1 is the darkest. You switch by class on a container.
- **High contrast.** No high-contrast theme. Radix Themes has a per-component `highContrast` option
  ([Radix Themes color](https://www.radix-ui.com/themes/docs/theme/color)).
- **Status.** No status tokens. Radix suggests pairings: error red, ruby, tomato or crimson; success green, teal,
  jade, grass or mint; warning yellow, amber or orange; info blue, indigo, sky or cyan
  ([composing a palette](https://www.radix-ui.com/colors/docs/palette-composition/composing-a-palette)).
- **Light fills.** Sky, mint, lime, yellow and amber step 9 are "designed for dark foreground text".
- **Accent rule.** Pick the gray "saturated with the hue closest to your accent hue". Radix warns that saturated
  grays can clash with colorful components such as badges in dark mode. Radix Themes pairs the gray automatically
  if you do not set one.
- **My WCAG 2 check of v3 values** ([@radix-ui/colors 3.0.0](https://unpkg.com/@radix-ui/colors@3.0.0/index.mjs)):
  - Step 11 on step 2, light: gray 5.62, slate 5.65, sand 5.73, blue 4.53, red 4.94, green **4.49**, amber
    **4.43**. In dark all exceed 8.
  - Step 8 on step 2 in light: 1.82 for grays, 2.12 to 2.28 for colors. In dark: 2.8 to 3.5.
  - Step 9 against white: blue 3.26, green 3.16, red 3.91. White labels on the default solids therefore pass only
    the large-text and non-text targets.

### 1.2 Material 3: HCT, tonal palettes, dynamic color, Expressive

- **Color space.** HCT combines hue and chroma from CAM16 with tone, which is CIE L\*
  ([material-color-utilities](https://github.com/material-foundation/material-color-utilities)). Because tone is
  luminance-based, "smaller elements require a tone difference of 50 with their background, larger elements 40"
  ([The Science of Color & Design](https://material.io/blog/science-of-color-design)).
- **Tonal palettes.** Five key colors: primary, secondary, tertiary, neutral and neutral variant, plus error. Each
  has a tonal palette of 13 standard tones
  ([Android M3](https://developer.android.com/develop/ui/compose/designsystems/material3)). Surface roles use extra
  tones (4, 6, 12, 17, 22, 24, 87, 92, 94, 96, 98).
- **Tones per role, 2021 spec, light/dark**
  ([color_spec_2021.ts](https://github.com/material-foundation/material-color-utilities/blob/main/typescript/dynamiccolor/color_spec_2021.ts)):

  | Role | Light | Dark | Contrast curve (low, **standard**, medium, high) |
  |---|---|---|---|
  | primary (also secondary, tertiary, error) | 40 | 80 | 3, **4.5**, 7, 7 |
  | onPrimary | 100 | 20 | 4.5, **7**, 11, 21 |
  | primaryContainer | 90 | 30 | 1, **1**, 3, 4.5 |
  | onPrimaryContainer | 30 | 90 | 3, **4.5**, 7, 11 |
  | surface | 98 | 6 | — |
  | surfaceContainerLowest / Low / – / High / Highest | 100 / 96 / 94 / 92 / 90 | 4 / 10 / 12 / 17 / 22 | — |
  | onSurface | 10 | 90 | 4.5, **7**, 11, 21 |
  | onSurfaceVariant | 30 | 80 | 3, **4.5**, 7, 11 |
  | outline | 50 | 60 | 1.5, **3**, 4.5, 7 |
  | outlineVariant | 80 | 30 | 1, **1**, 3, 4.5 |

  The four curve values belong to contrast levels −1, 0, 0.5 and 1
  ([contrast_curve.ts](https://github.com/material-foundation/material-color-utilities/blob/main/typescript/dynamiccolor/contrast_curve.ts)).
  At standard contrast, Material *aims for 7:1* on primary text (onSurface) and on-colors (onPrimary). That is
  stricter than WCAG AA and equal to westron's high-contrast target.
- **Dynamic color.** Android 12 and later derive a scheme from the wallpaper. Apps fall back to a static scheme
  ([Android M3](https://developer.android.com/develop/ui/compose/designsystems/material3)).
- **Chroma by variant, 2021 spec.** TonalSpot, the default, uses primary chroma 36, secondary 16, tertiary 24 at
  hue +60°, neutral 6 and neutral variant 8. Error is hue 25 at chroma 84
  ([dynamic_scheme.ts](https://github.com/material-foundation/material-color-utilities/blob/main/typescript/dynamiccolor/dynamic_scheme.ts)).
- **Harmonizing fixed colors.** Custom fixed colors, such as status colors, can be "harmonized": their hue rotates
  toward the source by half the difference, at most 15°, and chroma and tone stay
  ([blend.ts](https://github.com/material-foundation/material-color-utilities/blob/main/typescript/blend/blend.ts)).
- **System contrast.** Android 14 (API 34) exposes the user's contrast choice, `UiModeManager.getContrast()`, as a
  float from −1 to 1 ([UiModeManager](https://developer.android.com/reference/android/app/UiModeManager)). Dynamic
  schemes follow it automatically, and static custom schemes must handle it themselves.
- **M3 Expressive, the 2025 spec.** Google described it as "more variation and higher chroma across all hues"
  ([Android Authority, May 2025](https://www.androidauthority.com/material-3-expressive-color-3560841/)). The code
  shows what changes
  ([color_spec_2025.ts](https://github.com/material-foundation/material-color-utilities/blob/main/typescript/dynamiccolor/color_spec_2025.ts);
  [dynamic_scheme.ts](https://github.com/material-foundation/material-color-utilities/blob/main/typescript/dynamiccolor/dynamic_scheme.ts)):
  - Dark surfaces go *darker* on phone: surface 4, containers 6/9/12/15, bright 18. In 2021 they were 6 and
    10/12/17/22.
  - Surfaces and neutral text get chroma multipliers. Expressive light neutral chroma is 18, against 8 for
    Expressive and 6 for TonalSpot in 2021, which tints surfaces visibly.
  - Expressive primary chroma is 48 in light; Vibrant uses 74.
  - Error hue now depends on the source hue.
  - New `*Dim` roles appear, and phone and watch get separate specs.
  - Material3 1.5.0-rc01 (November 4, 2026) stabilized most Expressive components
    ([compose-material3](https://developer.android.com/jetpack/androidx/releases/compose-material3), cited in the
    repo report).
- **Status and data-viz.** Error is the only status role. Material has no categorical or data-viz palette.

### 1.3 Atlassian

- **Palette.** Nine hues: lime, red, orange, yellow, green, teal, blue, purple and magenta. Each has steps 100, 200,
  250, 300, 400, 500, 600, 700, 800, 850, 900 and 1000, plus a few alpha variants such as `Red200A40`.
- **Neutrals.** Light neutrals `Neutral0`–`Neutral1200` (13) plus 5 alpha. A separate dark ramp has
  `DarkNeutral-100`–`DarkNeutral1200`, 16 steps including 250 and 350 for elevations, plus alpha
  ([palette](https://atlassian.design/foundations/color/color-palette)).
- **Dark theme by symmetry.** "If a button color is 700 in light theme, it will be 400 in dark theme." A section
  message background goes from 100 to 1000. The page notes that symmetry "may not work for all use cases".
- **Token grammar.** Property, then role, then emphasis, then state. Roles: neutral, brand, information, success,
  warning, danger, discovery, accent, inverse and input. Emphasis runs "subtlest to boldest". The 10 accents (gray,
  red, green, blue, yellow, orange, teal, purple, magenta, lime) carry no meaning: "You should be able to exchange
  one accent color for another" ([color](https://atlassian.design/foundations/color)).
- **Contrast.** WCAG AA: 4.5:1 below 24px, 3:1 for essential UI.
  - Pairing rules for accents: default or bolder text on subtlest or subtler backgrounds, bolder on subtle, inverse
    on bolder.
  - Yellow has special `warning.inverse` tokens.
  - Atlassian advises against yellow accents because they "become brown to meet contrast requirements"
    ([accents](https://atlassian.design/foundations/color/accents)).
- **Data-viz.** `color.chart.categorical.1`–`.8` (8), plus per-hue chart ramps and semantic chart tokens. I found
  these in the token list ([all tokens](https://atlassian.design/components/tokens/all-tokens)).
- **Dark layering.** "The higher the elevation, the lighter the surface looks." Raised and overlay surfaces also
  keep shadows ([elevation](https://atlassian.design/foundations/elevation)).
- **High contrast.** Light and dark themes only.
- **Color space.** Not documented on the pages I could read.

### 1.4 Adobe Spectrum 2 and Leonardo

- **Steps.** 16 per hue, numbered 100–1600. The blue scale is labeled with contrast ratios from 1.06:1 to 19.5:1
  ([color fundamentals](https://spectrum.adobe.com/page/color-fundamentals/)). The S2 token source has separate
  light and dark values for every index
  ([color-palette.json](https://github.com/adobe/spectrum-design-data/blob/main/packages/tokens/src/color-palette.json)).
- **Generation.** "Spectrum colors are generated using the Leonardo color tool" from key colors and target
  contrast ratios ([color system](https://spectrum.adobe.com/page/color-system/)).
  - Leonardo's `Theme` takes a background color, lightness (0–100), a contrast multiplier and saturation.
  - Each `Color` takes key colors, an interpolation space (LCH, LAB, CAM02, HSL, HSLuv, HSV or RGB) and a list of
    target ratios. Negative ratios name colors below the base.
  - Dark mode is the same theme with a different background lightness. Leonardo recommends restricting the range
    to avoid inaccessible combinations
    ([Leonardo contrast-colors](https://github.com/adobe/leonardo/tree/main/packages/contrast-colors);
    [repo](https://github.com/adobe/leonardo)).
  - The theme-wide contrast multiplier is a natural high-contrast knob.
- **Rules.**
  - Yellow, orange, chartreuse and celery need black text.
  - "Do not use color functions to modify Spectrum colors."
  - Hierarchy comes from gray background layers.
- **Spectrum 2** (announced December 12, 2023) rebuilt color from Adobe's brand colors and moved away from the
  "gray color palette designed to recede"
  ([Adobe blog](https://blog.adobe.com/en/publish/2023/12/12/adobe-unveils-spectrum-2-design-system-reimagining-user-experience-over-100-adobe-applications)).
- **Data-viz.** A categorical palette of 6 colors "optimized to be distinguishable for users with color vision
  deficiencies", with advice to use fewer than 6. Only partly verified (section 7).

### 1.5 IBM Carbon

- **Palette.** 10 grades per hue (10–100), each with a hover value, plus black and white. The families include
  `gray`, `coolGray` and `warmGray`. Carbon now ships the palette as a DTCG 2025.10 file
  ([colors.tokens.json](https://github.com/carbon-design-system/carbon/blob/main/packages/colors/tokens/colors.tokens.json)).
  - `coolGray10` `#f2f4f8` is `oklch(0.967 0.006 265)`.
  - `warmGray10` `#f7f3f2` is `oklch(0.967 0.005 34)` (my conversion).
- **Themes.** White and Gray 10 (light), Gray 90 and Gray 100 (dark).
- **Layering.** Light themes alternate White and Gray 10 with each layer. In dark themes layers "become one step
  lighter with each added layer" ([color overview](https://carbondesignsystem.com/elements/color/overview/)).
- **Contrast and states.**
  - A table gives the minimum grade distance for 4.5:1 and 3:1.
  - Hover is a half step, selected one step, active two steps.
  - The focus ring is Blue 60 in light and White in dark.
- **Status.** `support-error` Red 60, `success` Green 50, `warning` Yellow 30, `info` Blue 70, plus
  `caution-minor`, `caution-major` and `caution-undefined`
  ([tokens](https://carbondesignsystem.com/elements/color/tokens/)).
- **Data-viz.** A **14-color** categorical palette "applied in sequence strictly", ordered to maximize contrast
  between neighbors. Also 4 monochromatic sequences of 10 steps, two diverging palettes and a 4-color alert
  palette. Sequential palettes flip direction in dark
  ([data-viz palettes](https://carbondesignsystem.com/data-visualization/color-palettes/)).
- **High contrast.** No dedicated theme on the pages I read.

### 1.6 GitHub Primer

- **Tiers.** Base (never used directly), functional (`bgColor-*`, `fgColor-*`, `borderColor-*` with
  `muted`/`emphasis`) and component.
- **Neutrals.** "shades of gray between 0 and 13". Light and dark scales run in opposite directions so both themes
  can share functional tokens.
- **Contrast rules.** Step 8 is the minimum for control borders, step 9 the minimum for text on steps 0–4. The
  light high-contrast theme uses steps 2–7 for backgrounds, 10 for borders and 11–13 for text. "For high contrast
  themes, the goal is to hit a minimum of 7:1 for most text and interactive elements"
  ([color usage](https://primer.style/product/getting-started/foundations/color-usage/)).
- **Roles.** accent, success, attention, severe, danger, open, closed, done and sponsors.
- **Nine themes.** light, light high contrast, light colorblind, light tritanopia, dark, dark dimmed, dark high
  contrast, dark colorblind and dark tritanopia ([primitives](https://github.com/primer/primitives); v11.10.0,
  2026-07-30).
- **Colorblind themes.** They "swap colors such as red and green for orange and blue"
  ([changelog 2022](https://github.blog/changelog/2022-04-19-protanopia-deuteranopia-colorblind-themes-beta/)).
  Users still report label colors they cannot tell apart
  ([discussion](https://github.com/orgs/community/discussions/65557)).
- **Process.** Lightness curve first, then hue and saturation, in HSLuv
  ([Primer Prism](https://github.blog/news-insights/product-news/accelerating-github-theme-creation-with-color-tooling/)).
  A contrast script over 100+ pairs runs in a GitHub Action on every PR, with translucent colors blended before
  measuring ([GitHub blog](https://github.blog/engineering/unlocking-inclusive-design-how-primers-color-system-is-making-github-com-more-inclusive/)).
- **Categorical colors.**
  - `display` has 19 hues × 10 steps (0–9) for labels, avatars and user-assigned colors. Its rule text says
    "Scales 0-2 are lighter (backgrounds), 3-5 are mid-tones, 6-9 are darker"
    ([display.json5](https://github.com/primer/primitives/blob/main/src/tokens/functional/color/display.json5)).
  - `data-vis` has 17 hues, each `emphasis` (display 5) and `muted` (display 0)
    ([data-vis.json5](https://github.com/primer/primitives/blob/main/src/tokens/functional/color/data-vis.json5)).
  - Both carry `org.primer.llm` usage and rules, for example "Do NOT use for semantic meaning".

### 1.7 Fluent 2

- **Neutrals.** 50 greys (2–98 in even steps, plus 99).
  ([colors.ts](https://github.com/microsoft/fluentui/blob/master/packages/tokens/src/global/colors.ts))
- **Brand.** A 16-step brand ramp (10–160). The default web brand is
  ([brandColors.ts](https://github.com/microsoft/fluentui/blob/master/packages/tokens/src/global/brandColors.ts)).
- **Dark theme.** Different steps of the same ramps:
  - `colorBrandBackground` is brand 80 in light and brand 70 in dark.
  - `colorBrandForeground1` is brand 80 in light and brand 100 in dark.
  - Neutral backgrounds 1–6 are white and greys 98–90 in light. In dark they are greys 16, 12, 8, 4, black and 20,
    so Background1, which cards use, is the lightest
    ([lightColor.ts](https://github.com/microsoft/fluentui/blob/master/packages/tokens/src/alias/lightColor.ts);
    [darkColor.ts](https://github.com/microsoft/fluentui/blob/master/packages/tokens/src/alias/darkColor.ts)).
- **Shared colors.** 49 ramps × 12 variants (shade50…tint60). From them come 7 status names and 28 persona
  (avatar) colors. Mapped status uses cranberry, green and orange
  ([sharedColorNames.ts](https://github.com/microsoft/fluentui/blob/master/packages/tokens/src/sharedColorNames.ts)).
- **High contrast.** The theme maps to CSS system colors (`Canvas`, `CanvasText`, `ButtonFace`), so the brand
  disappears entirely
  ([highContrastColor.ts](https://github.com/microsoft/fluentui/blob/master/packages/tokens/src/alias/highContrastColor.ts)).
- **Guidance.** Fluent says to avoid brand color on large surfaces. On Windows, interaction states lighten
  instead of darkening ([Fluent color](https://fluent2.microsoft.design/color)).

### 1.8 Apple system colors and Increased Contrast

- **Variants.** 12 system hues (red, orange, yellow, green, mint, teal, cyan, blue, indigo, purple, pink, brown),
  each in four variants: light, dark, increased-contrast light and increased-contrast dark. Six system grays,
  label levels (primary to quaternary), separators, and primary/secondary/tertiary backgrounds, plain and grouped.
  Values were updated June 9, 2025, and the Liquid Glass guidance on December 16, 2025
  ([HIG Color](https://developer.apple.com/design/human-interface-guidelines/color)).
- **My check of the published values.**

  | Hue | Light | vs white | IC light | vs white | Dark on `#1c1c1e` | IC dark on `#1c1c1e` |
  |---|---|---|---|---|---|---|
  | blue | `#0088FF` | 3.52 | `#1E6EF4` | 4.57 | 5.26 | 7.90 |
  | red | `#FF383C` | 3.57 | `#E9152D` | 4.56 | 4.96 | 5.79 |
  | green | `#34C759` | 2.22 | `#008932` | 4.54 | 8.42 | 9.25 |
  | orange | `#FF8D28` | 2.31 | `#C55300` | 4.55 | 7.62 | 8.44 |
  | yellow | `#FFCC00` | 1.51 | `#A16A00` | 4.59 | 12.05 | 12.84 |
  | indigo | `#6155F5` | 5.09 | `#564ADE` | 6.12 | 4.84 | 7.97 |

  **Ten of the twelve IC light variants sit at 4.54–4.59 against white**; indigo (6.12) and purple (5.21) are
  the exceptions. Apple's Increase Contrast is tuned to WCAG AA 4.5:1, not 7:1.
- **Grays.** Slightly cool: `systemGray6` `#f2f2f7` is `oklch(0.963 0.007 286)`.
- **Rules.**
  - Custom colors need light, dark and "an increased contrast option for each variant".
  - Provide light and dark "even if your app ships in a single appearance mode … to support Liquid Glass
    adaptivity".
  - "strive for a contrast ratio of 7:1, especially in small text" for custom colors
    ([HIG Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode)).
  - Minimums are 4.5:1 up to 17 pt and 3:1 at 18 pt or bold. Apple names APCA alongside WCAG
    ([HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)).
- **Dark layering.** iOS dark mode has base and *elevated* backgrounds. "The elevated colors are brighter".
- **Liquid Glass.** Apply color sparingly. Color the background of the primary action, not its symbol or text, and
  do not color the backgrounds of several controls. In apps with colorful content, prefer monochrome toolbars or a
  well-differentiated accent ([HIG Color](https://developer.apple.com/design/human-interface-guidelines/color)).
- **Branding** (refined September 9, 2026). Use the accent "for primary actions or status indicators", and move
  brand color "into the content layer, where it scrolls beneath Liquid Glass controls"
  ([HIG Branding](https://developer.apple.com/design/human-interface-guidelines/branding)).
- **macOS accent.** The app's accent applies only when the user's accent setting is *multicolor*. Otherwise the
  user's color replaces it.

### 1.9 libadwaita (GNOME 47+)

- **System accent.** Since libadwaita 1.6 (September 2024), apps follow a system accent picked from nine colors.
  The system maps an arbitrary color to the closest of the nine "in the Oklch color space, mostly based on hue"
  ([Alice Mikhaylenko, Libadwaita 1.6](https://blogs.gnome.org/alicem/2024/09/)).
- **Three accent variables** ([CSS variables, libadwaita 1.10](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/1-latest/css-variables.html)):
  - `--accent-bg-color`: the fill;
  - `--accent-fg-color`: the label on the fill, white for every default accent;
  - `--accent-color`: the standalone text color, derived as
    `oklab(from var(--accent-bg-color) var(--standalone-color-oklab))` with `min(l, 0.5) a b` in light and
    `max(l, 0.85) a b` in dark. Out-of-gamut results are clipped, for example blue's dark standalone becomes
    `#81d0ff`.
- **Contrast of the nine accents (my check).** White on the accent background gives 3.01 (yellow), 3.44 (orange),
  3.50 (pink), 3.76 (teal), 3.77 (blue), 3.81 (green), 3.92 (slate), 4.36 (red) and 5.91 (purple). The standalone
  colors give 5.4–6.3 on the light window and 6.9–11 on the dark window.
- **Overriding.**
  - Apps set `--accent-bg-color`, and "CSS always takes priority over the system accent". The `AdwStyleManager`
    API keeps reporting the system color.
  - If the accent is too bright, set a dark `--accent-fg-color`
    ([Styles & Appearance](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/1-latest/styles-and-appearance.html)).
- **Status.** `destructive`, `success`, `warning` and `error`, each with bg, fg and standalone. The warning
  foreground is `rgb(0 0 0 / 80%)`. White on the light success background `#2ec27e` is only 2.30 (my check).
- **Palette.** Eight hues × 5 shades, plus light and dark neutrals × 5.
- **Neutrals.** Faintly cool: window `#fafafb` / `#222226`, view `#ffffff` / `#1d1d20`, header bar and sidebar
  `#2e2e32` in dark. Dark layering is view < window < header bar, and dark cards are white at 8%.
- **High contrast.** "applications cannot disable it". High contrast raises `--border-opacity` from 15% to 50% and
  `--dim-opacity` from 55% to 90%. Borders are `currentColor` mixed at that opacity, so they adapt automatically.
- **Custom CSS.** Use `@media (prefers-color-scheme: dark)` and `@media (prefers-contrast: more)` in `style.css`.
  The 1.10 docs still present `style-dark.css` and `style-hc.css` as an alternative.

### 1.10 Linear

- **2024 rebuild.** Linear replaced 98 hand-defined variables per theme with "three: base color, accent color,
  and contrast", generated in LCH. LCH is "perceptually uniform, meaning a red and a yellow color with lightness 50
  will appear roughly equally light". The contrast input lets Linear "automatically include super high-contrast
  themes". Elevation surfaces come from the same generator
  ([How we redesigned the Linear UI, part II, March 2024](https://linear.app/now/how-we-redesigned-the-linear-ui)).
- **March 2026 refresh.** The default neutral moved from "cool and blue-ish" to "a warmer gray that still feels
  crisp, but less saturated", warning that "too warm" looks muddy. The sidebar became "a few notches dimmer"
  ([Behind the latest design refresh](https://linear.app/now/behind-the-latest-design-refresh);
  [changelog](https://linear.app/changelog/2026-03-12-ui-refresh)).

### 1.11 Vercel Geist

- **Scales.** 10 scales: two backgrounds plus gray, gray-alpha, blue, red, amber, green, teal, purple and pink. Each
  color has 10 steps (100–1000).
- **Step jobs.**
  - 100–300: component backgrounds (default, hover, active);
  - 400–600: borders (default, hover, active);
  - 700–800: high-contrast backgrounds;
  - 900–1000: secondary and primary text.
- **Gamut.** "P3 colors are used on supported browsers and displays" ([Geist colors](https://vercel.com/geist/colors)).
- **Dark mode.** Not described on the page.

### 1.12 Comparison

| System | Steps per hue | Space / method | Dark | High contrast | Status | Categorical |
|---|---|---|---|---|---|---|
| Radix | 12 + alpha + P3 | hand-tuned, APCA Lc 60/90 | separate scales | none (per-component option) | suggested pairings | none |
| Material 3 | 13 tones (+ surface tones) | HCT, generated | other tones; 2025 darker, tinted | contrast level −1…1, API 34 | error only (+ harmonize) | none |
| Atlassian | 12 (100–1000) | not documented | symmetry 700↔400 | none | info, success, warning, danger, discovery | 8 chart, 10 accents |
| Spectrum 2 | 16 (100–1600) | Leonardo, contrast-targeted | index = contrast | via contrast | informative, negative, notice, positive | 6 (CVD) |
| Carbon | 10 + hover | grades | own themes, layers lighten | none | error, success, warning, info + 3 caution | 14 ordered |
| Primer | 10 (display), neutrals 0–13 | Prism, HSLuv; CI audit | reversed scales | 2 HC themes, 7:1 goal | 9 roles | 19 display, 17 data-vis |
| Fluent 2 | 16 brand, 50 grey, 12 shared | ramps | other steps | system colors | danger, success, warning (+ severe) | 28 persona |
| Apple | 4 variants per color | hand-tuned | dark variants, elevated bg | IC variants ≈ 4.5:1 | system hues | 12 system hues |
| libadwaita | 5 palette shades | Oklab derivation | standalone L ≥ 0.85 | automatic, opacities | destructive, success, warning, error | 9 accents |
| Linear | generated | LCH, 3 inputs | same generator | contrast input | — | — |
| Geist | 10 (100–1000) | P3 | — | — | red, amber, green, blue | — |

---

## 2. Contrast by construction

### 2.1 Four ways systems guarantee targets

1. **Luminance-banded steps.** Each step owns a band of relative luminance, so a fixed step distance gives a fixed
   minimum ratio for any hue.
   - USWDS: a "magic number" of 40 gives AA large text, 50 gives AA, 70 gives AAA, because "each grade conforms to
     a specific range of values for relative luminance"
     ([USWDS](https://designsystem.digital.gov/design-tokens/color/overview/)).
   - Material: tone is L\*, and a difference of 40 or 50 gives 3:1 or 4.5:1.
   - Carbon publishes a grade-distance table.
   - Cheap, robust, hue-independent. The cost: lightness is fixed per step, so yellows become brown at text
     steps, as Atlassian warns.
2. **Contrast-targeted generation.** You state the ratio against a background, and the generator solves the
   lightness. Examples: Leonardo with Spectrum's indices, Linear's contrast input, Material's `ContrastCurve` per
   role and contrast level. Changing the background, such as the dark canvas, re-solves everything, which is how
   dark and high-contrast themes come out of one definition.
3. **Pairing rules plus an automated audit.** Primer checks 100+ pairs on every PR, with translucent colors
   blended first. Atlassian documents which emphasis levels may pair. Apple ships system colors with tested
   variants. This is the proof; methods 1 and 2 only make passing likely.
4. **APCA targets.** Radix guarantees Lc 60 and Lc 90 for its text steps. As shown above, that does not imply
   WCAG 2 4.5:1 for all hues.

**OKLCH lightness is not a contrast guarantee.** In my check, `oklch(0.60 0.15 h)` against white gives 4.23 at
hue 30, 3.95 at 90, 3.70 at 150, 4.00 at 260 and 4.19 at 300. OKLCH is the right space to *author* hue and chroma
in, but each step's lightness must be *solved* against WCAG luminance.

### 2.2 APCA and WCAG 3 in November 2026

- **WCAG 3.** The latest Working Draft (10 September 2026) lists "Text contrast sufficient (minimum)" with
  "@@[contrast measure to be determined]" and the note "The contrast algorithm used in WCAG 3 is yet to be
  determined". It assumes the future algorithm "will include a size/weight factor" and asks that translucency
  "be tested as the rendered color" ([WCAG 3 WD](https://www.w3.org/TR/wcag-3.0/)). Ten drafts have been
  published since 2021, all Working Drafts ([history](https://www.w3.org/standards/history/wcag-3.0)).
- **APCA.** It was removed from the drafts in 2023. "WCAG3 is years away from being done", likely not before
  about 2030. Even APCA's author says "no one should be calling it 'WCAG 3'"
  ([Adrian Roselli, April 2026](https://adrianroselli.com/2026/04/wcag3-contrast-as-of-april-2026.html)).
- **What westron should target now.**
  - **WCAG 2.2 stays the gate**, with the current targets: 4.5 / 3 / 3 standard, 7 / 4.5 / 4.5 plus separators
    at 3 in high contrast.
  - Add two things:
    - **Solve, don't pick.** The palette generator solves each step's lightness against luminance, so the CI
      passes by construction and the audit stays the proof.
    - **Optionally report APCA Lc as a non-blocking column** for dark-theme text. Apple cites APCA, and Radix
      uses it. That helps where WCAG 2 is known to be lenient with light text on dark grounds. Do not let it fail
      builds.

---

## 3. Neutrals

### 3.1 Tinted or pure, and how temperature is chosen

| Reference | Value | OKLCH (my conversion) | Reading |
|---|---|---|---|
| Apple systemGray6 light / dark | `#f2f2f7` / `#1c1c1e` | 0.963 0.007 286 / 0.227 0.004 286 | cool, tiny chroma |
| GNOME window light / dark | `#fafafb` / `#222226` | 0.985 0.001 286 / 0.254 0.007 286 | cool, more chroma in dark |
| Carbon gray10 / coolGray10 / warmGray10 | `#f4f4f4` / `#f2f4f8` / `#f7f3f2` | C 0 / 0.006 @265 / 0.005 @34 | pure default; cool and warm offered |
| Radix slate12 / sand12 | `#1c2024` / `#21201c` | 0.241 0.010 248 / 0.243 0.008 95 | pairs with accent hue |
| Fluent grey16 | `#292929` | C 0 | pure |
| Material 2025 Expressive neutral | — | HCT chroma 18 in light | strongly tinted to the source hue |

How systems choose temperature:

- **Radix.** Match the accent: use "the gray scale which is saturated with the hue closest to your accent hue",
  but beware clashes with colorful badges in dark mode.
- **Material.** The neutral takes the source hue at low chroma, so neutrals are always accent-tinted.
- **Apple and GNOME.** A faint cool tint, about hue 286° at chroma ≤ 0.007.
- **Carbon.** Pure gray by default; cool and warm families are available.
- **Linear 2026.** Moved from cool to a less saturated warm gray, and warned that "too warm" looks muddy.

Two practical rules follow:

1. Neutral chroma of **0.003–0.012** reads as tinted without becoming colored.
2. Dark neutrals can carry **slightly more chroma** than light ones: GNOME dark is 0.007 against 0.001 in light,
   and Material 2025 multiplies neutral chroma.

### 3.2 How many neutral steps

| Count | Systems |
|---|---|
| 5–10 | GNOME 5+5; Carbon 10; Geist 10 |
| 12–16 | Radix 12 (+12 alpha); Atlassian 13 light, 16 dark; Primer 0–13 |
| 50 | Fluent |

Apple exposes about 6 grays, 4 label levels and 3 backgrounds rather than a ramp. Twelve steps plus alpha
overlays covers everything the systems with step jobs use.

### 3.3 Surface layering

- **Dark: lighter is higher, everywhere.**
  - Apple has base and elevated backgrounds.
  - Atlassian: "the higher the elevation, the lighter".
  - Carbon: each layer is one step lighter.
  - Fluent Background1 is grey 16, over 12, 8 and 4.
  - Material 2025 surface tones are 4, then containers 6, 9, 12, 15, then bright 18.
  - GNOME: view `#1d1d20` < window `#222226` < header bar `#2e2e32`, and cards are white at 8%.
  - Shadows still appear on raised and overlay surfaces (Atlassian), but tone carries the depth.
- **Light: two models.**
  - Canvas grey with white raised surfaces: GNOME window `#fafafb` and view `#ffffff`; Fluent; Carbon Gray 10.
  - White canvas with grey sunken areas: Atlassian `sunken`; Radix steps 1–2.
  - Both work. Pick one per direction (section 6.7).

---

## 4. Status colors and categorical palettes

### 4.1 Status sets

| System | Status roles |
|---|---|
| Atlassian | information, success, warning, danger, discovery |
| Carbon | error, success, warning, info, caution-minor, caution-major, caution-undefined |
| Primer | accent, success, attention, severe, danger, done, open, closed, sponsors |
| Fluent | danger, success, warning, severe |
| GNOME | destructive, success, warning, error |
| Material | error only |
| Radix, Geist | no roles; red, amber, green, blue scales |

The common core is **danger, warning, success and info**. Technical products add neutral or unknown states. For
example, Carbon's `caution-undefined` and Primer's `done`/`closed` cover workflow states that are not good or bad.

### 4.2 Behavior in dark and high contrast

- **Text and fill split by theme.** Status text gets lighter in dark, but fills that carry white labels stay
  mid-tone. GNOME's red is `#c30000` standalone versus a `#e01b24` fill in light, and `#ff938c` versus `#c01c28` in
  dark. Atlassian handles the same split with symmetry.
- **Yellow and amber fills take dark text everywhere.** GNOME warning foreground is black at 80%. Radix amber and
  yellow, Spectrum yellow, orange, chartreuse and celery, and Atlassian `warning.inverse` all do the same. In my
  check white on iOS yellow is 1.51:1.
- **High contrast differs by platform.**
  - Apple ships per-color IC variants, which reach about 4.5:1 against white.
  - Primer aims for 7:1.
  - Fluent drops to system colors.
  - GNOME raises border and dim opacities but does not change its status colors.

### 4.3 Color-vision deficiency

- **Primer's experience.** Its protan/deutan and tritan themes swap red and green for orange and blue, and users
  still find some label pairs indistinguishable. A separate CVD theme is costly and not a complete fix.
- **Datawrapper.** "you can use any colors you like as long as they vary by lightness". Blue is the most stable
  hue for red- and green-blind readers. "The only bulletproof solution is to encode your data with a second visual
  variable" ([Datawrapper](https://www.datawrapper.de/blog/colorblindness-part2)).
- **Apple and WCAG 3.** Apple asks for shapes or icons in addition to color. Red-green and blue-orange are the
  hard pairs ([HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)).
  The WCAG 3 draft adds that "a separate requirement may be needed if red/green CVD is not accounted for" by the
  contrast algorithm.
- **My check: same-lightness red and green fills barely differ under deuteranopia.**

  | Pair | Deutan ΔE |
  |---|---|
  | `oklch(0.56 0.17 27)` danger and `oklch(0.55 0.15 150)` success | 0.031 |
  | danger at L 0.48 and a bluish green `oklch(0.554 0.112 168)` | 0.095–0.102 |

  The second pair is the trick behind Okabe-Ito's "bluish green" `#009E73`.

### 4.4 Categorical palettes: sizes and methods

| Palette | Size | Notes |
|---|---|---|
| Okabe-Ito | 8 (incl. black) | CUD 2008. My check: min ΔE protan 0.096, deutan 0.076. Three of the 7 colors fall under 3:1 on white |
| Tol bright / muted / dark | 7 / 9 / 11 | "distinct for all people, including colour-blind readers". The new dark scheme (Aug 2026) has ≥ 4.5:1 with white "with only some cost for people who are colour blind". "For more than nine distinct colours, a sequential colour scheme can be (mis)used" ([Paul Tol](https://sronpersonalpages.nl/~pault/)) |
| Atlassian chart | 8 | `color.chart.categorical.1–8` |
| Tableau 10 / Observable 10 | 10 | My check: deutan min ΔE 0.007 (red/green) and 0.020 |
| Carbon | 14 | strict order for neighbor contrast |
| Primer | 17 data-vis, 19 display | labels need text anyway |
| Spectrum | 6 | "fewer than 6" advised (partly verified) |

Okabe-Ito's size comes from the [khroma README](https://cran.r-project.org/web/packages/khroma/readme/README.html),
and its 2008 Color Universal Design origin from the same source.

The evidence converges:

- **Up to 6 colors** for series that must be told apart quickly.
- **8 as a ceiling** for charts.
- **Above 8, only with direct labels**, or use a sequential scheme for ordered data.
- Tags and list colors are a different job: they always carry a name, so 10–12 hues work. Atlassian has 10
  accents, GNOME 9, Apple 12 system hues, and the pilot 11.

**My check of the method for westron.** I fixed eight hues and searched lightness and chroma so that every color
reaches **3:1 against the canvas** (WCAG 1.4.11 for marks) and the minimum ΔE stays as high as possible under
normal, protan, deutan and tritan simulation. Hue 95 appears below as a dark yellow-olive.

- **Light canvas `#fbfbfc`**, in greedy order (each next color is the most distinct):

  | # | Hue | Color | OKLCH |
  |---|---|---|---|
  | 1 | blue | `#1e68bd` | 0.520 0.151 255 |
  | 2 | green | `#349d11` | 0.612 0.191 140 |
  | 3 | rust | `#873d00` | 0.450 0.118 50 |
  | 4 | teal | `#00a589` | 0.644 0.122 175 |
  | 5 | magenta | `#ba368c` | 0.556 0.189 345 |
  | 6 | violet | `#9369ec` | 0.626 0.190 295 |
  | 7 | coral | `#e36c66` | 0.672 0.150 25 |
  | 8 | yellow-olive | `#816b00` | 0.533 0.109 95 |

  Every color is ≥ 3.0:1. Min ΔE: normal 0.119, protan 0.083, deutan 0.075, tritan 0.048. That is close to
  Okabe-Ito (protan 0.096, deutan 0.076), which does not meet 3:1.
- **Dark canvas `#1b1c1f`**, in order: `#80b8ff`, `#edc700`, `#e24947`, `#9975eb`, `#ff8025`, `#00a78b`,
  `#ff82cd`, `#8ec682`. Min ΔE: normal 0.138, protan 0.091, deutan 0.086, tritan 0.063.
- **These are proofs of feasibility, not final colors.** The first four of the light set include green next to
  teal (tritan ΔE 0.048). An art-directed pass should reorder and retune them inside the same constraints.

---

## 5. Accent constraints per platform

### 5.1 libadwaita accent

- **Label on the fill.** `--accent-bg-color` carries `--accent-fg-color`, white by default. For westron's CI the
  pair must reach 4.5:1, which GNOME's own accents do not (3.0–3.9). A westron accent therefore sits darker than
  GNOME's. The lightest fill that still passes with white is OKLCH L 0.574 for cobalt (262°, C 0.19), 0.593 for
  violet (298°, C 0.23), 0.558 for teal (192°, C 0.09) and 0.554 for green (150°, C 0.14) (my check). Otherwise set
  a dark `--accent-fg-color`.
- **Derived text color.** `--accent-color` is the fill's a and b at L ≤ 0.5 in light and L ≥ 0.85 in dark.
  - Light: a westron fill at L ≈ 0.52–0.54 becomes L 0.50, which is fine; on the light window this gives 5.5–6.5
    (my check).
  - Dark: at L 0.85, sRGB holds chroma ≈ 0.074 for hue 262 and ≈ 0.085 for hue 298, against ≈ 0.146 for teal 192
    (my check). So blue and violet accents are clipped and change hue. Direction A's cobalt becomes `#87cbff`
    (hue 242), and C's violet becomes `#e2a6ff` (hue 314).
  - Either choose a hue that survives (teal, green, amber), or set `--accent-color` explicitly inside
    `@media (prefers-color-scheme: dark)`. The docs show per-widget overrides of `--accent-color`; an app-wide
    override should work the same way but is not documented (section 7).
- **High contrast cannot be disabled**, and libadwaita does not change the accent in high contrast. To meet 7:1
  with white text, set a darker `--accent-bg-color` in `@media (prefers-contrast: more)`.
- **The user's system accent is overridden** when the app sets one. GNOME allows this ("Apps are still free to set
  their own accent color"), but the user's GNOME 47+ choice is then ignored. This is a product decision, recorded
  in the contract's `platforms` block: macOS behaves the other way round (section 5.3).

### 5.2 Material 3 color scheme from westron tokens

Two routes.

**(a) Map tokens directly to `ColorScheme`.** This is the route the repo report recommends
([Android custom design systems](https://developer.android.com/develop/ui/compose/designsystems/custom)).

- **`primary` is both a fill and a text color.** Filled buttons use it as a container. Text buttons, links,
  selected icons and focus use it as content on `surface`. So `primary` must reach 4.5 against every surface
  container, *and* `onPrimary` must reach 4.5 on it.
  - In light, one dark-ish accent with a white on-color satisfies both. Direction fills sit at L\* 43–46, close to
    Material's tone 40.
  - In dark, a mid-tone fill with white text fails as text on the dark surface. Direction A's lifted accent
    `#4987ff` gives 3.39 with white but 5.49 with the dark canvas. So in dark, Material's `primary` has to be the
    *lifted* accent with a *dark* `onPrimary`. This is Material's tone 80 over 20 convention.
  - That is a visible difference from Apple and GNOME, which keep a mid-tone fill with white text in dark. Either
    record it in each component contract's `platforms` block, or adopt "light fill + dark label" for dark themes
    everywhere.
- **Fill every role westron does not have.**
  - `secondary` and `secondaryContainer`: used for selected navigation items and tonal buttons. Use a low-chroma
    accent, as TonalSpot does with chroma 16.
  - `tertiary`: use the info hue or the accent.
  - Five `surfaceContainer*` levels from neutral steps, lighter is higher in dark.
  - `outline` at 3:1 and `outlineVariant` decorative.
  - The `inverse*` roles for snackbars.
- **High contrast.** Read `UiModeManager.getContrast()` on API 34+ and switch to westron's `*-hc` scheme at a
  threshold; I suggest ≥ 0.5, "medium". Static schemes do not adapt by themselves.

**(b) Generate from a seed with material-color-utilities.**

- The hue is kept, but chroma is capped. TonalSpot primary is chroma 36 (2021) or 32 (2025, 26 in dark), so a
  vivid accent like direction C is visibly muted. The Fidelity and Content variants keep the source chroma in
  `primaryContainer`.
- Tones are fixed per role, so the brand's exact color appears only by accident.
- Use this route only if westron wants Material's role logic for free.
- **Dynamic color**, the wallpaper scheme, replaces the brand entirely. If westron offers it, keep status colors
  fixed and harmonize them toward the source (≤ 15° hue rotation).

What an accent needs as a Material source:

- a hue whose light variant (tone 80, about OKLCH L 0.80) still reads as the brand. Blue and violet lose chroma
  there, as in 5.1;
- enough chroma to survive TonalSpot's cap;
- not yellow or yellow-green, which become olive at tone 40, as Atlassian found.

### 5.3 Apple tint next to Liquid Glass

- **Prominent controls.**
  - The accent colors the *background* of the prominent button, as the system does for Done. Labels and symbols on
    glass stay monochrome. Do not tint the backgrounds of several controls.
  - The label on the tinted fill must reach westron's 4.5 (7 in IC). Apple's own default blue gives 3.52, so
    westron's fill is deliberately darker than system blue.
- **Four variants.** Supply light, dark, IC light and IC dark through an asset-catalog colorset with High Contrast
  enabled. This maps one-to-one onto westron's four themes.
- **Content.**
  - "in apps with primarily monochromatic content or backgrounds, choosing your brand color as the app accent
    color can be an effective way". Colorful content suggests a monochrome toolbar or a strongly differentiated
    accent.
  - For westron's technical products, which are mostly neutral content with status colors and charts, the accent
    must not collide with status hues. A blue accent next to blue "info" is acceptable only if info *is* the
    accent (direction A).
- **macOS.** The system replaces the app accent unless the user chose multicolor. Everything westron draws
  (selection, focus, charts) must look right with any of the system accents. Keep westron's content colors
  independent of `controlAccentColor`.
- **watchOS.** Dark only. The dark and IC dark variants are the ones that ship.
- **The tint on glass cannot be measured statically**, because glass picks up whatever is behind it. The HIG's
  advice is to keep the resting state legible. In the specimens, check the accent fill over the canvas and over
  the most colorful content, such as the chart.

### 5.4 One accent for all platforms

An accent works everywhere when it meets all of the following:

1. **A fill with a white label at 4.5:1.** About L 0.50–0.55 for most hues; 7:1 in high contrast at about L
   0.45–0.49.
2. **A text variant solved per theme.** Reach 4.5 on the hover background (≈ 5.5 on the canvas); 7 in high
   contrast.
3. **A dark variant at L ≈ 0.64–0.76 that keeps the hue in sRGB.** If not, set GNOME's dark `--accent-color` and
   Material's dark `primary` explicitly.
4. **A hue at least about 40° away from the status hues** at similar chroma, unless it doubles as info.
5. **Not yellow or lime**, which loses identity at text lightness.
6. **A defined dark high-contrast fill.** A white label at 7:1 pushes the fill below 3:1 against the dark canvas
   (2.55–2.75 in my checks), so dark high contrast should switch to a light fill with a dark label (≈ 8.5:1 both
   ways).

---

## 6. Recommendations for westron

### 6.1 Ramp structure: 12 steps with one job each, solved against the canvas

Use twelve steps per hue, as in Radix and Geist. Define each step by a **contrast target against the theme's
canvas** (step 1), not by a fixed lightness. A generator in `tools/` authors hue and chroma in OKLCH and
**solves L per theme** so that the target holds under WCAG 2 luminance. The same step number keeps the same job
in all four themes; this is Spectrum's index idea.

| Step | Job | Standard target vs canvas | High-contrast target | Radix / Geist analog |
|---|---|---|---|---|
| 1 | canvas (neutral) or faint tint (hue) | — | — | 1 / bg-100 |
| 2 | subtle surface: sidebar, code block, zebra row | 1.05 | 1.05 | 2 |
| 3 | component rest: chip, field fill, tag bg | 1.12 | 1.12 | 3 / 100 |
| 4 | component hover | 1.20 | 1.20 | 4 / 200 |
| 5 | pressed, selected | 1.32 | 1.32 + a non-color cue | 5 / 300 |
| 6 | separators, decorative rules | 1.55 | **3.0** (westron separator rule) | 6 / 400 |
| 7 | container borders, guides | 2.2 | **4.5** | 7 / 500 |
| 8 | interactive borders, focus ring, meaningful glyphs | **3.0** | **4.5** | 8 / 600 |
| 9 | solid fill: brand or status, highest chroma | on-color **≥ 4.5** | on-color **≥ 7** | 9 / 700 |
| 10 | solid hover | 9 ± small ΔL | same | 10 / 800 |
| 11 | secondary or colored text, icons | **≥ 4.5 on step 4** (≈ 5.4 on canvas) | **≥ 7 on step 4** (≈ 8.5) | 11 / 900 |
| 12 | primary text | ≥ 14 | ≥ 16 | 12 / 1000 |

Design notes:

- **Step 11 is solved against step 4, not the canvas.** Text then stays legible on rest and hover backgrounds,
  which is where Radix's WCAG results fail.
- **Neutral ramps use the same steps plus an alpha series** for overlays (hover, pressed, scrim, glass). Hue ramps
  vary chroma by step: low at 2–5, peak at 8–10, moderate at 11–12.
- **Fit with decisions/0012.** That decision names primitives by OKLCH lightness permille (`color.neutral.977`).
  With per-theme solving, a step's lightness differs by theme. So primitives become `color.<hue>.<1–12>`, with
  values in the resolver's theme contexts, and semantic tokens alias steps. This is a change to 0012 to decide,
  not a detail.

### 6.2 Deriving the four themes

1. **light**: solve every step against the light canvas.
2. **dark**: solve the same targets against the dark canvas, walking *lighter*. Do not invert.
   - Surfaces: canvas, then sunken one step *darker*, then raised and overlay *lighter* (steps 2–4). Lighter is
     higher, as on every platform.
   - Status and accent fills that carry white labels stay the same as in light; text variants are re-solved.
3. **light-hc and dark-hc**: keep the canvas and steps 1–5. That keeps 0012's principle "the same product with
   every quiet thing made clear".
   - Raise steps 6–8, 11 and 12 and the on-solid targets as in the table.
   - Make translucent overlays opaque, as Apple's Reduce Transparency and GNOME's opacity helpers do.
   - Selected states get a non-color cue: a border at step 8 or a check.
   - **In dark-hc, switch solid fills to a light fill with a dark label.** In all three directions a white label at
     7:1 drags the fill below 3:1 against the dark canvas.
4. **Platform mapping.**
   - Apple colorsets: Any, Dark, High Contrast, Dark + High Contrast.
   - Web: `light-dark()` plus `@media (prefers-contrast: more)`, and `forced-colors` for Windows.
   - GNOME: `style.css` media queries.
   - Compose: `ColorScheme` × `getContrast()`.

### 6.3 Neutral options

| Option | Neutral hue | Chroma light / dark | Precedent | Use when |
|---|---|---|---|---|
| Cool | 250–265 | 0.004–0.008 / 0.008–0.012 | Apple, GNOME, Carbon coolGray, Radix slate | precision, technical density; sits naturally next to Apple and GNOME chrome |
| Warm | 70–85 | 0.008–0.012 / 0.008–0.011 | Radix sand, Carbon warmGray, Linear 2026 | everyday apps, long reading; risk of "muddy" above ~0.014 |
| Pure | any | ≤ 0.002 | Fluent, Carbon gray | maximum neutrality for data colors; can feel inert in dark |
| Accent-tinted | = accent hue | 0.004 / 0.012–0.018 | Material, Radix pairing | expressive brands; tinted dark grounds |

Whatever the option, keep the canvas chroma low and give text steps about 1.6× the canvas chroma, so text reads as
"ink", not "colored". Westron's previous warm paper is the pilot's (decisions/0012). Direction B below tests
whether warmth itself is wanted; it does not reuse the pilot's accent.

### 6.4 Status set

- **Hues and roles.** Five statuses: **danger, warning, success, info, neutral**. Each has six roles: text, icon,
  border, subtle background, solid and on-solid.
  - Danger is about hue 27, with its solid at **L ≈ 0.47–0.48**. That is darker than usual, which separates it
    from success under CVD, and white passes 7:1 even in standard themes.
  - Warning is about hue 80. Its solid is bright amber (L ≈ 0.80) with a **dark** label. Warning text is dark
    amber in light (L ≈ 0.48) and amber in dark.
  - Success is a **bluish green, hue ≈ 168** (Okabe-Ito's trick), with its solid at L ≈ 0.55. If the accent
    occupies the teal zone (direction B), success falls back to hue ≈ 148, and the icon becomes mandatory.
  - Info is about hue 245, or simply the accent (direction A).
  - Neutral is the neutral ramp: queued, skipped, cancelled, unknown, debug.
- **Status in technical products.**
  - Log levels: error → danger, warn → warning, info → info or neutral, debug → neutral secondary, trace →
    `icon.tertiary`.
  - Pipeline states: failed → danger, running → info with motion, succeeded → success, queued, cancelled and
    skipped → neutral.
  - Status always comes with an icon and words, as in westron's chapter 02. On Apple, honor
    `accessibilityDifferentiateWithoutColor` with extra shapes. Do not ship a separate colorblind theme; Primer's
    experience is the warning.

### 6.5 Categorical sets

Two families with different jobs:

- **`chart.categorical`: 8 colors, ordered.**
  - Per-theme values: light and dark.
  - Every color ≥ 3:1 against its canvas.
  - Min ΔE in OKLab ≥ 0.07 under simulated protan and deutan for the full set, and ≥ 0.10 for the first four.
    These thresholds are my heuristic; the method is section 4.4.
  - Greedy order, so the first 2–4 colors are the most distinct.
  - In the HC themes, charts add direct labels, markers, dashes or patterns rather than more contrast.
  - More than 8 series means direct labels or a sequential scale. Separate 9–10-step sequential and diverging
    ramps flip in dark, as in Carbon.
- **`category.<name>`: 12 named identity colors** for lists, tags and projects.
  - Keep names, as the pilot does, and regenerate the shades from the new ramps: steps 3, 8, 9, 11 map to
    background, border, fill and text.
  - Twelve fits Apple's 12 system hues and westron's existing 11 (add one).
  - They always carry a name and icon, so CVD distinctness is secondary to harmony.
  - Identity never means status, as in chapter 02.

### 6.6 Accent rules per platform

| Platform | Rule |
|---|---|
| All | Pass the checklist in 5.4. One accent per product; at most one tinted control per screen; the accent never means status, except as info in A. |
| Apple (iOS, iPadOS, watchOS) | `AccentColor` colorset with 4 appearances. Tint the background of prominent actions only; monochrome glass bars by default. Brand color lives in the content layer. |
| macOS | Same colorset; it applies only under multicolor. Every westron surface must also work with the user's accent. |
| GNOME | `style.css` sets `--accent-bg-color` (and a dark `--accent-fg-color` if needed). It sets the dark `--accent-color` explicitly for blue and violet hues, and a darker `--accent-bg-color` in `@media (prefers-contrast: more)`. Overriding the system accent is a recorded decision. |
| Android | Static `ColorScheme` mapped from tokens. `primary` is the text-capable accent, and dark uses a light fill with a dark on-color. Secondary is a low-chroma accent; containers come from neutral steps. HC scheme at `getContrast() ≥ 0.5`. Dynamic color off by default. |
| Web | CSS custom properties per theme. `oklch()` with a hex fallback; P3 extension allowed for direction C. |

### 6.7 Three palette directions for the specimens

All anchors below were computed and checked with the scripts listed at the top. Contrast values are WCAG 2.x;
"n" is a neutral step from 6.1. Neutral hues are the input hues. At chroma below 0.012, the hue measured back
from an 8-bit hex drifts by a few degrees, so a canvas shows, for example, 261 for input 258.

#### A. Instrument: cool and precise

The reasoning: a technical, quiet ground that sits naturally next to Apple's and GNOME's own faintly cool chrome. One
saturated cobalt does all the signaling, and info is the accent, so the screen holds only four hues. It fits dense
tables, logs and dashboards, and suits everyday apps as a "calm tool". Light model: a faint cool canvas with white
raised cards.

| Anchor | light | dark | light-hc | dark-hc |
|---|---|---|---|---|
| Neutral hue (input) / chroma | 258 / 0.007 (text 0.011) | 258 / 0.011 (text 0.018) | as light | as dark |
| Canvas (n1) | `#f7faff` oklch(0.984 0.007 261) | `#101318` oklch(0.186 0.011 261) | same | same |
| n8 interactive border | `#8d9198` (3.0) | `#5b626b` (3.0) | `#6f747a` (4.5) | `#777e88` (4.5) |
| n11 secondary text | `#62676d` (5.45) | `#858c96` (5.48) | `#464a50` (8.52) | `#a8b0bb` (8.50) |
| n12 primary text | `#25282e` (14.1) | `#d9e0ec` (14.0) | `#1a1e23` (16.0) | `#e7effa` (16.1) |
| Accent fill, white label | `#2763d7` oklch(0.531 0.189 262), 5.45 | same, 5.45 (3.41 vs canvas) | `#1650c4` oklch(0.472 0.191 262), 7.05 | **invert**: `#83afff` with a canvas-colored label, 8.46 |
| Accent text | `#245fd4` (5.48) | `#4987ff` oklch(0.644 0.190 262) (5.49) | `#033fb2` (8.51) | `#83afff` oklch(0.755 0.125 262) (8.46) |
| Status solids, light | danger `#a92321` (white 7.12), warning `#f3b01d` (dark label 7.76), success `#008766` oklch(0.554 0.112 168) (white 4.51), info = accent | | | |

Risks:

- In dark, GNOME's derived accent drifts to `#87cbff` (hue 242), so set the dark `--accent-color` to `#4987ff`.
- Cobalt next to iOS system blue may read as "default"; the specimen should judge this.

#### B. Paper: warm humanist

The reasoning: a warm, slightly darker paper ground (not white) and warm charcoal in dark, for long reading and
planning. A low-chroma verdigris (teal) accent is distinctive, calm and far from danger and warning. It is the only
direction whose accent survives GNOME's dark derivation in gamut. Light model: the paper canvas with white raised
cards. **Note:** the warm ground resembles the pilot's. The difference is the accent and the solved ramp, so this
direction tests whether warmth itself is wanted.

| Anchor | light | dark | light-hc | dark-hc |
|---|---|---|---|---|
| Neutral hue (input) / chroma | 75 / 0.011 (text 0.018) | 75 / 0.010 (text 0.016) | as light | as dark |
| Canvas (n1) | `#faf5ee` oklch(0.972 0.011 77) | `#1a1712` oklch(0.206 0.011 81) | same | same |
| n8 interactive border | `#958d83` (3.0) | `#69635a` (3.0) | `#777066` (4.5) | `#867f76` (4.5) |
| n11 secondary text | `#6b635a` (5.44) | `#948d83` (5.44) | `#4e473e` (8.44) | `#b9b2a8` (8.51) |
| n12 primary text | `#2b241c` (14.1) | `#eae3d8` (14.0) | `#1f1911` (16.1) | `#f9f2e7` (16.1) |
| Accent fill, white label | `#007976` oklch(0.520 0.089 192), 5.25 | same, 5.25 (3.40 vs canvas) | `#006462` oklch(0.455 0.078 192), 7.00 | **invert**: `#55c3bf`, 8.46 |
| Accent text | `#00706e` (5.46) | `#279e9a` oklch(0.636 0.100 192) (5.48) | `#00514f` (8.45) | `#55c3bf` (8.46) |
| Status solids, light | danger `#9e2d28` (white 7.34), warning `#edb345` (dark 8.12), success `#26873f` oklch(0.551 0.140 148) (white 4.55), info `#1c7abb` (4.61) | | | |

Risks:

- Success must stay classic green because teal is taken. Danger and success solids then reach only ΔE 0.071
  (standard) and 0.038 (HC) under protan and deutan, so icons are mandatory.
- GNOME derived accents: light `#007370` (5.46 on the window), dark `#84e1dc` (10.40), both in gamut.

#### C. Signal: bold expressive

The reasoning: an almost neutral light ground, an inky violet-tinted dark ground (Material-Expressive-style
tinted dark), and a high-chroma electric violet. Violet is far from every status hue (≥ 50°), so the brand is
unmistakable on dashboards and in empty states. The most "ownable" direction, and the one that most needs
discipline: one tinted control per screen. Light model: a near-white canvas with step-2 sunken areas. P3 may raise
chroma on Apple and the web, with the sRGB values as fallback.

| Anchor | light | dark | light-hc | dark-hc |
|---|---|---|---|---|
| Neutral hue (input) / chroma | 292 / 0.004 (text 0.006) | 292 / 0.016 (text 0.026) | as light | as dark |
| Canvas (n1) | `#fcfbfe` oklch(0.990 0.004 301) | `#0e0d15` oklch(0.164 0.017 290) | same | same |
| n8 interactive border | `#929296` (3.0) | `#5f5d6d` (3.0) | `#757478` (4.5) | `#7b798a` (4.5) |
| n11 secondary text | `#68676b` (5.44) | `#898698` (5.45) | `#4b4b4e` (8.43) | `#acaabc` (8.49) |
| n12 primary text | `#2a292d` (14.0) | `#dcdaec` (14.1) | `#1f1e22` (16.1) | `#eae8fb` (16.0) |
| Accent fill, white label | `#833ddf` oklch(0.540 0.229 298), 5.68 | same, 5.68 (3.40 vs canvas) | `#762ace` oklch(0.492 0.229 298), 7.02 | **invert**: `#bc9bff`, 8.53 |
| Accent text | `#843ee0` (5.44) | `#a267ff` oklch(0.650 0.217 298) (5.45) | `#6810be` (8.47) | `#bc9bff` oklch(0.758 0.143 298) (8.53) |
| Status solids, light | danger `#b00c15` (white 7.22), warning `#f5af00` (dark 7.58), success `#008766` (4.51), info `#007ac1` (4.61) | | | |

Risks:

- GNOME's dark derivation clips violet to `#e2a6ff` (hue 314, pinkish), so set the dark `--accent-color` to
  `#a267ff`.
- Material's TonalSpot would mute this chroma, so use direct token mapping on Android.
- Accent versus info under deutan is ΔE 0.062, adequate but not large.

#### Common to all three

- **Chart palette.** The 8-color method of 6.5. Start from the section 4.4 sets and tune chroma to the direction:
  lower for B, higher for C.
- **Category colors.** Twelve names regenerated from the direction's ramps.
- **Typography color.** Text steps n11 and n12 only. Tertiary words are not allowed, as in chapter 02.

### 6.8 What the specimens should show

- **Layout.** Show each direction on the five shared screens in **all four themes**, side by side at the same
  scale. Use a light and a dark screenshot of the chart over glass on Apple.
- **What the owner judges:**
  - the canvas temperature at a glance;
  - whether the accent survives at "one tinted control per screen";
  - whether status reads instantly in the dense table and the log;
  - whether dark-hc inverted fills feel like the same product.
- **Data rows.** Pick deliberately hard ones: a failed row next to a succeeded row, warning text on a hovered row,
  and a selected row in high contrast.

### 6.9 Relationship to decisions/0012

**Keep these mechanics from 0012:**

- OKLCH with a hex fallback;
- declared contrast pairs in `dev.westron.contrast`;
- compositing translucent colors before measuring (the WCAG 3 draft says the same);
- HC files that hold only changes;
- "move lightness, keep hue and chroma".

**Change these:**

- **Where values come from.** Replace "the pilot's hex values" with generator-solved steps.
- **Primitive naming.** Rename primitives from lightness permille to step numbers resolved per theme.
- **Dark-hc fills.** Add the inverted fill for dark-hc.
- **Success hue.** Make success bluish green where the accent allows.
- **Material's dark `primary`.** Record its convention as a parity entry.

---

## 7. Could not verify, and caveats

- **Atlassian.** Pages are client-rendered. I read structure, step names and token names from the HTML, but could
  not extract reliable hex values or a stated color space. The palette page says "10 swatches in each palette"
  while listing 12 step names (including 250 and 850). The data-visualization page did not render; the 8
  categorical tokens come from the token list.
- **Spectrum.**
  - Data-viz pages did not render. The "6-color, CVD-optimized, use fewer than 6" claim comes from a search
    snippet of the Spectrum page.
  - I could not confirm whether S2 grays are tinted.
  - The S2 index behavior is inferred from three blue values in `color-palette.json`.
- **Material.**
  - m3.material.io did not render. Tone and chroma figures come from material-color-utilities source, and the
    Expressive description from that code plus Android Authority.
  - The 2025 spec's `getCurve(x)` helpers are not fully read; I report the 2021 curves.
  - The Android contrast thresholds (0 / 0.5 / 1) come from an AOSP commit; the constants are hidden API.
- **libadwaita.**
  - The docs document overriding `--accent-color` per widget only. That an app-wide override in `style.css` takes
    effect is my inference.
  - The repo report says GNOME 50 deprecated autoloading `style-dark.css`, but the libadwaita 1.10 docs still
    describe those files as an alternative. I could not confirm the deprecation.
- **Apple.**
  - System color values come from the HIG images' alt text (the June 2025 values). Apple warns values "may fluctuate
    from release to release".
  - Nothing newer than the December 2025 color change log and the September 2026 branding change was found.
- **Observable 10 and Tableau 10.** The Observable post returned HTTP 429. The hex values I tested come from memory
  of d3's `schemeObservable10` and Tableau 10, so treat those two ΔE figures as indicative.
- **CVD method.** The Machado 2009 matrices are typed from memory of the published table. The ΔE thresholds (0.07
  and 0.10) are my heuristics, not a standard. Simulation approximates dichromacy, and anomalous trichromats see
  more.
- **Linear.** The March 2026 refresh post does not mention LCH by name. The LCH generator is from the 2024 post.
- **Carbon.** The absence of a high-contrast theme is based on the pages I read, not a confirmed statement.
- **My anchors.**
  - They are sRGB gamut-mapped by chroma reduction. GTK and browsers may gamut-map differently for `oklch()`
    values outside sRGB, so ship the hex fallbacks for GTK.
  - The anchors are starting points for specimens, not approved values. The CI remains the proof.
