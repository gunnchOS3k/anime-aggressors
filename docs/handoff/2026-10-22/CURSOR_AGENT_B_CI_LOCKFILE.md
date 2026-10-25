# Agent B CI lockfile — 2026-10-22

Official V1.0.0 and RC2 remain **NOT READY** and **NOT AUTHORIZED**. Nothing here was merged, deployed, tagged, or pointed at by a DNS change. gunnchos.com was not edited. #131 was not merged into #123. B04 and B05 stay open. #127 and #128 stay open and were not updated.

The commit that adds this file is the pull request tip. Its parent is the lockfile commit `2e681d823494ea95d61f86c137767b7a56964c67`.

## npm ci

Old head: `c41b59694877e8ea1bf7f20b4f5f305113a9c56e`

Failed run: https://github.com/gunnchOS3k/anime-aggressors/actions/runs/39873111838 (workflow `ci`, job `web`, head `c41b5969`)

Quoted npm error:

```
npm error code EUSAGE
npm error `npm ci` can only install packages when your package.json and package-lock.json or npm-shrinkwrap.json are in sync. Please update your lock file with `npm install` before continuing.
npm error Missing: @anime-aggressors/invite-contract@0.0.0 from lock file
npm error Missing: @anime-aggressors/invite-contract@0.0.0 from lock file
```

The workspace glob `packages/*` already included `packages/invite-contract` at version `0.0.0`. No package.json dependency was added. `npm install --package-lock-only` reported the tree up to date and wrote nothing. npm's ideal tree was missing two lock entries, which is why the message is repeated: `node_modules/@anime-aggressors/invite-contract` and `packages/invite-contract`.

Lockfile change: those two entries only. The package entry is name `@anime-aggressors/invite-contract` and version `0.0.0`, matching `packages/invite-contract/package.json`. No versions were invented. The CI workflow still runs `npm ci`. Local `npm ci` was not run. Disk free space was about 12 GiB, under the 18 GiB reserve.

Lockfile head: `2e681d823494ea95d61f86c137767b7a56964c67`

Passing run: https://github.com/gunnchOS3k/anime-aggressors/actions/runs/39898893049

Conclusion: **success**. Job `web` log:

```
added 42 packages, and audited 53 packages in 3s
```

The push run of the same workflow also succeeded: https://github.com/gunnchOS3k/anime-aggressors/actions/runs/39898888497

Wave016 and Wave017 still fail with process exit codes, the same workflows that failed on `c41b5969`. Those logs do not show the invite-contract `npm ci` error.

## Two-client evidence

`packages/partylink/test/twoClientPostedFrames.test.ts` started the existing LAN host and posted from two separate Node processes. Local command, no `npm install` and no Godot:

```
PARTYLINK_ROOT=$PWD node --experimental-transform-types --import /tmp/party-ts-register.mjs --test packages/partylink/test/twoClientPostedFrames.test.ts packages/partylink/test/postedGrabFrame.test.ts
```

Result: 2 passed, 0 failed.

Proven:

- Each process post was accepted and the host consumed both on one tick.
- The silent seat had no served input.
- A non-JSON `/input` body was rejected with HTTP 500 and `ok: false`.
- The grab bit, attack bit, and right bit survived on the served frame.
- `stepState` changed `x` by `+256` for right and `-256` for left. The silent seat's `x` stayed put.
- `y`, `stocks`, `damage`, `vx`, `vy`, `grabTargetId`, and `grabbedByPlayerId` stayed at the values from before the tick.
- Existing `session.disconnect` plus `POST /reconnect` restored the same participant id and seat. A later right+grab post moved `x` by another `+256`, and grab still survived.

Not proven: contact, throw ownership, damage, or a match outcome. `stepState` does not call `simulateFrame`. A served grab bit is not combat resolution. This is not multiplayer acceptance.

## Adapters

Left unchanged. Checks on the existing heads were success, not a lockfile failure.

| Repo | PR | SHA | Checks |
|---|---|---|---|
| pedestrian-pursuit | https://github.com/gunnchOS3k/pedestrian-pursuit/pull/43 | `980d20ae448afaa480757de7131f281804d86ab8` | gate1, wave010, windows-pilot0, wp014, godot-headless: success |
| beatlink-party | https://github.com/gunnchOS3k/beatlink-party/pull/33 | `b534d50acb46af8b4a875d213075384ce55bdbaf` | build-and-test, gate1, wave007, windows-pilot0: success |
| archive-of-life-artifact-world | https://github.com/gunnchOS3k/archive-of-life-artifact-world/pull/44 | `5f8489f1b759337a2bbb559ce4b4f0d661356654` | build-and-audit, gate1, wave008, windows-pilot0: success |

Beatlink two-client evidence was not run. `scripts/browser-two-client-evidence.mjs` imports `playwright` and requires a server on port 3001 and the web app on port 5173. This checkout has no root `node_modules`, no `apps/server/node_modules`, and no `apps/web/node_modules`, so `vitest`, `socket.io-client`, and `playwright` are absent. They were not installed. No Beatlink server was started. No multiplayer acceptance is claimed.

## Codex compatibility

Observed Codex worktree HEAD, read only: `f3753775df43592b0c29a06d0b8329abfc35164e` on `release/anime-v1-dialogue-and-elemental-performance`. That matches the claimed SHA.

Original #131 base recorded by the prior handoff: `7c25c2996f8adcee97ec2187a14bfc578d8681bf`. Merge-base of that commit and `f3753775` is `7c25c299`. Codex is 18 commits ahead of that base. Name-only diff of those 18 commits against the #131 file list has **no overlapping paths**. Codex names are hand-review and production artifact files. #131 names are PartyLink, the invite-contract package, `package-lock.json`, Party Lobby, and these handoff docs. No cherry-pick onto #123. No merge.

## Not edited

Story worktrees, story scripts, Codex art, the portal, and gunnchos.com. The Codex worktree was not modified.
