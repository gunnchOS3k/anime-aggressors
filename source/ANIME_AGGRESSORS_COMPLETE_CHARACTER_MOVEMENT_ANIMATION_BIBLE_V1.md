# ANIME AGGRESSORS
## Complete Character, Movement & Animation Bible — V1
### Canonical creative target for the seven-spectrum roster, Prismatic Gray forms, and Yin/Yang

**Status:** Creative/production bible  
**Purpose:** Give design, animation, gameplay, VFX, audio, rigging, QA, and implementation teams one shared source of truth for how every Anime Aggressors fighter should *look, move, feel, read, react, and express personality*.  
**Scope:** Seven base fighters × male/female presentation, seven Prismatic Gray variants, Yin/Black, Yang/White, story/boss variants, and competitive/playable variants.  
**Important:** This bible defines the intended finished product. It is not a statement that every item is already implemented.

---

# 1. Why this bible exists

Expressive fighting games do not become expressive from a move list alone. The finished character is the intersection of:

```text
CHARACTER FANTASY
+ SILHOUETTE
+ MOVEMENT PHYSICS
+ ANIMATION TIMING
+ POSE LANGUAGE
+ HITBOX / FRAME DATA
+ VFX / SFX
+ CAMERA / HITSTOP
+ PERSONALITY
+ REACTION LANGUAGE
+ RIG / MODEL RULES
+ QA / READABILITY
```

If any one of those layers says something different, the character feels generic.

Anime Aggressors therefore treats a fighter as a **motion identity**, not just a mesh plus attacks.

---

# 2. Public fighting-game development lessons this bible adopts

The exact internal production bibles for Super Smash Bros., Marvel vs. Capcom, MultiVersus, and similar commercial games are generally proprietary. Public developer material nevertheless shows a consistent production pattern:

## 2.1 Super Smash Bros.

Public interviews describe Smash characters as a **concentrated version of the source character**, with individual movement/landing feel and *hundreds* of tuned attributes per fighter. The lesson for Anime Aggressors is:

> Every number and every animation must reinforce the fighter's identity.

A fast fighter should not merely have a higher speed value; acceleration, foot contact, landing, turnaround, anticipation, pose shape, camera response, and recovery all need to read as speed.

## 2.2 Super Smash Flash 2 / McLeodGaming

McLeodGaming publicly discussed:
- transferring attributes, attack strength, and hitbox placement from reference material;
- character-specific hit effects;
- replacing repeated/generic animations;
- using “emphasis stretching” to make moves feel more powerful and connect more clearly;
- telegraphing charged actions through the character itself rather than depending on UI bars.

The lesson:

> Gameplay state should be visually readable from the body before the HUD explains it.

## 2.3 Fraymakers

McLeodGaming publicly described roughly **80 custom high-resolution animations per playable character**.

The lesson:

> A polished platform fighter requires complete state coverage. A fighter cannot have beautiful attacks while generic movement, ledges, hurt reactions, landings, and transitions remain unfinished.

## 2.4 Marvel vs. Capcom

Capcom described the goal as preserving a character's **movements, design, mannerisms, and source essence**, while translating that essence into an interesting fighting-game character. MvC3's visual direction was explicitly aimed at making comic-book art feel alive.

The lesson:

> Ask “How would this character express this action?” rather than “What animation do all fighters use for this action?”

## 2.5 MultiVersus

MultiVersus publicly emphasized that character abilities were designed around the game's team-play identity and that each fighter should have unique abilities that interact dynamically with others.

The lesson:

> Character identity includes how the fighter behaves around other fighters, not merely solo attacks.

For Anime Aggressors this applies especially to PartyLink duplicate fighters, team readability, assists/story interactions, and Yin/Yang puppet states.

## 2.6 Skullgirls

Public GDC material emphasizes:
- strong key poses;
- anticipation;
- timing;
- smears;
- squash/stretch;
- believable anatomy even under heavy stylization;
- gameplay responsiveness constraining the number of frames available.

The lesson:

> Pose clarity beats decorative smoothness.

## 2.7 Guilty Gear Xrd / Arc System Works

Arc System Works publicly documented a 3D animation method built to look like authored 2D animation:
- intentionally limited animation;
- little/no automatic interpolation between key poses;
- hand-authored keyframes;
- scale deformation and perspective cheating;
- rigs flexible enough to distort a model for the best screen-space pose.

The lesson:

> Anime Aggressors is allowed to break physically correct 3D if doing so creates a stronger fighting-game image.

## 2.8 Rivals of Aether

Official workshop documentation exposes an unusually clear character-state vocabulary:
- dash start / dash / dash stop / dash turn;
- multiple air dodges;
- ledge, tech, hurt and attack states;
- frame-based timing;
- hurtbox and movement properties.

The lesson:

> Animation states, gameplay states, and frame data must be explicitly mapped instead of being loosely inferred.

---

# 3. The Anime Aggressors house motion style

## 3.1 Visual target

Anime Aggressors should combine:

```text
ANIME CHARACTER DESIGN
+ 3D CEL-SHADED MODELS
+ 2D-LIKE KEY-POSE TIMING
+ PLATFORM-FIGHTER READABILITY
+ MARVEL-VS-CAPCOM-SCALE EXAGGERATION
+ CARTOON SQUASH / STRETCH
```

