# CODEX ADDENDUM — Anime Aggressors V1 Full Campaign, Variants, Combat Feel, VFX & Audio

Use this with `CODEX_ANIME_AGGRESSORS_CHIBI_FIGURINE_V1_ART_DIRECTION.md`.

## Existing authority in the repo

Do not ask the owner to re-supply bibles that already exist. Before editing, ingest and reconcile:

- `docs/anime-aggressors/creative/authority_pack_v1/README.md`
- `docs/anime-aggressors/creative/authority_pack_v1/01_FULL_ROSTER_ART_CORRECTION_DIRECTION.md`
- `docs/anime-aggressors/creative/authority_pack_v1/02_CANONICAL_3D_CHIBI_MODEL_BIBLE.md`
- `docs/anime-aggressors/creative/authority_pack_v1/03_COMPLETE_STORY_MODE_CAMPAIGN_BIBLE.md`
- `docs/anime-aggressors/creative/authority_pack_v1/04_SOURCE_AUTHORITY_MATRIX.md`
- `docs/anime-aggressors/creative/authority_pack_v1/MODEL_ROSTER_AUTHORITY.json`
- `docs/anime-aggressors/creative/authority_pack_v1/STORY_CAMPAIGN_MANIFEST.json`
- `source/ANIME_AGGRESSORS_COMPLETE_CHARACTER_MOVEMENT_ANIMATION_BIBLE_V1.md`
- `docs/bibles/README_START_HERE.md`
- `docs/bibles/fighters/*.md`
- `data/bibles/FIGHTER_BIBLE_INDEX.json`
- `docs/design/ROSTER_MOTION_IDENTITY_BIBLE.md`
- `docs/design/FIGHTER_SIGNATURE_MOVE_BIBLE.md`
- `docs/design/CHARACTER_COMBAT_INSPIRATION_BIBLE.md`
- `docs/quality/ANIMATION_TASTE_RUBRIC.md`
- `docs/VFX_AND_CAMERA_PIPELINE.md`
- `docs/vfx/ELEMENTAL_VFX_LANGUAGE_V1.md`
- `docs/production/VFX_DIRECTOR_NOTES.md`
- `game-godot/data/combat/v3_vfx_events.json`
- `game-godot/data/combat/v3_sfx_events.json`
- `docs/KNOWN_ISSUES.md`
- `docs/PRODUCTION_BLOCKERS.md`

If a newer owner-supplied bible exists outside the repo, stop only for that specific conflict. Otherwise use repository authority.

## Full V1 story/campaign requirement

V1 must include the complete playable campaign, not only Kaia's route.

Campaign progression:
1. The Green Between / Kaia Root Story
2. Prismatic Gray Kaia
3. Six additional Prismatic Routes: Ember, Rook, Juno, Nix, Orion, Vesper
4. Seven of Seven Prismatic Gray
5. Sevenfold Convergence
6. Yin + Yang playable unlock
7. Yin/Yang cosmic Story/Boss contracts where declared
8. competitive playable Yin/Yang contracts

For every route verify:
- prologue/intro
- recruitment/encounters
- Accord
- catastrophe
- Impossible Yin/Yang Battle I
- First Loss
- puppet imbalance
- first release
- restored 2v2 equilibrium
- dual releases
- six-Essence state
- route-specific Prismatic Gray transformation
- Impossible Yin/Yang Battle II
- route resolution/epilogue
- unlocks
- return to Story menu
- save/resume
- chapter replay where declared
- no dead ends
- no unreachable fights
- no V1-required “coming soon”

The campaign must use actual gameplay encounters, not only text cards.

### Open canon

The campaign bible says:
- Kaia's First Loss is canonically Rook.
- First Loss for Ember, Rook, Juno, Nix, Orion, Vesper is OPEN CANON.

For those six:
1. generate 1–3 candidate First Loss choices using the rule that the lost ally must most directly expose the protagonist's flaw;
2. provide rationale;
3. continue all route work that does not depend on the final choice;
4. do not silently canonize one;
5. do not mark those routes V1 complete until owner approval.

## Full roster/variant completion

Reconcile and implement the declared V1 roster:
- Ember Vale
- Rook Ironside
- Juno Spark
- Kaia Windrow
- Nix Calder
- Orion Vell
- Vesper Nyx
- Yin
- Yang

For every applicable fighter:
- base playable form
- promised male/female presentation variants
- Prismatic Gray form where required
- Black Puppet story variant
- White Puppet story variant
- story/boss variants
- competitive/playable contracts
- selection portrait
- battle model
- rig
- animations
- VFX
- SFX
- story dialogue identity
- victory/defeat/selection/reaction presentation

A variant does not count because it exists in a manifest. It must render and function in Godot where V1 declares it playable.

