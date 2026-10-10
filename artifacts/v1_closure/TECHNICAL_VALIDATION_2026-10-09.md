# Campaign source validation — October 9, 2026

Tested gameplay source: `30ea37f5e653357bc4ca2b6867d05cc221429b19`.
Start: `codex/anime-v1-closure-2026-10-06` at
`e063b13bcb293ad3ac7b8673c82d8830f8e0b24d`.
Implementation branch: `release/anime-v1-canon-and-campaign`.
Draft PR: https://github.com/gunnchOS3k/anime-aggressors/pull/122

| Check | Result | Evidence scope |
|---|---|---|
| Canon and graph validators | PASS | Seven approved unique losses; all 145 executable contracts; reproducible compiler |
| Godot 4.7.1 editor import | PASS | No script/parse errors; platform/sandbox warnings retained |
| FullCampaign | PASS, 145/145 | 115 real BattleScene receipts; seven Gray completions; five Convergence nodes; both Yin/Yang unlocks |
| CampaignRestart | PASS | Separate process loads all 145 signed completions; seven watch paths cannot mutate progress; earned Gray skin retains move manifest |
| FirstLossFraming | PASS, 7/7 | Distinct lost actors/positions/cameras; live player controls; Juno's five remaining team actors; no renderer capture |
| CampaignCheckpoint | PASS, 49/49 | Opening encounters, actual replay loss/result, save/reload/idempotence and negative cases |
| OwnerOverrideRuntime | PASS | Seven real elapsed two-cosmic survival paths and seven watch paths |
| CombatActivation | PASS | Real activation, hit/block/recovery and contact-feedback regression |
| ShippingRosterPath | PASS, 18/18 BASE | Existing male/female selection, controls, resolved contact, staged KO, results/rematch/return |
| Model structural checks | PASS, 64/64 | Preserved GLB hashes/skins/candidate slots; no asset regeneration |

FullCampaign, Restart, Framing and import use exact source `30ea37f5…`.
Opening/owner/combat/roster regressions use `c2bdf288…`; subsequent source changes
add First Loss camera/pose framing and scoped authority CI. All per-test exact SHAs,
source file SHA256s and evidence links are in `technical_validation_2026-10-09.json`.

The staged automation uses protected players, positioned collision contacts and
blast-zone KO fixtures. Outcomes pass through the bound BattleScene; normal-mode
receipt qualification is engine behavior, not human acceptance. Negative checks
cover token-only result forgery, edited signed envelope, malformed save, signed
sparse prefix, signed nonqualifying review completions, real replay loss and
idempotent receipts. Atomic reload is exercised after every node. Debug/review/eval
and watch paths cannot earn Gray/cosmic unlocks. Legacy unsigned saves are retained
as `.legacy` before overwrite and require authenticated replay.

Godot logs retain macOS CA lookup errors, sandbox settings/achievement persistence
warnings, and shutdown ObjectDB/resource warnings. The final full sweep has no
script/parse errors; shutdown cleanup warnings remain unresolved. Earlier failed
development helper output is retained under `history/2026-10-09` and is explicitly
excluded from the final passing evidence.

No current packed/Web/Android artifact was generated or tested. No current
real-renderer Story cinematic capture, PartyLink cross-device regression, ordinary
human full playthrough or final presentation acceptance was run. Disk capacity is
approximately 7.3 GiB, below the 18 GiB heavy-generation/export guard.

Historical owner-review PCK source is `ce2775f1fddc725c4cad639ef03d87666ec6d003`,
93,426,580 bytes, SHA256
`a62f4458506dc66d5fcd7eaf088148a1e8edc9e57d696e83e2e123a14c3435dc`.
Its hash was reverified; its narrower October 6 probes do not prove this campaign.
Generated local `build_identity.json` remains ignored by repository policy; the
tracked source validation identity records the current source stamp separately.

All owner/human gates and `V1_AUTOMATED_READY` remain false. See
`CONTINUATION_2026-10-09.md` for the precise unfinished gameplay, ANI-03/04/05 and
owner review work. Original worktrees/assets/backups remain preserved.
