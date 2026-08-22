# VRoid Authoring Packet — Ember Vale

Status: `production-detailed`
`VROID_MODEL_CREATION=HUMAN_GUI_REQUIRED` (GUI cannot be automated in this environment; do not fabricate VRM/GLB)

## Proportions
- Adult anime-humanoid, readable at game-camera distance
- Lane silhouette: forward-leaning sprinter, asymmetric ember gauntlets, flame-tail hair volume

## Face
- Original facial structure; avoid franchise eye/hair icons
- High-contrast brows for combat readability

## Hair silhouette
- Distinct from other six fighters at black-silhouette distance
- Physics goals: secondary motion without covering hurtbox core

## Outfit construction
- Modular pieces exportable as VRM materials
- Palette: #E8453C, #F28C28, #1A0A08, #FFD27A

## Texture guide
- Base albedo, roughness, emissive accents for aura sockets
- No licensed decals

## Hand/foot readability
- Oversized combat gloves/boots preferred for hitbox alignment

## Accessories
- Lane-specific props only if they do not clip canonical sockets

## Prohibited franchise resemblance
- No costumes/logos/haircuts that read as a single protected property

## Silhouette gates
- Front / side / back black-silhouette must pass distinctiveness vs roster

## Export settings
- VRM 0.x/1.0 compatible; T-pose; meters; -Z forward / Y up after Blender normalize

## Provenance checklist
- [ ] Human GUI authored in VRoid Studio
- [ ] Export logged in content/provenance.json
- [ ] Originality review signed
- [ ] Blender normalize + rig validate PASS
