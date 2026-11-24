# 0018. Patterns: compositions of westron's components, written as sources

Date: 2026-11-24. Status: a proposal for the owner (#35, stage 1). Each question below is the owner's, with the
recommendation marked (A); the first pattern, `spec/patterns/choice-list-sheet.md`, is drafted to the recommendations.

## Context

Issue #35 asks for patterns: "Forms, errors, empty and loading states, settings." decisions/0014 keeps a small core and
leaves composition to products; decisions/0016, point 4, orders patterns right after the agent context, because a
pattern is what an agent composing a screen needs most, and patterns feed the context bundle the westron plugin carries.

The check of decisions/0016, point 5 (2026-11-24, the comment on #37; the evidence on the branch
`evidence/37-pilot-check`): a fresh agent with only the plugin's skill moved todo-app's "Move to…" picker to westron.
The components were enough. What it could not find was how to compose them: whether the current choice is `selected`
or a check (its Q3), how an area that can be chosen is built (Q2), how the rows keep one column at their end (Q4), where
a hint under a sheet's title goes (Q10) and how large the Mac's sheet is (Q9). The owner decided the same day that "a
list of choices in a sheet" is the first pattern of #35.

Nothing in westron says what a pattern is. The only composition guidance is sketches in contracts' decisions, which
are not in the bundle and are not checked: ListRow's decisions/0001, "The pilot's rows, composed", writes
`ListRow(…) { IconTile(…) } title: { … }`, which is not the initializer that was built (the title is the first
closure, the tile goes in `leading:`).

## Questions

**Q1. What a pattern is.**
- (A, recommended) A composition of existing components, system containers and tokens for one job a person does on a
  screen (choose one of many, fill a form, meet an empty list), with rules and the reason for each: which component
  takes which part, with which options, what stays the system's, what the product writes in words, what assistive
  technology hears. It adds no component, option, state, token, icon or modifier, and its code calls only what
  WestronUI declares. A contract is one component's API and look, generated into code and held by the parity lint and
  the snapshot matrix; a pattern generates nothing, and its code is an example. A design-language chapter states a rule
  for every screen (color, layout); a pattern applies the chapters to one job. When a pattern needs what westron lacks,
  it records the gap and the issue it would become, and says what a product does meanwhile; the change itself goes
  through `/new-component` or a revision of the contract, the first gate (decisions/0005), never through the pattern.
- (B) A pattern may propose a small addition, such as a modifier, for a later pull request: faster, but it puts an API
  in a document that is not a contract, against rule 1.
- (C) Patterns as sections of the design-language chapters: no new kind of document, but each chapter grows by every
  job, and the chapters are CC BY (decisions/0007) while a pattern carries code.

**Q2. Where patterns live, and their format.**
- (A, recommended) `spec/patterns/<id>.md`, one file per pattern, beside `spec/components/` and under MIT like the
  contracts; the id is kebab-case and names the job (`choice-list-sheet`). Markdown, since a pattern is mostly prose
  (decisions/0004), with YAML front matter the generator and a check read deterministically: `id`, `title`, `status`
  (`proposed` or `approved`), `summary` (one line, for the bundle's index), `consumers` (the product screens, as a
  contract's, rule 6), `components` (contract ids), `tokens` (source names, `space.page.narrow`), `icons` (registry
  names) and `gaps` (the gaps it records). Fixed sections, in this order: "When to use", "Parts", "Rules",
  "Accessibility", "Apple" (one complete example), "Not covered", "Gaps", and "Questions" while it is proposed; each
  later platform adds a section. A check, of a later stage, holds every component id to a contract, every token to the
  token model, every icon to the registry, and the names the example writes to WestronUI's reviewed API, as the
  bundle's prose is held today (`ContextNames`).
- (B) YAML like a contract, the prose in block strings: one parser, but long prose in YAML strings is hard to read and
  to review (ListRow's description runs to 120 lines).
- (C) Plain Markdown with no front matter: nothing for a check to hold to the sources, and the index would have to
  parse headings.

**Q3. How a pattern is approved.**
- (A, recommended) As a contract, at the first gate: the owner approves it, or the coordinating agent under a
  delegation of the owner's, as in phase 4 (decisions/0014, "Process"), and its front matter says `approved`. It
  changes no code, so the second gate has nothing to review until the pattern has an example in the catalog (Q4); its
  screenshots then join the second gate as a supplement does. There is no release step: the bundle reaches users with
  the next commit (decisions/0016, open point 1), so only an approved pattern enters it.
- (B) A decision in `decisions/` per pattern: a familiar gate, but decisions are not sources the generator reads.

**Q4. How a pattern is checked.**
- (A, recommended) Stage 1: its example is compiled against the checkout from a scratch package, as
  decisions/0017 does for `WestronContract`, and the build's last line goes into the pull request. Stage 2: the
  example becomes a catalog entry, so it compiles with the catalog in CI, the accessibility audit and VoiceOver's
  reading cover it and a screenshot shows it; and `tools/westron` gains the front-matter check of Q2 as a step of
  `tools/check.sh`.
- (B) The examples in a test target that only compiles them: cheaper, but no screenshot and no audit.
- (C) No check: the prose drifts from the API, as ListRow's sketch did.

**Q5. How patterns reach agents** (a later stage's code; what it needs from the format).
- (A, recommended) The generator copies each approved pattern to `context/patterns/<id>.md`, its links rewritten as
  the chapters' are, and `index.md` gains a section "Patterns", one line per pattern from its `title` and `summary`; a
  component's card may list the patterns that use it, from `components`. `SKILL.md`, hand-written, says to read the
  pattern for a job before composing a screen. The stage needs from the format: the front matter of Q2, links relative
  to the repository, and a pattern that stands alone, as a card does.
- (B) Patterns stay in the repository and the skill links to them: no generation, but a product's agent cannot read
  them (decisions/0016, the plugin's directory).

**Q6. The patterns #35 names, and their order.**
- (A, recommended) 1. `choice-list-sheet` (this stage). 2. `empty-state`: `ContentUnavailableView` with an IconTile
  and text roles (decisions/0014, "What stays the system's"), the pilot's empty screen. 3. `form`: framed and inline
  TextFields, labels, a field's error, the primary Button, the pilot's naming and task card. 4. `errors` beyond a
  field: an alert, a confirmation, a status line, the pilot's delete confirmation. 5. `loading`: Button's
  `.loading(_:)` and the system's `ProgressView`. 6. `settings`, when a product has a settings screen: a pattern names
  its consumers, as a contract does (rule 6).
- (B) The issue's order, forms first: the largest pattern before the format has been tried on a small one.

## Consequences

- If accepted, `spec/patterns/` is a source: the first pattern goes from `proposed` to `approved` with the owner's
  answers to its own questions, and the later stages build the check, the catalog example and the bundle's section.
- Stage 1 changes no code: no contract, schema, generator, plugin or chapter, and `tools/westron generate --check`
  is unchanged.
- ListRow's sketch of a "Move to…" row (its decisions/0001) gives way to the pattern once the pattern is approved; the
  sketch stays as written, as decisions do.
- A gap a pattern records becomes an issue only when the owner says so.

### Open points

1. **Other platforms.** A pattern has an "Apple" section now; the web's comes with phase 6, and a pattern says where a
   platform composes it differently, as a contract's `platforms` block does.
2. **A product's own patterns.** Whether a product keeps its own compositions in this format, in its repository.
3. **The version an agent reads** is decisions/0016's open point 2: a pattern can be newer than the WestronUI a
   product is pinned to.
