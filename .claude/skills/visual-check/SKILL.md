---
name: visual-check
description: Takes screenshots of westron catalog entries on iOS and macOS, opens them and checks them against the contract and the reference screenshots. Use after any edit that changes how a component or the catalog looks, and before showing the result to the human.
argument-hint: "[entry id …] [--platform ios|macos]"
---

# Visual check of the catalog

The goal is to see the result with your own eyes, not to assume. A screenshot you have not opened does not count.

## 1. What to capture

- If the arguments contain entry ids, capture those: `$ARGUMENTS`.
- Otherwise, the entries of the affected components: directories in `spec/components/` and files in `platforms/apple/`
  that changed (`git status`, `git diff main...HEAD --stat`). An entry id equals the component id.
- If nothing fits, the utility entry `environment`.

## 2. Capture

For each entry, on both platforms by default:

```sh
tools/apple/catalog-screenshot.sh ios   --entry <id> --appearance light
tools/apple/catalog-screenshot.sh ios   --entry <id> --appearance dark
tools/apple/catalog-screenshot.sh ios   --entry <id> --dynamic-type accessibility3
tools/apple/catalog-screenshot.sh macos --entry <id> --appearance light
tools/apple/catalog-screenshot.sh macos --entry <id> --appearance dark
```

The script prints the path to the PNG. The captures are independent: run them one at a time and do not stop at the first error.

If macOS fails with `Timed out while enabling automation mode`, Automation Mode is not enabled on the machine.
Only the human can enable it, once:
`! sudo automationmodetool enable-automationmode-without-authentication`. Say so and continue with iOS.

## 3. Look

Open every PNG (Read) and check:

- every variant, size and state from the contract `spec/components/<id>/<id>.spec.yaml` is present;
- nothing "gets lost" in the dark theme: text is readable, borders are visible;
- at `accessibility3` text is not clipped and does not overlap, and the layout is not broken;
- iOS and macOS look like one system, and the differences match the contract's `platforms` block;
- if there are reference screenshots in `spec/components/<id>/reference/`, open them and compare.

## 4. Report

For each screenshot: the path and one line on "what is visible". Then the discrepancies: what is wrong, on which screenshot,
and the likely cause. If a discrepancy is a contract gap and not a code bug, say so.
