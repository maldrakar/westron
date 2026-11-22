# 0006. Pilot product: todo-app

Date: 2026-11-14. Status: accepted. Revised 2026-11-15: westron's look is its own, and the pilot adopts it. Revised
2026-11-22: the pilot keeps its compositions, built from westron's core (decisions/0014).

## Context

westron components appear only for a real product need (decisions/0005). We need a product that will be the first
to adopt westron on Apple, and whose screens say which components westron needs, so that none is invented without a
consumer.

## Decision

The pilot is [todo-app](https://github.com/maldrakar/todo-app): a task app in the spirit of Things 3 with a shared core
in Swift and a native UI on each platform. The Apple app is written in SwiftUI and supports
iOS 17, macOS 14 and watchOS 10.

westron first serves two screens of the pilot.

### Lists screen

The list of views the user keeps. On iPhone it is a separate screen and the root of the stack;
on Mac and iPad, a sidebar. Spec: `docs/specs/lists-screen.md` in todo-app.

What it draws:
- a list row: a tile with a color and an icon, the name, the count of open tasks, a chevron that collapses the branch;
- guide lines for nesting levels; an area as a line with its name across the tree;
- the bottom bar: a "…" button, a search capsule, a "+" button with a menu;
- context menus: rename, new list, move, delete;
- a name field right in the row;
- edit mode: drag handles, an insertion point indicator;
- a "Move to…" sheet with the tree of lists; delete confirmation.

### List screen

The tasks of one view: the screen that opens when you tap a list. On Mac and iPad it sits in the pane
next to the sidebar. Spec: `docs/specs/list-screen.md` in todo-app.

What it draws:
- floating glass "back" and "…" buttons;
- the screen header: tile, name, day;
- a tag bar with filter chips;
- blocks: a header with a chevron, a title and a date; "+ Add task" at the end of the block;
- a task row: a completion circle, the title, a metadata line, swipe to delete;
- a task card: fields, subtasks, an add row, day, deadline and tag pills;
- columns; a "Done today" strip; "+ Add list"; a round "+" button;
- an empty state; a "Show as" menu.

## What the pilot gives westron and what it takes

- **The pilot gives the need.** Its screens decide which components come first and what they must do. Its specs in
  todo-app are right about behavior, and the pilot's own motions, such as a done row lingering before it leaves,
  stay the product's behavior (decisions/0013).
- **westron gives the look.** Color, type, icons, space, shape, shadows and motion are westron's own
  (decisions/0011, 0012, 0013). The pilot adopts them as their first consumer.
- **Icon names carry over.** The pilot stores icons by name, and its 32 names stay as they are in westron's registry
  (decisions/0011).

### What happens to the pilot's look modules

The pilot keeps its own look in two modules: `DesignSystem` holds its palette, fonts, icons and animations, and
`DesignSystemComponents` holds the models and styles of the components on these screens. As westron gets tokens,
styles and components, the pilot moves to them. The move happens in parts, as westron covers what these modules
contain: phase 1 tokens replace `DesignSystem`, which the pilot deletes, and components from phases 2–4 replace the
values and styles of `DesignSystemComponents`, while the pilot's compositions stay, built from westron's components
(revision of 2026-11-22). With each part, the pilot's screens take westron's look.

## Revision of 2026-11-15

The first version of this decision took westron's look from the pilot: the canvas "Todo — дизайн" set the look of
both screens, and phase 1 extracted the tokens from the pilot's `DesignSystem` module. On 2026-11-15 the owner
decided that westron's look is designed for many products, everyday and technical, and that nothing is kept from
the pilot's look. The owner chose it on direction specimens: direction B, the cobalt palette, Onest for headings.
The pilot adopts this look as westron's first consumer.

## Revision of 2026-11-22

The first version had components from phases 2–4 replace `DesignSystemComponents` whole, and drew the phase 4 list
from the inventory above. On 2026-11-22 the owner rejected porting the pilot's components one to one: westron holds a
small core, and the pilot builds its more custom parts from it by composition (decisions/0014, which gives the phase 4
list and maps every family of the module).

- The pilot deletes the values and styles of `DesignSystemComponents`, its numbers, colors, fonts and motions, as
  westron's tokens and components cover them.
- It keeps its compositions, the task row, the card, the headers, the bars and the rest that decisions/0014 lists,
  built from westron's components.

## Consequences

- westron's minimum OS versions equal the pilot's (decisions/0008).
- westron's toolchain equals the pilot's: Xcode 27.1, Swift 6.4.
- The `consumers` field in a component contract refers to a pilot screen: `todo-app/lists-screen` or
  `todo-app/list-screen`.
- The phase 4 component list (issue #32) is drawn up from the inventory above: decisions/0014 (revision of
  2026-11-22).
- westron tokens and components must cover every role the pilot takes from its own modules, such as a list color, a
  text role or an icon; otherwise the pilot cannot delete them. They cover the roles, not the pilot's values. The
  inventory of these modules, `research_notes/pilot-inventory.md`, is a checklist of roles for phase 1 and for #32.
- The pilot stores eleven list color names. Two of them, rose and stone, are not among westron's twelve
  (decisions/0012), so the pilot maps them when it moves.
- The pilot's `DesignSystem` does not depend on SwiftUI and builds for WASM. Decided in #14: `WestronTokens` holds
  the values with no SwiftUI and builds for WebAssembly and Linux, so the pilot's shared code can use it
  (decisions/0010).
- Moving the pilot over is work in the todo-app repository; its tasks are opened there once a replacement is ready.
