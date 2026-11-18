# 0001. The Rule contract

Date: 2026-11-18. Status: draft for approval (#29, which calls it a divider). The owner answered the interview on
2026-11-18. This record keeps three things apart: what the owner answered, what the documents had already decided,
and what the agent proposes on top of both, which is still to confirm.

## Context

Both pilot screens draw straight rules (decisions/0006, `research_notes/pilot-inventory.md` 1.4:144–147, 5.3): on
`todo-app/lists-screen` the Mac bar's top rule and the edit bar's group divider, 1 × 22; on `todo-app/list-screen` the
block header's rule, the add-list rule and the pane capsule's divider, 1 × 16. The pilot draws them as filled
rectangles, not strokes. Some are horizontal, some vertical.

## What the owner answered

### The line

- Considered: (a) westron's own line, `stroke.thin` in `color.border.default`; (b) the system `Divider`, tinted;
  (c) the system `Divider` as it is.
- **Chosen: (a).** The system fixes its divider's thickness, so a tinted `Divider` would still not draw `stroke.thin`
  on every platform, and an untouched one would not take westron's color.

### The name

- Considered: (a) `rule` for the component and `Rule` for the Apple type; (b) `separator`; (c) the contract `divider`
  with an Apple type named otherwise.
- **Chosen: (a).** A type named `Divider` would collide with `SwiftUI.Divider` in every file that imports SwiftUI
  (decisions/0003, point 3), and one name on every platform needs no record of a difference.

### Scope

- **Chosen: straight rules only.** Nesting guides, dashed outlines and the line of a labeled area belong to the
  phase-4 components that draw them, and there is no guide color token now.

## Already decided by the documents

| What | Source |
|---|---|
| `color.border.default` draws separators; it is decoration in the standard themes and reaches 3:1 in high contrast (its `separator` contrast declaration, on canvas, surface and sunken) | design-language/02:25–27, 02:119; 04:58–60; `tokens/semantic/color.tokens.json` |
| `stroke.thin` draws rules and dividers; rules stay thin, since space and alignment already show the grouping | 04:51–55 |
| In high contrast lines gain contrast through their color, and their widths stay | 04:59–60 |
| Nesting guides and the labeled area line are a phase-4 component | decisions/0013:177 |

## Proposed, to confirm

| # | Proposal | Reason |
|---|---|---|
| P1 | Strategy `own-component`; on Apple a view, `Rule()` | The owner chose westron's own line over the system's; a line is a view, not a modifier of one |
| P2 | An option `axis`, `horizontal` or `vertical`, default `horizontal`; on Apple `Rule(axis: .vertical)` | The pilot needs both (above). An explicit axis holds on every platform: SwiftUI's `Divider` takes its axis from its stack, `GtkSeparator` and an `<hr>` do not. `horizontal` as the default because most rules are; the owner may prefer no default, as for a variant |
| P3 | The rule fills the length it is offered along its axis; the product sets that length and the space around it with its stack and spacing tokens | The pilot's 22 and 16 come from the bar, not from the rule; a rule with a length of its own would be an off-ladder value (design-language/06:23–25) |
| P4 | Accessibility: role `none`, hidden from assistive technology | A rule only repeats the grouping its neighbors already announce. The schema's role `none`, added with Surface, is the truthful value; `separator` was considered, but it would ask the platforms to announce the rule |
| P5 | No states and no slots | A rule does not react to input and holds no content |
| P6 | watchOS draws a rule as the other OSes do | Nothing in the documents differs there |
| P7 | Web, provisional: an `<hr>` with westron's CSS and `aria-hidden` for a horizontal rule, a vertical one an element decided with #40; GTK, provisional: a stock `GtkSeparator` in its orientation with westron's color and width through a style class, hidden from assistive technology | They are the native separators; their default look and announcement are replaced, as on Apple |

## What the tools need before an approved Rule is generated

Today an approved own component generates nothing, and the parity lint reports public API named as its component as
API no contract gives (conventions Q2).

- **The conventions:** settle Q2 for an own view: options as initializer parameters, `Rule(axis: .vertical)`, the
  shape the conventions' option (a) describes.
- **`AppleComponents`:** generate `RuleAxis` and the initializer's signature, or the conventions' chosen form, into
  `WestronUI/Generated/Rule+Contract.swift` for an approved own component; today `generates(_:)` requires
  `style-on-system-control`. `RuleAxis` is not a SwiftUI type name (`SwiftUITypes`), so it does not shadow `Axis`.
- **`APIParity`:** expect `public struct Rule: View` and its `init(axis: RuleAxis = .horizontal)` from the contract.
- **The snapshot matrix:** `AppleComponents.givesAPI` admits own components with API, and a hand-written
  `RuleMatrixCell` draws both axes in the four themes.
