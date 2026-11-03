# All-nine Party forms, ultimates and Perfect Guard — owner review

Runtime/source `fec5156d5c4c544902f17bd793f394888e4b6da0`, existing draft123 stacked
on122. Subsequent evidence commits do not change the bound runtime hashes in
[FINAL_SOURCE_BINDINGS.json](FINAL_SOURCE_BINDINGS.json). All values are tuning
candidates. All art/gameplay/balance/roster/release gates remain false.

Launch from the repository: `tools/v1_closure/play_party_review.command`.
Choose any fighter: `tools/v1_closure/play_party_review.command yin --body female
--opponent yang --item prism_heart`. Options: all9 fighter IDs, male/female,
`prism_heart`, `black_seal`, `white_seal`, and `--local` for two local players.
The launcher uses an isolated profile and a declared initial item placement.
No Story rewards, regular owner saves or battle outcomes are altered.

A/D movement, J light, J+K heavy, K special, W jump, L shield, U grab, I dodge.
After pickup, T activates the temporary item. A fresh T in active Prism form
executes one ultimate and consumes the activation after recovery. Seals alter
side special for600simulation frames (10seconds at60Hz). P2 review Taunt: F8.
T/F8 are review-only bindings on existing normalized Taunt actions; shipping
hardware/touch mappings and PartyLink transport remain the Universal Input stream.

Tap grounded shield for a4frame Perfect Guard window; rearm requires a fresh
press after24frames. An early held guard blocks normally; a late guard can be
hit. Grabs remain valid. Parry stops the shot rather than reflecting it. Melee
parry pauses the attacker6frames and defender2; projectiles do not remotely
freeze their owner. Existing shield drain continues. No invulnerability is granted.

| Fighter | Prism / Seal identity | Ultimate candidate | Runtime configurations |
|---|---|---|---|
| ember-vale | PRISMATIC_ECHO / BLACK_PUPPET_ECHO, WHITE_PUPPET_ECHO | Sevenfold Furnace — combustion_chase | 12 +9ordered pairs |
| rook-ironside | PRISMATIC_ECHO / BLACK_PUPPET_ECHO, WHITE_PUPPET_ECHO | Worldbreaker Bastion — guarded_retaliation | 12 +9ordered pairs |
| juno-spark | PRISMATIC_ECHO / BLACK_PUPPET_ECHO, WHITE_PUPPET_ECHO | Spectrum Overdrive — rhythmic_rails | 12 +9ordered pairs |
| kaia-windrow | PRISMATIC_ECHO / BLACK_PUPPET_ECHO, WHITE_PUPPET_ECHO | Eye of the Seven Winds — rising_spiral | 12 +9ordered pairs |
| nix-calder | PRISMATIC_ECHO / BLACK_PUPPET_ECHO, WHITE_PUPPET_ECHO | Chromatic Citadel — finite_lattice | 12 +9ordered pairs |
| orion-vell | PRISMATIC_ECHO / BLACK_PUPPET_ECHO, WHITE_PUPPET_ECHO | Orbit of Seven — vector_compression | 12 +9ordered pairs |
| vesper-nyx | PRISMATIC_ECHO / BLACK_PUPPET_ECHO, WHITE_PUPPET_ECHO | Sevenfold Mirage — offset_echoes | 12 +9ordered pairs |
| yin | INFINITE_QUIET_TRUE_ASPECT / NULL_CONDUCTOR | The Infinite Quiet — collapsing_apertures | 12 +9ordered pairs |
| yang | ABSOLUTE_RADIANCE_TRUE_ASPECT / RADIANT_CONDUCTOR | The Absolute Radiance — radiant_construction | 12 +9ordered pairs |

[ROSTER_MATRIX.json](ROSTER_MATRIX.json) separates implementation, runtime,
native, device and human status per fighter. Both bodies/facings loaded and
executed in Party fixtures. This does not establish final retargeting quality.