The models are 3D.

The *thinking* is 2D.

## 3.2 Animation frequency

Gameplay simulation remains **60 Hz**.

Animation may intentionally hold poses for multiple simulation frames when that improves readability.

Examples:

```text
SIMULATION:
60 updates / second

VISUAL ANIMATION:
may present a key pose for 2–3 frames
then snap to the next authored pose
```

Do not confuse low-quality low-FPS animation with intentional limited animation.

Every hold must be deliberate.

## 3.3 The six-beat attack grammar

Almost every expressive attack should be understandable as:

```text
1. INTENT
2. ANTICIPATION
3. ACCELERATION
4. CONTACT
5. FOLLOW-THROUGH
6. RECOVERY
```

For a very fast jab these beats may occupy only a few frames.

For a super, each may become a major pose.

## 3.4 Contact rule

At the instant of a major hit, combine:

```text
strong silhouette
+ pose exaggeration
+ hitstop
+ hit spark
+ impact SFX
+ defender reaction
+ selective camera impulse
```

Never compensate for a weak attack pose by adding more particles.

## 3.5 Emphasis deformation

Allowed:
- fists enlarge during foreshortened punches;
- feet enlarge during foreground kicks;
- torso compresses before explosive launch;
- limbs temporarily lengthen along attack direction;
- Rook's body mass compresses downward before a quake;
- Kaia's ribbons/airfoils stretch into motion arcs;
- Vesper's body may visibly offset from itself.

Gameplay collision stays canonical.

Visual deformation may exceed collision geometry.

## 3.6 Interpolation rules

Use three modes:

### A. SNAP / LIMITED
For:
- major attacks;
- supers;
- hit reactions;
- character-select poses;
- stylized anticipation;
- aura transformation.

### B. CONTROLLED INTERPOLATION
For:
- walk/run locomotion;
- camera-safe transitions;
- subtle idles;
- long traversal.

### C. PHYSICS / PROCEDURAL SECONDARY
Only for approved secondary details.

Primary silhouette and attack readability must never depend on uncontrolled cloth/hair physics.

---

# 4. Universal character bible template

Every fighter must have a complete character bible containing:

```text
01 Identity sentence
02 Narrative personality
03 Combat fantasy
04 Archetype
05 ROYGBIV / cosmic color identity
06 Shape language
07 Material language
08 Male/female presentation contract
09 Silhouette rules
10 Idle posture
11 Breathing rhythm
12 Walk identity
13 Run identity
14 Dash identity
15 Turnaround identity
16 Jump identity
17 Double-jump identity
18 Air-drift identity
19 Fast-fall identity
20 Landing identity
21 Ledge identity
22 Dodge identity
23 Shield/defense identity
24 Grab identity
25 Hurt-light reaction
26 Hurt-heavy reaction
27 Launch/tumble reaction
28 KO identity
29 Respawn identity
30 Victory identity
31 Defeat identity
32 Aura BASE
33 Aura CHARGED
34 Aura SURGE
35 Aura ASCENDANT
36 Aura SUPER
37 Attack-pose rules
38 VFX rules
39 SFX rules
40 Voice rules
41 Camera rules
42 Hitstop rules
43 Smear/deformation rules
44 Hitbox visual alignment
45 Hurtbox visual alignment
46 Animation no-go list
47 Accessibility/readability rules
48 PartyLink duplicate readability
49 Prismatic Gray expression
50 Story-mode corruption/puppet expression
```

---

# 5. Universal movement system bible

## 5.1 Current numeric baseline

These values are the current accepted gameplay-data baseline and should not be silently changed by animators.

| Fighter | Weight | Run | Dash | Air | Jump | Fall | Core movement read |
|---|---:|---:|---:|---:|---:|---:|---|
| Ember Vale | 100 | 294 | 441 | 224.4 | 620 | 1800 | Forward-pressure acceleration |
| Rook Ironside | 125 | 238 | 357 | 193.6 | 570.4 | 1944 | Heavy planted momentum |
| Juno Spark | 82 | 330.4 | 495.6 | 268.4 | 669.6 | 1836 | Burst speed / precision |
| Kaia Windrow | 96 | 274.4 | 411.6 | 246.4 | 644.8 | 1728 | Aerial flow / drift |
| Nix Calder | 118 | 252 | 378 | 198 | 589 | 1890 | Controlled heavy zoning |
| Orion Vell | 100 | 280 | 420 | 220 | 620 | 1800 | Neutral vector control |
| Vesper Nyx | 88 | 266 | 399 | 215.6 | 607.6 | 1728 | Deceptive phase movement |

These numbers define *physics*. Animation defines how those physics feel.

## 5.2 Movement invariants

Every fighter must support and visually own:

```text
idle
walk
run
dash start
dash
dash stop / skid
turnaround
crouch
jump squat
full jump
short-hop expression
double jump
fall
fast fall
soft land
hard land
platform drop
ledge teeter
ledge grab
ledge hang
ledge getup
ledge roll
ledge jump
ledge attack
air dodge
ground dodge
tech in place
tech forward
tech back
pratfall / knockdown
```

## 5.3 Input-response rule

The character must visually acknowledge player intent immediately.

