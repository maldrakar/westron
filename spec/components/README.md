# Component contracts

Each component is a folder `spec/components/<id>/`:

| File | What it is |
|---|---|
| `<id>.spec.yaml` | The contract: options, states, slots, constraints, token bindings, accessibility, the `platforms` block |
| `decisions/` | Decisions about the component, with the options considered |
| `reference/` | Reference screenshots approved by the human |

The contract schema and the validator will appear in phase 2 (issue #18); the first contract is Button (issue #22).
A new contract starts with the `/new-component` skill.
