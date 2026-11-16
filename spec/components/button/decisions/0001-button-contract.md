# 0001. The Button contract

Date: 2026-11-16. Status: draft for the owner's approval (#22). The owner's answers in the interview are decided; the
bindings and rules in the last section are proposals.

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
  equals its height, with a required accessible label. On Apple it is `.labelStyle(.iconOnly)`.

### Floating glass buttons

- Considered: a glass variant for the pilot's floating back and "…" buttons over the task list; the system's styles.
- **Chosen: not part of this contract.** Products use the system's `.glass` styles (chapter 09).

### Sizes and shape

- **Chosen: `s`, `m`, `l`, default `m`.** The heights are `size.control.s|m|l`: 24, 32 and 40 with a pointer, 32,
  44 and 52 on touch. The hit area is at least the platform's recommended target (chapter 08).
- **Chosen: `radius.control` everywhere,** icon-only included.

### States

- **Chosen: hover, focus, pressed, disabled, loading.**
- **Loading.** A progress indicator takes the icon's place; without an icon it sits before the label, and in
  icon-only it replaces the icon. The label stays and the width does not change. Presses are not accepted. It does
  not dim as disabled does. Assistive technology announces the label and "busy".
- **Disabled.** The whole button is drawn at `opacity.disabled`, with no disabled colors.
- **Hover and pressed.**
  - `primary`: `color.background.accent-hover` and `accent-pressed`.
  - `primary` with the destructive role: `color.status.danger.fill-hover` and `fill-pressed`.
  - `secondary` and `tertiary`: `color.background.hover` and `color.background.pressed`.

### Platforms

- watchOS offers only size `m`. The Swift enum keeps every case, and the style falls back to `m`.
- Hover exists only with a pointer: never on iPhone or watchOS.
- The focus ring is the system's on Apple and GTK; on the web it is an outline in `color.border.focus`.
- On macOS, Return and Escape trigger the default and cancel actions.

### Swift API conventions

The owner settled four open questions of `spec/conventions.md`, which now holds them as rules:

1. A call without `size:` takes its size from `@Environment(\.controlSize)`: `mini` and `small` → `s`, `regular` →
   `m`, `large` and `extraLarge` → `l`. An explicit `size:` wins.
2. One shared state modifier, `.loading(_:)`, not `.buttonLoading(_:)`.
3. A value a platform does not support keeps its enum case and falls back to the value the `platforms` block names.
4. The variant is always written: `.buttonStyle(.secondary)`. There is no call without a variant.

## Proposed, for the owner to confirm

The decisions above leave these bindings and rules open. Each is a proposal, with its reason and its source.

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
| P13 | Loading without an icon keeps the resting width: the indicator, the gap and the label share it | The owner's "the width does not change" with an indicator added before the label leaves no other reading; a long label can then truncate. The alternative is to let the width grow in this one case | the owner's loading decision |
| P14 | On Apple, `role` is SwiftUI's `ButtonRole`: no enum is generated for it, and `.cancel` or no role draws as `default` | A generated `ButtonRole` would collide with SwiftUI's, and the system already carries the role to VoiceOver and dialogs | decisions/0003, point 3; spec/conventions.md |
| P15 | Hover on the web only under `(hover: hover)` | The owner's "hover only with a pointer", in CSS terms | the owner's platforms decision |

## Consequences

- The contract schema allows an enum option without a default, which every use must name; the variant is the first.
- Some pairs this contract draws have no contrast declaration yet, so the contrast check does not prove them:
  `color.text.accent` on `color.background.pressed`, and `color.status.danger.text` on `color.background.hover` and
  `pressed`. They are declared in `tokens/` before the implementation (#23).
- The schema has no machine-readable way to say that an option is the system's own API, as `role` is on Apple. The
  `platforms` block says it in prose until the generator (#20) needs a field.
