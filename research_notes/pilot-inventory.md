# Pilot design inventory: todo-app → westron tokens

Read-only inventory for westron phase 1 (issues #10 colors, #11 typography/spacing/radii/shadows/motion, #15 WCAG
pairs, #16 icons and fonts). Pilot: todo-app at `227606c` (2026-11-13). Written 2026-11-15 by an agent, read-only; file:line references are to that commit.
`.superpowers/` and `.build/` were ignored except where noted (the only local canvas copies live in `.superpowers/`).

## How to read the references

| Short | Path (in todo-app) | Holds |
|---|---|---|
| `DS/` | `Sources/DesignSystem/` | tokens: colours, fonts, motion, shadows, icon cases (no SwiftUI; builds for wasm32) |
| `DSC/` | `Sources/DesignSystemComponents/` | component styles and models: **field declarations only, no values** |
| `TVL` | `Sources/Features/TaskViewList/TaskViewList+Components.swift` | every value of the Lists screen (phone) and the sidebar (Mac/iPad) |
| `TLM` | `Sources/Features/TaskList/TaskList+Metrics.swift` | every value of the list screen, phone list + phone board |
| `TLP` | `Sources/Features/TaskList/TaskList+PaneMetrics.swift` | every value of the list screen, Mac/iPad pane list + pane board |
| `TLC` / `TLX` / `TLK` | `Sources/Features/TaskList/TaskList+Components.swift` / `+Controls.swift` / `+Card.swift` | which token colours/fonts each text and glyph of the list screen takes |
| `UI/` | `Apps/Apple/Sources/TodoAppleUI/` | SwiftUI adapters (`UI/DesignSystem/*.swift`) and views; values here are platform containers only |

**Layouts, not OSes.** The pilot keys its numbers by window width (`WindowWidth`, `UI/WindowView.swift:85-90`), not by OS:

- **phone** = `.narrow` (horizontal size class compact): iPhone, narrow iPad windows. `TVL` `Metrics.phone` (:694), `TLM`
  `phone` (:208) and `phoneColumns` (:263).
- **wide** = regular or no size class: **Mac**, **iPad**, iPhone Plus/Max in landscape. `TVL` `Metrics.sidebar` (:741, "the
  Mac board's"), `TLP` `pane` (:30) and `paneColumns` (:87). The iPad takes the wide numbers with the phone's gestures and
  the phone's edit-mode bar; the Mac takes the bar without edit mode, pointer hover and the toolbar's back.
- **watchOS** has no values of its own: it is a compile check (`UI/AppScene.swift:26`), draws the dark shade only
  (`UI/DesignSystem/Color+DesignSystem.swift:16-20`), leaves out `Menu` (`UI/DesignSystem/Bar.swift:53-56`,
  `UI/ListScreen/GlassButton.swift:41-42`), keyboard shortcuts, hover and context menus.

So "iOS vs macOS" below means phone vs wide; the iPad is wide.

## 0. Sources and the canvas

- The canvas files exist locally only as a snapshot taken for the list-screen work, in a git-excluded folder
  (`todo-app/.git/info/exclude:7`):
  - `todo-app/.superpowers/sdd/list-screen/canvas/Phone.dc.html` (153 KB, 2026-11-07)
  - `todo-app/.superpowers/sdd/list-screen/canvas/project/Mac.dc.html` (122 KB, 2026-11-09)
  - `…/canvas/project/MacWeek.dc.html`, `…/canvas/project/MacWeekColumns.dc.html` (0.9 KB stubs that import `Mac`)
  - `todo-app/.superpowers/sdd/list-screen/task-4-canvas.md` (an extraction of canvas numbers)
- **`Main.dc.html` of the todo canvas is not available locally.**
- The live canvas "Todo — дизайн": https://claude.ai/artifact/WWLXn8c4CcV8VKHXwpMqtU (`docs/specs/lists-screen.md:9`,
  `docs/specs/list-screen.md:15`); owner review: https://claude.ai/artifact/LkHnP681CciwgYNgJL8fkm
  (`docs/specs/list-screen.md:4`). Not fetched.
- The inventory is of the **code**. The local canvas was used only to cross-check CSS variables, curves, shadows and
  tracking; differences are flagged.

---

## 1. Colours

### 1.1 Base palette (`DS/Color.swift:42-60, 97`)

| Token | Light | Dark | Role | Defined |
|---|---|---|---|---|
| `paper` | `#FAF7F2` | `#1A1917` | screen ground (Lists phone, list screen, picker sheet, task rows) | `Color.swift:42` |
| `surface` | `#FFFFFF` | `#24221F` | cards, fields, drag cards, lifted rows | `:43` |
| `sidebar` | `#F2EDE5` | `#1F1E1B` | sidebar column and its rows/bar (canvas `--side`) | `:44` |
| `fill` | `#F0EBE3` | `#2E2B27` | chips, pills, Done strip, board columns, Mac search field, phone highlighted row, picker top-level tile | `:45` |
| `line` | `#E8E2D8` | `#35322D` | rules, dividers, area line, phone guides, dashed add-list edge | `:46` |
| `ink` | `#1F1D1A` | `#EEEAE3` | primary text and glyphs | `:47` |
| `ink2` | `#625C53` | `#ABA498` | secondary text and glyphs | `:48` |
| `ink3` | `#A39C90` | `#6F6A62` | grips, strike-through lines, sidebar area caption | `:49` |
| `red` | `#C2362B` | `#F07468` | due deadline; swipe Delete background | `:50` |
| `guide` | `#E0D9CC` | `#36332E` | sidebar tree guides (`Mac.dc.html --guide`) | `:53` |
| `accent` | `#3653C9` | `#3653C9` | **one blue in both modes** (canvas "Ink"; the canvas exposes the accent as a prop with options `#3653C9 #1F7A5C #B4471F #7A4CCB`, default `#3653C9`) | `:56, :97` |
| `onAccent` | `#FFFFFF` | `#FFFFFF` | glyphs/words on accent, and on red | `:60` |

### 1.2 Derived colours (`DS/Color.swift:62-93`)

Mixing is channel-linear in gamma-encoded sRGB (`RGB.mixed(toward:by:)`, `Color.swift:18-24`), the canvas JS `mix`.
Opacity keeps channels (`withOpacity`, `:27-29`). Two derived colours are pre-mixed opaque "so that nothing behind shows
through".

| Token | Light rule → value | Dark rule → value | Used for | Defined / tested |
|---|---|---|---|---|
| `accentSoft` | literal `#E7EAF9` | `paper.dark` mixed 24 % toward accent → `#212742` (opaque) | phone drag slot fill | `:64-65`; `Tests/DesignSystemTests/ColorTests.swift:16-19` |
| `selection` | `sidebar` mixed 14 % toward accent → `#D8D7E1` | `sidebar` mixed 22 % toward (accent mixed 32 % to white = `#768ADA`) → `#323645` | sidebar highlighted row (`Mac.dc.html selBg`) | `:71-73`; `ColorTests.swift:40-45` |
| `glass` | white @ 0.72 | `#322F2B` @ 0.72 | list-screen glass surface, OS < 26 only | `:78` |
| `glassLine` | `ink.light` @ 0.08 | white @ 0.08 | glass hairline; board-card ring | `:82` |
| `fresh` | accent @ 0.12 | white @ 0.08 | row just dropped, fades over 1.6 s | `:86` |
| `hover` | `ink.light` @ 0.05 | white @ 0.05 | Mac/iPad pointer hover tint | `:90` |
| `placeholder` | `ink2` @ 0.8 | `ink2` @ 0.8 | every field's placeholder | `:93`; `ColorTests.swift:30-35` |

Composited for reference: over paper — glass `#FEFDFB`/`#2B2925`, hover `#EFECE7`/`#252423`, fresh `#E2E3ED`/`#2C2B2A`;
placeholder over surface `#817D75`/`#908A80`.

### 1.3 List colours (`DS/Color+Components.swift`)

Eleven names the store keeps (`Tile`, `:14-15`): blue, amber, rose, green, stone, indigo, teal, pink, orange, violet, sky.
Only the **base** is a literal (`:52-66`); every shade is computed by the canvas `paint(hex, dark)` rule (present in
`Phone.dc.html`):

| Shade | Light | Dark | Defined |
|---|---|---|---|
| tile `background` | base @ 0.15 | base @ 0.24 | `:18-20` |
| tile `glyph` | base mixed 20 % toward `ink.light` `#1F1D1A` | base mixed 30 % toward white | `:24-28` |
| `dropTint` | base @ 0.10 | base @ 0.20 | `:32-34` |
| `check.ring` | base mixed 20 % toward `ink.light` (= glyph) | base mixed 18 % toward white | `:41-43` |
| `check.fill` | base | base mixed 8 % toward white | `:44` |
| `check.mark` | white; **amber: `#1F1D1A` in both modes** | same | `:74-79` |

The mark rule: white unless WCAG contrast(white, fill) < 3, then light ink. Amber alone falls under (2.61 light, 2.41
dark); next lowest are dark stone 3.26 and dark orange 3.28 (`Color+Components.swift:68-73`;
`Tests/DesignSystemTests/CheckColorTests.swift:92-128`). It is written by hand, not computed, because the module has no
`pow`.

Resolved values (computed here; blue and the check values match `TileColorTests.swift:8-19` and `CheckColorTests.swift:29-70`):

| Tile | base | bg light (15 % → over paper) | bg dark (24 % → over paper) | glyph L / D | check ring L / D | check fill L / D | mark | dropTint over paper L / D |
|---|---|---|---|---|---|---|---|---|
| blue | `#3E6EC5` | `#DEE2EB` | `#232D41` | `#385EA3` / `#789AD6` | `#385EA3` / `#6188CF` | `#3E6EC5` / `#4D7ACA` | `#FFFFFF` both modes | `#E7E9EE` / `#212A3A` |
| amber | `#D49408` | `#F4E8CF` | `#473713` | `#B07C0C` / `#E1B452` | `#B07C0C` / `#DCA734` | `#D49408` / `#D79D1C` | `#1F1D1A` (ink light) both modes | `#F6EDDB` / `#3F3214` |
| rose | `#D2455A` | `#F4DCDB` | `#462427` | `#AE3D4D` / `#E07D8C` | `#AE3D4D` / `#DA6678` | `#D2455A` / `#D65467` | `#FFFFFF` both modes | `#F6E5E3` / `#3F2224` |
| green | `#36925C` | `#DDE8DB` | `#213628` | `#317B4F` / `#72B38D` | `#317B4F` / `#5AA679` | `#36925C` / `#469B69` | `#FFFFFF` both modes | `#E6EDE3` / `#203125` |
| stone | `#8A847A` | `#E9E6E0` | `#35332F` | `#756F67` / `#ADA9A2` | `#756F67` / `#9F9A92` | `#8A847A` / `#938E85` | `#FFFFFF` both modes | `#EFECE6` / `#302E2B` |
| indigo | `#5B55D8` | `#E2DFEE` | `#2A2745` | `#4F4AB2` / `#8C88E4` | `#4F4AB2` / `#7974DF` | `#5B55D8` / `#6863DB` | `#FFFFFF` both modes | `#EAE7EF` / `#27253E` |
| teal | `#168985` | `#D8E6E2` | `#193431` | `#187370` / `#5CACAA` | `#187370` / `#409E9B` | `#168985` / `#29928F` | `#FFFFFF` both modes | `#E3ECE7` / `#192F2D` |
| pink | `#C64C88` | `#F2DDE2` | `#432532` | `#A54372` / `#D782AC` | `#A54372` / `#D06C9D` | `#C64C88` / `#CB5A92` | `#FFFFFF` both modes | `#F5E6E7` / `#3C232E` |
| orange | `#D7652C` | `#F5E1D4` | `#472B1C` | `#B25728` / `#E3936B` | `#B25728` / `#DE8152` | `#D7652C` / `#DA713D` | `#FFFFFF` both modes | `#F6E8DE` / `#40281B` |
| violet | `#8452C8` | `#E8DEEC` | `#332741` | `#7047A5` / `#A986D8` | `#7047A5` / `#9A71D2` | `#8452C8` / `#8E60CC` | `#FFFFFF` both modes | `#EEE6EE` / `#2F243A` |
| sky | `#2A86B9` | `#DBE6E9` | `#1E333E` | `#287199` / `#6AAACE` | `#287199` / `#509CC6` | `#2A86B9` / `#3B90BF` | `#FFFFFF` both modes | `#E5ECEC` / `#1D2F37` |

- A list with no colour, or an unknown name, draws **stone** (`TLC:382-384`, `TaskViewList+Rows.swift:173-175`); no icon
  draws `bullets`.
- Seeds: Inbox blue/tray, Today amber/sun, Upcoming rose/calendar, Logbook green/logbook, Trash stone/trash
  (`docs/specs/lists-screen.md:53`).
- **A list colour used as a semantic colour:** the card's When pill draws its sun in `Tile.amber.glyph` when a day is set
  (`TLK:103`). westron will want a semantic token ("when/today") instead.

### 1.4 Where each colour is used

- `paper`: Lists phone ground (`UI/ListsScreen/ListsScreen.swift:24`) and its two fades (`:49-53`, `:68-75`); phone
  row background (`TVL:704`); picker sheet and its rows (`UI/ListsScreen/MovePickerSheet.swift:47,69`, `TVL:843`); list
  screen ground (`TLM:532`, `TLP:153`) and fades (`TLM:538`, `TLP:166`); task row ground (`TLM:405`, `TLP:282`); drop
  mark's circle fill (`TLM:503`, `TLP:299`); block header behind the list-name field (`TLC:138`).
- `surface`: title field (`TVL:361`); phone drag card and sidebar indicator card (`TVL:791,818`); open card (`TLM:436`,
  `TLP:334`); lifted row copy (`TLM:479`); board card (`TLM:272`, `TLP:96`); card fields (`TLK:36,41,48`); expand
  button fill (`TLK:61`).
- `sidebar`: sidebar ground and its bar (`UI/ListsScreen/ListsSidebar.swift:34,56`); sidebar row background
  (`TVL:750`); sidebar drop-indicator circle fill (`TVL:815`).
- `fill`: phone highlighted row (`TVL:704`); picker top-level tile (`TVL:206`); Mac search field (`TVL:464`); Done strip
  (`TLM:229`, `TLP:51`); unlit chip (`TLM:573`, `TLP:227`); pills (`TLM:468`, `TLP:359`); board column (`TLM:271`,
  `TLP:95`) and column header (`TLC:149`); pane tag capsule (`TLP:245`).
- `line`: Mac bar's top rule and the edit bar's group divider (`TVL:96,118`); area line (`TVL:334`); phone guides at
  1.5 pt (`TVL:705`); block header rule (`TLM:213`, `TLP:35`); add-list rule (`TLM:242`, `TLP:63`); dashed add-list
  column (`TLM:329`, `TLP:137`); pane capsule divider (`TLP:157`).
- `guide`: sidebar guides (`TVL:751`).
- `ink`: list row titles (`TVL:247`), "Top level" (`TVL:202`), bar "…" (`TVL:430`), field text (`TVL:361`); list
  header title (`TLC:43`), open task title (`TLC:237`), unlit chip title (`TLC:67`), empty title (`TLC:324`), glass
  back/"…"/"+" (`TLC:337,350`, `TLX:54`), card title/subtask/field (`TLK:36,48,78`), set pills and tag pill names
  (`TLK:104,109,112`); sentence strip (`UI/ListsScreen/ListsTree.swift:379`).
- `ink2`: count, chevron, phone area label, hint, top-level glyph, search placeholder + magnifier + mic, phone drag
  card grip (`TVL:285,302,709,195,200,445-446,461,715,792`); header subtitle (`TLC:44`), block date and chevron
  (`TLC:134,174`), meta (`TLC:279`), done row title (`TLC:237`), leaving title (`TLM:351`), add rows (`TLX:23-24`),
  Done strip label and chevron (`TLX:73,77`), unlit chip hash (`TLC:64`), unset pills (`TLK:103-109`), tag pill hash
  (`TLK:112`), notes (`TLK:41`), done card/subtask title (`TLK:36,78`), expand glyph (`TLK:58`), empty text (`TLC:325`).
- `ink3`: grip (`TVL:545`); sidebar area caption (`TVL:755`); every strike-through (`TLM:287,309,351,389,403,438`;
  `TLP:111,280,340,345`).
- `red`: due meta (`TLC:295`), deadline pill (`TLK:107-109`), swipe button (`TLM:421`).
- `accent`: bar "+" and Done fills (`TVL:473,483,519`); edit-bar "List"/"Area" words and plus (`TVL:531-532`); title
  field ring 2 pt (`TVL:363`); picker check (`TVL:831`); phone drag slot stroke (`TVL:788`); sidebar drop line and ring
  (`TVL:813,815`); floating "+" (`TLM:543`).
- `onAccent`: bar glyphs (`TVL:472,482,518`), floating plus (`TLX:43`), swipe "Delete" **on red** (`TLX:93`).
- `accentSoft`: phone drag slot (`TVL:787`). `selection`: sidebar highlighted row (`TVL:750`). `glass`, `glassLine`:
  glass (`TLM:522`, `TLP:199`), board-card ring (`TLM:271`, `TLP:95`). `fresh`: `TLM:404`, `TLP:281`. `hover`:
  `TLP:173`. `placeholder`: `TVL:361`, `TLC:264`.
- List colours: tile background/glyph (`UI/DesignSystem/ListTile.swift:20,25`); block and column title and the list-name
  field (`TLC:164,173`); Done strip glyph (`TLX:71`); check ring/fill/mark (`UI/ListScreen/CheckButton.swift:51-59`);
  lit chip background, hash and title (`TLC:64,67`, `TLM:573`, `TLP:227`); drop tint and ring, drop mark (`TLM:274,
  490,501-503`; `TLP:98,297-305`).

### 1.5 System colours and materials used instead of tokens

- `.regularMaterial` under the Lists bar's controls on every OS (`UI/DesignSystem/Bar.swift:184-188`, via `:97,:159,:196`);
  under the list-screen glass on OS < 26 (`UI/ListScreen/GlassButton.swift:99-100`); the root's sentence strip
  (`UI/RootView.swift:240`).
- `glassEffect(.regular.interactive())` on iOS/macOS/watchOS 26+ for the list-screen glass buttons and the pane capsule
  (`GlassButton.swift:96-97`): system colours, not tokens. Toolbar items hide the system's shared glass on 26
  (`UI/ListScreen/ListPane.swift:256-258`).
- Bar glass edge is `Color(.ink).opacity(0.08)` (`Bar.swift:178`): in dark that is `#EEEAE3` @ 8 %, **not** `glassLine`
  (white @ 8 %), which the list-screen glass uses.
- Every shadow is `.black.opacity(x)` (`UI/DesignSystem/Shadow+DesignSystem.swift:9`), the same in both modes.
- `.secondary` for "Nothing to show" in the empty detail column, on the system background (`RootView.swift:101-102`).
- System primary text and system fonts: root sentence strip (`RootView.swift:236-241`), task screen (`.font(.title)`,
  `UI/TaskScreenView.swift:19-20`), Quick Entry (`UI/QuickEntryView.swift`), navigation titles
  (`MovePickerSheet.swift:49`, `UI/ListScreen/ListSurface.swift` `.navigationTitle`), alerts
  (`UI/ListsScreen/ListsDialogs.swift:28-37`), menus and their `Divider()` (`UI/DesignSystem/MenuItems.swift`).
- **System tint:** there is no asset catalog (no `.xcassets`, no `AccentColor`) and no `.tint(...)` anywhere. Sheet
  Cancel (`MovePickerSheet.swift:57`), alert buttons, menu checks, the toolbar's Quick Entry button (`RootView.swift:248`)
  and Quick Entry's Cancel/Add are the **system default blue, not `#3653C9`**. Destructive roles use system red
  (`MenuItems.swift:57`, `ListsDialogs.swift:31`).
- Tag bar mask gradients use `.black`/`.clear` as alpha only (`UI/ListScreen/TagBarView.swift:33-40`).

### 1.6 Per platform

- iOS/iPadOS: `UIColor` dynamic provider on `userInterfaceStyle` (`Color+DesignSystem.swift:24-27`); macOS: `NSColor`
  provider on `bestMatch([.darkAqua, .aqua])` (`:30-33`); watchOS: the dark shade only (`:16-20`).
- No per-platform colour values. Layouts differ only in which tokens they use: phone rows on paper with `fill` highlight;
  sidebar rows on `sidebar` with `selection`; Mac bar search on `fill`, phone/iPad search on glass; hover only in wide.
- OS-version split: glass is the token `glass` + material before 26, system Liquid Glass from 26.

### 1.7 What is absent

- **No high-contrast variant.** Nothing reads `colorSchemeContrast`/Increase Contrast; the canvas has no
  `prefers-contrast`. No Reduce Transparency handling (materials and glass stay). No Differentiate Without Colour (lit
  chip and due-red are colour-led; due also has words "Due …"/"Overdue …").
- Canvas variables with no counterpart in code (likely needed by later screens): `--press` (ink @ .08 / white @ .09),
  `--scrim` and `--scrim2` (phone: `rgba(34,28,20,.32)`/`.14`, dark black .5/.34; Mac .26/.2 and .45/.42), `--toast`
  `#1F1D1A`/`#EEEAE3` with `--toastink` `#FAF7F2`/`#1A1917`, `--badgeink`, keyboard colours `--kb`, `--key`, `--key2`,
  and the clear stops `--paper0`, `--side0`.

### 1.8 Code vs canvas (colour)

- `hover`: code ink @ 0.05 (Mac canvas); `Phone.dc.html --hover` is 0.045 (the phone draws no hover).
- Phone guides are `line` at 1.5 pt (`TVL:705`); `Phone.dc.html` has its own `--guide` `#E3DCD0`/`#38352F`
  (the Mac's `#E0D9CC`/`#36332E` is the code's `guide`).
- Bar glass edge in dark (above).
- Shadows: canvas uses warm `rgba(60,40,20,…)` in light and much heavier black in dark (§5); code is black and
  mode-independent.

---

## 2. Foreground/background pairs actually drawn (WCAG matrix)

Method: WCAG 2.x relative luminance. Translucent layers are composited in sRGB over what lies under them (paper unless
the background says `a/b`, read "a over b"). Thresholds used: **4.5** for text; **3.0** for large text (only the list
header's `largeTitle`, 34 pt heavy, and the empty title, 20 pt heavy, on iOS; on the Mac the same roles are 26 and
15 pt) and for non-text UI that carries meaning (glyphs, check ring/fill, focus ring). Material backgrounds
(`.regularMaterial`) are approximated by their backdrop (paper or sidebar); on device they are lighter/blurred.
"Where" uses the short references above. 61 plain pairs + 15 list-colour pair groups (× 11 colours × 2 modes).

### 2.1 Pairs with fixed tokens

| ID | Foreground | Background (top/under) | Need | Light | Dark | Used for | Where |
|---|---|---|---|---|---|---|---|
| L1 | `ink` | `paper` | 4.5 | 15.73<br>`#1F1D1A` on `#FAF7F2` | 14.65<br>`#EEEAE3` on `#1A1917` | list row title (rowTitle/nestedRowTitle ±semibold); picker 'Top level' and option titles; picker sheet rows | TVL:247,202; TVL:843 (picker bg paper) |
| L2 | `ink` | `fill` | 4.5 | 14.17<br>`#1F1D1A` on `#F0EBE3` | 11.75<br>`#EEEAE3` on `#2E2B27` | phone list row title, highlighted row (highlight .fill) | TVL:247,704 |
| L3 | `ink` | `sidebar` | 4.5 | 14.43<br>`#1F1D1A` on `#F2EDE5` | 13.90<br>`#EEEAE3` on `#1F1E1B` | sidebar list row title | TVL:247,750 |
| L4 | `ink` | `selection` | 4.5 | 11.82<br>`#1F1D1A` on `#D8D7E1` | 10.03<br>`#EEEAE3` on `#323645` | sidebar highlighted row title (semibold) | TVL:234,247,750 |
| L5 | `ink2` | `paper` | 4.5 | 6.19<br>`#625C53` on `#FAF7F2` | 7.11<br>`#ABA498` on `#1A1917` | phone row count (.count); phone area label (.areaLabel); picker hint (.hint) | TVL:285,709,195 |
| L6 | `ink2` | `fill` | 4.5 | 5.57<br>`#625C53` on `#F0EBE3` | 5.70<br>`#ABA498` on `#2E2B27` | phone count on highlighted row; Mac bar search placeholder + magnifier on .fill | TVL:285; TVL:459-466 |
| L7 | `ink2` | `sidebar` | 4.5 | 5.68<br>`#625C53` on `#F2EDE5` | 6.74<br>`#ABA498` on `#1F1E1B` | sidebar row count; sidebar chevron (12pt glyph) | TVL:285,302 |
| L8 | `ink2` | `selection` | 4.5 | 4.65<br>`#625C53` on `#D8D7E1` | 4.86<br>`#ABA498` on `#323645` | sidebar count / chevron on highlighted row | TVL:285,302,750 |
| L9 | `ink3` | `sidebar` | 4.5 | 2.34 **✗**<br>`#A39C90` on `#F2EDE5` | 3.11 **✗**<br>`#6F6A62` on `#1F1E1B` | sidebar area caption (UPPERCASE .areaCaption, Mac 10pt) | TVL:755 |
| L10 | `ink3` | `paper` | 4.5 | 2.55 **✗**<br>`#A39C90` on `#FAF7F2` | 3.27 **✗**<br>`#6F6A62` on `#1A1917` | area caption in Move-to picker at wide width (picker rows on paper) | TVL:755,843 |
| L11 | `ink3` | `paper` | 3 | 2.55 **✗**<br>`#A39C90` on `#FAF7F2` | 3.27<br>`#6F6A62` on `#1A1917` | grip glyph 18pt, phone edit mode (row end / area line end) | TVL:545,711 |
| L12 | `ink3` | `fill` | 3 | 2.29 **✗**<br>`#A39C90` on `#F0EBE3` | 2.62 **✗**<br>`#6F6A62` on `#2E2B27` | grip on phone highlighted row | TVL:545 |
| L13 | `ink3` | `sidebar` | 3 | 2.34 **✗**<br>`#A39C90` on `#F2EDE5` | 3.11<br>`#6F6A62` on `#1F1E1B` | grip on iPad sidebar rows (edit mode) | TVL:545,757 |
| L14 | `ink3` | `selection` | 3 | 1.91 **✗**<br>`#A39C90` on `#D8D7E1` | 2.24 **✗**<br>`#6F6A62` on `#323645` | grip on iPad highlighted row | TVL:545 |
| L15 | `ink2` | `paper` | 3 | 6.19<br>`#625C53` on `#FAF7F2` | 7.11<br>`#ABA498` on `#1A1917` | phone Lists-row chevron 13 pt semibold (glyph) | TVL:302,706 |
| L16 | `ink` | `surface` | 4.5 | 16.81<br>`#1F1D1A` on `#FFFFFF` | 13.23<br>`#EEEAE3` on `#24221F` | title field text (rename) on .surface; drag card titles (phone card, sidebar indicator card) | TVL:361; TVL:790-795,818-820 |
| L17 | `placeholder` | `surface` | 4.5 | 4.11 **✗**<br>`#817D75` on `#FFFFFF` | 4.63<br>`#908A80` on `#24221F` | title field placeholder 'Title'/'Area name' (ink2@80%) | TVL:249,322,361 |
| L18 | `accent` | `paper` | 3 | 6.07<br>`#3653C9` on `#FAF7F2` | 2.71 **✗**<br>`#3653C9` on `#1A1917` | title field ring 2pt (focus) around field, on phone paper | TVL:363 |
| L19 | `accent` | `fill` | 3 | 5.47<br>`#3653C9` on `#F0EBE3` | 2.17 **✗**<br>`#3653C9` on `#2E2B27` | title field ring on highlighted phone row | TVL:363 |
| L20 | `accent` | `sidebar` | 3 | 5.57<br>`#3653C9` on `#F2EDE5` | 2.57 **✗**<br>`#3653C9` on `#1F1E1B` | title field ring on sidebar | TVL:363 |
| L21 | `accent` | `selection` | 3 | 4.56<br>`#3653C9` on `#D8D7E1` | 1.85 **✗**<br>`#3653C9` on `#323645` | title field ring on sidebar highlighted row | TVL:363 |
| L22 | `ink2` | `surface` | 3 | 6.61<br>`#625C53` on `#FFFFFF` | 6.42<br>`#ABA498` on `#24221F` | grip on phone drag card (ink2 18pt) | TVL:792 |
| L23 | `ink2` | `surface` | 4.5 | 6.61<br>`#625C53` on `#FFFFFF` | 6.42<br>`#ABA498` on `#24221F` | phone area label on line drag card (.areaLabel) | TVL:709; ListsDragGesture.swift:392-397 |
| L24 | `ink3` | `surface` | 4.5 | 2.72 **✗**<br>`#A39C90` on `#FFFFFF` | 2.96 **✗**<br>`#6F6A62` on `#24221F` | sidebar area caption on line drag card | TVL:755; ListsDragGesture.swift:295,325 |
| L25 | `onAccent` | `accent` | 3 | 6.49<br>`#FFFFFF` on `#3653C9` | 6.49<br>`#FFFFFF` on `#3653C9` | bar '+' (20 semibold / Mac 16 bold), Done check (20 bold) — glyphs on accent circle | TVL:472,482,518 |
| L26 | `accent` | `paper` | 4.5 | 6.07<br>`#3653C9` on `#FAF7F2` | 2.71 **✗**<br>`#3653C9` on `#1A1917` | edit-bar group 'List'/'Area' (.barLabel) + plus 15pt in accent, on glass (regularMaterial over paper; approximated as paper) | TVL:531-532; Bar.swift:159,185 |
| L27 | `accent` | `sidebar` | 4.5 | 5.57<br>`#3653C9` on `#F2EDE5` | 2.57 **✗**<br>`#3653C9` on `#1F1E1B` | same on iPad sidebar (material over sidebar; approximated as sidebar) | TVL:531-532 |
| L28 | `ink` | `paper` | 3 | 15.73<br>`#1F1D1A` on `#FAF7F2` | 14.65<br>`#EEEAE3` on `#1A1917` | bar '…' glyph 20 semibold on glass (material over paper ≈ paper) | TVL:430 |
| L29 | `ink2` | `paper` | 4.5 | 6.19<br>`#625C53` on `#FAF7F2` | 7.11<br>`#ABA498` on `#1A1917` | search capsule 'Search' (.search) + magnifier/mic 17pt on glass (material over paper ≈ paper) | TVL:445-446,715 |
| L30 | `ink2` | `sidebar` | 4.5 | 5.68<br>`#625C53` on `#F2EDE5` | 6.74<br>`#ABA498` on `#1F1E1B` | iPad search capsule on glass over sidebar (≈ sidebar) | TVL:445 |
| L31 | `accent` | `paper` | 3 | 6.07<br>`#3653C9` on `#FAF7F2` | 2.71 **✗**<br>`#3653C9` on `#1A1917` | picker check glyph 15pt bold (accent) on paper | TVL:831 |
| L32 | `ink2` | `fill` | 3 | 5.57<br>`#625C53` on `#F0EBE3` | 5.70<br>`#ABA498` on `#2E2B27` | picker 'Top level' divider glyph (15/11pt) on .fill tile | TVL:200,206 |
| L33 | `ink` | `paper` | 4.5 | 15.73<br>`#1F1D1A` on `#FAF7F2` | 14.65<br>`#EEEAE3` on `#1A1917` | sentence ('problem') strip, default font, Lists phone / list screen | ListsTree.swift:378-383; ListsScreen.swift:43; ListSurface.swift:282 |
| L34 | `ink` | `sidebar` | 4.5 | 14.43<br>`#1F1D1A` on `#F2EDE5` | 13.90<br>`#EEEAE3` on `#1F1E1B` | sentence strip on sidebar | ListsSidebar.swift:52 |
| S1 | `ink` | `paper` | 3 | 15.73<br>`#1F1D1A` on `#FAF7F2` | 14.65<br>`#EEEAE3` on `#1A1917` | list screen header title (.largeTitle heavy rounded, 34pt iOS / 26pt Mac) — large text | TLC:43 |
| S2 | `ink2` | `paper` | 4.5 | 6.19<br>`#625C53` on `#FAF7F2` | 7.11<br>`#ABA498` on `#1A1917` | header subtitle (.count); block date (.areaLabel); meta text+glyphs (.meta, 13/12pt); add rows 'Add task'/'Add list' + plus; empty-state text (.notes); done task title (rowTitle) | TLC:44,174,286; TLX:23-24; TLC:325; TLC:237 |
| S3 | `ink` | `paper` | 4.5 | 15.73<br>`#1F1D1A` on `#FAF7F2` | 14.65<br>`#EEEAE3` on `#1A1917` | open task row title (rowTitle: 17 pt phone, 13 pt Mac) | TLC:237 |
| S4 | `ink` | `paper` | 3 | 15.73<br>`#1F1D1A` on `#FAF7F2` | 14.65<br>`#EEEAE3` on `#1A1917` | empty-state title (.emptyScreenTitle 20 pt heavy rounded, large on iOS; 15 pt on Mac needs 4.5 — passes either way) | TLC:324 |
| S5 | `red` | `paper` | 4.5 | 5.10<br>`#C2362B` on `#FAF7F2` | 6.19<br>`#F07468` on `#1A1917` | due deadline meta text + flag (.meta) | TLC:295-296 |
| S6 | `red` | `surface` | 4.5 | 5.45<br>`#C2362B` on `#FFFFFF` | 5.59<br>`#F07468` on `#24221F` | due deadline on board card / lifted copy (surface) | TLC:295; RowDrag.swift:75 |
| S7 | `red` | `fill` | 4.5 | 4.59<br>`#C2362B` on `#F0EBE3` | 4.97<br>`#F07468` on `#2E2B27` | deadline pill text when due + flag (pill on .fill) | TLK:107-109 |
| S8 | `ink` | `fill` | 4.5 | 14.17<br>`#1F1D1A` on `#F0EBE3` | 11.75<br>`#EEEAE3` on `#2E2B27` | unlit tag chip title (.pill); set When/Deadline pill text; tag pill names (.areaLabel) | TLC:67; TLK:104,109,112 |
| S9 | `ink2` | `fill` | 4.5 | 5.57<br>`#625C53` on `#F0EBE3` | 5.70<br>`#ABA498` on `#2E2B27` | unlit chip hash (13/12pt, glyph); unset pill text 'When'/'Deadline' + glyphs; Done strip label (.barLabel) + chevron; column subtitle; column 'Add task'; pane tag capsule text (.meta) | TLC:64; TLK:103-109; TLX:73-77; TLC:149,174; TLP:244 |
| S10 | `ink` | `surface` | 4.5 | 16.81<br>`#1F1D1A` on `#FFFFFF` | 13.23<br>`#EEEAE3` on `#24221F` | open card title field (rowTitleEmphasized); subtask title (.notes); subtask field; board card title (nestedRowTitle); lifted row copy | TLK:35,48,78; TLM:298; RowDrag.swift:75 |
| S11 | `ink2` | `surface` | 4.5 | 6.61<br>`#625C53` on `#FFFFFF` | 6.42<br>`#ABA498` on `#24221F` | card notes text; done card title; done subtask title; 'Add subtask' + plus; expand glyph (19/16pt); board card meta | TLK:41,36,78,53,58 |
| S12 | `placeholder` | `surface` | 4.5 | 4.11 **✗**<br>`#817D75` on `#FFFFFF` | 4.63<br>`#908A80` on `#24221F` | card placeholders 'New task', 'Notes', 'Subtask' | TLK:35,41,48; TLC:264 |
| S13 | `ink` | `paper` | 3 | 15.73<br>`#1F1D1A` on `#FAF7F2` | 14.65<br>`#EEEAE3` on `#1A1917` | glass back chevron 24pt / '…' 22pt (pre-26 glass ≈ glass over paper → see S14); Mac capsule '+' 17 / '…' 18 | TLC:337,350; TLX:54 |
| S14 | `ink` | `glass/paper` | 3 | 16.51<br>`#1F1D1A` on `#FEFDFB` | 12.11<br>`#EEEAE3` on `#2B2925` | glass buttons glyphs on canvas glass (white72% / #322F2B 72% over paper; material ignored) | TLM:510-523; GlassButton.swift:99-100 |
| S15 | `onAccent` | `accent` | 3 | 6.49<br>`#FFFFFF` on `#3653C9` | 6.49<br>`#FFFFFF` on `#3653C9` | floating '+' 22pt medium on accent | TLX:43; TLM:543 |
| S16 | `onAccent` | `red` | 4.5 | 5.45<br>`#FFFFFF` on `#C2362B` | 2.84 **✗**<br>`#FFFFFF` on `#F07468` | swipe 'Delete' (.barLabel, white) on red | TLX:93; TLM:421 |
| S17 | `ink2` | `paper` | 3 | 6.19<br>`#625C53` on `#FAF7F2` | 7.11<br>`#ABA498` on `#1A1917` | block header chevron 18/15pt; add-row plus 18/15pt (glyphs) | TLC:134; TLX:23 |
| S18 | `ink` | `hover/paper` | 4.5 | 14.28<br>`#1F1D1A` on `#EFECE7` | 12.85<br>`#EEEAE3` on `#252423` | pane row title under pointer (hover tint over paper) | TLP:283; TaskRowView.swift:36 |
| S19 | `ink2` | `hover/paper` | 4.5 | 5.62<br>`#625C53` on `#EFECE7` | 6.23<br>`#ABA498` on `#252423` | pane add-task / block header date under pointer | TLP:44,37 |
| S20 | `ink2` | `hover/fill` | 4.5 | 5.07<br>`#625C53` on `#E6E1D9` | 4.89<br>`#ABA498` on `#383632` | pane Done-strip label / unlit chip hash / column add-task under pointer | TLP:55,227,129 |
| S21 | `ink` | `hover/fill` | 4.5 | 12.88<br>`#1F1D1A` on `#E6E1D9` | 10.08<br>`#EEEAE3` on `#383632` | pane unlit chip title under pointer | TLP:227 |
| S22 | `ink2` | `hover/surface` | 3 | 6.00<br>`#625C53` on `#F4F4F4` | 5.55<br>`#ABA498` on `#2F2D2A` | pane expand glyph / add-subtask under pointer | TLP:340,352 |
| S23 | `ink` | `fresh/paper` | 4.5 | 13.21<br>`#1F1D1A` on `#E2E3ED` | 11.73<br>`#EEEAE3` on `#2C2B2A` | title of a row just dropped (fresh tint fading over 1.6 s) | TLM:404; TLP:281; TaskLanding.swift:24-27 |
| S24 | `ink2` | `fresh/paper` | 4.5 | 5.20<br>`#625C53` on `#E2E3ED` | 5.69<br>`#ABA498` on `#2C2B2A` | meta of a row just dropped | TLM:404 |
| S25 | `red` | `fresh/paper` | 4.5 | 4.28 **✗**<br>`#C2362B` on `#E2E3ED` | 4.96<br>`#F07468` on `#2C2B2A` | due meta on a row just dropped | TLM:404 |
| S26 | `ink` | `hover/glass/paper` | 3 | 14.97<br>`#1F1D1A` on `#F2F2F0` | 10.41<br>`#EEEAE3` on `#363430` | pane capsule item glyph under pointer | TLP:192-194 |
| S27 | `ink3` | `paper` | 3 | 2.55 **✗**<br>`#A39C90` on `#FAF7F2` | 3.27<br>`#6F6A62` on `#1A1917` | strike line through done titles (ink3 over ink2 text) — line vs paper | TLM:403; TLC:237 |

### 2.2 Pairs that depend on the list colour (each × 11 colours)

| ID | Foreground | Background | Need | Light: min / max / below need | Dark: min / max / below need | Used for | Where |
|---|---|---|---|---|---|---|---|
| T1 | `tile.glyph` | `tile.bg/paper` | 3 | 3.02 (amber) / 5.42 (indigo) / none | 4.57 (indigo) / 5.99 (amber) / none | tile glyph on tile bg over paper (phone rows, list header, empty state, picker) | ListTile.swift:19-25; TVL:233; TLC:36-41,317-322 |
| T2 | `tile.glyph` | `tile.bg/fill` | 3 | 2.75 (amber) / 4.93 (indigo) / **amber 2.75** | 3.75 (indigo) / 4.83 (amber) / none | tile on phone highlighted row (fill) | TVL:704 |
| T3 | `tile.glyph` | `tile.bg/sidebar` | 3 | 2.79 (amber) / 5.01 (indigo) / **amber 2.79** | 4.34 (indigo) / 5.66 (amber) / none | tile on sidebar row | TVL:750 |
| T4 | `tile.glyph` | `tile.bg/selection` | 3 | 2.34 (amber) / 4.18 (indigo) / **amber 2.34, orange 3.00** | 3.27 (indigo) / 4.30 (amber) / none | tile on sidebar highlighted row | TVL:750 |
| T5 | `tile.glyph` | `tile.bg/surface` | 3 | 3.20 (amber) / 5.77 (indigo) / none | 4.15 (indigo) / 5.39 (amber) / none | tile on drag cards (surface) | ListsDragGesture.swift:307,377 |
| T6 | `tile.glyph` | `paper` | 4.5 | 3.42 (amber) / 6.66 (indigo) / **amber 3.42** | 5.65 (indigo) / 9.08 (amber) / none | block header title (.sectionTitle heavy rounded 17/13pt) in list colour on paper; block name field text | TLC:173,164 |
| T7 | `tile.glyph` | `fill` | 4.5 | 3.08 (amber) / 6.00 (indigo) / **amber 3.08, green 4.36, stone 4.18, orange 4.14** | 4.53 (indigo) / 7.28 (amber) / none | column header title (.sectionTitle) on column fill | TLC:149,173 |
| T8 | `tile.glyph` | `tile.drop/paper` | 4.5 | 3.15 (amber) / 5.82 (indigo) / **amber 3.15, green 4.33, stone 4.19, orange 4.11, sky 4.48** | 4.76 (indigo) / 6.49 (amber) / none | column header title while column is drop-tinted (fill replaced by dropTint over paper) | ColumnView.swift:52-56 |
| T9 | `tile.glyph` | `fill` | 3 | 3.08 (amber) / 6.00 (indigo) / none | 4.53 (indigo) / 7.28 (amber) / none | Done strip check-circle glyph 18/16pt (list glyph colour) on fill | TLX:69-72 |
| T10 | `tile.mark` | `tile.fill` | 4.5 | 3.63 (orange) / 6.44 (amber) / **rose 4.43, green 3.87, stone 3.71, teal 4.24, pink 4.38, orange 3.63, sky 4.03** | 3.26 (stone) / 6.98 (amber) / **blue 4.26, rose 3.96, green 3.42, stone 3.26, teal 3.73, pink 3.88, orange 3.27, violet 4.48, sky 3.56** | LIT tag chip title (.pill 13pt semibold) + hash in mark colour on check fill | TLC:64,67,573 |
| T11 | `tile.mark` | `tile.fill` | 3 | 3.63 (orange) / 6.44 (amber) / none | 3.26 (stone) / 6.98 (amber) / none | check mark (tick) on checked check fill | CheckButton.swift:56-66 |
| T12 | `tile.ring` | `paper` | 3 | 3.42 (amber) / 6.66 (indigo) / none | 4.48 (indigo) / 8.06 (amber) / none | open check ring (1.75/1.5pt) on paper (row ground) | CheckButton.swift:52-53; TLM:403 |
| T13 | `tile.ring` | `surface` | 3 | 3.66 (amber) / 7.12 (indigo) / none | 4.04 (indigo) / 7.28 (amber) / none | open check ring on surface (card, board card, subtask) | TLK:31,75 |
| T14 | `tile.fill` | `paper` | 3 | 2.44 (amber) / 5.26 (indigo) / **amber 2.44** | 3.67 (indigo) / 7.29 (amber) / none | checked check disc / drop-mark line+ring / block-drop ring on paper | CheckButton.swift:50-53; TLM:499-505,488-493 |
| T15 | `tile.fill` | `fill` | 3 | 2.20 (amber) / 4.74 (indigo) / **amber 2.20** | 2.94 (indigo) / 5.84 (amber) / **indigo 2.94** | lit chip (check fill) vs unlit chip bg (fill) — state change | TLM:573 |

### 2.3 Below threshold (summary)

1. **`ink3` as text**: sidebar area caption 2.34 light / 3.11 dark (L9), the same caption in the wide Move-to picker on
   paper 2.55/3.27 (L10), on the drag card 2.72/2.96 (L24).
2. **`ink3` grip glyph** (3:1): 2.55 light on paper; 2.29 fill, 2.34 sidebar, 1.91 selection; dark fails on fill (2.62)
   and selection (2.24) (L11-L14).
3. **Accent as foreground in dark** (the accent does not change with the mode): accent on paper 2.71, on sidebar 2.57,
   on fill 2.17, on selection 1.85 — the edit bar's "List"/"Area" words (L26/L27), the title-field focus ring
   (L18-L21), the picker check (L31).
4. **Lit tag chip text** (`mark` on `check.fill`, 13 pt semibold): below 4.5 for 7 colours in light (orange 3.63 …
   rose 4.43) and 9 in dark (stone 3.26 … violet 4.48) (T10). The mark rule was built for the tick at 3:1; the chip
   reuses it for text.
5. **Swipe "Delete"**: white on dark red `#F07468` = 2.84 (S16).
6. **Placeholders** on surface, light: 4.11 (L17, S12).
7. **Block/column title in the list colour** (`sectionTitle`, 17 pt heavy on iOS — under WCAG's 18.66 px bold "large";
   13 pt on Mac): amber on paper 3.42 (T6); on column fill amber 3.08, green 4.36, stone 4.18, orange 4.14 (T7);
   drop-tinted column adds sky 4.48 (T8).
8. **Tile glyph on tile** (3:1): amber on fill 2.75, on sidebar 2.79, on selection 2.34; orange on selection 3.00
   (T2-T4).
9. **Checked disc vs paper**: amber 2.44 light (T14). Lit vs unlit chip: amber 2.20 light, indigo 2.94 dark (T15).
10. Due red on the fading `fresh` tint: 4.28 light (S25), transient.
11. Strike-through `ink3` on paper 2.55 light (S27) — decorative; the done state is also the check and `ink2`.

Tight passes: `ink2` on `selection` 4.65/4.86 (L8), `ink2` on hover-over-fill 5.07/4.89 (S20), `red` on `fill` 4.59
light (S7).

### 2.4 State and decorative contrasts (no WCAG minimum unless they are the only cue)

| Pair | Light | Dark | Note |
|---|---|---|---|
| `selection` vs `sidebar` | 1.22 | 1.39 | sidebar highlight (title also turns semibold, `TVL:234`) |
| `fill` vs `paper` | 1.11 | 1.25 | phone highlight, chips, pills, columns |
| `line` vs `paper` / vs `sidebar` | 1.21 / 1.11 | 1.38 / 1.31 | rules, phone guides, dashed add-list edge (its only outline) |
| `guide` vs `sidebar` / vs `selection` | 1.20 / 1.01 | 1.33 / 1.05 | guides vanish under the highlighted row |
| `accentSoft` vs `paper`; accent stroke vs `accentSoft` | 1.12; 5.42 | 1.20; 2.26 | phone drag slot |
| `surface` vs `paper` / vs `fill` | 1.07 / 1.19 | 1.11 / 1.13 | open card relies on its shadow; board cards on columns |
| `glassLine` vs `fill` | 1.17 | 1.28 | 0.5 pt board-card ring |
| `hover` / `fresh` over paper vs paper | 1.10 / 1.19 | 1.14 / 1.25 | |
| tile bg over paper vs paper | 1.13–1.23 | 1.24–1.52 | |
| `dropTint` over paper vs paper | 1.09–1.15 | 1.19–1.40 | drop target |

### 2.5 Pairs not computable here (system or material)

`ink`/`ink2`/`accent` on `.regularMaterial` (Lists bar on every OS, and the list-screen glass before 26); glyphs on
system Liquid Glass (26+); `.secondary` on the system detail background (`RootView.swift:102`); system text on
`.regularMaterial` (`RootView.swift:236-241`); navigation titles, alert, menu, sheet and Quick Entry chrome. They need
on-device measurement (screenshot sampling) in both modes.

---

## 3. Typography

Seventeen roles (`DS/Font.swift:21-69`). Each is a **text style + weight + rounded flag**; no explicit point size, no
tracking, no line spacing. Rendered as `Font.system(<TextStyle>, design: rounded ? .rounded : .default, weight:)`
(`UI/DesignSystem/Font+DesignSystem.swift:8-10`), so every text follows Dynamic Type. The Mac is smaller only because
macOS text styles are smaller (`TLP:9-10`: "a font of the look is a text style, which the Mac draws smaller by itself").
Sizes below are Apple's defaults (iOS at the default "Large" setting; macOS fixed).

| Role | Text style | Weight | Rounded | iOS pt | macOS pt | Canvas px (phone / Mac) | Used for |
|---|---|---|---|---|---|---|---|
| `largeTitle` | largeTitle | heavy | yes | 34 | 26 | 32, line-height 1.1, −0.01em / 30, −0.01em | list screen header title (`TLC:43`) |
| `sectionTitle` | headline | heavy | yes | 17 | 13 | 17 heavy | block and column title, list-name field (`TLC:164,173`) |
| `meta` | caption | medium | no | 12 | 10 | 12.5 medium | task meta line text (`TLC:286`) |
| `count` | subheadline | regular | no | 15 | 11 | 15 regular | Lists row count (`TVL:285`), list header subtitle (`TLC:44`) |
| `areaLabel` | footnote | medium | no | 13 | 10 | 13 medium | phone area label and its field (`TVL:709,712`), block date (`TLC:174`), card tag-pill names (`TLK:112`) |
| `areaCaption` | caption | heavy | yes | 12 | 10 | — / 10.5 800 `ui-rounded`, +0.07em, uppercase | sidebar area caption (`TVL:755`) |
| `rowTitle` | body | regular | no | 17 | 13 | 17 / 13.5 and 13 | Lists rows (phone root depth; sidebar every depth) (`TVL:697,744,747`), "Top level" (`TVL:202`), list-screen row title (`TLM:408`, `TLP:287`), sidebar drag card (`TVL:820`, canvas 13 px 500) |
| `rowTitleEmphasized` | body | semibold | no | 17 | 13 | 17 600 | Lists row with children, sidebar highlighted row (`TVL:234-235`); open card title field (`TLK:35`) |
| `nestedRowTitle` | callout | regular | no | 16 | 12 | 16 | phone nested Lists rows (`TVL:700`); board card title (`TLM:298`, `TLP:117`) |
| `nestedRowTitleEmphasized` | callout | semibold | no | 16 | 12 | 16 600 / 12.5 600 | phone nested row with children (`TVL:701`); sidebar area field (`TVL:759`) |
| `barLabel` | subheadline | semibold | no | 15 | 11 | 15 600 | edit-bar words (`TVL:532`), "Add list" (`TLM:245,332`, `TLP:66,140`), Done strip label (`TLX:73`), swipe Delete (`TLX:93`) |
| `hint` | footnote | regular | no | 13 | 10 | 13 | Move-to hint (`TVL:195`) |
| `search` | body | regular | no | 17 | 13 | 17 / 13.5 | search placeholder, both bars (`TVL:445,460`) |
| `addRow` | subheadline | medium | no | 15 | 11 | 15 500 | "Add task" (`TLM:224,322`, `TLP:46,131`) |
| `notes` | subheadline | regular | no | 15 | 11 | 15, line-height 1.45 | notes, subtask title/field, "Add subtask", empty-state text (`TLK:41,48,78`, `TLM:461`, `TLP:354`, `TLC:325`) |
| `pill` | footnote | semibold | no | 13 | 10 | 13.5 600 | tag chips (`TLC:67`), When/Deadline pills (`TLK:92`) |
| `emptyScreenTitle` | title3 | heavy | yes | 20 | 15 | 20 800 `ui-rounded` | empty-state title (`TLC:324`) |

- Canvas sizes come from the code comments (`Font.swift:7-69`, `TVL:735-736,807-808`, `TLM:429-430`) and
  `docs/plans/lists-screen.md:162`; the Mac large title 30 px and tracking are from the local `Mac.dc.html`/`Phone.dc.html`.
- At iPhone default size every role equals the canvas except **large title 34 vs 32, meta 12 vs 12.5 (owner's choice on
  #151, `Font.swift:8-9`, `docs/plans/lists-screen.md:42`) and pill 13 vs 13.5**.
- Mac result vs Mac canvas: large title 26 vs 30, row title 13 vs 13.5/13, search 13 vs 13.5, area field 12 vs 12.5,
  area caption 10 vs 10.5.
- Weights in use: regular, medium, semibold, heavy for text; **bold only on glyphs** (Mac "+", Done, picker check).
  Rounded: four roles (largeTitle, sectionTitle, areaCaption, emptyScreenTitle). Faces: SF Pro and SF Pro Rounded via
  `.system`; no bundled font. The canvas declares `-apple-system, BlinkMacSystemFont, 'SF Pro Text', Inter` and
  `ui-rounded` (the canvas page loads Inter and Nunito as web fallbacks).
- **Tracking**: none in code. Canvas: −0.01em on large titles (phone 32 and 24 px day title; Mac 30 and 25 px), +0.07em
  on uppercase area captions (Mac 10.5 px; phone canvas 12.5 px).
- **Line spacing**: none in code. Canvas: 1.1 (large title), 1.2 (day title), 1.45 (notes, from which the 22/20 pt notes
  height comes).
- **Monospaced digits**: none; counts, "2/4", "Done today · N" are proportional. The canvas has no `tabular-nums`.
- **Capitalisation**: the sidebar caption is uppercased in the model string (`TVL:320`, flag `TVL:755`), not by the font.
  The phone area label is sentence case in `areaLabel` 13 pt medium (`TVL:709`); the local `Phone.dc.html` (list-screen
  snapshot) draws area text uppercase 12.5 px 800 +0.07em — a canvas/code difference to confirm against the live canvas.
- **Dynamic Type**: text scales; glyph sizes do not (fixed points, `UI/DesignSystem/Icon.swift:5-7`, `ListTile.swift:24`);
  many containers have fixed heights (`UI/DesignSystem/ListRowView.swift:42`, `AreaLine.swift:56`, `Bar.swift:37`,
  `TagBarView.swift:57`, `UI/ListScreen/TaskCardView.swift:167`, `DoneStripView.swift:51`, `BlockHeaderView.swift:31`),
  so large sizes clip; task rows use a minimum height (`TaskRowView.swift:35`).
- Outside the tokens: task screen `.title` (`TaskScreenView.swift:20`), sentences in default body, Quick Entry, menus,
  alerts and navigation titles in system fonts.
- watchOS: text styles render at watch sizes; nothing designed or measured.

---

## 4. Spacing, sizes, radii

All in points. Phone column = `TVL` `phone` / `TLM` `phone`; wide column = `TVL` `sidebar` / `TLP` `pane`. "—" = not
present. View-level container values are at the end of each block.

### 4.1 Lists screen (phone) and sidebar (Mac, iPad) — `TVL`

| Kind | Value | Phone | Wide | Ref |
|---|---|---|---|---|
| indent | tile leading start / step | 20 / 22 | 18 / 16 (from the column edge: content inset 10 + canvas 8) | `:765,769` |
| row height | list row; "Top level" | 46 | 30 | `:695,742` |
| tile size | root tile side / radius / glyph | 30 / 8 / 19 | 22 / 6 / 14 | `:697,744` |
| tile size | nested tile side / radius / glyph | 26 / 7 / 16 | 18 / 5 / 12 | `:700,747` |
| gap | tile → title | 12 | 8 | `:703,749` |
| width | title minimum (row need) | 140 | 90 | `:703,749` |
| field | row field height / padding / radius | 34 / 10 / 10 | 24 / 6 / 6 | `:704,750` |
| padding | row background inset / radius | 0 / 0 | 10 / 7 | `:705,751` |
| line width | guide | 1.5 (`line`) | 1 (`guide`) | `:705,751` |
| width | end fade | 10 | 8 | `:706,752` |
| cell | count cell min / glyph cell min | 20 / 36 | 18 / 20 | `:706,752` |
| width | accessories in need | 72 | 70 | `:706,752` |
| gap | row end gap | 4 | 4 | `:292` |
| icon size | chevron (semibold) / grip | 13 / 18 | 12 / 18 | `:706,752,540` |
| row height | area line alone / with label / with field | 17 / 36 / 36 | 15 / 15 / 28 | `:708,754` |
| padding | area label leading / field leading | 20 / 20 | 18 / 16 | `:708,754` |
| gap | label → line | 10 | 6 | `:708,754` |
| gap | line → end; edit: line → grip, cell min, end gap | 20; 10, 0, 12 | 18; 8, 20, 14 | `:710-711,756-757` |
| field | area field width / height / padding / radius | 160 / 28 / 8 / 8 | 160 / 22 / 6 / 6 | `:712,758` |
| line width | area line; title-field ring | 1; 2 | 1; 2 | `:334,363` |
| gap | picker hint → rows | 8 | 8 | `:213` |
| row height | picker option minimum | 36 | 30 | `:717,761` |
| icon size | "Top level" divider glyph | 15 | 11 | `:717,761` |
| picker | check 15 bold; cell min 0; end gap 20; line → check 20; check in need 18 | same | same | `:831-865` |

Bar (`TVL:87-121`; `UI/DesignSystem/Bar.swift`):

| Value | Phone and iPad (edit mode) | Mac (no edit mode) |
|---|---|---|
| bar height | 48 | 48 |
| top rule | none | 1 (`line`) |
| control height (circle diameter) | 48 | 30 |
| gap between controls / side padding | 10 / 16 | 8 / 10 |
| group button height / glyph→word / group padding / divider | 40 / 6 / 4 / 1 × 22 | (shared, never drawn) |
| "…" / "+" / Done glyph | 20 semibold / 20 semibold / 20 bold | — / 16 bold / — |
| group plus | 15 semibold | — |
| search: gap / leading / trailing / radius | 8 / 15 / 6 / 24 (half of 48) | 6 / 9 / 4 / 8 |
| magnifier / trailing glyph | 17 / mic 17 in a 36 cell (phone only; iPad none, `TVL:736-738`) | 15 / none |

Drag (`TVL:783-823`):

- Phone slot: 52 high, 44 drawn (vertical inset 4), starts 6 before the tile, ends 12 short of the edge, radius 13, stroke
  1.5 accent dashed 5/4, fill `accentSoft`. Card: raised 6 above, scale 1.03, rotation −1.5°, `lifted` shadow on
  surface; list card 50 high, inset 2, padding 12, grip 18 in a 40 cell, trailing gap 6, radius 14; line card 36 high,
  inset 8, trailing 8, radius 12; minimum width 120.
- Sidebar indicator: 12 gap, line 2 (end radius 1) from +2 after the tile to 18 short, circle 10 ringed 2 at −6, filled
  `sidebar`. Card 170 × 30, offset 14, radius 7, rotation −1.2°, opacity 0.95, padding 10, tile 18/5/12, tile → title 8.

View containers: Lists phone bottom fade 52 (paper, solid from 72 %) and top inset 4 (paper solid to 55 %)
(`UI/ListsScreen/ListsScreen.swift:47-75`); sidebar top inset 2 and 14 above the bar (`ListsSidebar.swift:37,58`); sidebar
column min/ideal 280 (`RootView.swift:159`); Mac picker sheet min 320 × 400 (`MovePickerSheet.swift:67`); sentence strip
`.padding()` system default; Quick Entry ideal width 320 (`QuickEntryView.swift:39`).

### 4.2 List screen — `TLM` (phone) and `TLP` (pane)

| Component | Value | Phone | Pane (Mac, iPad) | Ref (phone; pane) |
|---|---|---|---|---|
| screen | glass row inset from sides | 14 | 14 (placed by the bar) | `TLM:532`; `TLP:153` |
| screen | content top / bottom | 56 under safe area / 116 above it | 10 under bar / 140 | same |
| screen | content side padding / max width | 0 / none | 48 / 780 (list); 0 / none (board) | `TLP:31,88` |
| screen | fade height / solid depth | 54 / 15.12 (list only) | 8 / 0 | `TLM:538`; `TLP:166` |
| glass | back diameter / glyph / weight / x-offset | 44 / 24 / regular / −2 | 34 / 19 / medium / −1 | `TLM:511-514`; `TLP:182-185` |
| glass | "…" | 44 circle, glyph 22 | capsule item 30 × 28, glyph 18 | `TLM:515-518`; `TLP:186,192-194` |
| glass | "+" | — (floating) | capsule item 30 × 28, glyph 17 medium | `TLP:187` |
| glass | capsule height / radius / padding / divider | — | 34 / 99 / 3 / 1 × 16 | `TLP:155-158` |
| glass | hairline | 0.5 | 0.5 | `TLM:522`; `TLP:199` |
| floating "+" | diameter / glyph / right / bottom | 48 / 22 medium / 16 / 30 | — | `TLM:542-545` |
| header | side padding / bottom (list, board) | 20 / 10, 12 | 0 or 28 / 8, 14 | `TLM:209,264,551-558`; `TLP:32,89,205-213` |
| header | tile side / radius / glyph | 38 / 11 / 23 | 40 / 11 / 24 | same |
| header | tile → title / title → subtitle / subtitle leading | 12 / 6 / 50 | 12 / 6 / 52 | same |
| tag bar | top / chip gap / padding / end room | 7 / 6 / 20 / 20 | 10 / 6 / 12 / 12 | `TLM:565-568`; `TLP:219-222` |
| tag bar | fade in / out; margins leading, trailing | 16 / 28; −20, −20 | 12 / 24; +40, −12 | same |
| chip | height / radius / padding L, R / hash → title / hit | 30 / 15 / 10, 12 / 5 / 44 | 26 / 13 / 8, 10 / 5 / 32 | `TLM:572`; `TLP:226` |
| chip | hash glyph | 13 | 12 | `TLM:576`; `TLP:230` |
| empty | tile side / radius / glyph | 64 / 18 / 32 | 60 / 17 / 30 | `TLM:587`; `TLP:239` |
| empty | tile → title / title → text / top / sides / max width / bottom (board) | 18 / 6 / 84 / 40 / 270 / 12 | 16 / 6 / 90 / 40 / 300 / 12 | `TLM:585`; `TLP:237` |
| block header | height / margins t, r, b, l | 44 / 6, 6, 2, 12 | 34 / 14, 0, 2, 4 | `TLM:212-216`; `TLP:34-38` |
| block header | padding t, h, b / title → date / radius / fold hit / chevron | 13, 8, 0 / 8 / 0 / 44 / 18 | 9, 6, 0 / 8 / 7 / 30 / 15 | same |
| task row | leading / trailing / min height / radius / lift radius | 8 / 12 / 44 / 12 / 14 | 4 / 10 / 36 / 9 / 11 | `TLM:398-410`; `TLP:275-289` |
| task row | title leading, trailing / vertical padding | 2, 4 / 11 | 4, 0 / 9 | same |
| task row | meta: title → meta / item gap / line gap | 3 (below title, wraps) / 10 / 3 | 12 (beside title, one line) / 8 / 0 | same |
| task row | meta glyph / glyph → text | 13 / 3 | 13 / 3 | same |
| task row | tag capsule (pane only): height / radius / padding | — | 20 / 10 / 8, 8 | `TLP:244-246` |
| check | diameter / ring / mark / mark stroke / hit | 24 / 1.75 / 15 / 1.75 / 44 × 44 | 18 / 1.5 / 12 / 1.4 / 32 × 36 | `TLM:370-375`; `TLP:250-255,286` |
| check | subtask: diameter / ring / mark / stroke / hit | 18 / 1.5 / 12 / 1.4 / 40 × 44 | 15 / 1.5 / 10 / 1.17 / 30 × 30 | `TLM:379-384`; `TLP:259-264` |
| swipe | threshold / shift / button width / insets v, trailing / radius | 40 / −88 / 78 / 3, 10 / 12 | same (the phone's, kept by the iPad) | `TLM:419-422`; `TLP:288` |
| drop mark | height / line / circle / ring; circle at; line from … to short of | 10 / 2 (r 1) / 8 / 2; 52; 62 … 20 | 10 / 2 / 8 / 2; 36; 46 … 10 | `TLM:499-505`; `TLP:295-301` |
| block drop | ring / radius / inset | 2 / 18 / 6 | 2 / 14 / 4 | `TLM:488-493`; `TLP:303-308` |
| add task | height / icon cell / plus / radius / padding L, R / margins L, R | 40 / 44 / 18 / 12 / 0, 12 / 8, 12 | 32 / 32 / 15 / 8 / 4, 12 / 0, 0 | `TLM:218-225`; `TLP:40-47` |
| add list | height / icon cell / plus / radius / top padding / top margin / margins L, R | 44 / 40 / 18 / 12 / 4 / 10 / 12, 6 | 36 / 32 / 15 / 9 / 4 / 10 / 4, 0 | `TLM:238-246`; `TLP:60-67` |
| Done strip | height / radius / gap / padding L, R | 36 / 18 / 8 / 10, 14 | 30 / 15 / 7 / 9, 12 | `TLM:226-236`; `TLP:48-58` |
| Done strip | top / margins L, R / to rows / glyph / chevron | 20 / 14, 16 / 6 / 18 / 15 | 22 / 6, 0 / 6 / 16 / 13 | same |
| open card | margins t, h, b / radius / shadow | 6, 10, 10 / 18 / raised | 6, 0, 10 / 14 / raised | `TLM:431-444`; `TLP:312-315` |
| open card | body leading, trailing, bottom / check hit | 46, 14, 14 / 44 × 44 | 38, 14, 14 / 32 × 40 | same |
| open card | title field height, padding / expand glyph in hit | 44, 2 / 19 in 44 | 40, 2 / 16 in 30 (hover r 7) | `TLM:441-442`; `TLP:331,347` |
| open card | notes min height / title → notes / notes → subtasks / outdent | 22 / 2 / 4 / 12 | 20 / 2 / 4 / 8 | same |
| open card | subtask row / subtask field height | 44 / 40 | 30 / 30 | `TLM:389,442`; `TLP:345,347` |
| open card | "Add subtask": height / cell / plus / radius / trailing / margin | 44 / 40 / 17 / 12 / 12 / −12 | 30 / 30 / 14 / 7 / 10 / −8 | `TLM:455-462`; `TLP:348-355` |
| pills | subtasks → pills / pill gap (both axes) | 10 / 6 | 8 / 6 | `TLM:435`; `TLP:333` |
| pill | height / radius / padding L, R / glyph → text | 32 / 16 / 10, 12 / 6 | 26 / 13 / 8, 10 / 5 | `TLM:466-471`; `TLP:356-362` |
| pill | sun / flag / hash glyph | 16 / 15 / 14 | 14 / 13 / 12 | same |
| motion offsets | card entrance offset; leaving sink | −4; 12 | −3; 12 | `TLM:448-450,350`; `TLP:335-337` |

Board (`TLM:263-335`; `TLP:87-143`):

| Value | Phone board | Pane board |
|---|---|---|
| column gap / side padding / end room / bottom padding / snapping | 10 / 16 / 16 / 24 / yes | 12 / 24 / 12 / 24 / no |
| column width / radius / card gap / column padding | 296 / 18 / 8 / 8 | 288 / 14 / 6 / 6 |
| card radius / ring / drop ring | 13 / 0.5 / 2 | 10 / 0.5 / 2 |
| column header height / top margin / leading margin / padding t, h, b | 44 / 0 / 0 / 13, 14, 9 | 31 / 5 / 6 / 6, 6, 4 (hover r 7, title fits) |
| card row: leading, trailing / title leading, trailing / vertical / min height | 0, 12 / 2, 4 / 11 / 44 | 0, 0 / 0, 10 / 9 / 36 |
| card row: meta gap / meta line gap / meta glyph / landing scale | 10 / 3 / 13 / 1.05 | 9 / 2 / 12 / 1.05 |
| card check: diameter / hit | 22 (ring 1.75, mark 15) / 42 × 44 | 18 / 34 × 36 |
| open card in a column: radius / margins / shadow / body leading, trailing, bottom | 13 / 0 / resting / 44, 12, 12 | 10 / 0 / resting / 36, 12, 12 |
| "Add task" (fills column on pane): height / cell / gap / padding / radius | 44 / 18 / 6 / 11, 12 / 13 | 32 / 15 / 6 / 10, 10 / 9 |
| "Add list" column: width / height / radius / padding / plus → title / dash | 200 / 52 / 18 / 16 / 8 / 1.5, [5, 4] | 200 / 44 / 14 / 14 / 8 / 1.5, [5, 4] |

### 4.3 Hit targets

- Phone: 44 everywhere (check 44 × 44, subtask check 40 × 44, fold 44, chip hit 44, expand 44, glass buttons 44, add
  task cell 44, subtask rows 44, list rows 46, bar controls 48). Exceptions: picker option minimum 36, area line alone 17
  (wrapped to 36 in the picker).
- Wide: 28–36 (rows 30, row check 32 × 36, card check 34 × 36, fold 30, chip 32, expand 30, glass back 34, capsule items
  30 × 28, Mac bar controls 30, subtask check 30 × 30). **The iPad uses these wide numbers with touch** (rows 30 pt,
  chevron cell 20) — below Apple's 44 pt touch target.

### 4.4 Distinct values and frequency

Counted over every non-zero numeric argument in `TVL`, `TLM` and `TLP` (declarations, not rendered occurrences).
Spacing = paddings, margins, gaps, insets; motion offsets, optical offsets, indicator positions, indent start/step,
content top/bottom and the empty state's top padding are left out (listed under outliers).

**Spacing (237 declarations, 23 distinct):**

| pt | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 18 | 20 | 22 | 24 | 28 | 30 | 40 | 48 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| count | 11 | 10 | 18 | 4 | 35 | 2 | 30 | 7 | 30 | 3 | 36 | 2 | 14 | 1 | 9 | 4 | 11 | 1 | 3 | 1 | 1 | 3 | 1 |

**Radius (61 declarations, 17 distinct, zeros left out):** 1 ×3 (line ends), 5 ×2, 6 ×3, 7 ×5, 8 ×4, 9 ×3, 10 ×6, 11 ×3,
12 ×6, 13 ×8, 14 ×6, 15 ×2, 16 ×1, 17 ×1, 18 ×6, 24 ×1, 99 ×1. Hover radii (`paneHover(n)`, `TLP:172-174`) repeat their
control's: 7, 8, 9, 13, 14, 15.

**Line widths (38):** 0.5 ×4, 1 ×9, 1.17 ×1, 1.4 ×2, 1.5 ×7, 1.75 ×4, 2 ×11. Dash `[5, 4]` ×3.

**Glyph sizes (15 distinct):** 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 22, 23, 24, 30, 32 (§7).

**Control heights:** 17, 20, 22, 24, 26, 28, 30, 31, 32, 34, 36, 40, 44, 46, 48, 50, 52.

### 4.5 Proposed scales (proposal; nothing decided)

- **Spacing:** `2 · 4 · 6 · 8 · 10 · 12 · 14 · 16 · 20 · 24` plus layout-level `40 · 48`. Covers 201 of 237 spacing
  declarations (85 %). Adding `3` covers 211 (89 %): 3 is the meta-line micro gap (title → meta, glyph → text, meta line
  gap, capsule padding) and is frequent enough to consider. An even 2-pt step to 16 fits because the canvas measures in
  even pixels almost everywhere.
- **Radius:** `6 · 8 · 10 · 12 · 14 · 18` + `full` (capsule: half the height; covers 10/13/15/16/18/24/99 as capsules) +
  a tile rule. **Tile radius = round(side × 0.28)** reproduces all eight tile radii (18→5, 22→6, 26→7, 30→8, 38→11,
  40→11, 60→17, 64→18); this is an observed fit, not a rule found in the canvas. Left over: 7 (sidebar row, Mac header,
  Mac controls, sidebar drag card), 9 (pane row, pane add list, pane column add task), 11 (pane lift), 13 (phone board
  card, slot, board add task).
- **Line width:** `0.5 · 1 · 1.5 · 2` (hairline, rule, emphasis, focus/drop); check strokes 1.75/1.4/1.17 are derived
  (canvas 2.8 in a 24-unit box × mark size) and belong to the check component.
- No single density factor maps phone to wide (heights ×0.75–0.87, header tile ×1.05, empty tile ×0.94), so a
  "compact" variant cannot be derived by scaling.

### 4.6 Outliers that belong to component contracts, not global tokens

- Odd spacings: 3 (meta), 5 (chip/pill glyph gap, pane column header top), 7 (phone tag-bar top, pane Done gap), 9 (Mac
  search leading, pane vertical paddings and meta gap), 11 (phone row vertical padding, board add-task leading), 13
  (block header top padding), 15 (search capsule leading).
- Positions derived from other geometry: body leading 46/44/38/36 (= check hit + title leading), subtitle leading 50/52
  (= tile + gap), drop-mark offsets 62/52/46/36, indicator −6/+2, indent 20+22n / 18+16n, glass icon offsets −2/−1.
- Screen-level: content top 56/10, content bottom 116/140, max width 780, fades 54/15.12/8/52/4, tag-bar margins ±20,
  +40/−12, empty top 84/90 and max width 270/300, sidebar width 280, column widths 296/288, add-list column 200, drag
  card 170 × 30.
- Behaviour: swipe threshold 40 / shift −88 / button 78; drag raise 6, minimum width 120; titles' minimum widths 140/90;
  area field 160.

### 4.7 Values the comments mark as deliberate

- Owner: block-drop ring 6 in from the block's sides "so that the ring stands clear of the rows' checks" (`TLM:484-487`,
  the owner's review of #177).
- Controller rulings (the pilot's review role, not the owner): the board's numbers (`TLM:250`, #175), the pane's fade 8
  and content top 10 (`TLP:145-166`, R204/R211), lift dimming 0.35 (`TLM:473-476`, #177), pane add-task filling its
  column (`TLP:83`, R215), the iPad search capsule without the microphone (`TVL:736-738`, #149), picker rows on paper
  (`TVL:839-843`, review of #149), the meta orders (`TLM:412-414`, `TLP:291-293`, R210).
- Engineer fill-ins where "the table gives no …" (most normalisable): phone row radius 12 "until Task 8's hand check
  tunes it" (`TLM:396-397`), notes height 22 (`TLM:429-430`), column padding and card gap 8 (`TLM:254-255`), column
  header height (`TLM:255`; pane 31, `TLP:85-86`), dash 5/4 (`TLM:262`), empty bottom 12 (`TLM:580-582`), the pane's
  "+ Add list" "the phone's at the pane's scale" (`TLP:27-29,84-86`), pane lift "2 more than the row" (`TLP:272`).

---

## 5. Shadows, opacity, line widths, blur

### 5.1 Shadows (`DS/Shadow.swift:20-34`; rendered `UI/DesignSystem/Shadow+DesignSystem.swift:8-10` as black, x 0)

| Token | Opacity | Radius | y | Used for | Canvas source |
|---|---|---|---|---|---|
| `lifted` | 0.22 | 18 | 10 | phone drag card, sidebar indicator card (`TVL:791,818`), lifted task copy (`TLM:479`) | drag card; "as Task 7 drew it" |
| `raised` | 0.12 | 12 | 5 | bar buttons on a fill (`TVL:118`, `Bar.swift:101`), bar glass (`Bar.swift:178`), list-screen glass before 26 (`TLM:522`, `TLP:199`), floating "+" (`TLM:543`), phone open card (`TLM:436`), pane open card (`TLP:313`) | `--shadow`, "as Task 7 drew it" |
| `resting` | 0.06 | 1 | 1 | board cards and open cards in a column (`TLM:272,307`; `TLP:96,122`) | `0 1px 2px rgba(0,0,0,.06)`, blur halved |
| `hovered` | 0.08 | 5 | 3 | pane board card under the pointer (`TLP:97`) | `0 3px 10px rgba(0,0,0,.08)`, blur halved |

Canvas, for comparison: `--shadow` = `0 1px 2px rgba(60,40,20,.06), 0 10px 28px rgba(60,40,20,.10)` light,
`0 1px 2px rgba(0,0,0,.35), 0 10px 28px rgba(0,0,0,.35)` dark; `--shadow-lg` = `0 2px 6px rgba(60,40,20,.08),
0 24px 60px rgba(60,40,20,.22)` / `0 2px 6px rgba(0,0,0,.4), 0 24px 60px rgba(0,0,0,.6)`. The code collapses each to one
black layer with **no dark-mode variant**; the canvas blur is halved into SwiftUI's radius (`Shadow.swift:28-34`).

### 5.2 Opacity

- In colour tokens: glass 0.72, glassLine 0.08, hover 0.05, fresh 0.12 / 0.08, placeholder 0.8, tile background
  0.15 / 0.24, drop tint 0.10 / 0.20, bar glass edge 0.08 (`Bar.swift:178`).
- In components: disabled picker option 0.35 (`TVL:213`, `MovePickerSheet.swift:134`); dragged-from row/card 0.35
  (`TLM:479`); sidebar drag card 0.95 (`TVL:819`); entrances start at 0 (Done rows) or 0.3 (card) (`TLM:231,449`,
  `TLP:53,336`); hidden accessory 0 (`Accessories.swift:100`).
- Gradients: Lists bottom fade paper 0 → 1 by 72 % over 52 (`ListsScreen.swift:47-53`); top paper 1 until 55 % → 0 over
  4 + status bar (`:66-75`); list-screen fade solid 15.12 then to clear at 54 (`TLM:538`, `ListSurface.swift:249-258`);
  pane 8 (`TLP:166`); row-end fade 10 / 8 (`ListRowView.swift:72-75`); tag-bar mask 16 / 28 and 12 / 24
  (`TagBarView.swift:33-40`).
- Scale/rotation: lift 1.03, landing 1.05, check pop 0.8 → 1.14, Done bump 1.22, entrances 0.92 / 0.94 / 0.97 / 0.98,
  drag card −1.5° (phone) / −1.2° (Mac); chevrons −90° folded (Lists, blocks), 180° open (Done strip).

### 5.3 Line widths

0.5 (glass hairline, board-card ring), 1 (rules, dividers, area line, sidebar guides), 1.5 (phone guides, slot stroke,
add-list dash, small check rings), 1.75 (phone check ring and tick), 2 (title-field focus ring, drop line and ring,
board drop ring, block-drop ring, sidebar indicator), 1.4 / 1.17 (tick strokes). Dash `[5, 4]`. Rules are filled
rectangles, not strokes (`UI/DesignSystem/Shape+DesignSystemComponents.swift:23-37`).

### 5.4 Blur

None in code. The canvas glass is `background: var(--glass); backdrop-filter: blur(20px) saturate(1.8); box-shadow: 0 0
0 .5px var(--glassline), var(--shadow)`, and its menu scrim `blur(10px)`. The pilot stands `.regularMaterial` in for the
blur before OS 26 and system Liquid Glass from 26.

---

## 6. Motion

### 6.1 Tokens (`DS/Animation.swift:27-89`)

Curves: `spring`, `easeIn`, `settle` = bezier (0.2, 0.8, 0.2, 1) (`:85`), `ease` = bezier (0.25, 0.1, 0.25, 1), CSS
`ease` (`:89`).

| Token | Curve | Duration | Delay | Used for | Canvas |
|---|---|---|---|---|---|
| `check` | spring | 0.45 | 0 | check pop keyframes (`TLM:363`); Done strip bump (`TLM:233`, `TLP:55`) | `cbPop` / `bumpA` .45s `cubic-bezier(.34,1.56,.64,1)` |
| `rowLeaves` | easeIn | 0.32 | 0.7 | completed row/card leaves (`TLM:351`) | `.row-leave` .32s ease-in |
| `rowLeavesWithNoMotion` | easeIn | 0.001 | 0.7 | the same with Reduce Motion (`TLM:352`) | — |
| `rowDeleted` | easeIn | 0.32 | 0 | deleted row (`TLM:352`, `BlockView.swift:259-266`) | — |
| `pushPop` | settle | 0.32 | 0 | **unused** (push/pop is the system's) | `Main.dc.html` |
| `popover` | spring | 0.2 | 0 | Lists chevron turn (`TVL:304`), Lists drag (`TVL:784,810`), scroll to a field (`UI/ListsScreen/ListsTree.swift:275`), Done rows entrance (`TLM:231`, `TLP:53`) | `popIn` .2s `cubic-bezier(.34,1.4,.64,1)` |
| `quickEntry` | spring | 0.42 | 0 | **unused** (the sheet is the system's) | `Main.dc.html` |
| `cardOpens` | settle | 0.26 | 0 | open card entrance (`TLM:449`, `TLP:336`) | `xIn` .26s |
| `drop` | spring | 0.32 | 0 | board card landing 1.05 → 1 (`TLM:288`, `TLP:112`) | `cardDrop` .32s `cubic-bezier(.34,1.56,.64,1)` |
| `swipe` | settle | 0.25 | 0 | row slide (`TLM:421`) | row `translateX` |
| `fold` | ease | 0.22 | 0 | block and Done chevrons (`TLC:136`, `TLX:80`) | chevron transition |
| `fresh` | ease | 1.6 | 0 | dropped row's tint fade (`TLM:404`, `TLP:281`) | `.row-fresh` 1.6s ease |
| `checkFills` | ease | 0.22 | 0 | check ring/fill colour (`TLM:363`) | `.cb` transition |
| `checkMarkDraws` | ease | 0.26 | 0.08 | tick draws in/out (`TLM:364`) | `.cb path` |
| `titleFades` | ease | 0.25 | 0 | title colour on check (`TLM:288,389,405`, `TLP:112,282,345`) | `.tt` |
| `chipToggles` | ease | 0.18 | 0 | chip lit/unlit (`TLM:573`, `TLP:227`) | `.tchip .chip` |
| `dropHighlights` | ease | 0.15 | 0 | lift dim, column and block drop tint (`TLM:274,480,491`, `TLP:98,306`) | `.card`, `.bcol` |
| `hoverTints` | ease | 0.12 | 0 | every pane hover (`TLP:173`) | `.mc-tap`, `.mc-trow` |
| `hoverShadows` | ease | 0.15 | 0 | pane board card shadow (`TLP:97`) | `.card` |

### 6.2 How `.spring` renders on Apple

`UI/DesignSystem/Animation+DesignSystem.swift:8-15`: `spring` → `Animation.spring(duration: d)` — SwiftUI's
`spring(duration:bounce:blendDuration:)` with **bounce 0** (critically damped, no overshoot; perceptual duration d, the
same as `.spring(response: d, dampingFraction: 1)`); `easeIn` → `.easeIn(duration:)` (Core Animation's ease-in, 0.42, 0,
1, 1); bezier → `.timingCurve(x1, y1, x2, y2, duration:)`; delay → `.delay(_:)`.

**The canvas's "springs" are overshooting cubic-béziers**, not physical springs: `(.34, 1.56, .64, 1)` for the check pop,
card drop and Done bump, `(.34, 1.4, .64, 1)` for `popIn`, the lift and toasts. The code loses that overshoot, except
where it rebuilds the shape with keyframes over the spring's duration:

- check pop: scale 1 → 0.8 by 35 % → 1.14 by 70 % → 1, cubic keyframes (`TLM:337-339`, `CheckButton.swift:69-84`);
- Done bump: 1 → 1.22 by 40 % → 1 (`TLM:233`, `DoneStripView.swift:28-41`).

Card drop (1.05 → 1) and popover entrances have no overshoot. westron must decide whether `spring` means a SwiftUI spring
(and with what bounce) or the canvas curve.

### 6.3 Composite motions (in component styles)

Entrance (opacity, scale about an anchor, y-offset; `DSC/EntranceStyle.swift`): Done rows 0 / 0.92 / −8 / anchor
(0.2, 0) phone, 0 / 0.94 / −6 / (0.12, 0) pane, on `popover`; card 0.3 / 0.97 / −4 phone, 0.3 / 0.98 / −3 pane, on
`cardOpens`. Leaving: title to `ink2`, strike `ink3`, fade and sink 12 on `rowLeaves` (`TLM:350-353`,
`CompletingTask.swift:55-57`). Landing: `fresh` tint fading 1.6 s, or scale 1.05 on `drop` (`TaskLanding.swift`).

Canvas motions not in code: sheet open .46s `(.2,.85,.25,1)`, close .34s `(.4,0,.7,1)`; drag card `lift` overshoot to
1.045 and `bob` 2.4s ease-in-out (left out, `TVL:777-778`); toast in/out.

### 6.4 Reduce Motion

Views read `accessibilityReduceMotion` and draw at once: chevrons (`Accessories.swift:64`, `BlockHeaderView.swift:87`,
`DoneStripView.swift:45`), check colour/tick (`CheckButton.swift:87-89`) and pop (a flat keyframe of the same length,
`:78-82`), Done bump (`DoneStripView.swift:34-35`), title colour (`TaskRowView.swift:81`, `TaskCardView.swift:139`),
chips (`TagBarView.swift:62`), column and block tint (`ColumnView.swift:32`, `BlockView.swift:153`), lift dim
(`RowDrag.swift:53`), hover (`Hovering.swift:30`), swipe (`SwipeToDelete.swift:75`), Lists drag and scroll
(`ListsTree.swift:275,305,321`, `ListsDragGesture.swift:365`), entrances drawn at rest (`Entrance.swift:19`), landing
skipped (`TaskLanding.swift:70`), delete without animation (`BlockView.swift:259-262`). A completed row still waits
0.7 s, then leaves over 0.001 s (`rowLeavesWithNoMotion`; a zero duration dropped the wait, `Animation.swift:32-34`).
Canvas: `prefers-reduced-motion` sets every duration to .01ms.

---

## 7. Icons

32 cases (`DS/Icon.swift:13-27`) → SF Symbols (`UI/DesignSystem/Image+DesignSystem.swift:19-53`). **One symbol for every
platform** (no per-platform mapping); all exist on iOS 17, macOS 14, watchOS 10 (checked against `name_availability.plist`,
`:11-18`; `Tests/DesignSystemTests/IconTests.swift`). Drawn as `Image(systemName:)` with `.font(.system(size:weight:))`
and a token colour (`Icon.swift:22-26`, `ListTile.swift:23-25`): no rendering mode, scale or variant set (monochrome,
default scale). Menus draw `Label { Text } icon: { Image(icon) }` at system size and colour (`MenuItems.swift:66-71`).
Glyph sizes are fixed points (no Dynamic Type). Weight is "the one nearest the canvas's stroke": 1.8 and the back
chevron's 2.2 → regular, the floating plus's 2.4 → medium (`TLC:15-16`).

| Case | SF Symbol | Where, size, weight, colour |
|---|---|---|
| `tray` | `tray` | tile (Inbox) |
| `sun` | `sun.max` | tile (Today); When pill 16 / 14, regular, `ink2` or amber glyph (`TLK:103`) |
| `calendar` | `calendar` | tile (Upcoming) |
| `week` | `calendar.badge.clock` | tile |
| `logbook` | `text.book.closed` | tile (Logbook) |
| `trash` | `trash` | tile (Trash); Delete menu items (`TVL:392,407`, `TLX:104`) |
| `briefcase`, `house`, `hourglass`, `bag`, `wrench`, `book` | `briefcase`, `house`, `hourglass`, `bag`, `wrench`, `book` | tile |
| `pen` | `pencil` | tile; Rename menu item (`TVL:418`) |
| `folder` | `folder` | tile; Move to… menu item (`TVL:386`) |
| `list` | `checklist` | tile (new lists); New List menu (`TVL:504`); meta subtasks 13 / 12 `ink2` (`TLC:303`); Show as List (`TLC:365`) |
| `bullets` | `list.bullet` | default tile glyph |
| `ellipsis` | `ellipsis` | bar "…" 20 semibold `ink` (`TVL:430`); glass "…" 22 regular / 18 `ink` (`TLC:350`) |
| `plus` | `plus` | bar "+" 20 semibold `onAccent`; Mac "+" 16 bold; group plus 15 semibold `accent`; floating 22 medium `onAccent`; pane glass 17 medium `ink`; add rows 18 / 15, subtask 17 / 14, regular `ink2`; New List menu |
| `check` | `checkmark` | Done 20 bold `onAccent` (`TVL:518`); picker check 15 bold `accent` (`TVL:831`) |
| `chevron` | `chevron.down` | Lists row 13 / 12 semibold `ink2` (rotated −90° folded); block header 18 / 15 regular `ink2`; Done strip 15 / 13 regular `ink2` (180° open) |
| `grip` | `line.3.horizontal` | rows and lines in edit mode 18 regular `ink3`; phone drag card 18 `ink2`; Edit menu item |
| `magnifier` | `magnifyingglass` | search 17 / Mac 15, regular `ink2` |
| `microphone` | `mic` | phone search capsule 17 regular `ink2` in a 36 cell |
| `newWindow` | `macwindow.badge.plus` | Open in New Window menu item |
| `checkCircle` | `checkmark.circle` | Done strip 18 / 16 regular, list glyph colour (`TLX:69-72`); New Task menu item |
| `divider` | `rectangle.split.1x2` | "Top level" 15 / 11 regular `ink2` on a `fill` tile; New Area menu item |
| `flag` | `flag` | meta deadline 13 / 12 (`ink2` or `red`); Deadline pill 15 / 13 |
| `hash` | `number` | chip 13 / 12 (`ink2` unlit, mark lit); tag pill 14 / 12 `ink2` |
| `note` | `note.text` | meta notes 13 / 12 `ink2` |
| `expand` | `arrow.up.left.and.arrow.down.right` | card expand 19 / 16 regular `ink2` |
| `columns` | `rectangle.split.3x1` | Show as Columns menu item |
| `chevronLeft` | `chevron.left` | glass back 24 regular / 19 medium `ink` |

- Tile glyphs are **medium** at every size (`TVL:567`, `TLC:40,321`): 12, 14, 16, 19, 23, 24, 30, 32.
- One symbol bypasses the token set: Quick Entry's toolbar button `systemImage: "plus"` (`RootView.swift:248`).
- **Custom drawn, no assets:** the check tick, a path `M6.5 12.5 l3.5 3.5 7.5−8` in a 24-unit box, round caps and joins,
  scaled to the mark size and trimmed to draw in (`TLM:341-345`, `CheckButton.swift:56-66,92-100`); the check circle
  (ring/disc); the drop indicator (rounded rule + ringed circle, `UI/DesignSystem/DropIndicator.swift`); the dashed slot
  and dashed add-list edge; rules (filled rectangles); the tile (rounded square). No image assets or custom fonts.

---

## 8. Haptics and other design decisions

- **Haptics: none.** No `sensoryFeedback`, `UIFeedbackGenerator`, `NSHapticFeedbackManager` or `WKInterfaceDevice` play;
  the specs and the canvas mention none. The system drag and context menu bring their own.
- **Corner style is mixed.** Tiles, rows, chips, pills, cards, columns, swipe button, hover, Done strip, lift and the
  glass face use `.circular` "as the canvas's `border-radius` draws them" (`ListTile.swift:17-19`,
  `GlassButton.swift:72-74`). Left at SwiftUI's default **continuous**: title field background and ring
  (`TitleField.swift:69-70`), search field (`Bar.swift:134`), picker top-level tile (`MovePickerSheet.swift:82`), phone
  drag slot and drag cards (`ListsDragGesture.swift:249,389,397`). westron needs one rule.
- **Hover** only where a pointer is (wide styles; `Hovering.swift:32-35` excludes watchOS only, so an iPad with a pointer
  gets it): a `hover` tint within the control's radius, and a deeper shadow for board cards.
- **Press state**: none of the look's own (buttons are `.plain`); the canvas's `--press` is unused.
- **Focus**: Lists title fields ring 2 pt accent; list-screen fields have no ring (plain fields with width-0 ring,
  `TLC:254-269`); no custom keyboard-focus styling.
- **Selection**: sidebar `selection` + semibold title (`TVL:234`); phone highlight `fill`, no emphasis (`TVL:618-619`).
- **Disabled**: picker options at 0.35 (`TVL:213`); "Show as → Columns" disabled by the system menu with a reason line
  (`TLC:369-371`).
- **Done state**: check fill + tick, title `ink2`, strike-through `ink3`; due deadline in `red` with words.
- **Glass by OS version**: token glass + material before 26, system Liquid Glass from 26 (§1.5).
- **Scrolling**: hidden indicators (lists, tag bar, columns); the phone board snaps to columns, the pane scrolls freely.
- **Chrome**: navigation bar hidden on the phone's Lists and list screens; Mac toolbar back; iPad glass back.
- **Truncation**: one line for list titles, labels, chips, pills, counts, Mac row titles; phone task titles wrap.
- **Fixed widths**: sidebar 280, pane content ≤ 780, board columns 296/288, Quick Entry 320, Mac picker 320 × 400.
- **iPad**: wide (Mac) metrics with touch gestures and the phone's edit-mode bar (spec §8) — the source of the small
  touch targets in §4.3.

---

## 9. What westron must reproduce exactly vs what could be normalised (flags, not decisions)

**Owner-fixed — reproduce exactly**

1. The canvas as a whole rules the look (decision 0006; Lists screen signed off on iPhone light 2026-10-25,
   `docs/specs/lists-screen.md:9`; list screen phone finished after sixteen rounds on 2026-11-01,
   `docs/specs/list-screen.md:15`).
2. Accent `#3653C9`, the same in both modes (decision 0006 line 51).
3. The palette hexes, the eleven bases and the `paint` rule, including the amber mark exception (tests pin them:
   `ColorTests`, `TileColorTests`, `CheckColorTests`).
4. Type: the role → text style/weight/rounded mapping; large title 34 (canvas 32) and meta 12 (canvas 12.5) are the
   owner's choice on #151 (`Font.swift:8-9`, `docs/plans/lists-screen.md:42`). Pill 13 vs 13.5 follows from the text
   style, with no owner citation.
5. Block-drop inset 6 (owner, #177; `TLM:484-487`).

**Canvas-measured — reproduce unless the owner approves a scale**

Every number in `TVL` `phone`/`sidebar` and `TLM`/`TLP` not listed below, the motion durations and curves, the check
geometry (diameters, ring, tick path, pop and bump shapes), the drop marks, the tag-bar fades.

**Controller rulings and engineer fill-ins — the most normalisable**

The values in §4.7 (controller rulings; "the table gives no …"), the pane's "phone at the pane's scale" values, and the
odd spacings and radii in §4.6 (3, 5, 7, 9, 11, 13, 15; radii 7, 9, 11, 13).

**Approximations of the canvas that westron may want to revisit (owner call)**

- Shadows: one black layer, the same in both modes, vs the canvas's two warm layers and heavy dark-mode shadows.
- `spring` without overshoot vs the canvas's overshooting béziers (§6.2).
- No tracking on large titles (−0.01em) and captions (+0.07em); no line heights.
- Materials for the canvas blur; Liquid Glass on 26.
- Mac sizes come out of macOS text styles and differ from the Mac canvas (§3).
- Phone guides in `line` vs the canvas's phone `--guide`; bar glass edge `ink` @ 8 % in dark vs `glassLine`.
- The system default tint on system controls instead of the accent (§1.5).

**Contrast failures — need an owner decision, not normalisation (§2.3)**

`ink3` as text and as grip; accent text, ring and check in dark; lit chip text; swipe Delete in dark; placeholders in
light; amber (and green, stone, orange) section titles; amber tile glyphs on fill/sidebar/selection.

**Gaps westron must fill that the pilot does not have**

High-contrast variants; press state; scrim/toast/badge colours (in the canvas, not in code); semantic tokens for colours
the pilot borrows from the list palette (amber for "When"); a dark-mode shadow; a corner-style rule; touch-target rules
for the iPad's wide layout; Dynamic Type behaviour of fixed-height containers and fixed-size glyphs.