Examples:
- dash: body commits within the opening frames;
- jump: visible compression before takeoff;
- dodge: silhouette clearly exits vulnerable posture;
- attack: anticipation begins immediately even if active hitbox occurs later.

“Responsive” does not mean every move has zero anticipation.

It means input produces an immediate readable *intent*.

---

# 6. Required animation inventory

The target is roughly the same order of magnitude as polished platform fighters: **about 90–100 authored animation clips per gameplay identity**, not counting every cinematic/story variant.

Male and female presentations share the same canonical animation library.

## 6.1 Locomotion / traversal

```text
idle_primary
idle_secondary
idle_long
walk_start
walk_loop
walk_stop
run_start
run_loop
run_stop
dash_start
dash_loop
dash_stop
skid
turnaround
crouch_start
crouch_hold
crouch_end
jump_squat
jump
short_hop_visual
double_jump
fall
fast_fall
land_soft
land_hard
platform_drop
```

## 6.2 Ledge / platform

```text
edge_warning
ledge_teeter
ledge_grab
ledge_hang
ledge_getup
ledge_roll
ledge_jump
ledge_attack
```

## 6.3 Defense / evasion

```text
shield_start
shield_hold
shield_hit
shield_stun
shield_break
spot_dodge
roll_forward
roll_backward
air_dodge_neutral
air_dodge_forward
air_dodge_back
air_dodge_up
air_dodge_down
tech_in_place
tech_forward
tech_back
pratfall
```

## 6.4 Damage / reactions

```text
hurt_light_front
hurt_light_back
hurt_heavy
hitstop_pose
hitstun_ground
launch_horizontal
launch_vertical
tumble
ground_bounce
wall_bounce
knockdown
ko
respawn
```

## 6.5 Grab / throw

```text
grab_startup
grab_active
grab_whiff
grab_hold
pummel
throw_startup
throw_release
```

Directional throw animation comes from the fighter's four throw moves.

## 6.6 Aura

```text
aura_charge
aura_ready
aura_burst_startup
aura_burst_active
aura_burst_recovery
aura_super_transform
```

## 6.7 Move-specific

Each fighter's current canonical move library contains 23 required gameplay moves:

```text
jab_1
jab_2
jab_finisher
forward_tilt
up_tilt
down_tilt
dash_attack
heavy_attack
neutral_air
forward_air
up_air
down_air
neutral_special_projectile
side_special
up_special_recovery
down_special
grab
throw_forward
throw_back
throw_up
throw_down
aura_charge
aura_burst
```

Attack animation names should map one-to-one to move IDs unless a documented shared clip is intentional.

## 6.8 Presentation

```text
match_intro
character_select_idle
character_select_confirm
taunt_1
taunt_2
victory
defeat
results_idle
story_dialogue_neutral
story_dialogue_intense
```

---

# 7. ROYGBIV visual bible

The seven base fighters must read as the spectrum even without names.

Target art-family colors:

```text
RED      Ember Vale
ORANGE   Rook Ironside
YELLOW   Juno Spark
GREEN    Kaia Windrow
BLUE     Nix Calder
INDIGO   Orion Vell
VIOLET   Vesper Nyx
```

Suggested art targets (not silent runtime replacements):

```text
Ember primary   #EF2B1F
Rook primary    #F47A20
Juno primary    #FFD229
Kaia primary    #2FCB88
Nix primary     #3F86F7
Orion primary   #5140C8
Vesper primary  #B73CFF
```

Rules:
- power VFX may shift luminance/value;
- do not let Juno read orange;
- do not let Kaia read cyan/blue;
- do not let Nix read indigo;
- do not let Orion read generic purple;
- do not let Vesper read magenta-red;
- neutral blacks/whites/metals support the hue, not replace it.

---

# 8. EMBER VALE — THE LIVING FURNACE

## Identity

**Fantasy:** A combustion martial artist who turns pressure into relentless forward offense.

**Archetype:** Rushdown Striker.

**Movement verbs:**
```text
ignite
lunge
drive
burst
chase
plant
re-ignite
```

## Shape language

```text
wedges
forward diagonals
gauntlet circles
vent slits
furnace core
```

No delicate flame wisps as the primary silhouette.

## Idle

- weight slightly forward;
- hands never fully relaxed;
- furnace core rises/falls with breath;
- small shoulder heat vents;
- impatience without jitter.

## Walk

- aggressive stalking step;
- feet land decisively;
- upper body already aimed at opponent.

## Run

- torso pitches forward;
- arms stay combat-ready rather than normal jogging;
- brief flame/heat impulse from rear foot.

## Dash

**Read:** ignition.

Pose sequence:
```text
compress
→ furnace flash
→ violent forward wedge
→ controlled catch step
```

Do not animate Ember as simply “running faster.”

## Turnaround

A hard heel plant with a short heat skid.

## Jump / air

Takeoff should look self-propelled.

Double jump:
- directional combustion pulse;
- knees compress toward chest before re-extension.

## Landing

Ember catches momentum aggressively and wants to attack immediately.

Hard landing:
- heat flare around feet;
- no generic superhero kneel.

## Defense

Shield posture still looks offensive:
- shoulders forward;
- gauntlets protecting centerline.

Dodge:
- combustion-assisted slip, not teleportation.

