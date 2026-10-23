# Cursor Agent A — PR #132 mergeability

Checked 2026-10-23 (local evening of 2026-10-22). V1.0.0 and RC2 remain **NOT READY** and **NOT AUTHORIZED**. B02 stays **CRITICAL**. Source art is **not approved**. This note does not merge, rebase, reset, or approve.

## Classification

**transient GitHub mergeability**

PR #132 is mergeable. There is no source conflict with the current Codex tip, and replaying the story commits onto that tip is unnecessary. No integration branch was created. `eng/cursor-v1-agent-a-story` was not rebased or force-reset.

## Live SHAs

| Ref | SHA |
|---|---|
| Codex PR #123 head, `origin/release/anime-v1-dialogue-and-elemental-performance` | `f3753775df43592b0c29a06d0b8329abfc35164e` |
| Claimed Codex head | `f3753775df43592b0c29a06d0b8329abfc35164e` (same; origin had not moved) |
| Earlier engineering base | `7c25c2996f8adcee97ec2187a14bfc578d8681bf` |
| PR #132 head at this check | `223aad16c7e7aa22c1168848d17fadd1e5b0f7cf` |
| PR #132 base branch | `release/anime-v1-dialogue-and-elemental-performance` |
| GitHub PR `base.sha` / `baseRefOid` | `7c25c2996f8adcee97ec2187a14bfc578d8681bf` (cached; behind the live tip) |
| GitHub `mergeable` | `MERGEABLE` (`mergeable: true`) |
| GitHub `mergeStateStatus` | `UNSTABLE` (`mergeable_state: unstable`) |
| Draft | yes, still open, not merged |

`git ls-remote` and `GET /commits/release/anime-v1-dialogue-and-elemental-performance` both return `f3753775`. The pull-request object still reports `base.sha` `7c25c299`. That pointer is stale metadata. It is not a conflict.

## Why this is not the other three classes

- **Not a real source conflict.** Merge-base of `223aad16` and `f3753775` is `7c25c299`. `git merge-tree --write-tree --name-only 223aad16 f3753775` exited 0 and wrote tree `85e9c21fe9e52d4d80b3cc49a0dfeac7b19a1462`. Overlapping paths: none.
- **Not an outdated-base conflict.** The live dialogue tip is 18 commits ahead of `7c25c299` (hand-repair art, CI mirror pin, tests). Those commits do not touch the five story paths below. A three-way merge onto `f3753775` is clean, so a new integration branch would only duplicate a merge GitHub can already do.
- **Not a stacked-branch block.** #132 targets the dialogue branch, which is #123's head branch. GitHub reports that merge as mergeable. #123 itself is `MERGEABLE` / `CLEAN` and was not merged.

Story commits on #132, both story-only:

- `68780162` fix: advance Story Next Route past the earliest open campaign
- `223aad16` docs: record the story route-advance fix commit

Paths those commits change, and that Codex did not change after `7c25c299`:

- `docs/handoff/2026-10-22/CURSOR_AGENT_A_STORY_HANDOFF.json`
- `docs/handoff/2026-10-22/CURSOR_AGENT_A_STORY_HANDOFF.md`
- `game-godot/scripts/menus/story_campaign_scene.gd`
- `game-godot/scripts/story/v1_campaign_runtime.gd`
- `tools/v1_closure/prove_story_route_advance.py`

## What UNSTABLE actually is

`mergeStateStatus: UNSTABLE` means mergeable with failing checks. Six engineering-wave jobs failed in checkout, not in story tests:

`fatal: No url found for submodule path 'third_party/anyCreature' in .gitmodules`

Then `git` exited 128. The tree contains gitlink `third_party/anyCreature` at `ab5b1ce5c13e632f00f7f7cbfdb7a746e315000d` and has no `.gitmodules`. The same gitlink is on `223aad16` and on `f3753775`. The story commits did not add it.

Failed jobs: wave011 (`39872259977`), wave013b (`39872260034`), wave014 (`39872259888`), wave015 (`39872260218`), wave016 (`39872259831`), wave017 (`39872259955`).

Passed on this head include V1 Story authority (`canon-and-graph`), wave012, wave018, wave019, wave020, taste-gate, animation authority, full-roster staging, both Windows Pilot 0 jobs, and web `ci`. hands-8d2 and the other authored-animation production jobs were skipped.

## Codex tip read (read-only)

`ANI03_RESUME_STATE.md` at `f3753775` records the 8D-2 hand repair and corrected native review as a bounded foundation. Art remains WIP. Forearm caps, Rook cuff/gauntlet interface, and fist/grip acting are unfinished. Not active-CPU, earned, device, or human acceptance. Internal reserve was already under 18 GiB. No merge, release, deploy, or tag.

`artifacts/v1_closure/production_8d/OWNER_REVIEW.md` says the hand-surface repair is not final hand, paired-contact, or full-body art approval. Human art, gameplay, balance, feel, mix, device, and release gates stay false.

`artifacts/v1_closure/production_8d/PRODUCTION_MATRIX.json` has `human_approved: false`. `hands_8d2_scope` says hands remain WIP and records no paired, floor, active-CPU, device, or human acceptance.

No wrist, palm, forearm, Rook gauntlet, grip acting, contact projection, transformation, floor-support, or ultimate art was edited.

## Runtime evidence

1. **Unit/script test — PASS, re-run this turn.** `python3 tools/v1_closure/prove_story_route_advance.py` exited 0 with `STORY_ROUTE_ADVANCE PASS`. It also printed `HUMAN_PLAYTHROUGH false`, `GODOT_IMPORT false`, `SEVEN_EARNED_ROUTES false`, `V1_READY false`, `RC2_READY false`. This does not launch Godot.
2. **Godot runtime test — SKIPPED.** `/System/Volumes/Data` had **12 GiB** available (`df -h`, about 412 GiB used of 460 GiB) before and after the unit script. The reserve is 18 GiB free after any allocation. No Godot import, export, project launch, asset copy, or duplicate checkout was started. `/opt/homebrew/bin/godot` was not executed.
3. **Ordinary input-driven gameplay — not run.**
4. **Complete earned human campaign acceptance — not claimed.** Seven earned human campaigns are not claimed. A checkpoint win was not fabricated because no checkpoint was loaded.

CPU advancement, KO, guard, and throw inspection against 8D-2 was not run. Pose sheets in the 8D-2 review are not earned gameplay.

When free space is at least 18 GiB after the forecast, the existing isolated launcher (separate `user://` identity, not owner saves) is:

```sh
python3 tools/v1_closure/launch_ordinary_review.py \
  --profile agent_a_ember_ordinary \
  --headless --automate \
  --route ember-vale --max-nodes 1 \
  --output artifacts/v1_closure/ordinary_review/agent_a_ember_ordinary
```

A fresh profile should record that Ember is locked until Kaia is earned. Do not pass `--seed-convergence-from` or `--replay` to manufacture a win. That command is still not seven earned human playthroughs.

## Left unchanged

Codex art and the `_anime_v1_closure` worktree, PartyLink and PRs #124–#131, the dirty anime main checkout, the website, the portal, and Thursday Open Lab. #123 was not merged. No force-push and no `--no-verify`.
