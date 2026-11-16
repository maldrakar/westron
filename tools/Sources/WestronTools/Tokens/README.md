# The DTCG subset westron reads

The code in this folder reads the part of DTCG 2025.10 (the Format, Color and Resolver modules) that westron uses
(decisions/0004, 0010). Anything outside it is an error that names the file and the token, group or place in the
resolver, never skipped. `tools/westron tokens check` runs the whole pipeline over `tokens/westron.resolver.json`;
`tools/check.sh` runs it too.

| Step | Code | What it does |
|---|---|---|
| Parse | `JSON.parse` | RFC 8259 JSON; keeps keys in document order; a duplicate key is an error |
| Read the resolver | `ResolverDocument.load` | Sets, modifiers, `resolutionOrder`, with the references between them resolved |
| Read a token file | `TokenTree.load` | Names, properties, the syntax of every value and the `dev.westron.*` keys; inheritance within the file |
| Official schemas | `TokenSchema` | The DTCG JSON Schemas from `tools/Schemas/dtcg-2025.10/`, for files the reader accepts |
| Load a resolution | `Resolution(resolverFile:)` | The resolver and its token files; no two modifiers set the same token |
| Resolve an input | `Resolution.resolve(_:)` | The sources of the input merged in order (`TokenTree.merge`), then every reference (`TokenTree.resolve`) |

## Token files

| `$type` | `$value` | Read into |
|---|---|---|
| `color` | `colorSpace` (all 14 spaces of the Color module), `components` (3 numbers or `"none"`, in the range of the space), optional `alpha` in [0, 1] (default 1), optional `hex` `#rrggbb` | `TokenValue.Color`, not converted |
| `dimension` | `{ value, unit }`, unit `px` or `rem` | `TokenValue.Dimension` |
| `number` | a number | `Double` |
| `duration` | `{ value, unit }`, unit `ms` or `s` | `TokenValue.Duration` |
| `cubicBezier` | `[x1, y1, x2, y2]`, x in [0, 1] | `TokenValue.CubicBezier` |
| `fontFamily` | a name or a non-empty list of names | `[String]` |
| `fontWeight` | a number in [1, 1000] or a name (`bold`, `semi-bold`, …; case-sensitive) | `TokenValue.FontWeight`, the number and the name |
| `typography` | `fontFamily`, `fontSize`, `fontWeight`, `letterSpacing`, `lineHeight` (a number), all required | `TokenValue.Typography` |
| `shadow` | one shadow object or a non-empty list; `color`, `offsetX`, `offsetY`, `blur`, `spread`, optional `inset` | `[TokenValue.Shadow]` |
| `transition` | `duration`, `delay` (durations) and `timingFunction` (a cubic Bézier), all required | `TokenValue.Transition` |

