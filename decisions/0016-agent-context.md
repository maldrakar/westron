# 0016. Agent context: skills and generated files, no MCP server

Date: 2026-11-24. Status: accepted by the owner on 2026-11-24, point 6 included: the owner decided the same day that the
context is distributed as a Claude Code plugin from the start.

## Context

Phase 5, "Patterns, documentation, agent context" (milestone 6: #35, #36, #37, #38), starts after phase 4 closed on
2026-11-24. Issue #37 asks for "`llms.txt`, a skill with the design language and, once there are many components, a
local MCP server", everything generated from the source. The research report plans the same: an agent context layer of
"Skills, `llms.txt`, a short DESIGN.md and later MCP" (`reports/westron-design-system-research.md`, the table of
layers, row 7) and "a local MCP once there are many components" (its work plan, phase 5).

The source is small: eleven contracts (`spec/components/*/*.spec.yaml`), ten design-language chapters
(`design-language/00`–`09`) and `spec/conventions.md` come to about 4100 lines. The report's measurements (section
"Spec-first with three approval gates is the best way to work with Claude Code", the Atlassian paragraph) favour
"structured context loaded on demand" over a volume of prose. There an MCP server beat one large DESIGN.md, which did
worse than no context at all; skills were not among the strategies compared.

The owner wants westron available to agents "not only when creating UI code, but also when creating the designs
themselves, for example in Claude Design". The source for the state of that tool is the Claude Code session of
2026-11-24: its DesignSync tool states that standalone Claude Design (claude.ai/design) closes by 2026-12-14 and that
Claude Design now lives in Claude. There an artifact of the "Design System" type (a README, tokens, components with
live previews, guidelines) is what Claude's Design and Slides artifacts read. The owner had no Design System artifact
that day.

## Decision

The owner, 2026-11-24, on the coordinating agent's proposal: points 1 to 5.

1. **Skills and generated files, no MCP server.** In the owner's words, an MCP server "seems excessive, most likely
   everything can be solved very effectively with skills". Reasons: the whole source fits a short index and
   per-component files read on demand, which is the structured context loaded on demand that the measurements favour;
   an MCP server is a process to run and version, and its tool definitions sit in an agent's context all the time.
   Revisit when a consumer agent has no file access, when the catalog no longer fits an index, or when a live
   operation is needed, such as rendering a component and returning a picture.
