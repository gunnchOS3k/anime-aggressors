# Export checklist

1. Action name matches Wave A id (`heavy`, not `Heavy.001`).
2. Canonical deform bones present. Control bones `use_deform=false`.
3. Frame range matches gameplay metadata when the action is a move.
4. Markers: `AA_CONTACT`, `AA_ACTIVE_START`, `AA_ACTIVE_END`.
5. No authoritative root motion.
6. `python3 tools/authored_animation/export_action.py --fighter <id> --action <id>`
7. Sidecar written next to GLB. Status `AUTHORED_WIP`.
8. Godot import if `GODOT_BIN` is set.
9. Do not tick human approved.
