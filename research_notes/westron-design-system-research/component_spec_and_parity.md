# One component spec, native implementations with identical names: shared library vs. spec plus per-platform code (state as of Nov 2026)

Scope note: research run 2026-11-14. Primary artifacts (repo files, schemas, source signatures) were read directly from GitHub with `gh api` where possible. Repo status ("last push") values are from the GitHub API on 2026-11-14.

## Q1. Machine-readable component spec formats that exist today: what they contain, and whether they drive codegen or conformance checks

### Takeaway
Two open, actively developed formats now cover the whole component contract. **Adobe Spectrum design-data** (`component.schema.json`, spec `1.0.0-draft`) records options/variants, constraints, slots, anatomy, states with a resolution algorithm, token bindings, per-platform a11y adapters and an `implementations[]` registry, and it ships a CI-gateable validator plus conformance fixtures. **Nathan Curtis's Spectacular** (`@directededges/specs-schema`, created Apr 2026) is generated from Figma and records props, variants, elements, layout, styles and slots, with emitters for React and Lit. Custom Elements Manifest, Figma Code Connect, Open UI and DTCG each cover only one slice. None of these formats generates production SwiftUI or Compose components. On native platforms they are used as input for token codegen, for conformance and drift checks, and as grounding for agents.

### Cited Findings
**Adobe Spectrum design-data (`adobe/spectrum-design-data`, active, pushed 2026-11-14)**
- The repo describes itself as "Design data, including design tokens, component schemas, and tooling for Spectrum". Its packages are `component-schemas`, `design-data-spec`, `design-data`, `design-system-registry`, `token-names` and `tokens`. The `sdk/` folder holds a Rust core, CLI, wasm and TUI, and `platforms/` holds `ios`, `react-spectrum` and `web-components` — [GitHub repo](https://github.com/adobe/spectrum-design-data)
- One JSON file per component lives under `packages/design-data/components/`. About 90 components are declared, including platform-specific ones such as `bottom-navigation-android.json` — [components dir](https://github.com/adobe/spectrum-design-data/tree/main/packages/design-data/components)
- Each component declaration "MUST validate against the Layer 1 schema component.schema.json" (JSON Schema Draft 2020-12). The `options` block "mirrors the shape of @adobe/spectrum-component-api-schemas for backward compatibility" — [Component format spec](https://opensource.adobe.com/spectrum-design-data/spec/component-format/)
- Concrete `button.json` excerpt (spec `1.0.0-draft`) — [button.json](https://github.com/adobe/spectrum-design-data/blob/main/packages/design-data/components/button.json):
  - `options`: `variant` (`accent|negative|primary|secondary`, default `primary`), `style` (`fill|outline`), `size` (`s|m|l|xl`, default `m`), `isDisabled`, `isPending`, `isLabelHidden`, `icon` ($ref `workflow-icon.json`), `staticColor` (`white|black`).
  - `constraints`: e.g. `{"when":{"style":"outline"},"require":{"variant":["primary","secondary"]},"severity":"error","source":"react-spectrum S2 Button.tsx"}`, and `isLabelHidden:true` requires `icon` present.
  - `slots`: `default` (label) and `icon`. `anatomy`: `container` (contains icon, progress, label), `icon`, `progress`, `label`, and `focus-indicator` (`presentIn: ["keyboard-focus"]`), with `anatomyReview.status: "reviewed"`.
  - `states`: `hover`, `down` and `keyboard-focus` (trigger `interaction`), `disabled` (trigger `prop`).
  - `tokenBindings`: `corner-radius-button-small|large|extra-large`. `accessibility`: `role: button`, `intents: [trigger]`, `focusable: true`, `keyboardIntents: [activate]`, WCAG 2.1.1 and 4.1.2.
  - `documentBlocks`: prose guidelines (pending-state 1 s delay, min width 2.25× height, RTL mirroring, keyboard table).
  - `implementations`: only web entries (`@react-spectrum/s2` `Button`, and `@adobe/spectrum-wc/components/button` → `swc-button`).
- `implementations[]` exists "so consumers such as Code Connect generators can resolve an implementation without platform-specific configuration". `platform` is `web|ios|android`, plus an optional `implementation` id such as `react-spectrum` or `web-components` — [component-format.md](https://github.com/adobe/spectrum-design-data/blob/main/packages/design-data-spec/spec/component-format.md)
- Canonical slot vocabulary: `default`, `icon`, `label`, `help-text`, `negative-help-text`, `action`, `heading`, `description`, `hero`, `footer`, `tooltip`. Custom names are allowed, but SPEC-021 warns when they are undocumented — [component-format.md](https://github.com/adobe/spectrum-design-data/blob/main/packages/design-data-spec/spec/component-format.md)
- The "Component visual recipe" (draft/RFC) is "a renderer-neutral description of how a component looks, bound to design tokens". It produces SVG, PNG and Figma output plus anatomy and spec overlays. Its non-goals include "Pixel parity with every platform implementation" and "Describing interaction, motion or accessibility behavior". The pilot is `visuals/action-button.json` — [component-visuals.md](https://github.com/adobe/spectrum-design-data/blob/main/packages/design-data-spec/spec/component-visuals.md)
- Conformance has three layers: Layer 1 JSON Schema, Layer 2 graph rules (`SPEC-0xx` in `rules/rules.yaml`), and Layer 3 fixtures (`conformance/invalid/<RULE_ID>/` plus `expected-errors.json`). Example rules: SPEC-063 "`sizeScale` keys differ from the component's `size` values", SPEC-064 "Constraint names an undeclared option or value", SPEC-074 "Anatomy `presentIn` names an undeclared state", SPEC-081 "A `componentAliases` entry is invalid" — [conformance README](https://github.com/adobe/spectrum-design-data/blob/main/packages/design-data-spec/conformance/README.md)
- The CLI commands `validate`, `validate-dataset` and `diff` "emit `--format json` and exit 1 on failure/drift, 2 on hard error — directly CI-gateable". `resolve --format dtcg` emits W3C DTCG `$value`/`$type` output for Style Dictionary and Terrazzo — [Multi-platform SDK strategy](https://github.com/adobe/spectrum-design-data/blob/main/SPECTRUM_MULTIPLATFORM_SDK_STRATEGY.md)
- The older `@adobe/spectrum-component-api-schemas` package is described as "JSON Schema for Spectrum components. Used in the table of options on the Spectrum Design System website". Its sample button table uses `size: s/m/l/xl` and `state: default/hover/down/keyboard focus` — [component-schemas README](https://github.com/adobe/spectrum-design-data/tree/main/packages/component-schemas)
- The strategy doc lists "Component **anatomy** data (spatial relationships, layout constraints)" as still **(future)** — [strategy](https://github.com/adobe/spectrum-design-data/blob/main/SPECTRUM_MULTIPLATFORM_SDK_STRATEGY.md)

**Spectacular / "Specs" by Nathan Curtis (DirectedEdges/spectacular, repo created 2026-04-05, active)**
- "Spectacular turns a Figma component into a compact, schema-valid specification — and then turns that specification into working code, Figma canvas documentation, analysis reports, and a versioned record". Schema parts: Component/Variant, Anatomy, Props (`BooleanProp`, `StringProp`, `EnumProp`, `SlotProp`, `NumberProp`), Elements, Layout, Styles (`TokenReference`), Slots, Bindings (`PropBinding`, `Conditional`), Subcomponents, Instance examples and Conventions (`PlatformConventions`). The JSON Schema plus TS types are governed by a `CONSTITUTION.md` and ADRs — [Spectacular README](https://github.com/DirectedEdges/spectacular)
- Emitters are `react-from-specs`, `webcomponents-from-specs` (Lit) and `figma-from-specs`. They are private packages published to npm. The README lists no SwiftUI or Compose emitter — [Spectacular README](https://github.com/DirectedEdges/spectacular)
- `PlatformConventions` members include `naming` (`NONE|SENTENCE|TITLE`), `codeOnlyProps`, `slotConstraints`, `slotPrimitives` and `stylesProp` (e.g. `sx`, `style`, `modifier`), declared per platform file in `config/conventions/<platform>.yaml`. The page has no vocabulary for iOS/Android casing, boolean prefixes or size names — [Conventions schema page](https://spectacular.systems/schema/conventions/)
- Curtis on what goes into specs (Aug 14, 2026): API, variants and examples are generated from Figma. Behavior, accessibility, configurations and motion are authored supplements, which can be platform-specific (e.g. `card.accessibility.android.md`). React output is "not intended for production". iOS and Android consume specs "through factories and per-platform skills". Versioning rule: removing a prop is breaking, adding an anatomy element is minor, rebinding a token is a patch — [Spec-driven UI component development](https://nathanacurtis.substack.com/p/spec-driven-ui-component-development)
- Curtis's contract principles (Jul 28, 2026): "A description informs. A contract arbitrates." and "Independent over platform biased: A definition biased to one party's point-of-view is testimony, not a contract". Also "Verifiable over readable" and "Deterministic over inference" — [Component contracts and schemas](https://nathanacurtis.substack.com/p/component-contracts-and-schemas)
- Earlier EightShapes posts include "Component Specifications" (Feb 20, 2023), "Crafting Component API, Together" (Jul 17, 2021, on unifying anatomy and props across code and design tools) and "Subcomponents" (Jul 20, 2022). Only titles and teasers were retrieved — [EightShapes on Medium](https://medium.com/eightshapes-llc/tagged/design-systems)

**Custom Elements Manifest (web only)**
- The `schema.d.ts` `CustomElement` declaration has `tagName`, `attributes[]`, `events[]`, `slots[]`, `cssParts[]`, `cssProperties[]`, `cssStates[]`, `members[]`, `superclass`, `mixins` and `deprecated`. It has no variants, anatomy beyond slots and parts, tokens or a11y semantics. Latest schema release is v2.1.0 (2024-05-06), and the repo was last pushed 2026-07-21 — [schema.d.ts](https://github.com/webcomponents/custom-elements-manifest/blob/main/schema.d.ts)

**Figma Code Connect**
- Code Connect maps code components to Figma components. Published mappings appear in Dev Mode and "the Figma MCP server … give[s] AI agents more precise implementation details". Template files are "recommended" and "work with any codebase, regardless of framework or language". The React, HTML, SwiftUI and Jetpack Compose framework APIs are labeled "Legacy". One-to-many mapping (React + SwiftUI + Compose) is supported. On Professional plans only one framework can be active at a time — [Figma docs](https://developers.figma.com/docs/code-connect)
- The npm README says framework-specific parsers "will no longer receive updates or support" — [npm @figma/code-connect](https://www.npmjs.com/package/@figma/code-connect)
- A July 2026 forum report says SwiftUI and Compose mappings queried through MCP `get_code_connect_map` returned only the Android component — [Figma forum](https://forum.figma.com/report-a-problem-6/code-connect-get-code-connect-map-does-not-return-all-connected-platforms-56495)

**Material (component tokens)**
- Compose Material 3 component tokens are generated files. `FilledButtonTokens.kt` starts with `// VERSION: v0_11_0` and `// GENERATED CODE - DO NOT MODIFY BY HAND`. It contains `ContainerColor = ColorSchemeKeyTokens.Primary`, `DisabledContainerOpacity = 0.1f`, `DisabledLabelTextOpacity = 0.38f`, and so on. Tokens are per component × state × property. Variants and the API are hand-written in Compose — [androidx FilledButtonTokens.kt](https://github.com/androidx/androidx/blob/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/FilledButtonTokens.kt)

**Open UI**
- Open UI is "a open source collective effort to standardize names and anatomies for common UI patterns". Design systems are documented in JSON5 against a JSON schema. Research pages show "concept coverage" (which systems use which name). Anatomy in that schema is "just an array of names with a description", and an issue tracks improving it — [Design Systems Analysis guide](https://open-ui.org/design-system-analysis-guide); [open-ui#845](https://github.com/openui/open-ui/issues/845)

**DTCG**
- The Design Tokens Format Module 2025.10 is a Final Community Group Report — [W3C CG report](https://www.w3.org/community/reports/design-tokens/CG-FINAL-format-20251028/). No component-level spec was found in DTCG material. Component-token naming appears only in third-party docs — [search result summary; DTCG drafts](https://www.designtokens.org/TR/drafts/format)

**Supernova / Knapsack / zeroheight**
- Supernova's Data Manager lets teams attach custom metadata properties to components, for docs or "export metadata to code" — [Supernova guide](https://supernova.io/guides-content/1-3-how-to-manage-component-metadata). The Supernova SDK README lists the Metadata API among unsolved areas — [SDK README](https://cdn.jsdelivr.net/npm/@supernovaio/sdk@2.4.8/README.md). No public component-schema format was found for any of the three vendors.

### Inferences
- Spectrum's component JSON is the most complete open model for westron to borrow from: options + constraints + slots + anatomy + states + tokenBindings + a11y + implementations. Its vocabulary is React-biased, though: `isDisabled`, `isPending` and `isLabelHidden`, constraints whose `source` is "react-spectrum S2 Button.tsx", and only web entries in `implementations`. That is the "testimony, not a contract" failure Curtis warns about. Westron should keep spec names platform-neutral, e.g. `disabled` / `pending` / `labelHidden` or concept ids, and let a per-platform conventions layer render them as `isDisabled`, `disabled` or `enabled`.
- No open format today generates native SwiftUI or Compose components. Every "spec → code" pipeline found emits web code (React or Lit) or tokens only. For native platforms the spec acts as a contract and as grounding for agents, not as a compiler input.
- Spectrum's split into Layer 1 schema, Layer 2 graph rules and Layer 3 fixtures is a pattern a one-person team can copy cheaply. JSON Schema plus a handful of rule checks in CI catch spec drift before any platform code exists.

### Gaps
- Microsoft Fluent 2 publishes per-platform guidance pages, but no machine-readable cross-platform component spec was found. Fluent's archived `fluentui-token-pipeline` covered tokens only (see Q3).
- I could not retrieve full text of Curtis's 2021–2023 EightShapes articles (Medium paywall/teasers only), nor a public Material component-spec JSON beyond generated token files.
- No evidence was found that Spectrum's iOS implementation (private `OneAdobe/spectrum-ios`) consumes `component.schema.json` options for API generation. Only tokens feed its Swift codegen.

## Q2. Evidence on the three architectures: (a) shared UI runtime, (b) shared non-UI design core plus native UI, (c) platform-neutral spec plus native handwritten or generated components

### Takeaway
Products held to a native-quality bar converge on (b) or (c): shared data or logic, with UI written separately per platform. The strongest 2026 data point is **Shopify leaving React Native (Sep 10, 2026) because "LLMs changed one of the core assumptions"**. Agents now make per-platform implementation cheap, so the cost moves to "shared specifications, tests, and review checkpoints". Adobe Spectrum explicitly considered a shared Rust core with UniFFI/JNI bindings to native code and **never built it**. It ships a resolved-data contract plus per-platform generators instead.

### Cited Findings
**(a) Shared UI runtimes (comparison point only)**
- Shopify, Jan 2025: "Over the past 5 years, we have migrated all our apps to React Native", reporting P75 screen loads under 500 ms and crash-free sessions above 99.9% — [Five years of React Native at Shopify](https://shopify.engineering/five-years-of-react-native-at-shopify)
- Shopify, Sep 10, 2026 ("Back to native", Mustafa Ali) — [shopify.engineering/back-to-native](https://shopify.engineering/back-to-native); secondary: [InfoQ](https://www.infoq.com/news/2026/09/shopify-drops-react-native/):
  - "LLMs changed one of the core assumptions behind our 2020 decision." Agents "can now do enough of the implementation, translation, testing, and review work". "Agents have reduced the advantages of sharing implementation."
  - React Native apps "can be fast. Ours are". Native keeps apps "closer to platform capabilities and first-party tooling".
  - The Shop app was rebuilt natively, from proof of concept to app-store release in 12 weeks. The Shopify app (300+ screens) is in progress.
  - Agents implemented features on one platform "using the other as a reference". Shopify chose a greenfield rebuild.
  - The Helix system gates checkpoints: each must pass tests, "match the running app visually", and "survive two adversarial code reviewers" before human approval.
  - Business logic was decoupled from the UI to run headlessly on desktop, so agents iterate "in milliseconds instead of minutes".
  - The cross-platform mechanism named is process-level: "shared specifications, tests, and review checkpoints".
- Airbnb, June 2018, announced it would sunset React Native and return to native. It "still heavily relies on its universal design language system (DLS)" across Android and iOS — [Sunsetting React Native](https://medium.com/airbnb-engineering/sunsetting-react-native-1868ba28e30a) (summary via search results)
- Compose Multiplatform for iOS has been Stable since 1.8.0 (May 2025) — [JetBrains blog](https://blog.jetbrains.com/kotlin/2025/05/compose-multiplatform-1-8-0-released-compose-multiplatform-for-ios-is-stable-and-production-ready/). In 1.11.0 (May 2026) a "new native text input on iOS is opt-in", while the existing cross-platform text input stays the default — [What's new 1.11](https://kotlinlang.org/docs/multiplatform/whats-new-compose-111.html)
- Generative UI: A2UI ("agents stream layout data, and apps render it with native components in React, Angular, Lit, Flutter, SwiftUI and Jetpack Compose") is active, with 17.3k stars as of Nov 2026 — [a2ui-project/a2ui](https://github.com/a2ui-project/a2ui); [roadmap](https://a2ui.org/roadmap/)
- Slint (declarative toolkit for Rust/C++/JS) is active — [slint-ui/slint](https://github.com/slint-ui/slint)

**(b) Shared non-UI core plus native UI**
- 1Password 8: the Rust "Core" holds as much as feasible "stopping short of the user interface". iOS uses SwiftUI plus some UIKit, Android uses a native toolkit, and Mac and Windows use web UI (Electron) — [1Password 8: The Story So Far](https://1password.com/blog/1password-8-the-story-so-far)
- Signal: separate native clients (`Signal-iOS` in Swift, `Signal-Android` in Kotlin, `Signal-Desktop` in TypeScript/Electron) plus a shared Rust `libsignal` — [Signal-iOS](https://github.com/signalapp/Signal-iOS), [Signal-Android](https://github.com/signalapp/Signal-Android), [libsignal](https://github.com/signalapp/libsignal)
- Telegram: per-platform native clients (`Telegram-iOS` in Swift, `DrKLO/Telegram` in Java, `tdesktop` in C++/Qt) plus a shared C++ `tdlib` ("Cross-platform library for building Telegram clients") — [Telegram-iOS](https://github.com/TelegramMessenger/Telegram-iOS), [tdesktop](https://github.com/telegramdesktop/tdesktop), [tdlib/td](https://github.com/tdlib/td)
- Bitwarden: Rust `sdk-internal` is active — [bitwarden/sdk-internal](https://github.com/bitwarden/sdk-internal). Shared-core toolkits Crux (Rust core with native shells) and UniFFI are active (pushed Nov 2026) — [redbadger/crux](https://github.com/redbadger/crux), [mozilla/uniffi-rs](https://github.com/mozilla/uniffi-rs)
- Spectrum's status note: an earlier draft described "per-platform `generated/` SDKs, and UniFFI/JNI/FFI bindings — that was **never built**". What shipped is a Rust core exposed as CLI, wasm and MCP, plus per-platform manifest repos. "Native FFI bindings: UniFFI (Swift), JNI (Android/Kotlin), FFI (Qt/C++)" remain "Aspirational / not yet scoped" (doc reconciled 2026-08-20) — [strategy](https://github.com/adobe/spectrum-design-data/blob/main/SPECTRUM_MULTIPLATFORM_SDK_STRATEGY.md)
- In Spectrum's reference architecture the platform team owns "the native library and its code generator, now fed by a resolved dataset rather than a bespoke merge". The iOS `tokentool` `generate-source-code` "keeps owning Swift codegen" — [strategy](https://github.com/adobe/spectrum-design-data/blob/main/SPECTRUM_MULTIPLATFORM_SDK_STRATEGY.md)

**(c) Platform-neutral spec plus native implementations**
- Airbnb's Ghost Platform uses a single GraphQL schema that serves web, iOS and Android and generates typed models per platform, with abstract section components in TypeScript, Swift and Kotlin — [Airbnb SDUI deep dive (2021)](https://medium.com/airbnb-engineering/a-deep-dive-into-airbnbs-server-driven-ui-system-842244c5f5)
- Lyft: "We don't even announce a component as ready to use until it is complete in design, Android, and iOS", and "We treat this lack of parity like a bug" — [A System Built on Parity](https://www.designsystems.com/a-system-built-on-parity-how-to-treat-all-of-your-users-equally/)
- Spotify Encore: a shared foundation of tokens, a shared button hierarchy and size framework, and "our cross-platform naming system is now a staple". Components are defined by a shared "outline" (terms, anatomy, variants, states), and focus states are platform-dependent — [How Spotify's design system goes beyond platforms](https://designsystems.com/how-spotifys-design-system-goes-beyond-platforms/)
- Skyscanner Backpack keeps separate native repos (`backpack-ios` with SwiftUI, `backpack-android` with Compose), both active in Nov 2026. The public web repo `Skyscanner/backpack` is **archived**: the final public release is `@skyscanner/backpack-web@43.16.0`, and "Internal Skyscanner users should continue contributing in the `design-system` repository" (last push 2026-08-05) — [Skyscanner/backpack](https://github.com/Skyscanner/backpack), [backpack-ios](https://github.com/Skyscanner/backpack-ios), [backpack-android](https://github.com/Skyscanner/backpack-android)
- Microsoft Fluent: separate native libraries `fluentui-apple` ("UIKit and AppKit controls", with SwiftUI styles) and `fluentui-android` (tokenized Compose controls), both active in Nov 2026 — [fluentui-apple](https://github.com/microsoft/fluentui-apple), [fluentui-android](https://github.com/microsoft/fluentui-android)
- Google: MDC-Android (Views) is in **maintenance mode** after I/O 2026. Material is "all-in" on Compose, so Material's native Android surface is one Compose library — [MDC-Android README](https://github.com/material-components/material-components-android); [Android Compose-first post](https://android-developers.googleblog.com/2026/05/android-ui-development-is-compose-first.html)

### Inferences
- For westron (one developer plus an AI agent, with native UI required), the evidence favours a mix of (b) and (c). Use (c) for components: one spec, native code written per platform. Use (b) only for tokens: generated constants, with no runtime FFI. Shopify and Adobe both moved implementation-sharing out of the runtime and into specs, tests and resolved data. Adobe explicitly declined an FFI-shared core even with a large team.
- A Rust/UniFFI or KMP "design core" makes sense only if westron has real non-UI logic to share (validation, formatting, state machines). Tokens and variant→style mapping are better served by codegen into plain Swift, TS and Kotlin constants, which also keeps watchOS and WASM builds simple.
- Shopify's Helix gates (tests, visual match against a reference app, two adversarial AI reviews) are the most concrete published recipe for an agent-maintained multi-platform codebase. They transfer directly to "agent implements each platform from one spec".

### Gaps
- No primary 2025–2026 posts were found from Linear, Things (Cultured Code), Duolingo, Cash App, Uber or Dropbox on design-system architecture. Their stacks are not asserted here.
- Airbnb's 2018 post was confirmed only via search snippets and secondary coverage. The medium.com fetch was not attempted because of 403s on Medium.

## Q3. Code generation of components from specs: what worked, what was abandoned, and how LLM agents change the calculus

### Takeaway
Full **component** codegen from a neutral spec has repeatedly stalled. Airbnb's Lona has been dormant since Jan 2023 (still "Developer Preview"), Diez since Dec 2022, and Cash App's Redwood was marked "no longer under active development" in Nov 2025. Mitosis is active but web-only in practice. **Token** codegen is the part that has survived (Style Dictionary v5.8.0 was released Nov 2026, and Material 3 component tokens are generated). In 2026 the pattern shifted to deterministic spec extraction and validation plus agent-implemented native code, with scaffolds rather than production emitters.

### Cited Findings
- **Lona (Airbnb)**: "A tool for defining design systems and using them to generate cross-platform UI code, Sketch files…". The README says "Lona (Developer Preview)" and "Airbnb doesn't provide support for this project". The repo is not archived, but the last push was **2023-01-04** — [Lona/Lona](https://github.com/Lona/Lona)
- Lona's rationale: Airbnb's DLS spanned web, iOS, Android and React Native. "Design files required manual translation to code for each of the 4 platforms… time consuming and error prone". Many decisions "can't be recorded in design files", so "the individual engineer on each platform often makes a judgement call, resulting in subtle inconsistencies". Its premise: "If an engineer can manually translate this file format into UI code with 100% accuracy, then fundamentally we should also be able to use this file format to generate the UI code" — [Lona background](https://github.com/Lona/Lona/blob/HEAD/docs/overview/background.md)
- **Diez**: "The Design Token Framework". It transpiled TypeScript tokens into native packages for iOS, Android and Web. Last push was **2022-12-10** — [diez/diez](https://github.com/diez/diez)
- **Redwood (Cash App)**: "Multiplatform reactive UI for Android, iOS, and web using Kotlin and Jetpack Compose" (schema-defined widgets bound to native views). The README line "**This project is no longer under active development.**" was added in the v0.19.0 commit on **2025-11-06**, and the last push was 2026-01-09 — [cashapp/redwood](https://github.com/cashapp/redwood); [commit e12c0f36](https://github.com/cashapp/redwood/commit/e12c0f36)
- **Mitosis (Builder.io)**: active, with 0.14.2 released 2026-10-28. It "Compiles to React, Vue, Qwik, Solid, Angular, Svelte, and more". The generator directories are alpine, angular, html, liquid, lit, marko, qwik, react, react-native, rsc, solid, stencil, svelte, **swift**, taro and vue. There is no Kotlin/Compose or GTK target, and the last substantive commits to the swift generator were in April 2025 — [BuilderIO/mitosis](https://github.com/BuilderIO/mitosis); [generators dir](https://github.com/BuilderIO/mitosis/tree/main/packages/core/src/generators)
- **Token pipelines**: Microsoft's `fluentui-token-pipeline` ("generates source code for Fluent UI libraries") is **archived** (last push 2024-06-18) — [microsoft/fluentui-token-pipeline](https://github.com/microsoft/fluentui-token-pipeline). Salesforce Theo is **archived** (last push 2025-06-09) — [salesforce-ux/theo](https://github.com/salesforce-ux/theo). Style Dictionary is active, with v5.8.0 released 2026-11-03 — [style-dictionary](https://github.com/style-dictionary/style-dictionary)
- **Spectacular** (2026) generates React (CSS + TS contract + scaffold + Storybook) and Lit from specs. Curtis says the React output is "not intended for production". iOS and Android use "factories and per-platform skills" (agents) grounded by specs — [Spec-driven UI component development](https://nathanacurtis.substack.com/p/spec-driven-ui-component-development); [Spectacular](https://github.com/DirectedEdges/spectacular)
- Spectacular argues for computation over inference in spec *extraction*: "~1 sec (CLI) / ~10 sec (plugin) per component" and "0 tokens", against "~5–10 minutes per component" and "25/50/100,000+ tokens" for agentic Figma extraction. These are vendor claims from the README. It ships Claude Code skills (`specs skills install`) — [Spectacular README](https://github.com/DirectedEdges/spectacular)
- Curtis's open question: "Should one code implementation be the reference that others derive from, or should all implementations be peers?" — [Spec-driven UI component development](https://nathanacurtis.substack.com/p/spec-driven-ui-component-development)
- Spectrum's agent surface ships in the repo: `CLAUDE.md`, `AGENTS.md`, `.mcp.json`, `llms.txt`, `tools/design-data-agent-mcp` (`npx @adobe/design-data-agent-mcp`) and `tools/design-data-skill` — [repo root](https://github.com/adobe/spectrum-design-data); [strategy](https://github.com/adobe/spectrum-design-data/blob/main/SPECTRUM_MULTIPLATFORM_SDK_STRATEGY.md)
- Shopify: agents implement features on one platform using the other as reference, behind test, visual and adversarial-review gates — [Back to native](https://shopify.engineering/back-to-native)
- Generic spec-driven development tooling (GitHub Spec Kit, Kiro, Tessl) treats the spec as source of truth, with agents generating the implementation. No design-system-specific usage was found in those sources — [GitHub blog on Spec Kit](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)

### Inferences
- The failure mode of Lona, Diez and Redwood was owning a compiler for every target language and keeping it in step with SwiftUI, Compose and web idioms. An AI agent replaces that compiler with a per-platform "skill" or prompt plus tests. It costs less to maintain but is non-deterministic, so it must be paired with mechanical checks (Q5).
- The recommended split for westron:
  - Deterministic codegen where output is pure data: tokens, enums for variant/size names, maybe a generated "API surface" stub or protocol per platform.
  - Agent-written code where idiom matters: view bodies, interaction, a11y, animation.
- Generating only the API skeletons (enums and parameter lists) from the spec forces name parity at compile time while leaving the implementation idiomatic.

### Gaps
- No published post-mortem explains why Lona stalled (the maintainer moved on? Airbnb priorities?). Only repo inactivity is evidenced.
- No 2026 primary source was found showing an agent generating production SwiftUI and Compose components from a component JSON spec, beyond Shopify's general app work and Curtis's "factories" description.

## Q4. API-naming parity: mapping one spec onto idiomatic Swift, TS/web, Kotlin Compose and GTK, and where idioms force divergence

### Takeaway
Mature multi-platform systems **do not achieve identical names** in practice. In Backpack the iOS `Style` enum is applied via a `.buttonStyle(_:)` method while Android has a `type: BpkButtonType` parameter. In Fluent the iOS `ButtonStyle` has 11 cases (`accent`, `outline`, `subtle`, `danger`…) while Android has `Button/OutlinedButton/TextButton`, and sizes are `ButtonSizeCategory` vs `ButtonSize`. Name parity has to be designed in: one neutral vocabulary in the spec, plus a per-platform conventions table for casing, booleans, enum style and modifier-vs-parameter. Spectrum's manifest (`formatting.casing`, `componentAliases`) and Spectacular's `PlatformConventions` are early, partial versions of that table.

### Cited Findings
**Backpack (Skyscanner): same system, divergent API names**
- SwiftUI: `BPKButton(_ title: String, icon: Icon? = nil, loading: Binding<Bool> = .constant(false), enabled: Binding<Bool> = .constant(true), size: BPKButton.Size = .default, action:)`. The style is applied via `public func buttonStyle(_ style: BPKButton.Style) -> BPKButton`, and there is also `.stretchable()`. `Size` = `.default`, `.large`. `Style` = `.primary`, `.secondary`, `.destructive`, `.featured`, `.link`, `.primaryOnDark`, `.primaryOnLight`, `.secondaryOnDark`, `.secondaryOnContrast`, `.linkOnDark` — [BPKButton.swift](https://github.com/Skyscanner/backpack-ios/blob/HEAD/Backpack-SwiftUI/Button/Classes/BPKButton.swift), [BPKButtonStyle.swift](https://github.com/Skyscanner/backpack-ios/blob/HEAD/Backpack-SwiftUI/Button/Classes/BPKButtonStyle.swift)
- Compose: `BpkButton(text: String, modifier: Modifier = Modifier, size: BpkButtonSize = DefaultSize, type: BpkButtonType = DefaultType, enabled: Boolean, loading: Boolean, onClick)`. `BpkButtonSize { Default, Large }`, `BpkButtonType { Primary, Secondary, Featured, PrimaryOnDark, PrimaryOnLight, SecondaryOnDark, SecondaryOnContrast, Destructive, Link, LinkOnDark }`, `BpkButtonIconPosition { Start, End }` — [BpkButton.kt](https://github.com/Skyscanner/backpack-android/blob/HEAD/backpack-compose/src/main/kotlin/net/skyscanner/backpack/compose/button/BpkButton.kt)
- Observed differences: the variant axis is "style" on iOS and "type" on Android; iOS takes a `Binding<Bool>` for `loading`/`enabled` where Compose takes a plain `Boolean`; and iOS applies the variant via a modifier-like method while Compose takes it as a parameter. The value sets match (same sources as above).

**Fluent (Microsoft): same design language, divergent enums**
- iOS: `public enum ButtonStyle` with `accent, outline, outlineAccent, outlineNeutral, subtle, transparentNeutral, danger, dangerOutline, dangerSubtle, floatingAccent, floatingSubtle`, and `public enum ButtonSizeCategory { large, medium, small }`. The SwiftUI bridge is `public struct FluentButtonStyle: SwiftUI.ButtonStyle { public init(style: ButtonStyle) }`, which must qualify `SwiftUI.ButtonStyle` to avoid the name clash. Tokens are a `ButtonToken` enum (`backgroundColor`, `backgroundPressedColor`, `borderFocusedColor`, `cornerRadius`…) — [ButtonTokenSet.swift](https://github.com/microsoft/fluentui-apple/blob/HEAD/Sources/FluentUI_iOS/Components/Button/ButtonTokenSet.swift), [FluentButtonStyle.swift](https://github.com/microsoft/fluentui-apple/blob/HEAD/Sources/FluentUI_iOS/Components/Button/FluentButtonStyle.swift)
- Android Compose: `fun Button(onClick, modifier, style: ButtonStyle = ButtonStyle.Button, size: ButtonSize = ButtonSize.Medium, enabled: Boolean = true, interactionSource, icon: ImageVector?, trailingIcon: ImageVector?, text: String?, contentDescription: String?, buttonTokens: ButtonTokens?)`, with `enum class ButtonStyle { Button, OutlinedButton, TextButton }` and `enum class ButtonSize { Small, Medium, Large }` — [Button.kt](https://github.com/microsoft/fluentui-android/blob/HEAD/fluentui_controls/src/main/java/com/microsoft/fluentui/tokenized/controls/Button.kt), [ButtonTokens.kt](https://github.com/microsoft/fluentui-android/blob/HEAD/fluentui_core/src/main/java/com/microsoft/fluentui/theme/token/controlTokens/ButtonTokens.kt)
- Fluent Android uses the unprefixed name `Button` in its own package (`com.microsoft.fluentui.tokenized.controls`). Fluent iOS and Backpack prefix (`FluentButtonStyle`, `BPKButton`) — same sources as above.

**Platform idioms that force divergence**
- SwiftUI `ControlSize` has `mini`, `small`, `regular` (default), `large` and `extraLarge` ("Resolves to large on platforms other than visionOS"). It is applied via the `controlSize(_:)` view modifier and the `EnvironmentValues.controlSize` environment value ("Sets the size for controls within this view"). Availability: iOS 15, macOS 10.15, watchOS 9, visionOS 1 — [Apple ControlSize docs](https://developer.apple.com/documentation/swiftui/controlsize)
- libadwaita/GTK4: button variants are **CSS style classes**, not properties: `.suggested-action` ("use accent colors"), `.destructive-action`, `.flat`, `.raised`, `.circular`, `.pill`, `.osd`, and `.opaque` (deprecated since 1.6). Flatness can also come from the `GtkButton:has-frame` property. There are **no dedicated button size classes** — [libadwaita style classes](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/style-classes.html)
- Web: Custom Elements expose `attributes`, `properties`, `slots`, `cssParts`, `cssProperties` and `cssStates` as separate API channels. A Swift or Kotlin enum parameter maps to an attribute plus a property, a slot maps to a named `<slot>`, and anatomy maps to `::part()` — [CEM schema.d.ts](https://github.com/webcomponents/custom-elements-manifest/blob/main/schema.d.ts)
- Spectrum spec sizes are `s|m|l|xl` (T-shirt). Backpack uses `default|large`, Fluent `small|medium|large`, Apple `mini|small|regular|large|extraLarge` — [button.json](https://github.com/adobe/spectrum-design-data/blob/main/packages/design-data/components/button.json); Backpack, Fluent and Apple sources above.
- Spectrum's platform manifest has a `formatting` block: `casing` (`kebab-case|camelCase|PascalCase|SCREAMING_SNAKE_CASE`), `delimiter`, `abbreviations` and `prefix`. It is **"Schema-declared only, not yet applied by the reference SDK"**, and it applies to token names, not component APIs. `componentAliases` maps foundation names to platform components, e.g. `{ "button": "button-ios", "switch": "switch-ios" }` in `platforms/ios/manifest.json` (which also sets `"formatting": {"casing": "camelCase"}` and pins `foundationVersion: 3.6.0`) — [manifest.md](https://github.com/adobe/spectrum-design-data/blob/main/packages/design-data-spec/spec/manifest.md); [platforms/ios/manifest.json](https://github.com/adobe/spectrum-design-data/blob/main/platforms/ios/manifest.json)
- Spectacular's `PlatformConventions.stylesProp` names the per-platform escape hatch for unmapped styling (`sx`, `style`, `modifier`). Slot-name matching is configurable (`specs.slots.default.match: [children, items]`) — [Conventions schema](https://spectacular.systems/schema/conventions/)
- Lyft: "For everything we build, a single name is a must." It chose "header" over "navigation bar" because that term means the top bar on iOS but the bottom bar on Android, and "sheet" over action sheet or bottom sheet — [Lyft parity article](https://www.designsystems.com/a-system-built-on-parity-how-to-treat-all-of-your-users-equally/)
- Spotify agrees naming conventions across platforms before building — [Spotify Encore article](https://designsystems.com/how-spotifys-design-system-goes-beyond-platforms/)

### Inferences
- Concrete implications for westron's `Button(variant: .primary, size: .m)` / `Button(variant = Primary, size = M)`:
  - **Name collision.** An unprefixed `Button` collides with `SwiftUI.Button` in any file that imports SwiftUI. Fluent hit the same problem with `ButtonStyle`. Options are a module-qualified name (`Westron.Button`), a prefix (`WButton`), or shadowing with documentation. In Kotlin, collision with `material3.Button` is resolved by imports, as Fluent Android shows.
  - **Size names.** `.m` reads oddly in Swift, where Apple's idiom is `.small/.regular/.large` via `.controlSize`. If westron wants `.s/.m/.l` on every platform it is choosing parity over idiom, which is defensible as long as it is consistent. Separately, consider honoring `@Environment(\.controlSize)` as a fallback so westron components sit naturally inside native containers.
  - **Variant mechanism.** A SwiftUI-idiomatic design passes variant via a `ButtonStyle` or environment (`.westronVariant(.primary)`) so it cascades. A parity-first design uses init parameters, as Backpack Android and Fluent Android do. Pick one rule per concept and record it in the conventions table, e.g. "visual axis = init parameter on all platforms; cascading theme/density = environment/CompositionLocal/CSS custom property".
  - **Booleans.** Spectrum uses `isDisabled` while Compose and Backpack use `enabled`. Choose one canonical spec name (e.g. `disabled`) and a per-platform rendering, where `enabled: Boolean = true` in Kotlin is idiomatic.
  - **GTK.** Westron variants should map to CSS classes on stock widgets (e.g. `primary` → `.suggested-action`, `danger` → `.destructive-action`). Sizes need westron-defined CSS because libadwaita has none.
- The cheapest way to guarantee identical names is to **generate the enums** (Variant, Size, and so on) for each platform from the spec, plus a small per-platform casing rule. Hand-written or agent-written code then cannot drift, because a renamed case fails compilation.

### Gaps
- No design system was found that documents a full four-platform API mapping table (Swift/TS/Kotlin/GTK) for the same component. No GTK or Rust design-system implementation with cross-platform naming was found.
- Apple's ButtonStyle, PrimitiveButtonStyle and ButtonRole idioms were not re-fetched in this session (only ControlSize was), so they are noted in inferences only.

## Q5. Verifying parity: conformance suites, spec-driven snapshots, cross-platform visual regression, API linting, status matrices

### Takeaway
No turnkey cross-platform parity framework exists. Leading practice combines four layers:
1. **Spec validation** (JSON Schema plus graph rules plus fixtures, exit codes in CI: Spectrum).
2. **Implementation-metadata verification** against source (Spectrum `s2-implementation-metadata`).
3. **Per-platform snapshot suites** (swift-snapshot-testing, Paparazzi/Roborazzi, Playwright), compared against a **reference rendering**: Spectrum compares iOS simulator captures with renderer output, and Shopify gates on "match the running app visually".
4. **Process gates**: Lyft's "not ready until on all platforms", parity gaps treated as bugs.

### Cited Findings
- Spectrum CLI: `validate`, `validate-dataset` and `diff` exit 1 on failure or drift. The roadmap includes a reusable GitHub Action running `validate-dataset --strict --format json`, `validate-manifest` and a foundation-drift `diff` gating platform-repo PRs — [strategy](https://github.com/adobe/spectrum-design-data/blob/main/SPECTRUM_MULTIPLATFORM_SDK_STRATEGY.md)
- Spectrum Layer 3 conformance fixtures: `invalid/SPEC-0xx/` plus `expected-errors.json`, e.g. SPEC-063 size-scale mismatch, SPEC-064 constraint on an undeclared option, SPEC-075 "Recipe and anatomy disagree on the states a part shows in", SPEC-076 "A platform manifest drops a token a recipe binds" — [conformance README](https://github.com/adobe/spectrum-design-data/blob/main/packages/design-data-spec/conformance/README.md)
- `tools/s2-implementation-metadata` "verifies and backfills `implementations[]` using local source checkouts of React Spectrum S2 and Spectrum Web Components gen2. It never adds non-exact aliases automatically" — [README](https://github.com/adobe/spectrum-design-data/tree/main/tools/s2-implementation-metadata)
- `tools/platform-capture` "Captures platform reference renderings so they can be compared with design-data renderer output". Its iOS adapter captures light and dark simulator screenshots of the Spectrum iOS Catalog app, and only `states.json` (a filename index) is committed — [README](https://github.com/adobe/spectrum-design-data/tree/main/tools/platform-capture)
- `tools/component-diff-generator` does "Breaking Change Detection" between component-schema versions — [README](https://github.com/adobe/spectrum-design-data/tree/main/tools/component-diff-generator)
- Shopify Helix checkpoints "must pass tests, match the running app visually, and survive two adversarial code reviewers" — [Back to native](https://shopify.engineering/back-to-native)
- Curtis: spec round trips (specs → Figma → specs) should stay byte-identical, and "cross-platform factories compare generated output against existing code" — [Spec-driven UI component development](https://nathanacurtis.substack.com/p/spec-driven-ui-component-development)
- Lyft: a component is not announced until complete in design, Android and iOS, and parity gaps are prioritized as bugs — [Lyft parity](https://www.designsystems.com/a-system-built-on-parity-how-to-treat-all-of-your-users-equally/)
- Snapshot tooling, all active in Nov 2026: [pointfreeco/swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) (pushed 2026-10-21), [cashapp/paparazzi](https://github.com/cashapp/paparazzi) ("Render your Android screens without a physical device or emulator", pushed 2026-11-13), [takahirom/roborazzi](https://github.com/takahirom/roborazzi) (pushed 2026-11-13). Web snapshots in Jest/Vitest are serialized text trees, not images, so they don't compare directly with mobile image snapshots — [Drizz article](https://www.drizz.dev/post/snapshot-testing-mobile-apps)
- A Fluent UI parity matrix example (columns Web/iOS/Android, cells Yes/Partial, separate token-parity and theming-parity tables) appears in a third-party skill file. This is a weak source and not verified against Microsoft docs — [skillsmp listing](https://skillsmp.com/skills/markus41-claude-m-fluent-ui-design-skills-fluent-cross-platform-skill-md)

### Inferences
- A workable parity harness for westron, sized for one developer plus an agent:
  1. `spec/` JSON validated by JSON Schema plus a few custom rules (constraints reference declared options; states and anatomy are consistent; every declared size has tokens).
  2. An API lint per platform: parse the generated or exported public API (Swift `swift-symbolgraph-extract`, Kotlin's binary-compatibility-validator `.api` dump, CEM for web) and diff it against the spec's options and values.
  3. A spec-driven snapshot matrix: one test generator per platform enumerates variant × size × state × theme from the spec and renders it with swift-snapshot-testing, Paparazzi/Roborazzi or Playwright `toHaveScreenshot`.
  4. A per-platform status matrix (component × platform × {spec, API, snapshots, a11y}) generated from `implementations[]`-style data rather than kept by hand.
- Exact cross-platform pixel equality is not a realistic goal. Spectrum's own non-goal says so ("Pixel parity with every platform implementation"). Compare each platform against the spec's token-resolved expectations (sizes, colors, radii) and review images side by side, rather than diffing pixels across platforms.

### Gaps
- No public tool was found that does automated cross-platform visual diffing (iOS vs Android vs web images of the same component). Spectrum's comparison is iOS against its own renderer, and its images are kept private.
- No public example was found of API-surface linting against a component spec (symbol graph vs. spec). This would need to be built.

## Q6. Component taxonomy and state model: variants, sizes, states, density, slots, a11y, and per-platform behavior (pointer, touch, keyboard, Digital Crown)

### Takeaway
Spectrum's draft spec offers the most rigorous reusable state model:
- States are typed by trigger (`prop` vs `interaction`), and there is a canonical vocabulary with aliases and precedence (hover 50 < keyboard-focus 60 < down 70).
- `disabled` suppresses interaction states, and resolution runs per property, by specificity first and then precedence.
- Accessibility is spec'd abstractly (`role`, `intents`, `keyboardIntents`) and mapped by **adapters** per platform (ARIA, UIAccessibility/SwiftUI, Android AccessibilityNodeInfo, voice).

Platform behavior differences are handled as explicit, documented exceptions: Lyft's sheet follows each platform, Spotify's focus states are platform-dependent, and Lyft standardizes tap targets at 48×48.

### Cited Findings
- State declaration fields: `name` (kebab-case, `^[a-z][a-z0-9-]*$`), `description`, `trigger` (`prop|interaction`), `precedence` and `lifecycle`. Token `state` arrays must reference declared states (SPEC-022), and undocumented custom names warn (SPEC-026) — [state-model.md](https://github.com/adobe/spectrum-design-data/blob/main/packages/design-data-spec/spec/state-model.md)
- Canonical states, with aliases → trigger, precedence ([state-model.md](https://github.com/adobe/spectrum-design-data/blob/main/packages/design-data-spec/spec/state-model.md)):
  - `default` (0)
  - `hover` → interaction, 50
  - `keyboard-focus` (aliases `focus`, `focus-visible`, `key-focus`) → interaction, 60
  - `down` (aliases `active`, `pressed`) → interaction, 70
  - `prop` states: `drag-and-drop`, `invalid`, `valid`, `selected`, `indeterminate`, `read-only`, `disabled`
- Resolution algorithm, run once per property ([state-model.md](https://github.com/adobe/spectrum-design-data/blob/main/packages/design-data-spec/spec/state-model.md)):
  1. Normalize aliases.
  2. "If `disabled` is active, drop every active `interaction` state."
  3. Collect candidate tokens whose state set contains only active states.
  4. Pick the highest specificity (most matched states).
  5. Break ties by interaction precedence.
  6. Break remaining ties by source order, with a warning.
  7. Fall back to default.
  - Worked example: a button that is hover, keyboard-focus and down at once gets its fill from `down`. Ring stroke comes only from `keyboard-focus`.
- Anatomy part fields: `name`, `description`, `required`, `contains` and `lifecycle`. There are state-only parts (e.g. `focus-indicator` with `presentIn: ["keyboard-focus"]`) and an `anatomyReview` status. SPEC-073 flags components without reviewed anatomy — [anatomy-format.md](https://github.com/adobe/spectrum-design-data/blob/main/packages/design-data-spec/spec/anatomy-format.md); [button.json](https://github.com/adobe/spectrum-design-data/blob/main/packages/design-data/components/button.json); [conformance README](https://github.com/adobe/spectrum-design-data/blob/main/packages/design-data-spec/conformance/README.md)
- iOS accessibility adapter mappings ([accessibility-adapters.md](https://github.com/adobe/spectrum-design-data/blob/main/packages/design-data-spec/spec/accessibility-adapters.md)):
  - `role`: `button` → `.button`; `checkbox` → `.button` with toggled state or SwiftUI `Toggle`; `slider` → `.adjustable`; `progressbar` → `.updatesFrequently` plus `accessibilityValue`; `group` → `accessibilityContainerType = .semanticGroup`.
  - `intents`: `choose` → `accessibilityIncrement()/Decrement()` with `.adjustable`; `dismiss` → `accessibilityPerformEscape()`.
  - `keyboardIntents` (external keyboards): `activate` → `UIKeyCommand` for Return and Space; `navigate-items` → arrow-key commands; `dismiss` → Escape.
  - The same document also defines Web/ARIA, Android/AccessibilityNodeInfo and "Voice and multimodal" adapters.
- Spectrum `button.json` documents platform-specific behavior as prose `documentBlocks` rather than structured data. Examples: "Buttons use the default arrow cursor … The only exception occurs on the web; if the button is using the href property it will display the pointer cursor", the 1 s pending-state delay, and RTL mirroring — [button.json](https://github.com/adobe/spectrum-design-data/blob/main/packages/design-data/components/button.json)
- Spectrum allows platform-only components in the foundation (`bottom-navigation-android.json`) and platform-owned replacements via `componentAliases` (`button` → `button-ios`) — [components dir](https://github.com/adobe/spectrum-design-data/tree/main/packages/design-data/components); [ios manifest](https://github.com/adobe/spectrum-design-data/blob/main/platforms/ios/manifest.json)
- Lyft: "For this component, we chose parity with the platform over parity with the design system" (sheet). Tap targets are 48×48 on both platforms even though iOS recommends 44×44 and Android 48×48 — [Lyft parity](https://www.designsystems.com/a-system-built-on-parity-how-to-treat-all-of-your-users-equally/)
- Spotify Encore: focus states are platform-dependent, and teams account for desktop screen area, TV viewing distance and condensed information on Watch — [Spotify Encore](https://designsystems.com/how-spotifys-design-system-goes-beyond-platforms/)
- Apple `controlSize` reaches watchOS from watchOS 9, and `extraLarge` resolves to `large` outside visionOS. Size semantics are therefore platform-clamped by the OS — [Apple ControlSize](https://developer.apple.com/documentation/swiftui/controlsize)
- Curtis: behavior, accessibility and motion are authored supplements, optionally per platform (`card.accessibility.android.md`), because "Designers I work with don't use Figma to express behaviors or accessibility" — [Spec-driven UI component development](https://nathanacurtis.substack.com/p/spec-driven-ui-component-development)

### Inferences
- A suggested westron spec shape, a superset that mostly borrows from Spectrum:
  - `options` (enum, bool, string, with defaults)
  - `constraints` (when/require/severity)
  - `slots` (canonical vocabulary)
  - `anatomy` (parts, `presentIn` states)
  - `states` (trigger and precedence; canonical ids `hover`, `focus` (keyboard), `pressed`, `disabled`, `selected`, `loading`/`pending`, `invalid`)
  - `tokenBindings` (part × state × property)
  - `accessibility` (role, intents, keyboardIntents, minimum target size)
  - `platforms.<ios|macos|watchos|web|gtk|android>` blocks for documented deviations: input modality (pointer hover exists on macOS, web, iPadOS pointer and GTK, but not watchOS or touch-only iOS), Digital Crown mapping for adjustable roles on watchOS, focus ring style, cursor, and `supported: false` for components not offered on a platform (e.g. tooltips on watchOS).
- Model `hover` as an interaction state that some platforms never enter, rather than as a variant. The state model then stays identical, and only the trigger availability differs per platform.
- Density belongs in a theme or environment-level mode (token mode set), not a per-component option. This matches Spectrum's `mode-sets` approach and SwiftUI's environment-based `controlSize`.

### Gaps
- No design system found specifies Digital Crown or watchOS behavior in machine-readable form. Spectrum's adapters cover web, iOS, Android and voice, with nothing on watchOS, macOS-specific or GTK/AT-SPI.
- No source covered density as a formal spec axis across platforms. The density recommendation is inference only.
