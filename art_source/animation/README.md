# Authored Animation Source

**Authority:** `artist-authored source → export → Godot import → runtime mapping`

This tree is the path that may be labeled human-authored animation.

Current shipping presentation on accepted `main` remains `CURRENT_ACCEPTED_ART`
(procedural production proxy). Generated V2–V9 art from PR #106 is
`GENERATED_EXPERIMENT` and does not ship from this branch.

## Provenance labels

| Label | Meaning |
|-------|---------|
| `CURRENT_ACCEPTED_ART` | What accepted main already ships. |
| `HUMAN_CANDIDATE` | Imported to staging. Not approved. |
| `HUMAN_APPROVED` | Owner set this. Automation never writes it. |
| `GENERATED_EXPERIMENT` | PR #106 V2–V9 research. Not production. |
| `PROCEDURAL_FALLBACK` | Scripted clips / proxy. Useful, not authored. |
| `MISSING` | Defined, not delivered. |

`HUMAN_*` and `MERGE_AUTHORIZED` stay **false** until a human sets them.