## Hurt

Light hurt:
- angry recoil.

Heavy hurt:
- furnace core visibly flickers/vents.

Ember does not look frightened; Ember looks interrupted.

## KO

Combustion shuts down in stages:
```text
vents fail
→ core dims
→ body loses forward tension
```

## Attack motion rule

Every attack must answer:
> Where is the combustion driving the body?

No fire should appear disconnected from force generation.

## Aura progression

BASE:
small furnace glow.

CHARGED:
thermal seams activate.

SURGE:
gauntlets/vents open.

ASCENDANT:
heat crown and stronger body distortion.

SUPER:
body reads like an opened humanoid furnace.

## Male / female

Same:
- core;
- gauntlets;
- vents;
- wedge language;
- movement timing.

Different:
- body proportion;
- face/head presentation;
- selected garment fit.

Never:
“male Ember + smaller/sexy Ember.”

## Prismatic Gray

Competitive movement/frame data stays Ember.

Story expression:
- six Essence colors appear only as secondary ignition states;
- movement remains fundamentally combustion-driven.

---

# 9. ROOK IRONSIDE — THE WALKING BASTION

## Identity

**Fantasy:** A fortress that decided to move.

**Archetype:** Armored Bruiser.

**Movement verbs:**
```text
brace
plant
compress
carry
crush
anchor
advance
```

## Shape language

```text
blocks
columns
layered strata
heavy circles at joints
broad low triangles
```

## Idle

- feet wider than shoulders;
- visible weight settling;
- shoulders slightly asymmetrical from load;
- small armor compression rather than fidgeting.

## Walk

Every step has weight transfer.

No foot sliding.

Hip and shoulder counter-rotation should be obvious.

## Run

Rook does not sprint like Juno.

Rook builds momentum:
```text
step 1 = commitment
step 2 = mass moving
step 3 = unstoppable
```

## Dash

A short armored charge, not athletic sprinting.

## Turnaround

Rook must decelerate before redirecting.

Even if gameplay changes direction immediately, animation can use a visual skid/compression to preserve mass.

## Jump

Jump looks expensive.

Deep compression before takeoff.

No graceful floating.

## Air

Limited visual correction.

Limbs reposition to prepare for impact, not to look agile.

## Landing

Most distinctive landing in roster.

Soft:
heavy two-foot plant.

Hard:
tectonic shock pose; shoulders absorb vertical force.

## Defense

Rook physically receives force.

Shield/armor:
plates lock.

Dodge:
short body shift / armored lean rather than acrobatics.

## Hurt

Light hits:
minimal displacement; head/shoulder acknowledges impact.

Heavy:
armor separates slightly, tectonic seams flare.

## KO

The “building collapse” rule:
- knees fail first;
- torso mass follows;
- armor loses locked alignment.

## Aura

BASE:
dark basalt/metal.

CHARGED:
seams glow.

SURGE:
joint rings activate.

ASCENDANT:
plates re-stack/compress.

SUPER:
living fortress silhouette.

## Male / female

Both must remain visually heavyweight.

Female Rook is not a speed fighter wearing Rook armor.

## Prismatic Gray

Other essences appear as material states:
molten plate, conductive stone, cryo-strata, gravity compression, phase armor.

Core movement remains Rook.

---

# 10. JUNO SPARK — THE ARC COURIER

## Identity

**Fantasy:** A living electromagnetic accelerator.

**Archetype:** Speed Confirm.

**Movement verbs:**
```text
snap
route
redirect
chain
skip
accelerate
rebound
```

## Shape language

```text
forward diagonals
thin rails
forks
small conductor nodes
compact center
```

## Idle

Juno appears ready to leave before the animation finishes.

Subtle micro-shifts.

No large slow breathing.

## Walk

Quick foot placement, light contacts.

## Run

Short ground-contact time.

Arms/legs form clear alternating diagonals.

## Dash

Fastest/readiest dash in roster.

Visual grammar:
```text
1-frame-like intent
→ elongated acceleration pose
→ arc ghost
```

Do not make Juno unreadable through excessive blur.

## Turnaround

Electric snap-turn.

Feet plant narrowly.

Upper body redirects almost immediately.

## Jump

Quick spring.

Double jump can use electromagnetic polarity kick.

## Landing

Cleanest, shortest-looking landing.

Juno visually “sticks” the landing and is ready again.

## Defense

Dodge movement should look like predictive repositioning.

Shield pose compact; minimal wasted silhouette.

## Hurt

Juno reacts quickly and returns quickly.

Heavy hurt should emphasize momentum being forcibly interrupted.

## Aura

BASE:
small current paths.

CHARGED:
channels synchronize.

SURGE:
conductor nodes align.

ASCENDANT:
rail geometry energizes.

SUPER:
body reads like a controlled lightning circuit.

## Male / female

Same compact-speed silhouette envelope.

Neither presentation may become bulkier enough to undermine speed identity.

## Prismatic Gray

Each Essence alters Juno's acceleration medium, not fundamental speed identity.

---

# 11. KAIA WINDROW — THE SKYFLOW DUELIST

## Identity

**Fantasy:** The spectrum's aerial mediator; movement becomes pressure control.

**Archetype:** Aerial Spacer.

