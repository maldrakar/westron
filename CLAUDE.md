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
- before the work finishes, checks of the affected parts run; until they pass, you cannot finish.

Per-platform rules live in `.claude/rules/` and load when the work is in the matching paths.

Commits and pushes only when the human asks. Work happens in a branch, with one pull request per issue.
