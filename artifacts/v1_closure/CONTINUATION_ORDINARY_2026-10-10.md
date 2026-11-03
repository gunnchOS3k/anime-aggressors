# Ordinary playability and renderer review checkpoint — 2026-10-10

Continue only from draft PR #122 on `release/anime-v1-canon-and-campaign`. Tested gameplay/render source is `83bab0825230154761b39e1a7ff63eeacf66de8d`; subsequent capture/package commits do not change game rules or art. Runtime stamp remains this tested source. This completed the requested ANI-01/02 ordinary-playability/review package; stop here rather than starting ANI-03/04/05.

## What now passes

Fresh separate profile `kaia_targeting_final_20261009` earned all 20 Kaia nodes and 16 genuine BattleScene receipts using public normal inputs. Initial process earned three encounters; new process resumed that earned prefix after real losses, completed remaining encounters and Next Route selected Ember. No position, damage, health, stock, immunity, AI, KO, save or result injection. Essence 1→2→4→6, Gray and ending are earned; only one Gray route, so Convergence/Yin/Yang remain locked. Current native replay loaded this exact completion and did not alter earned progress/receipts/unlocks. Full evidence is under `ordinary_review/kaia_targeting_final*` and `render_83_kaia`.

Juno `kaia08_20261009` earned 11 ordinary chapters in the earlier input run. Current source `render_83_juno` replays its earned First Loss: Shield chooses ESCORT_TEAM, five companions and two forward signals, Orion remains the approved route-local loss. Orion's ultimate fate remains unresolved.

`convergence_targeting_20261009` explicitly seeds the seven Gray prerequisites from authenticated STAGED source evidence, then clears Convergence. Five Convergence nodes pass normal input mechanics, including seven actual trial KOs and both cosmic opponents hitting the player during seven guard alternations. `render_83_convergence` is also labeled seeded prerequisites. Its cosmic unlock does not prove seven ordinarily earned routes.

Scoped staged regressions: 145 nodes/115 receipts/seven Gray/five Convergence, all seven watch paths, save/receipt semantic negatives, independent persisted receipts, replay prior-state reconstruction, 18 BASE presentations, seven unique approved First Loss mappings and focused hit/block/action-lock/cosmic targeting. Exact source/report hashes in `ordinary_review/technical_regression.json`. WAV/playback shutdown leaks and headless speech/unknown cosmic announcer data remain logged; no acoustic acceptance.

## Owner entry point

`ordinary_review/OWNER_REVIEW.md` contains controls, objective matrix, evidence boundaries and human checklist. `ordinary_review/CAPTURE_INDEX.md` links native PNGs and short silent 10fps MP4 samples from the current Godot renderer. Raw frames are locally retained, ignored by Git, never deleted. Clips are chapter replays, not a continuous final OVA or live performance recording.

Double-click `tools/v1_closure/owner_play_review.command`, or run:

```sh
python3 tools/v1_closure/launch_ordinary_review.py --profile owner_kaia_review_20261009 --output /private/tmp/aa-owner-human-review-20261009
```

Without --automate, this launches actual BootScene for human input with all user:// state redirected before autoloads into a separate review application identity. Production owner saves remain untouched. Use `--profile kaia_targeting_final_20261009` for the earned automation review save, not a human-earned claim. Replays cannot mint progress.

## Exact remaining boundary

No known Kaia objective-mechanic blocker remains in the successful ordinary run. Owner human play, difficulty/pacing/readability approval, six other complete ordinary routes and fully earned ordinary Convergence remain open. Current character overlaps, companion bunching and simple stage geometry are visible presentation limitations. Seven human gates and V1_AUTOMATED_READY remain false.

ANI-03: unique competitive/boss Yin/Yang kits, full form lifecycle, authored animation/expression/secondary motion, VFX/audio timing/mix. ANI-04: continuous final OVA and variations, final screenplay/acting, voices/music/transitions. Supplied 145-node/1025-cue production pack inspected read-only; embedded TTS instructions were not invoked. ANI-05: exact-source packed/Web/Android exports and real device acceptance once ≥18GiB guard restored. Do not delete uncertain outputs to recover space.

All 33 original worktrees preserved and backup manifest SHA256 remains `1d0cf84125d2dbcb82ef9ba79aeb6852829415e20c5dba2951f886c98880147d`. See current disk inventory; only ~88MiB scoped reproducible imported caches identified, no deletions, insufficient for 18GiB guard. Historical exports/evidence/art retained. No merge/deploy/tag/publication/new large export.

Source CI snapshot distinguishes completed checks from Windows Pilot 0 Windows 2025 evidence pending; the Windows latest success is compatibility-note-only. Recheck latest PR head before any future work. Do not turn a pending CI job or source-scene evidence into exported-platform acceptance.
