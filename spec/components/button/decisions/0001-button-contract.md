# 0001. The Button contract

Date: 2026-11-16. Status: accepted. The owner answered the interview and, on 2026-11-16, approved the contract with
every binding and rule proposed on top of the answers (#22). The look (shape, secondary's outline, padding, gap, the
font at l, the iOS heights) was replaced on 2026-11-20: decisions/0003-the-look-of-2026-11-20.md.

## Context

Both pilot screens need a button (decisions/0006):

- `todo-app/lists-screen`: the bottom bar's "…" and "+", "+ Add list", confirm and cancel in the "Move to…" sheet
  and in the delete confirmation;
- `todo-app/list-screen`: "+ Add task".

Every platform has a system button, so westron gives it a style and adds no type of its own (decisions/0003). Button
is the end-to-end slice of phase 2: the contract schema (#18), the conventions (#19), the Swift API generator (#20)
and the parity lint (#21) are proved on it before a second component starts. The tokens it binds came with #56.

## Decisions

### The system control

- Considered: a style on the platform's button; an own component.
- **Chosen: a style on `SwiftUI.Button`, `GtkButton` and a native `<button>`.** Android is planned.

### Variants

- Considered: two variants (filled and outlined); three, with a quiet one for actions inside content.
- **Chosen: `primary`, `secondary`, `tertiary`.**
  - `primary` is filled with the accent, the one main action on a screen.
  - `secondary` is outlined in `color.border.strong`, its label in `color.text.primary`.
  - `tertiary` has no background, its label in `color.text.accent`.
- The variant has no default: it is always written, `.buttonStyle(.secondary)` (spec/conventions.md).

### A destructive action

- Considered: a `destructive` variant; a role that recolors any variant.
- **Chosen: a separate option `role: default | destructive`** that recolors any variant in the danger colors. On
  Apple it is the system's `Button(role: .destructive)`, and the style reads the role, so VoiceOver and the system's
  confirmation dialogs know it too.

### Slots and icon-only

- **Chosen: `label` and a leading `icon`.** Icon-only is the same button, not another component: a square whose side
  equals its height, with a required accessible label. On Apple it is an argument of the style,
  `.buttonStyle(.primary, iconOnly: true)`; the interview first named `.labelStyle(.iconOnly)`, which the review
  showed cannot work (below).
- **Icon-only on Apple** (decided 2026-11-16, after review).
  - A probe on macOS showed that the system's `.labelStyle(.iconOnly)` cannot drive westron's style. The label style
    is an environment value: the label style westron's `ButtonStyle` applies to `configuration.label` inside
    `makeBody` overrides the product's outer one, and a `ButtonStyle` has no public way to read the outer label style,
    so it could not know to draw the square either.
  - Considered: a labeled argument of the style overload; a westron environment modifier `.iconOnly()`.
  - **Chosen: the argument, `.buttonStyle(.primary, size: .m, iconOnly: true)`.** The style hides the title, keeps
    it as the accessible label and draws the square. The modifier was rejected: it would make a bool option look
    like a state, and it is easy to confuse with the system's `.labelStyle(.iconOnly)`.
  - This also settles how every bool option that is not a state looks in Swift: a labeled `Bool` argument of the style
    overload, named as in the contract, with the contract's default (`spec/conventions.md`).

### Floating glass buttons

- Considered: a glass variant for the pilot's floating back and "…" buttons over the task list; the system's styles.
- **Chosen: not part of this contract.** Products use the system's `.glass` styles (chapter 09).

### Sizes and shape

- **Chosen: `s`, `m`, `l`, default `m`.** The heights are `size.control.s|m|l`: 24, 32 and 40 with a pointer, 32,
  44 and 52 on touch. The hit area is at least the platform's recommended target (chapter 08), except on macOS and,
  next to another control, on iOS (below).
- **The hit area on macOS** (decided 2026-11-18, after the Apple implementation, #75).
  - Size s is drawn 24 pt tall, below macOS's recommended 28. On macOS a click outside the system button's frame
    misses, whatever the content shape, so reaching the target means growing the frame (measured in the catalog's
    `ButtonBehaviorTests`, #23).
  - Considered: growing the frame by 2 pt on each side inside the system button and taking it back with a negative
    padding outside, so the drawn and laid out size stay; growing the layout frame to 28 pt; the drawn 24 pt as the
    hit area.
  - **Chosen: on macOS the hit area is the drawn button; size s takes clicks in its 24 pt.** It is a recorded platform
    difference, in the contract's `platforms.apple.macos`, not a gap. The whole drawn button takes clicks, the empty
    inside of `secondary` and `tertiary` included: until the style gave the button its drawn shape to hit-test,
    macOS took clicks on those two only where they paint, the label and the border.
  - Why: the grown frame overlaps a neighbor closer than 4 pt, and the later sibling wins there, inside the
    neighbor's drawn area: with no spacing, a click 1 pt inside the first button ran the second (measured with real
    clicks in the review of #69); the style cannot see its neighbors. A layout frame of 28 pt breaks the alignment
    that size s exists for, in toolbars and table rows. A pointer is precise, and the system's own small controls
    take clicks in their frame only.
- **The hit area on iOS** (decided 2026-11-21, after the behaviour tests failed on CI's iOS 27.0 simulator, #102).
  - Size s is drawn 28 pt tall, below the 44 pt target; size m, 36. On iOS westron does not grow the hit area and
    relies on the system's touch tolerance (`ButtonVariantStyle.swift`). The catalog's `ButtonBehaviorTests` tap 8 pt
    below size s "Add", the target's edge, passed on iOS 26.3 and failed every time on iOS 27.0 (run 44888969666).
  - Measured with taps at 1 pt steps around the buttons of that catalog page, same layout and frames on both
    versions: with no other control near, the tolerance reaches 15 to 19 pt past a button of size s or m on iOS 26.3
    and 27.0 alike, past the target. Next to another control the system shares the gap between the two: with the
    page's Toggle row 12 pt below "Add", the reach below it was 8 pt on 26.3 (8.33 missed) and 7 on 27.0; a button
    20 pt above it left 10, one 16 pt away 7. The test's tap sat on the boundary with the Toggle row, which moved by
    under a point on 27.0: it measured the arbitration with a neighbor, not the contract.
  - Considered: growing the hit area in the style to the target on iOS; keeping the system's tolerance and fixing
    the catalog page and the test.
  - **Chosen: the system's tolerance stays the hit area on iOS; westron still does not grow it.** The catalog page
    keeps other controls clear of the test's tap ("Add" is the last button, the Toggle row above the buttons), and
    the test asserts that no other control is within 16 pt of the tap. The contract's `platforms.apple.ios` records
    the iOS 27.0 measurement and that another control closer than about 16 pt takes part of the tolerance, so a size s
    button reaches the full target only where no control is that close.
  - Why: the tolerance did not shrink on iOS 27, and it already reaches past the target where nothing else is near. A
    hit area grown in the style overlaps a neighbor and gives every tap in the overlap to the later sibling, even one
    closer to the first (#23), where the system gives it to the closer one.
- **Chosen: `radius.control` everywhere,** icon-only included.
- **Narrower than the longest word** (decided 2026-11-17, after the Apple implementation, #23).
  - Considered, side by side in the catalog at sizes m and l, at the default text size and at accessibility3: a
    minimum width inside the style, the width of the label's longest word, so the label wraps only between words and
    the button grows past its container; one line with an ellipsis; the word breaking inside, as the platforms do
    when nothing stops them.
  - **Chosen: a usage rule for products, not a mechanism in the style.** The button is not meant for a width smaller
    than its label's longest word; the label wraps only between words; the product provides the room, by stacking
    buttons, giving the button the full width, a shorter label, or icon-only.
  - Why the rule sits with the product: the style cannot see the label's words (on Apple the label is an opaque view,
    and its width alone does not show where a word breaks); an ellipsis contradicts "the button grows with its text"
    (P11) and loses the label at large text sizes, down to a clipped first letter or the icon alone; and a button that
    enforces its own minimum width runs off the screen at large text sizes.
  - If a product breaks the rule, the label breaks inside a word ("Delet/e"). That is unsupported, not a behavior of
    this contract, and not a bug to fix in the style.

### States

- **Chosen: hover, focus, pressed, disabled, loading.**
- **Loading.** A progress indicator takes the icon's place, and in icon-only it replaces the icon, so the width does
  not change. Without an icon it goes before the label, and the button widens by the indicator and the gap (P13,
  below). The label stays. Presses are not accepted. It does not dim as disabled does. Assistive technology
  announces the label and "busy".
- **Loading without an icon** (decided 2026-11-17, after the Apple implementation, #23).
  - Considered, side by side in the catalog: the indicator, the gap and the label share the resting width, the
    label truncating (P13 as first confirmed); the button widens by the indicator and the gap; the indicator's slot
    kept at rest too; the indicator replaces the label.
  - **Chosen: the button widens by the indicator and the gap; the label is neither truncated nor hidden.** The
    shared width cut short labels to almost nothing ("Save cha…", "Save" to the indicator alone; "Ad…" and "D…" on
    the web prototype, decisions/0002), and the accessibility audit reported the truncated label as clipped text.
    The width still holds wherever the label has an icon.
- **Disabled.** The whole button is drawn at `opacity.disabled`, with no disabled colors.
- **Hover and pressed.**
  - `primary`: `color.background.accent-hover` and `accent-pressed`.
  - `primary` with the destructive role: `color.status.danger.fill-hover` and `fill-pressed`.
  - `secondary` and `tertiary`: `color.background.hover` and `color.background.pressed`.
- **States that exclude each other** (decided 2026-11-16, after review).
  - Considered: disabled and loading enter neither hover nor pressed; hover stays and pressed does not; each
    platform does what its control does.
  - **Chosen: neither hover nor pressed.** While the button is disabled or loading, its fill stays as at rest and a
    press does not scale it, on every platform. A loading button that tinted under the pointer or the finger would
    promise an action it does not take. The contract binds it: the first cases of `container.background` give the
    resting fill to `state: [disabled, loading]`, ahead of the hover and pressed cases, since the first match wins.

### Platforms

- watchOS offers only size `m`. The Swift enum keeps every case, and the style falls back to `m`.
- Hover exists only with a pointer: never on iPhone or watchOS.
- The focus ring is the system's on Apple and GTK; on the web it is an outline in `color.border.focus`.
- On macOS, Return and Escape trigger the default and cancel actions.
- On macOS the hit area is the drawn button, so size s takes clicks in its 24 pt (above).
- **Known issue on Apple (#23): the `trash` glyph and the accessibility audit.** With `trash` as the destructive
  samples' icon, the Dynamic Type accessibility audit of the catalog's `button-destructive` page times out ("Audit
  failed to complete in time") on the screenful of size m and l samples at accessibility5, on the code before and
  after the icon-only changes; with any other glyph the page passes. The cause is not found. A product's icon-only
  trash button may hit the same in its own audit. The catalog's destructive samples use `xmarkCircleFill`, which the
  owner chose on 2026-11-17.

### Swift API conventions

The owner settled four open questions of `spec/conventions.md` in the interview and a fifth in the review; the
document now holds them as rules:

1. A call without `size:` takes its size from `@Environment(\.controlSize)`: `mini` and `small` → `s`, `regular` →
   `m`, `large` and `extraLarge` → `l`. An explicit `size:` wins.
2. One shared state modifier, `.loading(_:)`, not `.buttonLoading(_:)`.
3. A value a platform does not support keeps its enum case and falls back to the value the `platforms` block names.
4. The variant is always written: `.buttonStyle(.secondary)`. There is no call without a variant.
5. A bool option that is not a state is a labeled `Bool` argument of the style overload, with the contract's
   default: `iconOnly: true` (above).

## Proposed and confirmed

The answers above left these bindings and rules open. The agent proposed each one, with its reason and its source,
and the owner confirmed P1–P15 as proposed on 2026-11-16, when approving the contract.

| # | Proposal | Reason | Source |
|---|---|---|---|
| P1 | `container.paddingHorizontal`: `s` `space.100`, `m` `space.150`, `l` `space.200` | A step per size, never less than the 8 pt corner, so the corner and the padding inside it stay in proportion | chapter 04 (corners on the space ladder), chapter 06 |
| P2 | `container.gap` between the icon and the label: `s` `space.50`, `m` `space.75`, `l` `space.100` | The small steps of the ladder serve the insets of small components; the gap grows with the size | chapter 06 |
| P3 | `label.font`: `s` `typography.footnote.strong`, `m` and `l` `typography.subheadline.strong` | Chapter 03 names `subheadline.strong` for a button's label and `footnote.strong` for a small button. The alternative for `l` is `body.strong`, as Apple's large buttons use; chapter 03 does not name it for buttons | chapter 03 |
| P4 | `icon.font` equals `label.font` by size | An icon next to text takes that text's role; without text, its control's text role. So the glyph scales with Dynamic Type and grows with the size | chapter 07 |
| P5 | `icon.color` and `progress.color` equal `label.color` | An icon takes the color of the text it goes with; the indicator stands in the icon's place | chapter 07 |
| P6 | `container.borderWidth`: `stroke.thin` on `secondary` | Rules and outlines that only mark an edge are thin; `stroke.thick` is for what must be found at once, such as focus | chapter 04 |
| P7 | Destructive `secondary`: border `color.status.danger.border`, label `color.status.danger.text`; destructive `tertiary`: label `color.status.danger.text` | The danger roles for an outline and for words; the owner chose that the role recolors every variant | chapter 02 |
| P8 | Destructive `secondary` and `tertiary` keep the neutral hover and pressed fills, `color.background.hover` and `pressed` | The owner's rule for neutral variants does not depend on the role; a red-tinted fill would need new tokens | the owner's states decision |
| P9 | `container.pressMotion`: `motion.press`, with the press scale of 98 %; `container.hoverMotion`: `motion.fade` | `press` is a control answering a press, its tint and its scale; `fade` is a hover tint. Reduce Motion drops the scale and keeps the tint | chapter 05 |
| P10 | `focusRing.color` `color.border.focus` and `focusRing.width` `stroke.thick`, on the web only | The owner chose `border.focus` for the web; chapter 04 gives the thick width to focus rings. Apple and GTK draw their own | chapter 04, chapter 08 |
| P11 | The height is a minimum: the button grows with its text, and icon-only stays square at that height | A fixed height clips text at large text sizes | chapter 06, chapter 08 |
| P12 | watchOS enters focus as the system decides; only hover is dropped there | The owner named hover only; a watch button can take focus from the Digital Crown, and the system draws it | the owner's platforms decision, chapter 08 |
| P13 | Loading without an icon widens the button by the indicator and the gap; the label is not truncated or hidden. Changed by the owner on 2026-11-17 (above): first confirmed as keeping the resting width, with the indicator, the gap and the label sharing it | The shared width truncated short labels ("Save cha…"), which the accessibility audit reported as clipped text; with an icon, the indicator takes its place and the width holds | the owner's loading decision of 2026-11-17 |
| P14 | On Apple, `role` is SwiftUI's `ButtonRole`: no enum is generated for it, and `.cancel` or no role draws as `default` | A generated `ButtonRole` would collide with SwiftUI's, and the system already carries the role to VoiceOver and dialogs | decisions/0003, point 3; spec/conventions.md |
| P15 | Hover on the web only under `(hover: hover)` | The owner's "hover only with a pointer", in CSS terms | the owner's platforms decision |

## Consequences

- The contract schema allows an enum option without a default, which every use must name; the variant is the first.
- Three pairs this contract draws had no contrast declaration: `color.text.accent` on `color.background.pressed`,
  and `color.status.danger.text` on `color.background.hover` and `pressed`. They are declared in `tokens/` now, and
  `tools/westron tokens contrast` proves them in every theme: 260 pairs, none failed. The margins are thin on the
  pressed fill, 4.52 for the accent text in light against a target of 4.5.
- The schema has no machine-readable way to say that an option is the system's own API, as `role` is on Apple. The
  `platforms` block says it in prose until the generator (#20) needs a field.
