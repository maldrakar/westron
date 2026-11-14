# Native UI technology choices and platform UX conventions for the westron design system (Apple, Web, Linux, Android), as of November 2026

Research date: 2026-11-14. Scope: one SwiftUI package (iOS/iPadOS/macOS/watchOS), a web library, a Linux desktop library, and later Android, all native per platform over a shared non-UI core. Where a finding comes from training knowledge rather than a page fetched in this session, it is marked "(not re-verified this session)".

---

## 1. Apple: SwiftUI in 2026 (OS 26/27), Liquid Glass, one Swift package for iOS/iPadOS/macOS/watchOS, idiomatic design-system construction, HIG, accessibility, testing

### Takeaway
SwiftUI is the clear toolkit. The 2027 OS releases (iOS/iPadOS/macOS/watchOS 27, announced at WWDC26 in June 2026) are incremental for SwiftUI: toolbar control, reordering, swipe actions, a new Document API, a `@State` macro, and `ContentBuilder`. The bigger constraint for a custom design system is Liquid Glass (introduced 2025). Building against the iOS 27 SDK removes the opt-out. Apple's HIG explicitly tells branded apps to keep brand color mostly in the content layer, keep the system-owned glass navigation/control layer, and express brand through familiar components. So westron on Apple should be a set of styles/tokens layered onto system components, not a replacement control set.

### Cited Findings

