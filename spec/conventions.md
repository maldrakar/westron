# Platform conventions

Date: 2026-11-16. Status: draft for the owner's approval (#19). The owner decided five of its open questions in the
Button work (#22): the size and `controlSize`, the name of a state modifier, an unsupported value, the variant's
default and the shape of a bool option. They are rules now, and the remaining questions are renumbered.

A component contract (`spec/components/<id>/<id>.spec.yaml`) is neutral: options, states, slots, constraints, token
bindings, accessibility and a `platforms` block. This document is the one rule for how each of those concepts becomes
platform API. The Swift API generator (#20), the API parity lint (#21), the `spec-reviewer` subagent and every
component follow it, so no component decides the mapping again.

It applies [decisions/0001](../decisions/0001-shared-contract-not-shared-ui.md),
[0003](../decisions/0003-styles-on-system-controls.md), [0005](../decisions/0005-workflow.md),
[0008](../decisions/0008-apple-toolchain-and-catalog.md) and [0010](../decisions/0010-token-structure-and-modes.md),
and chapters [06](../design-language/06-layout.md), [08](../design-language/08-accessibility.md) and
[09](../design-language/09-platform-adaptation.md) of the design language. Where they override the research report,
they win: the report's draft table proposed a one-letter prefix and wrapper types on every platform, which
decisions/0003 rejected.

## How to read the table

- **SwiftUI is authoritative.** It is the pilot platform (decisions/0002), and its column is what #20, #21 and
  every Apple component implement now.
- **Web, GTK and Compose are provisional.** They record the expected mapping so that the contract does not quietly
  take on SwiftUI assumptions. They are confirmed in phase 6 (web, with #40 deciding the shape of the web library),
  phase 7 (GTK) and phase 8 (Compose), and checked first by the Button prototype on web and GTK (#26). Until then,
  a provisional cell is a direction, not a rule.
- **Two cases on every platform** (decisions/0003, chapter 09): when the platform has a system control, westron
  gives it a style and extensions; when it has none, westron builds its own component, named as in the contract with
  no prefix. A cell covers both cases where they differ.
- **"Q*n*"** points to an open question at the end. The cell then shows the options, not a decision.
- The examples use Button. Its real values are in its contract,
  [`spec/components/button/button.spec.yaml`](components/button/button.spec.yaml).

## The table

| Contract concept | SwiftUI (authoritative) | Web (provisional) | GTK: Rust + GTK4/libadwaita (provisional) | Compose (provisional) |
|---|---|---|---|---|
| **Component id and naming** | System control: no westron type. The contract binds to the system control (`Button`), and westron adds an overload of its style modifier. Own component: a `View` named after the id in UpperCamelCase (`empty-state` → `EmptyState`), no prefix. Generated types are `<Component><Option>`: `ButtonVariant`, `ButtonSize`. A name that would collide with a SwiftUI type is recorded in the `platforms` block (decisions/0003, point 3) | System control: the native element (`<button>`) with westron's CSS. Own component: a custom element, whose name must contain a hyphen, so it differs from the contract's and the `platforms` block records it; the namespace is decided in #40 | System control: the stock widget (`gtk::Button`) with westron's style classes and an extension trait. Own component: a GObject subclass, `Badge` in westron's crate; its GType name carries the library's namespace, as every GTK library's does, and the `platforms` block records it | System control: the Material3 composable inside `WestronTheme`. Own component: a `@Composable` function named after the id in UpperCamelCase. Where Material3 has a composable of the same name (`Badge`), the strategy differs from Apple's and the `platforms` block records it |
| **Enum option: the variant** | A generated `public enum ButtonVariant: String, CaseIterable, Sendable`; cases are the contract's values in lowerCamelCase. It is the first, unlabeled argument of the style overload and has no default, so it is always written: `.buttonStyle(.primary, size: .m)`, `.buttonStyle(.secondary)`; the contract gives the variant no default. A value must not match a system style's static name (`plain`, `bordered`, …); the validator checks it (#18). Another enum option is a labeled argument named after it. Own component: Q2 | A `variant` attribute and property on a custom element; on a native element a class or data attribute (#40) | A Rust `enum ButtonVariant { Primary, … }` that adds a CSS class: the stock class where one exists (`.suggested-action`, `.destructive-action`), westron's own otherwise. The value-to-class map is in the `platforms` block | A generated `enum class ButtonVariant { Primary, … }` passed as a parameter; the variant picks westron's colors and shape for the Material3 composable, through `ButtonDefaults`-style factories or the Compose Style API, decided in phase 8 |
| **Size option** | A generated `public enum ButtonSize` with the contract's values `s`, `m`, `l`, never `small/regular/large`. A labeled `size:` argument of the style overload. When the call leaves it out, the size comes from `@Environment(\.controlSize)`: `mini` and `small` → `s`, `regular` → `m`, `large` and `extraLarge` → `l`; an explicit `size:` wins. What `size:` does to `controlSize` inside the label is Q5 | A `size` attribute (`size="m"`) or a class, sizes in westron's CSS | A Rust `enum ButtonSize { S, M, L }` that adds westron's own size class: libadwaita has no size classes | `enum class ButtonSize { S, M, L }` as a parameter |
| **Bool option** | A labeled `Bool` argument of the style overload, named as in the contract, with the contract's default: `.buttonStyle(.primary, size: .m, iconOnly: true)`. Not an environment modifier, which would make the option look like a state, and not a system modifier the style cannot read (`.labelStyle(.iconOnly)`, see "Slots"). A bool that is a state follows the state rows | A boolean attribute, present or absent; an absent attribute is `false` (Q1) | A boolean GObject property, or a style class | A `Boolean` parameter with the contract's default |
| **States the system control has** (pressed, hover, focus, disabled) | The system owns them, and the style reads them: pressed is `configuration.isPressed`, disabled is `@Environment(\.isEnabled)` set by `.disabled(_:)`, focus is `@Environment(\.isFocused)`, hover is `onHover`. Touch iOS and watchOS never enter hover, and `onHover` does not exist on watchOS. The system draws the focus ring (chapter 08). Where states hold at once, the first matching case of a binding wins, as the contract orders them | CSS pseudo-classes: `:active`, `:hover`, `:focus-visible`, `:disabled`; a native element still matches `:hover` while disabled, and `:hover` and `:active` while `aria-busy`, so westron's CSS excludes what the contract excludes | CSS pseudo-classes `:active`, `:hover`, `:focus-visible`, `:disabled`; disabled is `set_sensitive(false)` | `interactionSource` (`collectIsPressedAsState`, `collectIsHoveredAsState`, `collectIsFocusedAsState`); disabled is the `enabled = false` parameter, Compose's positive name |
| **States the system control lacks** (loading) | A modifier sets an environment value, and the style reads it (decisions/0003): `.loading(isSaving)`. One shared modifier per state, named as the state, for every component that has it: `.loading(_:)`, not `.buttonLoading(_:)` | An attribute that is also the accessible state: `aria-busy="true"`, styled by westron's CSS | A westron style class plus the accessible state `gtk::AccessibleState::Busy` | A `Boolean` parameter (`loading = true`), as Compose passes per-component state; a cascading value would go through `CompositionLocal` |
| **Slots** | System control: the control's own `@ViewBuilder` label. The contract's `label` and `icon` are the title and the icon of a `Label` inside it: `Button { save() } label: { Label("Save", icon: .check) }`. Own component: a `@ViewBuilder` closure per slot, named after the slot, plus convenience initializers that take text and a `Westron.Icon`, as SwiftUI's `Label` does | The element's content; `<slot>` and `<slot name="icon">` in a custom element | Child widgets: `adw::ButtonContent` for an icon and a label; an own component exposes a child property per slot | `@Composable` lambda parameters: `content`, `icon: (@Composable () -> Unit)? = null` |
| **Constraints between options** | The contract states them (`when` / `require` / `severity`) and the validator checks the contract (#18). The catalog and the snapshot matrix (#24) leave out combinations a constraint forbids. What code does with a forbidden combination is Q3 | As SwiftUI: checked in the contract; runtime behavior with Q3 | As SwiftUI | As SwiftUI |
| **Token bindings** | Written by hand in the style's or the component's body (decisions/0001), through WestronUI's accessors: `.background(.background.accent, in: …)`, `.radius.control`, `.textRole(.body.strong)`, `.animation(.press, value: …)`. No raw values: the raw-values lint and the `spec-reviewer` subagent check them (decisions/0005) | CSS custom properties generated from the token paths (#39), read with `var(…)` in westron's CSS | libadwaita's variables (`--accent-bg-color`, …) and westron's `style.css` variables, both generated; Rust constants for values outside CSS | `WestronTheme` values through `CompositionLocal`, and a Material `ColorScheme` mapped from the tokens (chapter 09) |
| **Accessibility: role** | System control: it keeps its own role and traits (chapter 08). Own component: `.accessibilityElement(children:)` and `.accessibilityAddTraits` (`.isButton`, `.isHeader`, `.isSelected`, `.isToggle`) | The native element's implicit role; a custom element sets it through `ElementInternals.role` | The stock widget's role; an own widget sets `gtk::AccessibleRole` on its class | The Material composable's semantics; an own component sets `Modifier.semantics { role = … }` |
| **Accessibility: intents** | `.accessibilityLabel`, `.accessibilityValue`, `.accessibilityAction(named:)`, `.accessibilityAdjustableAction`, `.accessibilityAction(.escape)` for dismiss | ARIA states and properties, and events | `update_property` and `update_state` (`gtk::AccessibleProperty`, `gtk::AccessibleState`); `GtkAccessible` documents no custom accessible actions, so how a named action reaches Orca is decided in phase 7 | `semantics { stateDescription, customActions, onClick(label = …) }` |
| **Accessibility: keyboard intents** | System control: the system handles activation and focus. Own component: `.focusable()`, `.onKeyPress` (iOS 17, macOS 14; not on watchOS), `.keyboardShortcut` (not on watchOS); on macOS also `.onMoveCommand` and `.onExitCommand`. On watchOS the Digital Crown: `.digitalCrownRotation` | Native behavior; a custom element handles `keydown` and sets `tabindex` | Native behavior; an own widget adds a `gtk::ShortcutController` or `gtk::EventControllerKey`, and mnemonics | `Modifier.focusable()` and `Modifier.onKeyEvent` |
| **The `platforms` block and recorded differences** | The Apple entry names the strategy (a style on a system control, or an own component), the base control, and what each of iOS, macOS and watchOS supports, with a reason for each deviation; the fields come with #18. Code that one OS needs goes behind `#if os(…)`. The parity lint (#21) compares the public API with the contract and this block. A value an OS does not support keeps its enum case on every OS, and the style falls back to the value the block's `fallback` names: a watch draws `.buttonStyle(.primary, size: .l)` at `m` | The web entry: element or custom element, its name, attribute names | The GTK entry: base widget, variant-to-class map, own size classes | The Android entry: the Material3 composable used, deviations |
| **Defaults** | An option's contract default is the argument's default value. An option with no default in the contract is a required argument: the variant has none, so it is always written. The size is the exception: left out, it comes from `controlSize`, and its contract default is the size `regular` maps to, `m` | An absent attribute means the contract's default; an option without one is a required attribute | The property's default | The parameter's default value, in a `<Component>Defaults` object where Compose expects one |
| **Modes: theme, contrast, density** | Not options: a contract has no density option (chapter 00, principle 4). Theme and contrast switch in the colorsets by themselves (decisions/0010). Density is an environment value set by a `density` modifier; its API arrives with #33 | `prefers-color-scheme`, `prefers-contrast`; density as a class or custom property on an ancestor | libadwaita's `StyleManager` for the dark style and high contrast; density as a style class on an ancestor | `WestronTheme` and `CompositionLocal` |

## SwiftUI rules and their reasons

### A style on the system control, not a wrapper

```swift
Button("Save") { save() }
    .buttonStyle(.primary, size: .m)
```

A system control keeps focus, keyboard support, VoiceOver traits, Liquid Glass adaptation and the next OS release
(chapter 09). A wrapper type would rebuild them, and its name would collide with `SwiftUI.Button` in every file that
imports SwiftUI. So westron has no wrapper types and no prefix (decisions/0003). The product writes the system
control, and westron adds one modifier.

### Generated enums, a generated signature, a hand-written style

`tools/westron generate` (the `components-apple` generator, #20) generates, from every contract that is approved or
later and whose Apple strategy is `style-on-system-control`, the enums and the signature of the overload, into
`WestronUI/Generated/<Component>+Contract.swift`; the body of the style is written by hand (decisions/0001). For
Button, without its doc comments:

```swift
public enum ButtonVariant: String, CaseIterable, Sendable {
    case primary
    case secondary
    case tertiary
}

public enum ButtonSize: String, CaseIterable, Sendable {
    case s
    case m
    case l
}

extension View {
    public func buttonStyle(_ variant: ButtonVariant, size: ButtonSize? = nil, iconOnly: Bool = false) -> some View {
        buttonStyle(ButtonVariantStyle(variant: variant, size: size, iconOnly: iconOnly))
    }
}

extension ButtonSize {
    init(_ controlSize: ControlSize)  // mini, small → s; regular → the default, m; large, extraLarge → l
    var offered: ButtonSize  // the size this OS draws: on watchOS every size draws m
}

extension ButtonVariant {
    var offered: ButtonVariant  // every OS offers every variant: the value itself
}

enum ButtonState: String, CaseIterable, Sendable {
    case hover, focus, pressed, disabled, loading  // one per line in the file
    var isEntered: Bool  // whether this OS ever enters it: watchOS never enters hover
}
```

- **What the generator writes, and what it leaves.** The public API is the enums and the overload. The overload is
  `<control>Style`, after the base control (`SwiftUI.Button` → `buttonStyle`), and applies the hand-written
  `<Component>VariantStyle`, initialized with every generated option, labeled, in the contract's order. The rest is
  internal tables the hand-written style reads instead of copying the contract: the `controlSize` mapping, `offered`
  for every enum option (its restrictions and fallbacks on each Apple OS, as `#if os(…)`), and `<Component>State`
  with `isEntered`. The hand-written style switches over these enums exhaustively, so a value renamed, added or
  removed in the contract fails the build there until the style follows it (#20). A draft contract generates nothing,
  so a contract in review never breaks the build, and an own component waits for Q2.
- **An option that is the system's own API gets no type.** The Apple entry names it in `systemOptions`, with the
  system type that carries it: Button's `role` is `systemOptions: { role: SwiftUI.ButtonRole }`, so no `ButtonRole`
  is generated, which would shadow SwiftUI's, the overload takes no `role:`, and the style reads
  `configuration.role`. A generated name that would shadow a SwiftUI type of the base control fails generation and
  points at `systemOptions`.
- **The names come from the contract.** The enum is `<Component><Option>` in UpperCamelCase. A case is the
  contract's value in lowerCamelCase. Renaming a value in the contract breaks the build (#20).
- **`String` raw values** are the contract's values as written, so the catalog, the snapshot matrix (#24) and the
  parity lint (#21) can match a case to the contract.
- **The variant is unlabeled, every other option is labeled.** `.buttonStyle(.primary, size: .m)` reads as SwiftUI's
  own `.buttonStyle(.bordered)` does, and the other options say what they are. A bool option is a labeled `Bool`
  with the contract's default: `iconOnly: true`. The variant is the enum option named `variant`, the size the one
  named `size`; an option without a default is a required argument, and one with a default takes it, except the size.
- **The variant is always written.** There is no `.buttonStyle(size: .s)`: a call names its variant, so the code
  says which action is the primary one, and a reader never has to know a default. The contract gives a variant no
  default, and the schema allows an enum option without one.
- **No value may share a name with a system style of the same control.** With westron's overload in scope,
  `.buttonStyle(.plain)` would be ambiguous (decisions/0003). The validator rejects such a value (#18).

### Sizes and `controlSize`

The contract's sizes are `s`, `m`, `l` on every platform. SwiftUI's own sizes are `mini`, `small`, `regular`,
`large` and `extraLarge`, set by `controlSize(_:)` and cascaded through the environment. westron chooses parity
over idiom for the names (decisions/0003) and keeps the cascade: an explicit `size:` wins, and a call without one
takes its size from `@Environment(\.controlSize)` (`.claude/rules/apple.md`):

| `controlSize` | `mini` | `small` | `regular` | `large` | `extraLarge` |
|---|---|---|---|---|---|
| westron's size | `s` | `s` | `m` | `l` | `l` |

- **Nothing set reads as `regular`.** SwiftUI cannot tell "not set" from "set to `regular`", so a contract's default
  size is the one `regular` maps to: `m`. The generator maps `regular` to the default, so a size option needs one,
  and maps any other `ControlSize` whose westron size the contract does not declare to the default too.
- **A size a platform drops falls back.** On a watch, where Button offers only `m`, the size from `controlSize` falls
  back as an explicit one does (below).

All five `ControlSize` cases exist on the minimum OS versions, but `ControlSize` is `Comparable` only from OS 26, so
the mapping is a `switch`, not a comparison.

### A value a platform does not support

The generated enum is one for every Apple OS, so it keeps every case the contract declares. Where an OS drops a
value, the `platforms` block names its fallback, and the style draws that value instead: on watchOS, which offers
only `m`, `.buttonStyle(.primary, size: .l)` compiles and draws `m`. The call never fails to compile on one OS only,
and the validator requires a fallback for every value Apple drops (#18).

### States: what the system has, the style reads; what it lacks, a modifier sets

```swift
// Hand-written. Illustrative tokens: the Button contract (#22) binds the real ones.
struct ButtonVariantStyle: ButtonStyle {
    let variant: ButtonVariant
    let size: ButtonSize?  // nil: from controlSize
    let iconOnly: Bool

    func makeBody(configuration: Configuration) -> some View {
        ButtonBody(configuration: configuration, variant: variant, explicitSize: size, iconOnly: iconOnly)
    }
}

private struct ButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let variant: ButtonVariant
    let explicitSize: ButtonSize?
    let iconOnly: Bool  // the style hides the title and draws a square; VoiceOver still reads the title

    @Environment(\.controlSize) private var controlSize  // the size when the call names none
    @Environment(\.isEnabled) private var isEnabled  // disabled: set by .disabled(_:)
    @Environment(\.isFocused) private var isFocused  // focus: the system draws the ring
    @Environment(\.isLoading) private var isLoading  // loading: set by westron's modifier
    @State private var isHovered = false  // hover: never entered on touch iOS and watchOS

    /// An explicit size wins; otherwise mini and small → s, regular → m, large and extraLarge → l.
    private var size: ButtonSize { explicitSize ?? ButtonSize(controlSize) }

    /// A disabled or loading button never enters hover or pressed: its fill stays as at rest.
    private var isTinted: Bool { isEnabled && !isLoading && (isHovered || configuration.isPressed) }

    var body: some View {
        // With iconOnly, westron's label style hides the title, which stays the accessible label, and the frame is
        // a square of the height.
        configuration.label
            .textRole(.body.strong)
            .foregroundStyle(.text.onAccent)
            .padding(.horizontal, .space200)
            .background(
                isTinted ? .background.accentHover : .background.accent,
                in: RoundedRectangle(cornerRadius: .radius.control, style: .continuous)
            )
            .overlay { if isLoading { ProgressView() } }
            .animation(.press, value: configuration.isPressed)
            #if !os(watchOS)
                .onHover { isHovered = $0 }
            #endif
    }
}
```

- **States the system control has stay the system's.** `isPressed`, `isEnabled` and `isFocused` are the system's
  own; westron's style only draws them. A product disables a westron button the way it disables any button:
  `.disabled(true)`.
- **Hover is a state, not a variant.** Touch iOS and watchOS simply never enter it, so one state model holds on
  every platform (research report). `onHover` does not exist on watchOS, so it sits behind `#if !os(watchOS)`.
- **States can hold at once, and the contract resolves them.** A component can be loading and hovered, or disabled
  and focused. A case's `state` matches when the component is in any of the states it names, and the first matching
  case wins, so a contract puts the states that exclude others first: a disabled or loading Button never draws hover
  or pressed.
- **A state the system control lacks goes through the environment** (decisions/0003). A modifier sets the value,
  the style reads it, and it cascades like `.disabled(_:)`:

  ```swift
  extension EnvironmentValues {
      @Entry var isLoading = false
  }

  extension View {
      public func loading(_ isLoading: Bool) -> some View {
          environment(\.isLoading, isLoading)
      }
  }

  Button("Save") { save() }
      .buttonStyle(.primary, size: .m)
      .loading(isSaving)
  ```

  The contract says what the state does, for example that a loading button does not act and is announced as busy.
- **One modifier per state, shared by every component.** `.loading(_:)` is named as the contract's state, as
  `.disabled(_:)` is, and it cascades over every component in the subtree that has the state. There is no
  `.buttonLoading(_:)`: the state's name is the same in the contract and in code.

### Slots through the system control's label

A system control already has a `@ViewBuilder` label, and westron uses it rather than adding parameters. The
contract's `label` and `icon` slots are the title and the icon of a `Label`:

```swift
Button { save() } label: {
    Label("Save", icon: .check)
}
.buttonStyle(.primary, size: .m)
```

The style lays the slots out, through a `LabelStyle` of its own where it must place the icon and the title
differently from the system. Icon-only is the style's own argument, `.buttonStyle(.primary, iconOnly: true)`: the
style hides the title, keeps it as the accessible label and draws the square.

A product's own `.labelStyle(.iconOnly)` cannot do this. The label style is an environment value, so the label style
westron's `ButtonStyle` applies to `configuration.label` inside `makeBody` overrides the product's outer one, and a
`ButtonStyle` has no public way to read the outer label style, so it could not know to draw the square either. A
probe on macOS confirmed both (#22).

### Own components, when no system control exists

When the platform has no control for the job (Badge, Banner, EmptyState), westron builds a `View` named as in the
contract, with no prefix (decisions/0003, point 2):

```swift
// Signatures only; EmptyState's contract decides its slots.
public struct EmptyState<Title: View, Actions: View>: View {
    public init(@ViewBuilder title: () -> Title, @ViewBuilder actions: () -> Actions)
}

extension EmptyState where Title == Text {
    public init(_ title: LocalizedStringKey, @ViewBuilder actions: () -> Actions)
}
```

- **Slots are `@ViewBuilder` closures**, one per slot, named after it, with initializers that take text and a
  `Westron.Icon` for the common case, as SwiftUI's `Label` does. An optional slot is an initializer without it, not
  an optional closure.
- **Options** use the same generated enums. Whether they are initializer parameters or a style modifier on the
  component is Q2.
- **States.** An interactive part of an own component is a system control inside it, such as a Banner's dismiss
  `Button`, so its pressed, hover, focus and disabled states are the system's. A state the system lacks goes
  through the environment, as above.
- **Accessibility.** An own component declares its role, label, value, states and actions from the contract's
  `accessibility` block (chapter 08), through the modifiers in the table.

### Token bindings stay in code, through the accessors

The contract binds tokens to parts, variants and states. The body of a style or component applies them with
WestronUI's accessors, never raw values (AGENTS.md, rule 2). decisions/0001 lists enums and style signatures as the
generated layer and style bodies as written natively, so the bindings are not generated; `spec-reviewer` checks them
against the contract.

### Minimum OS

The minimum is iOS 17, macOS 14 and watchOS 10 (decisions/0008). Every API in this document exists there, except
where the table names a platform it lacks: `onHover`, `onKeyPress` and `keyboardShortcut` are not on watchOS, and
`onMoveCommand` and `onExitCommand` are macOS only. Code that uses one of them goes behind `#if !os(watchOS)` or
`#if os(macOS)`, or the watchOS build fails. Newer API, such as Liquid Glass, goes inside
`if #available(iOS 26, macOS 26, watchOS 26, *)` with a fallback.

## Open questions

The owner decided the former questions 1, 2, 6 and 7 in the Button interview (#22), and the shape of a bool
option in its review; the rules above hold them. The rest are renumbered: question 1 keeps what the bool question
left open, and the last one what the size question left open.

1. **The default of a bool option.** A bool option is a labeled `Bool` argument with the contract's default (the
   table). Should the contract require every bool option to default to `false`? An HTML boolean attribute can only
   express that default.
2. **Options of an own component.** (a) Initializer parameters, `Badge("3", variant: .info)`: the report's
   parity-first shape. (b) A style modifier on the component, `Badge("3").badgeStyle(.info)`, cascading through the
   environment: the same call shape as a system control, and a later system control could replace the own component
   without changing call sites.
3. **A forbidden combination in code.** (a) Nothing beyond the validator, the catalog and the snapshot matrix.
   (b) `assertionFailure` in debug builds and a fallback the contract names. (c) Overloads that make the combination
   fail to compile, at the cost of an overload per allowed combination.
4. **The visibility of the hand-written style.** Internal, so that the public API is exactly what #20 generates and
   #21 checks; or public, so that a product can compose it.
5. **`controlSize` beyond the mapping.** Does an explicit `size:` also set `controlSize` for the system controls
   inside the label, such as the loading `ProgressView`? Does the `compact` density also set `controlSize(.small)`
   on its subtree (chapter 06, question 2)?
