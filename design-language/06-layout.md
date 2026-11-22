# 06. Layout

Date: 2026-11-15. Status: draft for the owner's approval (#8). It follows
[decisions/0013](../decisions/0013-typography-space-shape-motion.md), which the owner accepted by choosing direction B.

Layout is space, size and how a screen adapts. westron keeps one short ladder of space on an 8 px base and spends it
generously, in direction B's rhythm. Density is a mode that changes components and leaves the ladder alone. Size
follows the platform and the person's text size. This chapter says why. The values are in decisions/0013 and
`tokens/semantic/space.tokens.json`; the modes are in [decisions/0010](../decisions/0010-token-structure-and-modes.md).

## The space ladder

- **A 4 px grid with an 8 px base.** `space.25` to `space.800`. A name is a step, and `100` is the base unit:
  `space.200` is twice the base, `space.50` half of it. Carbon, Atlassian and Spectrum build their spacing on this
  grid, and Atlassian and Carbon name their steps the same way (decisions/0013).
- **Names are steps.** `space.300` reads as twice `space.150`, so a contract shows its rhythm in its names. The same
  names serve every platform, whatever its unit: points on Apple, CSS pixels on the web, dp on Android.
- **The ladder is short on purpose.** Thirteen steps keep neighboring components in one rhythm and give an agent few
  enough choices to pick the right one. The small steps serve the insets of small components. The large ones serve the
  gaps between sections and pages.
- **The ladder never changes.** Density never redefines what a step is worth. A dense view picks other steps and
  smaller components (below).
- **Off-ladder values belong to a component.** An odd gap used by one component, or a position derived from other
  geometry, lives in that component's contract, in a component tier when one is needed (decisions/0010). Examples are
  a body that starts after a check's hit area and an indent per level of a tree. Neither becomes a new step.
- **Corners use the same ladder** (chapter 04), so a corner and the padding inside it stay in proportion.

## Direction B's rhythm

B spends space generously, on the 8 px base. Each place has a role, and the role aliases a step of the ladder
(decisions/0013, revision of 2026-11-18):

| Where | Role | Step |
|---|---|---|
| A card's padding | `space.card` | `space.200` |
| The gap inside a group | `space.within-group` | `space.150` |
| The gap between groups | `space.between-groups` | `space.300` |
| The page margin on a narrow window and on a wide one | `space.page.narrow`, `space.page.wide` | `space.250`, `space.400` |

- **Use the role, not its step.** A contract or a screen that pads a card takes `space.card`, not `space.200`. The
  role says why the space is there, and the compact density can point it at another step without touching the code
  that uses it. A step stays the right choice for space that is not one of these places.
- **Narrow and wide follow the width class.** On Apple the horizontal size class decides: compact takes
  `space.page.narrow`, regular takes `space.page.wide`, and a Mac is always wide. On the web, GNOME and Android a
  breakpoint decides, set in each platform's phase. westron has no helper for it yet; a product reads the size class
  itself.
- **The margins are for layout the product builds.** A `ScrollView`, a stack or a grid that the product lays out
  takes westron's page margin. The system's `List`, `Form`, toolbars and navigation bars keep their own insets, as a
  system control keeps its own look (decisions/0003), so a westron screen next to a system one does not jump. One
  exception: a ListRow in a `List` draws its own padding and highlight, so the product sets the List's row insets to
  zero for it (spec/components/list-row, decisions/0001, Q2).

- **Groups show through space.** The gap between groups is twice the gap inside one, so a person sees the grouping
  before any line. Separators stay quiet (chapter 02), and a screen needs few of them (chapter 00, principle 4).
- **The rhythm suits calm screens, and density covers dense ones.** B's comfortable rhythm suits a list or a form. A
  table or a log that must show more takes the compact density, which keeps the page margins and the gaps between
  sections. Without it, B would not hold up in a dense table (`research_notes/space-shape-motion.md`, 5.3).
