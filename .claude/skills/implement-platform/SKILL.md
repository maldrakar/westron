---
name: implement-platform
description: The second approval gate. Implements a westron component on a platform from its approved contract, with a catalog entry, tests, screenshots and review by subagents. Use after the component's contract is approved.
argument-hint: "<component id> <apple|web|linux>"
---

# Implementing a component on a platform

> **Draft until phase 2.** The API generator from the contract (#20), the parity lint (#21), the snapshot matrix (#24)
> and the accessibility audit in tests (#25) arrive in phase 2. Steps that rely on them are marked "phase 2".
> Only the `apple` platform is implemented now.

Arguments: `$ARGUMENTS`, the component id and the platform.

## 1. Preconditions

- The contract `spec/components/<id>/<id>.spec.yaml` exists and has `status: approved`. If not, stop:
  run `/new-component` first.
- Read the contract, its decisions, `decisions/0003` and the platform rules `.claude/rules/<platform>.md`.
- If the component already exists on another platform, read that implementation as the reference for behavior, but the
  contract, not the reference, settles disputed points.

## 2. Implementation (apple)

1. `npm run generate`: enums and signatures from the contract (phase 2). Do not edit generated code.
2. The style or component in `platforms/apple/Sources/WestronUI/<Component>/`: tokens only, a system control
   underneath, `if #available` for APIs newer than the minimum.
3. A catalog entry in `Catalog.entries`: the matrix of variants × sizes × states from the contract.
4. Tests: behavior and states with Swift Testing; snapshots of the matrix (phase 2).
5. If the contract is silent somewhere, do not decide yourself: stop, propose a contract change and wait for approval.

## 3. Check

```sh
tools/apple/check.sh all
npm run lint:raw-values
npm run generate:check
```

Then run `/visual-check <id>` and open every screenshot.

## 4. Review

Run the `spec-reviewer` and `a11y-auditor` subagents in parallel, with the component id and the platform. Fix everything
they found, or explain why it is not a bug. Fix contract gaps by changing the contract.

## 5. Show the human

The screenshot matrix (paths to the PNGs), the output of the checks, the review results and the list of deviations recorded in the `platforms` block.
The human looks at the matrix and the snapshot diff: this is the second approval gate. Commit and pull request only when the human asks.
