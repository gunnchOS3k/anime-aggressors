# Playtest Checklist (~5 minutes)

Use a **fresh browser profile** or clear site data for `anime-aggressors` before starting.

## Setup

1. Open the home page (`#/`)
2. Confirm **Quick Match** is the primary button (not buried under setup or Godot)

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