- **Controls and rows have heights of their own.** On the web, B's controls are 32 px, its list rows 44 and its table
  rows 36 (decisions/0013). On touch platforms, rows are at least the platform's recommended hit target: 44 pt on
  iOS, 48 dp on Android. A row's height is a minimum, so it grows with its text.
- **Controls come in three heights, set by the input.** `size.control.s`, `m` and `l` are 24, 32 and 40 on macOS,
  where a pointer drives; 28, 36 and 50 on iOS and iPadOS, beside the system's own 28, 34 and 50; and 32, 44 and 52 on
  watchOS, pending the owner's look at the watch (decisions/0013, revision of 2026-11-20). A control's hit area is not
  its height: it is at least `size.target.minimum`, 44 pt on touch and 28 on macOS (chapter 08). The tokens for row
  heights arrive with the dense components (#33).

## Density is a mode

- **`density` is a modifier with `regular` and `compact`.** `regular` is direction B's comfortable density, the default
  for every product. The mode is resolved at runtime through the environment, like the theme (decisions/0010).
- **Compact changes components.** Controls and rows get one 8 px step smaller, cell insets halve, and gaps inside a
  group move one step down (decisions/0013). The gap moves by pointing `space.within-group` at another step.
- **Compact keeps the frame.** The ladder, text sizes, page margins and the gaps between sections stay the same in both
  densities. No surveyed system rescales its ladder, and a dense view should keep its margins. A dense table picks a
  smaller text role itself (chapter 03).
- **Touch rows keep their target.** Rows on touch platforms stay at the recommended hit target in both densities.
  Whether a compact control may go below it, down to the platform's floor, is an open question of chapter 08.
- **A mode keeps components in agreement.** A table, a log or a long list is dense as a whole, and every component in
  it must agree. One environment value keeps them agreeing. A `compact` option on each component would let them drift.
  SwiftUI cascades `controlSize` the same way.
- **The platform supplies, the density picks.** A control's height differs by platform and by density. The platform's
  token file supplies both values, and the density context picks one, so no token is set by two modifiers
  (decisions/0010, 0013). Today the platform files supply only the regular heights, as `size.control.*` itself.
- **`compact` is empty until it has a consumer.** It gets its values with the dense components (#33); until then both
  densities take the regular heights. Then the platform files add the compact column and each density points
  `size.control.*` at its own, so the names a contract binds stay the same.

## Size follows the platform

- **Values are keyed by platform.** A value that differs between iOS, macOS and watchOS lives in the `platform`
  modifier, resolved at build time, and only where it differs (decisions/0010). The input decides the size: touch
  needs larger targets than a pointer, whatever the width. The control heights are the first tokens that differ by
  platform (#56); the row heights follow with #33.
- **Width decides structure.** Whether a screen shows a sidebar, a stack or columns follows the width class, never the
  device (chapter 09). So an iPad shows a wide layout with touch-sized controls.
- **Hit targets follow chapter 08.** The platform's recommended size is the target, and the hit area may be larger
  than what is drawn.

## Text size and containers

- **Text scales, and containers make room.** Every role follows the person's text size (chapter 03), and so does the
  spacing that belongs to text: on Apple through `@ScaledMetric`, with a token as its base value. A row, a bar or a
  header grows with its text.
- **A minimum height, never a fixed one, wherever text sits.** A fixed height clips text at large sizes. SwiftUI's
  lists work the same way: `defaultMinListRowHeight` is a minimum. Some of the pilot's bars and headers have fixed
  heights today; the westron components that replace them have minimum heights.
- **Screen-level measures belong to the product or the component**: a sidebar's width, the maximum width of readable
  content, a board column's width. They are not steps of the space ladder.

## Open questions

1. **The values of compact (#33).** Each platform's control heights in the compact density, and its row heights in
   both.
2. **System controls in compact.** On Apple, should compact also set `controlSize(.small)` on its subtree, so that
   system controls get denser together with westron's own?