## Moves and animation completion

For every fighter and every required state verify:
- idle
- walk/run
- dash
- jump/fall
- light string
- heavy string
- aerials
- specials
- super
- grabs
- directional throws
- hit reactions
- knockback/launch
- recovery
- shield/block
- dodge/evade if declared
- KO
- victory
- defeat
- selection/lock-in
- story-specific transformation/action states

Every move must have:
- anticipation
- distinct action
- impact
- recovery
- hitbox/hurtbox alignment
- timing aligned to startup/active/recovery
- fighter-specific body language
- VFX timing
- SFX timing
- camera/hitstop feedback

Do not accept generic retargeted motion where the bibles require distinct motion identity.

## Game juice / power fantasy

The owner wants every fighter to feel captivating, breathtaking, and powerful in a character-specific way.

Automation must create the conditions for human taste review:

### Input/response
- immediate response
- readable commitment
- input buffering where appropriate
- no dead inputs
- responsive attack/jump/dash transitions

### Impact
- hitstop scaled by move severity
- contact flash/accent
- camera impulse scaled by move
- knockback/launch response
- defender reaction
- KO punctuation

### Motion
- anticipation
- overshoot/follow-through
- secondary motion
- smear/stretch where appropriate
- trails/arcs
- recovery snap/weight
- unique locomotion grammar

### Elemental VFX must differ by shape/behavior, not only color
- Ember: combustion / pressure / heat
- Rook: mass / armor / impact
- Juno: voltage / speed / chain
- Kaia: flow / wind / carry
- Nix: crystal / containment / frost
- Orion: orbit / gravity / vector
- Vesper: phase / void / misdirection
- Yin: absorption / reduction / nullity
- Yang: radiance / definition / creation

Preserve readability hierarchy:
body -> contact -> defender -> primary effect -> trail -> particles.

### Audio
Replace placeholder/oscillator-only release audio with authored/original or approved procedural-final assets.

Per fighter/move family cover:
- movement accents
- whiff
- light hit
- heavy hit
- elemental signature
- special
- super startup
- super impact
- block
- launch
- KO
- select/lock-in
- transformation
- Puppet/Prismatic cues
- original/authorized short VO where used

Fix known issues such as shield-hit SFX firing on shield start if still present.

### Camera/presentation
- supers get stronger framing without hiding play
- transformations get authored presentation
- victory/defeat are character-specific
- no VFX wall that obscures opponent state

## Automated matrix

Produce machine-readable + human-readable coverage for every fighter/form/move/story node:
- model
- rig
- animations
- moves
- VFX
- SFX
- camera feedback
- hitstop/impact
- story route
- encounter
- runtime loadability
- web build
- Android/Godot build
- source/artifact provenance

Keep these human gates false:
- `FINAL_CHARACTER_ART_PASS`
- `ANIMATION_TASTE_HUMAN_PASS`
- `GAME_FEEL_HUMAN_PASS`
- `VFX_TASTE_HUMAN_PASS`
- `SFX_MIX_HUMAN_PASS`
- `STORY_HUMAN_PASS`
- `V1_ANIME_HUMAN_PASS`

## Runtime acceptance

Exercise the actual Godot shipping path.

For every playable fighter/form:
select -> battle -> move -> jump -> light -> heavy -> special -> super -> take hit -> recover -> KO -> be KO'd -> victory/defeat -> return/rematch.

For Story:
new campaign -> save -> resume -> every required chapter/node -> every fight -> transformations/unlocks -> route ending -> next route -> Sevenfold Convergence -> Yin/Yang unlock.

No route may rely only on JSON validation.

## Owner review package

Generate:
1. full roster contact sheet
2. male/female comparison
3. base/Puppet/Prismatic variants
4. per-fighter turntables
5. battle-camera captures
6. signature move classes
7. light/heavy/special/super impact montage
8. elemental VFX comparison
9. SFX comparison by fighter
10. story route map
11. campaign completion matrix
12. transformations/unlocks
13. unresolved canon choices
14. known technical defects
15. exact build SHA/artifact

Owner must be able to judge:
- Does this character look right?
- Does this move feel powerful?
- Can I identify them without the nameplate?
- Does each element sound/feel distinct?
- Is Story Mode actually complete?
- Do I want to keep playing?

## Final rule

Anime V1 is not complete merely because files, GLBs, story JSON, move IDs, VFX events, and SFX events exist.

Automated readiness requires the declared roster/forms/moves/story runtime to be playable and technically covered.

Final V1 acceptance additionally requires explicit owner approval of:
- art
- animation taste
- combat/game feel
- VFX
- SFX/mix
- story/campaign
- replay desire

Do not publish V1 or mark human gates true.