**Movement verbs:**
```text
flow
curve
float
redirect
spiral
glide
balance
```

## Shape language

```text
arcs
airfoils
ribbons
crescents
open negative space
```

## Idle

The body never looks fully gravity-bound.

Ribbons/control surfaces respond subtly.

Breathing is calm and centered.

## Walk

Smooth weight transfer.

Less vertical bounce than Ember/Juno.

## Run

Longer flowing stride.

Upper body remains composed.

## Dash

A pressure-driven glide step:
```text
lean
→ airfoil alignment
→ low horizontal sweep
```

## Turnaround

Kaia redirects momentum rather than stopping it.

Turn uses curved footwork and ribbon arc.

## Jump

Most elegant takeoff in base roster.

Double jump:
pressure ring / wind step.

## Air

Kaia must be immediately recognizable from air-drift animation.

Body subtly banks into horizontal input.

Limbs/ribbons function like control surfaces.

## Fast fall

Airfoils collapse; body streamlines downward.

## Landing

Kaia bleeds vertical energy sideways into a small spiral/step.

## Defense

Dodge = flow around danger.

Shield pose remains open enough to preserve calm confidence.

## Hurt

Light hurt:
balance disturbed.

Heavy:
flow breaks and ribbons/control surfaces lose alignment.

## Aura

BASE:
gentle current.

CHARGED:
pressure rings.

SURGE:
airfoils open.

ASCENDANT:
larger current ribbons.

SUPER:
Kaia becomes the visual eye of a controlled storm.

## Male / female

Same movement rhythm.

Same personality.

Same long aerodynamic silhouette.

## Prismatic Gray — canonical story transformation

Gray Kaia carries all six ally Essences without becoming six separate characters.

Movement principle:
> wind remains the medium binding everything.

Competitive form:
same Kaia gameplay.

Story form:
movement can briefly express the other six essences.

---

# 12. NIX CALDER — THE CRYOLATTICE ARCHITECT

## Identity

**Fantasy:** A tactical controller who builds order into the battlefield.

**Archetype:** Control Tank.

**Movement verbs:**
```text
measure
place
lock
brace
construct
contain
advance
```

## Shape language

```text
facets
grids
lattices
hexagonal/triangular crystal
vertical walls
```

## Idle

Extremely controlled.

Minimal wasted motion.

Hands often positioned as if evaluating space.

## Walk

Measured steps.

Each step looks chosen, not casual.

## Run

Nix does not look panicked at speed.

Stride remains organized.

## Dash

A controlled frost slide with an explicit stop point.

## Turnaround

Sharp but deliberate pivot.

## Jump

Compact takeoff.

Air pose remains structured.

## Landing

Crystal/frost geometry can momentarily organize beneath feet.

## Defense

Strongest “planned defense” in roster.

Shield pose:
calculated.

Dodge:
minimum necessary displacement.

## Hurt

Light:
structure flexes.

Heavy:
crystalline geometry fractures visually.

## Aura

BASE:
small facets.

CHARGED:
lattice expands.

SURGE:
mantle grows.

ASCENDANT:
major crystal structures.

SUPER:
Nix becomes center of a geometric frozen system.

## Male / female

No “ice prince / ice princess” split.

Both are tactical cryolattice architects.

## Prismatic Gray

Other essences become construction materials inside Nix's lattice language.

---

# 13. ORION VELL — THE ORBITAL MARSHAL

## Identity

**Fantasy:** A calm controller of mass, vectors, orbit, and consequence.

**Archetype:** Combo Control.

**Movement verbs:**
```text
orbit
pull
repel
suspend
redirect
compress
release
```

## Shape language

```text
circles
ellipses
concentric rings
node constellations
long vector lines
```

## Idle

Centered and composed.

Small orbit nodes continue moving even when body does not.

## Walk

Deliberate but not heavy.

Each hand gesture implies space is already being managed.

## Run

Orion looks as though space is helping movement.

Less visible exertion than Ember/Rook.

## Dash

Brief local compression:
```text
nodes contract
→ body advances
→ nodes restore orbit
```

## Turnaround

Body pivots around an implied center rather than skidding.

## Jump

Gravity releases rather than legs simply overpowering ground.

## Air

Slight suspension quality.

Do not make Orion float so much that Kaia loses aerial identity.

## Landing

Gravity returns in a clean controlled compression.

## Defense

Shield posture can use orbit nodes as defensive geometry.

Dodge:
local vector displacement.

## Hurt

A hit should visibly break orbital order.

Heavy hurt:
nodes scatter before re-forming.

## Aura

BASE:
few orbit nodes.

CHARGED:
ring appears.

SURGE:
multiple nodes.

ASCENDANT:
nested orbital system.

SUPER:
body becomes center of a miniature celestial machine.

## Male / female

Same calm authority.

Same orbital architecture.

## Prismatic Gray

Six spectral nodes can orbit Orion, each representing an absorbed Essence, while gravity remains the core mechanic.

---

# 14. VESPER NYX — THE PHASE WEAVER

## Identity

**Fantasy:** A spatial trickster whose greatest weapon is making the opponent trust the wrong moment.

**Archetype:** Phase Trickster.

**Movement verbs:**
```text
misdirect
offset
vanish
reappear
delay
slip
fracture
```

## Shape language

