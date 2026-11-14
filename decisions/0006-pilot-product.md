# 0006. Pilot product: todo-app

Date: 2026-11-14. Status: accepted.

## Context

westron components appear only for a real product need (decisions/0005). We need a product that will be the first
to adopt westron on Apple, and from which components will be extracted rather than invented.

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

## Where the look comes from

- The look of both screens is set by the canvas "Todo — дизайн", which the owner approved. Where the canvas and the spec
  disagree, the canvas is right about the look and the spec is right about behavior.
- The decisions about the look are already written in the pilot's code. The `DesignSystem` module holds the palette per theme, the accent #3653C9,
  eleven list colors, the SF Pro Rounded heading font, icons and animations. `DesignSystemComponents`
  holds the models and styles of the components on these screens.
- Phase 1 extracts the tokens from here, and phases 2–4 extract the components.

### What happens to the pilot's look modules

As westron gets tokens, styles and components, the pilot moves to them and deletes its own `DesignSystem`
and `DesignSystemComponents`: two implementations of the same look are not needed. The move happens in parts, as
westron covers what these modules contain: phase 1 tokens replace `DesignSystem`, and components from phases 2–4 replace
`DesignSystemComponents`.

## Consequences

- westron's minimum OS versions equal the pilot's (decisions/0008).
- westron's toolchain equals the pilot's: Xcode 27.1, Swift 6.4.
- The `consumers` field in a component contract refers to a pilot screen: `todo-app/lists-screen` or
  `todo-app/list-screen`.
- The phase 4 component list (issue #32) is drawn up from the inventory above.
- westron tokens and components must cover everything the pilot takes from its own modules; otherwise the pilot cannot
  delete them. The inventory of what these modules contain is input for phase 1 (issues #10, #11, #16) and for #32.
- The pilot's `DesignSystem` does not depend on SwiftUI and builds for WASM. If the pilot needs the same numbers on WASM,
  the Apple token generator (issue #14) must account for it. For example, the values can live in a module
  without SwiftUI, and the SwiftUI adapter in `WestronUI`. Decided in #14.
- Moving the pilot over is work in the todo-app repository; its tasks are opened there once a replacement is ready.
