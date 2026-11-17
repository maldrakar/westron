# 0002. Portability of the Button contract to web and GTK

Date: 2026-11-16. Status: proposed. Findings of #26 for the owner. The contract is approved, so nothing in
`button.spec.yaml`, `spec/conventions.md` or the schema has changed: the changes this file proposes go through the
owner.

## Context

The Button contract (decisions/0001 of this folder) was written with SwiftUI as the pilot platform. decisions/0002
of the repository names the risk: "the contract may quietly take on SwiftUI assumptions". Before a second component
is specified, #26 checks Button with two short prototypes, in [`../prototypes/`](../prototypes/README.md):

- **Web:** a native `<button>` with CSS, no framework and no build step. The token values come from `tokens/`
  through a small script (`web/resolve-tokens.swift`), since the CSS token generator is #39.
- **GTK:** stock `GtkButton`s with style classes in a PyGObject window, and a CSS file for GTK 4.20.

### Evidence and its limits

- **Web: verified by run** in WebKit, through `WKWebView` (Xcode 27.1, macOS 26), the engine of Safari; Chrome and
  Firefox were not available. `web/snapshot.swift shot` rendered the page to PNG in four themes and with the hit
  areas outlined; `web/snapshot.swift probe` sent synthetic `NSEvent`s to the web view and read back what WebKit
  matched. Where the tables below say **forced**, the state was drawn through `data-state`, because a static capture
  has no pointer and no keyboard; the CSS excludes the forced twin exactly where it excludes the pseudo-class.
  - Dark was selected by the real `prefers-color-scheme` (the web view's dark appearance). `light-hc` and `dark-hc`
    were forced with `data-theme`: `prefers-contrast` follows a system setting this run could not change.
  - The evidence is committed in [`../prototypes/evidence/`](../prototypes/evidence/), downscaled to 2000 px wide:
    [`web-light.png`](../prototypes/evidence/web-light.png),
    [`web-dark-hc.png`](../prototypes/evidence/web-dark-hc.png),
    [`web-hit-44.png`](../prototypes/evidence/web-hit-44.png) and the probe's output,
    [`web-probe.txt`](../prototypes/evidence/web-probe.txt). The dark and light-hc captures are not committed; the
    prototypes' README has the commands that render them again.
  - Not exercised: hover from pointer motion alone (synthetic `mouseMoved` did not set `:hover`; `mouseDown` did),
    a real `:focus-visible` (the off-screen window never became key, so `:focus` read false, although Space and
    Return still activated the focused button), `(pointer: coarse)`, the real
    `prefers-reduced-motion` (its rules were forced), forced colors, and any screen reader.
- **GTK: not run.** GTK 4, libadwaita and PyGObject were not installed, and nothing was installed for this issue.
  Every GTK finding is marked **doc**, verified against the GTK 4.24 and libadwaita 1.10 documentation and
  libadwaita's `_buttons.scss` (URLs below), or **unverified**, where the documentation says nothing and the claim
  comes from the prototype's design alone. The command to run it once GTK is there:
  `python3 spec/components/button/prototypes/gtk/button.py --screenshot .build/button-prototype/gtk-light.png`.

Sources for GTK: [GTK CSS properties](https://docs.gtk.org/gtk4/css-properties.html),
[GTK CSS overview](https://docs.gtk.org/gtk4/css-overview.html),
[libadwaita style classes](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/1-latest/style-classes.html),
[styles and appearance](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/1-latest/styles-and-appearance.html),
[CSS variables](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/1-latest/css-variables.html),
[AdwApplication](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/1-latest/class.Application.html),
[AdwButtonContent](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/1-latest/class.ButtonContent.html),
[AdwSpinner](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/1-latest/class.Spinner.html),
[GtkAccessibleState](https://docs.gtk.org/gtk4/enum.AccessibleState.html),
[gtk-interface-reduced-motion](https://docs.gtk.org/gtk4/property.Settings.gtk-interface-reduced-motion.html),
[`_buttons.scss`](https://gitlab.gnome.org/GNOME/libadwaita/-/raw/main/src/stylesheet/widgets/_buttons.scss).

## Summary

Verdicts: **carried over** as written; **note**, carried over with a platform note that the contract's `platforms`
block should record; **assumption**, the contract carries a SwiftUI assumption that the other platforms cannot honor
as written.

| Part of the contract | Web | GTK | Verdict |
|---|---|---|---|
| `variant` | `data-variant`; verified | own class per variant; doc | carried over |
| `role` | collides with ARIA's `role` (reasoning); `data-role` verified | `.destructive-action` is a tint, not a fill; doc | note |
| `size` | heights verified; no `web` token context; touch is an input, not a platform | no size classes, content-box `min-height`; doc | assumption |
| `iconOnly` | `aria-label`, square verified | `set_icon_name`, tooltip, accessible label; unverified | carried over |
| hover | exclusion verified with real `:hover`; motion-only hover not exercised | `:hover` flag; unverified | carried over |
| focus | outline verified; no offset: ring 1.13–1.48 against the fill | the system's ring; doc | assumption |
| pressed | real `:active`, pressed fill and 98 % scale verified | `transform` exists; doc | carried over |
| disabled | whole control at 0.4 verified; WebKit matches `:hover` and `:active` while disabled | libadwaita's own dimming must be replaced; doc | note |
| loading | indicator, width, exclusion verified; presses need a script; busy announcement unverified | no busy button, spinner swap; refusing presses unsolved for action-bound buttons; doc and unverified | assumption |
| slots `label`, `icon` | fixed inner markup needed | `AdwButtonContent` takes an icon name only; doc | note |
| bindings: one token, by size | custom properties per size; verified | same; doc | carried over |
| bindings: `cases` | translated by hand to selectors; verified | same; unverified | note |
| bindings: "no value" | a native control draws its own look | libadwaita draws a fill | assumption |
| `label.font` | px → rem; `system-ui` | rem resolves against GNOME's font; no `system-ui`; doc | note |
| `icon.font` | an SVG has no font | an icon has a pixel size | assumption |
| `progress.color` | verified, but westron draws the indicator | `AdwSpinner`; doc | assumption |
| `focusRing.*` | needs an offset | not applied; doc | assumption |
| motion | spring sampled to `linear()`; reduced rules verified forced | curve only; `reduced` keyword; doc | note |
| `accessibility` | role, label, disabled verified by markup; busy unverified | `BUSY` exists; doc; Orca unverified | note |
| `platforms.web` | mostly right; two corrections | — | note |
| `platforms.linux` | — | the class map can be written now | note |
| hit area | no target token; at 44 px, neighbours' areas overlap (screenshot) | no mechanism documented | assumption |
| themes and contrast modes | four themes verified (two forced) | media queries since GTK 4.20; doc | carried over |

## Findings

### Options

- **`variant`: carried over.**
  - Web, verified: `data-variant="primary|secondary|tertiary"` on the `<button>`; every value draws as the contract
    binds it in four themes ([`web-light.png`](../prototypes/evidence/web-light.png),
    [`web-dark-hc.png`](../prototypes/evidence/web-dark-hc.png); dark and light-hc rendered the same way and not
    committed).
  - GTK, doc: primary is `.suggested-action`; tertiary is `.flat`. libadwaita has **no outlined button** (no style
    class draws a border without a fill), so secondary needs westron's own class, `.westron-secondary`.
- **`role`: note.**
  - Web, by reasoning, not run: the option cannot be an attribute named `role`. `role` is the ARIA attribute on
    every HTML element, so an option of that name collides with it. `role="destructive"` is not an ARIA role, so a
    user agent ignores it and the button keeps its implicit role, but the markup is invalid; and an option value that
    happened to be a valid ARIA role would re-role the button. The prototype writes `data-role` (verified to draw);
    a custom element (#40) would need another name. This is the web's twin of the `ButtonRole` collision the Apple
    entry records.
  - GTK, doc: libadwaita's `.destructive-action` is **not a filled red button**. Its `_buttons.scss` sets
    `color: var(--accent-color)` with a 15 % `currentColor` tint, so it matches none of the contract's destructive
    variants. Combined with `.suggested-action` it is undocumented. A style class also carries no accessible meaning.
    The prototype maps the role to `.destructive-action` on every variant and lets westron's CSS draw each combination.
- **`size`: assumption.**
  - Web, verified: 24, 32 and 40 px with a fine pointer, as min-heights, so the button grows with its text.
  - The resolver's `platform` modifier has only `ios`, `macos` and `watchos`, so the prototype borrows `macos`.
    decisions/0010 expects `web` and `gnome` contexts with their phases.
  - **The assumption:** the contract says "24, 32 and 40 with a pointer (macOS), 32, 44 and 52 on touch", and the
    tokens choose by platform at build time. On Apple the platform decides the input. On the web the same page meets
    a mouse and a finger, so the input is known only at runtime, through `(pointer: coarse)`. The prototype's
    `tokens.css` switches to the touch heights under that query (not exercised: WebKit on a Mac reports
    `(pointer: fine)`). GNOME runs on laptops and phones alike, with libadwaita's own 34 px buttons for both.
  - GTK, doc: libadwaita has no size classes, so westron adds `.westron-s|m|l`. GTK has **no `box-sizing`**, so
    `min-height` must subtract the border: `calc(var(--wb-height) - 2 * var(--wb-border-width))`.
- **`iconOnly`: carried over.**
  - Web, verified: `data-icon-only` and `aria-label`; the square is `aspect-ratio: 1` with `min-width` equal to the
    height (32 × 32 px at m, measured).
  - GTK, unverified: `set_icon_name()`, which makes GtkButton add `.image-button`, a tooltip and
    `GTK_ACCESSIBLE_PROPERTY_LABEL`. Whether Orca reads the label rather than the tooltip is not checked.

### States

- **hover: carried over.**
  - Web, verified: only under `(hover: hover)`. The probe pressed a disabled and a busy button: WebKit reported
    `:hover=true` on both, and the fill stayed at rest (`rgb(40, 99, 215)`, the accent). Hover from motion alone was
    not exercised.
  - GTK, unverified: `:hover` is `GTK_STATE_FLAG_PRELIGHT` (doc); the exclusion
    `:hover:not(:disabled):not(.westron-loading)` was not run.
- **focus: assumption.**
  - Web, verified with forced focus: an outline of `stroke.thick` in `color.border.focus` on `:focus-visible`. The
    contract gives **no offset**, so the ring is drawn against the button's own edge. The ring against the fill it
    touches measures 1.48 (light), 1.21 (dark), 1.26 (light-hc) and 1.13 (dark-hc) on primary, and 1.00–1.01 against
    secondary's border; against the canvas it is 3.53–6.23. In
    [`web-dark-hc.png`](../prototypes/evidence/web-dark-hc.png) the ring on a primary button disappears into the
    fill; with an offset of `stroke.thick` it sits on the canvas, as the "offset proposed" column shows.
  - Why the verdict is "assumption", and what it rests on: the contract binds the ring only on the web, where westron
    draws it, and there the missing offset is verified above. That the system rings on Apple and GTK keep a gap from
    the fill, so that nobody needed an offset, is **unverified**: Apple's ring was not looked at in this issue, and
    for GTK only libadwaita's `_buttons.scss` was read, which passes `$outer: true, $offset: 1px` to its
    `focus-ring` mixin for `.suggested-action`; the mixin's definition was not read.
  - GTK, doc: the system's ring; nothing to apply. Note that GTK sets `:focus-visible` on the focused widget and all
    its ancestors, unlike CSS.
- **pressed: carried over.**
  - Web, verified: under a real `mouseDown`, `:active` matched, the fill became `accent-pressed`
    (`rgb(15, 74, 188)`) and the transform `matrix(0.98, 0, 0, 0.98, 0, 0)`.
  - GTK, doc: `transform` and `transform-origin` are supported properties; the rule is unverified.
- **disabled: note.**
  - Web, verified: `opacity: 0.4` on the whole control
    ([`web-light.png`](../prototypes/evidence/web-light.png), "disabled"). The browser's own disabled text color is
    overridden by westron's. **WebKit matched `:hover` and `:active` on a disabled button** under the probe's
    press, so the `platforms.web` text, which names only `:hover` while disabled, should name both. The click did not
    reach the page's handler.
  - GTK, doc: libadwaita dims a disabled button with `filter: opacity(var(--disabled-opacity))`, 50 % (40 % in high
    contrast), and a flat one more strongly; its helper variables "should not be overridden". westron sets its own
    `filter: opacity(var(--westron-opacity-disabled))` on every variant. `set_sensitive(false)` is the API.
- **loading: assumption, on three counts.**
  1. **"Presses are not accepted" is behavior, and a style cannot refuse a press.**
     - Web, verified: a native `<button aria-busy="true">` is still enabled. The probe pressed it: `:active` matched
       (the fill stayed at rest and it did not scale, as the contract asks), and WebKit dispatched the click. Space
       and Return on it dispatched two more. A capture-phase listener in the page stopped all three, so the page's
       handler accepted none; the same sequence on the primary button was dispatched and accepted three times. The
       listener also covers implicit form submission, which arrives as the same `click`. `disabled` is not an
       option: it would dim the button, drop it from the tab order and announce it as unavailable. So the web's
       "style on a system control" needs a script for this state; that fits a custom element (#40) better than CSS
       alone.
     - GTK, unverified: a handler connected first stops the `clicked` emission while loading
       (`button.py`, `_refuse_while_loading`). That stops the product's later `clicked` handlers at best. `clicked`
       is likely a RUN_FIRST signal whose class handler activates the button's `action-name`; if so, the class
       handler runs before any connected handler, and the guard does not stop an action-bound button, which is the
       usual case in GNOME apps. Disabling the action instead makes the button insensitive, which dims it and
       announces it as unavailable. So GTK has no known way yet to refuse a press without looking disabled.
     - On Apple, outside this issue and unverified: a `ButtonStyle` cannot cancel its button's action either; only a
       `PrimitiveButtonStyle` decides when to trigger. The SwiftUI implementation should check this before #24.
  2. **The indicator is the system's on Apple and GTK, and the web has none.**
     - Web, verified: westron must draw it. The prototype draws a ring in `progress.color` at the icon's size, but
       its stroke, its gap and its period are raw values: the contract and the tokens bind none of them.
     - Chapter 05 says that under Reduce Motion nothing loops; a spinner loops. The prototype stops it, which leaves
       a still ring. The contract does not say what a westron-drawn indicator does under Reduce Motion.
     - GTK, doc: `AdwSpinner` (libadwaita 1.6) is a widget of 16 to 64 px. Its pages say nothing about reduced
       motion or about use inside a button.
  3. **"The width does not change" costs a second copy of the label everywhere.**
     - Web, verified: the label sizes the button through a hidden copy of its text (`data-label`), and the visible
       row (indicator, gap, label) overlays it. Measured in all 18 cases of the state matrix: every loading button
       kept its resting width to 0.01 px.
     - The consequence of P13 is visible: at size m, a label-only "Add list" reads "Ad…" and "Delete" reads "D…"
       ([`web-light.png`](../prototypes/evidence/web-light.png), "loading"). A two-word label keeps two letters.
     - Since 2026-11-17 P13 is changed (decisions/0001): without an icon the button widens by the indicator and the
       gap, so the label is not truncated. The width holds only where the indicator takes an icon's place, and the
       prototypes' label-only loading layout (`web/button.css`, `gtk/button.py`) is out of date.
     - GTK, unverified: the same needs a `GtkOverlay` whose overlay child is not measured
       (`set_measure_overlay(false)`), over the resting content made transparent. `AdwButtonContent` cannot hold a
       spinner (it takes an icon name only), so the content is rebuilt.
  - The exclusion of hover and pressed while loading is verified on the web (point 1).
- **The rule that disabled and loading exclude hover and pressed: carried over.** Verified on the web with real
  pseudo-classes for both states (above). On GTK the selectors are written and unverified.

### Slots

- **`label` and `icon`: note.**
  - Web, verified: the slots are not free content. westron's CSS needs a fixed inner structure: an icon wrapper
    hidden from assistive technology, a label wrapper with a copy of its text for the width rule, and a text span
    that can ellipsize. A product writing a plain `<button>Save</button>` gets neither the loading layout nor the icon
    sizing. The conventions cell "the element's content" understates this; it is another argument for a custom
    element in #40.
  - GTK, doc: `AdwButtonContent` has `icon-name`, `label`, `use-underline` and `can-shrink`, and no paintable or
    child property.

### Token bindings

- **One token, and one token per size: carried over.** Web, verified: the size picks custom properties
  (`--wb-height`, `--wb-padding`, `--wb-gap`, the font fields) that the rules read. GTK, doc: custom properties and
  `var()` exist since GTK 4.16, `calc()` is supported.
- **`cases`: note.** The first-match order has no direct CSS form. The prototype translated it by hand: the resting
  values by variant and role, then hover and pressed rules guarded by `:not(:disabled, [aria-busy="true"])`, which is
  what the leading `state: [disabled, loading]` cases mean. It worked (verified on the web), but a generator (#39)
  or the parity lint (#21) cannot check it without a rule for that translation.
- **"No value": assumption.** For secondary and tertiary at rest, `container.background` has no value, and for
  primary and tertiary `container.borderWidth` has none. A SwiftUI `ButtonStyle` starts from nothing, so no value
  draws nothing. A native `<button>` draws the browser's fill, border, font and color (reset in `web/button.css`), and
  a libadwaita button draws a 10 % `currentColor` fill and its own hover fills (replaced in `gtk/button.css`).
  "No value" has to mean "nothing drawn", stated, not "leave the platform's look".
- **`label.font`: note.**
  - Web, verified: the typography tokens hold px sizes, which do not follow the person's default font size (chapter
    08), so the script writes rem of 16 px. `font.family.system` is `system-ui`, a CSS keyword that works on the web.
  - GTK, doc: rem resolves against the initial font size, which comes from `gtk-font-name`, not 16 px; with GNOME's
    default of 11 pt (about 14.7 px), 0.9375 rem would be about 13.75 px. `system-ui` is not documented in GTK CSS,
    so the GTK output leaves the family out and the button keeps GNOME's font.
  - Both sizes are Apple's text styles at their iOS default; the web and GNOME read them as fixed sizes.
- **`icon.font`: assumption.** A text role as an icon's size is SF Symbols' model: a symbol is a glyph of the font.
  A web icon is an SVG and a GTK icon is an image with a pixel size (`-gtk-icon-size`). The prototypes read it as
  "the icon's box is 1 em of the label's role", which is a reading, not the contract.
- **`progress.color`: assumption** as above: it presumes a system indicator that takes a tint.
- **`focusRing.color` and `focusRing.width`: assumption**, for the missing offset (states, focus).
- **`container.opacity`, `container.radius`, borders and colors: carried over.** Verified on the web in four themes;
  in `dark-hc` the fills turn light with dark labels, as chapter 02 says.

### Motion

- **`motion.fade` and `motion.press`: note.**
  - Web, verified: `motion.press` has a spring (duration 0.15 s, bounce 0). The script samples it into `linear()`
    with SwiftUI's model, stiffness (2π / 0.15)² and critically damped, so the web runs the same motion as SwiftUI's
    `spring(duration: 0.15, bounce: 0)`. The spring's 0.15 s is a perceptual duration; the motion settles within
    0.1 % at about 0.22 s on both, which is why the CSS transition lasts 221 ms. There is no gap
    between the two, and no proposal rests on one (C11 is about the scale and the release).
  - CSS takes a transition's timing from the state it goes to, so the release from pressed runs in `motion.fade`
    for the tint; SwiftUI's `.animation(.press, value: isPressed)` runs both directions in `press`. The contract
    does not say which.
  - The 98 % press scale is prose in chapter 05, not a token, so both prototypes write it as a raw value.
  - GTK, doc: the documentation does not list `linear()` among timing functions, so GTK takes the cubic curve and
    the duration, as chapter 05 expects.
- **Reduce Motion: note.**
  - Web, verified with forced rules: the forced pressed button reported `matrix(0.98, …)` and then `none` once the
    reduced-motion rules applied; the tint stays.
  - GTK, doc: the media feature exists since GTK 4.20, but its value is `reduced`, not CSS's `reduce`, and the
    setting `gtk-interface-reduced-motion` exists since GTK 4.22.

### Accessibility block

- **`role: button`, `intents: [activate]`, `keyboardIntents: [activate]`: carried over.** Native on both. Keyboard
  activation of the native `<button>`: Space and Return each dispatched a click (probe, above).
- **`label: required`: carried over.** Visible text, or `aria-label` when icon-only; the icon beside a label is
  `aria-hidden`. GTK, unverified: the tooltip and the accessible label property.
- **`states.disabled: disabled`: carried over.** The native `disabled` attribute and `set_sensitive(false)`.
- **`states.loading: busy`: note.**
  - Web, unverified: `aria-busy` is defined for a region whose content is being updated, so that assistive technology
    can wait; it is not a control's state, and screen readers are not known to announce it on a button. A reliable
    form is likely `aria-busy` plus text in a live region or the description. No screen reader was run.
  - GTK, doc: `GTK_ACCESSIBLE_STATE_BUSY` is "a busy state" with boolean values; what Orca says is unverified.
  - On Apple, outside this issue and unverified: UIKit has no busy trait either. The abstract state may need a
    per-platform mapping in the conventions rather than one word.
- **`keyboardIntents` beyond activate: note.** macOS adds `defaultAction` and `cancelAction`. The web has a default
  action too, implicit form submission by Return, and GTK has a window's default widget. Neither entry records it.

### The `platforms` entries

- **`web`: note.** As written it holds: `base: button`, the outline on `:focus-visible`, hover under `(hover: hover)`,
  circular corners, the exclusion. Corrections and gaps, all verified on WebKit: `:active` also matches while
  disabled; the option `role` is written `data-role`; loading refuses presses through a script; the focus ring needs an
  offset; the touch heights under `(pointer: coarse)`.
- **`linux`: note.** The entry leaves the class map to phase 7; the prototype can already propose it: primary
  `.suggested-action`, secondary `.westron-secondary`, tertiary `.flat`, the destructive role `.destructive-action`,
  sizes `.westron-s|m|l`, icon-only `.westron-icon-only`, loading `.westron-loading`. Also: libadwaita 1.9 deprecated
  the per-theme files `style-dark.css`, `style-hc.css` and `style-hc-dark.css` in favor of media queries in
  `style.css` (doc), and an application provider at `GTK_STYLE_PROVIDER_PRIORITY_APPLICATION` wins over libadwaita
  whatever the selectors' specificity (unverified).
- **Naming:** the contract says `linux`, decisions/0010 plans a `gnome` token context, and the conventions table
  says GTK. One name would do.

### The hit-area rule: assumption

- The contract says the hit area is at least the platform's recommended target. No token holds a target: on Apple
  `size.control.m` happens to equal it on touch, and the rule rests on that. The web names two targets, 24 px (AA)
  and 44 px (AAA), and chapter 08 leaves the choice open (question 1); GNOME names none.
- Web, verified: with 44 px, a pseudo-element extends each button's hit area. At size s, icon-only buttons 8 px apart
  have extended areas that overlap their neighbours'
  ([`web-hit-44.png`](../prototypes/evidence/web-hit-44.png), the last row and every s cell). The contract says
  nothing about neighbours.
- GTK, unverified: the documentation does not say whether the input area is the border box or includes the margin,
  and names no way to make it larger than what is drawn.

### Themes and contrast modes: carried over

- Web, verified: four themes from `prefers-color-scheme` and `prefers-contrast`; dark selected for real, the
  high-contrast ones forced ([`web-dark-hc.png`](../prototypes/evidence/web-dark-hc.png); light-hc not committed).
  Forced colors (Windows) are not exercised: the prototype keeps a transparent border so that every variant keeps an
  outline there.
- GTK, doc: media queries `prefers-color-scheme` and `prefers-contrast` since GTK 4.20; an application cannot disable
  high contrast.

## The conventions table, cell by cell

Web and GTK cells of `spec/conventions.md` checked against the prototypes. Cells not listed held as written.

| Row | Column | Status | What the prototype showed |
|---|---|---|---|
| Component id and naming | GTK | unverifiable | The extension trait is Rust; the Python prototype sets classes directly |
| Enum option: the variant | Web | incomplete | A custom element's attribute cannot be named `role`; the conventions need a rule against option names that are global HTML attributes (`role`, `hidden`, `title`) |
| Enum option: the variant | GTK | wrong in part | "The stock class where one exists": the stock classes do not draw the contract's look (`.destructive-action` is a tint), and the role is a class of its own that combines with the variant's |
| Size option | Web | wrong in part | A native `<button>` has no `size` attribute: `data-size` or a class. The heights depend on the input at runtime, which the cell does not mention |
| Size option | GTK | incomplete | GTK's `min-height` is the content box, with no `box-sizing` |
| Bool option | GTK | incomplete | The cell already allows a style class; it could add that a stock `GtkButton` gains no GObject property without a subclass, so a style class it is, with the value kept by the extension trait |
| States the system control has | Web | incomplete | WebKit matches `:active` too while disabled, not only `:hover` |
| States the system control has | GTK | note | `:focus-visible` is set on ancestors too (doc) |
| States the system control lacks | Web | incomplete | `aria-busy` styles and labels the state but refuses no press; a script is needed, and the announcement is unverified |
| States the system control lacks | GTK | incomplete | Besides the class and `Busy`: a spinner swap, and a way to refuse presses that a guard on `clicked` likely does not give for action-bound buttons (unverified) |
| Slots | Web | incomplete | westron's CSS needs a fixed inner structure, not any content |
| Slots | GTK | incomplete | `adw::ButtonContent` cannot show a spinner |
| Token bindings | GTK | wrong in part | Setting libadwaita's variables is not enough: a regular button's hover is a `currentColor` mix in `background-color`, the opaque buttons' (`.suggested-action`) an overlay `background-image`, its helper variables should not be overridden, and westron sets backgrounds itself. "Rust constants for values outside CSS" is unverifiable here |
| Accessibility: keyboard intents | Web, GTK | incomplete | A default action exists on both (implicit submission; the default widget) |
| The `platforms` block | GTK | incomplete | The map is per option: the role's class too, not only the variant's |
| Defaults | Web | unverifiable | Nothing makes an attribute required on a native element; without `data-variant` the browser's look shows |
| Defaults | GTK | wrong in part | A stock widget has no constructor argument to require: the variant becomes a required argument of the extension trait's method |
| Modes | GTK | incomplete | Media queries in `style.css` (GTK 4.20) replace the per-theme files, deprecated in libadwaita 1.9 |

## Proposed changes

None is applied. Each needs the owner's decision.

| # | Where | Proposal | Evidence |
|---|---|---|---|
| C1 | Contract `tokens` | Add `focusRing.offset` (the prototype used `stroke.thick`), so the ring always sits on the ground its contrast is declared against | Ring against the fill 1.13–1.48 |
| C2 | Contract `platforms.web` | Name `:active` as well as `:hover` while disabled; record `data-role`; record that loading needs a script; record the offset | WebKit probe |
| C3 | Contract, loading | Say what the indicator is where the platform has none: its size (the icon's), its stroke, its motion (a token), and its form under Reduce Motion | Raw values in `web/button.css` |
| C4 | Conventions, states the system lacks | State that refusing presses is behavior: a script on the web; on GTK a mechanism still to be found, since a signal guard likely misses action-bound buttons (unverified); and check it on Apple | [`web-probe.txt`](../prototypes/evidence/web-probe.txt); `button.py` |
| C5 | Contract, P13 | Reconsider the fixed width without an icon: let it grow, or keep the width only when an icon slot exists. Decided 2026-11-17: it grows (decisions/0001, P13) | "Ad…" and "D…" at size m |
| C6 | Contract `accessibility`, conventions | Map the abstract `busy` per platform rather than to one state | ARIA's definition of `aria-busy`; no busy trait on UIKit |
| C7 | Conventions, token bindings | A rule for `icon.font` where icons are images: the icon's box is 1 em of the role, or an icon-size token per size | Both prototypes |
| C8 | Contract `size`, tokens | Describe the heights by input ("a fine pointer", "touch"), and give the web a runtime switch: a `web` platform context with both sets, or an input modifier | `tokens.css`, `(pointer: coarse)` |
| C9 | Tokens, chapter 08 | A target-size token per platform, decide the web's target, and add a rule that an extended hit area never crosses half the gap to a neighbour | [`web-hit-44.png`](../prototypes/evidence/web-hit-44.png) |
| C10 | Schema README, conventions | Define "no value" as "nothing drawn", and require a style on a system control to reset the platform's own look | The browser's and libadwaita's fills |
| C11 | Tokens or chapter 05 | Make the 98 % press scale a token, and say whether `motion.press` also times the release | Raw `scale(0.98)` in both |
| C12 | Contract `platforms.web`, `platforms.linux` | Add `keyboardIntents: [defaultAction]`, or decide it does not apply | Implicit submission; the default widget |
| C13 | Contract `platforms.linux` | Record the class map above, and that `.destructive-action` is restyled because libadwaita draws it as a tint | `_buttons.scss` |
| C14 | Conventions table | Correct the cells listed above | The table |
| C15 | Naming | One name for the platform: `linux`, `gnome` or GTK | The contract, decisions/0010, the table |

## Consequences

- The contract carries over in structure: options, slots, states, the bindings' three forms and the accessibility
  block all found a home on the web and, by the documentation, on GTK. What does not carry over is what SwiftUI or
  Apple supplies for free: a focus ring with its own offset, a progress indicator, icons that are glyphs of a font, a
  style that starts from nothing, a platform that implies its input.
- Five proposals (C1, C3, C5, C8, C10) change what a second component's contract will look like, so the owner should
  see them before #26 closes and before a second component starts.
- The GTK prototype must be run before phase 7 relies on any GTK finding marked unverified.
