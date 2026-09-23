# Aura Clash — Vertical Slice

## Eligibility

Clash fires only when **both** fighters are in a high-commitment window:

- `move_type` or `move_id` in aura / super / beam / signature burst-finisher
- or `choreography.clashable == true`

Jabs, lights, tilts, and unspecified aerials **never** clash.

## Resolve

`AuraClashDirector.commitment_score` is deterministic:

`aura*10 + (startup+active)*3 + clash_weight*20 + stable_fighter_seed`

No extra input after the moves started. No mash.

Winner: higher score. Tie: draw (incoming confirm cancelled).  
Defender-win: incoming confirm cancelled.  
Attacker-win: existing hit path continues, tagged `cinematic_class=CLASH`.

Mixed-identity clashes (`attacker_id != defender_id`) combine both palettes for VFX/camera.

## Debug

Training Impact Lab → **Debug aura clash**.  
`GameState.last_aura_clash` holds the last result.

## Quality

`AURA_CLASH_SYSTEM_PASS` may be true for architecture + debug path.  
`HUMAN_AURA_CLASH_PASS` stays false until a human signs the acting.
