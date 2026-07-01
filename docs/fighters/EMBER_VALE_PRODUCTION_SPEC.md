# Ember Vale — Production Spec

## 1. Fantasy
Close-range flame brawler who pressures with gauntlet strikes and burst specials.

## 2. Silhouette
Medium build, oversized flame gauntlets, angular hair crest, warm red/orange read.

## 3. Body type
Athletic medium — broad chest, exaggerated hands.

## 4. Movement identity
Forward pressure, short dash extensions, committed landings.

## 5. Difficulty
- Beginner: strong neutral jab, readable fire effects
- Intermediate: flame cross spacing, aura management
- Advanced: launch confirms off ember sweep

## 6. Attack style
Fast gauntlet jabs, flame cross side attack, rising uppercut, low ember sweep.

## 7. Special style
Flame burst — short-range explosion with stock aura cost.

## 8. Aura visual language
Embers rise from gauntlets and chest; super-ready ring behind shoulders.

## 9. VFX sockets
- aura_core: chest
- right_hand / left_hand: gauntlet cores
- weapon_tip: N/A (fists)

## 10. Animation list
Full `FighterAssetContract.REQUIRED_ANIMATIONS` set.

## 11. Victory pose
Raises flaming gauntlet; fire arc ring behind.

## 12. Defeat pose
Kneel, embers die on gauntlets.

## 13. Required assets
- `assets/blender/fighters/ember-vale/ember-vale.blend`
- `assets/exports/godot/fighters/ember-vale.glb`

## 14. Acceptance criteria
- [ ] Gauntlets readable at gameplay distance
- [ ] Neutral attack shows arm wind-up and fist extension
- [ ] Aura particles at aura_core socket only