```text
asymmetry
broken diagonals
negative space
split tails
offset doubles
partial circles
```

## Idle

Never completely stable.

Occasional small positional mismatch:
- hand ghost;
- shadow delay;
- cowl offset.

Do not overuse.

## Walk

Quiet and predatory.

Body sometimes leads with an unexpected shoulder/foot.

## Run

Vesper's path reads clearly but animation suggests location uncertainty.

## Dash

Short phase displacement.

Opponent must still be able to read start/end for competitive fairness.

## Turnaround

Can rotate through a brief offset silhouette.

## Jump

Low visual effort.

Double jump can look like a local phase correction rather than propulsion.

## Landing

Feet arrive a beat before/after ghost geometry.

## Defense

Best evasive personality in roster.

Shield:
minimal.

Dodge:
phase slip.

## Hurt

Light:
body flickers but receives hit honestly.

Heavy:
phase breaks fail; multiple ghost positions collapse into one.

## Aura

BASE:
small void seams.

CHARGED:
edge ghosts.

SURGE:
negative-space cuts.

ASCENDANT:
secondary offset body fragments.

SUPER:
silhouette partially disagrees with itself.

## Male / female

Same deceptive timing and personality.

## Prismatic Gray

Each alternate phase echo may carry a different Essence color.

Vesper still reads as phase/void first.

---

# 15. PRISMATIC GRAY BIBLE

## 15.1 Meaning

Gray does not mean absence of color.

Gray means:

> **all seven colors held without one dominating the others.**

Visual hierarchy:

```text
graphite / silver / neutral body
+
small spectral ROYGBIV accents
+
fighter's original power architecture
```

## 15.2 Competitive rule

In versus/ranked:

```text
same frame data
same hitboxes
same movement
same damage
same knockback
same recovery
```

Prismatic Gray is not pay-to-win or progression-to-win.

## 15.3 Story rule

Story-mode Prismatic forms may use Essence-enhanced mechanics because story balance is separate.

## 15.4 Movement rule

Gray never replaces the fighter's core movement identity.

Examples:
- Gray Rook still moves like mass.
- Gray Juno still moves like acceleration.
- Gray Kaia still moves like flow.
- Gray Vesper still moves like misdirection.

---

# 16. YIN / BLACK — THE INFINITE QUIET

## Status

New cosmic character. Numbers/frame data require dedicated playable/boss prototype and are not silently invented here.

## Identity

**Philosophy:** Peace through reduction.

**Healthy principles:**
```text
rest
privacy
silence
ending
restraint
introspection
potential
```

**Absolute failure state:**
```text
difference → friction → suffering
therefore remove difference
```

## Movement verbs

```text
absorb
settle
fold
collapse
still
erase
draw inward
```

## Movement personality

Yin should appear to use less effort than anyone else.

Walk:
- unnervingly quiet;
- almost no secondary motion.

Run:
- should not look like athletic running;
- space shortens around Yin.

Dash:
```text
destination darkens
→ distance collapses
→ Yin is there
```

Not Vesper teleportation.

Vesper deceives perception.

Yin reduces distance itself.

Jump:
gravity seems to stop insisting.

Fall:
controlled descent as if reality is being absorbed beneath.

Landing:
almost no impact sound; surrounding ambience briefly disappears.

## Combat

Yin does not “blast black energy.”

Yin subtracts.

Examples:
- removes projectile;
- shortens attack trail;
- collapses field;
- reduces sound;
- suppresses color;
- folds hit space inward.

## Hurt

The body does not recoil dramatically.

Impact is swallowed until a threshold is exceeded.

When truly hurt, a tiny WHITE seed should become more visible.

## Black-with-white-seed rule

Yin contains a small Yang principle.

This is essential to the story.

## Boss version

Cosmic Yin can violate normal movement laws.

## Playable version

Must fit platform-fighter fairness:
- readable startup;
- readable destination;
- standardized hurtbox;
- punishable recovery.

---

# 17. YANG / WHITE — THE ABSOLUTE RADIANCE

## Status

New cosmic character. Numbers/frame data require dedicated playable/boss prototype.

## Identity

**Philosophy:** Peace through perfect definition and unity.

**Healthy principles:**
```text
creation
clarity
action
communication
growth
warmth
revelation
```

**Absolute failure state:**
```text
ambiguity → misunderstanding → conflict
therefore define everything perfectly
```

## Movement verbs

```text
emit
expand
declare
construct
align
project
overwrite
```

## Movement personality

Yang is the opposite of Yin's stillness.

Walk:
- each step looks exact and intentional.

Run:
- clean accelerating geometry.

Dash:
hard-light path manifests before/with motion.

Jump:
light constructs or exact force vector.

Fall:
controlled luminous descent.

Landing:
space organizes into clean geometry.

## Combat

Yang adds structure.

Examples:
- hard-light constructs;
- expanding fields;
- imposed trajectories;
- repeated patterns;
- revelation/outline effects;
- forcing things into exact positions.

## Hurt

Normal hit:
perfect geometry cracks.

Heavy hit:
BLACK seed becomes visible.

## White-with-black-seed rule

Yang contains an ending/destructive principle.

Without this, peace would be philosophically impossible.

## Boss version

