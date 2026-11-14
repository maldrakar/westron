---
name: new-component
description: The first approval gate. Runs an interview about a new westron component and writes a draft contract and a short decision. Use when a product needs a component that westron does not have yet.
argument-hint: "<component id>"
---

# New component: interview → contract → approval

> **Draft until phase 2.** The contract format is set by the schema `spec/schema/component.schema.json` (issue #18).
> Until it exists, the contract follows the structure of the example in the report (`reports/`, section "Identical
> names do not hold by discipline") and counts as a draft. The example predates the decisions and differs from them in two places:
> - the component name has no prefix, and the component is a style on top of a system control, not `WButton` (decisions/0003);
> - `consumers` is a pilot screen, for example `todo-app/list-screen`, not `pilot-app` (decisions/0006).
>
> The process steps will not change when the schema appears: only the file format will change, and validation will be added.

Component `$ARGUMENTS`. The task is to get the design decisions from the human and write them down so that
an implementation on any platform can be verified. Do not make design decisions yourself: offer options.

## 1. Is there a need

- Find the pilot screen that needs the component (decisions/0006). Without a consumer, the component is not created:
  say so and stop.
- Check whether `spec/components/` already has a suitable component, or the platforms have a system control for it.

## 2. Interview

Ask through AskUserQuestion, 1–4 questions at a time, with the recommended option first:

1. Purpose and scenarios: what the user does with this component, where it sits on the pilot screen.
2. System control: does one exist on Apple, in GTK, on the web. If it does, westron provides a style, not a replacement (decisions/0003).
3. Options: variants, sizes, flags, defaults. Value names do not match the names of system styles.
4. States: hover, focus, pressed, disabled, loading, selected and so on; which platforms never enter which states.
5. Slots: text, icon, supporting content.
6. Constraints between options.
7. Accessibility: role, intents, keyboard, what VoiceOver announces.
8. Platform differences: what is different on macOS, watchOS, in GTK and on the web, and why.

If there are several options for how it looks, make 2–3 HTML sketches on westron tokens and show them.

## 3. Write down

- `spec/components/<id>/<id>.spec.yaml`: the contract with status `draft` and the `consumers` field.
- `spec/components/<id>/decisions/0001-<topic>.md`: a short decision with the context, the options considered and the choice.

## 4. Approval

Show the human the whole contract and ask whether they approve it. Only after a "yes", change `status` to
`approved`. Offer to open an issue and a `component/<id>` branch; commit only when the human asks.
Next: `/implement-platform <id> apple`.
