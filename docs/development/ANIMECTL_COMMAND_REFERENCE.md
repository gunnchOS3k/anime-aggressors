# Animectl command reference

```bash
./animectl --help
./animectl <command> --help
```

Global flags (before or after subcommand): `--json` `--output <path>` `--exact-head` `--no-color` `--verbose`

## Exit codes

| Code | Meaning |
|------|---------|
| 0 | success |
| 2 | invalid arguments |
| 3 | environment/tool missing |
| 4 | validation failure |
| 5 | build failure |
| 6 | runtime/e2e failure |
| 7 | physical device unavailable |
| 8 | signer/install safety block |
| 9 | stale evidence / exact-head mismatch |
| 10 | external dependency block |

## Commands

| Command | Purpose |
|---------|---------|
| `doctor [--safe-clean]` | Toolchain + disk; optional regenerable cache clean |
| `audit` | Code-backed runtime map |
| `inspect runtime --fighter <id> --body <male\|female>` | Model provenance contract |
| `verify <animations\|moves\|models\|story\|determinism\|partylink\|all>` | Wrap validators |
| `acceptance --exact-head [--quick\|--full]` | Exact-head acceptance board |
| `story <status\|reset\|route\|state\|unlock-cosmic>` | Isolated test-profile QA helpers |
| `build <web\|android\|all>` | Wrap canonical builds |
| `android <doctor\|build\|install\|smoke\|evidence>` | ADB/Maestro surface |
| `play` | Dev play hints |
| `capture <roster\|story\|fighter\|acceptance>` | Evidence dirs under `.acceptance/` |
| `art <doctor\|validate\|build>` | Blender pipeline wrappers |

## Model kinds

`AUTHORED_GLB` · `GENERATED_LOW_POLY` · `DEBUG_FALLBACK` · `MISSING`

Acceptance requires `model_kind=AUTHORED_GLB` and `fallback_used=false` for all 18 presentations.