Cosmic Yang may overwhelm the entire arena with imposed order.

## Playable version

Normalized startup/recovery and readable construct limits.

---

# 18. Yin / Yang paired motion bible

They should be designed in mirrors.

| Yin | Yang |
|---|---|
| absorbs | emits |
| shortens | expands |
| quiets | announces |
| removes trails | creates trails |
| collapses geometry | constructs geometry |
| asymptotic inward motion | radiating outward motion |
| low-frequency/deep SFX | high-frequency/clear SFX |
| desaturates | overexposes |
| puppet individuality is subtracted | puppet individuality is overwritten |

When both act simultaneously:

```text
YIN: toward zero
YANG: toward infinity
```

The collision is not “purple explosion.”

It is a cosmological contradiction.

---

# 19. Puppet animation bible

Every base fighter needs three puppet states:

```text
NORMAL
YIN-CONTROLLED
YANG-CONTROLLED
```

## Yin puppet

Animation changes:
- fewer secondary motions;
- shorter holds;
- movement seems dragged inward;
- original color nearly disappears;
- personality gestures suppressed.

But:
one tiny pulse of original hue remains.

## Yang puppet

Animation changes:
- unnaturally exact symmetry;
- perfectly repeated timing;
- over-clean trajectories;
- high white exposure;
- personality timing flattened into imposed order.

But:
one small dark imperfection remains.

## Release

When Kaia/anchor breaks control:

```text
forced timing breaks
→ original fighter motion returns
→ one authentic personality gesture
→ essence release
```

The brief return of their true animation language is emotionally important.

---

# 20. Hit-reaction bible

A fighting game roster feels expensive when characters are expressive while losing.

Every fighter needs:

```text
light face/body reaction
medium stagger
heavy stagger
low-hit reaction
air-hit reaction
launch
tumble
wall bounce
ground bounce
shield break
grabbed
thrown
KO
```

Identity examples:

Ember:
frustrated interruption.

Rook:
mass resists, then fails catastrophically.

Juno:
momentum abruptly cut.

Kaia:
balance/flow broken.

Nix:
structure fractures.

Orion:
orbit scatters.

Vesper:
phase coherence collapses.

Yin:
absorption threshold exceeded.

Yang:
perfect geometry fractures.

---

# 21. Camera bible

Camera must support combat, not compete with it.

## Normal attacks

No camera cut.

Only micro-impulse for sufficiently strong hits.

## Heavy attacks

Short directional impulse aligned with impact.

## Supers

Camera may:
- push in;
- change FOV;
- use short authored angle;
- return to combat camera before gameplay ambiguity.

## Multiplayer

2–8 player PartyLink:
- readability overrides cinematic framing;
- never cut camera away from another vulnerable player;
- strongest cinematics become local VFX/zoom rather than exclusive camera takeover.

---

# 22. Hitstop bible

Hitstop is character acting.

The attacker pose and victim pose must both be authored to look good while frozen.

Suggested qualitative tiers:

```text
TIER 0 — no/near-no hitstop
movement ticks / weak multihits

TIER 1 — light
jab / quick normals

TIER 2 — medium
tilts / aerial finishers

TIER 3 — heavy
heavy attacks / strong specials

TIER 4 — dramatic
super finisher / KO-confirming impact
```

Exact frame counts remain move-data authority.

---

# 23. Smear / stretch bible

Allowed methods:

```text
mesh scale
limb extension
ghost mesh
2D effect card
motion arc
temporary duplicate geometry
power-specific trail
```

Per fighter:

```text
Ember  → heat wedge / flame stretch
Rook   → mass compression / rock debris arc
Juno   → electric arc ghost
Kaia   → wind ribbon arc
Nix    → crystal construction streak
Orion  → orbit-vector curve
Vesper → phase afterimage
Yin    → trail deletion / space fold
Yang   → geometric expansion trail
```

---

# 24. Audio movement bible

Movement SFX must be character-specific.

Examples:

Ember:
heat crackle + ignition thump.

Rook:
dense low-frequency armor/stone impacts.

Juno:
tight electric chirps, short transient snaps.

Kaia:
air pressure, cloth/control-surface flutter.

Nix:
crystal tick, ice compression.

Orion:
low orbital hum, gravitational pitch bend.

Vesper:
phase flutter, reversed transient, spatial delay.

Yin:
ambience removal, sub-bass pressure.

Yang:
clear harmonic chimes, hard-light construction.

Do not let all characters share the same generic footstep library without material/power treatment.

---

# 25. Voice / personality bible

Voice must obey animation rhythm.

Ember:
direct, impatient, committed.

Rook:
minimal words, grounded confidence.

Juno:
fast, playful, precise.

Kaia:
calm but decisive; never blandly “peaceful.”

Nix:
measured, analytical.

Orion:
composed, philosophical.

Vesper:
dry, playful, ambiguous.

Yin:
quiet, economical, almost never raises volume.

Yang:
clear, declarative, unnervingly certain.

Male/female presentation:
same writing/personality; different performer only if desired.

---

# 26. Character-select movement bible

Each fighter's select preview needs:

```text
ENTRY
IDLE
POWER DEMO
CONFIRM
CANCEL / RETURN
```

Examples:

Ember:
gauntlet ignition.

Rook:
plates lock.

