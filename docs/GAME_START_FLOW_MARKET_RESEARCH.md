# Game Start Flow — Market Research

## How Fighting Games Begin

Successful fighting and platform fighters follow a predictable ritual:

1. **Pick mode** — Stock, time, training, or side mode.
2. **Pick rules** — Stocks, timer, hazards, team settings.
3. **Pick stage** — Map with readable preview.
4. **Pick character(s)** — Explicit fighter selection before any gameplay sim runs.
5. **Confirm controls** — Versus layout, input profile, remapping if needed.
6. **Ready / Fight** — Countdown or "READY… FIGHT!" transition.
7. **Gameplay** — Inputs enabled only after ready sequence completes.
8. **Results** — Winner presentation, rematch, menu.

## Side Modes Still Need a Fighter

Home-run, training, and challenge modes (e.g. Impact Dummy Derby) still require a **selected playable character** before gameplay. The player must know who they are controlling for models, moves, stats, and results.

## Why This Matters

A pristine sequence:

- Reduces confusion ("who am I playing?").
- Makes the product feel like entering a match, not clicking through a web form.
- Prevents broken states (timer/results without loaded fighters).
- Matches player expectations from Smash, Rivals, Brawlhalla, and traditional fighters.

## Anime Aggressors Implementation

| Mode | Flow |
|------|------|
| Normal Match | Rules → Map → Fighters → Controls → Battle |
| Custom Game | Custom Rules → Map → Fighters → Controls → Battle |
| Flagline Clash | Setup → Teams → Controls → Battle |
| Impact Dummy Derby | **Fighter Select** → Intro → Ready → Damage → Launch → Results |
| Training | Fighter Select → Training Stage → Training |

Guards (`StartFlowGuard`, `modeEntryGuards`) redirect incomplete setup to the next required screen.
