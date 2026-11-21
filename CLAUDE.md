@AGENTS.md

## Claude Code in this repository

The process from decisions/0005 runs through commands:

| Step | Command | Who runs it |
|---|---|---|
| Interview → contract → approval | `/new-component` | the human or an agent |
| Implementation on a platform from the contract | `/implement-platform <component> <platform>` | an agent |
| Catalog screenshots and a check against the contract | `/visual-check [entry]` | an agent |
| Release | `/release` | only the human |

Subagents with a fresh context:
- `spec-reviewer` checks the diff against the contract, requirement by requirement;
- `a11y-auditor` checks the accessibility of the implementation.

Run them after implementation, before you show the result to the human.

Hooks (`.claude/settings.json`) run on their own:
- after an edit to a `.swift` file, the file is formatted, and code in `WestronUI` is checked by the raw-values lint;
- before the work finishes, checks of the affected parts run, each only when the changes touch what it reads (not the
  snapshot matrix, which a local machine cannot check against the CI runner's references); until they pass, you
  cannot finish. `WESTRON_STOP_CHECKS_DRY_RUN=1 .claude/hooks/stop-checks.sh < /dev/null` lists the checks it would
  run.

The `Stop` hook sees only the main session's uncommitted changes. An implementer subagent, which commits in its own
worktree, is checked by the orchestrator's test gate instead: it runs the line in `.claude/test-command`,
`.claude/hooks/stop-checks.sh --branch main`, the same checks over everything the branch changed since its merge base
with `main`, committed or not, in the checkout it starts in. There a failure fails every time; the dry run works with
`--branch` too.

Per-platform rules live in `.claude/rules/` and load when the work is in the matching paths.

Commits and pushes only when the human asks. Work happens in a branch, with one pull request per issue, unless the
owner ships a phase as one pull request (decisions/0005, revision of 2026-11-18).
