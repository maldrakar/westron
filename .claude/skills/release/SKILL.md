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
- CI on HEAD: !`gh run list --branch main --limit 3 --json headSha,conclusion,status,workflowName --jq '.[] | "\(.workflowName) \(.headSha[0:7]) \(.status) \(.conclusion)"' 2>/dev/null`

## Steps

1. **Preconditions.** The branch is `main`, the working tree is clean, `main` matches `origin/main` (`git fetch` and compare),
   and the last CI run on this commit is green. If something is wrong, stop and say what exactly.
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
