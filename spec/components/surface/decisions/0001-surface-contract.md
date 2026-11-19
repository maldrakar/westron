# 0001. The Surface contract

Date: 2026-11-18. Status: approved on 2026-11-18 under the owner's delegation of 2026-11-18 (#29), pending the
owner's confirmation. The owner answered the interview on 2026-11-18 and delegated the approval: the coordinator, not
the owner, approved the contract as written and every one of its "Proposed" items, P1–P12, all of them pending the
owner's confirmation. The owner's own answers are the section "What the owner answered". Of the proposals, P5 (every
kind draws `radius.card`) and P12 (the high-contrast line replaces the hairline) are substantive choices the agent
made where the owner and the documents were silent. This record keeps three things apart: what the owner answered,
what the documents had already decided, and what the agent proposed on top of both.

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
- **Chosen: (a).** `outlined` draws a line for a card that sits on a fill. In high contrast a line is drawn whether
  or not `outlined` is set. The owner chose the flag; its color and width are the documents' (below), not part of
  the answer.

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
| A card needs no outline in the standard themes; a hairline, `stroke.hairline`, edges a card on a fill, in `color.border.default`, which draws separators | 04:51, 04:56–57, 04:58; `stroke.hairline`'s `$description`, "The edge of glass and of a card on a fill" |
| Corners are continuous on Apple, circular elsewhere | 04:41–44, decisions/0013:86 |
| westron never shadows what the system draws (a sheet, a popover, a menu, glass); a card never takes glass | 04:88–89, decisions/0013:104, design-language/09:39–42 |
| The nesting rule itself, `max(outer − inset, 4)` within the corner, the role's radius further in | 04:34–40, decisions/0013:82–85 |

**The high-contrast line is in the description only.** A case's `when` names options and states, and has no key for
the theme or the contrast, so no binding can say "in high contrast". The contract's description states it, and the
bindings carry only `outlined`'s hairline.

## Proposed, to confirm

| # | Proposal | Reason |
|---|---|---|
| P1 | Strategy `own-component` | No system control draws a card's ground on every platform |
| P2 | On Apple a view modifier on the content, `.surface(.raised)`, `.surface(.sunken, outlined: true)`, not a container type | It lays nothing out, so the product keeps its own stack and padding (the owner's padding answer). SwiftUI's `GroupBox` and `groupBoxStyle` are not available on watchOS, so a style on `GroupBox` could not hold on every Apple OS, and `GroupBox` brings a padding and a label of its own. The conventions' own-component row assumes a view type and leaves its options open (Q2), so this needs the conventions to record a modifier shape for an own component |
| P3 | The kind is the option `variant`, with no default | The conventions call the unlabeled first argument the variant; every use names its kind, as every Button names its variant |
| P4 | `raised` and `dragged` take `color.background.surface`, `sunken` takes `color.background.sunken` | `surface` and `sunken` are the documents' (above); that the lifted card keeps the surface ground of the card it lifts is the agent's reading |
| P5 | `dragged` takes `radius.card` too, and so does `sunken`: all three kinds draw `radius.card` | The lifted card keeps its card's corner; a well is "a panel" in radius.card's sense. The pilot's column has a larger corner than its cards (18 against 13 on the phone, inventory 4.2), which westron does not follow: one corner for the panels of a board. Kept by the agent under the owner's delegation of 2026-11-18, pending the owner's confirmation |
| P6 | `sunken` casts no shadow and gets no high-contrast line | Chapter 04 gives shadows only to what stands off its ground, and the high-contrast rule to "every raised surface"; a well is neither. A sunken surface on a fill still takes `outlined` |
| P7 | `outlined` binds `color.border.default` at `stroke.hairline`, for every kind | The documents give a card on a fill a hairline in the separators' color (above); P7 only applies it to each kind |
| P8 | Accessibility: role `none`, a schema value added with this contract | A surface adds no role, trait or label; assistive technology reads its content as if it were not there (below, "The schema") |
| P9 | One slot, `content` | What the product lays out on the surface |
| P10 | watchOS draws a surface as the other OSes do, always in the dark themes, where `raised` has no shadow | Nothing in the documents differs there; watchOS always shows the dark themes (design-language/02:107) |
| P11 | Web, provisional: a class with background, radius, shadow and, under `prefers-contrast: more`, a border; GTK: chapter 04's open question 4 (libadwaita's `.card` or westron's tokens), decided in phase 7 | As for Button's web entry; the GNOME question is open in the design language |
| P12 | In high contrast an outlined raised or dragged surface draws the high-contrast line, `stroke.thin`, instead of its hairline: the high-contrast rule wins | Both rules apply to such a surface, and one line is drawn, not two; the high-contrast rule is the stronger edge, which is what high contrast asks for. Decided by the agent under the owner's delegation of 2026-11-18, pending the owner's confirmation |

## The schema

- **`accessibility.role: none`.** The schema required a role and offered no value for a component that adds none.
  - Considered: (a) `none`, ARIA's name for an element that adds no role; (b) a role that is not true, such as
    `group`, which would make a card a group for screen readers; (c) making `role` optional, which would let a
    contract forget it.
  - **Proposed: (a).** `spec check` holds it: a component with role `none` has no intents, no keyboard intents (its own
    or a platform's), no announced states, and no required label. Rule takes it too.

## What the tools need before an approved Surface is generated

**Superseded by "How the tools settled it" below.** This is what the agent proposed before the implementation; the
generated signature it describes was not built: the modifier is hand-written and the lint holds it to the contract. Kept
as the record of the proposal.

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

**How the tools settled it (#29, with the implementation).** The contract names its shape in a structured field,
`platforms.apple.form: modifier`, added to the schema with this work: the generator and the lint read the shape from
it, not from the description. `tools/westron generate` writes `SurfaceVariant` into
`WestronUI/Generated/Surface+Contract.swift`; the modifier `surface(_:outlined:)` is hand-written, as Text's
`textRole(_:)` is, and the API parity lint holds its signature to the contract (`spec/conventions.md`, "Own
components"). The snapshot matrix is generated, three kinds by `outlined`.
