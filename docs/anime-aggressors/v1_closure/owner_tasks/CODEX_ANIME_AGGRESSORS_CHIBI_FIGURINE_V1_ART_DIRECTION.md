# Codex Task — Anime Aggressors V1 Art Direction Lock: Lore-Faithful Collectible Chibi Figurines

Work only in `gunnchOS3k/anime-aggressors`.

Expected accepted main at task start:
`887e100114c9741ebc7a449b46116bcb6eef5072`

## Owner art-direction decision

The V1 character direction is now locked conceptually:

**Anime Aggressors characters should read like premium collectible anime figurines in a cute / kawaii / chibi / super-deformed style, while remaining highly faithful to each character's lore, silhouette, element, outfit, combat role, and personality.**

Reference families include collectible vinyl figures and articulated chibi figures such as Funko-style and Nendoroid-style proportions, but the shipping Anime Aggressors design must be original. Do not copy another company's exact head shape, eye language, proprietary packaging, trade dress, or model.

This replaces the current mannequin/proxy-looking presentation as the target V1 art direction.

## Visual design rules

Create and document an original Anime Aggressors collectible-figurine style bible.

Target qualities:
- large expressive head;
- compact articulated body;
- readable hands/feet for platform-fighter animation;
- toy/figurine material language;
- strong silhouette at gameplay camera distance;
- highly recognizable hair/head shape;
- lore-faithful outfit construction;
- elemental materials and VFX;
- readable face/emotion rather than generic mannequin features;
- cute/kawaii proportions without erasing fighter identity;
- production-rig compatibility.

Suggested starting proportion study:
- roughly 2.0–2.6 heads tall depending on fighter;
- head approximately 40–50% of full standing height;
- slightly enlarged hands/feet for action readability;
- simplified anatomy but enough shoulder/hip/limb articulation for martial-arts poses.

Do not treat those numbers as immutable; use the repo's animation/rig requirements to converge on the best playable proportion.

## Full roster requirement

V1 is not one Kaia slice.

Lock the declared V1 roster/forms in repo truth, including current roster identities such as:
- Ember Vale
- Rook Ironside
- Juno Spark
- Kaia Windrow
- Nix Calder
- Orion Vell
- Vesper Nyx
- Yin
- Yang

Reconcile any older "7 fighter" documentation with the actual declared V1 roster. Do not silently omit Yin/Yang if they are now V1.

For every V1 fighter:
- male/female variants where promised must be visibly distinct;
- lore/element silhouette must remain obvious;
- hair/head/facial silhouette must match approved character-sheet intent;
- outfit must match the character-sheet language;
- palette/materials must match element identity;
- Black Puppet / White Puppet variants must remain story variants, not substitutes for the base roster;
- transformation/forms must be labeled and wired truthfully.

## Art pipeline

Use the existing Blender -> GLB -> Godot production pipeline.

Build the style as a reusable procedural/parametric production system where possible:
- shared base rig compatibility;
- per-fighter head/hair/outfit modules;
- per-form material/VFX overrides;
- automated topology/rig/socket validation;
- turntable renders;
- front/side/back renders;
- battle-camera renders;
- animation stress renders.

Do not declare final art because a mesh imports.

## Gameplay readability

The chibi treatment must preserve:
- anticipation/action/impact/recovery readability;
- jump/dash silhouettes;
- light/heavy/special/super distinction;
- hitboxes/hurtboxes;
- weapons/props;
- elemental VFX;
- stage readability;
- male/female distinction;
- story transformations.

Re-run the movement/animation/combat acceptance matrix after proportion changes.

## Owner-review packet

Generate a review packet for every fighter/form:
1. authoritative character-sheet reference;
2. current V1 candidate turntable;
3. front/side/back;
4. neutral + combat pose;
5. battle-camera capture;
6. one signature move;
7. male/female comparison where applicable;
8. any transformation/Puppet variant;
9. mismatch list;
10. objective technical status.

Do not set:
`FINAL_CHARACTER_ART_PASS=true`
`HUMAN_ART_APPROVAL=true`
`V1_ANIME_HUMAN_PASS=true`

Those are owner-only.

## Full product regression

After art integration validate:
- roster loadability
- all promised forms
- story routes/nodes
- stages
- moves
- damage/KO truth
- animation/effects references
- web runtime
- Android build
- exact candidate provenance

## Final return

Return:
- locked style-bible path
- roster/forms matrix
- generated candidate assets
- technical validation
- owner-review packet location
- exact remaining human decisions
