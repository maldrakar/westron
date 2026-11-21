---
name: release
description: Releases a new westron version (CHANGELOG, tag and GitHub Release). The third approval gate; only the human invokes it.
disable-model-invocation: true
argument-hint: "[major|minor|patch]"
---

# Releasing westron

One version for the whole repository; SwiftPM takes it from the tag (decisions/0005). The tag is a bare semver version
with no prefix: `0.2.0`, not `v0.2.0`.

## State at invocation

- Branch: !`git branch --show-current`
- Uncommitted: !`git status --porcelain | head -20`
- Last tag: !`git describe --tags --abbrev=0 2>/dev/null || echo "no tags"`
- Commits since it: !`git log --oneline $(git describe --tags --abbrev=0 2>/dev/null || git rev-list --max-parents=0 HEAD)..HEAD | head -40`
- CI (`ci.yml`) on HEAD: !`gh run list --workflow ci.yml --commit "$(git rev-parse HEAD)" --limit 3 --json status,conclusion,event,url --jq 'if length == 0 then "no run" else .[] | "\(.status) \(.conclusion) \(.event) \(.url)" end' 2>/dev/null || echo "no run found"`
- Successful nightly runs (`accessibility-audit.yml`: the full audit, the behaviour UI tests) on HEAD: !`gh run list --workflow accessibility-audit.yml --commit "$(git rev-parse HEAD)" --status success --json databaseId,event,createdAt,url --jq 'if length == 0 then "none" else .[] | "\(.databaseId) \(.event) \(.createdAt) \(.url)" end' 2>/dev/null || echo "none found"`

## Steps

1. **Preconditions.** If something is wrong, stop and say what exactly.
   - The branch is `main`, the working tree is clean, and `main` matches `origin/main` (`git fetch` and compare).
   - The last `ci.yml` run on this commit is green. Only that workflow counts here, and it holds the snapshot matrix's
     check against the references (`snapshots`); the nightly checks are a workflow of their own (decisions/0008,
     notes of 2026-11-20 and 2026-11-21). If `snapshots` passed with a warning (no references, or references from
     another runner image), it compared nothing: tell the human, who decides whether to record them first.
   - The nightly checks passed on exactly this commit, the full accessibility audit and the behaviour UI tests on iOS
     and macOS: a successful run of `accessibility-audit.yml` (scheduled, or dispatched by hand) whose head commit is
     `git rev-parse HEAD`, and whose Mac jobs ran, the audit's legs and the behaviour tests' alike. A scheduled run
     skips them when the commit was already checked, and that run is green too, so check the jobs of each run listed
     above, newest first, until one has them all green:
     `gh run view <databaseId> --json jobs --jq '[.jobs[] | select(.name != "Accessibility audit — anything new") | .conclusion]'`
     must be a non-empty list of `success` only (a run whose jobs were skipped shows `skipped`). No such run, or no
     run listed at all (`none`, or `none found` when the query failed), means not green: the release waits. Say so,
     and offer the human the ways: when a run on this commit failed only for a flaky job (`gh run list --workflow
     accessibility-audit.yml --commit "$(git rev-parse HEAD)"` lists them all), re-run its failed jobs
     (`gh run rerun <databaseId> --failed`, then check that run again: a re-run keeps its id and commit); otherwise run
     the nightly checks now on `main` (`gh workflow run accessibility-audit.yml --ref main`, an hour or more, then
     check again), or wait for the nightly run.
2. **Version.** If the human passed `major|minor|patch` (`$ARGUMENTS`), use that. Otherwise propose one yourself from
   the "Unreleased" section in `CHANGELOG.md` and the commits: before 1.0, a breaking change is a minor bump.
   With no tags, the first version is `0.1.0`. Show the resulting version and wait for confirmation.
3. **CHANGELOG.** Move "Unreleased" into a section `## <version> — <YYYY-MM-DD>`. Only changes a consumer
   can notice. Breaking changes go in a "Migration" subsection, with concrete steps for the product.
   Leave an empty "Unreleased" section at the top.
4. **Checks.** `tools/apple/check.sh all` and `tools/check.sh`; attach the output.
5. **Commit and tag.** `git commit -m "Release <version>"`, `git tag -a <version> -m "<version>"`.
6. **Publish.** Show the human the CHANGELOG diff and the commands below, wait for an explicit "yes", then run
   `git push origin main <version>` and `gh release create <version> --title <version> --notes-file <file with the version's section>`.
7. **Result.** The link to the release and a line for the consumer: `.package(url: "https://github.com/maldrakar/westron", from: "<version>")`.

Never publish without the confirmation in step 6, and never rewrite tags that are already released.