- **Groups**: nested groups, empty groups, `$type` inherited by the tokens inside, `$description`, `$deprecated`
  (inherited; `false` cancels a group's), `$extensions` kept as raw JSON on tokens and groups. `$schema` is allowed
  at the root of a file.
- **Names**: not empty, no `{`, `}` or `.`, not starting with `$`. Spaces, `/` and other characters are fine.
- **References**: `{group.token}` to a whole token, as a whole `$value` or as a sub-value of a composite type
  (a typography, shadow or transition property, an element of a shadow list). Chains are followed. A reference
  token without `$type` takes its target's type. Errors: a missing token, a group, a path into a token's value, a
  cycle (reported once with the whole cycle), a target of another type. A reference elsewhere inside a value, such
  as a color's `alpha`, is an error, as in DTCG.
- **Merge** (`TokenTree.merge`, the Resolver module's "later source wins"): a later token replaces an earlier one at
  the same path whole; groups merge name by name, and a group property the later group sets wins.
- **Order**: tokens come out in document order. In a merged tree a name keeps the position of its first occurrence,
  and new names follow in the order of the later file. Paths sort name by name (`TokenPath` is `Comparable`).

## westron's `$extensions` keys

Read into `WestronExtensions` on each token (decisions/0010). Any other `dev.westron.*` key is an error, so a
misspelled key fails; other vendors' keys pass through in `extensions`. westron's keys go on tokens, not on groups.

| Key | Shape | Only on |
|---|---|---|
| `dev.westron.usage` | `{ "use": [string, …], "avoid": string }`, both required | any token |
| `dev.westron.contrast` | `[{ "kind": "text" \| "large-text" \| "non-text" \| "separator", "on": [background, …] }, …]`; a background is a path or a stack of paths, top first | color tokens |
| `dev.westron.apple` | `{ "textStyle": largeTitle, title1, title2, title3, headline, body, callout, subheadline, footnote, caption or caption2 }` | `textStyle` on typography tokens |
| `dev.westron.spring` | `{ "duration": seconds above 0, "bounce": -1…1 }`, both required | transition tokens |

The paths of `dev.westron.contrast` are whole token paths without braces, `color.background.canvas`, as in
decisions/0012. Each must name a color token in the same resolution, so a background missing from one theme fails
in that theme. The contrast check (#15) reads the same declarations and computes the ratios.

## The resolver file

| Supported | Rejected |
|---|---|
| `version` `2025.10` (required), `name`, `description`, `$schema`; `$defs` is ignored | Any other root property |
| `sets`: `sources` of token files and inline tokens; a set may refer to another set (`#/sets/<name>`) | A set or a context referring to a modifier; references into `resolutionOrder` |
| `modifiers`: `contexts` (at least two; an empty context is allowed), `default`, `description`, `$extensions` | A modifier with one context, a `default` that is not a context |
| `resolutionOrder`: `{ "$ref": "#/sets/<name>" }`, `{ "$ref": "#/modifiers/<name>" }`, inline sets and modifiers with `type` and `name`, names unique | — |
| Token files by a path relative to the resolver, inside its directory | Remote URLs, fragments (`file.json#/…`), absolute paths, `..`, other pointers (`#/$defs/…`), a reference object with keys besides `$ref` (Resolver 4.2.2), a file in `resolutionOrder` |

- **Inputs** name a context per modifier; a modifier the input does not name takes its `default`. An unknown
  modifier, an unknown context, or a missing modifier without a default is an error. Inputs are case-sensitive
  (the Resolver module allows either).
- **Orthogonality** (decisions/0010): no token path is set by the contexts of two different modifiers. `Resolution`
  checks it on loading, over all contexts, and names the path, both modifiers, their contexts and files. A modifier
  may override a set.
- **All inputs**: `Resolution.inputs` is every combination of contexts, the first modifier varying slowest;
  `resolveAll()` reports a problem once, saying in which inputs it occurs when not in all.

## Rejected as unsupported in token files

| Feature | Instead |
|---|---|
| Group `$extends` | Write the tokens out, or alias them |
| `$root` tokens and references to them | Give the token a name |
| JSON Pointer references: a token's `$ref`, `{ "$ref": "#/…" }` inside a value | A curly-brace reference to a whole token |
| Types `strokeStyle`, `border`, `gradient` | Add the type to the reader and to this file when a component needs it |

## Stricter than DTCG, on purpose

- What a token inherits from its groups (`$type`, `$deprecated`) comes from the groups of its own file: merging
  another file never retypes a token, and each file is valid on its own.
- A group's `$type` applies to references in it too (as in Format 6.7.3): a reference in a `color` group must point
  at a color. Format 5.2.2 would give such a token its target's type.
- A token in one file and a group at the same path in another is an error, not "the later one wins".
- A duplicate key in a JSON object is an error; JSON parsers usually keep one of the two silently.
- A font name in a list cannot start with `{` or end with `}`, and cannot be empty.
- Nesting deeper than 64 levels is rejected.
- `tools/westron tokens check` also fails on a token file in the resolver's directory that the resolver does not use.

## The official schemas and their validator

The DTCG schemas are draft-07 and swift-json-schema 0.15 implements draft 2020-12; the doc comment of
`TokenSchema` says what that costs, and `TokenSchemaTests` and `ResolverSuiteTests` pin it against the DTCG test
suite. For token files, tuple-form `items` is ignored, so the schema does not check the range of each color
component or cubic Bézier coordinate; the reader checks them, and it rejects every invalid fixture of the test suite
on its own. For resolver files, the schema agrees with every fixture it can decide alone; the reader checks the
rest (cycles between sets, unique names).

One defect is in the format schema itself: a font weight *name* whose `$type` comes from its group fails it, because
the schema matches a value without its own `$type` against every type and the name is also a valid font family. So
in westron files **a font weight name carries its own `$type`**: `"bold": { "$type": "fontWeight", "$value":
"bold" }`. A number needs nothing.

## Adding a type or a feature

1. A case in `TokenType`, the value in `TokenValue`, reading it in `ValueDecoder`; remove it from `Unsupported`.
2. Tests in `tools/Tests/WestronToolsTests/`; move its DTCG fixtures out of `TokenSchemaTests.outsideSubset`.
3. This file.
