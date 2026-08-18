# 6G workload relevance — Anime Aggressors

This product is a **game / interactive workload**, not a RAN research result.

The notes below describe **measurable latency, QoE, and traffic characteristics** a lab could observe if this client ran on an instrumented link. They are **not** a 6G dissertation contribution, not a beam-selection result, and not evidence for research questions in the telecom spine.


## What this client is

Local 2D/3D platform-fighter simulation at ~60 Hz with optional touch overlay and Android export. Online rollback is **not** the shipping path (`game-godot/scripts/net/` is architecture, not a live 6G stack).

## Measurable characteristics (lab, if instrumented)

| Quantity | Where it lives | Typical digital observation |
|---|---|---|
| Input-to-hitstop latency | `scripts/combat/move_runner.gd` + `hit_resolver.gd` | Frame-quantized (16.7 ms at 60 Hz) plus render delay |
| Simulation tick | `FighterStateMachine.update` | Fixed combat frames, not wall-clock 6G slots |
| Android touch sampling | `scripts/input/touch_input_manager.gd` | Extra OS/input jitter vs keyboard |
| Audio start delay | `scripts/audio/AudioDirector.gd` | Procedural SFX; acoustic device output is PHYSICAL_PENDING |
| Export package | `com.gunnchos.animeaggressors` | Distinct from other gunnchos games |

QoE for a fighter is “did the hit confirm on the intended frame,” not spectral efficiency.

## What this is not

- Not a contribution to 6G air-interface, RIC, or NTN papers
- Not Pixel 6a PASS while adb is unauthorized
- Not evidence that rollback netplay was measured on a cellular link
