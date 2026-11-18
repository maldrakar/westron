# 08. Accessibility

Date: 2026-11-15. Status: draft for the owner's approval (#8).

Accessibility is part of every component and every theme, not an option added at the end (chapter 00, principle 6).
This chapter sets the targets and says how westron checks them. Where a platform publishes its own rule, westron
follows it and links to it.

## Contrast

The reference is WCAG 2 ([WCAG 2.2](https://www.w3.org/TR/WCAG22/)). The kinds and targets are set in
[decisions/0012](../decisions/0012-color.md); chapter 02 explains them.

| Kind | Standard themes | High-contrast themes |
|---|---|---|
| `text` | 4.5:1 ([1.4.3](https://www.w3.org/TR/WCAG22/#contrast-minimum)) | 7:1 ([1.4.6](https://www.w3.org/TR/WCAG22/#contrast-enhanced)) |
| `large-text` | 3:1 | 4.5:1 |
| `non-text`: glyphs, rings and indicators that carry meaning | 3:1 ([1.4.11](https://www.w3.org/TR/WCAG22/#non-text-contrast)) | 4.5:1 |
| `separator`: rules and guides | none | 3:1 |
| `chart`: a series in a chart | 3:1 | 3:1 |

- **The high-contrast column goes beyond WCAG** for glyphs and rules, where WCAG has no stricter level. A person who
  asks for more contrast gets it on everything that carries meaning, not only on words.
- **A chart keeps 3:1 in high contrast.** Eight series darkened to 4.5:1 would be hard to tell apart. High contrast
  adds direct labels and markers to a chart instead.
- **Large text is WCAG's large text**: at least 18 point, or 14 point bold. The HIG's own table lets bold text of any
  size pass at 3:1 ([HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility));
  westron does not, because a small bold label, such as the overline heading, is still small.
- **Exempt as WCAG defines it**: text and glyphs that are part of an inactive control, purely decorative, not visible
  to anyone, or part of a picture with significant other content, and logotypes. Nothing else is exempt.
- **A disabled control is dimmed whole.** westron draws it at `opacity.disabled`, 0.4, fill, border, label and icon
  together, rather than in colors of its own (decisions/0013). It falls under the exemption for inactive controls,
  so it carries no contrast declaration. Its state is also announced as unavailable (below), so dimming is never the
  only signal.
- **The kind lives with the token.** Each foreground color lists, in `dev.westron.contrast`, the backgrounds it is
  drawn on and the kind of contrast it needs there ([decisions/0010](../decisions/0010-token-structure-and-modes.md)).
  A color that meets only a glyph's target, such as `color.icon.tertiary`, says in `dev.westron.usage`, under `avoid`,
  that it is not for words.
- **The targets hold by construction.** The palette generator solves each step of each ramp for its job's contrast
  in each theme, and it fails with the token and the theme when a target cannot be met (decisions/0012). The
  contrast check then proves every declared pair: on 2026-11-16, `tools/westron tokens contrast` measured 260 pairs
  in each of the four themes, and none failed, the three that the Button contract (#22) draws on the hover and
  pressed fills among them.
- **A stack is measured as it is seen.** A translucent color is composited over what is under it, in gamma-encoded
  sRGB, before its contrast is measured.

## Settings the person chooses

- **Text size.** Text roles map to the platform's text styles, so text follows the person's setting: Dynamic Type on
  Apple, the text scale on GNOME, the font scale on Android, zoom and the default font size on the web
  ([decisions/0013](../decisions/0013-typography-space-shape-motion.md)). The fonts westron ships follow it too. On
  Apple, a heading in Onest or a code role in Geist Mono is `Font.custom(_:size:relativeTo:)` with its text style,
  and a view never sets a size of its own ([decisions/0011](../decisions/0011-icons-and-fonts.md)). The HIG asks apps
  to let text grow to at least 200 percent, or 140 percent on watchOS. Layout reflows instead of clipping: lines wrap,
  rows grow, and a row that runs out of width stacks its parts. Spacing that belongs to text scales with it, and so do
  icons (chapter 07).
- **Reduce Motion.** Every motion has a reduced form (decisions/0013):
  - a spring loses its bounce;
  - travel becomes a fade of at most 150 ms;
  - changes of scale and depth are dropped;
  - color fades stay, and so does a pause that lets a person read a change;
  - animations turned off on the platform (`gtk-enable-animations = false`, an animator scale of 0) mean every change
    is instant.

  Nothing flashes more than three times a second
  ([2.3.1](https://www.w3.org/TR/WCAG22/#three-flashes-or-below-threshold)).
- **Reduce Transparency.** Glass and materials are the system's, and they adapt to this setting by themselves
  ([HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials)). A translucent surface that
  westron draws itself becomes opaque when the setting is on.
- **Increase Contrast and high contrast.** The setting selects the `light-hc` or `dark-hc` theme.
  - The high-contrast themes keep the canvas and the surfaces, and move separators, borders, secondary and colored
    text further from the ground (decisions/0012).
  - Every raised surface gets an outline in `color.border.default`, because a shadow alone does not mark an edge
    (decisions/0013).
  - In `dark-hc`, a fill with a white label turns light and its label dark, so that the pair reaches 7:1 and the
    fill still stands out from the dark canvas.
  - On Apple, each colorset carries all four themes and the system switches them. watchOS shows the dark theme
    whatever its contrast setting (decisions/0010).
  - On GNOME, libadwaita applies high contrast whenever the person asks for it, and an app "cannot disable it"
    ([libadwaita](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/1-latest/styles-and-appearance.html));
    westron's own CSS follows it under `prefers-contrast: more`. On the web it is the same media query. Android's
    mapping is decided in phase 8.

## Screen readers

VoiceOver on Apple, Orca on GNOME, TalkBack on Android, and the screen readers of the web.

- **A system control keeps its own role and traits.** This is one more reason for styles on system controls
  ([decisions/0003](../decisions/0003-styles-on-system-controls.md)).
- **A custom component declares** its role, label, value, states and actions in its contract's `accessibility` block.
  Each platform maps them to its own API.
- **Every element has a short, accurate name.** An icon-only control is labelled by what it does ("More", not
  "Ellipsis"). Decorative graphics are hidden. States are announced: selected, unavailable, busy.
- **Every gesture has another way.** An action reached by a swipe, a drag or a long press is also a named accessibility
  action, a menu item or a keyboard command. The pilot's swipe to delete is also an accessibility action, and its drag
  between lists is also "Move to…" ([2.5.7](https://www.w3.org/TR/WCAG22/#dragging-movements)).

## Hit targets

westron's target is the platform's recommended size. The hit area may be larger than what is drawn.

| Platform | Recommended | Floor | Source |
|---|---|---|---|
| iOS, iPadOS | 44×44 pt | 28×28 pt | [HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility) |
| macOS | 28×28 pt | 20×20 pt | HIG Accessibility |
| watchOS | 44×44 pt | 28×28 pt | HIG Accessibility |
| GNOME | no number: "large enough to be comfortably used with different pointing devices and physical abilities" | — | [GNOME HIG](https://developer.gnome.org/hig/guidelines/pointer-touch.html) |
| Web | 44×44 CSS px (AAA) | 24×24 CSS px (AA) | [2.5.5](https://www.w3.org/TR/WCAG22/#target-size-enhanced), [2.5.8](https://www.w3.org/TR/WCAG22/#target-size-minimum) |
| Android | 48×48 dp | — | [Android accessibility](https://developer.android.com/guide/topics/ui/accessibility/apps) |

The value for each platform lives in its platform token file, not in component code. The control heights are there
(#56): `size.control.m` is 44 on iOS, iPadOS and watchOS, the recommended target, and 32 on macOS, above its
recommended 28. `size.control.s` is below the recommended size on every platform, 32 on touch and 24 on macOS, so a
control drawn at it keeps a hit area of the recommended size around what it draws.

## Keyboard and focus

- On macOS, iPadOS with a keyboard, GNOME and the web, every action is reachable from the keyboard. GNOME puts it
  plainly: "every action should also be possible with the keyboard"
  ([GNOME HIG](https://developer.gnome.org/hig/guidelines/keyboard.html)).
- Focus is always visible, and the platform draws it. A custom component shows focus the way the platform does.
- Focus order follows reading order. Escape closes what is open. Shortcuts use the platform's modifier (chapter 09).
- On watchOS, the Digital Crown scrolls and adjusts values.

## Color is never the only signal

A state shown in color also shows a shape, a glyph or a word ([1.4.1](https://www.w3.org/TR/WCAG22/#use-of-color);
[GNOME HIG](https://developer.gnome.org/hig/guidelines/ui-styling.html)).

- **A status always has an icon and a word.** A failed build shows a crossed circle and the word "Failed"
  (decisions/0012, chapter 02).
- **A list color is identity, never the only cue.** A list also has an icon and a name.
- **A checked control shows a mark.** A checked box or a completed task is a fill with a mark, not only a color.
- **Differentiate Without Color.** On Apple, when the person turns it on, a cue that is normally left out appears.

## How westron checks

| Check | What it catches | When |
|---|---|---|
| Palette generator | A ramp step that cannot meet its contrast target in a theme; it fails with the token and the theme | `tools/westron generate`, on every change to `tokens/palette.json` |
| Contrast check (#15) | Every declared pair in `dev.westron.contrast`, by kind (`text`, `large-text`, `non-text`, `separator`, `chart`), in all four themes | `tools/westron tokens contrast` in CI, on every token change |
| Raw-values lint | Colors, sizes and motion that bypass the tokens, and so the themes | Hook and CI |
| Accessibility audit (#25) | `performAccessibilityAudit` on catalog entries: contrast, labels, hit regions, clipped text, Dynamic Type, traits | UI tests, from phase 2 |
| Snapshot matrix (#24, #72) | Every option value at rest and in each state, in the four themes side by side at the `large` text size, and in the light theme at `xSmall` and `accessibility5`, so the owner sees how a component grows with the person's text size (on iOS; macOS has no Dynamic Type). Hand-written supplementary sheets, marked "not a contract option", add what no option sets, such as Button's label without an icon while loading. Other text sizes: `tools/apple/catalog-screenshot.sh --dynamic-type`; the accessibility audit's Dynamic Type test (`testAccessibilityDynamicType`) checks the catalog entries at `accessibility5` | Second approval gate |
| `a11y-auditor` subagent | Roles, labels, Dynamic Type, Reduce Motion, Reduce Transparency, keyboard, by reading code and screenshots | After each implementation, before the owner sees it |

The subagent is defined in [`.claude/agents/a11y-auditor.md`](../.claude/agents/a11y-auditor.md). GNOME has no ready
tool for screenshots and an accessibility audit; phase 7 builds one (#45).

## Open questions

1. **Hit targets on GNOME and the web.** Which value does westron adopt where the platform names none or two?
2. **Dense controls.** decisions/0013 keeps rows at 44 pt on iOS and 48 dp on Android in every density. May a
   control in the `compact` density go below the recommended hit target, down to the platform's floor?
3. **Increase Contrast on the watch.** watchOS asset catalogs take no appearances, so the watch shows the dark theme
   even when the person asks for more contrast (decisions/0010). Does the watch need its own way to the `dark-hc`
   colors?
4. **A manual pass.** Should the second approval gate include a pass with a screen reader by a person?
