# Animation Matrix — Anime Aggressors

Status: **P** Planned · **S** Shared proxy clip · **U** Unique timing target · **D** Done for Pixel pass

| Character | Idle | Walk/Run | Jump | Action | Hit reaction | Recovery | Victory | Defeat | Selection |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Ember Vale | U heat breath | U sharp stride | S→U | U gauntlet jabs | S→U | S | P proud raise | P kneel ember-out | P rush pose |
| Rook Ironside | U near-still | U heavy plant | S→U | U armored swings | U big recover | S | P fist-heart | P upright kneel | P fortress |
| Juno Spark | U restless | U blink-dash | S→U | U snap strikes | S | S | P spin snap | P scarf flick | P hip lean |
| Kaia Windrow | U ribbon drift | U light step | U air-favored | U flowing aerials | S | U soft land | P ribbon flourish | P poised kneel | P ribbon arc |
| Nix Calder | U micro-still | U precise | S | U exact hands | S | S | P chin lift | P composed kneel | P front precision |
| Orion Vell | U orbit idle | U measured | S→U | U vector casts | S | S | P ring open | P orbs dim | P cosmic 3/4 |
| Vesper Nyx | U delayed tells | U deceptive | S | U late-then-snap | S | S | P smirk wrap | P hooded kneel | P side smirk |

## Clip inventory (current GLB)

Shared across fighters today: `idle`, `walk`, `run`, `dash`, `jump`, `fall`, `land`, `jab_1`, `jab_2`, `heavy_attack`, `special`, `shield`, `hurt_light`, `hurt_heavy`, `launched`, `aura_charge`, `aura_burst`, `throw_forward`, `ko`.

Missing vs bible: `victory`, `defeat`, `throw_back`, `throw_up`, `throw_down`, `grab_hold`, expression overlays, selection lock-in.

## Runtime personality layer (this pass)

Until unique clip re-export completes, Godot applies per-fighter:

- idle playback scale / phase offset
- run speed scale
- attack anticipation scale
- head/eye micro-look
- aura particle language
- victory/defeat posed via tween overlays on `ko`/`idle`
