# Cursor PartyLink grab finding — October 22, 2026

Official V1 and RC2 remain NOT READY. This note does not accept art, gameplay feel, balance, device, or a release gate. B02 stays CRITICAL. No animation, combat timing, VFX, audio, mesh, or visual identity file changed. Draft only. Do not merge.

## Classification

Genuine safe defect. A second PartyLink client can already put `grab: true` on the accepted input message. The LAN host then builds the game frame with `grab` forced false. The browser pad also has no grab control, so that client cannot send the bit the protocol and `InputFrame` already carry. This is not fixed by the Godot input map in draft #126.

## Where grab is dropped

- Browser pad: `packages/partylink/src/browserController.ts` had left, right, up, down, jump, attack, special, shield, dodge, and pause. No `data-act="grab"`. The existing pointer handler sends whatever `data-act` is on the button, so the missing control is the only reason the pad cannot assert grab.
- Protocol message: `ControllerInput.semantic` is an open record. `PartyRoomSession.submitInput` accepts the message without stripping keys. `InputFrame` in `packages/game-core/src/types.ts` already has `grab: boolean`. No new wire field was required.
- Host: `packages/partylink/src/lanHost.ts` `tick` copied attack, shield, dodge, and the other carried actions from `semantic`, then set `grab: false`. That overwrite is the drop. A second client's accepted `{ grab: true, attack: true }` kept attack and lost grab.
- Idle default: `emptyInput` in `hostAuthoritativeParty.ts` still uses `grab: false` when a seat sends nothing. That matches the other actions and was not changed.

## Reproduction

Base when the failure was recorded: `2d762eef5584255b099a597d206d4a1473c48a87`. PartyLink bytes are unchanged through the later art commit `7c25c2996f8adcee97ec2187a14bfc578d8681bf`, which is the commit this branch now starts from. No Godot process. No npm install.

```sh
node --experimental-transform-types --import /tmp/party-ts-register.mjs --test packages/partylink/test/partylinkGrab.test.ts
```

The register file is a local Node resolver only. It maps `@anime-aggressors/game-core` to `packages/game-core/src/index.ts` and relative `.js` specifiers onto the existing `.ts` sources. It is not part of the product change.

Before, exit 1, 2 failed:

```
✖ browser pad offers grab the same way it offers the other carried actions
  AssertionError [ERR_ASSERTION]: missing data-act=grab

✖ keeps a second client's intentional grab when the host builds the frame
  AssertionError [ERR_ASSERTION]: host dropped semantic.grab while keeping semantic.attack
  false !== true
```

The second failure is after both `/input` posts were `accepted: true`, seat 1's shield stayed true, seat 1's grab stayed false, and seat 2's attack stayed true.

After the two-line source change, the same command exits 0 (2 passed). The existing PartyLink tests in `partylink8p.test.ts`, `partylinkProductization.test.ts`, and `dualFormDuplicate.test.ts` were run with the same runner: 22 passed, 0 failed.

## Fix

- `lanHost.ts`: `grab: Boolean(i.semantic.grab)`, same shape as dodge, shield, and attack.
- `browserController.ts`: one `<button data-act="grab">Grab</button>` in the existing pad, after Dodge and before Pause. Same element pattern. No new CSS. The pedestrian pad is unchanged and still has no grab control.

## Not this defect

`HostAuthoritativePartySim.stepState` still moves a seat only from left and right. Attack, grab, jump, shield, special, and dodge do not change that sim's match state. The comment there already says full combat stepping belongs to game-core when an adapter calls simulate. This change does not add that call and does not change throw timing.

`apps/web/src/screens/PartyLobbyScreen.ts` still builds its own arena frames and hardcodes `grab: false`. It does not read posted `/input`. That display path was not changed.

Godot local grab remains the separate input-map issue in draft #126. PartyLink does not load that map.

## Not run

No local Godot import, export, editor reimport, or headless scene. `npm run test -w @anime-aggressors/partylink` was not run: this checkout has no `node_modules`, and an install was not started because free space was already under the 18 GiB reserve (about 16 GiB at start, about 15 GiB after the sparse worktree and tests). The worktree is a sparse checkout of `packages/partylink`, `packages/game-core`, and `AGENTS.md`, about 1.4 MiB. No paid runner.
