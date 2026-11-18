---
name: implement-platform
description: The second approval gate. Implements a westron component on a platform from its approved contract, with a catalog entry, tests, screenshots and review by subagents. Use after the component's contract is approved.
argument-hint: "<component id> <apple|web|linux>"
---

# Implementing a component on a platform

> Phase 2 tools are in place: the API generator from the contract (#20), the parity lint (#21), the accessibility
> audit in tests (#25) and the snapshot matrix (#24). Only the `apple` platform is implemented now.

Arguments: `$ARGUMENTS`, the component id and the platform.

## 1. Preconditions

- The contract `spec/components/<id>/<id>.spec.yaml` exists and has `status: approved`. If not, stop:
  run `/new-component` first.
- Read the contract, its decisions, `decisions/0003` and the platform rules `.claude/rules/<platform>.md`.
- If the component already exists on another platform, read that implementation as the reference for behavior, but the
  contract, not the reference, settles disputed points.

## 2. Implementation (apple)

1. `tools/westron generate`: enums and signatures from the contract, and the snapshot matrix in
   `WestronCatalog/Generated/<Component>+Matrix.swift`. Do not edit generated code.
2. The style or component in `platforms/apple/Sources/WestronUI/<Component>/`: tokens only, a system control
   underneath, `if #available` for APIs newer than the minimum.
3. A catalog entry in `Catalog.entries`: the matrix of variants × sizes × states from the contract.
4. Tests: behavior and states with Swift Testing. Write `<Component>MatrixCell` in the catalog, which draws one cell
   of the generated matrix with the real component (Button's is in `Components/ButtonPages.swift`): the catalog does
   not build until it exists.
5. If the contract is silent somewhere, do not decide yourself: stop, propose a contract change and wait for approval.

## 3. Check

```sh
tools/apple/check.sh all
tools/check.sh             # tools tests, the raw-values lint, generate --check
```

Then run `/visual-check <id>` and open every screenshot, and capture the snapshot matrix on both platforms:

```sh
tools/apple/snapshot-matrix.sh ios   --component <id>   # prints the path to index.html
tools/apple/snapshot-matrix.sh macos --component <id>
```

For a change to an existing component, capture before and after on the same machine and compare:
`tools/apple/snapshot-matrix.sh compare <before> <after>`.

## 4. Review

Run the `spec-reviewer` and `a11y-auditor` subagents in parallel, with the component id and the platform. Fix everything
they found, or explain why it is not a bug. Fix contract gaps by changing the contract.

## 5. Show the human

The snapshot matrix (the paths to both platforms' `index.html`), the output of the checks, the review results and the
list of deviations recorded in the `platforms` block. The human looks at the matrix and, for a change, the snapshot
diff (the compare report): this is the second approval gate. Commit and pull request only when the human asks.
