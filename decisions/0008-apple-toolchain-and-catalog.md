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
    system setting rather than of the component.
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
