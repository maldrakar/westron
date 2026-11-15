# westron: type and icons, research report

Date: 2026-11-15. Scope: brand heading fonts, monospace fonts, how to ship them on each platform, how other multi-platform systems split brand and system fonts, and the base icon set for domain icons.

## How this was checked

- **Fonts are verified from the files, not from marketing pages.** I downloaded each variable font from the [google/fonts](https://github.com/google/fonts/tree/main/ofl) repository (the files Google Fonts serves) and, where upstream has a newer release, from the upstream repository. I then read them with fontTools 4.60.2:
  - `cmap`: Russian alphabet (66 letters including Ё/ё), the whole Cyrillic block U+0400–04FF, Cyrillic Supplement U+0500–052F, and test letters for Ukrainian (Є І Ї Ґ), Belarusian (Ў), Serbian/Macedonian (Ј Љ Њ Ћ Џ Ђ Ѓ Ќ Ѕ) and Kazakh (Ә Ғ Қ Ң Ө Ұ Ү Һ);
  - `fvar`: axes and ranges;
  - `GSUB`/`GPOS`: OpenType features (`tnum`, `zero`, `case`, `ssNN`, `cvNN`, `calt`) and whether the default digits are already equal-width;
  - `OS/2`: x-height and cap height, relative to the em;
  - sizes: each font subset to Latin + Latin Extended + Cyrillic + Cyrillic Extended with all layout features kept, saved as hinted TTF (what an app bundles) and as unhinted WOFF2 (what the web serves).
- Where a statement comes from a page rather than from a file, the link is inline. Items I could not verify are marked **UNVERIFIED** and collected at the end.
- Parts 3 (shipping), 4 (brand vs system) and 5 (icons) were researched in parallel from primary docs; the links are inline.

---

## 1. Brand heading fonts

### 1.1 The short answer

Of the 18 requested fonts, **9 have no Cyrillic at all** in their current files and drop out on the owner's hard requirement:
Mona Sans, Hubot Sans, Instrument Sans, Figtree, Schibsted Grotesk, Bricolage Grotesque, **Google Sans Flex**, Fraunces, Newsreader.
This includes the newest upstream releases (Mona Sans 2.0.27 from May 2026, Google Sans Flex 5.000 from October 2026), not only the Google Fonts copies. Two fonts I added as extras also lack Cyrillic: Geist Serif (new in October 2026) and Space Grotesk.

The fonts that pass are **Inter, Geist, IBM Plex Sans, Onest, Golos Text, Manrope, Rubik, Unbounded, Source Serif 4**, plus Literata as a second serif.

### 1.2 Verified data

Russian = letters present out of 66. Cyr block = code points present out of 256 in U+0400–04FF. "uk/be/sr/kk" = whether the test letters for those languages are all present. Sizes are for the Latin + Latin Ext + Cyrillic + Cyrillic Ext subset of the upright variable font. RFN = Reserved Font Name in the OFL (see 1.4).

| Font (version checked) | License | Russian | Cyr block | uk/be/sr/kk | Axes | Figures | x-height | WOFF2 | TTF |
|---|---|---|---|---|---|---|---|---|---|
| Inter 4.001 (GF) / 4.1 upstream | OFL, no RFN | 66/66 | 248 | all | opsz 14–32, wght 100–900 | `tnum` (default proportional), `zero`, `case`, 22 `ss`/`cv` | 0.546 | 234 KB; Display-only instance 110 KB | 570 KB; Display-only 314 KB |
| Geist 1.900 (upstream 1.9.2, 2026-11-06) | OFL, no RFN | 66/66 | 134 | all | wght 100–900 | `tnum`, `case`, `ss01`–`ss11` | 0.530 | 49 KB | 119 KB |
| IBM Plex Sans Var 3.000 (`@ibm/plex-sans-variable` 0.2.0) | OFL, **RFN "Plex"** | 66/66 | 192 | all | wght 100–700, wdth 85–100 | **default digits tabular** (no `pnum`), `zero`, `onum` | 0.516 | 163 KB | 389 KB |
| Onest 2.001 (2026-08-06) | OFL, no RFN | 66/66 | 162 | all | wght 100–900 | `tnum`/`pnum`, `case`, `ss01`–`ss02` | 0.527 | 67 KB | 149 KB |
| Golos Text 2.004 | OFL, no RFN | 66/66 | 170 | all | wght 400–900 | `tnum`/`pnum`, `lnum`/`onum`, `case` | 0.530 | 68 KB | 161 KB |
| Manrope 4.505 | OFL, no RFN | 66/66 | 104 | Kazakh partly missing | wght 200–800 | `tnum`/`pnum`, `case` | 0.540 | 40 KB | 113 KB |
| Rubik 2.300 | OFL, no RFN | 66/66 | 176 | all | wght 300–900 | `tnum`, `zero`, `case` | 0.520 | 61 KB | 162 KB |
| Unbounded 1.701 | OFL, no RFN | 66/66 | 98 | Kazakh missing | wght 200–900 | `tnum`, `case` | 0.566 | 213 KB | 592 KB |
| Source Serif 4 4.004 | OFL, no RFN | 66/66 | 150 | all | opsz 8–60, wght 200–900 | `tnum`, `zero`, `lnum`/`onum` | 0.475 | 350 KB | 927 KB |
| Literata 3.103 (extra) | OFL, no RFN | 66/66 | 118 | all | opsz 7–72, wght 200–900 | `tnum`, `zero`, `lnum`/`onum` | 0.507 | 221 KB (Latin+Cyrillic only) | — |
| Mona Sans 2.0.27 upstream | OFL, **RFN "Mona"** | **0/66** | 0 | none | wdth 75–125, wght 200–900, opsz 0–100 (upstream) | `tnum` | 0.517 | — | — |
| Hubot Sans 2.000 | OFL, **RFN "Hubot"** | **0/66** | 0 | none | wdth 75–125, wght 200–900 | `tnum` | 0.515 | — | — |
| Instrument Sans 1.000 | OFL | **0/66** | 0 | none | wdth 75–100, wght 400–700 | `tnum`, 12 `ss` | 0.510 | — | — |
| Figtree 2.002 | OFL | **0/66** | 0 | none | wght 300–900 | `tnum` | 0.500 | — | — |
| Schibsted Grotesk 1.100 | OFL | **0/66** | 0 | none | wght 400–900 | `tnum`, `zero` | 0.527 | — | — |
| Bricolage Grotesque 1.001 | OFL | **0/66** | 0 | none | opsz 12–96, wdth 75–100, wght 200–800 | `tnum` | 0.528 | — | — |
| Google Sans Flex 5.000 (2026-10-09) | OFL, no RFN, **plus Google trademark terms** | **0/66** | 0 | none | opsz 1–144, wdth 25–151, wght 1–1000, ROND 0–100, slnt −10–0 | `tnum`, `zero` | 0.510 | ~1 MB even Latin-only | 3.8 MB full |
| Fraunces 1.000 | OFL | **0/66** | 0 | none | opsz 9–144, wght 100–900, SOFT, WONK | **no `tnum`** | 0.482 | — | — |
| Newsreader 1.003 | OFL | **0/66** | 0 | none | opsz 6–72, wght 200–800 | `tnum` | 0.426 | — | — |

For comparison, the system fonts the headings will sit next to: SF Pro has x-height 0.508 (read from `/System/Library/Fonts/SFNS.ttf` on this Mac); Adwaita Sans is a customized Inter, so its x-height should be close to Inter's 0.546 (inferred, not measured; see 3.2).

All the variable files are TrueType-flavoured (`glyf`) with `STAT` and `HVAR` tables, so they work with CoreText, FreeType/HarfBuzz (GTK, Android) and browsers. Almost all are unhinted; only IBM Plex (and the old static Mona Sans build) carries TrueType hinting. For headings at 20 px and up this does not matter on any platform. At small sizes on low-DPI Linux screens an unhinted font relies on grayscale antialiasing.

Primary file locations: [ofl/inter](https://github.com/google/fonts/tree/main/ofl/inter), [rsms/inter v4.1](https://github.com/rsms/inter/releases/tag/v4.1), [vercel/geist-font](https://github.com/vercel/geist-font/releases), [IBM/plex](https://github.com/IBM/plex/releases), [simpals/onest 2.001](https://github.com/simpals/onest/releases/tag/2.001), [ofl/golostext](https://github.com/google/fonts/tree/main/ofl/golostext), [ofl/manrope](https://github.com/google/fonts/tree/main/ofl/manrope), [ofl/rubik](https://github.com/google/fonts/tree/main/ofl/rubik), [ofl/unbounded](https://github.com/google/fonts/tree/main/ofl/unbounded), [ofl/sourceserif4](https://github.com/google/fonts/tree/main/ofl/sourceserif4), [ofl/literata](https://github.com/google/fonts/tree/main/ofl/literata), [github/mona-sans v2.0.27](https://github.com/github/mona-sans/releases/tag/v2.0.27), [ofl/hubotsans](https://github.com/google/fonts/tree/main/ofl/hubotsans), [ofl/instrumentsans](https://github.com/google/fonts/tree/main/ofl/instrumentsans), [ofl/figtree](https://github.com/google/fonts/tree/main/ofl/figtree), [ofl/schibstedgrotesk](https://github.com/google/fonts/tree/main/ofl/schibstedgrotesk), [ofl/bricolagegrotesque](https://github.com/google/fonts/tree/main/ofl/bricolagegrotesque), [googlefonts/googlesans-flex v5.000](https://github.com/googlefonts/googlesans-flex/releases/tag/v5.000), [ofl/fraunces](https://github.com/google/fonts/tree/main/ofl/fraunces), [ofl/newsreader](https://github.com/google/fonts/tree/main/ofl/newsreader).

### 1.3 Each candidate in a sentence

**Inter / Inter Display.** A neutral neo-grotesque drawn for screens, with a tall x-height. Since 4.0 (November 2023) the "Display" cuts live on an `opsz` axis, so one file gives text and display spacing ([v4.0 release notes](https://github.com/rsms/inter/releases/tag/v4.0)). Version 4.1 (November 2024) overhauled many Cyrillic glyphs ([v4.1](https://github.com/rsms/inter/releases/tag/v4.1)); the Cyrillic is the most complete of the sans candidates (248 of 256). Used by Figma's UI ([Wikipedia](https://en.wikipedia.org/wiki/Inter_(typeface))), Linear (Inter Display for headings, Inter for the rest; [Linear, March 2024](https://linear.app/now/how-we-redesigned-the-linear-ui)), the Shopify admin ([Polaris docs](https://github.com/Shopify/polaris/blob/main/polaris.shopify.com/content/design/typography/font-and-typescale.mdx)), and as the base of Atlassian Sans ([atlassian.design](https://atlassian.design/foundations/typography/product-typefaces-and-scale)) and of GNOME's Adwaita Sans (3.2). **Caveat for westron:** on GNOME the body font *is* Inter, and on Apple it sits very close to SF Pro, so as a heading font Inter Display reads as "a slightly different system font". The brand signal is weak; consistency is excellent. Upstream has had no release since November 2024.

**Geist.** A Swiss-inspired grotesque with geometric construction, crisp and slightly condensed, the voice of Vercel ([ofl/geist](https://github.com/google/fonts/tree/main/ofl/geist)). The Cyrillic was redesigned in 1.7.0 (January 2026, by Guido Ferreyra) ([release](https://github.com/vercel/geist-font/releases/tag/1.7.0)). Very actively maintained: 1.9.2 shipped 2026-11-06. Only a weight axis, but the smallest files of the serious candidates (49 KB WOFF2 with Cyrillic). Used by Vercel and v0 on product and marketing. **Caveat:** strongly associated with Vercel and the Next.js ecosystem.

**IBM Plex Sans.** An engineered grotesque with squared-off curves and visible "machine" details, designed to express "the relationship between mankind and machine" ([GF description](https://github.com/google/fonts/tree/main/ofl/ibmplexsans)). Its default digits are already tabular, which is unusual and good for dashboards. A variable build exists but is still at 0.2.0 (June 2025); Plex Mono Variable reached 1.0.0 on 2026-07-30 ([IBM/plex releases](https://github.com/IBM/plex/releases)). It is IBM's corporate typeface and the Carbon font everywhere ([Carbon](https://carbondesignsystem.com/elements/typography/overview/)). **Caveats:** the IBM look is unmistakable, and the "Plex" RFN complicates self-made web subsets (1.4).

**Onest.** A hybrid of geometric and humanist grotesque with two character sets for closed or semi-open apertures (`ss01`/`ss02`), friendly but clean ([Onest article](https://github.com/google/fonts/blob/main/ofl/onest/article/ARTICLE.en_us.html)). Designed in Moldova by Dmitri Voloshin and Andrey Kudryavtsev for Simpals, positioned as a typeface for open communication between state and society ([voloshin.md](https://voloshin.md/en/project/onest), [Simpals](https://simpals.com/?p=43955)). Version 2.000 extended Cyrillic to 56 languages, and 2.001 shipped in August 2026 ([release](https://github.com/simpals/onest/releases/tag/2.001)). Little brand baggage outside Moldova.

**Golos Text.** A calm, closed-aperture Russian grotesque for continuous reading on screen, by Alexandra Korolkova and Vitaly Kuzmin (ParaType, 2019), "commissioned by Smena and AIC Media for state and social service websites" ([README](https://github.com/googlefonts/golos-text)). Excellent Cyrillic drawing. **Caveat:** in Russia it is associated with state-service websites (the exact site is **UNVERIFIED** from a primary source). A sibling, **Golos UI**, is a narrower interface cut whose weights keep the same width ("multiplexed"), Latin and Cyrillic, weights 400–700 ([v-fonts](https://v-fonts.com/fonts/golos-vf)). It is not on Google Fonts, and I could not open its official licence file (**UNVERIFIED**: OFL per third-party sources only).

**Manrope.** A modern semi-condensed geometric grotesque with rounded forms, by Mikhail Sharanda (2018), common on startup sites ([GF description](https://github.com/google/fonts/tree/main/ofl/manrope)). Clean, compact Cyrillic and the smallest file here (40 KB). Kazakh letters are only partly present.

**Rubik.** A sans with slightly rounded corners, soft and chunky. It came from Google's Chrome Cube Lab, and Alexei Vanyashin redesigned the Cyrillic in 2016 ([GF description](https://github.com/google/fonts/tree/main/ofl/rubik)). Friendly and toy-like at heavy weights; less suited to a precise technical voice. Upstream has been quiet since 2023.

**Unbounded.** A wide, rounded, loud display face, funded by the Polkadot treasury and drawn by NaN and Studio Koto ([GF description](https://github.com/google/fonts/tree/main/ofl/unbounded)). Only for large headlines: it is very wide, so a long Russian word in a narrow column breaks layouts. The Cyrillic is basic (98 code points, no Kazakh).

**Source Serif 4.** A quiet transitional serif after Fournier, with an optical-size axis 8–60 and full localized forms for Bulgarian, Macedonian and Serbian ([GF description](https://github.com/google/fonts/tree/main/ofl/sourceserif4)). The editorial choice with Cyrillic, but heavy: 350 KB WOFF2 for the subset.

**Literata (extra serif).** A contemporary book serif by TypeTogether, made for Google Play Books, with `opsz` 7–72 and Cyrillic ([ofl/literata](https://github.com/google/fonts/tree/main/ofl/literata)). Warmer than Source Serif.

**No Cyrillic (dropped):**
- **Mona Sans / Hubot Sans** (GitHub): an industrial grotesque with a width axis and a geometric "robotic" sibling. Mona Sans 2.0 added `opsz` and a Mona Sans Mono, but still has no Cyrillic in 2.0.27 ([repo](https://github.com/github/mona-sans)).
- **Instrument Sans**: a precise neo-grotesque with 12 stylistic sets.
- **Figtree**: a friendly geometric sans. A "Add Cyrillic support" issue has been open since August 2022 ([issue search](https://github.com/erikdkennedy/figtree/issues?q=cyrillic)).
- **Schibsted Grotesk**: a newsy grotesque for the Schibsted media group.
- **Bricolage Grotesque**: an ink-trapped collage of French and British grotesques.
- **Google Sans Flex**: Google's brand face, open-sourced in 2025 ([GF article](https://github.com/google/fonts/blob/main/ofl/googlesansflex/article/ARTICLE.en_us.html)). It has no Cyrillic in 5.000, and its [TRADEMARKS.md](https://github.com/google/fonts/blob/main/ofl/googlesansflex/TRADEMARKS.md) forbids implying any affiliation with Google. The non-Flex **Google Sans** does have Cyrillic (220 code points), but its `opsz` axis spans only 17–18, the file is 4.9 MB, and it reads as Google.
- **Fraunces**: a soft, "wonky" old-style display serif; it also has no tabular figures.
- **Newsreader**: a text serif for news.
- **Geist Serif** (extra): a high-contrast display serif added in October 2026 ([release](https://github.com/vercel/geist-font/releases/tag/v1.9.0)).

### 1.4 License fine print that affects shipping

- **Bundling an OFL font in an app is allowed.** You must ship "at a minimum … the copyright statement, the license notice and the license text" ([OFL FAQ 1.20](https://openfontlicense.org/ofl-faq/)). For westron that means an `OFL.txt` per font in every app and in the web package.
- **Subsetting is modification.** "Removing parts … is considered modification … permitted by the OFL but would not normally allow the use of RFNs" (FAQ 2.6). WOFF2 compression of unchanged font data is *not* modification (FAQ 2.2.1).
  - So for **IBM Plex** ("Plex"), **Mona/Hubot** and **Monaspace** (RFN "Monaspace" and its subfamily names, [LICENSE](https://github.com/githubnext/monaspace/blob/main/LICENSE)), westron must not ship a self-made subset or instance under the original name.
  - Use the rights holder's own builds instead: IBM's npm packages include official per-script WOFF2 splits.
  - Inter, Geist, Onest, Golos, Manrope, Rubik, Unbounded, Source Serif 4, Literata, JetBrains Mono, Fira Code, Iosevka and Commit Mono have **no RFN**, so westron can subset and instance them freely.
- **Google Sans and Google Sans Flex** have no RFN, but Google's trademark terms forbid implying affiliation. They are unsuitable as a brand face for someone else.

---

## 2. Monospace fonts

### 2.1 Verified data

All are monospaced across Latin and Cyrillic (checked: every A–Z and А–я has the same advance), so the digits are tabular by construction.

| Font (version checked) | License | Russian | Cyr block | uk/be/sr/kk | Axes | Notable features | Box drawing U+2500–257F | x-height | WOFF2 / TTF (Lat+Cyr+ext) |
|---|---|---|---|---|---|---|---|---|---|
| JetBrains Mono 2.211 (GF) / 2.304 upstream | OFL, no RFN | 66/66 | 98 | Kazakh partly missing | wght 100–800 | coding ligatures in `calt` (on by default), `zero`, `case` | 128/128 | 0.550 | 51 KB / 125 KB |
| IBM Plex Mono Var 1.000 (2026-07-30) | OFL, **RFN "Plex"** | 66/66 | 192 | all | wght 100–700 | `zero`, `ss01`–`ss05`, no ligatures | 128/128 | 0.516 | 54 KB / 137 KB |
| Geist Mono 1.900 (upstream 1.9.2) | OFL, no RFN | 66/66 | 134 | all | wght 100–900 | coding ligatures moved to `ss11`, **off by default** since 1.7.0 | 128/128 | 0.530 | 48 KB / 106 KB |
| Fira Code 5.002 (GF) / 6.2 upstream | OFL, no RFN | 66/66 | **240** + 48/48 Supplement | all | wght 300–700 | ligatures in `calt` (on), `ss01`–`ss08`, `zero` | 128/128 | 0.525 | 63 KB / 136 KB |
| Iosevka 34.9.1 (2026-10-24); file checked: 22.1.2 build from Fontsource | OFL, no RFN | 66/66 | **254** + 36 Supplement | all | static per weight (configurable builds) | ~29,900 glyphs, build-time variants | yes | 0.520 | **984 KB WOFF2 for one weight, unsubset** |
| Martian Mono 1.000 (GF) / 1.1.0 upstream | OFL, no RFN | 66/66 | 84 | **Serbian and Kazakh missing** | wdth 75–112.5, wght 100–800 | `calt`, `cv01`–`cv02` | **0/128** | **0.600** | 57 KB / 132 KB |
| Commit Mono 1.143 (2023-12-28) | OFL (font); the repository code is MIT | **0/66** | 0 | none | wght 200–700, ital (VF) | 16 `ss`/`cv` | 127/128 | 0.540 | — |
| Monaspace Neon 1.400 (2026-03-28, extra) | OFL, **RFN "Monaspace"** | 66/66 | 124 | all | wght 200–800, wdth 100–125, slnt | "texture healing" in `calt` | 128/128 | 0.500 | 147 KB (Lat+Cyr) |
| SF Mono (reference, Apple only) | Apple licence | — | 220 | — | wght | — | — | 0.526 | not redistributable |

**Commit Mono has no Cyrillic** and is excluded. Google Sans Code 6.001 and Mona Sans Mono 2.0.27 also have none (checked).

Sources: [ofl/jetbrainsmono](https://github.com/google/fonts/tree/main/ofl/jetbrainsmono), [IBM/plex releases](https://github.com/IBM/plex/releases), [vercel/geist-font 1.7.0 notes](https://github.com/vercel/geist-font/releases/tag/1.7.0), [ofl/firacode](https://github.com/google/fonts/tree/main/ofl/firacode), [be5invis/Iosevka releases](https://github.com/be5invis/Iosevka/releases), [Fontsource Iosevka](https://api.fontsource.org/v1/fonts/iosevka), [ofl/martianmono](https://github.com/google/fonts/tree/main/ofl/martianmono) (GF: "In January 2023, the basic Cyrillic script is added"), [commit-mono v1.143](https://github.com/eigilnikolajsen/commit-mono/releases/tag/v1.143) with `license.txt` = OFL 1.1, [githubnext/monaspace v1.400](https://github.com/githubnext/monaspace/releases/tag/v1.400).

### 2.2 Character and fit

- **JetBrains Mono.** Tall x-height, rectangular ovals, made "for the specific needs of developers"; the de facto standard in IDEs. Turn off `calt` for UI and log text, or the `->`/`!=` ligatures appear in data. Upstream releases have stalled since January 2023. Atlassian built Atlassian Mono from it to pair with its Inter-derived Atlassian Sans, matching baseline and x-height ([atlassian.design](https://atlassian.design/foundations/typography/product-typefaces-and-scale)).
- **IBM Plex Mono.** A humanist mono with Plex's squared details; the most "printed manual" of the group. It is now variable. It has no ligatures, which is good for logs.
- **Geist Mono.** Clean and geometric. Ligatures are off by default since January 2026, the right default for tables and logs. Very active upstream.
- **Fira Code.** Fira Mono plus ligatures, with the most complete Cyrillic (including all of Cyrillic Supplement). Its humanist shapes are a little softer. Upstream has had no release since 2021.
- **Iosevka.** Narrow and very configurable; GNOME's Adwaita Mono is derived from it (3.2). Narrow glyphs fit more columns in dense log views. It must be custom-built and subset for the web; one stock weight is close to 1 MB.
- **Martian Mono.** Wide, "brutal", with a huge x-height and a width axis; very expressive. It has **no box-drawing characters**, so tree views and ASCII tables fall back to another font. Serbian and Kazakh are missing.
- **Monaspace.** Five "voices" with metric compatibility and texture healing; interesting, but the RFN and a 147 KB Latin+Cyrillic subset per voice count against it.

### 2.3 Which mono goes with which heading font

| Heading font | Natural mono | Why |
|---|---|---|
| Inter Display | JetBrains Mono (or Geist Mono) | The pairing Atlassian chose for its own derivatives. x-heights 0.546 vs 0.550. |
| Geist | Geist Mono | One superfamily, same metrics (0.530). |
| IBM Plex Sans | IBM Plex Mono | One superfamily. Both use tabular digits. |
| Onest / Golos Text / Manrope | Geist Mono or JetBrains Mono | Neutral monos that do not fight a soft grotesque. Geist Mono's x-height 0.530 matches Onest (0.527) and Golos (0.530). |
| Rubik / Unbounded | Martian Mono (expressive) or JetBrains Mono (safe) | Martian matches Unbounded's width and loudness but lacks box drawing. |
| Source Serif 4 / Literata | IBM Plex Mono | A classic editorial pairing. Plex Mono's lower x-height (0.516) suits a serif. |

---

## 3. Shipping a custom font on each platform

### 3.1 Apple (SwiftUI; iOS 17, macOS 14, watchOS 10)

**Registering fonts from a Swift package.**
- The Info.plist keys only see the app bundle: `UIAppFonts` ([doc](https://developer.apple.com/documentation/bundleresources/information-property-list/uiappfonts)) and `ATSApplicationFontsPath` ([doc](https://developer.apple.com/documentation/bundleresources/information-property-list/atsapplicationfontspath)). A library such as `WestronUI` therefore registers its own fonts from `Bundle.module`.
- Use `CTFontManagerRegisterFontsForURL(url, .process, &error)` or `CTFontManagerRegisterFontURLs`. Both are available on iOS, macOS and watchOS ([doc](https://developer.apple.com/documentation/coretext/ctfontmanagerregisterfontsforurl(_:_:_:)), [doc](https://developer.apple.com/documentation/coretext/ctfontmanagerregisterfonturls(_:_:_:_:))).
- Make it idempotent: a second registration fails with `kCTFontManagerErrorAlreadyRegistered` (105).
- Do not use `CTFontManagerRegisterGraphicsFont`. It is deprecated in the iOS 18 / macOS 15 / watchOS 11 SDK, and on iOS 17 fonts registered that way were reported to disappear after backgrounding ([forum 741720](https://developer.apple.com/forums/thread/741720)).

**Dynamic Type.**
- `Font.custom(_:size:relativeTo:)` (iOS 14 / macOS 11 / watchOS 7) scales with the text style you name ([doc](https://developer.apple.com/documentation/swiftui/font/custom(_:size:relativeto:))). The plain `custom(_:size:)` also scales, relative to `.body` ([doc](https://developer.apple.com/documentation/swiftui/font/custom(_:size:))). `custom(_:fixedSize:)` does not scale.
- A missing PostScript name falls back to the system font silently, and SwiftUI does not synthesize bold or italic ([article](https://developer.apple.com/documentation/swiftui/applying-custom-fonts-to-text)). A snapshot test is the only safeguard.
- The HIG requires a custom font to provide Dynamic Type and Bold Text behaviour itself ([HIG Typography](https://developer.apple.com/design/human-interface-guidelines/typography)). Bold Text is not applied to custom fonts automatically; map `@Environment(\.legibilityWeight)` to a heavier weight ([forum 759013](https://developer.apple.com/forums/thread/759013)).

**Variable axes.**
- SwiftUI has no API for arbitrary axis values. `Font.Weight` has nine constants only. Setting `wght=650` or `opsz` means building a `CTFontDescriptor` with `kCTFontVariationAttribute` and wrapping it in `Font(ctFont)` ([doc](https://developer.apple.com/documentation/coretext/kctfontvariationattribute)).
- Such a `Font` loses automatic Dynamic Type. You must scale it with `UIFontMetrics`, which does not exist on macOS, and observe `dynamicTypeSize` yourself ([forum 759013](https://developer.apple.com/forums/thread/759013)).
- Whether `.fontWeight()` drives the `wght` axis of a registered variable font is **UNVERIFIED**.
- **Practical route for westron:** generate static instances at the token weights (e.g. 600 and 700, with `opsz` pinned for Inter Display) using fontTools `varLib.instancer` at build time. Then `Font.custom(_:size:relativeTo:)` gives Dynamic Type with no Core Text code. This is legal without renaming only for fonts without an RFN (1.4).

**Figures.** `monospacedDigit()` leaves the font unchanged if it has no tabular digits ([doc](https://developer.apple.com/documentation/swiftui/font/monospaceddigit())). Every candidate in 1.2 has `tnum` or tabular default digits, except the dropped Fraunces.

**macOS.** "macOS doesn't support Dynamic Type" (HIG). Sizes are fixed; the Sonoma "Text size" setting is documented for Apple apps only ([Apple support](https://support.apple.com/guide/mac-help/mchld786f2cd)).

**watchOS.** Dynamic Type works with `relativeTo:`. Given the screen size, I suggest keeping watchOS all-system (SF Compact) even in a branded direction. That is a design opinion, not a platform rule.

**SF Pro and SF Mono licence.** The downloadable SF fonts are for mock-ups only: "You may not embed the Apple Font in any software programs", and website use is forbidden ([developer.apple.com/fonts](https://developer.apple.com/fonts/)). The "all-system" direction therefore uses SF only through system APIs on Apple, and other system fonts elsewhere.

### 3.2 GNOME (GTK4 + libadwaita, Rust)

**The system fonts.** GNOME 48 ships Adwaita Sans, a "customized version of the popular Inter typeface", and Adwaita Mono, a "custom build of the Iosevka typeface family" ([GNOME 48 release notes](https://release.gnome.org/48/), [adwaita-fonts](https://gitlab.gnome.org/GNOME/adwaita-fonts)). So on GNOME:
- Inter Display headings look native.
- Any other heading font is a visible brand accent over Inter-based body text.
- Iosevka (narrow) is the native mono. A wider brand mono (JetBrains, Geist) will look different from the terminal.

**Loading a bundled font.**
- **Flatpak (the expected distribution):** install the TTF into `/app/share/fonts` from the manifest. The freedesktop SDK's fontconfig config already lists that directory ([50-flatpak.conf](https://gitlab.com/freedesktop-sdk/freedesktop-sdk/-/blob/master/files/fontconfig/50-flatpak.conf)). No code is needed.
- **Outside Flatpak:**
  - Pango 1.56 (January 2025) added `pango_font_map_add_font_file()`; added fonts take precedence over same-named system fonts ([doc](https://docs.gtk.org/Pango/method.FontMap.add_font_file.html)). In Rust it is `FontMapExt::add_font_file` behind the `pango` feature `v1_56` ([gtk-rs](https://gtk-rs.org/gtk-rs-core/stable/latest/docs/pango/prelude/trait.FontMapExt.html)).
  - It takes a **file path**. A font stored in a GResource must be written to disk first; I found no GBytes variant.
  - For older Pango, `FcConfigAppFontAddFile` is the fontconfig route ([doc](https://www.freedesktop.org/software/fontconfig/fontconfig-devel/fcconfigappfontaddfile.html)).

**CSS.**
- GTK CSS has no `@font-face` ([gtkcssprovider.c](https://gitlab.gnome.org/GNOME/gtk/-/blob/main/gtk/gtkcssprovider.c)). The font is referenced by family name once registered.
- `font-family`, `font-weight`, `font-feature-settings`, `font-variation-settings` and `font-variant-numeric` are all supported ([GTK CSS properties](https://docs.gtk.org/gtk4/css-properties.html)). Variable axes work directly in CSS, unlike SwiftUI.

**libadwaita classes.**
- `.title-1`…`.title-4` and `.heading` set weight and a percentage size. `.numeric` sets `tabular-nums`, and `.monospace` uses `--monospace-font-family` ([style classes](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/style-classes.html)).
- Branding the headings is one app-CSS rule on those classes, e.g. `.title-1, .title-2 { font-family: "Onest"; }`. Body text stays on the system font, as the owner wants.
- Keep sizes in `%` or `pt` so they follow the Large Text setting.

### 3.3 Android (Compose + Material 3, later)

- **Bundled fonts:**
  - Put the variable TTF in `res/font`. Declare `FontFamily(Font(R.font.x, FontWeight.SemiBold), …)`; the default `variationSettings` drive `wght` from the declared weight.
  - Arbitrary axes use `FontVariation.Settings`. Variable fonts need API 26+ ([guide](https://developer.android.com/develop/ui/compose/text/fonts), [FontVariation](https://developer.android.com/reference/kotlin/androidx/compose/ui/text/font/FontVariation)).
- **Downloadable fonts:** limited to the Google Fonts catalog through Google Play services. On slow or offline devices they fall back to the default font and reflow when the font arrives ([guide](https://developer.android.com/develop/ui/compose/text/fonts)). For a design system, bundle the font.
- **Material 3 split:**
  - M3 tokens already separate "Brand" roles (`display*`, `headline*`, `titleLarge`) from "Plain" roles (`titleMedium`/`Small`, `body*`, `label*`) ([TypefaceTokens.kt](https://github.com/androidx/androidx/blob/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/TypefaceTokens.kt)).
  - Setting `fontFamily` only on the Brand roles gives exactly westron's "brand headings, system body" split.
- **Tabular figures:** `TextStyle(fontFeatureSettings = "tnum")` ([TextStyle](https://developer.android.com/reference/kotlin/androidx/compose/ui/text/TextStyle)).

### 3.4 Web (CSS + Lit)

**Hosting.**
- Self-host variable WOFF2 split by `unicode-range` the way Google Fonts does it (latin, latin-ext, cyrillic, cyrillic-ext). A subset downloads only if the page uses its characters ([web.dev](https://web.dev/articles/font-best-practices)).
- The Google Fonts cyrillic range is `U+0301, U+0400-045F, U+0490-0491, U+04B0-04B1, U+2116` ([Inter css2 response](https://fonts.googleapis.com/css2?family=Inter:wght@100..900&display=swap)).
- Russian text also uses Latin-range punctuation and digits, so a Russian page loads **latin + cyrillic**.
- Self-hosting is also the privacy-safe option. Since 2020–21 all major browsers partition the HTTP cache, so there is no cross-site cache benefit from the Google CDN ([Chrome](https://developer.chrome.com/blog/http-cache-partitioning)). A Munich court fined dynamic Google Fonts loading under the GDPR ([LG München I, 2022](https://www.gesetze-bayern.de/Content/Document/Y-300-Z-GRURRS-B-2022-N-612)).

**Lit and shadow DOM.**
- `@font-face` inside a shadow root is ignored in Chrome and was broken in Firefox until 125 ([CSSWG wiki](https://wiki.csswg.org/spec/css-scoping), [Mozilla bug 1884786](https://bugzilla.mozilla.org/show_bug.cgi?id=1884786)).
- westron's web package must ship a document-level stylesheet with the `@font-face` rules. Components only reference `var(--westron-font-heading)`.

**Avoiding layout shift.**
- Preload the primary subset with `crossorigin` ([MDN](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Attributes/rel/preload)).
- Use `font-display: swap` for headings, or `optional` if a fallback flash is acceptable.
- Add a metric-adjusted fallback face with `size-adjust` ([Chrome](https://developer.chrome.com/blog/font-fallbacks)). `size-adjust` works in Safari 17+, but `ascent-override` and the other overrides are still missing from stable Safari (MDN browser-compat-data 8.1.9).

**Numbers and system fonts.**
- `font-variant-numeric: tabular-nums` is universal.
- The generic `ui-monospace` works only in Safari, so the mono stack needs explicit names.

### 3.5 Size cost per platform

Measured on the files in 1.2 and 2.1. Unhinted WOFF2 for the web, hinted TTF for apps. "lat+cyr" is the Google Fonts `latin` + `cyrillic` ranges; "full" is the whole font as shipped.

| Font | Web: latin | Web: cyrillic | Web: what a Russian page loads | App TTF, full file | App TTF, Lat+Cyr+ext subset |
|---|---|---|---|---|---|
| Inter (opsz+wght) | 103 KB | 29 KB | ~121 KB | 856 KB (≈447 KB deflated in an .ipa/.apk) | 570 KB; Display-only instance 314 KB |
| Geist | 32 KB | 15 KB | ~40 KB | 165 KB (≈84 KB deflated) | 119 KB |
| IBM Plex Sans Var | 64 KB | 41 KB | ~109 KB (use IBM's own splits) | 525 KB | n/a (RFN; use IBM builds) |
| Onest | 37 KB | 16 KB | ~48 KB | 189 KB (≈105 KB deflated) | 149 KB |
| Golos Text | 39 KB | 21 KB | ~53 KB | 180 KB | 161 KB |
| Manrope | 24 KB | 14 KB | ~32 KB | 161 KB | 113 KB |
| Rubik | 37 KB | 14 KB | ~47 KB | 351 KB | 162 KB |
| Unbounded | 65 KB | 30 KB | ~95 KB | 760 KB | 592 KB |
| Source Serif 4 (opsz+wght) | 192 KB | 125 KB | ~288 KB | 1.2 MB | 927 KB |
| JetBrains Mono | 40 KB | 11 KB | ~46 KB | 183 KB (≈88 KB deflated) | 125 KB |
| Geist Mono | 33 KB | 12 KB | ~40 KB | 168 KB (≈86 KB deflated) | 106 KB |
| IBM Plex Mono Var | 27 KB | 16 KB | ~37 KB | 200 KB | n/a (RFN) |
| Fira Code | 38 KB | 11 KB | ~45 KB | 254 KB | 136 KB |

**Rule of thumb.** A one-axis (weight) variable sans with Latin and Cyrillic costs **40–55 KB on the web and 100–190 KB in an app** per style. Optical-size axes roughly double to triple that: Inter 121 KB, Source Serif 288 KB.

- Upright only: italics are a second file of about the same size, and headings rarely need them.
- The heading font plus the mono font comes to roughly **80–170 KB on a Russian web page**. Per app it is **330–730 KB of TTF before compression**, about half that in the download. Inter with its `opsz` axis is the outlier at about 1 MB with JetBrains Mono, or about 440 KB if Inter is instanced to Display only. On a modern app bundle all of this is negligible.
- On the web the cost is real only for the first paint; the font is cached afterwards.

---

## 4. How multi-platform brands split brand font and system font

| System | Product UI font | Marketing / brand font | Native apps | Mono | Tabular rule | Cyrillic |
|---|---|---|---|---|---|---|
| **Adobe Spectrum 2** | Adobe Clean Spectrum VF (proprietary, Adobe Fonts only) | Adobe Clean Display (Latin only) | Docs say the same custom font on iOS/Android; one doc omits Android | Source Code Pro (OFL) | Yes: "Numbers within components should be tabular" | Yes |
| **Atlassian** | **Atlassian Sans** (derived from Inter Variable) | **Charlie Sans** (custom) | **UNVERIFIED** | **Atlassian Mono** (derived from JetBrains Mono) | Yes: tabular "for tables and lists", slashed zero for data | **UNVERIFIED** (Inter has it) |
| **GitHub Primer** | System stack; `Mona Sans VF` added first in the tokens in March 2026, but product pages did not load it on 2026-11-15 | Mona Sans, Hubot Sans (OFL) | **UNVERIFIED** | System `ui-monospace` stack | Markdown tables only | No (Mona/Hubot) |
| **Shopify Polaris** | Inter (referenced, not loaded by Polaris), system font fallback for missing scripts | `Shopify-Inter` on shopify.com | iOS app reportedly Inter (forum, non-staff) | System mono | Yes: tabular for every money amount; "Don't use mono to align numbers" | Yes |
| **Airbnb** | Airbnb Cereal VF (proprietary) | Cereal | Cereal on web, iOS and Android per the 2018 launch | **UNVERIFIED** | **UNVERIFIED** | Yes (self-hosted Cyrillic subset) |
| **Linear** | Inter for UI, **Inter Display for headings** | Inter + Tiempos Headline (serif) | **UNVERIFIED** | Berkeley Mono (commercial) | Heavy use of `tabular-nums` and slashed zero | Yes |
| **Microsoft Fluent 2** | Segoe UI / Segoe UI Variable on Windows and web | Segoe | **SF Pro on iOS/macOS, Roboto on Android** | Consolas (web token); Cascadia Code elsewhere | Dedicated `fontFamilyNumeric: Bahnschrift` | Segoe: **UNVERIFIED** here |
| **IBM Carbon** | IBM Plex (OFL) everywhere; "productive" vs "expressive" type sets | Plex | **UNVERIFIED** | Plex Mono | Default digits are tabular | Yes |

Sources:
- Adobe: [Spectrum typography](https://spectrum.adobe.com/page/typography), [fonts.json guideline](https://github.com/adobe/spectrum-design-data/blob/main/packages/design-data/guidelines/fonts.json), [applying-the-type-system.json](https://github.com/adobe/spectrum-design-data/blob/main/packages/design-data/guidelines/applying-the-type-system.json).
- Atlassian: [typography](https://atlassian.design/foundations/typography), [product typefaces](https://atlassian.design/foundations/typography/product-typefaces-and-scale), [GA announcement, Sep 2025](https://atlassian.design/whats-new/new-typography-in-general-availability), [blog](https://www.atlassian.com/blog/design/implementing-typography-at-scale-the-journey-behind-the-screens).
- GitHub: [primer/primitives PR #1332](https://github.com/primer/primitives/pull/1332) (merged 2026-03-25), [brand.github.com](https://brand.github.com/foundations/typography).
- Shopify: [Polaris font and typescale](https://github.com/Shopify/polaris/blob/main/polaris.shopify.com/content/design/typography/font-and-typescale.mdx), [using type](https://github.com/Shopify/polaris/blob/main/polaris.shopify.com/content/design/typography/using-type.mdx).
- Airbnb: [Introducing Airbnb Cereal (2018, archived)](https://web.archive.org/web/2022/https://airbnb.design/introducing-airbnb-cereal/).
- Linear: [How we redesigned the Linear UI (2024)](https://linear.app/now/how-we-redesigned-the-linear-ui); site CSS checked 2026-11-15.
- Microsoft: [Fluent 2 typography](https://fluent2.microsoft.design/typography), [@fluentui/tokens fonts](https://unpkg.com/@fluentui/tokens/lib/global/fonts.js), [fluentui-apple UIFont+Extensions](https://github.com/microsoft/fluentui-apple/blob/main/Sources/FluentUI_common/Core/Extensions/UIFont+Extensions.swift).
- IBM: [Carbon typography](https://carbondesignsystem.com/elements/typography/overview/), [carbon fontFamily.ts](https://github.com/carbon-design-system/carbon/blob/main/packages/type/src/fontFamily.ts).

**Patterns.**
1. **One owned font everywhere, native apps included:** Adobe, Airbnb, IBM. These companies own large multi-script families. Adobe notes Adobe Clean "is generally a size smaller than system fonts such as SF Pro, Segoe UI, Roboto" and adjusts its scale. A brand font in body text has metric costs.
2. **Product font separate from marketing font:** Atlassian (Atlassian Sans vs Charlie) and Adobe (Spectrum VF vs Clean Display). The 2024–2026 trend is an **OFL base for the product font**: Atlassian forked Inter and JetBrains Mono, while Shopify and Linear use Inter directly. Atlassian left system fonts because "SF Pro (Mac OS) sits much higher on the baseline than Segoe UI (Windows)", which broke icon alignment.
3. **Brand font for marketing, system font in product:** GitHub, now slowly moving Mona Sans into product tokens.
4. **Platform font on native apps:** Microsoft Fluent is the clearest case. Its iOS code takes an optional custom font name, falls back to the system font, and always scales with `UIFontMetrics`. That is a good model for westron's Apple accessor.
5. **Brand font for headings only, system or neutral body:** Linear uses Inter Display only for headings. This is also Apple's advice: "use a custom font for headlines and subheadings while using system fonts for body copy and captions, because the system fonts are designed for optimal legibility at small sizes" ([HIG Branding](https://developer.apple.com/design/human-interface-guidelines/branding)).

**westron's chosen split** (brand headings, system body, own mono) is pattern 5 with a custom mono. Of the systems above, only Linear does exactly that on the web; on native platforms it is what Apple recommends.
- Every web stack ends in a system-font fallback.
- Tabular figures in tables and money are an explicit rule at Adobe, Atlassian and Shopify. westron should make `tnum` a token-level property of numeric styles, not a per-screen choice.

---

## 5. Icons

### 5.1 Base sets compared

Counts and dates come from the GitHub API and npm, checked 2026-11-15.

| Set | Grid and keylines | Stroke, caps, joins, corners | Styles | Icons | License | Activity | Source SVG | New icons upstream |
|---|---|---|---|---|---|---|---|---|
| **Lucide** | 24, ≥1 px padding; circle r=10, square 18 with rx=2 | 2 px centred, round caps and joins; radius 2 (1 on shapes <8 px); ≥2 px between elements ([design guide](https://lucide.dev/guide/design/icon-design-guide)) | One outline; stroke width is a parameter | ~2,055 unique | **ISC**; Feather-derived icons MIT ([LICENSE](https://github.com/lucide-icons/lucide/blob/main/LICENSE)) | 1.73.0 on 2026-11-14, near-daily ([releases](https://github.com/lucide-icons/lucide/releases)) | Strokes | **PRs accepted** ([CONTRIBUTING](https://github.com/lucide-icons/lucide/blob/main/CONTRIBUTING.md)) |
| **Tabler** | 24, ≥1 px padding | 2 px centred, round/round, radius 2; drawn to survive other stroke widths ([design guide](https://docs.tabler.io/icons/design-guide)) | Outline 5,491 + Filled 1,054 | 6,545 | MIT | v3.52.0 on 2026-11-14 | Strokes (outline), fills (filled) | By request only ([repo](https://github.com/tabler/tabler-icons)) |
| **Phosphor** | 256 viewBox (≈3 px padding at 24) | Regular = 1.5 px@24; thin/light/bold; round/round | 6 weights: thin, light, regular, bold, fill, duotone | 1,512 × 6 | MIT | **Last package 2024-03-29**; only docs commits since ([core](https://github.com/phosphor-icons/core)) | Strokes (`raw/`) + outlined | No public guide |
| **Iconoir** | 24 | 1.5 px, round/round | Regular 1,383 + Solid 288 | 1,671 | MIT | v7.12.2 on 2026-11-04 | Strokes | **No icon PRs** ([CONTRIBUTING](https://github.com/iconoir-icons/iconoir/blob/main/CONTRIBUTING.md)) |
| **Heroicons** | 24 outline; separate 20 and 16 solid sets | 1.5 px, round/round | Outline 24; solid 24/20/16 | 324 | MIT | v2.2.0 on **2024-11-18** | Strokes / fills | **Not accepting new icons** ([repo](https://github.com/tailwindlabs/heroicons)) |
| **Material Symbols** | 24 dp, 20 dp live area | ≈2 dp at wght 400 / opsz 24; Outlined / Rounded / Sharp | Variable: FILL 0–1, wght 100–700, GRAD −50–200, opsz 20–48 | 4,157 | Apache-2.0 | Weekly updates, last 2026-10-23 ([repo](https://github.com/google/material-design-icons)) | **Fills only** | Closed |
| **Fluent System Icons** (extra) | Drawn per size: 12/16/20/24/28/32/48 | 1 px@16–20, 1.5 px@24 | Regular, Filled, Light, Color | 3,002 | MIT | 2026-11-13 | Fills | – ([repo](https://github.com/microsoft/fluentui-system-icons)) |
| **Hugeicons free** (extra) | 24 | 1.5 px, round | Free tier: Stroke Rounded only | 6,000+ | MIT for the free set, Pro proprietary | 2026-10-28 | Strokes | Issues only ([repo](https://github.com/hugeicons/hugeicons)) |
| **Remix Icon** (extra) | 24 | Line + fill | – | 3,229 | **Custom "Remix Icon License v1.0" since January 2026**, which forbids building a "competing icon library" ([License](https://github.com/Remix-Design/RemixIcon/blob/master/License)) | 2026-01 | Fills | **Excluded** |

Radix Icons (15 px grid, 332 icons) and Pictogrammers MDI (last npm release in December 2023) are too small or too stale.

### 5.2 Conversion to each platform

**Apple: custom SF Symbols** ([Creating custom symbols](https://developer.apple.com/documentation/technologyoverviews/custom-sf-symbols)).
- **Template.** A variable template needs three sources, **Ultralight-S, Regular-S and Black-S**, from which the system interpolates all 27 weight × scale variants.
  - The sources must be path-only (strokes converted to fills), with **the same number of paths and control points** in all three.
  - Layers, variable colour and Draw guide points are annotated in the SF Symbols app.
  - Draw animations (`DrawOnSymbolEffect`) need iOS/macOS/watchOS **26**, so on westron's minimum OS they go behind `if #available` ([doc](https://developer.apple.com/documentation/symbols/drawonsymboleffect), [WWDC25-337](https://developer.apple.com/videos/play/wwdc2025/337/)).
  - Annotations survive regeneration only if path count and order stay stable, so generation must be deterministic.
- **Ready exports.** **Only Material Symbols** ships ready SF Symbol templates (`symbols/ios`, Ultralight–Bold × S/M/L). Lucide, Tabler, Phosphor and Iconoir offer Swift packages that draw `Shape`/`Image`. Those lose baseline alignment, `.fontWeight`, `.imageScale` and symbol effects, so they are not a substitute.
- **Automation: SwiftDraw** ([repo](https://github.com/swhitty/SwiftDraw), Zlib licence, 0.29.0 on 2026-07-19).
  - `swiftdraw icon.svg --format sfsymbol` expands strokes and aligns the result to the template guides.
  - PR #125 (merged 2026-05-16) added **auto-generated Ultralight and Black weights by scaling `stroke-width` before outlining** ([PR #125](https://github.com/swhitty/SwiftDraw/pull/125)). PR #123 added path normalization so the variants interpolate ([PR #123](https://github.com/swhitty/SwiftDraw/pull/123)).
  - That is exactly the pipeline a stroke-based set needs. SwiftDraw outlines with CoreGraphics, so it runs on **macOS only**; it fits a macOS CI job.
  - **Risks.** Different stroke widths can give different point structures, and at Black weight Lucide's 2 px gaps close (≈2× stroke fills counters). Black should be about ≤1.6× Regular, or be hand-fixed.
  - **UNVERIFIED:** whether SwiftDraw's output on real Lucide icons passes Xcode validation and interpolation. A spike is needed. Glyphs 3 with the [SF Symbol plug-in](https://github.com/schriftgestalt/SFSymbolTemplate) is the manual fallback.

**GNOME: symbolic icons.**
- **HIG** ([UI icons](https://developer.gnome.org/hig/guidelines/ui-icons.html)): draw on a **16×16 grid** with **2 px strokes**, avoid 1 px, align to pixels, use one colour.
- **Format.**
  - Up to GTK 4.18, symbolic SVGs must be outlined fills.
  - Since **GTK 4.20 and 3.24.50**, strokes are supported, but only on elements with an explicit class (`foreground-stroke` and so on); "any element that does not have one of these classes is not stroked", and `fill`/`stroke` attributes are ignored ([symbolic-icons.md](https://gitlab.gnome.org/GNOME/gtk/-/blob/main/docs/symbolic-icons.md)).
  - A stock Lucide SVG therefore renders as filled blobs in GTK.
  - Ship **outlined `-symbolic.svg`**, which works on every GTK version, in a GResource under `/<app-id>/icons/scalable/actions/` ([themed icons](https://developer.gnome.org/documentation/tutorials/themed-icons.html)).
- **New direction.** GTK's new icon format and GNOME's symbolic redesign are moving to strokes with a CSS-driven weight (`-gtk-icon-weight`) ([icon-format](https://docs.gtk.org/gtk4/icon-format.html), [GTK blog, Feb 2026](https://blogs.gnome.org/gtk/2026/02/25/an-update-on-svg-in-gtk/)). A stroke-centreline source is the future-proof master here too.
- **Platform icons on GNOME.** adwaita-icon-theme describes itself as a private set for core apps. Third-party apps are expected to copy standard icons from [Icon Library](https://gitlab.gnome.org/World/design/icon-library) or the CC0 Icon Development Kit into their own resources ([adwaita-icon-theme README](https://gitlab.gnome.org/GNOME/adwaita-icon-theme)). "Platform icons for standard actions" on GNOME therefore means *bundled copies of Adwaita icons*, not theme lookups.
- **The 16 px problem.** Lucide's 2 px@24 scaled to 16 px is 1.33 px: blurry and much lighter than Adwaita's 2 px@16. Sets that solve this draw sizes separately (Fluent, Heroicons). **A 16 px master must be drawn, not scaled.**

**Android: VectorDrawable and Compose.**
- VectorDrawable supports `strokeWidth`, `strokeLineCap`, `strokeLineJoin` (defaults butt/miter, so set them) and `trimPath*` for draw animations ([VectorDrawable](https://developer.android.com/reference/android/graphics/drawable/VectorDrawable)).
- Compose's `ImageVector.Builder.path` has the same stroke parameters ([package](https://developer.android.com/reference/kotlin/androidx/compose/ui/graphics/vector/package-summary)).
- Stroke icons convert without loss. Generate them from the same centreline source; no third-party Compose icon library is needed.
- For standard actions, Google now recommends downloading Material Symbols rather than the old `material-icons` artifact ([docs](https://developer.android.com/develop/ui/compose/graphics/images/material)).

**Web.** Inline SVG with `stroke="currentColor"` and a `--westron-icon-stroke` variable. The web has no platform icon set, so **on the web westron's set must also cover standard actions**. Lucide already does.

### 5.3 Recommendation

**Lucide as the base, Tabler as a donor, westron-owned masters.**

Why Lucide:
1. **Stroke-centreline sources make weight a parameter on every target:** the SF Symbols Ultralight/Regular/Black sources via SwiftDraw, GTK's coming stroke weight, Android `strokeWidth` and a CSS variable. Fill-based sets (Material, Fluent, Remix) need hand-drawn masters for every weight.
2. **It has the most precise public design guide**, which westron can adopt verbatim for domain icons, and **it accepts PRs**, so generic icons can go upstream.
3. **It is the most active** (a release every day or two), with good coverage of both everyday and technical domains: list-todo, calendar, notebook, database, server, terminal, table, chart.
4. **Round caps, joins and corners sit well next to SF Symbols** and GNOME's new rounded, stroked symbolics.
5. **The licence is ISC/MIT**: keep the notice in acknowledgements.

Why not the others:
- **Tabler** shares Lucide's grammar (24/2 px/round) and has 3× the glyphs plus filled variants. But new icons come only by request, so it serves as a donor for missing glyphs after a check against westron's rules.
- **Phosphor's** six weights are tempting, but releases stopped in March 2024.
- **Material Symbols** has the best ready exports (SF templates, VectorDrawables, an optical-size axis). It is fills-only, has Google's look and is closed to contributions, so it fits as the *Android platform set*, not as westron's own set.

**How to add westron's domain icons on the same grid:**
- **24 master** (the source of truth):
  - 24×24 canvas, 1 px padding, keylines circle Ø20 and square 18 with rx=2;
  - 2 px centred stroke, round caps and joins, corner radius 2 (1 on small shapes), ≥2 px gaps;
  - modifiers (badges, `-off` slash) in fixed positions, following Lucide/Tabler naming.
- **20 master:** refit to a 20 grid with a 1.5 px stroke, for macOS sidebars and dense web tables.
- **16 master:** redrawn on an integer grid with a 2 px stroke for GNOME (HIG). It is simplified, not scaled.
- **Fill state** only where a selected state needs it: SF `.fill`, GNOME "state 1". Tabler's 1,054 filled icons are references.
- **Outputs from one source:**
  - Apple: SwiftDraw variable template, validated by compiling an asset catalog on macOS CI;
  - GNOME: outlined `-symbolic.svg` from the 16 master in a GResource;
  - Android: stroked VectorDrawable or ImageVector;
  - web: inline SVG.
- **Calibration:** match the Regular stroke against SF Symbols' `circle`, as Apple suggests for custom symbols, so domain icons sit next to system symbols at the same weight.

---

## Recommendations for westron

### Pairings for the specimens

Every pairing uses system body text: SF Pro on Apple, Adwaita Sans on GNOME, Roboto/`sans-serif` on Android, `system-ui` on the web. All the fonts named are OFL 1.1.

| # | Heading font + mono | Character in one line | License | Cyrillic (verified in the files) | Direction |
|---|---|---|---|---|---|
| **A** | **Inter Display** (opsz 32, wght 600–700) + **JetBrains Mono** (`calt` off) | Neutral, engineered, closest to native; the Linear/Atlassian lineage. Brand signal is weak: on GNOME it is almost the body font. | OFL / OFL, no RFN | Inter 248/256, all test languages; JetBrains Mono Russian complete, Kazakh partial | **Cool and precise (quiet)** |
| **B** | **Onest** (wght 600–800, `ss01`/`ss02` to tune apertures) + **Geist Mono** | A friendly hybrid geometric/humanist grotesque, Cyrillic-first, with little brand baggage. Matching x-heights (0.527 / 0.530). | OFL / OFL, no RFN | Onest 162, all test languages; Geist Mono 134, all | **Warm humanist** (alternative: **Golos Text** for a calmer, more "Russian bookish" tone) |
| **C** | **IBM Plex Sans** (Var, wdth 85–100) + **IBM Plex Mono** (Var 1.0) | Industrial and data-first, a single superfamily; digits are tabular by default. Looks like IBM. | OFL with **RFN "Plex"**: use IBM's own builds, no self-made subsets | 192 each, all test languages | **Technical / engineered** |
| **D** | **Geist** + **Geist Mono** | Swiss, crisp and slightly condensed; a superfamily with the most active upstream. Tied to Vercel's look. | OFL / OFL, no RFN | 134 each, all test languages; Cyrillic redesigned in January 2026 | **Cool and precise (sharper, more "dev tool")** |
| **E** | **Unbounded** (large headlines only) + **Martian Mono** (or JetBrains Mono for safety) | Wide, rounded and loud. Martian matches the width and attitude but has no box-drawing characters and lacks Serbian/Kazakh. | OFL / OFL, no RFN | Unbounded 98, no Kazakh; Martian 84, no Serbian/Kazakh | **Bold expressive** (a softer variant: **Rubik**, 176, all test languages) |
| (opt.) | **Literata** or **Source Serif 4** + **IBM Plex Mono** | Editorial, bookish headings over a sans body. Heavy files (221–288 KB on a Russian web page). | OFL | 118 / 150, all test languages | **Editorial** |
| **0** | **All-system:** SF Pro + SF Mono (Apple), Adwaita Sans + Adwaita Mono (GNOME), Roboto + system mono (Android), `system-ui` + an explicit mono stack (web; `ui-monospace` is Safari-only) | Zero cost and maximum native feel, but no brand in the type, and metrics differ across OSes (the reason Atlassian gave for leaving system fonts). | Platform licences; SF is not redistributable | All system fonts above cover Russian | **Baseline variant** |

My suggestion for the three specimens: **A or D** (cool), **B** (warm) and **E** (bold), each next to variant 0. **C** is strong but reads as IBM.

### Cost of shipping a brand font, per platform

| Platform | What it takes | Bytes (heading + mono, Latin+Cyrillic) | Gotchas |
|---|---|---|---|
| **Apple** | TTFs as `WestronUI` resources. One idempotent `CTFontManagerRegisterFontsForURL(.process)` call. `Font.custom(_:size:relativeTo:)` accessors on **static instances** generated at the token weights. A `legibilityWeight` → heavier instance mapping for Bold Text. A snapshot test that the PostScript name resolves. | ≈ 330–730 KB of TTF (B, D ≈ 340 KB; C ≈ 730 KB; A ≈ 1 MB, or ≈ 440 KB with a Display-only Inter instance), about half in the download | No SwiftUI axis API. macOS has no Dynamic Type. A wrong name silently falls back to SF. Keep watchOS all-system. |
| **GNOME** | TTFs into `/app/share/fonts` in the Flatpak manifest. One app-CSS rule on `.title-*`/`.heading`; `.monospace` and `.numeric` for technical views. Outside Flatpak, Pango ≥1.56 `add_font_file` from a file path. | Same files as Apple, ≈ 330–730 KB | No `@font-face`. GResource fonts must be extracted to a file. Inter-based headings are nearly invisible against Adwaita Sans. |
| **Android** | Variable TTFs in `res/font`. `fontFamily` only on M3 Brand roles (display, headline, titleLarge). `fontFeatureSettings = "tnum"` on numeric styles. | Same files, ≈ 330–730 KB | Variable axes need API 26+. Do not rely on downloadable fonts. |
| **Web** | Self-hosted variable WOFF2 split by `unicode-range` (latin, cyrillic, plus the -ext ranges). `@font-face` in a **document-level** stylesheet, because Lit shadow roots ignore it. Preload the primary subset. A `size-adjust` fallback. | **≈ 80–170 KB on a Russian page** (A ≈ 167 KB, B ≈ 88 KB, C ≈ 146 KB, D ≈ 80 KB) | `ascent-override` is missing in stable Safari. Fonts with an RFN need the owner's official subsets. |
| **All** | `OFL.txt` plus the copyright line in every app and package (OFL FAQ 1.20). Pin font versions in `tokens/` and treat updates as reviewed changes. | — | Instancing and subsetting are fine only for fonts without an RFN. |

### Icons

- **Standard actions use platform sets:**
  - SF Symbols on Apple;
  - **bundled copies** of Adwaita icons from Icon Library or the Icon Development Kit on GNOME (the theme itself is private);
  - Material Symbols on Android.
- **Domain icons, and all icons on the web:** westron's own set, built on **Lucide**'s grammar, with Tabler as a donor.
- Keep one stroke-centreline 24 master per icon, with hand-drawn 20 and 16 masters.
- Generate everything from that source: SF Symbol variable templates (SwiftDraw, macOS CI), outlined GTK `-symbolic.svg`, VectorDrawables and inline SVG.
- First step: a spike that runs SwiftDraw's stroke-scaled weights on ~10 Lucide icons and validates them in an Xcode asset catalog.

---

## Not verified, or possibly outdated

- **Golos UI licence and files.** It is not on Google Fonts, and ParaType's page could not be fetched; it is OFL per third-party sources only. The "state-service websites" association of Golos is from its README; the specific site is not confirmed from a primary source.
- **Iosevka** was checked on Fontsource's 22.1.2 build (2023), not on 34.9.1, because the current packages are 177 MB and up. Cyrillic coverage has not shrunk across versions as far as I know, but that is not confirmed.
- **Apple.** Whether `.fontWeight()` drives the `wght` axis of a registered variable custom font. Whether macOS 14's Text size setting affects third-party SwiftUI text. The SF Mono licence text, which ships inside its own download.
- **GNOME.** That GNOME 48+ Flatpak runtimes carry Pango ≥1.56 (inferred from dates). Fontconfig bindings in gtk-rs. The exact mapping of `-gtk-icon-weight` to stroke width.
- **Android.** Whether Pixel apps get Roboto or Google Sans from `sans-serif`. Whether `FontVariation` is still `@ExperimentalTextApi` in the Compose version westron will use.
- **Web.** The current Chrome status of `@font-face` inside shadow roots; the source data is from 2024.
- **Brands.**
  - The fonts used in the native apps of Atlassian, GitHub, Linear, Airbnb (beyond the 2018 statement) and Carbon.
  - Atlassian Sans Cyrillic.
  - Shopify's iOS app font (forum, not staff).
  - Whether logged-in github.com pages load Mona Sans.
- **Icons.**
  - SwiftDraw's output on Lucide icons through Xcode validation, not run.
  - Phosphor weight interpolation compatibility.
  - Material's keyline numbers, taken from snippets and SVG measurement because m3.material.io needs JavaScript.
  - The Lucide count: 2,055 from the repository tree versus 1,808 in a community README.
- **Sizes** are from my subsetting with fontTools: Google Fonts-style ranges, all OpenType features kept, unhinted WOFF2. Real deliveries vary by ±10–20% depending on features kept and hinting. The "deflated in an .ipa/.apk" figures are zlib estimates, not measured app builds.
