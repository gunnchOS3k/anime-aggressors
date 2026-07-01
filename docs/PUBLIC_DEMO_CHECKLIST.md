# Public Demo Checklist

Use before sharing the web demo link externally.

---

## Build

- [ ] `npm run typecheck` passes
- [ ] `npm test` passes
- [ ] `npm run build` succeeds
- [ ] `apps/web/dist/index.html` exists
- [ ] Local preview loads Home at `/anime-aggressors/`

## Home & navigation

- [ ] **Play Demo** starts battle quickly
- [ ] **Fighter Select** shows all 7 fighters with production/preview badges
- [ ] **Stage Select** shows 3 production stages
- [ ] **Training** launches training grid
- [ ] **Controls** and **About** accessible
- [ ] **Labs & Debug** separated — not mixed into main carousel

## Battle

- [ ] HUD shows fighter names, damage %, stocks
- [ ] CPU label when P2 is bot
- [ ] H opens controls overlay
- [ ] First-match onboarding appears once; dismiss works
- [ ] Hit / shield / KO feedback visible
- [ ] Results: rematch, change fighters, change stage, home

## Audio

- [ ] Hit and KO sounds play (after user gesture)
- [ ] Mute and volume in Controls work

## Deployment

- [ ] Hash routes work when pasted directly
- [ ] No console errors on fresh load
- [ ] `deploy-info.txt` matches merged commit (if Pages deploy)

## Known limitations (acceptable for M5)

- Mobile touch controls incomplete
- Procedural placeholder audio/VFX
- Preview fighters balance-pending
- Career/online not part of public demo

---

**Sign-off:** _______________  **Date:** _______________
