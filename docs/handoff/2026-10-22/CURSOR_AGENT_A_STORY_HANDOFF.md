# Cursor Agent A — Story route advance

Runtime fix commit: `68780162c5a9a8a11157d8e28eb8e836ef41a3d5`. The branch tip is `git rev-parse HEAD` on `eng/cursor-v1-agent-a-story`.

V1.0.0 and RC2 remain **NOT READY** and **NOT AUTHORIZED**. This draft does not merge, deploy, tag, or approve.

## What changed

Story menu **Next Route** walked `campaign.routes` from the start and selected the first incomplete available route. After Kaia is complete and the six variations are open, a player already on Rook was sent back to Ember. Further presses stayed on Ember. Juno, Nix, Orion, Vesper, and Convergence could not be reached with that control.

`CampaignRuntime.next_incomplete_route_id()` now walks forward from the selected route and wraps. A completed selected route still opens the first incomplete route, which keeps the existing Kaia-complete check (leave Kaia for Ember).

No screenplay, dialogue, essence ownership, combat numbers, shield-break default, art, audio, PartyLink, or input map edits.

## Baseline

Command, run against `v1_campaign.json` route order before the fix, with Kaia complete and Rook selected:

```text
LEGACY_NEXT ember-vale
LEGACY_WALK ['ember-vale', 'ember-vale', 'ember-vale', 'ember-vale', 'ember-vale', 'ember-vale']
```

After the fix the same case walks:

```text
FIXED_WALK ['juno-spark', 'nix-calder', 'orion-vell', 'vesper-nyx', 'ember-vale', 'rook-ironside']
```

Proof command, from this worktree:

```sh
python3 tools/v1_closure/prove_story_route_advance.py
```

Result: `STORY_ROUTE_ADVANCE PASS`. That script also checks the campaign file: 145 nodes, seven 20-node routes, 16 battles each, seven distinct First Loss identities, and six essences before each prismatic node. It does not play the game.

## What this does not prove

- No Godot import, export, or headless BattleScene run. Internal free space was about 15 GiB, under the 18 GiB reserve.
- No seven earned human playthroughs. `human_playthrough` stays false. Kaia's earlier 20-node / 16-battle ordinary evidence is still one route.
- Kaia's second advancement remains the prior bounded CPU observation (first stage only in that 720-frame recipe). This change does not grant a combo or a second form.
- #124 shutdown audio and #125 form GLB sidecars are reused as findings, not redone. #126–#130 were not edited.

## Owner saves

Not opened and not written. Observed mtimes, unchanged:

- `aa_save.cfg` 2026-10-01 14:35:37
- `green_between_progress.json` 2026-10-01 09:08:35
- `achievements_v1.json` 2026-10-01 14:35:37

No `user://anime_v1_campaign.json` was present in the Anime Aggressors Godot user directory at check time.

## Next command not started

When `df -h /` shows at least 18 GiB free after forecast, run one isolated ordinary-input pass of a non-Kaia route. Do not use the owner user directory.

```sh
python3 tools/v1_closure/launch_ordinary_review.py \
  --profile agent_a_ember_ordinary \
  --headless --automate \
  --route ember-vale --max-nodes 1 \
  --output artifacts/v1_closure/ordinary_review/agent_a_ember_ordinary
```

That still is not seven earned human playthroughs. Variations stay locked until Kaia has an earned Gray route, so a fresh profile should record `Requested route is locked: ember-vale` unless a separate earned-Kaia save is supplied on purpose and labeled as seeded.
