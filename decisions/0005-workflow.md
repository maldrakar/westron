# 0005. Workflow

Date: 2026-11-14. Status: accepted.

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
- Decisions are stored as files in `decisions/`, not in issues.
- One version for the whole repository: SwiftPM takes versions from the repository tags.

## Rules

- A new component appears only for a real product need.
- A parity gap between platforms with no record in the contract is a bug.
- Component code has no raw values, only tokens.
- Instead of saying "tests passed", the agent shows the command output or a screenshot.
