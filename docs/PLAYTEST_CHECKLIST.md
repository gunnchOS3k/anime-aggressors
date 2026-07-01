# Playtest Checklist (~5 minutes)

Use a **fresh browser profile** or clear site data for `anime-aggressors` before starting.

## Setup

1. Open the home page (`#/`)
2. Confirm **Play Demo** is the primary button (not buried under setup or Godot)

## Quick Match flow

3. Click **Quick Match**
4. Battle should load on `#/battle` without a dead-end setup screen
5. Countdown → **Fight!** banner appears; no console errors

## Controls — P1 (WASD + J/K/L)

6. **A / D** — move left / right  
7. **W** or **Space** — jump (double jump allowed)  
8. **S** — fast fall while airborne  
9. **J** — attack  
10. **K** — special  
11. **L** — shield  
12. Press **H** — controls overlay toggles on/off

## Controls — P2 (arrows + numpad)

13. **← / →** — move  
14. **↑** or **Numpad0** — jump  
15. **↓** — fast fall  
16. **Numpad1–5** — attack / special / shield / dodge / grab  
17. **/** (Slash) — aura charge

## Combat readability

18. P1 attacks P2 at close range — damage % increases on HUD  
19. Hit produces visible knockback and brief hitstop  
20. Repeated frames of the same swing do **not** rack damage every frame  
21. Launch P2 off stage — stock decreases or player respawns with invuln

## Match end

22. KO opponent or win on stocks — **Results** screen appears  
23. **Rematch** starts a new countdown fight with same setup  
24. **Home** returns to menu without console errors

## Layout

25. Battle view uses full viewport width (not a narrow 1100px card)  
26. HUD (damage, stocks, timer) remains readable  
27. Home / debug toolbar does not cover the playfield

## Debug (optional)

28. **F2** toggles hitbox/hurtbox debug overlay (off by default)  
29. **F1** toggles sim debug panel

## Pass criteria

All steps complete with **no uncaught console errors** and controls matching the reference in `apps/web/src/input/controlReference.ts`.

---

## Milestone 4 — Four-fighter vertical slice

See full checklist: `docs/playtest/2026-06-30-m4-four-fighter-vertical-slice.md`

31. Character select shows all 7 fighters with Production/Preview badges  
32. Quick Match = Ember Vale vs Rook Ironside on Skyline Arena  
33. Production stages: Training Grid (flat), Skyline Arena, Neon Rooftops  
34. Training mode (`#/training`) — dummy modes 1–4, D/P reset  
35. CPU opponent levels 1–3 in custom match setup  
36. Dual gamepad auto-maps to P1/P2 when both connected

---

## Milestone 5 — Public demo readiness

See full checklist: `docs/playtest/2026-07-01-m5-public-demo-readiness.md`

37. Home exposes Play Demo, Fighter Select, Stage Select, Training, Controls, About  
38. Labs & Debug separated from main carousel  
39. First-match onboarding appears once; dismiss persists  
40. HUD shows CPU label when bot active; damage/stocks readable  
41. Results: rematch, change fighters, change stage, home  
42. Audio mute/volume in Controls  
43. `npm run build` artifact playable; hash routes work

