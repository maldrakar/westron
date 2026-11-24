<!-- Generated from design-language/00-principles.md by `tools/westron generate`. Do not edit: change the source and
generate again (decisions/0016). -->
<!-- The design language is distributed under CC BY 4.0, https://creativecommons.org/licenses/by/4.0/ (westron's
design-language/LICENSE). Links to the rest of westron's repository are left as their text. -->

# 00. Principles

Date: 2026-11-15. Status: draft for the owner's approval (#8).

These principles settle the cases the other chapters do not cover. Each one says what it asks, why, and what it means
for a designer and for an agent writing code. Where a machine can check a principle, the principle says how.

westron serves several products on several platforms: everyday ones, such as a task list, and technical ones, such as
a table of deployments, a log or a dashboard. Its look is designed for all of them and is not taken from any one
product. The pilot, todo-app, is its first consumer and takes this look
(decisions/0006).

## 1. The brand lives in the content layer, not in recolored system controls

People recognize westron by what a screen shows: its Onest headings, its cool ground and soft cards, its cobalt accent,
its list colors, its domain icons, its words and its dense data views. They never recognize it by a repainted
navigation bar, toggle or menu.

**Why.** Every platform owner draws this line. The HIG asks apps to apply the accent color "judiciously", to minimize
it on controls, and to move brand color "into the content layer, where it scrolls beneath Liquid Glass controls"
([HIG Branding](https://developer.apple.com/design/human-interface-guidelines/branding)). GNOME asks apps to keep
custom styling "to a minimum" ([GNOME HIG](https://developer.gnome.org/hig/guidelines/ui-styling.html)). Android
recommends Material and shows how to extend its theme. A recolored control fights the platform, breaks with each OS
release and loses the accessibility the system gives for free. So westron's look is in its content: the heading face
(decisions/0011), the palette (decisions/0012),
and the shapes, shadows and motions (decisions/0013). Bars,
sheets, menus and glass stay the system's.

**In practice.**
- Designer: to make a screen more recognizable, change the content: a heading, a card, a color, an icon, the words,
  the density. Leave bars, sheets, menus and pickers as the platform draws them.
- Agent: never tint or restyle navigation, toolbars, tab bars, sidebars, sheets, menus or pickers beyond the accent
  the platform already takes. Brand values go into content-layer components and into the styles of controls.
- Check: replace every westron control style with the system default. The screen should still be recognizable. Hide
  the content instead, and it should not be.

## 2. The system owns structure and behavior; westron styles the system's controls

Navigation, modality, menus, pickers, text input, focus, scrolling and window chrome belong to the platform. Where a
system control exists, westron gives it a style. westron builds its own component only where none exists.

**Why.** A system control brings keyboard support, focus, screen reader traits, Liquid Glass adaptation and next
year's OS changes with it. A wrapper or a lookalike has to rebuild all of that, and it drifts from the platform
(decisions/0001,
decisions/0003). The HIG asks apps to "express your brand with
familiar components" and to keep their "sizing, placement, and behavior" familiar.

**In practice.**
- Designer: before you draw a control, name the system control it is. A custom control needs a reason in the contract.
- Agent: `Button("Save") { … }.buttonStyle(.primary, size: .m)`, never a `WButton`. A component with no system
  counterpart (Badge, Banner, EmptyState) has the contract's name, with no prefix.
- Check: the contract's `platforms` block names the base control on each platform. The API parity lint (#21) and the
  `spec-reviewer` subagent compare the code with it. Chapter 09 has the full policy.

## 3. Color and motion carry meaning, never decoration

The accent marks the primary action and the current selection. A status color warns or reports, and a list color
identifies a thing a person named. Motion shows what changed and where it went. Neither color nor motion is ever the
only signal.

**Why.** A color used everywhere stops meaning anything, and in a technical product people read color as state. So
westron has one accent, cobalt, which also means "info", and a screen holds four hues at most. A status always shows
an icon and a word. A list color never means a state (decisions/0012). Each motion is
named by what moves and answers a change: a check pops, a reordered row moves to its place, a sheet is revealed
(decisions/0013). People who cannot tell colors apart or who
turn motion off must lose nothing (chapter 08).

**In practice.**
- Designer: on one screen, the accent fills one action, the primary one. A checked box or a switch that is on takes
  the accent too, because it marks a selection. A color that means a state comes with a glyph, a shape or a word.
  Every motion answers "what changed, and where did it go?".
- Agent: take colors by role from the semantic tokens, and read `dev.westron.usage` before using the accent. Take
  motion from the motion tokens, and honor Reduce Motion in every animation.
- Check: the `a11y-auditor` subagent checks Reduce Motion and differentiation without color. A screen with more than
  one accent-filled button is a review finding.

## 4. Quiet by default, dense where the work is

Surfaces are calm and close in tone. Hierarchy comes from type, space and a soft shadow, not from boxes and borders.
Where people read a lot of data, westron gets denser, not louder.

**Why.** People keep westron's screens open for hours, and in a technical product they scan them for one value. A
cool, quiet ground and thin lines keep attention on the content (chapter 02). Density follows directly from the word
"technical": tables, logs and code need it (research report, "Ten additions"). Comfortable is the default density for
every product, and a dense view is a mode, not a second design
(decisions/0013).

**In practice.**
- Designer: before you add a border, try space and weight. A card groups content and is raised off the canvas: by a
  soft shadow in light, by a lighter surface in dark. Something that floats or is dragged stands higher (chapter 04).
- Agent: density comes from the `density` modifier through the environment
  (decisions/0010), never from a component's own option. It changes
  the sizes and insets of components, never the space ladder, the text size, the page margins or the gaps between
  sections.
- Check: no contract has a density option of its own. The `compact` context gets values with the dense components
  (#33).

## 5. Every value has a role and a name

A color, a size, a radius or a motion is chosen for what it does (`color.text.secondary`, `space.100`) and comes from a
token. The names of variants, sizes and states come from the contract through the generator.

**Why.** The same role takes a different value in each of the four themes, in each density and on each platform. A raw
value is right in one of these and wrong in the others, and the contrast check cannot see it. A role also tells the
agent which token to pick; a value does not.

**In practice.**
- Designer: when a value is missing, name the role it serves and add a token for it. Do not reuse a token with another
  role because its value happens to match.
- Agent: no raw values in `WestronUI`. A deliberate exception carries `// westron-lint: allow <reason>`. Generated
  files are never edited by hand.
- Check: `tools/westron lint raw-values` and `tools/westron generate --check`.

## 6. Every theme and every text size is a real one

The light, dark and both high-contrast themes, the accessibility text sizes and Reduce Motion are designed and checked
like the default. They are not derived from it at the end.

**Why.** A person who turns on Increase Contrast or the largest text size sees only that version. Each of the four
themes (decisions/0010) is a target of the contrast check and a
column of the snapshot matrix.

**In practice.**
- Designer: review a sample in all four themes and at an accessibility text size before you approve it.
- Agent: take screenshots in the dark theme and at `accessibility3` before you say "done". Text that does not fit
  wraps, or truncates with an ellipsis where its full text is reachable; it is never clipped.
- Check: the contrast check (#15), the accessibility audit in UI tests (#25), the snapshot matrix (#24) and the
  `a11y-auditor` subagent (chapter 08).

## Open questions

1. **Order when principles conflict.** Proposal: accessibility (6) wins, then the platform (2), then the brand (1).
2. **A consumer for dense components.** A component needs a product that uses it, and the pilot is a task list. Which
   product consumes the dense components, such as a table or a log (#33), so that they can be built?
