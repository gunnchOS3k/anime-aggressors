# Live audio routing and diagnosed causes

Prior checkpoint: Fighter._start_move_dict played collectible whiff/super-startup at input, CombatFeedback.apply_hit played collectible tier impacts first. The v3 resolver was a fallback, so a correct element string or v3 WAV did not prove that sound played. Aura code only set _aura_sfx_hook=true and never played charge audio. Projectile had visual configuration and collision callbacks but no launch/travel/dissipation audio. AudioDirector.stop_music stopped every bank player, including effects. Embedded GLB clips took precedence over procedural JSON, so changing JSON alone could leave the old arm-swing performance visible.

Current runtime:

| Trigger | Live route | Loaded asset / lifecycle |
| --- | --- | --- |
| Enter aura charge | Fighter._set_aura_vfx → ElementalPerformance.update_charge | fighter charge_start.wav, one owned charge_loop.wav |
| Sustain / full | repeated update_charge | gain follows existing aura meter; exactly one charge_ready.wav at 100 |
| Release / burst | Fighter state transition | stop owned loop, charge_release.wav |
| Hit / jump / cancel | Fighter state transition / jump cancel | stop owned loop, charge_cancel.wav |
| Projectile first active frame | existing ProjectileSpawner → configure | projectile_launch.wav plus one owned projectile_travel.wav |
| Projectile hit | unchanged HitResolver → CombatFeedback | original impact plus attacker projectile_impact.wav |
| Environment contact | existing body_entered observation | attacker projectile_impact.wav; collision authority unchanged |
| Block | unchanged HitResolver → CombatFeedback | original defender shield sound plus attacking fighter block.wav |
| Expire / hit completion | Projectile._expire | stop owned travel through node lifetime, projectile_dissipate.wav |
| Signature first active frame | Fighter._on_move_active | fighter signature_release.wav once; plays on hit or miss |
| Heavy / super impact | CombatFeedback → V1CandidateSfx | preserved original punch/impact plus heavy.wav / signature.wav |
| Missing required layers | returned playback result / regression | no silently invented element assignment; surfaced missing_stream |

Layer files live under assets/audio/elemental_v1/<fighter>/<event>.wav. Catalog and separate body/texture/transient stems include hashes, sample rates, peaks and provenance. All are original deterministic synthesis with zero third-party samples and no paid service. The repository MIT license applies to newly authored project material.

Mix: retained impact at existing level, added layers at conservative gain, independent element-layer/voice/music settings, and Master hard limiter ceiling -1 dB. New layered assets have peak headroom of at least 3 dB. Music stop now filters music-tagged players. Owned loops inherit scene pause/lifetime. Final speaker/listening/mix acceptance remains an owner gate.

Before/after clips use the same normal-input capture driver. Baseline overlay reads the preserved c5f3be23 scripts/project config into a small temporary wrapper; it does not reset or add a worktree. Final clips must report current source SHA/diff hash and both real video/audio streams. Failed early pilot with inactive CPU is excluded from acceptance evidence.
