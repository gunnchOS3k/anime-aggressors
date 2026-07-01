# Fighter Production Spec Template

Copy this template for new roster members.

## 1. Fantasy


## 2. Silhouette


## 3. Body type


## 4. Movement identity


## 5. Difficulty

- Beginner:
- Intermediate:
- Advanced:

## 6. Attack style


## 7. Special style


## 8. Aura visual language


## 9. VFX sockets

- aura_core:
- right_hand:
- left_hand:
- weapon_tip:

## 10. Animation list

idle, walk, run, dash, jump, double_jump, fall, land, neutral_attack, side_attack, up_attack, down_attack, neutral_special, side_special, up_special, down_special, aura_charge, hitstun_light, hitstun_heavy, launch, victory, defeat

## 11. Victory pose


## 12. Defeat pose


## 13. Required assets

- `assets/blender/fighters/<id>/<id>.blend`
- `assets/exports/godot/fighters/<id>.glb`
- Material palette JSON or spec section

## 14. Acceptance criteria

- [ ] Silhouette readable at default camera
- [ ] All required animations exported
- [ ] `FighterAssetContract.validate()` passes
- [ ] No DEBUG FALLBACK in shipping build
