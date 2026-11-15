# 09. Platform adaptation

Date: 2026-11-15. Status: draft for the owner's approval (#8, #9).

This chapter says what stays with the system and what westron controls on each platform. It applies principles 1 and 2
(chapter 00) and [decisions/0002](../decisions/0002-platforms-and-stacks.md) and
[decisions/0003](../decisions/0003-styles-on-system-controls.md). The goal is the same decisions on every platform, not
the same pixels.

## The rule

**A system control with a westron style beats a custom control.** In order of preference:

1. The system control as it is. westron only gives it tokens, such as the accent the platform tints it with.
2. The system control with a westron style: a SwiftUI `ButtonStyle`, a GTK style class, a Material3 component inside
   `WestronTheme`, a native web element with westron CSS.
3. A westron component, named as in the contract with no prefix, only when the platform has no control for the job.

If a design asks for a look the system control cannot take, the design changes first. If it still needs a custom
control, the contract records why.

## Why

- Platform owners draw the same line. The HIG asks apps to use the accent "judiciously", to move brand color "into the
  content layer", to "express your brand with familiar components" and to "rely on established conventions for
  navigation and modality" ([HIG Branding](https://developer.apple.com/design/human-interface-guidelines/branding)).
  GNOME asks apps to keep custom styling "to a minimum" and to use the stock style classes and color variables, which
  "automatically adjust for the light, dark and high-contrast styles"
  ([GNOME HIG](https://developer.gnome.org/hig/guidelines/ui-styling.html)). Android recommends Material and shows how
  to extend its theme ([Android](https://developer.android.com/develop/ui/compose/designsystems/custom)).
- A system control carries behavior westron cannot afford to rebuild on four platforms: focus, keyboard, screen
  readers, input methods and the next OS release.

## Liquid Glass

- Liquid Glass is the system's layer for controls and navigation that "floats above the content layer". The HIG says:
  "Don't use Liquid Glass in the content layer", and asks to use it "sparingly" on custom controls
  ([HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials)).
- System bars, toolbars, tab bars, sidebars, sheets and menus get glass by themselves. westron does not restyle them.
- A westron control that floats over content, such as the pilot's round back and "…" buttons, may use glass through the
  system API (`glassEffect`, the `.glass` button styles), because it is a control. A row, a card, a tile or an empty
  state never does.
- Brand color belongs "in the content layer, where it scrolls beneath Liquid Glass controls and gets picked up
  dynamically" (HIG Branding).
- Glass needs iOS 26, macOS 26 and watchOS 26. It sits behind `if #available` with a fallback for the minimum versions
  ([decisions/0008](../decisions/0008-apple-toolchain-and-catalog.md)).

## What stays with the system and what westron controls

| Platform | Stays with the system | westron controls |
|---|---|---|
| Apple, all | Liquid Glass and its layer; navigation stacks, split views, bars, toolbars, sheets, popovers, alerts, menus, context menus, pickers, text input, scrolling, focus; the system font for body text; Dynamic Type; the look of SF Symbols | Tokens as colorsets with four themes; styles on system controls; content-layer components (rows, tiles, headers, empty states, dense data views); headings in the rounded design; icon names mapped to SF Symbols; motion tokens; the app's accent |
| iOS, iPadOS | Edge swipe back, swipe actions, haptics, the keyboard; size classes and window size, since iPhone apps become resizable from iOS 27 | Content layout per width class, never per device |
| macOS | Window chrome, title bar and toolbar, the sidebar's material, the menu bar, ⌘ shortcuts, the focus ring, inactive window dimming; the person's accent color, which replaces the app's on system controls unless they chose Multicolor | Hover states inside content rows; the density of data views |
| watchOS | Navigation, the Digital Crown, modal sheets and their materials ("Avoid removing or replacing material backgrounds for modal sheets") | A reduced subset of components, recorded in each contract (#34); glanceable layouts ([HIG watchOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-watchos)) |
| Web | Native `<button>`, `<input>`, `<select>`, `<dialog>`, popover; routing and history; `system-ui`; the person's color scheme, contrast, reduced motion, forced colors and zoom | Tokens as CSS custom properties; the look of native elements; own components only where no element exists; the shape of the library is decided in #40 |
| GNOME | Adwaita widgets and their look; `AdwNavigationView`, `AdwSidebar`, dialogs and bottom sheets; the header bar; the dark style and high contrast, which an app "cannot disable"; Adwaita Sans | The accent through `--accent-bg-color`, `--accent-fg-color` and `--accent-color` ([libadwaita](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/1-latest/styles-and-appearance.html)); variants as stock style classes (`.suggested-action`, `.destructive-action`); a small `style.css` for westron's own content widgets, built on libadwaita's variables; icons; heading weight and size |
| Android | Material3 components and their behavior; system and predictive back; text fields, pickers, sheets; ripple; minimum touch targets; Roboto | `WestronTheme` around `MaterialTheme` through `CompositionLocal`; Material's color, type and shape schemes derived from westron tokens; own components only where Material has none |

Fonts follow [decisions/0011](../decisions/0011-icons-and-fonts.md): no font files, the system font everywhere, and the
rounded design for headings on Apple only.

## How differences are recorded

A difference between platforms with no record is a bug ([decisions/0005](../decisions/0005-workflow.md)). There are
three places for a record:

- **The contract's `platforms` block.** For each platform: whether the component exists there, the strategy (a style on
  a system control, a style class, an own component), the base control, the supported variants and sizes, and each
  deviation with its reason. For example, the watch may support only one button size. The exact fields arrive with the
  contract schema (#18).
- **The `platform` modifier in the tokens.** A value that differs by platform, such as a control height on macOS and
  iOS, lives in `tokens/platform/<platform>.tokens.json` and is resolved at build time by that platform's generator. A
  value that is the same everywhere is not repeated there
  ([decisions/0010](../decisions/0010-token-structure-and-modes.md)).
- **The conventions table (#19).** How a contract concept maps to each platform's API: variants and sizes through a
  style, states through the environment, slots through `@ViewBuilder`.

Names never differ silently. The values of variants, sizes and states are generated from the contract. A component's
type name may differ only where the platform forces it, and the contract says so (decisions/0003).

## Open questions

1. **The person's accent or the brand's.** On GNOME an app may override the accent the person chose; on macOS the
   person's choice wins on system controls. Should westron override it on GNOME?
2. **Dynamic color on Android.** Material can take its colors from the wallpaper. Should westron products allow it, or
   always use westron's palette? Decided at the latest in phase 8.
3. **The fallback before OS 26.** The pilot draws its floating buttons on its own translucent color when glass is not
   available. Proposal: use the system material instead, which adapts to Reduce Transparency and Increase Contrast.
4. **Headings on GNOME.** libadwaita has its own title style classes. Should westron headings use them as they are, or
   change their weight and size through `style.css`?
