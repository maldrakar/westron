# Workflows, processes and tooling for an AI-agent-built design system ("westron": one human + Claude Code), as of November 2026

Research date: 2026-11-14. Every dated claim carries its date. Items older than ~12 months (before ~Nov 2025) are marked **[>12 mo]**. Where a fact comes only from third-party or trade-press sources rather than the vendor, it is marked **[secondary]**.

---

## 1. AI-agent-driven design system practices published 2025–2026 (spec-driven development, design-system-as-context, MCP servers, "design systems for agents")

### Takeaway
By late 2026 the consensus is "DS+AI": agents should assemble UI only from the design system's real components and tokens, and what decides quality is *structured, on-demand context*: MCP servers, skills and lint rules generated from one machine-readable source, rather than one big prose file. Atlassian measured that a single DESIGN.md file did worse than an MCP server or a skill. Figma measured that Code Connect coverage was the single biggest factor in agent output quality. Spec-driven workflows (Spec Kit, Kiro, Claude Code's SPEC.md pattern) are mature and fit per-component specs well.

### Cited Findings

**Thought leadership / framing**
- Brad Frost (post dated 16 Dec 2025) calls the approach "DS+AI": "the AI is deliberately constrained to using the high-quality design system materials". He contrasts this with vibe coding and describes Storybook's "brand-new" Storybook MCP as helping teams "generate UI by wielding their sturdy, well-considered design system component libraries" — [Brad Frost, Agentic Design Systems in 2026](https://bradfrost.com/blog/post/agentic-design-systems-in-2026/)
- Frost, Ian Frost and Southleft (TJ Pitre) run an "AI & Design Systems" course at aianddesign.systems. One listing gives a $500 preorder price **[secondary]** — [Southleft course announcement](https://southleft.com/insights/design-systems/introducing-our-new-course-ai-design-systems); [course curriculum](https://courses.bradfrost.com/courses/ai-design-systems-course)
- TJ Pitre, "Context-Based Design Systems, Revisited" (12 May 2026):
  - Context (intent, when a pattern applies, why it exists) is "the unit of value". Weak metadata produces drift, and automation spreads it fast.
  - Favors human-led orchestration ("human sets constraints first, AI executes within them") over propose-and-approve agent autonomy.
  - Designers author first-draft components in code with AI help and open PRs, which a "Context Engineer" reviews, tests and ships. That role owns metadata, constraints and contracts so that every shipped change traces back to a human decision.
  - Recommends "scoped, boring agents", design QA with the same rigor as code QA, and an auditable record of who decided what and what the AI was authorized to do.
  - His team uses Figma Console MCP — [Southleft Substack](https://southleft.substack.com/p/context-based-design-systems-revisited)
- One third-party guide describes per-component machine-readable metadata covering purpose, variants, tokens, relationships and explicit anti-patterns. This is general industry practice, not a Frost-specific standard **[secondary]** — [designproject.io, Agentic design system](https://designproject.io/blog/agentic-design-system/)

**Survey data (zeroheight, 2026)**
- zeroheight "State of AI in Design Systems 2026", n=123 practitioners, mostly in-house leads at mid-to-large tech companies:
  - Adoption: 82% of teams use AI; 74% use Claude; 56% use Figma Make.
  - Where AI works and where it doesn't: documentation is the strongest win (63% most satisfied). Design generation is the weakest area, at −53 net satisfaction.
  - Readiness: only 17% rate their docs "very AI-ready"; 48% already run an MCP server.
  - Bypass: 59% report UI being built outside the design system.
  - Recommended priority: "documentation first, MCP second, quality over adoption" — [zeroheight State of AI in DS 2026](https://zeroheight.com/resources/state-of-ai-in-design-systems/)
- zeroheight's annual Design Systems Report 2026 (published ~17 Mar 2026), per its webinar summaries: 56% of DS teams use AI but only 15% say it lives up to the hype; 61% say they lack people **[secondary]**. A secondary summary says only 38% of design systems achieve wide adoption — [zeroheight report webinars](https://webinars.zeroheight.com/register/zeroheight-design-systems-report-2026-the-findings)

**Design-system-as-context: measured results**
- **Atlassian, "Teaching AI to speak our design language" (2 Jun 2026)**
  - Converted ADS docs into machine-readable TypeScript schema files living alongside the code. The schemas cover components, icons, tokens, lint rules and foundational guidelines, and capture usage, code examples, props, content standards and accessibility requirements.
  - From that one source they generate the ADS MCP server content, the design-system skill, DESIGN.md files, and other formats.
  - MCP with structured content vs. no MCP: up to 52% accuracy improvement on specific queries, 34% faster, 26% fewer tool calls, 16% lower token use, 4.9% more accurate code, 11% fewer errors.
  - Lessons: "Documentation that drifts from the codebase is worse than no documentation at all." Restructuring the content exposed missing accessibility guidance.
  - "Self-healing docs": AI skills update the structured content when components change, then run evals and code-health checks — [Atlassian blog](https://www.atlassian.com/blog/ai-at-work/teaching-ai-to-speak-our-design-language)
- **Atlassian, "DESIGN.md is here" (15 Jun 2026)**: login-screen task, comparing four context strategies:

  | Context | Avg. tokens | Avg. time | Avg. turns |
  |---|---|---|---|
  | No context | 4.20M | 6m19s | 43 |
  | ADS MCP | 3.75M | 5m01s | 35.1 |
  | ADS skill | 4.43M | 5m23s | 36 |
  | DESIGN.md | 7.21M | 6m46s | 45.3 |

  - DESIGN.md used "~92% more tokens" than the baseline and had ~2.7× the run-to-run variance. The file is 80 KB (~19.8k tokens). The MCP server and skills distill ~2.5 MB of guidance that agents fetch on demand.
  - DESIGN.md struggles because it loads everything at once and describes how to *re-implement* components, which leads agents to recreate components instead of importing them.
  - Recommendation: MCP or skills plus lint rules for production work. DESIGN.md fits high-level art direction, quick prototyping and design-tool interop.
  - Atlassian flags the results as "not conclusive" — [Atlassian blog](https://www.atlassian.com/blog/how-we-build/atlassians-design-md-is-here-what-we-learned-testing-portable-design-context-in-practice)
- **Figma, "The benefits of Code Connect in MCP" (5 Aug 2026)**
  - Without Code Connect, `get_design_context` returns a generic React description of the canvas. With it, agents get real component snippets ("exactly which component to import, and which property values to pass in").
  - Results: median task duration −19.6%, median tokens −29.5%, code quality +1 point on a 1–4 Likert scale (judged by an LLM against a rubric).
  - Setup: 27 test cases, two React design systems, models Claude Sonnet 4.5 and Claude Opus 4.7.
  - Code Connect coverage was "the single biggest factor": the well-connected system had ~20% of response content as Code Connect snippets, the larger one only ~6% — [Figma blog](https://figma.com/blog/the-benefits-of-code-connect-in-mcp)

**DESIGN.md / AGENTS.md / CLAUDE.md conventions**
- DESIGN.md: Google Labs (Stitch) open-sourced a draft spec on 21 Apr 2026. It is Markdown with YAML front matter holding machine-readable tokens (colors, typography, spacing, components, rules). A validator runs as `npx @google/design.md lint DESIGN.md` **[secondary]**. Critics note drift risk and an informal spec — [pasqualepillitteri.it](https://pasqualepillitteri.it/en/news/1251/google-stitch-design-md-open-source-spec-2026); [Better Stack guide](https://betterstack.com/community/guides/ai/design-md-ai/); [thalion substack critique](https://thalion.substack.com/p/designmd-new-standard-or-temporary)
- Atlassian publishes atlassian.design/DESIGN.md (15 Jun 2026). It adds non-standard properties because the standard doesn't yet support theming — [Atlassian](https://www.atlassian.com/blog/how-we-build/atlassians-design-md-is-here-what-we-learned-testing-portable-design-context-in-practice)
- Claude Code reportedly added an AGENTS.md fallback in v2.1.277 (~18 Sep 2026): if a folder has no CLAUDE.md, Claude reads AGENTS.md. The recommended interoperable pattern is a CLAUDE.md whose first line is `@AGENTS.md`, with Claude-specific notes below it **[secondary]** — [devops.com](https://devops.com/claude-code-adds-agents-md-fallback-cutting-instruction-file-sprawl/); [developersdigest](https://www.developersdigest.tech/blog/claude-code-agents-md-support)

**Spec-driven development**
- **GitHub Spec Kit** (launched Sep 2025 **[>12 mo]**; still very active in Nov 2026, with ~149.8k stars, 2,428 commits and an Oct 16, 2026 video on the repo page):
  - Commands are now exposed as skills: `/speckit-constitution`, `/speckit-specify`, `/speckit-plan`, `/speckit-tasks`, `/speckit-implement`, `/speckit-converge`.
  - Extensions (e.g., `specify extension add bug`, `assess`) can add commands, quality gates and hooks. Presets adapt templates and terminology to organizational standards — [github/spec-kit](https://github.com/github/spec-kit)
  - The constitution records principles, constraints, quality gates and governance — [Microsoft Learn module](https://learn.microsoft.com/en-us/training/modules/spec-driven-development-github-spec-kit-enterprise-developers/3-examine-github-spec-kit); [Microsoft dev blog, Sep 2025](https://developer.microsoft.com/blog/spec-driven-development-spec-kit/) **[>12 mo]**
- **Kiro specs** (docs updated 12 Nov 2026):
  - Each spec has three files: `requirements.md` (or `bugfix.md`), `design.md` and `tasks.md`.
  - When running all tasks, Kiro builds a dependency graph of `tasks.md` and runs independent tasks concurrently in "waves".
  - A "Quick Spec" generates all three files without approval gates — [Kiro docs](https://kiro.dev/docs/specs/)
- **Claude Code's own recommended pattern** (current docs):
  - Ask Claude to "Interview me until you could write the spec, then write it to SPEC.md". Then start a fresh session to build from SPEC.md.
  - Afterwards: "use a subagent to review the … diff against SPEC.md, check every requirement is implemented and the listed edge cases have tests" — [Claude Code best practices](https://code.claude.com/docs/en/best-practices)

**MCP servers exposing design systems (status late 2026)**
- **Storybook MCP** (docs v10.6; AI features "in preview", API may change)
  - Tools:
    - Development: `stories-changed`, `get-storybook-story-instructions`, `stories-preview`, `stories-find-by-component`, `review-create`
    - Docs: `docs-show`, `docs-show-story`, `docs-list`
    - Testing: `test-run`
  - Setup: `npx storybook add @storybook/addon-mcp`, enable `features: { componentsManifest: true }`, then `npx mcp-add --type http --url "http://localhost:6006/mcp" --scope project`. Add instructions to AGENTS.md or CLAUDE.md.
  - Docs tools need the components manifest, which works with React frameworks, Angular-vite and Vue3-vite.
  - With Storybook Test (including a11y checks), the agent runs tests, fixes failures and re-runs them: a "self-healing loop" — [Storybook docs](https://storybook.js.org/docs/ai/mcp/overview)
  - The storybookjs/mcp repo also lists `@storybook/claude-code-plugin` and `@storybook/codex-plugin` packages **[secondary]** — [mcpservers.org listing](https://mcpservers.org/en/servers/github-com-storybookjs-addon-mcp)
- **Primer MCP** (`@primer/mcp`, local stdio, `npx @primer/mcp@latest`). 19 tools:
  - `init`
  - Components: `list_components`, `get_component`, `get_component_examples`, `get_component_usage_guidelines`, `get_component_accessibility_guidelines`
  - Patterns: `list_patterns`, `get_pattern`
  - Tokens: `find_tokens`, `get_token_group_bundle`, `get_design_token_specs`, `get_token_usage_patterns`, `lint_css`
  - Color and type: `get_color_usage`, `get_typography_usage`
  - Icons: `list_icons`, `get_icon`
  - Guidance and review: `primer_coding_guidelines`, `review_alt_text` — [primer.style MCP](https://primer.style/product/getting-started/foundations/mcp)
- **Atlassian** `@atlaskit/ads-mcp` (e.g., an `ads_plan` tool that fetches per-component guidance), paired with an ADS skill and lint rules — [Atlassian](https://www.atlassian.com/blog/how-we-build/atlassians-design-md-is-here-what-we-learned-testing-portable-design-context-in-practice)
- **IBM Carbon**: hosted MCP at mcp.carbondesignsystem.com, plus an llms.txt index of docs and components (overview page last updated 28 Sep 2026 **[secondary]**) — [Carbon MCP overview](https://carbondesignsystem.com/developing/carbon-mcp/overview/)
- AWS Cloudscape publishes llms.txt files — [Cloudscape llms.txt](https://cloudscape.design/gen-ai/ai-tools/llms-txt-files/)
- **shadcn MCP** (CLI 3.0, Aug 2025 **[>12 mo]**)
  - Exposes any shadcn-compatible registry as list/search/view/add tools.
  - Setup: `pnpm dlx shadcn@latest mcp init --client claude`. Registries are configured in `components.json` — [shadcn MCP docs](https://ui.shadcn.com/docs/mcp); [changelog 2025-08](https://ui.shadcn.com/docs/changelog/2025-08-cli-3-mcp)
- **Figma MCP**: remote endpoint `mcp.figma.com/mcp`. The Claude connector page lists Figma as added Jan 2026 **[secondary]**. Write-to-canvas is covered in §3 — [Figma help](https://help.figma.com/hc/en-us/articles/32132100833559); [Claude connector page](https://claude.com/connectors/figma-8ef5e4)

### Inferences
- For westron, the strongest evidence (Atlassian, Figma, zeroheight) points to one architecture:
  - Keep a **structured, machine-readable source of truth** in the repo: token JSON (DTCG) plus per-component spec files with intent, anatomy, props, states, a11y and do/don't.
  - **Generate** agent-facing artifacts from it: a Claude Code skill per domain, optionally a small local MCP server or llms.txt, and a short DESIGN.md for art direction only.
  - **Enforce** with lint rules and tests.
  - Do not rely on one long prose document.
- Spec-driven development maps naturally onto design system work. Treat each component as a "feature spec":
  - requirements: purpose, use cases, a11y
  - design: anatomy, tokens, states, per-platform API
  - tasks: one per platform
  - The "constitution" is the design language plus the engineering principles.
- Spec Kit's full ceremony is likely overkill for one human. Claude Code's native SPEC.md, skills and a subagent reviewer give most of the benefit with less tooling. This is a judgment call, not a sourced finding.
- Storybook MCP is useful for the web library. No equivalent "component manifest MCP" exists for SwiftUI, GTK or Compose (none found), so westron will need its own platform-neutral component registry that agents read directly as files.

### Gaps
- No published primary "design system for agents" posts from Dan Mall, Nathan Curtis, Josh Clark ("Sentient Design"), Vercel, Shopify (Polaris) or Anthropic's engineering blog were retrieved in this pass. Their positions are not represented.
- Google's own DESIGN.md spec page was not fetched; details come from secondary sources.
- The Claude Code AGENTS.md fallback version and date come from third-party sources only.
- Whether Spec Kit's `clarify`/`analyze`/`checklist` commands still exist in the current release could not be confirmed.

---

## 2. Claude Code capabilities relevant to this workflow, and agent visual-verification loops

### Takeaway
Claude Code (Nov 2026) supplies the building blocks for a disciplined design-system loop:
- short CLAUDE.md plus path-scoped `.claude/rules/`
- skills (procedures, loaded on demand)
- subagents (fresh-context reviewers, worktree-isolated per-platform workers)
- hooks (deterministic gates; a `Stop` hook blocks "done" until checks pass)
- plan mode
- worktrees
- MCP
- image input
- Claude Design (an artifact template with design-system import and `/design-sync` / `/design` commands)

Visual verification on Apple platforms needs extra tooling (XcodeBuildMCP, Apple's Xcode MCP RenderPreview, or a custom preview harness), because Claude cannot see Xcode Previews by default.

### Cited Findings

**Instructions, memory and rules**
- Keep CLAUDE.md short; the memory guide recommends under 200 lines.
- Include only what Claude can't infer:
  - exact test, typecheck and lint commands
  - misleading code
  - decisions not in the repo
  - things you've corrected twice
- Personal preferences go in `CLAUDE.local.md`.
- Path-scoped rules go in `.claude/rules/*.md` with a `paths:` filter, so they load only when Claude works in matching files.
- "If something has to happen every time, make it a hook, a deny rule, or a managed setting. CLAUDE.md is for guidelines" — [Claude Code best practices](https://code.claude.com/docs/en/best-practices)

**Skills**
- Each skill is a directory with `SKILL.md` (YAML frontmatter plus instructions) and optional reference files and scripts. Keep SKILL.md under 500 lines.
- The body loads only when invoked; the description is always in context. This is progressive disclosure, so long reference material "costs almost nothing until you need it".
- Locations: `.claude/skills/<name>/` (project, commit it), `~/.claude/skills/` (personal), nested `<subdir>/.claude/skills/`, and plugins.
- Custom slash commands have been merged into skills: `.claude/commands/x.md` and `.claude/skills/x/SKILL.md` both create `/x`.
- Frontmatter:
  - `disable-model-invocation: true` (user-only, for side-effect workflows such as releases)
  - `user-invocable: false` (Claude-only background knowledge)
  - `allowed-tools`
  - `context: fork` plus `agent:` (run in a forked subagent)
  - `paths`, `model`, `effort`, `hooks`
- `` !`cmd` `` injects shell output into the skill before it is sent — [Claude Code skills docs](https://code.claude.com/docs/en/skills)

**Subagents**
- Defined in `.claude/agents/*.md`. Frontmatter fields: `name`, `description`, `tools`, `model`, `isolation: worktree`, `memory` (user/project/local, persisted in `.claude/agent-memory/<name>/`), `skills` (preloaded in full), `mcpServers`, `hooks`, `background`.
- Each subagent starts with a fresh context and does not see the conversation history. Only its final summary returns.
- `isolation: worktree` gives it a temporary git worktree, auto-cleaned if it makes no changes.
- Default cap: 20 concurrent subagents.
- Built-ins: Explore and Plan (read-only) and general-purpose — [Claude Code subagents docs](https://code.claude.com/docs/en/sub-agents)

**Hooks**
- Events include `PreToolUse` (can block), `PostToolUse`, `PostToolBatch`, `Stop`, `SubagentStop`, `SessionStart`, `FileChanged`, `WorktreeCreate`, `PreCompact` and others.
- Hook types: `command`, `http`, `mcp_tool`, `prompt`, `agent` (experimental).
- Exit code 2 blocks:
  - on `PostToolUse`, stderr is fed back to Claude;
  - on `Stop`, it "Prevents [Claude] from stopping".
- Matcher examples: `Edit|Write`. The `if` field narrows a hook, e.g. `"Edit(*.ts)"`.
- Example: a `PostToolUse` lint hook on `Edit|Write` — [Claude Code hooks docs](https://code.claude.com/docs/en/hooks)
- A `Stop` hook running a typecheck keeps Claude working until it passes. After 8 consecutive blocks Claude Code overrides; the cap is configurable via `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`.
- "Keep the enforced set small… If you ever find yourself at forty of them, most are probably preferences" — [Claude Code best practices](https://code.claude.com/docs/en/best-practices)

**Verification guidance**
- "Give Claude something it can run that comes back pass or fail." Valid checks include a test file, a build exit code, a linter, a fixture diff, or "a browser screenshot next to the mockup".
- Ask for *evidence*: "the command it ran and its output, or the screenshot".
- `/verify` has Claude build and run the app and look at the result.
- `/code-review` reviews the diff in a fresh subagent "not swayed by the reasoning that produced the code".
- `/goal <condition>` has a separate model check after each turn whether the condition is met — [Claude Code best practices](https://code.claude.com/docs/en/best-practices)

**Parallelism and planning**
- `claude --worktree <name>` starts an isolated parallel session per git worktree (the repo needs at least one commit).
- Plan mode: `claude --permission-mode plan` or Shift+Tab ("⏸ plan mode on"); no edits until approved.
- Images: paste a screenshot with Ctrl+V, drag and drop, or give a file path.
- Non-interactive `claude -p` runs in CI — [Claude Code common workflows](https://code.claude.com/docs/en/common-workflows)

**Claude Design (Anthropic)**
- History:
  - Launched 17 Apr 2026 as a research preview from Anthropic Labs, powered by Opus 4.7 — [TechCrunch, 17 Apr 2026](https://techcrunch.com/2026/04/17/anthropic-launches-claude-design-a-new-product-for-creating-quick-visuals/)
  - A June 2026 update added design-system import (GitHub repo, design files, uploads). Claude "checks its output against the system's specifications, and corrects it before returning results". It also added an admin role to lock one approved design system and a Claude Code handoff bundle (components, tokens, copy, interaction notes) **[secondary]** — [PureAI, 17 Jun 2026](https://pureai.com/articles/2026/06/17/anthropic-overhauls-claude-design.aspx)
- Current help center (Nov 2026):
  - Claude Design is "one of the artifact templates", usable "in any chat, in Claude Code, and from the Artifacts tab".
  - Plans: Free, Pro, Max, Ultra, Team and Enterprise (Enterprise default-on from 15 Oct 2026). The standalone claude.ai/design "closes on December 14, 2026".
  - Design systems come in from a GitHub repo, design files, uploads, or the local codebase via `/design-sync` in Claude Code.
  - `/design` in Claude Code imports a design into the codebase, exports code as a live prototype, or builds end-to-end.
  - Handoff options: "Send to local coding agent" or "Send to Claude Code Web".
  - Limitations:
    - "doesn't have version history yet"
    - real-time co-editing "still basic"
    - "Design system import is only as good as its source"
  - Usage counts toward the same pool as Claude Code — [Claude Help Center](https://support.claude.com/en/articles/14604416-get-started-with-claude-design)

**Apple-platform visual verification**
- Grindr Engineering (12 Mar 2026; updated 8 Nov 2026): "Claude cannot see Xcode Previews, so it ends up building SwiftUI components completely blind."
  - Fix: a `preview` CLI that reads a view file's imports, generates a minimal app target with XcodeGen, renames the view struct into a template entry point, and launches it in the simulator (`./grind preview /components/MyComponent.swift`).
  - Limitation: views tied to concrete ViewModels; they prefer data passed via `init`.
  - Planned next step: idb or MCP for screenshots and interaction — [Grindr blog](https://www.grindr.com/blog/claude-cant-see-xcode-previews----heres-how-we-fixed-it)
- XcodeBuildMCP (Sentry-maintained, MIT) lets Claude build, launch the simulator, screenshot, read the accessibility tree and tap/swipe/type. Install: `claude mcp add XcodeBuildMCP -- npx -y xcodebuildmcp@latest mcp` **[secondary]** — [mcp.directory guide 2026](https://mcp.directory/blog/xcodebuildmcp-complete-guide-2026)
- Apple's native Xcode MCP server reportedly exposes a `RenderPreview` tool that renders SwiftUI previews and returns a screenshot path. Common pattern: XcodeBuildMCP for the build/sim loop, Xcode MCP for preview screenshots. Claude in Xcode requires Xcode 26 **[secondary]** — [Blake Crosley, Xcode MCP + Claude Code](https://blakecrosley.com/ja/blog/xcode-mcp-claude-code); [Daniel Vaughan, May 2026](https://codex.danielvaughan.com/2026/05/24/codex-cli-swift-swiftui-development-xcode-mcp-servers-agent-skills-workflows/)
- A developer report describes Claude Code with simulator access tapping and screenshotting on its own **[secondary]** — [dev.to](https://dev.to/shimo4228/i-gave-claude-code-a-simulator-and-it-started-tapping-and-taking-screenshots-on-its-own-57bj)

**Web visual verification**
- Storybook MCP `stories-preview` and `test-run` give a render-and-test loop — [Storybook docs](https://storybook.js.org/docs/ai/mcp/overview)
- Claude Code docs point to browser screenshots via its Chrome integration — [Claude Code best practices](https://code.claude.com/docs/en/best-practices)

### Inferences
- Suggested westron Claude Code setup (synthesis, not a published recipe):
  - **CLAUDE.md (<200 lines):** build, test and snapshot commands per platform, plus the "never hand-roll a color or spacing value; use tokens" rule.
  - **`.claude/rules/`:** per-platform rules scoped by path (`platforms/apple/**`, `platforms/web/**`, `platforms/linux/**`).
  - **Skills:**
    - `/new-component`: interview, then write a spec from the template
    - `/implement-platform <component> <platform>`
    - `/visual-check`: render the gallery, screenshot, compare to reference and spec
    - `/release` with `disable-model-invocation: true`
    - a background-knowledge skill holding the design language
  - **Subagents:**
    - `spec-reviewer` (reviews the diff against spec.md)
    - `a11y-auditor`
    - per-platform implementers with `isolation: worktree`, so Apple, web and Linux implementations of one spec run in parallel
  - **Hooks:**
    - `PostToolUse` token-lint and formatter on edits
    - `Stop` hook running the unit and snapshot tests for touched packages
- Claude Design is a plausible exploration and prototyping canvas for a team without a designer. Run `/design-sync` once tokens and core components exist, so explorations use westron's own system.
  - The help center names no SwiftUI or GTK export. Treat its output as visual reference and web prototypes, not as native code.
  - The lack of version history means decisions should be captured back into the repo (spec plus reference screenshots).
- The Grindr pattern ("isolated view host app, launched per component") generalizes into a westron **catalog/gallery app per platform**. The agent renders any component in isolation there, takes a screenshot, and compares.

### Gaps
- Official Apple documentation for the Xcode MCP server's tool list (e.g., `RenderPreview`) was not retrieved; the claims come from secondary sources.
- The exact name and behavior of Claude Code's `/verify` skill, and its Chrome integration details, were not read in full.
- No verified documentation of a Claude Code ↔ Linux desktop (GTK/Qt) screenshot loop was found.

---

## 3. Design source of truth for a team without a dedicated designer: Figma vs code-first vs Penpot vs agent-native canvases

### Takeaway
In 2026 every major canvas tool is agent-addressable:
- Figma: MCP read/write, Code Connect, Specs, guidelines on libraries
- Penpot: official free/open MCP, self-hostable
- Pencil: `.pen` JSON files in the repo, edited via MCP
- Claude Design: design-system import from code

For a developer-led, agent-implemented system, the evidence favors **code-first truth**: DTCG token JSON plus per-component specs in git plus live gallery apps. A canvas then serves as an exploration and review surface, not the canonical source. Figma's value scales with Code Connect coverage, which is extra maintenance for one person.

### Cited Findings

**Figma**
- Figma MCP plus Code Connect: agents get real component imports and props, and coverage is the main quality driver (5 Aug 2026; −19.6% duration, −29.5% tokens) — [Figma blog](https://figma.com/blog/the-benefits-of-code-connect-in-mcp)
- A third-party guide says Code Connect requires an Organization or Enterprise plan (unverified against Figma pricing). It advises connecting the 10–15 most-used components first **[secondary]** — [fast.io guide](https://www.fast.io/resources/mcp-server-for-figma/)
- Agents can write native content (frames, components, variables) back to the Figma canvas — [Figma help, Workflow lab: Code to canvas](https://help.figma.com/hc/en-us/articles/40219873508247-Workflow-lab-Code-to-canvas)
  - Coverage of the March 2026 launch names the write tool `use_figma` and warns that agents can damage production files, so permissions and governance matter **[secondary]** — [muz.li](https://muz.li/blog/figma-just-opened-the-canvas-to-ai-agents-heres-what-it-means-for-designers/)
- Config India (14 Oct 2026):
  - **Figma Specs**, a Markdown editor to "define their design language", usable standalone or on canvas, which serves as a reference for teams and agents
  - teams can attach design libraries, code libraries and guidelines as centralized design-system context for agents
  - code layers moved to open beta
  - MCP support added for 20+ new partner tools — [TechCrunch, 14 Oct 2026](https://techcrunch.com/2026/10/14/figma-announces-new-features-to-define-how-agents-work-on-its-platform/)
- Guidelines on published libraries are in open beta **[secondary]** — [wearetenet summary](https://www.wearetenet.com/updates/figma-specs-code-layers-ai-agents)
- Figma Make is used by 56% of DS teams surveyed. AI "design generation" has the worst satisfaction of any AI use (−53 net) — [zeroheight 2026](https://zeroheight.com/resources/state-of-ai-in-design-systems/)

**Penpot**
- Official MCP server, "free and open". Supports design→design (variants from library components), design→code (semantic HTML/CSS, connecting to Storybook) and code→design. Workflows produce "editable design files, tokens and code"; hosted or self-hosted. Penpot claims its "open, structured design data is easier for LLMs to read" — [Penpot AI workflows](https://penpot.app/ai/ai-workflows)
- Community MCP servers expose tokens. For example, `get_tokens` (Mart1M `penpot-mcp-server`) returns DTCG-formatted tokens plus CSS variables — [glama listing](https://glama.ai/mcp/servers/Mart1M/penpot-mcp-server/tools/get_tokens)
- One blog judges Figma MCP more mature than Penpot's **[secondary, opinion]** — [buildmvpfast](https://www.buildmvpfast.com/blog/penpot-mcp-ai-agent-design-system-open-source-figma-2026)
- Penpot 2.15 release notes exist on the community forum (not read in detail) — [Penpot community](https://community.penpot.app/t/penpot-2-15-master-of-puppets/10529)

**Pencil (pencil.dev; possibly rebranded pen.dev)**
- An agent-driven design canvas inside VS Code or Cursor. Designs are stored as an open `.pen` JSON format in the git repo and edited by agents (primarily Claude Code) via a local MCP server. Recreating components from code requires the `.pen` file and code in the same workspace **[secondary]** — [Better Stack guide](https://betterstack.com/community/guides/ai/pencil-ai/); [classmethod hands-on](https://dev.classmethod.jp/en/articles/claude-code-pencil-mcp-web-design/)
- Listed on the Thoughtworks Technology Radar (ring not verified) — [Thoughtworks Radar](https://www.thoughtworks.com/es-ec/radar/tools/pencil)

**Claude Design**
- Imports design systems from GitHub, the codebase (`/design-sync`) or files. It validates output against the design system and hands off to Claude Code. No version history yet — [Claude Help Center](https://support.claude.com/en/articles/14604416-get-started-with-claude-design)

**Code-first tokens**
- The DTCG Design Tokens spec reached its first stable version, 2025.10, on 28 Oct 2025 **[>12 mo, just]**. It is split into Format and Resolver modules (the Resolver handles themes and modes) — [W3C DTCG announcement](https://www.w3.org/community/design-tokens/2025/10/28/design-tokens-specification-reaches-first-stable-version/); [Format module](https://www.w3.org/community/reports/design-tokens/CG-FINAL-format-20251028/); [Resolver module](https://www.w3.org/community/reports/design-tokens/CG-FINAL-resolver-20251028/)
- Style Dictionary is the common transformer from one token source into CSS, Swift, Kotlin and JSON. Salesforce's token package outputs both Swift and Kotlin from a Style Dictionary build **[secondary]** — [Salesforce design tokens README](https://unpkg.com/@salesforce-ux/design-tokens@4.1.0/README.md); [dev.to tokens for mobile](https://dev.to/beefedai/design-tokens-for-mobile-apps-scalable-theming-3ick)

### Inferences
- Recommended stance for westron (synthesis):
  1. **Canonical:** `tokens/*.tokens.json` (DTCG 2025.10) plus `spec/components/<name>/spec.md` (and machine-readable `api.yaml`) in git.
  2. **Visual truth:** rendered galleries (SwiftUI catalog app, Storybook or plain HTML gallery for web, GTK demo app) plus committed reference screenshots.
  3. **Exploration canvases:** Claude Design or a Claude artifact for quick HTML explorations of direction, optionally Penpot or Pencil when a manipulable canvas helps. These feed decisions back as spec edits, never as the canonical source.
- Figma's benefits (Code Connect, Specs, guidelines) mainly pay off when designers work in Figma. With no designer and a multi-platform target (SwiftUI, GTK), Figma's React-centric `get_design_context` output and Code Connect maintenance cost are hard to justify early.
- Penpot (open source, self-hostable, MCP, tokens) is the strongest "canvas" option if one is wanted without vendor lock-in.
- DESIGN.md is cheap to generate from the token source and useful for Claude Design, Stitch and other tools. Generate it; don't hand-maintain it (Atlassian's approach).

### Gaps
- No primary Figma source confirmed Code Connect plan requirements or Variables/DTCG export behavior in late 2026.
- Penpot's native design-tokens implementation details (DTCG compliance, themes) were not verified from Penpot docs in this pass.
- Sketch's 2026 agent/MCP status was not researched.
- Paper (paper.design) was not researched.
- Pencil's official docs pages returned 404, so details are secondary.

---

## 4. How the human reviews design decisions efficiently

### Takeaway
The efficient pattern for one reviewer:
- small decisions captured as **per-component spec/decision records** in the repo
- **rendered evidence** attached to every PR: gallery screenshots across platforms × themes × sizes, plus snapshot diffs
- a **fresh-context reviewer subagent** checking the diff against the spec before the human looks

The human approves at a few explicit checkpoints: spec approval, visual approval, release. Claude Code's guidance explicitly says to ask for evidence (command output, screenshots) rather than "all tests pass".

### Cited Findings
- "Ask Claude for evidence: the command it ran and its output, or the screenshot… For a session you weren't watching, it's also the only evidence you have" — [Claude Code best practices](https://code.claude.com/docs/en/best-practices)
- Write a SPEC.md via an interview, build in a fresh session, then have a subagent review the diff against SPEC.md ("check every requirement is implemented and the listed edge cases have tests") — [Claude Code best practices](https://code.claude.com/docs/en/best-practices)
- Plan mode gives a review checkpoint before any edits — [Claude Code common workflows](https://code.claude.com/docs/en/common-workflows)
- Coded prototypes "short-circuit the circular, unproductive back-and-forth of design review meetings" — [Brad Frost, Dec 2025](https://bradfrost.com/blog/post/agentic-design-systems-in-2026/)
- Keep an auditable record of what was decided, by whom, and what the AI was authorized to do. Every shipped change should trace to a human decision — [Southleft, May 2026](https://southleft.substack.com/p/context-based-design-systems-revisited)
- Storybook MCP has a `review-create` tool in its development toolset (purpose not detailed in the docs excerpt) — [Storybook docs](https://storybook.js.org/docs/ai/mcp/overview)
- Snapshot tools surface diffs for review:
  - swift-snapshot-testing attaches image diffs as XCTest attachments and can call a custom `diffToolCommand` — [pointfreeco/swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing)
  - Playwright writes platform-suffixed baseline PNGs (e.g., `example-test-1-chromium-darwin.png`) to commit — [Playwright docs](https://playwright.dev/docs/test-snapshots)
- SwiftUI previews can be converted into snapshot tests via third-party Prefire and PreviewSnapshots — [pointfreeco/swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing)
- Google's Compose Preview Screenshot Testing generates tests from `@Preview` functions (drawback: previews in a separate source set) **[secondary]** — [xckevin blog](https://xckevin.github.io/en/blog/android-compose-screenshot-testing-paparazzi/)
- Claude Design supports inline comments on the canvas and direct editing, but has no version history and only basic co-editing — [Claude Help Center](https://support.claude.com/en/articles/14604416-get-started-with-claude-design)
- Design systems should keep a decision log and version history so the language evolves traceably **[secondary, general practice]** — [Design Systems Collective](https://www.designsystemscollective.com/one-design-language-many-platforms-how-brands-can-create-consistent-experiences-everywhere-71dade6eb0a0)

### Inferences
- A practical westron review loop (synthesis):
  1. `/new-component X`: the agent interviews the human and drafts `spec.md` plus a short decision record (options considered and the chosen one). The agent may also produce 2–3 HTML or Claude Design explorations rendered with westron tokens.
     **Checkpoint 1: the human approves the spec.**
  2. Per-platform implementation in worktrees, in parallel. Each adds gallery entries and snapshot tests.
  3. A CI job (or the agent locally) renders a **matrix image**: rows are components and states; columns are platforms × light/dark × default/large text. It is posted to the PR, together with snapshot diffs and the a11y audit output.
  4. The `spec-reviewer` subagent posts a requirement-by-requirement checklist.
     **Checkpoint 2: the human looks at the matrix and diffs** (minutes, not hours).
  5. **Checkpoint 3: release** (a user-only `/release` skill).
- Decision records should live next to the spec (`spec/components/button/decisions/0001-*.md`) or in a global `decisions/` folder for foundations (color, type, shape). The agent then sees the "why" when it later edits code, which matches Pitre's traceability point.
- Per-platform catalog apps (SwiftUI catalog, web gallery/Storybook, GTK demo, later a Compose showcase) are both the human's review surface and the agent's screenshot source. Building them early pays twice.

### Gaps
- No published, end-to-end example was found of a cross-platform side-by-side screenshot matrix generated in CI for a native multi-platform design system. This would be a custom script.
- Chromatic (hosted visual review for Storybook) pricing and features in 2026 were not researched.
- ADR/RFC templates specific to design systems (e.g., published by large DS teams) were not retrieved.

---

## 5. Quality gates an agent can run and CI setup

### Takeaway
Most gates can be deterministic scripts the agent runs and hooks enforce:
- token schema validation (DTCG), plus generated-output diffing
- a "no raw values" lint
- contrast checks on token pairs
- API-parity checks against a machine-readable spec
- per-platform snapshot tests (swift-snapshot-testing, Playwright `toHaveScreenshot`, Roborazzi or Paparazzi)
- accessibility audits: XCUITest `performAccessibilityAudit`, axe through Storybook Test/Playwright

Snapshot baselines must be recorded and compared in the same environment (simulator model and OS for Apple; OS and browser for Playwright), which shapes CI design.

### Cited Findings
- **swift-snapshot-testing** (Point-Free):
  - Platforms: "any platform that supports Swift" (iOS, macOS, tvOS, Linux).
  - Strategies: `.image` (with device configs such as `.image(on: .iPhoneSe(.landscape))`), `.recursiveDescription`, `.dump`, `.json`, `.plist`.
  - Record modes: `record: .all`, `record: .failed`, and `withSnapshotTesting(record:)`. Swift Testing support via `@Suite(.snapshots(record: .failed))`.
  - Compare on the same simulator that recorded the reference.
  - SwiftUI previews via Prefire or PreviewSnapshots — [GitHub README](https://github.com/pointfreeco/swift-snapshot-testing)
- **Playwright**:
  - `await expect(page).toHaveScreenshot()` creates a baseline on first run; refresh with `npx playwright test --update-snapshots`.
  - Names carry browser and platform suffixes because "Screenshots differ between browsers and platforms".
  - "For consistent screenshots, run tests in the same environment where the baseline screenshots were generated."
  - Thresholds: `threshold` (0–1, default 0.2) and `maxDiffPixels` — [Playwright docs](https://playwright.dev/docs/test-snapshots)
- **Android**:
  - Both Roborazzi (Robolectric) and Paparazzi (LayoutLib) run screenshot tests on the JVM without an emulator. Roborazzi supports interactions such as clicks and works with Robolectric; Paparazzi does not.
  - Telefónica chose Roborazzi for its multi-platform design system — [Telefónica engineering](https://hub.telefonica.com/en/engineering/testing-screenshot-roborazzi-systems-design); [xckevin comparison](https://xckevin.github.io/en/blog/android-compose-screenshot-testing-paparazzi/)
- **Apple accessibility audit**:
  - `XCUIApplication.performAccessibilityAudit()` (Xcode 15 / iOS 17, WWDC23 **[>12 mo]**) fails the test automatically on issues.
  - Audit types include contrast, elementDetection, hitRegion, sufficientElementDescription, dynamicType, textClipped and trait. It can be scoped (`[.dynamicType, .contrast]`) or have types excluded (`.all.subtracting(...)`), and takes an issue handler to filter false positives — [WWDC23 notes](https://wwdcnotes.com/documentation/wwdc23-10035-perform-accessibility-audits-for-your-app/); [Create with Swift](https://createwithswift.com/testing-your-apps-accessibility-ui-tests)
  - An Apple Developer Forums thread requests better SwiftUI support in audits — [Apple forums](https://developer.apple.com/forums/thread/851560)
- **Storybook Test via MCP**: `test-run` runs story tests "including accessibility checks if configured". The agent fixes and re-runs in a "self-healing loop" — [Storybook docs](https://storybook.js.org/docs/ai/mcp/overview)
- **Primer's MCP** ships a `lint_css` tool and a `review_alt_text` tool, i.e. the design-system team exposes its gates to agents as tools — [Primer MCP](https://primer.style/product/getting-started/foundations/mcp)
- **Atlassian** pairs its MCP server and skill with lint rules for production work, and runs evals and code-health checks when skills update docs — [Atlassian, 15 Jun 2026](https://www.atlassian.com/blog/how-we-build/atlassians-design-md-is-here-what-we-learned-testing-portable-design-context-in-practice); [Atlassian, 2 Jun 2026](https://www.atlassian.com/blog/ai-at-work/teaching-ai-to-speak-our-design-language)
- **DESIGN.md** has a linter: `npx @google/design.md lint DESIGN.md` **[secondary]** — [Better Stack](https://betterstack.com/community/guides/ai/design-md-ai/)
- **Claude Code enforcement**: `PostToolUse` hooks for lint and format on `Edit|Write`; a `Stop` hook (exit 2) blocks finishing until checks pass; `claude -p` for CI and batch runs — [Claude Code hooks](https://code.claude.com/docs/en/hooks); [best practices](https://code.claude.com/docs/en/best-practices)

### Inferences
- Suggested gate set for westron, by layer (synthesis):
  - **Tokens:**
    - JSON Schema validation against DTCG 2025.10
    - reference resolution (no broken aliases)
    - contrast matrix for every declared fg/bg pairing in light, dark and high-contrast (WCAG thresholds)
    - generated outputs (Swift, CSS, GTK CSS, Kotlin) committed and diffed, so token changes are reviewable
  - **API parity:**
    - each component has `api.yaml` (props, states, events)
    - a script extracts the public API per platform (Swift symbol graph via `swift package dump-symbol-graph`, TS types, GObject/Vala/Rust signatures) and diffs it against `api.yaml`
    - the agent runs it; CI enforces it
  - **Visual:** snapshot tests per platform for each gallery state × theme × dynamic-type size
  - **A11y:**
    - `performAccessibilityAudit` in a UI test over the SwiftUI catalog app
    - axe via Storybook Test or Playwright for web
    - GTK accessibility checks are a gap
  - **Docs:** generated docs build cleanly (DocC for Swift, Storybook or static site for web); llms.txt and DESIGN.md regenerated and diff-checked
- CI runners: Apple snapshot jobs must pin the Xcode version, simulator model and OS. Web snapshot jobs should run in a pinned container. Otherwise baselines churn (the cross-environment warnings from both Point-Free and Playwright imply this).

### Gaps
- GitHub Actions macOS runner images (e.g., macOS 26 / Xcode 26 availability, pricing) were not verified in this pass.
- Linux GTK/libadwaita snapshot testing and accessibility audit tooling was not researched. No source found.
- No published "API parity linter" across Swift, TS and GTK for design systems was found. It would be custom.
- The exact swift-snapshot-testing precision parameters (`precision`, `perceptualPrecision`) were not on the fetched README page.

---

## 6. Repository strategy, versioning and release automation

### Takeaway
A monorepo (tokens, spec, all platform libraries) best suits one human plus an agent: one spec PR can carry all platform implementations and atomic token changes, and the agent sees everything. SwiftPM's hard constraint — a remote package's `Package.swift` must be at the repository root, and versions come from repo-level git tags — means either:
- (a) put `Package.swift` at the monorepo root and use **unified semver tags** for the whole repo, or
- (b) mirror or split-publish the Swift package into its own repo.

Changesets and Style Dictionary are the common npm-side tooling.

### Cited Findings
- **SwiftPM root requirement:** a Swift package must be released as a git repository with `Package.swift` at its root. A forum proposal to relax this has not shipped, and multi-package repositories were "proposed years ago but … not shipped" **[forum threads, several >12 mo]** — [Swift Forums: allow Package.swift not at root](https://forums.swift.org/t/allow-package-swift-to-not-be-at-the-root-of-the-repository/60431); [Swift Forums: multi-package repos](https://forums.swift.org/t/spm-multi-package-repositories/43193/7)
- **Tags:** "tags are associated with repos and not branches". No supported subdirectory-scoped version tags were found **[>12 mo]** — [Swift Forums](https://forums.swift.org/t/monorepo-using-spm-packages/53739)
- **Workarounds:**
  - a CI workflow that copies a subfolder into a separate branch or repo root and tags it there — Material Color Utilities issue — [material-color-utilities #143 mirror](https://git.tdem.in/material-foundation/material-color-utilities/issues/143)
  - Touchlab's GitHub Action for pushing a remote Swift package (used in the KMP world) — [touchlab/ga-push-remote-swift-package](https://awesome.ecosyste.ms/projects/github.com%2Ftouchlab%2Fga-push-remote-swift-package)
  - env-var switching between local `path:` and remote `url:` dependencies — [Swift Forums](https://forums.swift.org/t/use-of-swiftpm-for-internal-modules/35713?page=2)
  - Apollo manages Swift packages in a monorepo with git subtrees — [Apollo blog](https://apollographql.com/blog/how-apollo-manages-swift-packages-in-a-monorepo-with-git-subtrees)
- **Local development:** Xcode prefers a local package added to a project or workspace over the remote reference — [Swift Forums](https://forums.swift.org/t/can-we-prefer-local-package-and-fallback-to-url-package/55676)
- **npm side:** Changesets collects per-PR change notes, bumps versions and publishes, wired via `changesets/action`. It is often paired with Turborepo **[secondary]** — [Steve Kinney, versioning and release management](https://stevekinney.com/courses/enterprise-ui/versioning-and-release-management); [turborepo-design-system example](https://github.com/anthonyhastings/turborepo-design-system/blob/main/README.md)
- **Claude Code release skill:** the docs' own example `release` skill runs `pnpm changeset version`, writes CHANGELOG entries from merged PRs ("user-facing changes only"), tags `v<new version>` and lets CI publish ("never publish from your machine"). It uses `disable-model-invocation: true` — [Claude Code best practices](https://code.claude.com/docs/en/best-practices)
- **Claude Code monorepo support:** nested `<subdir>/.claude/skills/` load only for sessions in that subtree; `.claude/rules/` with `paths:`; a dedicated docs page on monorepos and large repos — [Claude Code skills](https://code.claude.com/docs/en/skills); [common workflows](https://code.claude.com/docs/en/common-workflows)
- **Tokens to platforms:** Style Dictionary transforms one token source into CSS, Swift, Kotlin, etc. Example pipelines run Figma Variables → JSON → Style Dictionary → CSS/Swift/Kotlin **[secondary]** — [dev.to tokens for mobile](https://dev.to/beefedai/design-tokens-for-mobile-apps-scalable-theming-3ick); [Design Systems Collective, tokens to code](https://www.designsystemscollective.com/the-missing-piece-in-mobile-development-tokens-to-code-chapter-2-cd386259ce40)

### Inferences
- Recommended westron layout (synthesis; check the SwiftPM constraints before committing):

```
westron/                       # one git repo
  Package.swift                # SwiftPM manifest at root (required for remote consumption); targets point into platforms/apple/
  CLAUDE.md  AGENTS.md         # CLAUDE.md starts with @AGENTS.md
  .claude/{skills,agents,rules,settings.json}
  design-language/             # principles, voice, color, type, shape, motion, layout, icons, a11y, platform adaptation
  decisions/                   # foundation-level decision records
  tokens/                      # DTCG 2025.10 *.tokens.json + resolver (themes/modes)
  spec/components/<name>/      # spec.md, api.yaml, decisions/, reference screenshots
  platforms/apple/             # Sources/WestronTokens (generated), Sources/WestronUI, Catalog app, Tests (snapshots, a11y audit)
  platforms/web/               # npm workspace package(s), Storybook/gallery, Playwright
  platforms/linux/             # GTK/libadwaita (or other) library + demo app
  platforms/android/           # later: Compose library + showcase, Roborazzi
  tools/                       # token build (Style Dictionary or custom), parity checker, matrix renderer, llms.txt/DESIGN.md generators
```

- **Versioning options:**
  - **(a) Unified version (recommended early):** one semver for the whole design system. Git tags `1.4.0` drive SwiftPM. The npm, Linux and Android packages publish the same version from the same tag. This is simplest for one human, keeps platforms in lockstep with the spec, and avoids SwiftPM tag problems. The cost is "empty" releases on platforms that didn't change.
  - **(b) Per-platform versions:** needed only once platforms diverge in cadence. Requires a separate mirror repo for the Swift package, because SwiftPM can't read prefixed per-package tags. This is an inference from the repo-level-tag constraint; verify it.
- **Consumers:**
  - Apple apps depend on the Git URL with `from: "1.0.0"`.
  - Web apps use the npm semver range.
  - Agent-assisted upgrades: a `/upgrade-westron` skill in each consuming product reads the westron CHANGELOG and migration notes, then applies codemods.
  - A machine-readable `CHANGELOG` with "breaking/migration" sections makes this tractable for agents.

### Gaps
- Whether SwiftPM in Swift 6.x (2026) gained any support for non-root manifests or prefixed tags was not confirmed. The forum threads found are older.
- Release-please vs Changesets for a polyglot (Swift + npm + Rust/C + Kotlin) monorepo was not researched in depth.
- Maven Central and Linux distribution packaging (Flatpak, distro packages, crates.io or Meson subprojects) were not researched.

---

## 7. Recommended build order, MVP scope and failure modes for a new design system built by a tiny team

### Takeaway
Published guidance converges on:
- start from a real consumer: extract from a real product, or run a pilot
- define principles and a small token foundation (color, type, spacing, shape, motion)
- build the handful of components that cover ~80% of the first product's screens
- then add patterns and docs

Failure modes for tiny teams are premature abstraction, doing too much too soon, and having no real consumer. Survey data adds a 2026-specific failure mode: AI-generated UI bypassing the system (59%).

### Cited Findings
- **Dan Mall:** if you already have a product that is "clearly a good foundation for a design system… no need to pilot; instead, extract and abstract the appropriate components and patterns you need". The best pilot candidates come "after planning for the pilot has begun but before it gets designed or built" (post date not shown; likely **[>12 mo]**) — [Dan Mall, Pilots & Scorecards](https://danmall.com/posts/design-systems-pilots-scorecards)
- Components should be derived from real products (summary of Mall's course) **[secondary]** — [NearForm](https://commerce.nearform.com/blog/2024/design-systems-lessons-learned)
- **Sparkbox:** small teams sharing a standup, board and repo often don't need a formal system. Start with "super small abstractions around the color system, typography, and a few similar things". A system shows its value during active development **[>12 mo likely]** — [Sparkbox, When not to use a design system](https://sparkbox.com/foundry/when_not_to_use_a_design_system)
- Design systems fail "when you try to do too much too soon" — [Measured, Why design systems fail](https://dev.to/measuredco/why-design-systems-fail-3ii)
- If developers find it faster to build from scratch, they will — [Rangle, Why your first design system will fail](https://rangle.io/blog/why-your-first-design-system-will-fail)
- **Bottleneck-driven scope:** if consistency is the bottleneck, build an exhaustive token set and few components; if delivery speed is the bottleneck, build more components and fewer tokens **[secondary]**. Another guide: identify the components that build 80% of the app — [Peter Kocur](https://peterkocur.substack.com/p/how-to-build-a-design-system-fast); [Obvious, design system in 8 weeks](https://medium.com/obvious-in/how-to-build-a-design-system-in-8-weeks-79373317c97b)
- **Nathan Curtis** (via a secondary summary): buttons often come first, but button styling can "invert many of the token decisions made elsewhere". Curtis treats a design system as an ongoing product, not a project **[secondary]** — [Design Systems Collective newsletter](https://www.designsystemscollective.com/the-first-component-debate-micro-frontends-ai-in-design-503170b6c139); [UX Planet on Curtis's framework](https://uxplanet.org/planning-a-design-system-work-insights-from-nathan-curtiss-framework-902b27dc81c4)
- **2026 adoption reality:** 59% report UI built outside the design system and 50% say other teams' AI use creates real problems. Recommended order: documentation, MCP, quality — [zeroheight 2026](https://zeroheight.com/resources/state-of-ai-in-design-systems/). Only 38% of design systems reach wide adoption **[secondary]** — [zeroheight report webinars](https://webinars.zeroheight.com/register/zeroheight-design-systems-report-2026-the-findings)
- **Atlassian:** "teams who try to create a single source of truth just end up creating another one" — [Atlassian, Jun 2026](https://www.atlassian.com/blog/ai-at-work/teaching-ai-to-speak-our-design-language)
- **Figma:** agent value depends on coverage of the components agents actually use. Connect the most-used components first — [Figma blog, Aug 2026](https://figma.com/blog/the-benefits-of-code-connect-in-mcp); [fast.io](https://www.fast.io/resources/mcp-server-for-figma/) **[secondary]**

### Inferences
- **Realistic phased roadmap for westron** (one human plus Claude Code; synthesis of the sources above, durations indicative only):
  - **Phase 0 — Setup (≈1 week):**
    - monorepo skeleton
    - CLAUDE.md/AGENTS.md
    - skills: `/new-component`, `/implement-platform`, `/visual-check`, `/release`
    - reviewer subagents
    - hooks
    - CI with one trivial component per platform
    - catalog app shells (SwiftUI catalog, web gallery, GTK demo)
    - **Pick the first consuming product now.** It should be a real app the human is building (Dan Mall's pilot logic).
  - **Phase 1 — Design language and foundations (≈2–3 weeks):**
    - principles (3–5, each with a "this means… / this doesn't mean…")
    - voice
    - color: primitive and semantic tokens, light/dark/high-contrast, contrast-checked
    - type: a scale mapped per platform (SF Pro / Dynamic Type on Apple; system or brand font on web/Linux)
    - spacing and layout grid; shape (radii); elevation; motion (durations, easings, reduced-motion)
    - iconography approach (SF Symbols on Apple vs a shared icon set elsewhere)
    - platform adaptation rules
    - Each foundation gets a decision record. The token pipeline generates Swift, CSS and GTK CSS. The gallery shows foundation swatches.
  - **Phase 2 — Core primitives (≈2–4 weeks):**
    - layout primitives (Stack, Spacer/Gap, Surface/Card container), Text styles, Icon, Divider
    - Button (all variants; note Curtis's warning that button decisions stress the token model)
    - TextField, Toggle/Switch, Checkbox, Radio
  - **Phase 3 — First 10–15 components, driven by the pilot product's screens:**
    - Select/Menu, Segmented control/Tabs, List row/Cell, Card, Dialog/Alert, Sheet/Popover, Toast/Banner, Progress/Spinner, Badge/Tag, Avatar, Tooltip, Navigation bar/Toolbar, Search field, Empty state
    - On Apple, many of these should *wrap or style native controls* rather than reimplement them, to stay "native-feeling". This is a design-language rule worth recording explicitly.
  - **Phase 4 — Patterns and docs:**
    - forms and validation, empty/error/loading states, settings screens, onboarding
    - generated docs site, llms.txt, DESIGN.md
    - optional local MCP server once the component count makes on-demand retrieval worthwhile (Atlassian's evidence)
  - **Phase 5 — Android:** add a Compose library, showcase app and Roborazzi tests. Because specs and tokens are platform-neutral, this is mostly per-platform implementation tasks.
- **Failure modes to guard against (tiny team plus agent):**
  - **Premature abstraction:** the agent will happily generate 40 components. Gate new components on a real pilot-product need (a "consumer link" field in each spec).
  - **Platform API drift:** enforce with parity checks.
  - **Doc and spec drift:** generate docs from specs; make the agent update the spec in the same PR.
  - **Baseline churn in snapshots:** pin environments.
  - **Non-native feel from over-custom components:** a platform-adaptation rule saying "prefer native control plus styling".
  - **Unreviewed agent volume:** keep PRs per component; insist on screenshot evidence.

### Gaps
- Nathan Curtis's own published sequence ("Your first component", "And You Thought Buttons Were Easy") was not retrieved directly.
- No 2025–2026 Sparkbox survey data was retrieved.
- No published case study of a one-person-plus-AI-agent multi-platform design system (with measured timelines) was found. The durations above are not sourced.
- Typical MVP component lists from authoritative sources (e.g., the component.gallery frequency data) were not retrieved; the list above is synthesis.

---

## 8. What a good design language document contains, and examples worth emulating

### Takeaway
Sources converge on these sections:
- principles that every token and component traces back to
- voice and tone with do/don't examples
- color (tokens, roles, contrast rules)
- typography (stack, scale, line heights)
- shape and elevation
- motion (intent, durations, easings, reduced motion)
- layout and spacing
- iconography
- an accessibility baseline
- explicit platform-adaptation rules: follow platform conventions for navigation, interaction and behavior; express the brand through color, type, iconography and motion
- a change log / decision log

2026 adds a machine-readable layer (DESIGN.md front matter, Figma Specs, Atlassian schemas) so agents can consume it.

### Cited Findings
- **Platform adaptation:** "follow the platform for navigation, interaction patterns, and component behavior; apply the brand to color, typography scale, iconography, and illustration" **[secondary]** — [get-design-done platforms reference](https://cdn.jsdelivr.net/npm/@hegemonart/get-design-done@1.60.4/reference/platforms.md)
- Cross-platform consistency means shared intent, not identical components ("consistency does not mean identical") — [Design Systems Collective, One design language, many platforms](https://www.designsystemscollective.com/one-design-language-many-platforms-how-brands-can-create-consistent-experiences-everywhere-71dade6eb0a0)
- Typical structure: foundations (color, typography, elevation, iconography, motion), components, accessibility, tokens, platform strategy. Principles serve as working rules that every token and component traces back to; voice is given as a writing-principles table with do/don't examples; motion should clarify rather than decorate and respect reduced motion; accessibility (contrast, touch targets, screen readers, reduced motion) is a required section; a decision log and version history are kept **[secondary, examples from individual DS sites]** — [Tessera UI principles](https://jkguidaven.github.io/tessera-ui/design-language/principles); [Automattic design system foundations](https://system.automattic.design/foundations/); [pb-design-language playbook](https://vnykmshr.github.io/playbook/commands/planning/pb-design-language.html)
- **Figma Specs** (Oct 2026): a Markdown editor to "define their design language", referencing canvas elements and code layers, intended as a reference for teams *and agents* — [TechCrunch](https://techcrunch.com/2026/10/14/figma-announces-new-features-to-define-how-agents-work-on-its-platform/)
- **DESIGN.md** (Google Stitch, Apr 2026): colors, typography, spacing, components and rules, with YAML front-matter tokens **[secondary]** — [Better Stack](https://betterstack.com/community/guides/ai/design-md-ai/)
- Atlassian's DESIGN.md is a public example of a large system's design language in agent-readable form (atlassian.design/DESIGN.md). Their schema-based content model covers usage, props, content standards and accessibility per component — [Atlassian, 15 Jun 2026](https://www.atlassian.com/blog/how-we-build/atlassians-design-md-is-here-what-we-learned-testing-portable-design-context-in-practice); [Atlassian, 2 Jun 2026](https://www.atlassian.com/blog/ai-at-work/teaching-ai-to-speak-our-design-language)
- Components should carry intent, behavior, accessibility and usage rules, not only visual properties — [Southleft, May 2026](https://southleft.substack.com/p/context-based-design-systems-revisited)

### Inferences
- **Proposed westron design-language document set** (synthesis): one folder, one file per chapter so agents can load chapters selectively, plus a generated DESIGN.md digest.
  1. `00-principles.md`: 3–5 principles, each with rationale, "this means / this doesn't mean", and an example decision it resolved.
  2. `01-voice.md`: tone attributes; do/don't table; terminology list; error-message, button-label and empty-state formulas.
  3. `02-color.md`: primitive palette → semantic roles (surface, content, accent, status, border, focus); light, dark and increased-contrast; contrast rules (pairings and thresholds); mapping to platform semantics (Apple semantic colors and accent color, GTK/libadwaita named colors, CSS custom properties).
  4. `03-typography.md`: per-platform font stack; semantic text styles mapped to Dynamic Type on Apple; scale, weights, line height; truncation rules.
  5. `04-shape-elevation.md`: radius scale and when to use each; borders; shadows vs. materials per platform.
  6. `05-motion.md`: intent (when motion is allowed); duration and easing tokens; spring parameters for SwiftUI; reduced-motion behavior.
  7. `06-layout-spacing.md`: spacing scale; density modes; grids and breakpoints (web); adaptive layout (size classes on Apple); touch and click target minimums.
  8. `07-iconography.md`: SF Symbols on Apple vs shared icon set elsewhere; sizes and weights matched to type; naming.
  9. `08-accessibility.md`: baseline (WCAG 2.2 AA-equivalent contrast, Dynamic Type support, VoiceOver/Orca/TalkBack labels, focus visibility, reduced motion and transparency); this doubles as the checklist the a11y-auditor subagent enforces.
  10. `09-platform-adaptation.md`: "follow the platform for navigation, interaction, control behavior; express brand through color, type, shape, motion, icon style". A per-platform table of what is native vs. custom. Rules for when to wrap native controls.
  11. `CHANGELOG.md` / `decisions/`.
- Examples worth emulating (well-known, not re-verified in this pass):
  - Material 3 "Foundations" and "Styles" (m3.material.io)
  - Apple Human Interface Guidelines "Foundations" (developer.apple.com/design/human-interface-guidelines)
  - Microsoft Fluent 2 (fluent2.microsoft.design)
  - GNOME HIG (developer.gnome.org/hig), for the Linux platform conventions
  - Atlassian's DESIGN.md, as an agent-readable digest

### Gaps
- The specific structure of Material 3, Apple HIG, Fluent 2 and GNOME HIG design-language sections was not re-fetched in this pass. The examples above rest on general knowledge and should be verified by the report writer before being cited as sourced.
- No 2025–2026 article comparing design-language documents across major systems was found.
- Josh Clark's "Sentient Design" guidance on AI-era design language was not retrieved.
