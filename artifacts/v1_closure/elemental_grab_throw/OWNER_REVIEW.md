# 8A — nine-fighter elemental grabs and throws

Runtime `d9b4ddc4bb70e62e58cabe11fcfd012a8799343c`, branch
`release/anime-v1-dialogue-and-elemental-performance`, draft PR123 on PR122.
Delivery evidence commits retain identical runtime hashes in
[FINAL_SOURCE_BINDINGS.json](FINAL_SOURCE_BINDINGS.json).
This is a working source increment. **Final acting, native visual quality,
game feel, balance and release approval remain false.**

## Play the source

From this worktree, run:

```sh
tools/v1_closure/play_party_review.command kaia-windrow --body female --opponent juno-spark
```

The existing launcher provides ordinary control against an active CPU, an
isolated profile and a declared review item. It creates no movie/export and
does not touch regular owner saves. Substitute any of the nine canonical IDs,
choose `male` or `female`, or add `--local` for two local players. Review-only
Taunt bindings and item placement remain unchanged; PartyLink/hardware mapping
belongs to the separate universal-input workstream.

A/D move, U grab, J release/throw; directional input chooses the existing
forward/back/up/down throw. Four separate victim Attack/Jump/Grab press edges
reach the existing mash threshold. Hold Grab through the original two-second
auto-release: it now requires a fresh press before another acquisition. L
shields; fresh Perfect Guard still cannot stop a normal grab. Test both sides,
escape, interruptions and temporary forms, then repeat with other fighters.

## What changed

- Mash escape now releases the victim's actual paired owner. It no longer
  emits false escape notifications while leaving the victim trapped.
- A successful grab consumes that move activation once, cancels the victim's
  existing normal/ultimate motion and retires its melee hitbox. Simultaneous
  grabs cannot create a mutual ownership cycle or false post-acquisition whiffs.
- Hurt, stock/respawn, character/reset/position change, actor removal and match
  closure release both references. Cancellation preserves the interrupting state;
  scene teardown does not animate an already detached model. Airborne locomotion
  no longer replaces a legitimate hold with Fall.
- Acquisition preserves the real Grab press edge. Holding the button through
  auto-release no longer reacquires the opponent without another press.
- An actor-owned observer presents attempted catch, elemental hold, real-vector
  release smear, measured-displacement wake and actual queried floor landing.
  It never deals damage, changes velocity or creates a combat result. Existing
  HitResolver/CombatFeedback remains the sole confirmed impact/hitstop/punch owner.
- Each actor has at most two phase-audio voices, reusing verified original
  elemental WAVs. Full/Balanced/Reduced, reduced flash/density, high contrast,
  scene pooling and match-end retirement remain active. No new audio binary,
  licensed sample, voice, combat delay, flash or camera impulse was introduced.

## Full-roster coverage

All rows have 16 grounded body/facing/direction ownership fixtures, six existing
form contexts, three accessibility presentations and a public held-button case.
These are separate scoped matrices, not an exhaustive form×body×facing product.
Both actual body model resources loaded. Native appearance/retargeting quality
is not established by loading them. [ROSTER_MATRIX.json](ROSTER_MATRIX.json)
separates implemented, engine verified, playable candidate, blocked and approved.

| Fighter | Original shape grammar | Active CPU throw contacts / 300 frames | Dedicated hold/victim art |
|---|---|---:|---|
| Ember | Turbulent combustion | 8 | Pending, both rigs |
| Rook | Compression fractures | 6 | Pending, both rigs |
| Juno | Branching voltage | 5 | Pending, both rigs |
| Kaia | Open pressure crescents | 8 | Pending, both rigs |
| Nix | Faceted crystal lances | 7 | Pending, both rigs |
| Orion | Collapsing orbital nodes | 7 | Pending, both rigs |
| Vesper | Dislocated phase seams | 8 | Pending, both rigs |
| Yin | Subtractive aperture | 8 | Pending, both rigs |
| Yang | Constructed hexagonal radiance | 7 | Pending, both rigs |

All nine opponents issued actual CPU moves. No AI, damage, control state or battle
outcome was forced during those observations. The 64 contacts do not establish
combos, unavoidable loops, earned KOs or human visual approval.

