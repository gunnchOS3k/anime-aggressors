# Owner Full-Roster Movement Feel Review

**PR:** #118 (`v4/dual-form-power-roster`)  
**Purpose:** Human movement/feel approval against **rendered** motion evidence — not JSON metadata alone.  
**Automation status:** Digital semantic uniqueness + rendered review packets are ready. Human gates remain open.

## Evidence locations

- Rendered contact sheets + GIF strips: `artifacts/animation_authority_v1/rendered_review/<fighter>/`
- Index: `artifacts/animation_authority_v1/RENDERED_MOTION_REVIEW_INDEX.json`
- Semantic distance: `artifacts/animation_authority_v1/SEMANTIC_MOTION_DISTANCE_MATRIX.json`
- Cross-fighter differentiation: `artifacts/animation_authority_v1/CROSS_FIGHTER_VISUAL_DIFFERENTIATION.json`
- Runtime playback proof: `artifacts/animation_authority_v1/RUNTIME_CANDIDATE_PLAYBACK_PROOF.json`
- Move frame sync: `artifacts/animation_authority_v1/MOVE_ANIMATION_FRAME_SYNC_168.json`

## Outcome options (do not prefill PASS)

Per fighter, set one of: `PASS` | `FIX_REQUIRED` | `DEFERRED`

## Review checklist (per spectrum fighter)

Fighters: Ember Vale · Rook Ironside · Juno Spark · Kaia Windrow · Nix Calder · Orion Vell · Vesper Nyx

For each fighter, answer:

1. Does idle express the power?
2. Does run/dash feel unique?
3. Does jump/landing match weight?
4. Can attacks be read with VFX off?
5. Do heavy attacks feel stronger than lights?
6. Do reactions preserve identity?
7. Is the fighter readable at gameplay scale?
8. Do male/female presentations preserve motion parity?
9. Do puppet variants alter identity without becoming a different moveset?
10. Does Prismatic progression feel additive rather than recolored?

### Ember Vale — outcome: _pending_
Notes:

### Rook Ironside — outcome: _pending_
Notes:

### Juno Spark — outcome: _pending_
Notes:

### Kaia Windrow — outcome: _pending_
Notes:

### Nix Calder — outcome: _pending_
Notes:

### Orion Vell — outcome: _pending_
Notes:

### Vesper Nyx — outcome: _pending_
Notes:

## Pixel / G7

If Pixel is connected after exact-head CI is green: build exact #118 head, signer-safe `adb install -r`, capture owner movement-review packet.  
If no device: `G7=REQUIRES_PHYSICAL`.

## Gates automation must not flip

- `G6_VISUAL_READABILITY=REQUIRES_HUMAN`
- `G8_HUMAN_FEEL=REQUIRES_HUMAN`
- `G9_FINAL_ART_APPROVED=REQUIRES_HUMAN`
- `MERGE_AUTHORIZED=false`
