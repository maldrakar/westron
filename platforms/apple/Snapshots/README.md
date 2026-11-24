# Snapshot references

The snapshot matrix as the CI runner renders it (#24, #92; decisions/0008, the note of 2026-11-21): `ios/` and
`macos/` hold one PNG per picture, named as the render names them (`<component>.<sheet>.<theme>.png`, …), and
`environment.json`, the environment they were made in and the number of images. The PNGs are in Git LFS
(`.gitattributes`); `.lfsconfig` keeps them out of what a clone or a SwiftPM checkout fetches by default, so locally
they are pointers unless you pull them (`git lfs pull --include "platforms/apple/Snapshots/**" --exclude ""`).

They are recorded on CI only, never by hand: a render differs in every image from one environment to another (the
Mac's macOS and processor, Xcode, the simulator's runtime), so references made on another machine would fail every
check on the runner.

- **Record:** run the workflow "Snapshot references" (`.github/workflows/snapshot-references.yml`) on a branch,
  `gh workflow run snapshot-references.yml --ref <branch>`, or add the label `record-snapshots` to a pull request. It
  renders both platforms, writes the references (`tools/apple/snapshot-matrix.sh record`; a reference within one
  level of its new picture stays as it was, and so does one of a picture that is not compared, such as Button's
  glass on iOS, while its size holds; in another environment only the same pixels keep one) and commits them to the
  branch. CI does not start for that commit, since
  a workflow pushed it: close and reopen the pull request, or push any commit, to run the checks again.
- **Check:** the job `snapshots` in `ci.yml` renders both platforms on every pull request and push to `main` and runs
  `tools/apple/snapshot-matrix.sh check`; a difference fails it, and its artifact holds the report and the render.
  With no references, or with references from another runner image, it passes with a warning: record them again.

Until the first recording, each `environment.json` says `"recorded": false` and the check reports that there is
nothing to compare with.

**The order, for the first recording and every change of look.** A push to `main` whose render cannot be compared
(no references, or references from another runner) fails the `snapshots` job; a pull request only warns. So:

1. Record on the pull request that introduces or changes the references: add the label `record-snapshots`. The
   workflow commits the references to the pull request's branch and comments when it is done.
2. Run the pull request's checks again on that commit, which a workflow's own push does not start: close and reopen
   the pull request (`gh pr close <n> && gh pr reopen <n>`), or push any commit. `snapshots` must pass, comparing.
3. Merge only then.

If `main` is already red for it (merged without references, or the runner image changed under them), record on
`main` itself: `gh workflow run snapshot-references.yml --ref main -f allow-main=true` (if branch protection refuses
the workflow's push, record on a branch with the label and merge that instead).

Locally, the check says the environment differs and compares nothing (exit 4). Render before and after a change and
compare the two instead: `tools/apple/snapshot-matrix.sh compare` (`.claude/skills/visual-check`).
