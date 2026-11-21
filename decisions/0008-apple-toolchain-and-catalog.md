# 0008. Apple: versions, toolchain, catalog and screenshots

Date: 2026-11-14. Status: accepted.

## Decision

### Versions and toolchain

- Minimum: iOS 17, macOS 14, watchOS 10, as in the pilot (decisions/0006). Newer APIs, including Liquid Glass,
  are used inside `if #available(iOS 26, macOS 26, watchOS 26, *)`. Raising the minimum later is cheap;
  lowering it is expensive.
- Xcode 27.1, Swift 6.4, Swift 6 language mode. The Xcode version is pinned in `.xcode-version`. The scripts
  find this Xcode themselves (`tools/apple/xcode-env.sh`) and do not touch `xcode-select`. CI runs on the
  `xcode-27` image with `DEVELOPER_DIR` set to the same Xcode, as in the pilot.
- `// swift-tools-version: 6.2` in the manifest is the minimum the manifest requires, not the version the checks
  run on.

### Package

- `Package.swift` at the root (decisions/0005), sources in `platforms/apple/`.
- `WestronUI` is what products import.
- `WestronCatalog` is the registry of catalog entries, the host and the launch argument parsing. It lives in the package rather than
  in the app so that the phase 2 snapshot tests iterate over the same entries. It is a separate SwiftPM product because
  the Xcode project sees the package only through products; the products that use westron do not need it.
  2026-11-18 (#24): the snapshot matrix does not iterate over `Catalog.entries`; that list drives the accessibility
  audit. The matrix has its own registry in the same package, `ComponentMatrix.all`, generated from the contracts.
- `WestronTokens` (generated tokens) arrives in phase 1.

### Catalog app

- The catalog is a thin shell: `@main` over `CatalogScene` from the package. One multiplatform app
  for iOS and macOS. watchOS will get its own target when the watch subset appears (issue #34).
- The project is `Catalog.xcodeproj/project.xcproj` in the Xcode 27 format, as in the pilot. Files are picked up
  from folders, so the project changes only for settings and targets.

### Screenshots for the agent

- `tools/apple/catalog-screenshot.sh ios|macos --entry <id>` builds the catalog and runs the UI test
  `CatalogScreenshotTests`. The test opens one entry in isolation and attaches a PNG to the test result;
  the script extracts it from `.xcresult` (`xcresulttool export attachments`). The runner cannot write the file itself:
  on macOS, Xcode runs it in a sandbox where the file system is read-only.
- The XCTest runner takes the screenshot. In-process options were tested on 2026-11-14 on macOS 26.7 with Xcode 27.1
  and rejected:
  - `NSView.cacheDisplay` and `CALayer.render(in:)` produce an empty image: SwiftUI draws through the render server;
  - `screencapture` requires the terminal to have screen recording permission;
  - `ImageRenderer` replaces system controls with placeholders.

  2026-11-21 (#92): this holds for the agent's screenshots of an entry, which stay as they are; the snapshot matrix is
  now drawn in-process (Consequences, the note of 2026-11-21). A spike of 2026-11-20 found what the test of
  2026-11-14 missed. `cacheDisplay` and `CALayer.render(in:)` do draw a hosting view that sits in a window, but they
  misdraw, as `ImageRenderer` does: a text field's placeholder, a spinner drawn as a square, a capsule's stroke,
  shadows, a color one level off. Two paths draw what the screen shows: on iOS, `drawHierarchy(in:afterScreenUpdates:)`
  of a window in the scene of the catalog app, which hosts a unit-test bundle (without a host app iOS draws nothing);
  on macOS, Core Animation's own renderer (`CARenderer`) into a Metal texture, for a hosting view in a borderless
  window that is never ordered in, with its backing scale fixed at 2 whatever the screens'.
- On iOS the status bar is pinned (`simctl status_bar`, 9:41) so that screenshots do not differ by the time.
- UI tests on macOS require Automation Mode. It is on for GitHub runners. On your own machine the human turns it on
  once: `sudo automationmodetool enable-automationmode-without-authentication`.
- The same UI test target will host the `performAccessibilityAudit` audit in phase 2 (issue #25).
  2026-11-16: it does. `CatalogAccessibilityAuditTests` audits every entry of `Catalog.entries` in five
  configurations (default, accessibility5, increased contrast, dark, dark with increased contrast);
  `tools/apple/check.sh a11y` runs it on the iOS simulator; CI runs it in jobs of its own, not as a required check
  (below).
  `tools/apple/check.sh a11y macos` runs it on macOS by hand: it needs Automation Mode and the screen to itself.
  Suppressed issues, each with its reason, are listed in the test; the matrix is in `platforms/apple/README.md`.
  2026-11-17: every test audits each page a screenful at a time, down to its end; the Dynamic Type and text clipped
  audits of the default test run on windows of the page held in place by `-WestronScrollAnchor`, because a dragged
  scroll view goes back to its top when they enlarge the text. The README lists what the audit still cannot see.
  The same day the audit outgrew one CI step: the runner is 2.2–2.3 times slower than a local Mac, and a serial run
  passed 40 minutes (`testAccessibilityDynamicType` alone took 13.5). CI now runs the five tests as a matrix job,
  `accessibility-audit`, one job each in parallel, 35 minutes each: about 40 runner-minutes per pull request. Whether
  it runs on every pull request or on `main` only is the owner's call: one commented `if:` line in the job.
  2026-11-18 (#66, #70): eight legs, "Accessibility audit — <test>" and "… — <test> (<i>/<n>)" for a shard, one for
  each contrast test and the two slow tests split by entries (`testAccessibilityDynamicType` into three shards,
  `testDefaultSettings` into two); they run on every push to `main`, and on a pull request only when the
  `audit-scope` job finds a changed path the audit depends on (or itself fails). They are not required checks: a pull
  request that skips them would wait for them forever.
  2026-11-18 (#74): the audit's legs failed on CI for the machinery, not for a page: 10 failed legs in 5 runs of
  2026-11-17/18, none for a real issue. The simulator stalls for a minute or more now and then, and whatever the
  test asks of it then fails (terminating or launching the catalog, a UI query, the audit's -56, the entry not
  rendering); a stopped `testmanagerd` in a local simulator gives the same "Failed to terminate" message, and a
  stopped catalog does not. XCTest stops the test method at a failed terminate, launch, query or drag, so the rest
  of the shard went unaudited. The test could withhold such a failure from XCTest and go on, but on an app in an
  unknown state; so it records every failure as it comes and prints it with its kind (`infrastructure` for those
  messages, `finding` for everything else), and which entries it finished. `tools/apple/check.sh a11y` then audits
  once more, in a run of its own, the entries a run did not finish or that failed for infrastructure alone, only
  after a run whose test started (the build is a step of its own) and only within a time budget of 30 of the leg's
  35 minutes. A test with a finding is never retried, so a rare finding still fails the leg; every retry is logged,
  warned on the run, and its logs are uploaded. One finding was transient too, on an element the bottom of the screen cut; such an element is now judged on
  the next screenful, which shows it whole. The legs stay informational checks, never required.
  2026-11-18 (#74): the retry's estimate refused it where it was needed. A stall in the first entry of a
  `testDefaultSettings` shard, 9 minutes into the leg, was estimated at 26 more minutes, since the stalled entry's
  minutes counted as the time per entry; the retry would have taken 9–11. The estimate now uses only the entries
  the first run finished without a failure and without an audit retried on the spot, and when there are none, a
  time per entry for each test measured on CI with a margin of 12–15 %: 60–81 s for `testDefaultSettings`, 50–114 s
  for `testAccessibilityDynamicType`, 25–33 s for the others, from the 15 legs of 17 that passed on their first run
  (one failed, one passed after a retry). The step spends 6.5–17.1 minutes, median 10.0 and mean 10.4, before its
  first entry; so a stall in the first entry of the slowest leg is retried within the budget after a usual build
  (10.4 + 3 + 15 = 28.4 minutes), and the budget of 30 and the leg's 35 minutes stay as they are.
  2026-11-19 (phase 3): the catalog grows from 17 entries to 28 (Text, Surface, Rule, Checkbox, Icon, Text field),
  and the whole phase reaches `main` in one pull request, so its first run must already fit. Seventeen legs of 35
  minutes would fit, but each pays the mean 10.4 minutes before its first entry, and at most 5 Mac jobs run at once
  on this repository (measured: runs 44339047592, 44360219942, 44364265656 and 44386153527 never ran more), while
  other branches' required `apple` job waits behind them (24 minutes in run 44364265656, behind a run on `main`). A
  run of 35 Mac jobs, about 10.1 runner-hours, would take an estimated 2 hours at best and about 2.4 as measured runs
  go (1.2 times the floor of runner-minutes over 5; run 44386153527: 256 minutes of Mac jobs, 62 minutes). So ten
  legs of 45 minutes with a retry budget of 40, from the times per entry above (90, 130 and 38 s):
  `testDefaultSettings` in three shards (10 entries, about 25.4 minutes), `testAccessibilityDynamicType` in four
  (7 entries, about 25.6) and each contrast test in one leg (28 entries, about 28.1); about 4.3 runner-hours. A stall
  in the first entry of the slowest leg is retried by 32.6 minutes, and still after up to 17.8 minutes before the
  first entry (17.1 seen), against 14.7 with the seventeen legs; a leg without a retry ends by 34.8 minutes. With
  the snapshot legs below, a run has 17 Mac jobs, about 7.7 runner-hours: an estimated 1.5 hours at best and about
  1.6–1.9 expected. Decided by the coordinator under the owner's delegation of 2026-11-18, pending the owner's
  confirmation.
  2026-11-19 (run 44444325775, phase 3's first run): three legs of 20 failed for the machinery and were not
  retried, each at the first launch of its first test run on the runner. The audit's retry rule stays as it is; it
  now knows two more of XCTest's messages. A test runner that crashed while preparing to run tests ("Early
  unexpected exit, operation never finished bootstrapping") did not start, like one that failed to install, and its
  whole test is run again within the first half of the budget. A launch that timed out on a stalled simulator
  ("Failed to get background assertion … Timed out while acquiring background assertion", "Failed to launch … via
  Xcode: Timed out while launching application") is infrastructure; any other launch failure stays a finding, and
  a run with a finding is still never retried. The snapshot matrix, which had no retry, gets one on the same
  grounds: a capture that wrote no manifest and whose every failure is one of those messages, or whose runner did
  not start, is captured once more, never one whose test reported a failure of a sheet. The retry is the whole
  capture, so it starts only within 25 minutes of the script's start, and a snapshot leg's timeout grows from 20 to
  30 minutes plus its capture time with a third more, so that such a retry ends inside it (before, it fitted only
  when it started by 15 minutes, less than the setup alone has taken). Decided by the coordinator under the owner's
  delegation of 2026-11-18, pending the owner's confirmation.
  2026-11-19 (run 44461921450): a macOS snapshot leg printed the capture's header and then nothing for 62 minutes,
  until the job's timeout killed it with no logs; a rerun of the same commit passed in 17. The snapshot matrix now
  stops an xcodebuild whose log has not grown for 10 minutes, its children too, and a capture so stopped counts as
  the machinery's failure, retried on the grounds above and never after a failure of a sheet; a second stall fails
  the leg. A capture's longest usual silence is the machinery's, 3.5 minutes. CI also stops whatever the script
  still does 2 minutes before a leg's timeout, an xcodebuild, the export of the attachments or the page, and the
  leg fails with its logs uploaded rather than being cancelled without them; a capture that would have ended in
  those 2 minutes fails too. Decided by the coordinator under the owner's delegation of 2026-11-18, pending the
  owner's confirmation.
  2026-11-20: a CI run on a pull request took 85–150 minutes, 17 Mac jobs and about 6 runner-hours, most of it the
  full audit (10 legs, about 3.7 hours) and the snapshot matrix (4 legs and a page job, about 2.2 hours), and the
  same set ran again on every push to `main`. The owner decided: the full audit runs once a night, the snapshot
  matrix on demand, and a pull request audits only what it changes. The ten legs move as they are into a workflow
  of their own, `.github/workflows/accessibility-audit.yml`, on a schedule (02:37 UTC) and by hand on any branch
  (`gh workflow run accessibility-audit.yml --ref <branch>`); a scheduled run skips the legs when `main`'s head is
  the commit the last successful scheduled run audited, and runs them if it cannot tell. In `ci.yml`, `audit-scope`
  maps a pull request's changed paths to catalog entries (`tools/apple/audit-scope.sh`: a component's directory in
  WestronUI, its generated files, its catalog page and its contract give that component's entries; a Foundations
  page that shares nothing with other files gives its own), and one job audits them in all five configurations,
  55 minutes with a retry budget of 50, split into shards of at most 5 entries when there are more; it is skipped
  when there are none, and on a push to `main`. A change to shared paths (tokens, the shared files of WestronUI, the
  catalog's host, the scripts) is audited by the night after its merge, or by hand on the branch before it. The
  snapshot matrix moves to `.github/workflows/snapshot-matrix.yml`, run by hand (optionally for some components) or
  by the label `snapshot-matrix` on a pull request; its legs, artifacts and page are as before. A pull request now
  takes 2–3 Mac jobs, up to about 1.4 runner-hours; a push to `main` 2. Decided by the owner. The same day the owner
  added the catalog's behaviour UI tests (`ButtonBehaviorTests`, `CheckboxBehaviorTests`, `TextFieldBehaviorTests`,
  `IconAccessibilityTests`), which nothing ran, to the nightly workflow: `tools/apple/check.sh behavior`, one leg on
  iOS and one on macOS, under the same skip rule; the release now needs that run green on its commit, behaviour tests
  included.

## Consequences

- Phase 2 reference snapshots must be taken in the same environment as CI: the same Xcode version, the same device
  and the same OS version. Issue #24 decides how to align the environments. The first CI run (2026-11-14, entry `environment`)
  showed how the environments differ now:

  | | Local | CI (`xcode-27`) |
  |---|---|---|
  | iOS in the simulator | 26.3 | 27.0 |
  | macOS | 26.7, 2x scale | 27.0.1, 1x scale (720×540 window) |
  | "Reduce motion" and "Reduce transparency" on macOS | off | on |
  | Locale | `ru_RU` | `ru_US` |

  Snapshots must not depend on these machine settings. What it can, the test sets itself: theme, font size, locale.
  The capture environment pins the rest: SwiftUI only reads some accessibility settings, and a test cannot change
  the scale or the OS version.

  2026-11-18, #24 decides: the environments are not aligned; captures are compared only within one.
  - **No reference images in the repository.** A matrix is generated from the contract and captured on demand
    (`tools/apple/snapshot-matrix.sh ios|macos`); nothing captured is committed. A committed reference would have to
    be taken in exactly one environment, and every other machine would see a diff of the OS version, the scale or a
    system setting rather than of the component. 2026-11-21 (#92): superseded; the references are in the
    repository, made in one environment, the CI runner's (the note of 2026-11-21 below).
  - **A matrix is compared only with a matrix from the same environment:** two local runs (before and after a change,
    on the same Mac and simulator), or two CI artifacts (`main` against the pull request, on the same runner image).
    `tools/apple/snapshot-matrix.sh compare <before> <after>` compares two captures pixel by pixel; its report names
    both environments, so a comparison across them is visible as such. The review page of each capture
    (`index.html`) names its OS version, device and scale, and the size of each picture.
    2026-11-19: on iOS the picture is the whole screen, and the system draws the home indicator over it, from launch
    to launch or not, or at another opacity: two captures of Button on the same commit differed in 54, 83 or 84 of
    its 144 images, every pixel in the indicator's place. The comparison of two iOS captures ignores the pixels on
    the indicator's footprint (a capsule of 144 × 5 pt at the bottom centre, in the bottom safe-area inset, with
    1.5 pt of tolerance), but only in an image whose content stays clear of the box around it in both pictures and
    where nothing else in that box differs; a sheet that overflows the screen is compared whole, and a block or dot in
    the box off the footprint is reported. Every image that differs on the indicator alone is still shown, with its
    diff, under a heading of its own. What a capture is does not change. Rejected: hiding the indicator in the catalog
    (`.persistentSystemOverlays(.hidden)`, UIKit's `prefersHomeIndicatorAutoHidden`), which only allows the system to hide it on its own schedule, after a
    few seconds without touches, so whether it shows still depends on timing, and which would change the catalog for
    one tool; it could not be shown to be deterministic cheaply either, since unchanged one capture showed the
    indicator in none of Button's 144 images and the next in 54. And cropping the bottom inset out of every picture,
    which would change what a capture is and hide from review whatever a sheet draws there. Decided by the
    coordinator under the owner's delegation of 2026-11-18, pending the owner's confirmation.
  - **The capture sets what it can itself:** the theme and the contrast for each image, the text size (`large`, the
    default), the language and the locale (`en`, `en_US`), on macOS the window's size (720 × 540, whatever size the
    system restores) and the picture of the sheet alone, without the title bar and the desktop at the window's
    corners, the status bar on iOS, and Core Animation frozen in the sheet's window, so that a loading indicator shows the same frame on
    every capture. What it cannot set (the OS version, the scale, Reduce Motion and Reduce Transparency on macOS)
    stays the environment's.
  - **Proposed next step, for the owner to decide:** a CI job on pull requests that downloads the matrix artifact of
    the latest `main` run, captures the pull request's matrix on the same runner image and attaches the compare
    report, informational and not a required check. It is not wired yet: it doubles the matrix's runner time on every
    pull request, and a runner image update would show as a diff of every image until `main` is captured again.
- The CI job with screenshots takes about 16 minutes: each shot calls `xcodebuild` separately. The snapshot matrix
  needs one run per platform; that is also #24. 2026-11-18: `tools/apple/snapshot-matrix.sh` takes the whole matrix
  in one `xcodebuild test` invocation per platform, relaunching the catalog for each sheet and theme inside it; the
  CI job `snapshot-matrix` runs it for iOS and macOS and uploads the pages as an artifact.
- 2026-11-18, #72: the matrix also shows text sizes and what no contract option sets, at the owner's request.
  - **Text sizes:** the four themes stay at `large`; the light theme is captured at `xSmall` and `accessibility5` too.
    Only the cells follow the size; the sheet's own text stays at `large`. At `accessibility5` a 3 × 6 sheet does not
    fit an iPhone 17, so it is captured in parts of one column each, a fixed split by text size, so the file names stay
    deterministic; the `large` sheets and their file names are unchanged. macOS has no Dynamic Type: SwiftUI there draws
    a cell the same at every `dynamicTypeSize` (checked in `ComponentMatrixTests`), so a Mac captures `large` alone
    rather than three copies of one picture.
  - **Supplementary sheets:** a component's catalog code may add hand-written sheets for what no contract option sets,
    on the generated sheets' axes and marked "not a contract option" on the sheet and the page; Button's label without
    an icon is the first. The generator and the generated files do not change: the contract still drives every
    generated sheet.
  - **Cost:** with Button, 144 images on iOS (was 48) and 72 on macOS (was 48): locally the UI test takes about 12 minutes
    for iOS (711 s, iPhone 17 simulator, iOS 26.3.1) and 5 for macOS (315 s), plus the builds. One CI job for both
    took 32–40 of its 50 minutes before; it would now need well over an hour, so the job `snapshot-matrix` runs one job
    per platform side by side, with 75 and 45 minutes, and uploads `snapshot-matrix-ios` and `snapshot-matrix-macos`.
  - 2026-11-19 (phase 3): with Text, Surface, Rule, Checkbox, Icon and Text field, 365 images on iOS and 184 on
    macOS: about 91 minutes of capture on iOS on the runner, past any one job. One job per component (fourteen, each
    with its own build) was too many for 5 concurrent Mac runners, so the components go into legs packed by their
    number of images (first fit, the largest first, at most 40 minutes of capture each, from a table of counts in the
    workflow that the page job checks against each capture), one `xcodebuild test` per leg (`--component a,b`): three
    legs for iOS and one for macOS, each with a timeout from its images. A job `snapshot-matrix-pages` merges each
    platform's legs into one page (`snapshot-matrix.sh merge --expect`), which names any component no leg brought, so
    the owner still opens `snapshot-matrix-ios` and `snapshot-matrix-macos`. Decided by the coordinator under the
    owner's delegation of 2026-11-18, pending the owner's confirmation.
  - 2026-11-20: the matrix compares nothing, so it no longer runs with every pull request and push to `main`; it is
    captured on demand, by `.github/workflows/snapshot-matrix.yml` (the note of 2026-11-20 under "Screenshots for the
    agent"). Decided by the owner.
- 2026-11-21 (#92): the matrix is rendered by unit tests in-process, and every pull request and push to `main` compares
  it with references in the repository. The UI-test capture took about 4.8 s an image locally and 7.5–15 s on CI (about
  2.2 runner-hours for both platforms) and compared nothing. A spike on 2026-11-20 measured the in-process paths (the
  note of 2026-11-21 under "Screenshots for the agent") locally and on the runner. The owner decided:
  - **Rendering.** The matrix is drawn by `platforms/apple/Tests/WestronSnapshotTests`, one source compiled twice: on
    macOS as a package test target under `swift test`, on iOS as the unit-test bundle `CatalogSnapshotTests`, hosted by
    the catalog app, whose project takes the same folder. Each picture is the catalog's own view for
    `-WestronMatrixSheet` with the capture's launch arguments, so the theme, the contrast and the text size are applied
    as in the app; states are forced through the API as before, and `FrozenAnimations` holds a spinner still. The sheet
    reports its own layout to the tests, which have no accessibility query: the frame of its content and of each cell
    (`MatrixSheetProbe`, an environment value only they set). The picture is cut to the content, as the macOS UI test
    cut it, the window's width from the top of the sheet (on iOS under the status bar's safe area: no status bar or home
    indicator is drawn in-process, so the rule of 2026-11-19 that ignored the indicator goes) down to its bottom and the
    reach of the deepest shadow token below it, `shadow.dragged`'s 56 pt, as far as the window goes, so that a dragged
    surface's shadow is compared whole. A picture fails by name, as the UI test's did, when a cell lies outside the
    window on either axis ("cut off") or a cell draws nothing (the drawn cells are counted against the matrix). The
    pictures are opaque RGB, the alpha channel only cost space. Locally (an M4 Pro, macOS 26.7.1, the iPhone 17
    simulator on iOS 26.3.1) the 388 iOS images take about 37 s and the 196 macOS images 15 s, about 0.1 and 0.08 s an
    image. The tests run only when `WESTRON_SNAPSHOTS` names a directory, so `swift test` and `tools/apple/check.sh
    package` skip them.
  - **The main thread between draws.** The first CI run (44835019906) drew the last five iOS pictures of the matrix
    blank, four times each, after the draws had slowed from 0.3 s to 5 s over the run. The cause was the test, not those
    sheets: the whole matrix ran as one job on the main queue, and `RunLoop.main.run(until:)` inside a job does not
    serve the main queue, so what UIKit and SwiftUI scheduled there never ran, the release of each picture's window and
    hosting controller among it. Every window and controller ever made stayed alive, 388 of 388, with its layers, and a
    local run grew to 4.2 GB, against the runner's 7 GB. Now the test is asynchronous and the main thread goes back to
    its run loop before every draw and while a sheet settles; each draw runs in its own autorelease pool, and a window
    leaves the scene when its picture is done. One window and one controller are alive at a time, and the process stays
    near 90 MB; the pictures are pixel for pixel those of before. On the runner (run 44841056509, the same VM: an M1
    with 3 cores and 7 GB, 134 MB free at the start), drawn this way all 388 pictures came out at their first draw, the
    five that had failed among them, in 147 s, 0.38 s an image against 1.2 s in the failing run, and the process ended
    at 63 MB; drawn the old way in the same job, the matrix had not finished after 15 minutes. A draw that gives no
    complete picture (no frame reported, `drawHierarchy` returning false, fewer than three colors) is taken again, four
    draws in all with a longer pause each, and then the picture fails by name with every draw's outcome; any retry,
    and on iOS a draw slower than 1.5 s, is taken a second time and must agree pixel for pixel, against a draw that the
    render server cut short. macOS draws with `CARenderer` in the process, with no server to fall behind and no
    incomplete draw ever seen, and its ordinary draws take up to 5.4 s on the runner, where a 1.5 s check doubled 35 of
    196 draws for nothing (run 44846443416), so a slow macOS draw is not checked.
  - **Fidelity.** In the same environment the in-process pictures match the UI test's: on iOS, of Checkbox's and Rule's
    26 images, 21 are pixel for pixel the same and 5 the same except where the UI test's status bar covered the top of a
    sheet that overflows the safe area (Checkbox's twelve list colors); on macOS, Text field's 40 images show the same
    layout, with a color one level off across the canvas (the window server's screenshot) and edges a few levels off.
    One difference is a defect of the old capture, not of the new: on macOS the UI test's window was key, so the first
    `SecureField` of the rest row drew a focus ring; in-process it draws at rest, as the contract asks. Seen again on
    2026-11-21 in a UI-test capture of `main` (fac36da).
  - **References** are in `platforms/apple/Snapshots/<platform>/`, PNGs in Git LFS, beside `environment.json`, plain
    text: the environment they were made in (the Mac's macOS and processor, Xcode, on iOS the simulator's runtime and
    device, the scale) and the number of images. Environments still differ in every image (locally and on the runner, in
    text and symbol anti-aliasing), so the references are made on the CI runner only, by the workflow
    `snapshot-references.yml` (by hand on a branch, or the label `record-snapshots` on a pull request), which commits
    them to that branch. `tools/apple/snapshot-matrix.sh check <platform>` compares a render with them and reports every
    change on a page, the reference, the new picture and a diff side by side; in an environment other than the
    references' it says so and compares nothing (exit 4), and with no references yet it says that (exit 3); `record`
    writes them, and refuses a render with a failed picture, which would otherwise delete that picture's reference. A
    pixel whose every channel differs by at most one level counts as the same: within one environment runs drift by a
    level in a few pixels of a shadow or an edge. A full set is about 77 MB (60 iOS, 17 macOS, measured locally): the
    RGB pictures cut to the sheet are 21 % smaller than RGBA of the whole window, and the encoder's level is not
    ImageIO's to set (a stronger zlib saved about 15 % more, not worth a dependency). `.lfsconfig` excludes the
    references from what Git LFS fetches by default: a clone or a SwiftPM checkout of westron does not download them,
    and without it a SwiftPM-style checkout (a clone of a local mirror) on a machine with Git LFS fails, the objects
    being nowhere to smudge from; CI pulls them explicitly, from a cache keyed by their object ids, pruned to the
    current set before it is saved (`git lfs prune` with the exclusion emptied: with it, prune deleted the current
    objects too).
  - **CI.** A job `snapshots` in `ci.yml` renders both platforms on every pull request and push to `main` and checks
    them: a difference fails it, and it uploads the report and the new pictures; with no references, or references from
    another runner image, a pull request passes with a warning that they need recording, and a push to `main` fails, so
    that a check that compares nothing does not stay green unnoticed. The runner image's name and version are recorded
    beside the environment for the reader, not compared: a weekly image version changes no picture by itself. Both runs
    so far had the same machine, "Apple M1 (Virtual)"; whether the pool is uniform is not known. It replaces the job
    "Catalog screenshots" (the agent's `catalog-screenshot.sh` stays) and `snapshot-matrix.yml` with its legs. The
    review surface of the second gate (decisions/0005) is the job's report of what changed against the references, and
    the full page of the render, an artifact of every run. The UI test `SnapshotMatrixTests` and the capture's retry,
    stall and deadline machinery are removed, and so is `merge`.
  - **Reproducible within a run** (#99). Pull request #98, which changed only a UI test file that the render does not
    build, failed the check on macOS
    (run 44885247356): seven text-field pictures in a row, in dark-hc, had every AppKit text field (the system field
    under SwiftUI's TextField) one point taller for a line, and nothing else in them or in the other 189 changed; every
    other run of the same code matched. It ended within one picture, so it was the process's state on the runner at
    that time, not the sheets, their order or the theme. It was not reproduced locally, and its cause is not
    identified; nothing below fixes it. What is known: under `swift test` the process took the Mac's languages, which
    the in-process render had stopped pinning (the UI test's launch arguments did), and AppKit measures a text style's
    line by them (16 pt with English, 17.3, 18.3 or 21 with some others among the languages), taking them anew after a
    change of the machine's preferences. That dependency is removed: on macOS the test pins `AppleLanguages` `en` and
    `AppleLocale` `en_US` in its argument domain, as xcodebuild's `-testLanguage en -testRegion en_US` does on iOS, and
    logs the languages and locale it had before. It does not account for run 44885247356, whose fields grew by 1 pt,
    not the 1.3 pt or more a language gives. Two checks are there to name the state when it occurs again, instead of
    letting it read as a change to a pull request: a picture fails, named, when a fresh AppKit field cell measures a
    line otherwise than at the start of the run (a proxy for the fields drawn: the picture may still be the same as a
    normal render); and each component's first picture in each capture is drawn again at the end and must give the
    same pixels. Either failure logs what could identify the state: the metrics and languages, the capture's theme and
    the app's appearance, the accessibility display options, the key window and first responder, and the time into the
    run.
    Neither noticed the second occurrence, on `main` (run 44917113978: one text-field sheet in light-hc): a fresh cell
    measured 16 pt at the start and the end, and the pictures drawn again agreed with their first draws. A probe on
    the runner (run 44932481160) then caught the state: SwiftUI laid out the AppKit field under a `TextField` 17 pt
    high while the field's own `intrinsicContentSize` and `cell.cellSize` said 16 (on another runner, 16 for a field in
    Onest whose line is 17), and the process stayed in it. So the laid-out height disagrees with AppKit's own by 1 pt;
    the cause is still unknown. A third check names exactly that: after each picture's layout and before its draw,
    every AppKit text field's laid-out height is compared with its cell's size at its width and, for a field that does
    not wrap, its `intrinsicContentSize`; off by more than half a pixel, the picture fails as "the render was in the
    state of #99", with each field's sizes, font and text, and is still compared as usual. Over a normal macOS render
    every field agrees. The two earlier checks stay: the pin and the fresh cell guard a proven dependency on the
    languages, and the drawing again a state that ends within the run.
  The details (the tolerance of one level, the cut to the sheet, the exit statuses, the gate on an environment variable)
  were chosen in the implementation, pending the owner's confirmation.
