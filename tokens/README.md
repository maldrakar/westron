# Tokens

westron tokens in the DTCG 2025.10 format (`*.tokens.json`) and the mode resolver: theme, contrast, density,
platform (decisions/0004). They will appear in phase 1 (issues #10–#13).

Two levels: primitive tokens and semantic tokens. Everything DTCG lacks (spring animation, platform mappings,
usage rules for the agent) lives in `$extensions` under the `dev.westron.*` key. From these files the
generators in `tools/` produce code for the platforms; generated files are not edited by hand.
