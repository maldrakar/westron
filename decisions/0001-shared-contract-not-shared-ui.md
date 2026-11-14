# 0001. A shared contract instead of a shared UI library

Date: 2026-11-14. Status: accepted.

## Context

We had to decide where design decisions live: in one cross-platform library, or in a shared specification from which each platform gets a native implementation.

## Decision

There is no shared UI library. What is shared is the data source in this repository, with a single version:

- tokens;
- component contracts;
- design language documents.

It produces three layers:

| Layer | What it contains | How it is produced |
|---|---|---|
| Generated | Tokens for each platform, enums of variants and sizes, style signatures, snapshot matrices, agent context | Scripts; regenerating from the same input gives an empty diff |
| Written natively | Bodies of styles and components, interaction, animation, accessibility | By hand from the contract, checked by tests and review |
| Left to the system | Navigation, sheets, menus, pickers, text input, focus, window chrome | The platform; westron only applies tokens |

Generated code is committed, and CI compares it with a fresh generation.

## Why

- Material, Fluent, Spectrum and Backpack share data and algorithms across platforms, not UI code.
- Generating whole components from one description (Lona, Redwood) did not catch on.
- With an agent, implementing on each platform has become cheap; what stays expensive is a precise contract and checking conformance to it.

Details and sources: [research report](../reports/westron-design-system-research.md).
