# DTCG 2025.10 schemas

The official JSON Schemas of the DTCG 2025.10 Format and Resolver modules, which `tools/westron tokens check`
validates token files and the resolver file against (`TokenSchema` in `tools/Sources/WestronTools/Tokens/`). Do not
edit them: replace them with a newer copy.

| | |
|---|---|
| Source | https://github.com/design-tokens/community-group, `schemas/src/2025.10/`: `format.json`, `format/`, `resolver.json`, `resolver/` |
| Commit | `882ebd6716abef9a46d8ef5fb12e82009d6cee2e` (main, 2026-11-15); the schemas last changed in `11f95e8770` |
| Version | DTCG Format and Resolver 2025.10; every file has `$id` `https://www.designtokens.org/schemas/2025.10/…` |
| Dialect | JSON Schema draft-07 (`$schema` of every file) |
| License | W3C 3-clause BSD License, see `LICENSE.md` |

These are the split source files, not the single-file bundles published at
https://www.designtokens.org/schemas/2025.10/format.json and `…/resolver.json`. The bundles are built from them; the
only difference is that they drop `description` annotations next to `$ref`. swift-json-schema cannot use the bundles:
it supports draft 2020-12 only, and the bundles embed the schemas under the draft-07 keyword `definitions`, where
2020-12 does not look for `$id`. `TokenSchema` registers each source file under its `$id` instead. What the validator
still misses, and how the reader covers it: the doc comment of `TokenSchema`.

To update: copy `format.json`, `format/`, `resolver.json` and `resolver/` from `schemas/src/2025.10/` at a newer
commit, update the table, and run `tools/check.sh`; `TokenSchemaTests` and `ResolverSuiteTests` show what changed
against the DTCG test suite.
