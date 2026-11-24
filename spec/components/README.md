# Component contracts

Each component is a folder `spec/components/<id>/`:

| File | What it is |
|---|---|
| `<id>.spec.yaml` | The contract: options, states, slots, constraints, token bindings, accessibility, the `platforms` block |
| `decisions/` | Decisions about the component, with the options considered |
| `reference/` | Reference screenshots approved by the human |

A new contract starts with the `/new-component` skill. The first contract is Button,
[`button/button.spec.yaml`](button/button.spec.yaml), approved by the owner on 2026-11-16 (#22). Text,
[`text/text.spec.yaml`](text/text.spec.yaml), approved by the owner on 2026-11-18 (#27), is the first contract with an
option whose values are tokens and with an extension of a system view. Surface and Rule
([`surface/`](surface/surface.spec.yaml), [`rule/`](rule/rule.spec.yaml), #29), approved on 2026-11-18 under the
owner's delegation, are the first own components, one a modifier and one a view, and the first with no role of their
own. Icon ([`icon/`](icon/icon.spec.yaml), #28), approved on 2026-11-19 under the owner's delegation, is the first
with an option whose values are the icon registry's names, an own view on Apple. TextField
([`text-field/`](text-field/text-field.spec.yaml), #30), approved on 2026-11-18 under the owner's delegation, is the
first style on the system's text field and the first that draws its own focus ring, on iOS and macOS, by the owner's
decision. Checkbox ([`checkbox/`](checkbox/checkbox.spec.yaml), #31), approved on 2026-11-18 under the owner's
delegation, is the first whose control has a value that is on or off and the first that takes a value from its
context (the list's color). Rule's revision of 2026-11-22 (#116, approved by the coordinating agent under the owner's
delegation) is the first with a drawn text label on a view, a constraint on a slot and the role `heading`. IconTile
([`icon-tile/`](icon-tile/icon-tile.spec.yaml), #118), approved on 2026-11-22 by the coordinating agent under the
owner's delegation (decisions/0014), is an own view with Icon's shape whose nil list color is its own default, a
neutral tile, and whose fill of a list's color is solid, as the owner chose. Chip ([`chip/`](chip/chip.spec.yaml),
#117), approved on 2026-11-22 by the coordinating agent under the owner's delegation, is the first in several forms,
each on its own system control, and the first with a case over several states at once. TextField's revision of
2026-11-22 (#115, approved by the coordinating agent under the owner's delegation, text-field/decisions/0003) adds
the options leadingIcon and trailingIcon, decorative glyphs at the field's start and end, so that a search field is
this field; they are no axis of the generated snapshot matrix. ListRow ([`list-row/`](list-row/list-row.spec.yaml),
#119), approved on 2026-11-22 by the coordinating agent under the owner's delegation, is the core row a product
composes its rows from (decisions/0014): the first own view in two forms, with an action and without, the first with
a mark (`marks: insertion`, Rule's insertion point over its edge) and the first that holds other components in its
slots; its revision of 2026-11-24, after the review of phase 4, says that a disabled row dims what it holds once and
leaves its branch's fold to the chevron's group, and that the trailing slot stands in the row's padding as the
leading one does and keeps its own width, up to half the row's, beside the title. Disclosure
([`disclosure/`](disclosure/disclosure.spec.yaml), #120), approved on 2026-11-22 by the coordinating agent under the
owner's delegation, is the first component an Apple OS lacks (`watchos: { status: unavailable }`, as SwiftUI has no
DisclosureGroup there), the first with the role `disclosure`, and the first that sets a context for other components
(`context: alignsLeaves`, which ListRow reads). Button's revision of 2026-11-23 (#121, the owner's answers and the
coordinating agent's, decisions/0015 at the repository's root) adds the option `floating`, the first look that stands
on the system's glass and the first `container.shadow` on a control.

## Format

The schema is [`spec/schema/component.schema.json`](../schema/component.schema.json) (JSON Schema 2020-12); the
contract is written in YAML (decisions/0004). In short:

```yaml
id: button                      # lowercase words joined by hyphens; the file is button/button.spec.yaml
status: draft                   # draft → approved → stable → deprecated
consumers: [todo-app/list-screen]   # <product>/<screen>, at least one (decisions/0006)
options:                        # no option is named `state`: cases use that key for states
  variant: { type: enum, values: [primary, secondary] }   # no default: every use names a value
  size: { type: enum, values: [s, m, l], default: m }
  role: { type: enum, values: [default, destructive], default: default }
  iconOnly: { type: bool, default: false }
slots: [label, icon]
states: [hover, focus, pressed, disabled, loading]
constraints:
  - { when: { iconOnly: true }, require: { size: [m, l] }, severity: warning }
  # A rule on a slot (Rule): when an instance fills it, the options take one value each.
  # - { when: { slots: [label] }, require: { axis: horizontal, purpose: separator }, severity: error }
tokens:                         # by <part>.<property>, in one of three forms
  container.radius: radius.control                 # 1. one token
  label.font: { s: typography.footnote.strong, m: typography.body.strong, l: typography.body.strong }
                                                   # 2. one token per value of one enum option
  container.background:                            # 3. cases: the first whose `when` matches applies,
    token: color.background.muted                  #    else `token`; without `token`, no value
    cases:
      - { when: { variant: primary, role: destructive }, token: color.status.danger.fill }
      - { when: { variant: primary, state: [hover, pressed] }, token: color.background.accent-hover }
      - { when: { variant: primary }, token: color.background.accent }
      - { when: { variant: secondary, state: disabled }, token: null }    # null: no value in this case
      # - { when: { state: { all: [checked, pressed] } }, token: … }   # in every one of the states at once
accessibility:
  role: button
  intents: [activate]
  keyboardIntents: [activate]
  label: required               # an accessible label even when none is visible; or optional
  states: { loading: busy }     # the abstract state assistive technology announces in a state
platforms:                      # all four; each is `status: planned` or a strategy
  apple:
    strategy: style-on-system-control   # or extension-on-system-control, or own-component, which has no base
                                        # (decisions/0003) and names its form: modifier or view
    base: SwiftUI.Button
    systemOptions: { role: SwiftUI.ButtonRole }   # options that are the system's own API: no type is generated
    macos: { keyboardIntents: [defaultAction, cancelAction] }   # added to accessibility.keyboardIntents
    watchos:
      options: { size: [m] }    # the values it offers
      fallback: { size: m }     # what the dropped values become: one value, or { s: m, l: m }
      states: [pressed, disabled, loading]   # the states it enters
      description: Why it differs.
  web: { status: planned }
  linux: { strategy: style-on-system-control, base: GtkButton }
  android: { status: planned }
```

An enum option without a `default` must be named in every use; a variant has none (`spec/conventions.md`).
Names of options, values, slots, states, forms and intents are lowerCamelCase: they become identifiers on every
platform. Swift, the pilot platform's language, cannot use a few words there: no value, state or form is `init`,
`self` or `none`, and no option is `inout`, `var` or `let` (an option becomes an argument label). Other Swift keywords
are fine.
`description` is allowed on the contract, an option, a constraint, `accessibility`, a platform and an Apple OS.

- **YAML words.** A boolean is `true` or `false`. YAML 1.1 also reads an unquoted `yes`, `no`, `on` and `off`
  (lowercase, capitalized or uppercase) and `True`, `TRUE`, `False`, `FALSE` as booleans, so they are errors wherever
  they stand; a name that is such a word, or a number, is quoted: `values: [auto, "on", "off"]`.
- **Bindings by value.** A map from the values of one enum option gives every value of it a token. A binding that
  leaves some values without one is written as cases, with `token: null` where there is none.
- **Cases.** A case's `when` takes the same values as a constraint's (one value, a list, or `true`/`false` for a bool
  option) plus the key `state`, which names one state or a list of them. Cases apply first match, so a case is never
  used when every combination it matches is matched by an earlier case, by one alone or by several together
  (`{ iconOnly: true }` and `{ iconOnly: false }` before anything); the check reports it and names those cases. A
  component can be in several states at once, or in none; `state` matches when it is in any of the named ones, and a
  case without `state` matches every set of states. So a state that excludes others goes first, and the narrower case
  before the wider one.
- **Cases over several states at once.** `state: { all: [checked, pressed] }` matches only when the component is in
  every one of the named states, two or more: a tint that depends on two states, such as a lit chip that darkens when
  pressed (Chip). It goes before the cases over one of its states, which would otherwise cover it. The check of such
  a binding enumerates every set of the states its cases name, 2ⁿ for n states, times the combinations of the
  options they name, and reports a binding past 20 000 of them instead of checking it: with 15 states named, it is
  past the limit with no option. A binding without such a case is checked as before, without enumerating states.
- **Forms.** A component whose one look a product reaches through several system controls, picked by the control it
  writes, names them in `forms`: each form with the states it enters, a subset of `states`, and, where it announces
  something else, an `accessibility` whose fields replace the contract's for that form (Chip: `selectable` on a
  toggle, `pressable` on a button, `static` on a label, which adds no role). Every declared state is entered by some
  form, and the rules of `accessibility` hold for each form's (a form with role `none` takes no intents, announced
  states or required label; it announces only states it enters). Each platform with a strategy names a base per form
  in `bases`, `{ selectable: SwiftUI.Toggle, pressable: SwiftUI.Button, static: SwiftUI.Label }`, in place of
  `base`, and `bases` belongs only to a contract with forms. On Apple each base is checked as `base` is
  (`SystemStyles`, its strategy, no value a system style of it), and the conventions derive forms only for
  `style-on-system-control`: one overload per base, each applying its own style (`spec/conventions.md`, "Forms").
  The snapshot matrix draws each form on a sheet of its own, in the states it enters.
- **Restrictions.** A platform, or an Apple OS (`ios`, `macos`, `watchos`), restricts the contract with `options` (the
  values of an enum option it offers) and `states` (the states it enters); what it does not name, it keeps whole. An
  Apple OS restricts what Apple keeps.
- **Fallbacks.** `fallback` says what a dropped value becomes on that platform. On Apple every value needs to reach
  one each OS offers, since the OSes share one generated enum: Apple's fallback applies first, to the values all of
  Apple drops, then the OS's, to what the OS drops of what Apple keeps. With Apple's `options: { size: [m, l] }`,
  `fallback: { size: l }` and watchOS's `options: { size: [m] }`, `fallback: { size: { l: m } }`, `s` draws `l` on
  iOS and macOS and `m` on watchOS; watchOS maps only `l`, since `s` is Apple's to map. Elsewhere a fallback is
  optional.
- **Keyboard intents.** A platform or an Apple OS lists in `keyboardIntents` only what it adds to the component's.
- **Options whose values are tokens.** `role: { type: tokens, group: typography }` takes as its values the tokens
  under the group, each by its path after the group: `heading.large` for `typography.heading.large`. The contract
  does not list them, so it cannot drift from `tokens/`; on Apple the values are the token accessor's names
  (`.textRole(.heading.large)`). `default`, when given, is one of them; without it, every use names one. Constraints,
  cases, bindings by value and platform restrictions do not name such an option yet: its values have dots, which a
  name cannot (Text, the first such contract, needs none of them). Nor is it a system option: its values are
  westron's tokens, not a system type's.
- **Options whose values are icons.** `glyph: { type: icons }` takes as its values the names of the icon registry,
  [`spec/icons/icons.yaml`](../icons/icons.yaml), in its order: `tray`, `sun`, `chevron`. The contract does not list
  them, so it cannot drift from the registry, which `tools/westron icons check` validates. It has no default: every
  use names its glyph (the registry's own `default` is what draws for a name a version does not know). As with tokens,
  constraints, cases, bindings by value and platform restrictions do not name such an option yet, and it is never a
  system option. Icon, the first such contract, needs none of them. With `optional: true` a use may name no glyph,
  and then none is drawn: TextField's `leadingIcon: { type: icons, optional: true }`, the glyph at a field's start
  (#115). It is allowed only on a style on a system control, which takes it as an argument that defaults to none; an
  own view's glyph is always named. An optional one is no axis of the snapshot matrix (below).
- **Constraints on a slot.** A constraint's `when` may name, under the key `slots`, the slots an instance fills
  instead of options: `{ when: { slots: [label] }, require: { axis: horizontal, purpose: separator }, severity:
  error }` says that a labelled rule is a horizontal separator. It is as narrow as what the conventions derive from
  it: it names slots the contract declares and no option in its `when`, its severity is `error`, and it gives each
  enum option it requires one value, which an instance that fills the slots takes; on Apple the initializers that
  take the slot leave those options out (`spec/conventions.md`, "Own components"). The conventions derive that only
  for an Apple `own-component` of form `view` whose one slot is `label`, drawn text, with no option whose values are
  icons (Rule), so on any other contract, such as a style, a modifier or an icon's view, it is an error: nothing would
  enforce it. No option is named `slots`. The snapshot matrix draws no slot, so it leaves out nothing for such a
  constraint.
- **No role of its own.** `accessibility.role: none` is a component that adds no role for assistive technology, as
  ARIA's `none`: its content, if it has any, is read as if the component were not there (Surface), and a component
  with no content is hidden. No contract has that shape yet: an unlabelled Rule is hidden too, but its role is
  `heading`, and it is hidden because it has no label to announce. Such a component has nothing to act on or
  announce, so it takes no `intents`, `keyboardIntents` (its own or a platform's), `states` under `accessibility`
  and no `label: required`.
- **A value that is on or off.** A control whose value is on or off, the system `Toggle` that Checkbox styles, is in
  the state `checked` when it is on and in none of it when it is off; `accessibility.states` announces it
  (`checked: checked`). The control carries it itself, as it carries `pressed` (`SystemStyles`), so no westron
  modifier sets it.
- **Extensions of a system view.** `strategy: extension-on-system-control` is for a system control or view, named in
  `base`, that takes no style: SwiftUI has no `textStyle`, so westron adds a modifier to `SwiftUI.Text` instead of a
  style (decisions/0003, point 1). On Apple its base is one of `SystemStyles.withoutStyle`, and a base that has a
  style modifier takes `style-on-system-control` instead (`spec/conventions.md`).
- **System options.** A platform names in `systemOptions` the options its system control already carries in its own
  API, each with the type that carries it, such as `role: SwiftUI.ButtonRole`. The generator makes no type and no
  argument for them; the style reads them from the control (`spec/conventions.md`). Their values are the system's, so
  that platform, and on Apple an Apple OS, does not restrict them or give them a fallback.

## Generated API

`tools/westron generate` writes, for every contract that is approved or later and whose Apple strategy is
`style-on-system-control`, `platforms/apple/Sources/WestronUI/Generated/<Component>+Contract.swift`: the enums of its
options (`ButtonVariant`, `ButtonSize`), the overload of the base control's style modifier
(`.buttonStyle(.primary, size: .m)`), which applies the hand-written `<Component>VariantStyle`, and the tables that
style reads (the `controlSize` mapping, each OS's fallbacks, the states). Its exact form is in
[`spec/conventions.md`](../conventions.md). A draft contract generates nothing.

An approved `own-component` names the shape of its API in `platforms.apple.form`, which the schema requires of it and
forbids on a style or an extension: `modifier`, a modifier on `View` named after the component (`.surface(.raised)`), or
`view`, a `View` named after it (`Rule(axis: .vertical)`). The generator writes the enums of its enum options alone into
`WestronUI/Generated/<Component>+Contract.swift` (`SurfaceVariant`, `RuleAxis`); the modifier or the view is
hand-written, and the API parity lint expects its signature from the contract: the variant unlabeled first and every
other option labeled with its default for a modifier, every option labeled with its default for a view's `init`, which
conforms to `View` alone and has `public var body: some View`. States, a `size` option, an option whose values are
tokens, icons on a modifier, a restriction of Apple or an Apple OS, more than one slot for a modifier, and a variant or
slots other than the one slot `label` for a view fail generation and the lint as not derived yet
([`spec/conventions.md`](../conventions.md), "Own components"). A view takes an option whose values are icons as its
first, unlabeled argument, `Westron.Icon`, and the slot `label` as a spoken label (Icon: `Icon(.tray)`, `Icon(.sun,
label: "Today")`); a view without such an option takes the slot `label` as drawn text, first and unlabeled, localized or
not, without the options a constraint on the slot fixes (Rule: `Rule()`, `Rule(axis: .vertical, purpose: .insertion)`,
`Rule("WORK")`); `systemOptions` are the system's environment modifiers, no parameter and no enum (Icon's `scale`,
`.imageScale(_:)`).

An approved `extension-on-system-control` gets no file in `WestronUI/Generated/`: its modifier is hand-written, its
argument is the token accessor the token generator already writes, and the API parity lint expects its signature from
the contract (Text: `.textRole(_: Westron.TextRole)` on `View`, and its twin on `Text`, which returns a `Text`). The
generator checks its shape: one option, whose values are the tokens of a group with an accessor on Apple
(`AppleComponents.tokenAccessors`: `typography` → `Westron.TextRole`), and no states; it fails on any other. An
approved style with an optional option whose values are icons gets a labeled argument of its overload,
`<name>: Westron.Icon? = nil`, in the contract's order of options after the variant, and passed to its
`<Component>VariantStyle` (TextField:
`.textFieldStyle(.framed, leadingIcon: .magnifier)`), and the API parity lint expects exactly that. A style's icons
option every use names, and an extension's, fail generation and the lint as not supported yet, and so does an own
modifier with one: the conventions derive a required one for an own view alone. An
approved `style-on-system-control` with an option whose values are tokens still fails, as not supported yet, and so
does an approved own component with such an option.

Every approved contract with API on Apple, any strategy, gets its snapshot matrix too,
`platforms/apple/Sources/WestronCatalog/Generated/<Component>+Matrix.swift` (#24): an option whose values are tokens is
an axis of the group's tokens, in token order, read from `tokens/`; one whose values are icons an axis of the registry's
names, in its order, read from `spec/icons/icons.yaml`, which runs down the rows of a contract without states. An
optional option whose values are icons is no axis: the generated matrix draws every combination without the glyph, and
the component's hand-written supplements draw the glyphs, marked "not a contract option" (TextField's `glyph-leading`,
`glyph-trailing`, `glyphs-both`). A bool option with `nameInMatrixAtDefault: false` is an axis whose default value is
named in no sheet's id or title, so that an option added to a contract whose sheets were reviewed leaves the names,
titles and pixels of the sheets at its default as they were (Button's `floating`, #121).

Generation fails, with every problem, when a contract does not pass the check below; when a generated name is a
public SwiftUI type; when two contracts generate one type name (`button`'s option `groupSize` and `button-group`'s
`size` are both `ButtonGroupSize`); and when two contracts on one base control could make a call ambiguous or pick
the wrong overload: their variants share no value, and at most one of them can be called without a variant (its
variant has a default, or it has none); and when two extensions would add one modifier.

## Check

```sh
tools/westron spec check                      # every spec/components/*/*.spec.yaml
tools/westron spec check path/to/x.spec.yaml  # the given files
```

Besides the schema, the check enforces what a schema cannot:

- the file is `<id>/<id>.spec.yaml`;
- no unquoted YAML 1.1 boolean word other than `true` and `false`; where a name is meant, YAML's `true`, `false` or a
  number is reported as such, with the advice to quote it;
- no list repeats a name; an enum option's default, when it has one, is one of its values; no option is named `state`;
- no value, state or form is `init`, `self` or `none`, and no option `inout`, `var` or `let`: Swift cannot use them in
  the generated API (above);
- no option value is the name of a system style of the Apple base control, such as `plain` for `SwiftUI.Button`
  (decisions/0003); a base the check has no style modifier and style names for is an error until they are added to
  `tools/Sources/WestronTools/Contracts/SystemStyles.swift`, which knows `SwiftUI.Button`, `SwiftUI.TextField` and
  `SwiftUI.Toggle`, and on macOS a test holds each list to the static styles SwiftUI's interface declares; a control
  with no style modifier (`SwiftUI.Slider`, `SwiftUI.Stepper`) takes no style, and `SwiftUI.SecureField` takes
  `textFieldStyle`, as `SwiftUI.TextField` does;
- the Apple strategy fits its base: an `extension-on-system-control` extends a base of `SystemStyles.withoutStyle`,
  `SwiftUI.Text` or `SwiftUI.Image`, not one that takes a style, such as `SwiftUI.Button`, and a style never goes on a base of
  `withoutStyle`; a base in neither list is an error until it is added there;
- an option whose values are tokens names a group of `tokens/`, not a token and not a path with nothing under it; the
  group's tokens are semantic, exist in every mode and are of one type; its default is one of them, by its path after
  the group; no constraint, case, binding by value, platform restriction or `systemOptions` names it;
- no constraint, case, platform restriction or `systemOptions` names an option whose values are icons; one is
  `optional: true` only on a contract whose Apple strategy is `style-on-system-control`;
- constraints and cases name options, values and states that exist, a bool option with `true` or `false`; a
  constraint on slots (`when: { slots: [...] }`) names declared slots and no option in its `when`, has severity
  `error`, gives each option it requires one value, and is only on an Apple `own-component` of form `view` whose one
  slot is `label`, with no option whose values are icons; no option is named `slots`;
- a binding by value uses the values of one enum option, every one of them; every case is reachable, and so is a
  binding's `token`, which the cases leave no room for when they match every combination. The check enumerates the
  values of the options the cases name, not the states (Button's widest binding has 6 combinations); past 20 000 it
  reports the binding instead;
- every bound token exists in `tokens/` in every mode and is semantic, not primitive;
- a platform's restrictions are subsets of the declared values and states, an Apple OS's of Apple's; a fallback
  maps dropped values to kept ones; on Apple every value reaches, through Apple's fallback and then the OS's, a value
  each OS offers; `systemOptions` name options that exist, and are not restricted;
- `accessibility.states` names states that exist; a platform's keyboard intents do not repeat the component's, an
  Apple OS's do not repeat Apple's;
- a component whose role is `none` has no intents, keyboard intents (its own or a platform's) or announced states, and
  its label is not `required`.

It prints every problem as `file: place.in.document: message` and exits with 1; `tools/check.sh` runs it, in CI too.
