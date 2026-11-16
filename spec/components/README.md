# Component contracts

Each component is a folder `spec/components/<id>/`:

| File | What it is |
|---|---|
| `<id>.spec.yaml` | The contract: options, states, slots, constraints, token bindings, accessibility, the `platforms` block |
| `decisions/` | Decisions about the component, with the options considered |
| `reference/` | Reference screenshots approved by the human |

A new contract starts with the `/new-component` skill. The first contract is Button,
[`button/button.spec.yaml`](button/button.spec.yaml), approved by the owner on 2026-11-16 (#22).

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
    strategy: style-on-system-control   # or own-component, which has no base (decisions/0003)
    base: SwiftUI.Button
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
`description` is allowed on the contract, an option, a constraint, `accessibility`, a platform and an Apple OS.

- **Cases.** A case's `when` takes the same values as a constraint's (one value, a list, or `true`/`false` for a bool
  option) plus the key `state`, which names one state or a list of them. Put the narrower case first: a case that an
  earlier one fully covers is never used, and the check reports it. A component can be in several states at once;
  `state` matches when it is in any of the named ones, so a state that excludes others goes first.
- **Restrictions.** A platform, or an Apple OS (`ios`, `macos`, `watchos`), restricts the contract with `options` (the
  values of an enum option it offers) and `states` (the states it enters); what it does not name, it keeps whole. An
  Apple OS restricts what Apple keeps.
- **Fallbacks.** `fallback` says what a dropped value becomes on that platform. On Apple every dropped value needs one,
  since the OSes share one generated enum; elsewhere it is optional.
- **Keyboard intents.** A platform or an Apple OS lists in `keyboardIntents` only what it adds to the component's.

## Check

```sh
tools/westron spec check                      # every spec/components/*/*.spec.yaml
tools/westron spec check path/to/x.spec.yaml  # the given files
```

Besides the schema, the check enforces what a schema cannot:

- the file is `<id>/<id>.spec.yaml`;
- no list repeats a name; an enum option's default, when it has one, is one of its values; no option is named `state`;
- no option value is the name of a system style of the Apple base control, such as `plain` for `SwiftUI.Button`
  (decisions/0003); a base the check has no style names for is an error until they are added to
  `tools/Sources/WestronTools/Contracts/SystemStyles.swift`;
- constraints and cases name options, values and states that exist, a bool option with `true` or `false`;
- a binding by value uses the values of one enum option; no case repeats or is covered by an earlier one;
- every bound token exists in `tokens/` in every mode and is semantic, not primitive;
- a platform's restrictions are subsets of the declared values and states, an Apple OS's of Apple's; a fallback
  maps dropped values to kept ones, and on Apple every dropped value has one;
- `accessibility.states` names states that exist; a platform's keyboard intents do not repeat the component's, an
  Apple OS's do not repeat Apple's.

It prints every problem as `file: place.in.document: message` and exits with 1; `tools/check.sh` runs it, in CI too.