Legacy BASE/advancement ladders and three temporary Party contexts passed 54
grab/release fixtures, including fresh guard. Yin/Yang retain their own
BASE/COSMIC_SURGE/COSMIC_ASCENDANT ladders and Party identities; ordinary Story
Essence/Puppet/Gray progression and cosmic-boss immunity were not granted.
Story-specific forms, boss situations and all airborne body/form combinations
still need representative runtime acceptance. No unlocks or receipts were seeded.

## Evidence and limits

[VALIDATION_SUMMARY.json](VALIDATION_SUMMARY.json) links eight passing current-runtime
regressions: throw39, ultimate-grab interruption9, guard exceptions20, Party
lifecycle10, projectile ownership18, charge9, Story ownership8, and Story authority
8 routes/16 stale acknowledgments. An additional54-case shared renderer saturation/
accessibility regression passed across all18body resources. Party expiry remains exactly600ticks and
Story memory/signed-save preservation passed. This is not seven earned campaigns
or a new full save/restart playthrough.

New fixtures: 144 ownership-candidate configurations; 15 lifecycle rows plus an
actor-removal check; 27 effect/accessibility contacts, with21 real surface landings;
54 form contexts; nine fresh-input/timed-release cases; nine active CPU observations.
Earlier candidate runs retain their own dirty-source hashes/IDs. Current-source
39-policy and27 presentation tests are separate from the earlier144 matrix.

Original failures, input-fixture false starts, a corrected parser error and a
corrected teardown animation error are retained. Accepted logs have no script or
shader errors; shutdown ObjectDB/resource warnings remain. They are not a leak-free
acceptance claim. The headless shader meshes/audio were instantiated and played;
their pixels and mix were not owner reviewed.

[PRESERVATION.json](PRESERVATION.json): all216 BASE move records,18 original Blender
rigs,18 BASE models, and five damage/throw/aura/Party/guard authority files match
the protected checkpoint. No Blender/GLB or character proportion changed. The
historical BASE aura double-pass remains the existing opt-in tuning decision.
Hitboxes, damage, launch, hitstop, move timing, default items and PG4/24 rules
were not retuned.

[PERFORMANCE_SCOPE.json](PERFORMANCE_SCOPE.json) records headless renderer-update
instrumentation: median11µs,95th percentile27µs, maximum215µs in that sample.
These are CPU update measurements, not GPU/native sustained FPS or device results.
[CI_d9b4ddc4.json](CI_d9b4ddc4.json): six successful exact-runtime checks; Windows2025
was still running. Read the final draft head's live Actions status separately.

## Remaining production work

The [18-rig source contract](../../../../docs/art/ELEMENTAL_GRAB_THROW_8A.md)
lists exact Blender, GLB and rig-specific JSON paths. All nine need dedicated
physical hold, victim restraint/escape, directional release/reaction, support-foot
exchange, landing and hair/cloth/accessory acting. Only Kaia/Juno's four rigs have
the inspected directed grab/throw WIP amendments; none has final dedicated hold
or victim acting. Shape fields and existing clips are not final character art.

[STORAGE.json](STORAGE.json): internal free about11.86GiB, below18GiB plus anticipated
allocations. No new native movie, Blender/GLB export, platform build, deletion,
worktree move or duplicate archival was performed. All33 worktrees and protected
evidence remain. Existing868-frame/647-match ANI03 media keeps its original source
IDs under `spectral_feedback/continuous_1020/final_contact/`; it does not demonstrate
this new8A source. New native visual/audio review remains pending.

Next production category: author distinct supported `grab_hold` and victim
held/escape actions on all18 original rigs using the established directed
Blender-action→runtime-JSON boundary, preserving frame-zero throw release. Perform
binary production/native review only when the reserve plus estimated peak allocation
is available. Owner can review the source interactively now without recording.

Universal Input/PartyLink transport and real LAN play, physical devices, final
OVA/acting, all earned Story routes/Convergence and release acceptance remain
separate unfinished dependencies. No merge, release, tag, deploy or publication.

For the separate replay/PartyLink integration: preserve the paired actor IDs,
MoveRunner activation/target ledger, `_grab_acquisition_activation`,
`_grab_whiff_activation`, input edges, throw latch, mash and hold elapsed time
in any future combat restore. Rebuild presentation from owned events; do not
restore a visual effect as a damage event. Current input checksum machinery is
not proof of live fighter-state rollback or LAN acceptance. This increment
does not modify transport, hardware mappings or the input resolver.
