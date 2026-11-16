# Component contracts

Each component is a folder `spec/components/<id>/`:

| File | What it is |
|---|---|
| `<id>.spec.yaml` | The contract: options, states, slots, constraints, token bindings, accessibility, the `platforms` block |
| `decisions/` | Decisions about the component, with the options considered |
| `reference/` | Reference screenshots approved by the human |

A new contract starts with the `/new-component` skill. The first contract is Button (issue #22).

## Format

The schema is [`spec/schema/component.schema.json`](../schema/component.schema.json) (JSON Schema 2020-12); the
contract is written in YAML (decisions/0004). In short:

```yaml
id: button                      # lowercase words joined by hyphens; the file is button/button.spec.yaml
status: draft                   # draft → approved → stable → deprecated
consumers: [todo-app/list-screen]   # <product>/<screen>, at least one (decisions/0006)
options:
  variant: { type: enum, values: [primary, secondary], default: secondary }
  size: { type: enum, values: [s, m, l], default: m }
  loading: { type: bool, default: false }
slots: [label, icon]
states: [hover, focus, pressed, disabled, loading]
constraints:
  - { when: { variant: primary }, require: { loading: false }, severity: warning }
tokens:                         # <part>.<property>: a token path, or one per value of an enum option
  container.background: { primary: color.background.accent, secondary: color.background.muted }
  container.radius: radius.control
accessibility: { role: button, intents: [activate], keyboardIntents: [activate] }
platforms:                      # all four; each is `status: planned` or a strategy
  apple:
    strategy: style-on-system-control   # or own-component, which has no base (decisions/0003)
    base: SwiftUI.Button
    watchos: { options: { size: [m] }, states: [pressed, disabled], description: Why it differs. }
  web: { status: planned }
  linux: { strategy: style-on-system-control, base: GtkButton }
  android: { status: planned }
```

Names of options, values, slots, states and intents are lowerCamelCase: they become identifiers on every platform.
`description` is allowed on the contract, an option, a constraint, `accessibility`, a platform and an Apple OS.
A platform, or an Apple OS (`ios`, `macos`, `watchos`), restricts the contract with `options` (the values of an enum
option it offers) and `states` (the states it enters); what it does not name, it keeps whole.

## Check

```sh
tools/westron spec check                      # every spec/components/*/*.spec.yaml
tools/westron spec check path/to/x.spec.yaml  # the given files
```

Besides the schema, the check enforces what a schema cannot:

- the file is `<id>/<id>.spec.yaml`;
- no list repeats a name; an enum option's default is one of its values;
- no option value is the name of a system style of the Apple base control, such as `plain` for `SwiftUI.Button`
  (decisions/0003); a base the check has no style names for is an error until they are added to
  `tools/Sources/WestronTools/Contracts/SystemStyles.swift`;
- constraints name options and values that exist, a bool option with `true` or `false`;
- a token binding keyed by value uses the values of one enum option, and every bound token exists in `tokens/` in
  every mode and is semantic, not primitive;
- a platform's restrictions are subsets of the declared values and states, an Apple OS's of Apple's.

It prints every problem as `file: place.in.document: message` and exits with 1; `tools/check.sh` runs it, in CI too.
