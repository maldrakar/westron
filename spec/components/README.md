# Component contracts

Each component is a folder `spec/components/<id>/`:

| File | What it is |
|---|---|
| `<id>.spec.yaml` | The contract: options, states, slots, constraints, token bindings, accessibility, the `platforms` block |
| `decisions/` | Decisions about the component, with the options considered |
| `reference/` | Reference screenshots approved by the human |

A new contract starts with the `/new-component` skill. The first contract is Button,
[`button/button.spec.yaml`](button/button.spec.yaml), approved by the owner on 2026-11-16 (#22). Text,
[`text/text.spec.yaml`](text/text.spec.yaml), is a draft (#27): the first contract with an option whose values are
tokens and with an extension of a system view.

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
accessibility:
  role: button
  intents: [activate]
  keyboardIntents: [activate]
  label: required               # an accessible label even when none is visible; or optional
  states: { loading: busy }     # the abstract state assistive technology announces in a state
platforms:                      # all four; each is `status: planned` or a strategy
  apple:
    strategy: style-on-system-control   # or extension-on-system-control, or own-component, which has no base
                                        # (decisions/0003)
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
Names of options, values, slots, states and intents are lowerCamelCase: they become identifiers on every platform.
Swift, the pilot platform's language, cannot use a few words there: no value or state is `init`, `self` or `none`, and
no option is `inout`, `var` or `let` (an option becomes an argument label). Other Swift keywords are fine.
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
[`spec/conventions.md`](../conventions.md). A draft contract and an own component generate nothing yet. Nor does an
`extension-on-system-control`, or an option whose values are tokens. Generation fails, as not supported yet, on an
approved `extension-on-system-control`, and on an approved `style-on-system-control` with an option whose values are
tokens, until the generator, the API parity lint and the snapshot matrix support them, so such a contract stays draft
until then. An approved own component with such an option generates nothing, as every own component does.

Generation fails, with every problem, when a contract does not pass the check below; when a generated name is a
public SwiftUI type; when two contracts generate one type name (`button`'s option `groupSize` and `button-group`'s
`size` are both `ButtonGroupSize`); and when two contracts on one base control could make a call ambiguous or pick
the wrong overload: their variants share no value, and at most one of them can be called without a variant (its
variant has a default, or it has none).

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
- no value or state is `init`, `self` or `none`, and no option `inout`, `var` or `let`: Swift cannot use them in the
  generated API (above);
- no option value is the name of a system style of the Apple base control, such as `plain` for `SwiftUI.Button`
  (decisions/0003); a base the check has no style modifier and style names for is an error until they are added to
  `tools/Sources/WestronTools/Contracts/SystemStyles.swift`; a control with no style modifier (`SwiftUI.Slider`,
  `SwiftUI.Stepper`) takes no style, and `SwiftUI.SecureField` takes `textFieldStyle`, as `SwiftUI.TextField` does;
- the Apple strategy fits its base: an `extension-on-system-control` extends a base of `SystemStyles.withoutStyle`,
  such as `SwiftUI.Text`, not one that takes a style, such as `SwiftUI.Button`, and a style never goes on a base of
  `withoutStyle`; a base in neither list is an error until it is added there;
- an option whose values are tokens names a group of `tokens/`, not a token and not a path with nothing under it; the
  group's tokens are semantic, exist in every mode and are of one type; its default is one of them, by its path after
  the group; no constraint, case, binding by value, platform restriction or `systemOptions` names it;
- constraints and cases name options, values and states that exist, a bool option with `true` or `false`;
- a binding by value uses the values of one enum option, every one of them; every case is reachable, and so is a
  binding's `token`, which the cases leave no room for when they match every combination. The check enumerates the
  values of the options the cases name, not the states (Button's widest binding has 6 combinations); past 20 000 it
  reports the binding instead;
- every bound token exists in `tokens/` in every mode and is semantic, not primitive;
- a platform's restrictions are subsets of the declared values and states, an Apple OS's of Apple's; a fallback
  maps dropped values to kept ones; on Apple every value reaches, through Apple's fallback and then the OS's, a value
  each OS offers; `systemOptions` name options that exist, and are not restricted;
- `accessibility.states` names states that exist; a platform's keyboard intents do not repeat the component's, an
  Apple OS's do not repeat Apple's.

It prints every problem as `file: place.in.document: message` and exits with 1; `tools/check.sh` runs it, in CI too.
