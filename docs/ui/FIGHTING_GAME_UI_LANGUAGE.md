# Fighting-Game UI Language (Wave021)

## Principles

1. **Ceremony over clutter** — select, versus, pause, move list, and victory each have a distinct beat.
2. **Focus is visible** — focused fighter tile, list row, and preview share accent hierarchy.
3. **Context-local presentation** — preview/versus/victory scales never leak into battle bodies.
4. **Form literacy** — move list exposes FORM / TRANSFORMATION with glyphs and transformed-move markers.

## Select feel

- Tile focus: brightness + silhouette `set_focused(true)`.
- Preview entrance: `play_selection_focus()` on browse; `play_lock_in()` on confirm.
- Lock-in ceremony: brief victory-pose flash before stage select handoff.
- Command Guide button preserved (Wave020 centered pause layout compatible).

## Versus ceremony

- Staggered P1/P2 portrait fade + scale snap (TRANS_BACK ease).
- `PresentationContext.CTX_VERSUS` for portrait instances.
- 2.2s hold before battle — readable names + stage line.

## Pause feel

- Centered responsive shell (OWNER-REG-013) **unchanged**.
- Move list opens with full-screen dimmer; battle remains paused (`PROCESS_MODE_ALWAYS`).

## Move List feel

- New category: **FORM / TRANSFORMATION**
- Transform glyph: `Shield + Special + Attack @ Tier 3`
- Transformed move markers on form override entries
- Preview uses `CTX_MOVE_PREVIEW` isolation

## Victory ceremony

- Winner portrait at `CTX_VICTORY` display contract — **current form**, not oversized preview scale.
- Faceless head direction preserved in victory bake.

## Typography & accent

- Gold border on modal panels (`#f2b847` family)
- Element color on fighter name labels
- CPU tag subdued (0.9 alpha)
