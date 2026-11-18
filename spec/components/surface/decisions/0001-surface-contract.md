# 0001. The Surface contract

Date: 2026-11-18. Status: draft for approval (#29). The owner answered the interview on 2026-11-18. This record keeps
three things apart: what the owner answered, what the documents had already decided, and what the agent proposes on
top of both, which is still to confirm.

## Context

The pilot draws three grounds that westron's tokens name (decisions/0006, `research_notes/pilot-inventory.md` 1.4 and
5.1): the open task card on `todo-app/list-screen`, raised off the canvas; the card a drag carries, on both screens
(the lifted task copy, the phone's drag card); and the board column on `todo-app/list-screen`, a well the cards sit
in. Each is a background, a corner and, for two of them, a shadow. No platform has a system control for it, so it is
westron's own component (decisions/0003, point 2).

## What the owner answered

### Kinds in version 1

- Considered: (a) `raised`, `dragged` and `sunken`; (b) `raised` only; (c) (a) with `muted`.
- **Chosen: (a).** `raised` is the open card, `dragged` the lifted card while dragging, `sunken` the board column as a
  well. `muted` was left out: the pilot's Done strip, its one use, is a capsule, which is a phase-4 component.

### Padding

- Considered: (a) none built in, the product pads with a token; (b) `space.200` built in, with a way to turn it off.
- **Chosen: (a).** A card pads its content with `space.card` (design-language/06:35–40).

### The line on a fill

- Considered: (a) a bool `outlined`, default `false`; (b) a line on every surface.
- **Chosen: (a).** `outlined` draws a line in `color.border.default` at `stroke.thin` for a card that sits on a fill.
  In high contrast the line is drawn whether or not `outlined` is set.

### Nesting (design-language/04, open question 1)

- Considered: (a) a surface draws its role's radius, and the concentric rule `max(outer − inset, 4)` applies only to
  a nested shape that sits within the outer shape's corner zone, applied by the product, the contract describing it and
  computing nothing; (b) every nested shape concentric; (c) nested pairs computed by the generator.
- **Chosen: (a).** This answers chapter 04's open question 1: within the corner zone the rule wins, further in the
  role's radius does, and no pair is stored.

## Already decided by the documents

| What | Source |
|---|---|
| `surface` is a card raised off the canvas, white in light, one step lighter than the canvas in dark; `sunken` is a well below the content | design-language/02:12–21, decisions/0012 |
| `radius.card`, 12, is a card's or a panel's radius | design-language/04:17–25, decisions/0013:71–80 |
| Shadows: `shadow.raised` for a raised card, none in dark; `shadow.dragged` for what a drag carries, three times as opaque in dark; everything else is flat | 04:62–80, decisions/0013:89–98 |
| In high contrast every raised surface is outlined in `color.border.default` at `stroke.thin`; this already answers chapter 04's open question 3 | decisions/0013:100–101, 04:84–87 |
| A card needs no outline in the standard themes; a hairline edges a card on a fill | 04:56–57 |
| Corners are continuous on Apple, circular elsewhere | 04:41–44, decisions/0013:86 |
| Never shadow what the system draws; glass is the system's, and a card never takes it | 04:88–89, decisions/0013:104, design-language/09:36–46 |
| The nesting rule itself, `max(outer − inset, 4)` within the corner, the role's radius further in | 04:34–40, decisions/0013:82–85 |

**One passage to reconcile at approval.** Chapter 04:51 and 04:56–57 give `stroke.hairline` to "a card on a fill",
while the owner's answer gives `outlined` `stroke.thin`, the width decisions/0013:100–101 gives the high-contrast
outline. The contract follows the owner. At approval, either 04:51 and 04:56–57 are revised to `stroke.thin` for a
card on a fill (one width for both lines of a surface), or the owner chooses `stroke.hairline` for `outlined` and the
contract follows.

## Proposed, to confirm

| # | Proposal | Reason |
|---|---|---|
| P1 | Strategy `own-component` | No system control draws a card's ground on every platform |
| P2 | On Apple a view modifier on the content, `.surface(.raised)`, `.surface(.sunken, outlined: true)`, not a container type | It lays nothing out, so the product keeps its own stack and padding (the owner's padding answer). SwiftUI's `GroupBox` and `groupBoxStyle` are not available on watchOS, so a style on `GroupBox` could not hold on every Apple OS, and `GroupBox` brings a padding and a label of its own. The conventions' own-component row assumes a view type and leaves its options open (Q2), so this needs the conventions to record a modifier shape for an own component |
| P3 | The kind is the option `variant`, with no default | The conventions call the unlabeled first argument the variant; every use names its kind, as every Button names its variant |
| P4 | `raised` and `dragged` take `color.background.surface`, `sunken` takes `color.background.sunken` | `surface` and `sunken` are the documents' (above); that the lifted card keeps the surface ground of the card it lifts is the agent's reading |
| P5 | `dragged` takes `radius.card` too, and so does `sunken` | The lifted card keeps its card's corner; a well is "a panel" in radius.card's sense. The pilot's column has a larger corner than its cards (18 against 13 on the phone, inventory 4.2), which westron does not follow: one corner for the panels of a board |
| P6 | `sunken` casts no shadow and gets no high-contrast line | Chapter 04 gives shadows only to what stands off its ground, and the high-contrast rule to "every raised surface"; a well is neither. A sunken surface on a fill still takes `outlined` |
| P7 | `outlined` binds `color.border.default` at `stroke.thin`, for every kind | The owner's answer; see the passage to reconcile above |
| P8 | Accessibility: role `none`, a schema value added with this contract | A surface adds no role, trait or label; assistive technology reads its content as if it were not there (below, "The schema") |
| P9 | One slot, `content` | What the product lays out on the surface |
| P10 | watchOS draws a surface as the other OSes do, always in the dark themes, where `raised` has no shadow | Nothing in the documents differs there; watchOS always shows the dark themes (design-language/02:107) |
| P11 | Web, provisional: a class with background, radius, shadow and, under `prefers-contrast: more`, a border; GTK: chapter 04's open question 4 (libadwaita's `.card` or westron's tokens), decided in phase 7 | As for Button's web entry; the GNOME question is open in the design language |

## The schema

- **`accessibility.role: none`.** The schema required a role and offered no value for a component that adds none.
  - Considered: (a) `none`, ARIA's name for an element that adds no role; (b) a role that is not true, such as
    `group`, which would make a card a group for screen readers; (c) making `role` optional, which would let a
    contract forget it.
  - **Proposed: (a).** `spec check` holds it: a component with role `none` has no intents, no keyboard intents (its own
    or a platform's), no announced states, and no required label. Rule takes it too.

## What the tools need before an approved Surface is generated

Today an approved own component generates nothing, and the parity lint reports any public API named as its component
as API no contract gives (conventions Q2). For `.surface(_:outlined:)`:

- **The conventions:** settle Q2 for an own component that lays nothing out: a modifier on `View` named after the
  component, its variant unlabeled first, other options labeled, as a style overload is.
- **`AppleComponents`:** generate `SurfaceVariant` (`raised`, `dragged`, `sunken`) and the signature
  `public func surface(_ variant: SurfaceVariant, outlined: Bool = false) -> some View` forwarding to a hand-written
  `SurfaceModifier`, into `WestronUI/Generated/Surface+Contract.swift`; today `generates(_:)` requires
  `style-on-system-control`.
- **`APIParity`:** expect that enum and that modifier for an approved own component of this shape (`Contract.hasAPI`
  and `noAPIReason` treat every own component as having no API).
- **The snapshot matrix:** `AppleComponents.givesAPI` admits only a style or an extension, so an own component gets no
  matrix; it would get one with a hand-written `SurfaceMatrixCell`, three kinds by `outlined`, in the four themes.
