# Agent B PartyLink handoff — 2026-10-22

Official V1.0.0 and RC2 remain **NOT READY** and **NOT AUTHORIZED**. This branch was not merged. Nothing was deployed, tagged, or pointed at by a DNS change. No money was spent. This is not a GamePigeon claim, not a public server, and not a production website deployment.

B02, B04, and B05 stay open. `stepState` still does not resolve attack, grab, hitstun, or throws. The served frame stores those bits. That is the whole combat claim.

## Where this sits

- Worktree: `anime-aggressors/.worktrees/cursor-v1-agent-b-partylink`
- Branch: `eng/cursor-v1-agent-b-partylink-grab-and-post`
- Base: `7c25c2996f8adcee97ec2187a14bfc578d8681bf` (`release/anime-v1-dialogue-and-elemental-performance`). Codex tip was re-checked and had not moved. PartyLink on that tip was unchanged, so this branch did not rebase onto a newer art commit.
- Product head recorded below: `d8f0cb18600c69f1e544c25388eaf38786710e58`
- This file is one commit on top of that product head. The pull request tip is the commit that adds this handoff.

## Reused drafts, not duplicated

| PR | Branch | SHA | What this branch did |
|---|---|---|---|
| #126 | `eng/cursor-v1-p1-joypad` | `46cf7ffeecd4950eb16d6cb731b41ab99dd66976` | Left untouched. Three device-0 events were not redone. |
| #127 | `eng/cursor-v1-partylink-grab` | `9dd5e3e8be8fe82f98c9d5e00c660952d7cbc4de` | Not merged and not committed onto. Grab mapping and the Grab button were ported by hand. |
| #128 | `eng/cursor-v1-two-client-input` | `efd26b2394febf78bc2ce287c73ed5e774a7812e` | Not merged and not committed onto. Posted-frame queue was ported by hand. |

#127 and #128 stay open until this pull request is reviewed. This pull request is the reconciliation candidate. It is not an automatic replacement. Landing #128 by itself would drop `Boolean(i.semantic.grab)`. Landing #127 by itself would keep the lobby synthesizing frames and would not publish the posted frame on the session.

## Grab bit on the posted frame

`partySimInputsFromControllerInputs` sets `grab: Boolean(i.semantic.grab)`. `consumePostedPartyFrames` drains the accepted queue and records that batch. `lanHost.ts` `tick` advances the sim with that batch and puts the same batch on the served world as `inputs`. The browser pad has `<button data-act="grab">Grab</button>`. The arena screen calls `consumePostedPartyFrames` instead of inventing `attack` / `grab` for every occupied seat.

`hostAuthoritativeParty.ts` `stepState` was not edited. A stored attack or grab does not change stocks, damage, hitstun, or a throw.

### Test, before the edit (tip `7c25c299`, exit 1)

`POST /input` for the second client was accepted. `tick()` returned players, arena, and HUD slots, and did not serve `world.inputs`.

```
✖ serves the second client's posted grab, attack, and right, and does not invent a silent seat
AssertionError: session did not serve the posted frame: {"players":[...],"arena":{...},"hudSlots":["seat_1","seat_2"]}
ℹ pass 0
ℹ fail 1
```

### Test, after (exit 0)

Same command:

```
node --experimental-transform-types --import /tmp/party-ts-register.mjs --test packages/partylink/test/postedGrabFrame.test.ts
```

The second client `POST /input` with `{ grab: true, attack: true, right: true }` is accepted. The frame served to the session, and the frame echoed by `GET /state`, has `grab`, `attack`, and `right` all true, sequence 1. The silent seat has no served frame. The Grab button is present for Anime and absent for Pedestrian. The lobby source no longer contains `attack: frames % 23`.

Result: 1 passed, 0 failed.

Existing PartyLink tests, same runner, no `npm install`: `partylink8p.test.ts`, `partylinkProductization.test.ts`, `dualFormDuplicate.test.ts` — 20 passed, 0 failed. `npm run test` was not claimed. This checkout has no `node_modules`.

## Invitation contract

Implemented on this branch as pure functions in `packages/invite-contract/`. The contract note is `packages/invite-contract/INVITE_CONTRACT.md`.

- Format: `https://gunnchos.com/i/<opaque-token>`
- 32-byte unguessable token. Expiry, duplicate issue, replay, and revocation are on the record.
- The URL has no query, fragment, port, or confidential state. The record stores a SHA-256 hash, not the raw token.
- Unit tests: 4 passed. One of them mints eight tokens and says that is not B05 acceptance.

Not implemented: website route, DNS, BeatLink public hosting, product adapters, MLV, Device OS. B04 and B05 stay open. A mocked server was not described as deployed.

## Not owned and not edited

- Story and campaign scripts, `GameState` save rules, `replay_store`, `private_netplay` (Agent A / #129 / #130)
- Blender, GLB bytes, meshes, animation, VFX, audio, combat move data
- Codex worktree `_anime_v1_closure` (still `7c25c299`, untracked art left untouched)
- Dirty main checkouts of anime, pedestrian, archive, and beatlink
- Branches for #124–#130, including no new commits on `eng/cursor-v1-partylink-grab`, `eng/cursor-v1-two-client-input`, or `eng/cursor-v1-p1-joypad`
- WAIKE, gunnchAI3k, waike-research-ops, the portal ledger, gunnchos.com, and 3k MLV

Disk during this pass was about 15 GiB free, under the 18 GiB reserve. No Godot export or import. No `npm install`.

## Coordinator

Keep #127 and #128 open while this draft is reviewed. Merge neither historical draft in place of this branch. Do not treat this draft as V1 or RC2 acceptance.