**State of SwiftUI at WWDC26 (2027 releases)**
- Apple's WWDC26 SwiftUI guide lists these new APIs:
  - Toolbars: a `visibilityPriority` modifier, `toolbarOverflowMenu`, the `topBarPinnedTrailing` placement, and `toolbarMinimizeBehavior` (collapses the navigation bar on scroll).
  - Documents: a Document API with `WritableDocument`/`ReadableDocument`, `DocumentCreationSource`, and `NewDocumentButton` (incremental async writes with Foundation Subprogress).
  - Reorderable containers that work beyond `List`. Reordering comes to watchOS for the first time.
  - A `swipeActionsContainer` modifier for any `ScrollView`.
  - Item-binding presentation for `confirmationDialog`/`alert`.
  - `AsyncImage` HTTP caching and an `asyncImageURLSession` modifier.
  - `State` is now a macro: classes in `@State` initialize lazily, once per view lifetime.
  - `ViewBuilder` is exposed as `ContentBuilder`, which Apple says significantly improves build times.
  - [Apple WWDC26 SwiftUI guide](https://developer.apple.com/wwdc26/guides/swiftui/)
- From the "What's new in SwiftUI" (WWDC26 session 269) transcript:
  - Apps get the refreshed Liquid Glass look on 2027 releases without code changes, and it responds to a new Liquid Glass slider that adjusts its tint.
  - Custom Liquid Glass elements can be marked "interactive" on iOS and macOS.
  - The custom account button dims with the tab labels via the `appearsActive` environment value.
  - Mac and iPad windows dim icons and text when inactive.
  - iPhone apps become resizable on iOS 27. Apps should "use size classes instead of idiom" and handle orientation changes.
  - Xcode 27 Live Previews have resize handles.
  - A new `prominent` tab role; `labelStyle(.titleAndIcon)` shows menu item icons in iPad/Mac menu bars.
  - The `@State` macro behavior is back-deployed to iOS 17/macOS 14. Setting a default `@State` value *and* assigning in `init` is now a use-before-initialization error.
  - `ContentBuilder` "works with any minimum deployment target."
  - [WWDC26 session 269 transcript (nonstrict.eu index)](https://nonstrict.eu/wwdcindex/wwdc2026/269/); [Apple session page](https://developer.apple.com/videos/play/wwdc2026/269)
- AI-agent relevance: Xcode 27 ships agent skills for its coding assistant ("SwiftUI Specialist Skill", "What's New In SwiftUI Skill"). `xcrun agent skills export` exports them as markdown files. — [WWDC26 session 269 transcript](https://nonstrict.eu/wwdcindex/wwdc2026/269/); [Apple: Extending and customizing agents](https://developer.apple.com/documentation/Xcode/extending-and-customizing-agents)
- Xcode 27 and iOS 27 were betas at WWDC, and names could change before release. A community write-up flagged the `@State` source-breaking edge case. — [dev.to WWDC26 SwiftUI breakdown](https://dev.to/arshtechpro/wwdc26-whats-new-in-swiftui-a-developers-breakdown-1333) (secondary source)

**Liquid Glass: rules a custom design system must respect**
- HIG Materials says:
  - Liquid Glass "forms a distinct functional layer for controls and navigation elements — like tab bars and sidebars — that floats above the content layer."
  - "**Don't use Liquid Glass in the content layer**", with an exception for transient interactive controls (sliders, toggles) that take on glass while activated.
  - "**Use Liquid Glass effects sparingly** … Standard components from system frameworks pick up the appearance and behavior of this material automatically … Limit these effects to the most important functional elements."
  - Two variants: `regular` (most system components; use for text-heavy components such as alerts, sidebars and popovers) and `clear` (only over visually rich media backgrounds). If the underlying content is bright, "consider adding a dark dimming layer of 35% opacity."
  - Variant appearance changes with the user's preferred Liquid Glass look and with accessibility settings that reduce transparency or increase contrast.
  - Standard materials (ultraThin/thin/regular/thick) remain for the content layer.
  - watchOS: "Avoid removing or replacing material backgrounds for modal sheets when they're provided by default."
  - Change log: guidance added June 9, 2025 and updated September 9, 2025.
  - [Apple HIG: Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- SwiftUI custom-glass API, from Apple's "Applying Liquid Glass to custom views" documentation:
  - `glassEffect(_:in:)`, which defaults to `Glass.regular` in a capsule. Apply it "after other modifiers that affect the appearance of the view."
  - `.regular.tint(_:)`, which Apple describes as "suggest prominence."
  - `Glass.interactive(_:)`, which gives custom components the same reactions that `PrimitiveButtonStyle.glass` gives buttons.
  - `GlassEffectContainer(spacing:)`, for performance and for shapes that blend and morph.
  - `glassEffectUnion(id:namespace:)`.
  - `glassEffectID(_:in:)`, with `GlassEffectTransition.matchedGeometry` / `.materialize`.
  - Button styles `.glass` (`GlassButtonStyle`) and `GlassProminentButtonStyle`.
  - Apple's warning: "Creating too many Liquid Glass effect containers and applying too many effects … can degrade performance."
  - [Apple docs JSON: Applying Liquid Glass to custom views](https://developer.apple.com/tutorials/data/documentation/swiftui/applying-liquid-glass-to-custom-views.json) (the fetched content did not state per-OS availability; Liquid Glass shipped with the OS 26 generation)
- Opting out of Liquid Glass is ending:
  - Apple DTS (Developer Forums, June 2026): "The system ignores this key [`UIDesignRequiresCompatibility`] only when the application is linked against the iOS 27 SDK or later." An app linked against the iOS 26 SDK keeps the opt-out even on iOS 27.
  - Apple "has not officially announced the iOS 27 SDK requirement date yet."
  - Xcode documentation quoted in the same thread: the key is ignored when building for iOS/iPadOS/Mac Catalyst/macOS/tvOS 27 or later.
  - TN3187: the UIScene lifecycle becomes required in the next major release when building with the latest SDK.
  - [Apple Developer Forums thread 832543](https://developer.apple.com/forums/thread/832543)
  - Blogs claiming an "April 2027 deadline" are projections, not Apple statements. — [Baytech: deadline misunderstood](https://www.baytechconsulting.com/blog/liquid-glass-app-store-deadline-misunderstood)

**HIG Branding (refined September 9, 2026; it is the most direct "branded but native" guidance)**
- "**Apply your app's accent color judiciously.** … Minimize its use on controls and instead use it intentionally for primary actions or status indicators … To express your brand through color, consider moving it into the content layer, where it scrolls beneath Liquid Glass controls and gets picked up dynamically."
- "**Consider using a custom font.** … be sure that it's legible at all sizes and supports accessibility features like bold text and Dynamic Type. It can work well to use a custom font for headlines and subheadings while using system fonts for body copy and captions."
- "**Express your brand with familiar components.** … If you need to customize a component's appearance … ensure that details like sizing, placement, and behavior continue to preserve a familiar experience."
- "**Help people feel comfortable by using standard patterns consistently.** … Place UI in expected locations, use standard symbols … rely on established conventions for navigation and modality."
- The page also advises against putting the logo throughout the app and against using the launch screen as a branding opportunity.
- [Apple HIG: Branding](https://developer.apple.com/design/human-interface-guidelines/branding) (WWDC26 video 251 is linked from it)

**watchOS constraints**
- HIG "Designing for watchOS":
  - "quick, glanceable, single-screen interactions."
  - "Minimize the depth of hierarchy … use the Digital Crown to provide vertical navigation."
  - Complications and notifications are often used more than the app itself.
  - Use background color for supporting information and materials for hierarchy.
  - Interactions often last "less than a minute."
  - [Apple HIG: Designing for watchOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-watchos)

**SF Symbols / Apple design tools (WWDC26)**
- SF Symbols 8 shipped as a beta at WWDC26 with "over 7,000 symbols," including new symbols for the 27 releases.
- Symbols come in 9 weights and 3 scales and can be exported to vector tools to build custom symbols that keep design characteristics and accessibility features.
- Icon Composer 2 shipped alongside it for Liquid Glass app icons.
- [Apple WWDC26 Design guide](https://developer.apple.com/wwdc26/guides/design/); [iPhoneSoft (FR)](https://iphonesoft.fr/2026/06/15/apple-sf-symbols-8-icon-composer-2-developpeurs)
- If symbols are referenced by name, verify each exists on every targeted OS version. — [lavx news (secondary)](https://news.lavx.hu/article/icon-composer-2-and-sf-symbols-8-beta-what-apple-s-updated-design-tools-mean-for-developers)

**Snapshot testing and reference libraries**
- pointfreeco/swift-snapshot-testing:
  - Releases in the 1.19.x line during 2026 (1.19.2 on 2026-03-30 per one aggregator; Swift Package Index references 1.19.4, July 2026).
  - Its README documents Swift Testing integration, labeled "Beta."
  - SwiftUI `.onAppear` fires during snapshot rendering, and modals are not captured.
  - [Point-Free: Swift Testing support](https://pointfree.co/blog/posts/146-swift-testing-support-for-snapshottesting); [README](https://cdn.jsdelivr.net/gh/pointfreeco/swift-snapshot-testing@main/README.md); [Classmethod walkthrough](https://dev.classmethod.jp/en/articles/swift-snapshot-testing/)
- Open-source SwiftUI design systems worth studying:
  - Kiwi.com Orbit SwiftUI — [GitHub](https://github.com/kiwicom/orbit-swiftui)
  - Orange OUDS iOS (MIT) and its showcase app — [OUDS toolbox](https://github-proxy.voidd.workers.dev/Orange-OpenSource/ouds-ios-design-system-toolbox)
  - DesignFoundation: token-based, 25 components, MIT, iOS 18+/macOS 15+/visionOS 2; "relatively new." — [Swift Forums](https://forums.swift.org/t/designfoundation-a-token-based-swiftui-design-system-for-swift-6/87930)
  - SwiftThemeKit — [Swift Package Registry](https://swiftpackageregistry.com/Charlyk/swift-theme-kit)
  - None of these was found to list watchOS support. Orbit and OUDS are the most established.

**Standard SwiftUI design-system building blocks (not re-verified this session; stable APIs documented at these URLs)**
- Component styling protocols: [ButtonStyle](https://developer.apple.com/documentation/swiftui/buttonstyle), [PrimitiveButtonStyle](https://developer.apple.com/documentation/swiftui/primitivebuttonstyle), [ToggleStyle](https://developer.apple.com/documentation/swiftui/togglestyle), [LabelStyle](https://developer.apple.com/documentation/swiftui/labelstyle), [LabeledContentStyle](https://developer.apple.com/documentation/swiftui/labeledcontentstyle), [GroupBoxStyle](https://developer.apple.com/documentation/swiftui/groupboxstyle), [ProgressViewStyle](https://developer.apple.com/documentation/swiftui/progressviewstyle).
- Tokens through the environment: [EnvironmentValues](https://developer.apple.com/documentation/swiftui/environmentvalues) (the `@Entry` macro since Xcode 16), plus custom [ShapeStyle](https://developer.apple.com/documentation/swiftui/shapestyle) values.
- Size and layout adaptation: [controlSize](https://developer.apple.com/documentation/swiftui/view/controlsize(_:)), [Layout](https://developer.apple.com/documentation/swiftui/layout), [ScaledMetric](https://developer.apple.com/documentation/swiftui/scaledmetric) and `Font.custom(_:size:relativeTo:)` for Dynamic Type.
- Accessibility environment values: `accessibilityReduceMotion`, `colorSchemeContrast`, `accessibilityReduceTransparency`.
- Documentation: [DocC](https://developer.apple.com/documentation/docc).

### Inferences
- The westron Apple package should be a single SwiftPM package declaring `.iOS`, `.macOS` and `.watchOS` platforms. Put tokens (color, spacing, radius, type ramp) in `EnvironmentValues`/`ShapeStyle` extensions and expose components mostly as *styles applied to system controls*, for example `.buttonStyle(.westronPrimary)` and `LabeledContentStyle`, rather than bespoke `WestronButton` views. That way system behaviors (focus, keyboard, VoiceOver traits, Liquid Glass adaptation, `controlSize`, macOS hover/pointer) remain intact.
- Navigation, toolbars, tab bars, sidebars, sheets, menus and pickers should stay system components. Liquid Glass is now non-optional for apps built with the iOS 27 SDK, and the HIG puts brand color in the content layer, so restyling the chrome fights the platform.
- Size classes, not `UIDevice` idiom, should drive adaptive layout, because iPhone apps are resizable from iOS 27.
- watchOS gets a deliberately reduced subset: tokens, typography and a few row/button styles. No glass on content, and keep system modal materials.
- Pin the minimum deployment target to the 26 generation (or 17+ with `#available` fallbacks). The `@State` macro and `ContentBuilder` are back-deployed, which reduces the cost of a lower floor.
- The Xcode 27 agent skills and `xcrun agent skills export` can be fed directly to the team's AI coding agent as house rules.

### Gaps
- The exact per-OS availability matrix for the `glassEffect`/`Glass.clear` APIs on watchOS 26/27 was not confirmed from Apple's fetched pages.
- No first-party Apple guidance was found specifically on "custom design systems coexisting with Liquid Glass" beyond the HIG Materials, Color and Branding pages.
- Whether Apple added an Xcode 27 native snapshot or preview-test feature (an analogue to Android's `@PreviewTest`) was not found.
- watchOS 26/27-specific HIG changes for Liquid Glass (the watchOS HIG page's change log stops at 2023) were not found.
- I did not find any well-regarded open-source SwiftUI design system with documented watchOS support.

---

## 2. Web: what "native web" means for a design system in 2026; Web Components versus framework-specific versus headless; modern CSS; distribution, docs, accessibility, testing

### Takeaway
The platform has absorbed much of what design-system libraries used to hand-roll:
- `@scope` (Baseline December 2025)
- anchor positioning (Baseline January 2026)
- popover/`<dialog>` with `closedby`
- container style queries and `contrast-color()` (Interop 2026 focus areas)
- customizable `<select>` (Chromium plus Safari 27; Firefox still flagged)

For a one-developer team that wants framework independence, the most defensible shape is a token-driven CSS layer (custom properties plus cascade layers) and framework-agnostic Web Components built with Lit (now an OpenJS Foundation project). Add thin React wrappers only where needed. Headless React libraries (Base UI 1.x, React Aria) are the better choice only if the products are React-only.

### Cited Findings

**Interop 2026 (published February 12, 2026)**
- Focus areas: anchor positioning; container style queries; dialogs and popovers (including `<dialog closedby>`, the `:open` pseudo-class, and `popover="hint"` for tooltips); scroll-driven animations; view transitions (same- and cross-document); `attr()`; `contrast-color()`; custom highlights; fetch uploads and ranges; IndexedDB; JSPI for Wasm; media pseudo-classes; Navigation API; **scoped custom element registries**; scroll snap; `shape()`; web compat; WebRTC; WebTransport; `zoom`.
- Investigation areas: accessibility testing, JPEG XL, mobile testing, WebVTT.
- The anchor positioning focus area continues from Interop 2025, with only the 2025 tests.
- [web.dev: Interop 2026](https://web.dev/blog/interop-2026)

**Baseline status of the key CSS features**
- `@scope`: Baseline Newly available on 2025-12-09 when Firefox 146 shipped it. Expected Widely available around 2028-06. — [web-features explorer: scope](https://web-platform-dx.github.io/web-features-explorer/features/scope); [web.dev: New to the web platform in December 2025](https://web.dev/blog/web-platform-12-2025); [Frontend Masters: How to @scope CSS now that it's Baseline](https://frontendmasters.com/blog/how-to-scope-css-now-that-its-baseline/)
- CSS anchor positioning (`position-area`, etc.): Baseline Newly available since January 2026, when Firefox 147 shipped it (January 13, 2026). Caveats:
  - A Mozilla thread suggested parts of the spec, for example the `position-try-fallbacks` details, may lag.
  - Adobe's compatibility page still rates it "Limited."
  - A conference write-up reports demos breaking between Chrome releases.
  - [MDN: position-area](https://developer.mozilla.org/en-US/docs/Web/CSS/position-area); [Mozilla intent to ship](https://groups.google.com/a/mozilla.org/g/dev-platform/c/B71NFNrZ8Lo); [Adobe shadow-dom-css: anchor positioning](https://shadow-dom-css.adobe.com/features/anchor-positioning); [Conffab talk](https://conffab.com/presentation/customisable-and-the-friends-we-made-along-the-way/)
- `anchor-scope`: Baseline since January 2026 per MDN. — [MDN: anchor-scope](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/properties/anchor-scope)
- Customizable `<select>` (`appearance: base-select`, `<selectedcontent>`, `::picker(select)`):
  - Chromium: Chrome's blog (March 24, 2025) announced it, and the I/O 2025 recap says it arrived in Chrome 134. Other sources say Chrome 135. These conflict; verify on MDN.
  - Safari: 27.0 per multiple 2026 posts, though one September 2026 article still said Technology Preview only.
  - Firefox: behind a flag, reportedly since Firefox 149.
  - Recommended practice is progressive enhancement with `@supports (appearance: base-select)`. Unsupported browsers render a normal select and ignore the extra markup.
  - [Chrome blog: customizable select](https://developer.chrome.com/blog/a-customizable-select); [Chrome I/O 2025 web UI recap](https://developer.chrome.com/blog/new-in-web-ui-io-2025-recap); [codercops: base-select 2026](https://blog.codercops.com/blog/css-customizable-select-appearance-base-select-2026); [Blake Crosley: customizable select in Safari 27](https://blakecrosley.com/ja/blog/customizable-select-safari-27); [Jake Archibald: Goldilocks select height (2026)](https://jakearchibald.com/2026/goldilocks-select-height/)
- Long-Baseline features a design system can rely on (not re-verified this session): [cascade layers @layer](https://developer.mozilla.org/en-US/docs/Web/CSS/@layer), [size container queries](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_containment/Container_queries), [`light-dark()`](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/light-dark), [`oklch()`](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/oklch), [`color-mix()`](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/color-mix), [`@property`](https://developer.mozilla.org/en-US/docs/Web/CSS/@property), [Popover API](https://developer.mozilla.org/en-US/docs/Web/API/Popover_API), [`<dialog>`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dialog), [declarative shadow DOM](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/template#shadowrootmode).

**Web Components ecosystem**
- Lit moved from Google to the OpenJS Foundation as an incubating Impact Project (announced October 2025). — [OpenJS: Lit moves to OpenJS Foundation](https://openjsf.org/blog/lit-moves-to-openjs-foundation); [lit.dev blog 2025-10-14](https://lit.dev/blog/2025-10-14-openjs/). No Lit 4 release was confirmed; npm `lit` shows a May 2026 release in the 3.x line. — [releasealert](https://releasealert.dev/npmjs/_/lit/links)
- Shoelace is frozen (last release March 11, 2025; "No new components, no fixes"). Its successor is Web Awesome, described as "the 3.0 release of Shoelace" with breaking changes. — [Font Awesome blog](https://blog.fontawesome.com/how-does-web-awesome-stack-up-against-shoelace/); [OpenReplay: framework-agnostic UI with Web Awesome](https://blog.openreplay.com/framework-agnostic-ui-web-awesome/)
- React 19 reportedly passes all Custom Elements Everywhere tests (properties versus attributes and events fixed). `@lit/react` wrappers still improve developer experience. Form-associated custom elements remain the main pain point. — [buildmvpfast (2026)](https://www.buildmvpfast.com/blog/web-components-declarative-shadow-dom-react-19-2026); [Brad Frost: Web Component continued progress](https://bradfrost.com/blog/post/web-component-continued-progress/) (secondary; verify against custom-elements-everywhere.com)
- AgnosticUI rewrite post-mortem (Rob Levin, March 3, 2026), the most directly applicable small-team case study:
  - Keeping JSX, Vue and Svelte versions in sync was too costly, so the team moved to Lit under the principle "Platform over Framework."
  - Theming uses exposed `--ag-*` custom properties plus `::part()`.
  - `<label for>` cannot cross shadow roots, so each form control keeps label, input and help text inside one shadow root.
  - `formAssociated = true` is only an opt-in. Real support needs `attachInternals()` plus reimplementing required, disabled, validation, reset and value; their input still isn't complete.
  - Raw React 19 still has friction (events via refs, string booleans, camelCase props), which `@lit/react` `createComponent` fixes.
  - Distribution is a CLI that copies component source into consumer projects (`npx agnosticui-cli init/add`), described as "easier for LLMs to work with."
  - [Frontend Masters/master.dev: Post Mortem: Rewriting AgnosticUI with Lit](https://blog.master.dev/post-mortem-rewriting-agnosticui-with-lit-web-components/)
- Scoped custom element registries are an Interop 2026 focus area. This matters for design-system web components because it allows multiple versions or tag-name collisions on one page. — [web.dev: Interop 2026](https://web.dev/blog/interop-2026)

**Headless primitives**
- Base UI (from the creators of Radix, Floating UI and MUI):
  - 1.0.0 released December 11, 2025, with 35 accessible components and a commitment to long-term maintenance.
  - Package renamed from `@base-ui-components/react` to `@base-ui/react`.
  - v1.1.0 shipped January 15, 2026; an npm mirror shows 1.6.0 in 2026.
  - [InfoQ: Base UI v1](https://www.infoq.com/news/2026/02/baseui-v1-accessible); [Base UI release notes v1.0.0 (unpkg)](https://app.unpkg.com/@base-ui/react@1.6.0/files/docs/react/overview/releases/v1-0-0.md); [About Base UI](https://base-ui.com/react/overview/about)
- Radix UI faced uncertainty after its acquisition, and some commentators position Base UI as its successor (a marketing framing). — [InfoQ](https://www.infoq.com/news/2026/02/baseui-v1-accessible)
- Ark UI is built on Zag.js state machines that are "modelled in a framework agnostic way," with packages for React, Solid, Vue and Svelte (Svelte support status varies by doc page). — [Zag.js](https://www.zagjs.com); [Ark UI docs](https://ark-ui.com/docs/vue/overview/introduction)

### Inferences
- For "framework independence with one developer," the lowest-maintenance architecture is:
  - (a) A token package that emits CSS custom properties (OKLCH colors, `light-dark()`), organized with `@layer` so consumer overrides are predictable.
  - (b) Lit-based custom elements for interactive components. Lean on platform primitives (`<dialog>`, `popover`, anchor positioning, `<details>`, customizable `<select>` as progressive enhancement) so less ARIA and focus code is hand-written.
  - (c) Thin `@lit/react` wrappers, generated rather than hand-maintained.
  - This mirrors the AgnosticUI lesson that maintaining N framework ports is the real cost.
- Text inputs and other form controls are the riskiest web-component area, because of form-associated custom elements and label association across shadow roots. Consider light-DOM (non-shadow) implementations or CSS-only styling of native `<input>`/`<select>` for those components.
- If the westron web products will be React-only, Base UI or React Aria plus westron CSS is faster and better-tested than writing custom elements. The trade-off is lock-in to React.
- Cross-cutting with the native principle: on web, "platform-native" means native HTML elements and browser behaviors (focus-visible, form validation, `<dialog>` modality, OS-level select pickers on mobile), not imitations of iOS or Android.

### Gaps
- Storybook, Ladle and Histoire 2026 versions and their Web Components support were not researched in this session.
- No 2026 primary source was found comparing visual regression tools (Playwright `toHaveScreenshot`, Chromatic, Lost Pixel).
- React Aria / React Spectrum 2026 release status was not verified.
- WAI-ARIA APG 2026 changes were not checked.
- ARIA cross-root references (the Reference Target proposal) and their 2026 shipping status were not verified, even though they are critical for shadow-DOM accessibility.
- `contrast-color()` and container style-query shipping status per browser was not individually verified (they are only confirmed as Interop 2026 focus areas).

---

## 3. Linux desktop: realistic native options in 2026 (GTK4 + libadwaita, Qt 6/QML + Kirigami, COSMIC/libcosmic, Relm4/gtk-rs, Adwaita for Swift), styling limits, distribution, accessibility

### Takeaway
GTK4 + libadwaita is the most defensible "native Linux" target. It defines the GNOME HIG, ships on the largest desktop share (default in Ubuntu 26.10 and Fedora 45 via GNOME 51), has mature Rust bindings (gtk4-rs 0.11 / libadwaita-rs 0.9 / Relm4 0.11), and now even has a SwiftUI-like Swift layer (Adwaita for Swift). The cost is deliberate: libadwaita lets an app override the accent color and add a small `style.css` using CSS variables and media queries. The GNOME HIG asks apps to keep custom styling minimal, so westron on Linux becomes "Adwaita with westron accent, type and illustration," not a full reskin. Qt/Kirigami is the KDE-native alternative and its theming is in flux (Union engine). COSMIC (libcosmic/iced) is young and its theming engine is slated to change.

### Cited Findings

**GNOME release cadence and versions**
- GNOME 49 (September 2025): libadwaita 1.8 added AdwShortcutsDialog and AdwShortcutLabel, plus full CSS media-query support, so one stylesheet can hold light, dark and high-contrast rules. — [GNOME 49 developers](https://release.gnome.org/49/developers/); [Linuxiac: libadwaita 1.8](https://linuxiac.com/libadwaita-1-8-arrives-alongside-gnome-49/)
- GNOME 50 (March 2026), with GTK 4.22 and libadwaita 1.9:
  - GtkSvg: an in-process SVG renderer with animated SVG support that passes 1,250+ resvg tests. Untrusted SVGs should still go through the sandboxed Glycin library.
  - `AdwSidebar` and `AdwViewSwitcherSidebar` (replacing GtkStackSidebar).
  - Most widgets now honor the system reduced-motion preference automatically.
  - **Deprecation:** autoloaded `style-dark.css`, `style-hc.css` and `style-hc-dark.css` give way to `style.css` with standard media queries.
  - [GNOME 50 developers](https://release.gnome.org/50/developers/)
- AdwSidebar is built on GtkListBox, so it suits sidebars but doesn't scale to thousands of items like GtkListView. Reduced motion is applied mostly by swapping slides and scales for crossfades. — [Libadwaita 1.9 summary (lavx)](https://news.lavx.hu/article/libadwaita-1-9-sidebar-widgets-and-mobile-first-design-take-center-stage) (secondary, citing Alice Mikhaylenko's Planet GNOME post)
- GNOME 51 "A Coruña" (released September 16, 2026; default in Ubuntu 26.10 and Fedora 45):
  - GTK 4.24 released September 12, 2026, with fractional-scaling pixel snapping and Wayland background blur. Session save/restore moved to 4.26.
  - GNOME 52 is expected in March 2027.
  - [Phoronix: GTK 4.24 released](https://www.phoronix.com/news/GTK-4.24-Released); [OMG! Ubuntu: GNOME 51 released](https://www.omgubuntu.co.uk/2026/09/gnome-51-released); [UbuntuHandbook](https://ubuntuhandbook.org/index.php/2026/09/gnome-51-released-to-be-default-in-ubuntu-26-10-fedora-45/)
- GNOME 51 developer notes, covering the GTK 4.23 development cycle and libadwaita 1.10:
  - GTK: `GtkSvgWidget`; all SVG icons now render through GtkSvg; `GtkSpinner`, `GtkStack` and `GtkRevealer` respect reduced motion; Wayland text-input 3.2; `xdg-session-management-v1`; a new `font-width` CSS property; `GtkEnumList`. GTK can target Android SDK 36.
  - libadwaita 1.10: new `AdwCssClassBinding`; sidebar `:prefix`/`:suffix`; `AdwStyleManager` Android settings backend; libadwaita "can be built on Android"; `AdwEnumListModel` deprecated.
  - [GNOME 51 developers](https://release.gnome.org/51/developers/)

**How far libadwaita can be restyled**
- Color schemes are controlled by `AdwStyleManager:color-scheme` (`PREFER_LIGHT`, `PREFER_DARK`, `FORCE_LIGHT`, `FORCE_DARK`).
- Apps follow the *system* accent by default. They can override it by setting `--accent-bg-color` on `:root` or on a widget; per-widget overrides must also set `--accent-color`. "When accent color is overridden, AdwStyleManager API will still return the system color."
- `AdwApplication` autoloads `style.css` from the app's resource base path.
- High contrast is supported automatically and "applications cannot disable it."
- "When possible, use CSS variables instead of hardcoded colors." The `.dimmed` class replaces manual opacity changes.
- [libadwaita: Styles & Appearance](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/1-latest/styles-and-appearance.html)
- Since libadwaita 1.6, CSS variables replace the old named colors (`@accent_color` becomes `var(--accent-color)`). Accent variables are `--accent-bg-color`, `--accent-fg-color` and `--accent-color`, and can be redeclared on `:root`. — [libadwaita CSS variables doc (Debian 1.8.2 copy)](https://sources.debian.org/src/libadwaita-1/1.8.2-1/doc/css-variables.md); [Alice Mikhaylenko: Libadwaita 1.6](https://blogs.gnome.org/alicem/2024/09/)
- GNOME HIG on UI styling: "As a general rule, it is better to keep the amount of this custom styling to a minimum." It recommends using "existing style classes and color variables as much as possible," which "automatically adjust for the light, dark and high-contrast styles," and warns: "Be careful not to use classes and variables outside of their intended uses." — [GNOME HIG: UI styling](https://developer.gnome.org/hig/guidelines/ui-styling.html)
- GNOME 48 replaced Cantarell with Adwaita Sans (an Inter derivative) and Source Code Pro with Adwaita Mono (Iosevka-based). — [OMG! Ubuntu: new Adwaita fonts](https://www.omgubuntu.co.uk/2025/02/gnome-introduces-new-ui-monospace-adwaita-fonts); [GNOME blog: Introducing Adwaita Fonts](https://blogs.gnome.org/monster/?term_id=2)

**Language bindings**
- Rust:
  - The `libadwaita` crate 0.9.x pairs with `gtk4` ^0.11 and `glib` ^0.22 (0.9.0 on 2026-01-04, 0.9.2 on 2026-07-07). — [docs.rs: libadwaita 0.9.2](https://docs.rs/crate/libadwaita/0.9.2)
  - `relm4` 0.11.0 has features `gnome_49`, `gnome_50` and `libadwaita`; relm4-components 0.11.0 shipped 2026-04-08 after 0.10.1 on 2025-12-29. docs.rs failed to build relm4 0.11.0 docs at the time. — [docs.rs: relm4](https://docs.rs/crate/relm4/latest); [lib.rs: relm4-components](https://lib.rs/crates/relm4-components)
- Swift:
  - Adwaita for Swift (David Häner, "david-swift") is "a framework for creating user interfaces for GNOME with an API similar to SwiftUI." It is active (commits in July 2026), has moved to git.aparoksha.dev with a Codeberg mirror, and was featured on swift.org.
  - The older imperative "Libadwaita" Swift binding is unmaintained.
  - [Codeberg: adwaita-swift](https://codeberg.org/aparoksha/adwaita-swift); [swift.org: Writing GNOME Apps with Swift](https://swift.org/blog/adwaita-swift/); [GNOME Circle proposal](https://gitlab.gnome.org/Teams/Circle/-/issues/222)

**Qt 6 / KDE**
- Qt 6.10 added a `SearchField` control and better FluentWinUI3 contrast-theme support. — [Qt 6.10 released](https://www.qt.io/blog/qt-6.10-released)
- Qt 6.11:
  - New controls and APIs: `DoubleSpinBox`, default-button APIs on `DialogButtonBox`, per-corner `RectangularShadow` radii.
  - Accessibility: a new Switch role and slider Orientation attribute.
  - **Qt Labs StyleKit**, a Technology Preview: "a declarative styling system for Qt Quick Controls that sits on top of Qt Quick Templates." It offers hierarchical fallbacks, state-based styling, light/dark/custom themes, and is activated by assigning `StyleKit.style` on the root `ApplicationWindow`. The API is not under compatibility promises.
  - [What's New in Qt 6.11](https://doc.qt.io/qt-6/whatsnew611.html); [Qt Labs StyleKit](https://doc.qt.io/qt-6/qtlabsstylekit-index.html)
- KDE:
  - The HIG names Breeze as the default workspace, application and window-decoration theme. — [KDE HIG architecture](https://develop.kde.org/hig/introduction/architecture)
  - Kirigami and QQC2 components "should follow the palette by default," so custom coloring is usually unnecessary. — [Kirigami style colors](https://scriptagc.wasmer.app/https_develop_kde_org/docs/getting-started/kirigami/style-colors)
  - A new **Union** style engine was announced for Plasma 6.7 (May 2026). Plasma 6.8 extends it to QtWidgets apps. — [plasma-devel: Union in Plasma 6.7](https://mail.kde.org/pipermail/plasma-devel/2026-May/123955.html); [Linuxiac: Plasma 6.8 Union](https://linuxiac.com/kde-plasma-6-8-expands-union-theming-to-qtwidgets-apps/)
  - Custom QQC2 styles can break Kirigami apps when the Kirigami platform plugin isn't available for that style. — [KDE Discuss](https://discuss.kde.org/t/styling-kirigami-applications-wtih-custom-qtquickcontrols-style/39063?page=2)

**COSMIC**
- COSMIC Epoch 1 shipped on December 11, 2025 with Pop!_OS 24.04. It is built on iced, and libcosmic is its app/applet toolkit. — [OMG! Ubuntu: Pop!_OS 24.04 stable](https://www.omgubuntu.co.uk/2025/12/pop_os-24-04-lts-stable-release); [GitHub: cosmic-epoch](https://github.com/pop-os/cosmic-epoch)
- Epoch 2 "promises … a new theming engine." Epoch 1.3's frosted glass required app developers to update libcosmic, so theming churn reaches third-party apps. — [linuxcompatible: COSMIC 1.3](https://www.linuxcompatible.org/story/cosmic-13-released-system76s-rust-linux-desktop-gains-frosted-glass-and-gpu-tools/); [System76 blog: Epoch 1 updates](https://blog.system76.com/post/cosmic-epoch-1-updates)

**Accessibility**
- GTK merged an AccessKit backend in 4.18 (opt-in via `-Daccesskit=enabled` plus `GTK_A11Y=accesskit`). GTK still defaults to AT-SPI on Linux, and AccessKit is used on Windows and macOS. Known gaps were out-of-tree `GtkAccessibleText` widgets and tables. — [GTK blog: An accessibility update (May 2025)](https://blog.gtk.org/2025/05/12/an-accessibility-update/)
- At the GTK hackfest before FOSDEM 2026, developers were "somewhat worried about the state of AccessKit" in GTK. — [GTK blog (mclasen)](https://blog.gtk.org/author/mclasen)
- Newton (Wayland-native accessibility on AccessKit) had no confirmed 2026 status. — [GNOME a11y blog: Newton update](https://blogs.gnome.org/a11y/)

### Inferences
- **Recommended Linux stack:** GTK4 + libadwaita in Rust (gtk4-rs + libadwaita-rs, optionally Relm4), shipped as a Flatpak on the GNOME runtime. It aligns with the likely Rust shared core: same language, no FFI layer. The libadwaita and GNOME HIG model already contains the right "brand vs native" boundary.
- What westron *can* express on Linux:
  - accent color through `--accent-bg-color`/`--accent-color`
  - a small `style.css` with westron spacing and radius on custom widgets only
  - illustration, empty states, iconography (symbolic SVGs render via GtkSvg)
  - copy tone
  - possibly a brand display font for headings
- What it should *not* do: replace Adwaita widget looks, disable high contrast (impossible), or invent a navigation model. AdwNavigationView, AdwSidebar and AdwDialog/bottom-sheet adaptivity should be used as-is.
- Adwaita for Swift is attractive because its API resembles the SwiftUI library, but it is a one-maintainer project. Rust bindings are the lower-risk choice.
- Qt/Kirigami should be chosen only if KDE is the primary audience. COSMIC and libcosmic are not yet a stable target for third-party design systems.

### Gaps
- Exact Flatpak GNOME runtime version naming for GNOME 51 (expected `org.gnome.Platform//51`) and the KDE runtime were not verified this session.
- gtk4-rs 0.11.0 stable release date was not confirmed (only 0.11.0-alpha.2 in January 2026 was seen for gsk4-sys).
- Slint (Rust/C++ declarative toolkit) and elementary Granite were not researched this session.
- No documentation was found on how third-party apps adopt the COSMIC theme.
- Newton status in 2026 is unverified.
- No libadwaita document was found that lists exactly which non-accent variables apps are "allowed" to override. Libadwaita does not explicitly forbid it; the HIG only discourages it.

---

## 4. Android: Jetpack Compose + Material 3 / M3 Expressive in 2026, custom design system on foundation versus wrapping Material, Wear OS, accessibility, screenshot testing

### Takeaway
Compose 1.11 (stable April 2026) is current. Material3 stable is 1.4.0, and 1.5.0 reached rc01 on November 4, 2026 with most M3 Expressive components promoted to stable. Google's official guidance offers three paths: extend MaterialTheme, replace subsystems, or go fully custom with `CompositionLocal`. For a small team, the pragmatic choice is to **wrap Material3 components with westron tokens provided via CompositionLocals** and drop to `compose.foundation` only for components whose shape and motion diverge.

For screenshot tests, Google's standalone preview-screenshot plugin is deprecated in favor of AGP test suites (AGP 9.5+). Roborazzi and Paparazzi remain the mature third-party options.

### Cited Findings

**Compose and Material versions**
- The Compose April 2026 release (Compose 1.11.0, BOM `2026.04.01`) added:
  - v2 test dispatcher APIs as the default (v1 deprecated)
  - trackpad input support
  - an experimental **Style API** for declaratively styling components, and an experimental MediaQuery API
  - the `@PreviewWrapper` annotation, for applying a theme to previews
  - deprecation of `Modifier.onFirstVisible()`
  - Compose 1.12 will require compileSdk 37 and AGP 9.
  - [Android Developers Blog: Compose April 2026 updates](https://android-developers.googleblog.com/2026/04/jetpack-compose-april-2026-updates.html)
- Compose Material3 status:
  - Latest stable is 1.4.0. 1.5.0-rc01 shipped November 4, 2026 (beta02 on October 21, alpha29 on September 23).
  - Expressive APIs promoted from experimental to stable during the 1.5 alphas: `expressiveLightColorScheme` and the expressive theme entry point (the release notes spell it "materialExpressTheme"; verify against the API reference), toggle buttons, FAB and FAB Menu, expressive buttons, `SplitButton`, expressive `FloatingToolbar`, `ButtonGroup`, expressive list items, and `TopAppBar` variants.
  - `MaterialShapes` and `LoadingIndicator` were reverted to experimental.
  - Breaking changes and deprecations:
    - Stateless `Slider`/`RangeSlider` deprecated in favor of `SliderState`.
    - `LocalMotionScheme` removed in favor of `MaterialTheme.motionScheme`.
    - `rememberModalBottomSheetState` deprecated in favor of `rememberBottomSheetState`.
    - `TonalToggleButton` renamed `FilledTonalToggleButton`.
  - [AndroidX release notes: compose-material3](https://developer.android.com/jetpack/androidx/releases/compose-material3)
- The December 2025 release included Material3 1.4, with Expressive APIs still developed in alphas at that time. — [Android Developers: What's new in the Jetpack Compose December release](https://developer.android.com/blog/posts/whats-new-in-the-jetpack-compose-december-release?hl=en)

**Official custom design-system guidance**
- "Material is our recommended design system … you are not forced to use it. Material is built entirely on public APIs."
- Three approaches:
  1. Extend `MaterialTheme`, via extension properties or an `ExtendedTheme` that wraps `MaterialTheme` with a `staticCompositionLocalOf` holding an `@Immutable` data class.
  2. Replace one or more of `ColorScheme`, `Typography` and `Shapes`.
  3. Fully custom.
- `MaterialTheme` also provides `TextSelectionColors` and ripple as `LocalIndication`. If Material components are used without `MaterialTheme`, "using Material components as-is will result in unwanted Material color, type, and shape values and indication behavior," so wrap them and set every value explicitly.
- Ripple configuration: `LocalRippleConfiguration`. Starting with material3 1.5.0-beta01, `LocalRippleThemeConfiguration` configures the ripple theme for all Material components (for example, an inset focus ring).
- For new token types such as gradients, Google suggests implementing components from scratch (see `JetsnackButton`).
- [Android Developers: Custom design systems in Compose](https://developer.android.com/develop/ui/compose/designsystems/custom)

**Wear OS**
- Wear Compose Material 3 1.5.0 is stable (August 27, 2025). Don't mix it with `androidx.wear.compose:compose-material` or `androidx.compose.material:material`.
- Wear OS 6's design refresh is based on Material 3 Expressive.
- [AndroidX: wear-compose-m3](https://developer.android.com/jetpack/androidx/releases/wear-compose-m3); [Android Developers Blog: M3 Expressive for Wear OS (Aug 2025)](https://android-developers.googleblog.com/2025/08/introducing-material-3-expressive-for-wear-os.html); [Wear OS 6 features](https://developer.android.com/training/wearables/versions/6/features)

**Screenshot testing**
- Google's tooling:
  - "The standalone `com.android.compose.screenshot` plugin … is no longer maintained. We recommend setting up screenshot tests with AGP test suites using Android Gradle Plugin (AGP) 9.5 or higher."
  - Features: `@PreviewTest` on previews in a `screenshotTest` source set; `updateDebugScreenshotTest`/`validateDebugScreenshotTest` Gradle tasks; HTML diff reports; IDE integration.
  - KMP non-Android targets are unsupported.
  - An `android skills add testing-setup` agent skill and `android studio render-compose-preview` CLI exist (relevant for AI-agent workflows).
  - [Android Developers: Compose Preview Screenshot Testing](https://developer.android.com/studio/preview/compose-screenshot-testing)
- Paparazzi renders on the JVM via LayoutLib with no emulator. Roborazzi uses Robolectric, so it can capture Activities and Fragments; it supports Compose Preview scanning via ComposablePreviewScanner and Compose Multiplatform Desktop previews (reported from 1.70.0), with 1.66.0 dated 2026-07-06. — [Roborazzi (ecosyste.ms)](https://awesome.ecosyste.ms/projects/github.com%2Ftakahirom%2Froborazzi); [xckevin: Paparazzi and Roborazzi](https://xckevin.github.io/en/blog/android-compose-screenshot-testing-paparazzi/); [Android screenshot testing playground](https://github.com/sergio-sastre/Android-screenshot-testing-playground/blob/master/README.md)

**Compose Multiplatform (comparison only)**
- iOS became stable in Compose Multiplatform 1.8.0. 1.10.0 (January 2026) brought unified `@Preview`, Navigation 3 on non-Android targets, and stable Hot Reload. 1.10.1 shipped in February 2026, and 1.11 was in alpha. — [Neowin: CMP 1.8.0 iOS stable](https://www.neowin.net/news/jetbrains-brings-compose-for-ios-to-stable-with-compose-multiplatform-180-release/); [JetBrains: CMP 1.10.0](https://blog.jetbrains.com/kotlin/2026/01/compose-multiplatform-1-10-0/); [What's new in CMP 1.10](https://kotlinlang.org/docs/multiplatform/whats-new-compose-110.html)

### Inferences
- Use approach 1 or 2 ("extend/replace") rather than fully custom. Provide `WestronTheme` = `CompositionLocalProvider(LocalWestronColors, LocalWestronType, LocalWestronShapes, LocalWestronSpacing)` wrapping `MaterialTheme`, with the Material color scheme *derived* from westron tokens so un-wrapped Material components still look on-brand.
- This preserves Material's accessibility semantics, touch-target sizing, predictive-back sheets, text fields and pickers, which are the "stay native" parts on Android.
- Watch the experimental Compose Style API (1.11). It may become the idiomatic Android analogue of SwiftUI's `ButtonStyle` model, but it isn't stable yet.
- Do not adopt Compose Multiplatform for iOS UI, because it conflicts with the native-per-platform constraint. It is only relevant if an Android plus desktop Kotlin UI were ever wanted. The shared core can still be Kotlin Multiplatform or Rust.
- Plan screenshot tests on Roborazzi, or on Google's AGP test-suites flow once on AGP 9.5+. Do not start on the deprecated standalone plugin.

### Gaps
- No exact Material3 1.4.0 release date or highlight list was retrieved (the release page section was beyond the fetched range).
- The exact name of the expressive theme composable (`MaterialExpressiveTheme`?) was not confirmed from the API reference.
- Android 16/17 platform accessibility changes and TalkBack specifics were not researched.
- Paparazzi's 2026 version and status were not verified from a primary source.
- Whether Wear Compose Material3 has a newer stable than 1.5.0 in 2026 was not confirmed.

---

## 5. Cross-cutting: what stays platform-native versus what is brand-consistent; published "branded but native" guidance

### Takeaway
Every platform owner's own guidance draws the line the same way. Brand lives in color (used sparingly on controls), illustration, voice/tone, iconography style, headline type, and content-layer surfaces. Structure and behavior (navigation, modality, menus, pickers, text input, scroll physics, focus, window chrome, system fonts for body text) stay native. Apple's HIG Branding page (September 2026), GNOME's UI-styling guidance, KDE's palette-following guidance, and Android's "extend or wrap Material" guidance all point there.

### Cited Findings
- Apple:
  - Keep brand color off most controls and move it "into the content layer, where it scrolls beneath Liquid Glass controls."
  - Use custom fonts for headlines and system fonts for body and captions.
  - "Express your brand with familiar components" while preserving "sizing, placement, and behavior."
  - "rely on established conventions for navigation and modality."
  - [Apple HIG: Branding](https://developer.apple.com/design/human-interface-guidelines/branding)
- Apple: Liquid Glass is the functional layer for controls and navigation, and standard components adopt it automatically. — [Apple HIG: Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- GNOME: keep custom styling "to a minimum" and use existing style classes and color variables that adapt to light, dark and high contrast. — [GNOME HIG: UI styling](https://developer.gnome.org/hig/guidelines/ui-styling.html)
- libadwaita: the accent color is the sanctioned brand hook, and high contrast can't be disabled. — [libadwaita: Styles & Appearance](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/1-latest/styles-and-appearance.html)
- KDE: Kirigami and QQC2 should follow the system palette by default. — [Kirigami style colors](https://scriptagc.wasmer.app/https_develop_kde_org/docs/getting-started/kirigami/style-colors)
- Android: Material is recommended but optional. Extending or wrapping `MaterialTheme` keeps "reasonable defaults" for Material components. — [Android: Custom design systems in Compose](https://developer.android.com/develop/ui/compose/designsystems/custom)
- Apple WWDC26: use size classes rather than device idiom for adaptivity, and inactive windows dim automatically. Chrome behavior is OS-owned. — [WWDC26 session 269 transcript](https://nonstrict.eu/wwdcindex/wwdc2026/269/)
- Web: tooltips and popovers via `popover="hint"`, `<dialog closedby>` and anchor positioning are now interoperability targets, so the browser owns modality and light-dismiss semantics. — [web.dev: Interop 2026](https://web.dev/blog/interop-2026)

### Inferences
- Proposed split for westron, derived from the sources above:
  - **Native per platform:** navigation pattern (tab bar, sidebar, navigation stack versus GNOME AdwNavigationView/AdwSidebar versus Material nav bar/rail versus web URL routing); sheets, dialogs and alerts; menus and context menus; date, time and select pickers; text fields and keyboard handling; scroll physics and overscroll; haptics; focus rings and keyboard shortcuts (⌘ versus Ctrl); window chrome and title bars; system font for body text and Dynamic Type/font scaling; control sizes and hit targets; platform icons for standard actions (share, close, back).
  - **Brand-consistent everywhere:** color palette expressed as semantic tokens mapped onto each platform's accent and surface slots; corner-radius and shape language *within* custom content components; spacing rhythm and grid; illustration and empty states; brand iconography for domain-specific concepts; voice and tone; component *naming and semantics* across codebases (one shared vocabulary such as "PrimaryAction", "Banner" or "ListRow"); display and headline typeface where licensing allows.
- A single token source (for example, W3C Design Tokens JSON) compiled to a Swift asset catalog plus Swift constants, CSS custom properties, a libadwaita `style.css`, and Kotlin objects is the natural mechanism. This is a common industry pattern; tooling was not researched in this session.

### Gaps
- No independent, published (non-platform-owner) case study of a 2025–2026 "branded but native" multi-platform design system was found in this session (for example, a company engineering blog).
- No research on haptics guidelines per platform or platform keyboard-shortcut conventions was done in this session.
- The W3C Design Tokens Community Group format status and token tooling (Style Dictionary, etc.) were not researched here; they are possibly covered by another researcher.

---

## 6. Iconography and fonts across platforms: SF Symbols limits, cross-platform icon sets, icon pipelines, font licensing and system-font strategy

### Takeaway
SF Symbols and SF Pro are legally Apple-platform-only. SF Symbols are "system-provided images" under the Xcode/SDK license, and the SF font license limits use to Apple-platform UI. westron therefore needs its own (or a permissively licensed) icon set for web, Linux and Android. On Apple it can use SF Symbols for standard actions plus custom symbols exported from SF Symbols templates for brand icons. Permissive sets: Lucide (ISC), Tabler (MIT), Phosphor (MIT, 6 weights), Material Symbols (Apache 2.0). Font strategy: system UI fonts for body text on each platform (SF Pro; Adwaita Sans on GNOME 48+; Roboto/Google Sans on Android), plus an optional brand display face. Google Sans Flex became OFL in November 2025.

### Cited Findings
- SF Symbols are treated as "system-provided images as defined in the Xcode and Apple SDKs license agreements" (Apple Developer Forums). The SF font license limits use to mock-ups for Apple OS software and bars use for non-Apple OS UI. Apple staff say they cannot interpret the license for specific cases. — [Apple Developer Forums: SF Symbol License](https://developer.apple.com/forums/thread/757407); [Apple Fonts page](https://developer.apple.com/kr/fonts); [Forums: SF Symbols & Fonts commercial use](https://developer.apple.com/forums/thread/703014)
- SF Symbols 8 has over 7,000 symbols, 9 weights and 3 scales; symbols can be exported to vector tools to build custom symbols that keep the same design characteristics. — [Apple WWDC26 Design guide](https://developer.apple.com/wwdc26/guides/design/)
- Open icon sets:
  - Lucide is ISC; some icons derive from Feather (MIT), so the notice file should cover both.
  - Tabler Icons and Phosphor are MIT (one outlier source said Apache 2.0 for Phosphor).
  - Lucide and Tabler are outline-first on a 24px grid with a 2px stroke; Phosphor has 6 weights including fill and duotone.
  - Approximate counts: Lucide 1.5–1.9k, Tabler 4.9–6.2k, Phosphor around 9k across weights.
  - [dev.to: icon library licenses](https://dev.to/usapopopooon/what-i-didnt-know-about-icon-library-licenses-and-you-might-not-either-30of); [allsvgicons: Tabler vs Lucide](https://allsvgicons.com/compare/tabler-vs-lucide/); [youngju.dev 2026 icon deep dive](https://www.youngju.dev/blog/culture/2026-05-16-icon-libraries-designers-developers-2026-lucide-heroicons-phosphor-tabler-radix-material-symbols-iconify-deep-dive.en) (secondary sources; confirm the LICENSE files)
- Material Symbols have replaced Material Icons as Google's focus. Fontsource shows Material Symbols under Apache License 2.0. — [Google Fonts FAQ](https://developers.google.com/fonts/faq); [Fontsource: Material Symbols Outlined](https://fontsource.org/fonts/material-symbols-outlined/about)
- Google Sans Flex was released under SIL OFL 1.1 in November 2025. — [9to5Google](https://9to5google.com/2025/11/18/google-sans-flex-font-available/); [Fontsource: Google Sans Flex](https://fontsource.org/fonts/google-sans-flex/about)
- GNOME 48+ default UI font is Adwaita Sans (Inter-based) and the monospace is Adwaita Mono (Iosevka-based). — [OMG! Ubuntu](https://www.omgubuntu.co.uk/2025/02/gnome-introduces-new-ui-monospace-adwaita-fonts)
- GTK 4.22+ renders SVG icons through GtkSvg, including animated SVG, and in GTK 4.23/4.24 all SVG icons go through GtkSvg. Plain SVG is therefore a first-class icon output for Linux. — [GNOME 50 developers](https://release.gnome.org/50/developers/); [GNOME 51 developers](https://release.gnome.org/51/developers/)
- Apple HIG: a custom brand font must support Dynamic Type and Bold Text; use system fonts for body copy and captions. — [Apple HIG: Branding](https://developer.apple.com/design/human-interface-guidelines/branding)

### Inferences
- Icon pipeline: master the westron icons as SVG on one grid, either based on a permissive set (Lucide or Phosphor for weight variety) or custom. Generate:
  - (a) SF Symbol custom-symbol templates, so the icons get weight and scale variants and Dynamic Type alignment on Apple;
  - (b) SVG sprites or inline components for web;
  - (c) symbolic SVGs (`-symbolic` naming, recolorable) for GTK;
  - (d) Android VectorDrawables.
- Use SF Symbols and platform-standard icons for generic actions (share, back, close), so each platform feels native. Use westron icons for domain concepts.
- Fonts: prefer system fonts for body and UI text on all platforms. If a brand display face is wanted for headings, choose one with an OFL or similar license that permits app embedding and web serving on all four platforms. Apple's fonts can't be shipped off-Apple, and Google Sans Flex's OFL now makes it a legal cross-platform option if its look fits the brand.

### Gaps
- No specific, verified open-source tool for automatically generating SF Symbol templates from SVG was confirmed in this session (community tools exist but weren't checked).
- Exact Android VectorDrawable conversion tooling (Android Studio Vector Asset, `vd-tool`) was not researched.
- GNOME icon guidelines (symbolic icon grid size, the Icon Development Kit) were not fetched in this session.
- The SF Symbols license text itself was not retrieved; findings rely on Apple forum statements and the SF font license.
