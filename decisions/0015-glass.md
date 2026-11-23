# 0015. Glass: a floating Button, and the system's glass everywhere else

Date: 2026-11-23. Status: approved on 2026-11-23 (#121): the owner answered the questions marked for him, and the
coordinating agent the others under the owner's delegation (decisions/0014), each with its recommendation (A); see
"Decision". Implemented on Apple in the same pull request ("Implementation: what was measured").

## Decision

The owner's answers, 2026-11-23:

- **Scope: the floating button only.** The pilot's bars go to the system's toolbars, westron adds Button's option
  `floating`, and there is no glass Surface. This revises decisions/0014's "a glass Surface" for #121 and the issue's
  title; decisions/0014 says so and points here.
- **Q3 (A).** A floating secondary is the system's glass from OS 26, `glassEffect(.regular.interactive(), in:
  Capsule())` behind `if #available`, with no fill, shadow, outline, tint or press scale of westron's on it: a narrow
  exception to the flat fills, the floating button only (decisions/0013, Button's decisions/0001 and 0003).
- **Q2 (A).** Before OS 26, an opaque raised surface: `color.background.surface`, `shadow.overlay`, hover and pressed
  from the existing row tints, and secondary's high-contrast outline. This answers design-language/09's open question 3
  otherwise than the chapter's draft proposal, a material; the chapter says so.
- **Q4 (A).** A floating primary is its opaque accent fill and `shadow.overlay` on every OS version.
- **Q1** is the pilot's own decision. westron's contract serves both cases, the system's navigation bar and floating
  buttons over a hidden one, and changes nothing in the pilot.

The coordinating agent's answers, 2026-11-23, each (A): Q5, the label's colors are Button's tokens; Q6, pressed and
hover on glass are the interactive glass's own response; Q7, disabled dims the whole button at `opacity.disabled`; Q8,
no westron outline on glass under Increase Contrast; Q9, no glass Surface; Q10, the system's toolbars; Q11, tertiary
cannot float, a constraint of severity `error`; Q12, the option is named `floating`; Q13, an icon-only floating glyph
takes Button's own scale, and the pilot's larger glyphs are a recorded difference, not adopted.

A shared decision rather than one under `spec/components/button/decisions/`: it answers for two contracts, Button and
Surface (decisions/0014 names both for #121), answers design-language/09's open question 3, and scopes statements in
decisions/0013, in chapters 00, 04, 08 and 09 and in Button's decisions 0001 and 0003. A component's own decision
folder could hold only one of these.

## Context

The owner took glass into phase 4 on 2026-11-22 (in the owner's words: we take glass into this phase). decisions/0014
gives #121 as "Glass: a floating Button and a glass Surface. The owner takes glass into this phase; what is drawn
before iOS 26 is decided at the contracts", an extension of `spec/components/button/` and `spec/components/surface/`.
The issue asks: "Decide at the contracts: a Button variant, a Surface variant, or both; what is drawn before iOS 26
(minimum iOS 17, macOS 14)."

### What the documents say today

Quoted as they stand on `main` at `05f8c1f`; the column on the right says what this proposal does to each.

| Where | Today | This proposal |
|---|---|---|
| design-language/00, principle 1 | "Bars, sheets, menus and glass stay the system's." "Agent: never tint or restyle navigation, toolbars, tab bars, sidebars, sheets, menus or pickers beyond the accent the platform already takes." | Kept, and applied first: every bar of the pilot takes the system's own glass (below, "System first") |
| design-language/04, "Lines" | "`stroke.hairline` edges glass and a card on a fill." | westron draws no edge on glass; the sentence keeps its card half (follow-up) |
| design-language/04, "Shadows", table | `shadow.overlay`: "A popover, a menu or a floating button westron draws" | Used as written: a floating button westron draws casts it |
| design-language/04, "Shadows" | "System surfaces bring their own shadow. Sheets, popovers, menus and Liquid Glass cast the system's shadow, and westron adds none (chapter 09)." | Kept: no westron shadow on glass |
| design-language/04, "Corners" | "Apple's controls and glass have continuous corners, and westron's shapes match them." | Kept: the glass is drawn in Button's capsule |
| design-language/05 | "Navigation motion belongs to the system: push and pop, sheets, popovers, menus, and Liquid Glass changing shape (chapter 09)." | Kept: the glass's press response and any morphing are the system's |
| design-language/08, "Reduce Transparency" | "Glass and materials are the system's, and they adapt to this setting by themselves (HIG Materials). A translucent surface that westron draws itself becomes opaque when the setting is on." | Kept: westron draws nothing translucent; its fallback is opaque |
| design-language/09, "Liquid Glass" | "Liquid Glass is the system's layer for controls and navigation that 'floats above the content layer'. The HIG says: 'Don't use Liquid Glass in the content layer', and asks to use it 'sparingly' on custom controls." "System bars, toolbars, tab bars, sidebars, sheets and menus get glass by themselves. westron does not restyle them." "A westron control that floats over content, such as the pilot's round back and '…' buttons, may use glass through the system API (`glassEffect`, the `.glass` button styles), because it is a control. A row, a card, a tile or an empty state never does." "Glass needs iOS 26, macOS 26 and watchOS 26. It sits behind `if #available` with a fallback for the minimum versions." | Applied as written: the floating Button is that control, through `glassEffect` |
| design-language/09, open question 3 | "The fallback before OS 26. The pilot draws its floating buttons on its own translucent color when glass is not available. Proposal: use the system material instead, which adapts to Reduce Transparency and Increase Contrast." | Answered differently: an opaque raised surface from tokens (Q2) |
| decisions/0002, "Consequences" | "On Apple, Liquid Glass and the HIG apply: the brand lives in the content layer, and the accent color is used sparingly." | Kept |
| decisions/0003, "Constraint on value names" | The names a button's value must not take include "`glass`, `glassProminent`". | Kept: the option is `floating`, a bool, and no value is named `glass` |
| decisions/0006, the list screen | "floating glass 'back' and '…' buttons;" | The consumer |
| decisions/0008 | "Newer APIs, including Liquid Glass, are used inside `if #available(iOS 26, macOS 26, watchOS 26, *)`." | Kept |
| decisions/0013, "Shadows" | "Never shadow what the system draws: a sheet, a popover, a menu, glass." | Kept |
| decisions/0013, the owner's decisions of 2026-11-20 | "Fills are flat and opaque, in westron's colors, with no glass or material." | **Scoped** (Q3, the owner's): a button in a layout; a floating secondary stands on the system's glass |
| decisions/0014, consequences | "#121 changes two approved contracts at the contract first: Button's description says floating glass buttons are not that component, and Surface's that a surface never takes glass." | Button changes; Surface keeps its sentence and says where a group's glass comes from |
| Button's contract, description | "Every fill is flat and opaque, in westron's colors, with no glass or material." "Floating glass buttons over content are not this component: products use the system's glass styles (chapter 09)." | **Reversed** for a floating button (the patch below) |
| Button's decisions/0001, "Floating glass buttons" | "Considered: a glass variant for the pilot's floating back and '…' buttons over the task list; the system's styles. **Chosen: not part of this contract.** Products use the system's `.glass` styles (chapter 09)." | **Reversed**: a bool option rather than a variant |
| Button's decisions/0003, point 1 | "Flat, opaque fills in westron's colors, no glass and no material." | **Scoped** as decisions/0013's (Q3) |
| Surface's contract, description | "westron's shadow never goes on what the system draws itself, a sheet, a popover, a menu or glass, and a surface never takes glass (design-language/04, 'Shadows'; 09, 'Liquid Glass')." | Kept; the glass under a group of controls is the system's (applied on this branch) |
| Surface's decisions/0001 | "westron never shadows what the system draws (a sheet, a popover, a menu, glass); a card never takes glass" | Kept |
| `tokens/semantic/stroke.tokens.json`, `stroke.hairline` | "The edge of glass and of a card on a fill." | Its glass half has no user (follow-up) |

### The pilot's glass

Read with `gh` at todo-app's `0162887` (the commit decisions/0014 read): `Sources/DesignSystemComponents/`
`GlassButtonModel`, `GlassButtonLabelModel`, `GlassControlStyle`, `GlassCapsuleStyle`, `GlassMenuButtonModel`,
`FloatingButtonModel`, `FloatingButtonStyle`, `ControlFillStyle`, `BarModel`, `BarStyle`; their views in
`Apps/Apple/Sources/TodoAppleUI/` (`ListScreen/GlassButton.swift`, `ListScreen/FloatingButton.swift`,
`ListScreen/ListScreen.swift`, `ListScreen/ListPane.swift`, `DesignSystem/Bar.swift`, `ListsScreen/ListsScreen.swift`,
`ListsScreen/ListsSidebar.swift`); their numbers in `Sources/Features/TaskList/TaskList+Metrics.swift`,
`TaskList+PaneMetrics.swift` and `Sources/Features/TaskViewList/TaskViewList+Components.swift`; and the specs
`docs/specs/lists-screen.md` (sections 1 and 7) and `docs/specs/list-screen.md` (sections 1 and 10).

| Use | Where it stands | What the pilot draws from OS 26 | Before OS 26 |
|---|---|---|---|
| iPhone, list screen: back and "…" | Over the content at the safe area's top, 14 pt in from the sides, the navigation bar hidden "for the canvas's look (owner, 2026-11-08, on #194)" (list-screen.md, section 1; `ListScreen.swift`, `.toolbar(.hidden, for: .navigationBar)`) | 44 pt circles, `glassEffect(.regular.interactive(), in: Capsule(style: .circular))` (`GlassButton.swift`, `glassSurface`) | The pilot's `.glass` color over `.regularMaterial`, a 0.5 pt hairline in `.glassLine`, the raised shadow |
| iPhone, list screen: round "+" | Bottom right, 16 pt in, 30 pt up (`TaskList+Metrics.swift`, `phoneFloatingButton`) | A 48 pt circle filled with the accent, casting the raised shadow; no glass (`FloatingButton.swift`) | The same |
| iPad pane: back, and "+" and "…" | Items of the window's bar (`ListPane.swift`, `ListPaneBar`) | The pilot's own glass, with the bar's hidden by `.sharedBackgroundVisibility(.hidden)`: "iOS 26 and macOS 26 put their own glass behind a bar's item, which would stand under the style's a second time" (`GlassToolbarItem`) | The bar draws none; the pilot's fallback glass |
| Mac pane: "+" and "…" in one capsule | An item of the window toolbar, at its trailing edge; the back is the toolbar's own (owner, 2026-11-09) | A capsule 34 pt high, items 30 × 28, a 1 × 16 rule between them, on the pilot's glass (`PaneMetrics`, `paneStyle`) | The same capsule on the fallback |
| iPhone, Lists screen: the bottom bar | `safeAreaInset(edge: .bottom)` over the pilot's own fade (`ListsScreen.swift`) | "…" on the container, the search capsule on the container, "+" filled with the accent and casting the raised shadow; in edit mode "+ List" and "+ Area" on one capsule, 40 high with a 1 × 22 rule, and Done on the accent (`TaskViewList+Components.swift`, `bar`) | The same: the bar's "container" is `.regularMaterial`, an ink hairline at 8 % and the raised shadow on every OS version, never Liquid Glass (`Bar.swift`, `glass(in:)`) |
| Mac, sidebar: the bottom bar | Under a 1 pt rule | The search field on a fill and "+": no glass | The same |

So the pilot draws Liquid Glass in two places, its glass circles and its pane's capsule, and its "glass" bar is a
material on every OS. Its floating "+" and its bar's "+" and Done are opaque accent fills with a shadow.

### Apple's API, verified in Xcode 27.1's SDK

Read in the SwiftUI and SwiftUICore `.swiftinterface` files of the iPhoneOS 27.1, MacOSX and WatchOS SDKs of
`/Applications/Xcode_27_1.app` (`source tools/apple/xcode-env.sh`), 2026-11-23:

| API | Availability in the interface |
|---|---|
| `View.glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape())` | iOS 26, macOS 26, tvOS 26, watchOS 26; visionOS unavailable; the same in all three SDKs |
| `Glass`: `.regular`, `.clear`, `.identity`, `tint(_: Color?)`, `interactive(_: Bool = true)`; `Equatable`, `Sendable` | iOS, macOS, watchOS 26 |
| `GlassEffectContainer(spacing: CGFloat? = nil, content:)` | iOS, macOS, watchOS 26 |
| `glassEffectID(_:in:)`, `glassEffectUnion(id:namespace:)`, `GlassEffectTransition` (`.matchedGeometry`, `.materialize`, `.identity`), `glassEffectTransition(_:)` | iOS, macOS, watchOS 26 |
| `PrimitiveButtonStyle.glass`, `.glass(_ glass: Glass)`; `GlassButtonStyle.init()` | iOS, macOS, watchOS 26 |
| `GlassButtonStyle.init(_ glass: Glass)` | iOS, macOS, watchOS 26.1 |
| `PrimitiveButtonStyle.glassProminent` | iOS, macOS, watchOS 26 |
| `View.backgroundExtensionEffect()`, `backgroundExtensionEffect(isEnabled:)` | iOS, macOS, watchOS, visionOS 26 |
| `ToolbarContent.sharedBackgroundVisibility(_:)`; `ToolbarSpacer` | iOS 26, macOS 26; watchOS unavailable |
| `ToolbarItemPlacement.bottomBar` | iOS, watchOS 10; macOS unavailable |
| `Material`: `.regularMaterial`, `.thickMaterial`, `.thinMaterial`, `.ultraThinMaterial` | iOS 15, macOS 12, watchOS 8 |
| `Material.bar` | iOS, macOS; watchOS unavailable |
| `EnvironmentValues.accessibilityReduceTransparency` | read-only; present on every SDK |
| An environment value for the person's choice of the glass's look (clear or tinted) | none found: no `glassAppearance` or similar member in the three interfaces |

Read in Apple's documentation (developer.apple.com, the pages' data, 2026-11-23), which the interface does not say:

- `glassEffect(_:in:)`: "When you use this effect, the system: Renders a shape anchored behind a view with the Liquid
  Glass material. Applies the foreground effects of Liquid Glass over a view." "SwiftUI uses the regular variant by
  default along with a Capsule shape."
- "Applying Liquid Glass to custom views": "Add `interactive(_:)` to custom components to make them react to touch and
  pointer interactions. This applies the same responsive and fluid reactions that `glass` provides to standard
  buttons." "Apply the `glassEffect(_:in:)` modifier after other modifiers that affect the appearance of the view."
  "Use `GlassEffectContainer` when applying Liquid Glass effects on multiple views to achieve the best rendering
  performance."
- `sharedBackgroundVisibility(_:)`: "In certain contexts, such as the navigation bar on iOS and the window toolbar on
  macOS, toolbar items will be given a glass background effect that is shared with other items in the same logical
  grouping."
- `Glass.clear`: "When using clear glass, ensure content remains legible by adding a dimming layer or other treatment
  beneath the glass."
- HIG Materials: "The appearance of these variants can differ in response to certain system settings, like if people
  choose a preferred look for Liquid Glass in their device's settings, or turn on accessibility settings that reduce
  transparency or increase contrast in the interface." "The regular variant blurs and adjusts the luminosity of
  background content to maintain legibility of text and other foreground elements." "Only use clear Liquid Glass for
  components that appear over visually rich backgrounds."
- HIG Color, "Liquid Glass color": "By default, Liquid Glass has no inherent color, and instead takes on colors from
  the content directly behind it." "For smaller elements like toolbars and tab bars, the system can adapt Liquid Glass
  between a light and dark appearance in response to the underlying content. By default, symbols and text on these
  elements follow a monochromatic color scheme, becoming darker when the underlying content is light, and lighter when
  it's dark." "To emphasize primary actions, apply color to the background rather than to symbols or text."
- `accessibilityReduceTransparency`: "If this property's value is true, UI (mainly window) backgrounds should not be
  semi-transparent; they should be opaque."

**Not verified, to be measured at implementation:** what exactly Reduce Transparency and Increase Contrast do to a
`glassEffect` (the documents say only that its appearance "can differ"); whether a custom glass circle flips between a
light and a dark appearance over content as toolbars do, and what then happens to a label in a fixed color (Q5);
whether the iOS bottom toolbar shares glass between grouped items as the navigation bar does (the documentation names
the navigation bar and the macOS window toolbar); whether `.opacity` dims the glass itself (Q7); whether the glass's
look is deterministic in the snapshot matrix's two render paths (below, "The snapshot matrix").

## System first

decisions/0003 point 1, AGENTS.md rule 3 and principle 1 come first: where the system draws the glass, westron adds
nothing. For each of the pilot's uses:

| Use | The system's own glass | What is left for westron |
|---|---|---|
| iPad pane: back, "+" and "…" | Toolbar items. The bar gives each group a shared glass background on iOS 26 and macOS 26; the pilot hides it only to draw its own. Before 26 the bar's own plain items | Nothing |
| Mac pane: "+" and "…" in one capsule | A `ToolbarItemGroup` in the window toolbar: macOS 26 draws the group on one glass capsule. The pilot's rule between the two goes (the group is the system's). Before 26 the toolbar's own items | Nothing |
| iPhone, Lists screen: the bottom bar | The bottom toolbar, `.toolbar { … }` at `.bottomBar`: from iOS 26 its items stand on the bar's glass and the scroll edge effect replaces the pilot's fade; before 26 iOS 17's and 18's own bar. The edit bar's "+ List" and "+ Area" are one `ToolbarItemGroup` | Nothing; the search field in it is westron's TextField (#115), the menus' buttons are the system's items with westron's Icons |
| iPhone, list screen: back and "…" | The navigation bar with no title, `navigationBarBackButtonHidden()` and the list's own back as a `.topBarLeading` item, "…" a `.topBarTrailing` `Menu`: from iOS 26 the bar draws each on a glass circle over the scrolling content, which is the canvas's look; before 26 iOS 17's bar. The pilot hid the bar for the canvas's look (owner, 2026-11-08); whether it shows it again is Q1, the owner's | Nothing if the bar is shown; two floating buttons while it is hidden |
| iPhone, list screen: round "+" | None: no bar has a corner slot. The system's nearest is a `.glassProminent` button, iOS 26 only | One floating button, on every OS version |
| Mac sidebar's bottom bar | No glass in the pilot either | Nothing |

**What is left is small.** Every bar of the pilot is the system's. westron is left with a control that floats over
content outside any bar: the round "+" for certain, and the back and "…" while the pilot keeps its navigation bar
hidden; and with what those draw before OS 26. A group of controls on one piece of glass needs nothing of westron's:
in a bar it is the bar's group, and outside one, from OS 26, it is the system's `GlassEffectContainer`, which a product
writes around floating buttons. So Surface takes no glass.

## Options

**A. Guidance only: no contract change.** Button's last sentence says where glass comes from: the bars, and the
system's `.glass` and `.glassProminent` styles behind `if #available`. The round "+" is already a composition:
`.buttonStyle(.primary, size: .l, iconOnly: true)` and `.shadow(.overlay)`, both public on `main`. Cost: every product
writes the `if #available` and its own fallback for a neutral floating button, and nothing of it is in a contract, a
matrix or a parity record; the system's `.glass` style draws the system's heights and label, not westron's.

**B. A bool option on Button, `floating` (recommended).** `.buttonStyle(.secondary, size: .l, iconOnly: true,
floating: true)`. A floating secondary stands on the system's glass from OS 26 and on an opaque raised surface before
it; a floating primary keeps its fill and casts `shadow.overlay`; tertiary does not float (a constraint). Surface is
unchanged but for one sentence. No new token. It covers every use that is left, both OS eras in one call.
- *Generator and parity lint, as they are on `main`*: a bool option that is not a state is a labeled `Bool` argument
  of the generated overload with its default, as `iconOnly` is (spec/conventions.md). Measured by generating with the
  revised contract on this branch and reverting: `Button+Contract.swift` gains `floating: Bool = false` and passes it
  to `ButtonVariantStyle(variant:size:iconOnly:floating:)`, which the hand-written style does not take yet, so the
  package would not compile; `Button+Matrix.swift` grows from "3 variant × 3 size × 2 role × 2 iconOnly × 6 states …
  216 combinations … on 12 sheets" to "… × 2 floating × 6 states … = 432 combinations; constraints forbid 72 of them,
  so the matrix has 360, on 24 sheets". The API parity lint compares `WestronUI`'s public API with the generated
  contract, so it passes once the style takes the argument. That is why the revision is a patch below and not in the
  contract file: applied without the code, `main` would not build.

**C. B, and a Surface variant for glass under a group.** `.surface(.glass)`: no system style to collide with, since
Surface is westron's own. But a surface draws `radius.card`, and a group of controls is a capsule, so it would need a
shape option; it puts glass in the content layer's component, which chapter 09 and Surface's contract rule out; and
after "System first" no use is left for it. Rejected, Q9.

**D. A variant value.** `glass` and `glassProminent` are banned (decisions/0003) and would shadow the system's styles;
`floating` as a fourth variant would need a second one for the accent ("+" is primary) and would say nothing about
the fill's role, which is what a variant says. Rejected.

## The proposal in detail (B)

### What a floating button draws

| | From iOS 26, macOS 26, watchOS 26 | Before |
|---|---|---|
| **secondary**, ground | The system's glass: `glassEffect(.regular.interactive(), in: Capsule())`, applied after every other modifier of the drawn button; no fill | `color.background.surface` |
| shadow | The glass's own; westron adds none | `shadow.overlay` |
| hover, pressed | The interactive glass's own response; no tint, no scale | `color.background.hover`, `color.background.pressed`, in `motion.fade` and `motion.press`; the press scale of 98 %, which Reduce Motion drops |
| high contrast | The glass's own adaptation to Increase Contrast (Q8) | secondary's outline: `color.border.strong` (`color.status.danger.border` with the destructive role) at `stroke.thin` |
| label, icon, progress | Button's colors: `color.text.primary`, `color.status.danger.text` (Q5) | The same |
| disabled | The whole button at `opacity.disabled` (Q7) | The same |
| **primary** | Its opaque fill and tints as in a layout, its press scale, and `shadow.overlay` (Q4) | The same |
| **tertiary** | Does not float (a constraint) | — |

Shape, heights, padding, gap, fonts, icon seating, loading, role and the hit area are Button's, unchanged. The `l` size
on iOS is 50 pt, past the pilot's 44 and 48 and past `size.target.minimum`.

### Before OS 26: why an opaque surface (Q2)

- It is in westron's tokens and needs no new one: the ground is `color.background.surface`, which a card already
  takes, raised off the canvas by `shadow.overlay`, which chapter 04 already names for "a floating button westron
  draws".
- Its contrast is computable and already declared and passing in all four themes (`tools/westron tokens contrast
  --all`, 2026-11-23, lowest of the four themes): `color.text.primary` on `background.surface` 12.74:1, on
  `background.hover` 11.73, on `background.pressed` 10.18; `color.status.danger.text` on them 5.51, 4.82, 4.53;
  `color.border.strong` on them 3.66, 3.21, 3.01 in the standard themes and 4.53 and up in high contrast, where 4.5 is
  the target. Only `color.status.danger.border` on `background.hover` and `background.pressed` is not declared yet
  (gap G8).
- It matches the owner's choice of flat, opaque fills for every button in a layout (decisions/0013), and chapter 08's
  rule that westron draws nothing translucent of its own, so Reduce Transparency has nothing to change.
- A material, chapter 09's proposal and the pilot's own fallback, adapts to Reduce Transparency and Increase Contrast
  by itself, but its contrast cannot be computed, it is the one material westron would draw itself, and it would make
  the pre-26 look a third look beside glass and westron's fills. It is Q2's second option.

### Tokens, and what contrast the contract can promise

Glass has no color of its own ("By default, Liquid Glass has no inherent color", HIG Color), and westron binds none to
it: no tint, no fill. What westron binds is the shape (`container.shape: capsule`, continuous on Apple), the height
(`size.control.*`), the hit area (Button's, at least `size.target.minimum` where the contract says so), the label's
colors, and the fallback's ground, shadow and tints. Over glass the ground is whatever content passes beneath, which no
token names, so WCAG 1.4.3 and 1.4.11 cannot be computed from tokens. The contract says so instead of promising a
ratio: legibility over glass is the system's, whose regular variant "blurs and adjusts the luminosity of background
content to maintain legibility", and which follows Reduce Transparency, Increase Contrast and the person's look for
the glass. The `clear` variant, which Apple keeps for media backgrounds and asks to dim, is not used. The accessibility
audit and the catalog's screenshots measure the label over a light and a dark ground at implementation (Q5's test).

### States, motion and the system's settings

- **Hover and pressed** on glass are the interactive glass's: it "reacts to touch and pointer interactions", "the same
  responsive and fluid reactions that `glass` provides to standard buttons". westron's tints are opaque tokens and would
  cover the glass, and its press scale would stack on the glass's own. Before 26, Button's tints and scale (Q6).
- **Focus**: the system's focus ring and effect, as for every Button on Apple ("The focus ring is the system's").
  Measured at implementation over glass with Full Keyboard Access on iOS and keyboard navigation on macOS.
- **Disabled and loading**: Button's rules; a disabled or loading floating button enters no hover or pressed. Glass
  that is `.interactive()` still answers a press on a disabled button unless the style makes it non-interactive there:
  the style passes `interactive(isEnabled && !isLoading)` (to measure).
- **Motion**: no morphing in westron's API. `glassEffectID`, `glassEffectUnion`, `GlassEffectTransition` and
  `GlassEffectContainer` are the system's, and a product that groups or morphs floating buttons writes them itself
  from OS 26; chapter 05 leaves "Liquid Glass changing shape" to the system. Reduce Motion: the glass's own response is
  the system's; the fallback drops its scale (chapter 05).
- **Reduce Transparency, Increase Contrast, the glass's look**: the system's, for the glass; the fallback is opaque and
  takes westron's high-contrast themes. westron reads no setting for the glass, and none exists for its look (above).

### Accessibility

Button's, unchanged: role `button`, the label required and the accessible name also when `iconOnly` hides it, so the
pilot's back is "Back" and its "…" "More", not "Chevron" and "Ellipsis" (Button's accessibility text); the icon beside a
label decorative; disabled announced as unavailable, loading as busy. Floating adds no role and no trait. The hit area
is Button's per OS. A floating button stands over content, so a product keeps it clear of the content's own controls,
which matters on iOS, where a control within about 16 pt shares the touch tolerance (Button's iOS record).

### The snapshot matrix

- **The axis.** `floating` is an axis of the generated matrix, the tertiary cells left out by the constraint (above:
  24 sheets where there are 12).
- **The ground.** The generated cells stand on the canvas, where glass shows almost nothing of itself. A
  hand-written supplement ("not a contract option", platforms/apple/README.md) draws the floating secondary and
  primary over a deterministic ground of westron's own. As built: diagonal stripes in four list colors' fills
  (`color.category.{orange,blue,green,violet}.fill`), which follow the theme, drawn by a `Canvas` with no image and no
  randomness, on the floating sheets of size `m`.
- **Both eras.** The CI runner renders on iOS 27.0 and macOS 27.0.1 (`platforms/apple/Snapshots/*/environment.json`),
  so the `else` branch, everything before OS 26, would never be rendered. The style reads a `package`-level override
  in `WestronUI`, set only by the catalog's supplement, that draws the fallback on any OS (gap G4); it is not public, so
  the API parity lint does not see it (to confirm with the lint).
- **What to expect, and measure first.** On iOS the matrix draws a window with `drawHierarchy(in:afterScreenUpdates:)`,
  which captures what the render server composites, glass included; on macOS a window never ordered in is drawn by
  `CARenderer` in the process, and a backdrop effect such as glass, which samples what is behind it, may draw nothing
  or a flat fill there: "`ImageRenderer`, `cacheDisplay` and `CALayer.render(in:)` misdraw system controls"
  (platforms/apple/README.md), and the macOS path has misdrawn system views before. The first step of the
  implementation renders one glass cell on both platforms, twice, and compares the draws pixel for pixel; where a
  path misdraws glass, those cells are recorded as such (gap G6) and the catalog's screenshot of the entry is their
  reference instead.

### Platforms

- **Apple**: one style on the system `Button`; the glass behind `if #available(iOS 26, macOS 26, watchOS 26, *)`. The
  difference between OS versions has no field in the `platforms` block, so Apple's description records it (gap G1).
  watchOS keeps its one size, `m`, and draws the same two looks.
- **Web** (provisional, phase 6): the fallback's bindings, a surface and a `box-shadow`; whether a floating secondary
  takes a translucent fill with `backdrop-filter`, opaque again under `prefers-reduced-transparency` and
  `prefers-contrast: more`, is decided there.
- **GTK** (provisional, phase 7): the bindings; whether a floating secondary takes libadwaita's `.osd` style class,
  its look for controls over content, is decided there.
- **Android**: planned, as Button's block says; Material3's floating action button is the likely base of a floating
  primary.

## The revision of Button, applied

Drafted as a patch, since the option it adds becomes an argument the hand-written style must take, and applied on
2026-11-23 with the implementation, its header comment's date filled in. The diff as drafted:

```diff
--- a/spec/components/button/button.spec.yaml
+++ b/spec/components/button/button.spec.yaml
@@ -1,9 +1,8 @@
 # westron's Button contract (#22), approved by the owner on 2026-11-16; the macOS hit area decided by the owner on
 # 2026-11-18 (#75) and the iOS one on 2026-11-21 (#102): decisions/0001-button-contract.md records the owner's answers and the bindings the owner confirmed
 # on top of them. Its look revised on 2026-11-20 (#85), the owner's choice from prototype renders, pending the owner's
-# review of this contract and its snapshot matrix together (decisions/0003-the-look-of-2026-11-20.md).
-# Proposed, not applied: the option floating for a button over content (#121), in decisions/0015-glass.md at the
-# repository's root as a patch to this file, applied with the code it needs.
+# review of this contract and its snapshot matrix together (decisions/0003-the-look-of-2026-11-20.md). The option
+# floating, a button over content, added on <date of approval> (#121), decisions/0015-glass.md at the repository's root.
 id: button
 status: approved
 description: >-
@@ -29,8 +28,20 @@
   the button does not dim. The button is not meant for a width smaller than its label's longest word: the label wraps
   only between words, and the product provides the room, by stacking buttons, giving the button the full width, a
   shorter label, or icon-only. In a narrower container the label breaks inside a word; that is unsupported, not a
-  behavior of this contract (decisions/0001). Floating glass buttons over content are not this component: products
-  use the system's glass styles (chapter 09).
+  behavior of this contract (decisions/0001). A floating button stands over content, outside any bar, such as a way
+  back and a "…" over a list or a round "+" in a screen's corner (decisions/0015). A floating secondary is the one
+  exception to the flat fills: from iOS 26, macOS 26 and watchOS 26 it stands on the system's glass, regular and
+  interactive, in the button's capsule, with no fill, outline, shadow, hover or pressed tint and no press scale of
+  westron's, since the glass answers the pointer and the press itself. Before those versions it stands on
+  color.background.surface and casts shadow.overlay, tinted and scaled under the pointer and pressed as the bindings
+  say, and draws secondary's outline in the high-contrast themes. A floating primary keeps its opaque fill, its tints
+  and its scale on every version and casts shadow.overlay. tertiary has no ground to float on and does not take
+  floating. The bindings below are what is drawn where there is no glass; on glass the label and the icon keep their
+  colors and the disabled button its opacity.disabled, and the glass adapts its luminosity to what passes beneath it
+  and follows Reduce Transparency, Increase Contrast and the person's choice of the glass's look by itself, so the
+  contract promises no contrast ratio for a label on glass: what lies beneath is the product's content, which tokens
+  do not name. A button in a system bar, toolbar or tab bar never floats: the bar draws its own glass
+  (design-language/09).
 consumers: [todo-app/lists-screen, todo-app/list-screen]
 
 options:
@@ -61,10 +72,23 @@
     description: >-
       The same button showing only its icon: a circle whose diameter equals its height; padding and gap do not apply.
       The label is still there as the accessible label.
+  floating:
+    type: bool
+    default: false
+    description: >-
+      The button stands over content, outside the layout and any bar, rather than among it: secondary on the system's
+      glass from OS 26 and on a raised surface before it, primary on its own fill with a shadow. Not for a button in a
+      system bar, toolbar or tab bar, whose glass is the bar's.
 
 slots: [label, icon]
 states: [hover, focus, pressed, disabled, loading]
 
+constraints:
+  - when: { floating: true }
+    require: { variant: [primary, secondary] }
+    severity: error
+    description: tertiary has no fill, so it has no ground to float on.
+
 tokens:
   container.height: { s: size.control.s, m: size.control.m, l: size.control.l }
   container.shape: capsule
@@ -75,6 +99,8 @@
       # Disabled and loading come first: they exclude hover and pressed, so the resting fill holds.
       - { when: { variant: primary, role: destructive, state: [disabled, loading] }, token: color.status.danger.fill }
       - { when: { variant: primary, state: [disabled, loading] }, token: color.background.accent }
+      # A floating secondary where there is no glass, before OS 26 (decisions/0015); on glass it has no fill.
+      - { when: { variant: secondary, floating: true, state: [disabled, loading] }, token: color.background.surface }
       - { when: { variant: secondary, state: [disabled, loading] }, token: color.background.muted }
       - { when: { variant: tertiary, state: [disabled, loading] }, token: null }
       - { when: { variant: primary, role: destructive, state: pressed }, token: color.status.danger.fill-pressed }
@@ -84,7 +110,11 @@
       - { when: { variant: primary, state: hover }, token: color.background.accent-hover }
       - { when: { variant: primary }, token: color.background.accent }
       # Under the danger words the muted fill darkens only as far as they still read; under text.primary it darkens
-      # more (the owner's decision of 2026-11-20, decisions/0003).
+      # more (the owner's decision of 2026-11-20, decisions/0003). A floating one stands on the surface, where the row
+      # tints read under both the danger words and text.primary (declared pairs, every theme).
+      - { when: { variant: secondary, floating: true, state: pressed }, token: color.background.pressed }
+      - { when: { variant: secondary, floating: true, state: hover }, token: color.background.hover }
+      - { when: { variant: secondary, floating: true }, token: color.background.surface }
       - { when: { variant: secondary, role: destructive, state: pressed }, token: color.background.muted-pressed-colored }
       - { when: { variant: secondary, role: destructive, state: hover }, token: color.background.muted-hover-colored }
       - { when: { variant: secondary, state: pressed }, token: color.background.muted-pressed }
@@ -95,6 +125,11 @@
   container.opacity:
     cases:
       - { when: { state: disabled }, token: opacity.disabled }
+  # Over content: a floating primary on every OS version, a floating secondary where there is no glass. The glass
+  # casts the system's own shadow, and westron adds none to it (design-language/04, "Shadows").
+  container.shadow:
+    cases:
+      - { when: { floating: true }, token: shadow.overlay }
   container.pressMotion: motion.press
   container.hoverMotion: motion.fade
   label.font: { s: typography.footnote.strong, m: typography.subheadline.strong, l: typography.body.strong }
@@ -150,7 +185,15 @@
       prototype the owner chose drew it; in icon-only's square frame it draws a circle.
       The icon beside the label is set to .imageScale(.small) and laid out with the label in an HStack aligned on
       .firstTextBaseline; icon-only draws the glyph at the same small scale. The high-contrast outline follows
-      colorSchemeContrast, as Surface's line does.
+      colorSchemeContrast, as Surface's line does. floating is a labeled argument too,
+      .buttonStyle(.secondary, size: .l, iconOnly: true, floating: true). A floating secondary's glass is
+      glassEffect(.regular.interactive(), in: Capsule()) inside if #available(iOS 26, macOS 26, watchOS 26, *),
+      applied after every other modifier of the drawn button, as glassEffect asks; the else branch draws the surface,
+      the shadow and the tints of the bindings. These two looks by OS version are one contract: the platforms block
+      has no field for an OS version, so this description is the record of the difference (decisions/0015). westron
+      adds no GlassEffectContainer, glassEffectID or glassEffectUnion: a product that sets floating buttons side by
+      side, or morphs one into another, writes the system's own around them from OS 26. The shadow is
+      View.shadow(_:), as Surface's.
     ios:
       description: >-
         Hover only with a pointer, on iPad; an iPhone never enters it. The hit area is the system's touch tolerance
@@ -188,13 +231,16 @@
       focusRing.color and focusRing.width on :focus-visible. Hover only under a pointer, (hover: hover). A native
       <button> still matches :hover while disabled, and :hover and :active while aria-busy, so the CSS excludes them
       in those states and keeps the resting fill. The capsule is a border-radius of half the height or more, so its
-      ends stay round as the button grows.
+      ends stay round as the button grows. floating draws the bindings, the surface and box-shadow, on every
+      browser; whether a floating secondary takes a translucent fill with backdrop-filter, opaque again under
+      prefers-reduced-transparency and prefers-contrast: more, is decided in phase 6, as the web has no system glass.
   linux:
     strategy: style-on-system-control
     base: GtkButton
     description: >-
       Provisional until phase 7: how the variants and the role map to style classes is decided there. The focus ring
       is the system's, so the focusRing bindings do not apply. The capsule is a border-radius of half the height or
-      more, as on the web.
+      more, as on the web. floating draws the bindings; whether a floating secondary takes libadwaita's osd style
+      class, its own look for controls over content, is decided there.
   android:
     status: planned
```

Button's decisions/0001 has a note under "Floating glass buttons" pointing here, and `Button+Contract.swift` and
`Button+Matrix.swift` are regenerated.

## The revision of Surface, applied

There is no glass Surface (the owner's scope, Q9).

Text only: no option, binding or code changes, so `tools/check.sh` passes with the current implementation. The
sentence "a surface never takes glass" stays, with its reason and where a group's glass comes from:

> … and a surface never takes glass (design-language/04, "Shadows"; 09, "Liquid Glass"): it is the ground of content,
> and glass is the layer of controls above it. The glass under a group of controls is the system's: a toolbar's or a
> bar's own group, from OS 26, or the system's GlassEffectContainer that a product writes around floating Buttons,
> from OS 26 too; a single control over content is a floating Button (decisions/0015).

## The pilot's uses, composed

Sketches for the decision only, in SwiftUI; `send`, the models and the menus' items are the pilot's. Icons are the
registry's names (`chevronLeft`, `ellipsis`, `plus`, `magnifier`, `microphone`).

**The list screen's back and "…", the system's bar (recommended, Q1).** The bar has no title, as the canvas; the back
is the list's own action, as the pilot's spec asks. Hiding the bar's back turns the edge swipe off as hiding the bar
does, so the pilot keeps its `EdgeSwipeBack`, the stack's pop, as it does now.

```swift
ListSurface(model: model, send: send)
    .navigationBarBackButtonHidden()
    .toolbar {
        ToolbarItem(placement: .topBarLeading) {
            Button { send(.backTapped) } label: { Label { Text("Back") } icon: { Icon(.chevronLeft) } }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu { MenuItems(model.showAs.menu, send: send) } label: {
                Label { Text("More") } icon: { Icon(.ellipsis) }
            }
        }
    }
    // iOS 26: each item on the bar's glass circle over the content, the scroll edge effect under them.
    // iOS 17 and 18: the system's bar with these two items.
```

**The same, floating (if the pilot keeps the bar hidden).**

```swift
content.overlay(alignment: .top) {
    HStack {
        Button { send(.backTapped) } label: { Label { Text("Back") } icon: { Icon(.chevronLeft) } }
            .buttonStyle(.secondary, size: .l, iconOnly: true, floating: true)
        Spacer()
        Menu { MenuItems(model.showAs.menu, send: send) } label: {
            Label { Text("More") } icon: { Icon(.ellipsis) }
        }
        .menuStyle(.button)  // iOS 16, macOS 13; Menu is unavailable on watchOS
        .buttonStyle(.secondary, size: .l, iconOnly: true, floating: true)
    }
    .padding(.horizontal, .space150)  // the pilot's 14 pt inset, in the nearest space token, the pilot's to choose
}
```

That a `Menu` in the button menu style takes westron's button style on iOS as the pilot's Mac code already does
(`.menuStyle(.button)` and `.buttonStyle(.plain)`) is measured at implementation; decisions/0014 already says "a
menu's button is a westron Button".

**The round "+".** On every OS version an accent circle over the content, casting `shadow.overlay`.

```swift
content.overlay(alignment: .bottomTrailing) {
    Button { send(.addTaskTapped) } label: { Label { Text("New task") } icon: { Icon(.plus) } }
        .buttonStyle(.primary, size: .l, iconOnly: true, floating: true)
        .padding(…)  // the pilot's margins, in space tokens
}
```

**The Lists screen's bottom bar, the system's bottom toolbar (recommended, Q10).**

```swift
.toolbar {
    if isEditing {
        ToolbarItemGroup(placement: .bottomBar) {  // one group: one piece of glass from iOS 26
            Button("List", systemImage: …) { send(.newListMenuItemChosen(in: nil)) }
            Button("Area", systemImage: …) { send(.newAreaMenuItemChosen) }
        }
        ToolbarItem(placement: .bottomBar) { Button("Done") { send(.doneTapped) } }
    } else {
        ToolbarItem(placement: .bottomBar) {
            Menu { MenuItems(model.more, send: send) } label: { Label { Text("More") } icon: { Icon(.ellipsis) } }
        }
        ToolbarItem(placement: .bottomBar) {
            TextField("Search", text: $query, prompt: Text("Search").foregroundStyle(.text.placeholder))
                .textFieldStyle(.inline, leadingIcon: .magnifier)  // #115; the microphone, an action, waits for a slot
                .accessibilityLabel("Search")
                .accessibilityAddTraits(.isSearchField)
        }
        ToolbarItem(placement: .bottomBar) {
            Menu { MenuItems(model.add, send: send) } label: { Label { Text("New") } icon: { Icon(.plus) } }
        }
    }
}
```

The inline field rather than the framed one, since the bar's glass is already its ground. The system's rule between
"+ List" and "+ Area" is none: the group is the system's. Whether the "+" and Done take the accent there is the
system's prominent item (`.buttonStyle(.glassProminent)`, iOS 26, tinted with the app's accent) or nothing; westron
does not restyle a toolbar's items (principle 1), and cobalt as the app's tint is chapter 09's open question 1.

**The Mac and iPad pane's "+" and "…", the toolbar's group.**

```swift
.toolbar {
    ToolbarItemGroup(placement: .primaryAction) {  // macOS 26 and iOS 26: one glass capsule for the group
        Button { send(.addTaskTapped) } label: { Label { Text("New task") } icon: { Icon(.plus) } }
        Menu { MenuItems(model.showAs.menu, send: send) } label: { Label { Text("More") } icon: { Icon(.ellipsis) } }
    }
}
```

The pilot's `GlassToolbarItem`, `sharedBackgroundVisibility(.hidden)`, `GlassCapsuleStyle` and its rule go; before
OS 26 the toolbar draws its own items, as for every Mac app.

**Floating buttons side by side, from OS 26** (no pilot use; for a product that needs one piece of glass outside a
bar):

```swift
if #available(iOS 26, macOS 26, watchOS 26, *) {
    GlassEffectContainer { row }  // the system's; the floating buttons' glass blends inside it
} else {
    row  // separate raised buttons before 26
}
```

## Open questions

Answered on 2026-11-23, every one with (A) ("Decision"); kept as asked. Each has the recommendation first, with its
reason; the contracts are drafted to the recommendations. Marked **owner**
where the answer changes a statement the owner made or accepted, or a decision of the pilot's that the owner made;
the others are the coordinating agent's to answer under decisions/0014.

**Q1 (owner: the pilot's decision of 2026-11-08). The list screen's back and "…" on the iPhone.**
- (A, recommended) The system's navigation bar, shown again with no title, its back hidden for the list's own back
  item and "…" a trailing `Menu`. From iOS 26 the bar draws them on glass circles over the scrolling content, which is
  the canvas's look, with the scroll edge effect instead of the pilot's fade; before 26 iOS 17's and 18's bar. System
  first (principle 1, decisions/0003); westron needs nothing for it.
- (B) Keep the bar hidden and float two westron buttons, `.buttonStyle(.secondary, size: .l, iconOnly: true,
  floating: true)`, as the pilot does now; the contract's floating secondary is drafted for this case.
- Either way the Button revision stands, for the round "+".

**Q2 (coordinator; answers design-language/09's open question 3 otherwise than the chapter's draft proposal). A
floating secondary before OS 26.**
- (A, recommended) An opaque raised surface: `color.background.surface`, `shadow.overlay`, the row tints, secondary's
  high-contrast outline. All in existing tokens, contrast declared and passing in every theme, westron's flat fills,
  nothing translucent for Reduce Transparency to change.
- (B) The system's `.regularMaterial`, a hairline and `shadow.overlay`: chapter 09's proposal and the pilot's fallback.
  The system adapts it to Reduce Transparency and Increase Contrast, but its contrast cannot be computed and no token
  names it; westron would draw a material nowhere else.
- (C) The plain secondary's muted fill and `shadow.overlay`: the least new, but the muted gray reads as a disabled
  control over a white card.

**Q3 (owner: scopes the owner's "Fills are flat and opaque, in westron's colors, with no glass or material",
decisions/0013 and Button's decisions/0003). Does a floating secondary stand on the system's glass from OS 26?**
- (A, recommended) Yes: the owner took glass into this phase for exactly these buttons (decisions/0006: "floating glass
  'back' and '…' buttons"; decisions/0014, #121), chapter 09 allows it through the system API, and next to the
  system's own glass bars an opaque circle would be the odd one out. The statement is scoped to buttons in a layout.
- (B) No: westron draws no glass at all; a floating secondary is Q2's fallback on every OS version, and glass stays in
  the system's bars. Simplest, one look, contrast computable everywhere; the pilot's circles lose their glass.

**Q4 (owner: the same statement). A floating primary, the round "+".**
- (A, recommended) Its opaque accent fill and `shadow.overlay` on every OS version, as the pilot's "+" is drawn today
  and as the owner's flat fills say.
- (B) From OS 26, accent-tinted interactive glass, `glassEffect(.regular.tint(accent).interactive())`, as the system's
  `.glassProminent` draws a prominent action; the opaque fill before 26.

**Q5 (coordinator). The label's color on glass.**
- (A, recommended) Button's tokens, `color.text.primary` and `color.status.danger.text`: no exception to rule 2, the
  danger role keeps its color, the high-contrast themes apply, and the pilot's ground is westron's own canvas in the
  same theme. Its test at implementation: a supplementary sheet with the floating secondary over a dark band in the
  light theme and a light band in the dark one; if the glass turns dark under dark content and the label stops reading,
  (B) replaces it.
- (B) The system's adaptive foreground (`.foregroundStyle(.primary)`, which glass turns light or dark with the content
  beneath), a marked exception to the raw-values rule; the danger role would lose its red on glass.

**Q6 (coordinator). Hover and pressed on glass.**
- (A, recommended) The interactive glass's own response, with no westron tint or scale: westron's tints are opaque
  and would cover the glass, and two press responses would stack.
- (B) Non-interactive glass, `.regular`, with westron's 98 % scale and a translucent tint, which needs a translucent
  token westron does not have.

**Q7 (coordinator). Disabled on glass.**
- (A, recommended) The whole button at `opacity.disabled`, as every Button: one rule, one parity record. To measure:
  whether the glass takes the opacity.
- (B) The label and the icon at `opacity.disabled` and the glass whole, as the system's `.glass` style is thought to
  draw it (not verified).

**Q8 (coordinator). Increase Contrast on glass.**
- (A, recommended) No westron outline on glass: the system adapts the glass to Increase Contrast (HIG Materials), and
  two edges would stack. To measure on iOS 26 and macOS 26 with the setting on; if the glass shows no edge, (B).
- (B) secondary's high-contrast outline on the glass too.

**Q9 (coordinator; reverses decisions/0014's "a glass Surface" for #121). Surface and glass.**
- (A, recommended) No glass variant: the glass under a group is a bar's group or the system's `GlassEffectContainer`,
  and a single control is a floating Button. Surface stays the ground of content, as its contract and chapter 09 say;
  no use is left for it after "System first".
- (B) `.surface(.glass)` for a group outside a bar, with a capsule shape option and the same fallback as Q2: for a
  product that draws its own bar, which the pilot would not under Q10's (A).

**Q10 (coordinator for westron's side; the pilot adopts it). The pilot's bars and its pane's capsule.**
- (A, recommended) The system's toolbars: the bottom bar at `.bottomBar`, the pane's "+" and "…" one
  `ToolbarItemGroup`, their glass the bar's from OS 26. Principle 1 and decisions/0014's "or the system's bottom
  toolbar" and "or the window toolbar's own group".
- (B) The pilot keeps its own bars over content, which then need Q9's (B) for the search field's and the group's glass.

**Q11 (coordinator). tertiary and floating.**
- (A, recommended) Forbidden by a constraint of severity `error`: tertiary has no fill to float on.
- (B) A floating tertiary is glass with an accent label: a third floating look with no consumer.

**Q12 (coordinator). The option's name.**
- (A, recommended) `floating`, the word decisions/0006, 0014 and chapter 09 use ("floats over content").
- (B) `overContent`, or `raised`, which Surface already uses for a card.

**Q13 (coordinator). The glyph of a floating icon-only button.**
- (A, recommended) Button's seating, the symbol's small scale in the label's font, for parity: at `l` on iOS, 50 pt
  across. The pilot's glyphs are larger (22 to 24 pt in 44 and 48 pt circles); the catalog's screenshot shows the
  difference at implementation, and a change would be a binding for every icon-only Button, not for floating alone.
- (B) A larger scale for floating icon-only buttons only.

## Gaps in the schema and the tools

Described, not built, except where "As built" says what the implementation did.

As built, 2026-11-23: G1 and G3 stay in Button's description, since no schema field is both small and general enough
to add for one option; G4 is `drawingButtonsWithoutGlass()`, `package` in `WestronUI` beside the catalog's other hooks
(`ButtonCatalogSupport.swift`), which the API parity lint does not see (it reads `public` and `open` declarations
only, as for `forcingButtonStates(_:)`); G5 is the two supplements above; G6 was not needed, since glass renders on
both paths; G8 is declared (`color.status.danger.border` on `background.hover`, 3.22 / 3.49 / 4.83 / 5.26, and on
`background.pressed`, 3.02 / 3.03 / 4.54 / 4.56, light / dark / light-hc / dark-hc, all passing).

- **G1. No field for an OS version.** The `platforms` block restricts per OS (`ios`, `macos`, `watchos`) but not per
  OS version, so "glass from 26, a surface before" is text in Apple's description, and the parity lint cannot hold the
  code to it. A possible shape: `platforms.apple.versions: [{ from: "26", description: … }]`, or a case key
  `os: { min: 26 }` in bindings, so that the fallback's bindings and the glass's absence of them are both data.
- **G2. A binding cannot name a system material.** On glass, `container.background` has no value and nothing says it
  is the system's glass; `token: null` means "nothing". A binding value such as `system: glass` would let `spec check`,
  the spec reviewer and the matrix know which cells stand on the system's material.
- **G3. A case has no contrast key** (as for secondary's high-contrast outline and Surface's line), so the fallback's
  outline is in the description.
- **G4. The matrix renders the runner's OS only** (iOS 27.0, macOS 27.0.1). The `else` branch of any `if #available`
  is never rendered. Proposal: a `package` override in `WestronUI` that a catalog supplement sets; to confirm that the
  API parity lint ignores `package` declarations.
- **G5. No ground for the matrix.** The generated sheets draw on the canvas; a translucent cell needs a busy ground.
  The hand-written supplement covers it; a contract key (an option whose cells the matrix draws over content) would
  make it generated.
- **G6. No way to mark a cell as not checkable on a platform**, should the macOS `CARenderer` path misdraw glass.
- **G7. A usage rule is not checkable**: "never in a system bar" is guidance; nothing can see where a product puts the
  button.
- **G8. Two contrast pairs are not declared**: `color.status.danger.border` on `color.background.hover` and on
  `color.background.pressed`, the fallback's high-contrast outline of a destructive floating secondary under the
  pointer and pressed. A declaration in the color tokens, at implementation.

## After approval: what else changes

Edited with the implementation, 2026-11-23:

- decisions/0013: the flat fills' sentence scoped to buttons in a layout (Q3, Q4).
- Button's decisions/0001, "Floating glass buttons", and decisions/0003, point 1: a note pointing here.
- design-language/09: "Liquid Glass" names the floating Button and the system's bars and `GlassEffectContainer`;
  open question 3 answered (Q2). design-language/04: `stroke.hairline` "edges glass" has no user; the token's
  description in `tokens/semantic/stroke.tokens.json` likewise. design-language/08: nothing changes.
- decisions/0014: the "Glass buttons" and "Bottom bar" rows, if Q9 and Q10 go as recommended.
- AGENTS.md: this decision in the list once it is accepted.

## Implementation: what was measured

On Apple, 2026-11-23, Xcode 27.1 on macOS 26.7.1, the iPhone 17 simulator on iOS 26.3 unless said. The CI runner,
which records the references, is on iOS 27.0 and macOS 27.0.1, so its pictures will differ from these in detail.

- **Glass renders in both of the matrix's paths.** iOS's `drawHierarchy` draws the system's glass as on screen; macOS's
  `CARenderer`, in a window never ordered in, draws it too, as a blurred and lightened ground with its edge. Rendered
  three times on each platform: macOS 208 of 208 pictures identical byte for byte, every time; iOS 463 to 466 of 468
  identical, the others differing in at most 4 pixels, of which at most one pixel in a picture by 2 levels, always on
  a generated `floating-true` sheet in `dark-hc`, where the glass stands on the plain canvas. The two supplements over
  the busy ground were identical in all three iOS renders. So the references hold glass on both platforms; on iOS a
  single pixel of a `dark-hc` floating sheet may now and then pass the check's tolerance of one level (seen in two of
  three pairs of renders), which the CI job `snapshots` would report as a change.
- **Buttons that do not float are unchanged.** The new code rendered with the contract before `floating` (its
  generated files and the catalog's matrix cell of then) against the render before the change: macOS 72 of 72
  pictures identical, iOS 152 of 152, at a tolerance of 0.
- **Before OS 26, for real.** The `button-floating` entry on an iPhone 15 simulator on iOS 17.5 draws every floating
  secondary on `background.surface` with `shadow.overlay`, its forced hover and pressed in the row tints, the pressed
  one scaled down: the same as the catalog's override draws on iOS 26.3, so the override's references stand for the
  minimum OS versions.
- **Disabled dims the glass.** The whole button at `opacity.disabled`, the glass with it, on both platforms (Q7 holds).
- **Increase Contrast** (the system's setting, through `simctl ui … increase_contrast`, on a separate iPhone 17 Pro
  simulator, iOS 26.3): the glass turns nearly opaque and light, with a faint edge; the label is the high-contrast theme's. westron draws no
  outline on it (Q8 holds). The matrix's high-contrast captures show the same glass.
- **Hit area.** On macOS a floating button takes clicks in its drawn capsule and none past it, on glass and before OS 26,
  every size (ButtonHitAreaTests). On iOS the behavior tests press the live floating buttons, find no press 4 points
  below one, and see the disabled one refuse a press (`behavior ios ButtonBehaviorTests`: 12 run, 1 skipped, 0
  failed). On macOS the same tests did not run: the Mac's screen was locked, so no app could be activated.
- **The accessibility audit** (iOS, the five configurations, `button-floating` and the entries it touches) passes with
  three suppressions of its own, each named in the log on every match: contrast on the enabled secondaries with a
  label on glass, which westron cannot promise over content it does not draw (the floating primary and the
  secondaries before OS 26 are audited as usual, and pass); contrast on the disabled samples (an inactive control);
  and "Text clipped" on the samples before OS 26 held pressed, whose frame is 0.98 of the unpressed one's, as the
  Chip's pressed sample is. The audit reports a button's text, which carries no identifier, so the samples on glass
  and before OS 26 carry different words to be told apart.
- **Not measured.** Reduce Transparency: set through the simulator's accessibility defaults, the glass looked
  unchanged, and nothing confirmed that the setting reached the app, so its effect is unknown. Reduce Motion: a still
  cannot show the glass's response to a press; westron's own press scale, which it drops, is not drawn on glass. The
  glass's response to a real touch and pointer, which forced states cannot show. watchOS at run time. On macOS, with
  the screen locked: the behavior tests, the accessibility audit, the catalog's screenshot and the system's focus ring
  over glass.

## Consequences

- westron gains one option on Button, no component, no token, no variant value; Surface keeps its rule.
- Every bar of the pilot takes the system's glass; the pilot's `GlassControlStyle`, `GlassCapsuleStyle`,
  `GlassToolbarItem` and its `.regularMaterial` bar go, and its floating buttons are Buttons.
- The implementation (#121's next step, `/implement-platform button apple`) starts by measuring glass in the matrix's
  two render paths, then adds the argument to `ButtonVariantStyle`, the supplements for the ground and the fallback,
  the catalog entry and the behavior tests (the press on glass, disabled, the hit area of a floating button).
