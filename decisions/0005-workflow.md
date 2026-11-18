# 0005. Workflow

Date: 2026-11-14. Status: accepted. Revised 2026-11-18: a phase may ship as one pull request when the owner says so.

## Decision

Work runs spec-first: the human makes the design decisions, Claude Code writes the specifications and the implementation.

Each component passes three approval gates, all held by the human:

1. **Contract.** The agent asks about purpose, variants, states and accessibility, then writes the contract and a short decision. The human approves the contract.
2. **Screenshot matrix.** The agent implements the component and adds it to the catalog and the snapshot tests. The human reviews the state matrix and the snapshot diff.
3. **Release.** Only the human runs it.

If a gap turns up during implementation, the contract is fixed first, then the code.

## GitHub

- One public monorepo.
- Phases are milestones, tasks are issues.
- Each component gets an issue and a pull request with the contract, the implementation and the screenshot matrix.
  A phase may ship as one pull request instead, when the owner says so (revision of 2026-11-18, below).
- Decisions are stored as files in `decisions/`, not in issues.
- One version for the whole repository: SwiftPM takes versions from the repository tags.

## Revision of 2026-11-18

The first version gave each component its own pull request. A CI run on a pull request takes about an hour and a
half (runs 44301767788, 44315755921 and 44339047592 took from 1 h 24 min to 1 h 50 min), and every push runs it
again. On 2026-11-18 the owner decided that phase 3 ships as one pull request:

- A phase **may** ship as one pull request when the owner says so. The default stays one pull request per issue.
- Such a phase has one branch, named after it (`phase-3/primitives-and-forms`). Each component still has its own
  issue, its own contract approval (gate 1) and its own review of the snapshot matrix (gate 2). Each component is
  merged into the phase branch locally once its gates pass.
- The phase branch goes to `main` in a single pull request that closes all the phase's issues.
- One intermediate push, of a draft pull request after the first component, is allowed, so that failures that show
  only on the CI runner turn up early.

## Rules

- A new component appears only for a real product need.
- A parity gap between platforms with no record in the contract is a bug.
- Component code has no raw values, only tokens.
- Instead of saying "tests passed", the agent shows the command output or a screenshot.
