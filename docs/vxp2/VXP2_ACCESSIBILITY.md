# VXP-2 Accessibility

## Designed treatments

- **Reduce motion**: skips menu ambient pulses, shortens versus/results celebration.
- **High contrast**: black ground, white ink, yellow focus rings + outline on titles.
- **Non-color cues**: element shape marks on fighter detail; diamond stock pips; WIN chip on results; glyph labels beside icons.

## Settings wiring

Existing Settings toggles continue to drive `DeviceRoleRuntime.reduce_motion` and `GameState.high_contrast`. VXP-2 chrome reads those flags at surface ready.

## Not claimed

Human visual validation and physical device a11y soak are **not** claimed by VXP-2.