Juno:
arc routes between fingers.

Kaia:
airfoil/ribbon current.

Nix:
small lattice construction.

Orion:
orbit nodes align.

Vesper:
preview briefly offsets.

Yin:
UI sound drops out.

Yang:
UI lines snap into exact alignment.

---

# 27. Animation readability tests

Every animation must pass:

## Silhouette test
Render as solid black.

Can the action still be identified?

## 3-frame test
Show:
- anticipation;
- contact;
- recovery.

Can a reviewer identify move intention?

## VFX-off test
Disable power effects.

Does attack still read?

## 25%-scale test
Shrink gameplay.

Does direction remain readable?

## grayscale test
Can pose and effect structure survive without hue?

## duplicate-fighter test
Can P1/P2/P3/P4 same-fighter presentations be distinguished without full recolor?

## freeze-frame test
Pause on contact.

Does it look intentionally illustrated?

---

# 28. Rigging bible

One canonical gameplay rig per fighter identity.

Male/female presentations must support:

```text
same bone names
same action IDs
same VFX sockets
same hitbox sockets
same root-motion assumptions
same gameplay reach envelope
```

Visual proportions may differ.

Collision may not.

Important deformation controls:

```text
head scale
hand scale
foot scale
forearm stretch
upper-arm stretch
spine curve
shoulder offset
hip compression
torso squash
face/eye control
power-structure controls
```

The rig should support intentional screen-space cheating.

---

# 29. Frame-data / animation ownership

Gameplay data is authoritative for:

```text
startup
active
recovery
damage
angle
base knockback
knockback growth
shield damage
shield stun
hitstop
aura scaling
hitbox timing
```

Animation must fit gameplay.

Do not lengthen gameplay recovery because an animator wants more flourish.

Use visual follow-through that can finish after the state becomes actionable only when it does not lie to the player.

---

# 30. Roster differentiation matrix

Every pair of fighters should differ in at least five of these:

```text
center of gravity
stride length
acceleration read
air posture
landing style
turnaround
idle rhythm
anticipation length
follow-through
defense posture
hurt reaction
smear style
aura growth
camera response
audio footprint
```

If two fighters differ only through VFX color, the bible has failed.

---

# 31. Production acceptance ladder

A character is not “done” when the move works.

Use:

```text
G0 DATA COMPLETE
G1 RIG COMPLETE
G2 STATE COVERAGE COMPLETE
G3 MOVE ANIMATION COMPLETE
G4 HITBOX / FRAME SYNC COMPLETE
G5 VFX / SFX COMPLETE
G6 VISUAL READABILITY COMPLETE
G7 PIXEL PHYSICAL PASS
G8 HUMAN FEEL PASS
G9 FINAL ART APPROVED
```

No lower gate implies a higher gate.

---

# 32. Per-fighter acceptance questions

## Ember
Does every movement feel like controlled combustion?

## Rook
Can the player feel Rook's mass before Rook attacks?

## Juno
Does Juno look fast while remaining readable?

## Kaia
Does Kaia own aerial flow without looking weightless or passive?

## Nix
Does Nix look like a tactical builder/controller rather than generic ice mage?

## Orion
Does Orion manipulate vectors rather than merely shoot purple spheres?

## Vesper
Does Vesper feel deceptive without becoming unreadable/unfair?

## Yin
Does Yin subtract reality rather than merely use black VFX?

## Yang
Does Yang impose/construct reality rather than merely use white VFX?

---

# 33. Story / versus separation

Story can exaggerate.

Ranked cannot lie.

## Story

Allowed:
- Prismatic Essence abilities;
- cosmic Yin/Yang movement;
- puppet transformations;
- impossible supers;
- scripted camera;
- cinematic hitstop.

## Versus

Required:
- standardized readability;
- punishable recovery;
- stable frame data;
- no untelegraphed teleport;
- no cosmetic variant hitbox changes.

---

# 34. Implementation files this bible should eventually drive

Recommended repository structure:

```text
docs/bibles/
  ANIME_AGGRESSORS_CHARACTER_MOVEMENT_BIBLE.md
  ANIMATION_STYLE_BIBLE.md
  HIT_REACTION_BIBLE.md
  CAMERA_HITSTOP_BIBLE.md
  VFX_SFX_BIBLE.md
  RIG_DEFORMATION_BIBLE.md

docs/bibles/fighters/
  ember-vale.md
  rook-ironside.md
  juno-spark.md
  kaia-windrow.md
  nix-calder.md
  orion-vell.md
  vesper-nyx.md
  yin.md
  yang.md

data/bibles/
  movement_profiles.json
  animation_inventory.json
  reaction_profiles.json
  aura_profiles.json
  presentation_profiles.json
```

---

# 35. Final canonical principle

The Anime Aggressors roster should never be described as:

> “seven characters with different powers.”

It should be experienced as:

```text
EMBER  moves like combustion.
ROOK   moves like mass.
JUNO   moves like current.
KAIA   moves like flow.
NIX    moves like structure.
ORION  moves like vectors.
VESPER moves like uncertainty.
YIN    moves like reduction.
YANG   moves like definition.
```

If a player can identify the fighter from a grayscale silhouette with all VFX disabled and only three seconds of locomotion, the movement bible is doing its job.