The temporary item domain supersedes legacy gameplay overlays while active;
aura enhancements do not stack. Legacy ownership is restored on expiry. Damage,
grabs, stock/respawn, character changes and match closure retire the relevant
startup/ultimate owner and projectiles. Spectrum Echoes reuse existing temporary
Gray/Black/White assets; Yin/Yang use their own True Aspect/Conductor identities.
Their ordinary Story Essence/Puppet/Gray paths and boss immunity are not granted.
Items require explicit enablement in existing versus, hazards or training modes;
competitive defaults are OFF, and Story/OVA/online/tournament modes reject them.

[BASE_AURA_DECISION.json](BASE_AURA_DECISION.json): the historical double pass is
reproduced across72paired cases. At75.5aura Ember dealt20.5075 historically versus
14.125 in the single-pass candidate with unchanged geometry. The candidate remains
unsaved, per-battle opt-in metadata. Accepted BASE defaults and all216move records
remain preserved. Enabling corrected BASE damage needs the separate tuning decision.

[VALIDATION_SUMMARY.json](VALIDATION_SUMMARY.json) links actual receipts:
108Party configurations are a composite of104passing cases and4Yin retakes;
81current ordered matchups passed (44body/37shield), nine grab interruptions,
600tick natural expiry, guard forms54, guard accessibility27, finite cosmic
exceptions14, throw39, charge9, Story scenes8 and projectile impacts63.
Guard timing108historical +27current and20counterplay negatives are separate.
The original full validation ledger still contains the Rook fixture failure;
its opposing input was sent during LAND. A readiness-corrected Rook retest passed.
All initial source defects and failed fixtures remain preserved. Teardown resource
warnings remain; no GPU/device performance or leak-free acceptance is claimed.

Current level3 CPU observations use public controls and unmodified AI rules.
All9 observed actual CPU move IDs. Juno/Kaia/Vesper achieved ultimate contacts;
Ember/Rook/Nix/Orion had no ultimate contacts in that bounded attempt. Yin/Yang
transformation startup was interrupted. These are retained misses/counterplay,
not claimed combos or successful KOs. The older observation is retained separately.
The CPU public observer was corrected to recognize visible ultimate states;
its strategy, reaction probabilities and combat values were not retuned.

Original source provenance: new item/form glyph geometry and guard shader are
project-authored code. Existing9elemental audio/visual families and source rigs
are reused. No third-party assets, actor imitation, synthetic voices, ripped
Nintendo material or new licensed samples were introduced.

Art remains unfinished across ALL9. Dedicated original ultimate/form acting,
full-body anticipation/follow-through, weighted soles, floor/contact alignment,
hair/cloth and KO/recovery acting require work in each
`art_source/collectible_v1/<fighter>/<male|female>/candidate.blend`.
No Blender/GLB binary changed. Current ultimate execution reuses each fighter's
existing signature candidate acting. Yin/Yang use a small open scale glyph;
this does not meet the required authored kaiju True Aspect presentation.
Current-source native visual approval is PENDING for the whole roster.

Internal capacity is below18GiB plus anticipated allocations. No heavy exports,
recordings, APK/PCK/bulk rig production, cleanup or deletion occurred. All33
worktrees, owner saves, original art, archived media and prior evidence remain.
See [PRESERVATION.json](PRESERVATION.json):154of156protected identities unchanged;
only the explicitly modified fighter/resolver sources differ. BASE data and
all18source rigs/64GLBs in that inventory are unchanged.

CI snapshot [CI_fec5156d.json](CI_fec5156d.json): six checks passed; Windows2025
was still running. CI is source/build evidence, not Windows/Android/Pixel human
playtesting. All7 successful b3c69930 checks remain historical evidence.

First unfinished production task: author dedicated original ultimate/form
performances across all18rigs and produce current-source native review once the
18GiB+allocation reserve is available. In parallel streams, finish normalized
controller/touch action mapping and real PartyLink/LAN verification. State
snapshots exist; replay restoration/transport are not accepted. Full seven earned
Story routes/Sevenfold Convergence, final Kaia OVA+sixvariants and physical-device
acceptance remain open. No merge, release, tag, deployment or publication.
