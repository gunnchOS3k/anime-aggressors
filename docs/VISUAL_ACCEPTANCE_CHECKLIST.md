# Visual acceptance checklist

Use before merging Three.js platform-fighter changes or tagging a demo release.

- [ ] Does the first screen say **platform fighter**, not mini-game collection?
- [ ] Can a visitor immediately start a match via **Play Match**?
- [ ] Are there two fighters on a 2.5D stage (Skyline Arena)?
- [ ] Is there a clear side-view / orthographic platform-fighter camera?
- [ ] Do attacks visibly produce hit sparks?
- [ ] Does knockback read clearly (fighter displacement + hitstun flash)?
- [ ] Are KOs visible and satisfying (stock loss + KO flash)?
- [ ] Can the player rematch from the results screen?
- [ ] Can debug mode show hitboxes/hurtboxes (F2)?
- [ ] Does the game feel closer to Smash-like platform-fighter readability than the prior mini-games?

## Capture for PR

1. Homepage showing Play Match as primary CTA
2. Character select → match start
3. Mid-fight with HUD (damage, stocks, timer)
4. Hit spark on connect
5. Debug overlay with hitboxes (F2)
6. Results screen + rematch

```bash
npm run dev
# open http://localhost:5173/anime-aggressors/
```

For GitHub Pages, verify the deployed URL after `build:pages`.
