# Combat clash audio handoff

Mixer: `game-godot/scripts/combat/clash_audio_mixer.gd`

| Cue ID | Timing | Loop | Max duration | Mix priority | Ducking | Placeholder |
|---|---|---|---|---|---|---|
| `aa_clash_energy_bed_a` | QUALIFY→RECOVER | yes | 48f | 40 | no | original procedural |
| `aa_clash_energy_bed_b` | QUALIFY→RECOVER | yes | 48f | 40 | no | original procedural |
| `aa_clash_central_collision` | CONTACT | no | 12f | 70 | no | original procedural |
| `aa_clash_escalating_pressure` | LOCK→ESCALATE | yes | 48f | 50 | no | original procedural |
| `aa_clash_strain_pulses` | ESCALATE | no | 16f | 55 | no | original procedural |
| `aa_clash_environment_lf` | SNAP→RECOVER | yes | 48f | 20 | yes | original procedural |
| `aa_clash_resolution_transient` | RESOLVE_* | no | 10f | 80 | no | original procedural |
| `aa_clash_post_resolution_tail` | RECOVER | no | 18f | 30 | no | original procedural |

Loops stop on RECOVER. No copyrighted audio. Dynamic-range option rides existing AudioDirector if present.