2. **Two channels from one source.**
   - *The code channel, now (#37).* `tools/westron generate` writes a context bundle from the contracts, the tokens
     (`tokens/`), the icon registry (`spec/icons/icons.yaml`) and `spec/conventions.md`: an index; one card per
     component (how it is called in SwiftUI, its options, states and accessibility, what not to do); tables of tokens
     and icons; and the design-language chapters as reference files, so that the bundle stands alone in a consumer
     repository. `tools/westron generate --check` catches drift, as for all generated code (rule 4). Over the bundle,
     a thin hand-written `SKILL.md` points into it. Agents outside the Claude family reach the same files through
     `llms.txt` and a paragraph for the product's `AGENTS.md` (#38).
   - *The design channel, after phase 6.* An artifact of the "Design System" type in Claude, which Claude's Design and
     Slides artifacts read. Its previews are HTML and westron exists only in SwiftUI, so it is built from the web
     library of phase 6, which gives that library its first real consumer (rule 6).
3. **The design channel's previews.** Three options were considered:
   1. Pull the CSS token generator (#39, phase 6) forward and hand-write HTML previews now. Rejected: a second,
      simplified rendering of every component, which must be checked against the snapshot matrix and which phase 6
      replaces.
   2. Tokens, guidelines and PNGs from the snapshot matrix only. No second implementation, but a designing agent
      rebuilds every component from tokens. Kept as an interim step, available if a design system in Claude is wanted
      before phase 6 ends; not planned.
   3. Wait for the web library. **Taken.**
4. **Order.** This decision; then #37, the code channel; #35, patterns (forms, errors, empty and loading states,
   settings): decisions/0014 leaves composition to products, so patterns are what an agent composing a screen needs
   most, and they feed the bundle; #38, rules for consumer repositories. Then phase 6, the web. Then the Design System
   artifact and #36, documentation, whose site also wants live web examples. Phase 5 is thus split around phase 6. One
   pull request per issue (decisions/0005).
5. **How #37 is checked** (rule 7). On the pilot, todo-app (https://github.com/maldrakar/todo-app, decisions/0006), an
   agent with a fresh context and the skill moves one or two of its screens to westron's components. The evidence:
   the app builds, the raw-values lint passes on the moved screens, and no hand-made component stands where westron
   has one. Which screens is chosen at #37 with the owner.
6. **The consumers of the code channel** (the owner, 2026-11-24, on the coordinating agent's proposal): Claude Code
   first, through the skill shipped as a Claude Code plugin from this repository from the start, with the plain files
   for other agents (`llms.txt`).

### Open points

None is settled here; the first two are #37's.

1. **The bundle's directory and layout.** A proposal for #37 to take or change:

   ```
   skills/westron/SKILL.md        hand-written: when to use the skill, how to read the bundle
   skills/westron/context/        generated by tools/westron generate; not edited by hand
     index.md                     one line per component, token group, icon table and chapter, with its file
     components/<id>.md           one card per contract
     tokens.md, icons.md          the tables
     design-language/             the chapters 00–09, copied
   llms.txt                       generated, at the root; links into skills/westron/context/
   .claude-plugin/                the plugin's manifest, if point 6 is accepted
   ```

   The skills in `.claude/skills/` stay what they are: the process for working on westron, not context for products.

   *Settled on 2026-11-24 by #37, as built:*

   ```
   .claude-plugin/marketplace.json            the marketplace "westron": one plugin, source ./plugins/westron
   plugins/westron/                           the plugin's root; an installed plugin is this directory, copied
     .claude-plugin/plugin.json               the manifest: name "westron", no version, so users track commits
     skills/westron/SKILL.md                  hand-written: the rules, how to read the bundle
     skills/westron/context/                  generated by tools/westron generate; not edited by hand
       index.md                               one line per component, token page, the icons, the SwiftUI page and
                                              chapter, with its file
       components/<id>.md                     one card per contract: what a call needs
       components/<id>.details.md             the contract's prose on behavior, accessibility and Apple
       tokens/color.md, typography.md, layout.md, motion-and-shadow.md
       icons.md, swiftui.md
       design-language/                       the chapters 00–09, copied
   llms.txt                                   generated, at the root; links into the bundle
   ```

   The plugin's root is a small directory, not the repository's root: Claude Code copies a marketplace plugin into
   its cache and leaves out every file outside the plugin's directory (Claude Code's plugin loading reference, "In-place
   and copied plugins"), so the skill and its bundle live inside it. A product adds this repository as a marketplace
   and installs the plugin (`README.md`, "For agents in a product": `claude plugin marketplace add maldrakar/westron
   --scope project`, then `claude plugin install westron@westron --scope project`); the repository is public, so
   neither needs credentials (corrected on 2026-11-24, #167: this text first called the repository private, from a
   wrong brief, and asked for git access to it). With no `version` in the manifest, Claude Code takes the commit of
   the plugin's directory as its version, so an update reaches users with the next commit that changes it; `claude
   plugin validate` warns about the missing version. Open point 2 stays open: a product pinned to an older WestronUI still reads the newest bundle.

   Changes from the proposal: the tables of tokens are split by kind, since one table of every token ran to several
   hundred lines; each card holds only what a call needs, and the contract's prose goes to a details file beside it,
   since the prose alone made a card of 300 lines; `swiftui.md`, how a contract's concepts become SwiftUI, is generated
   from `spec/conventions.md`, its section on the system's controls and the SwiftUI column of its table, without its
   pointers to sections it does not copy. The copied chapters keep their links to each other and to the bundle's files;
   a link to the rest of westron's repository is left as its text. Every westron name the generator's own prose
   writes is looked up in the token model and WestronUI's reviewed API (`ContextNames`), so a rename fails generation.
   The generator is `AgentContext` (`tools/Sources/WestronTools/Context/`); the bundle's directory is owned by it, so a
   file it no longer writes is stale.
2. **The version a consumer reads.** A product pins westron through SwiftPM, and a plugin can be newer than the pinned
   checkout. How a consumer gets the context of exactly the version its package is pinned to, for example by reading
   the bundle from its SwiftPM checkout rather than from the plugin.
3. **The milestone.** Whether the Design System artifact and #36 stay in phase 5's milestone or move to phase 6's.

## Consequences

- Issue #37's "once there are many components, a local MCP server" and the report's "later MCP" (the table of layers,
  row 7; its work plan for phase 5, "a local MCP once there are many components") are superseded by this decision. The
  report and the issue's text stay as written; this decision is what holds.
- The bundle is generated code. A change to a contract, a token, the icon registry, `spec/conventions.md` or a
  design-language chapter changes it, and `tools/westron generate --check` fails until it is regenerated.
- The skill is tested on the pilot, not only in this repository: #37 is done when the check of point 5 has its
  evidence.
- Phase 5 does not close before phase 6 while the Design System artifact and #36 stay in its milestone (open point 3).
- The web library of phase 6 has a consumer besides parity: the previews of the Design System artifact.
- Until phase 6, an agent that makes designs in Claude has no westron Design System to read; option 2 of point 3 is
  the step available if that is wanted sooner.
