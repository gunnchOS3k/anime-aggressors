# Agent B invite adapters — 2026-10-22

Official V1.0.0 and RC2 remain **NOT READY** and **NOT AUTHORIZED**. Nothing here was merged, deployed, tagged, or pointed at by a DNS change. No money was spent. This is not a public server, not a gunnchos.com website change, and not a GamePigeon claim.

B02 stays **CRITICAL**. B04 and B05 stay open. Anime #127 and #128 stay open and were not updated. The existing PartyLink handoff in this directory was left in place.

The commit that adds this file is the pull request tip. Its parent is the PartyLink adapter commit `4b954671d91e20d54a5a187fef1ae5e94c92d295`.

## Anime PartyLink adapter

- Pull request: https://github.com/gunnchOS3k/anime-aggressors/pull/131
- Branch: `eng/cursor-v1-agent-b-partylink-grab-and-post`
- Base: `7c25c2996f8adcee97ec2187a14bfc578d8681bf`
- Prior tip, rechecked before this pass: `86f011d78bac9e3a64008b924c8b44a9bfb6aca8`
- Posted-frame commit: `a0e6b660f23d66addb2b412d4c6cee36f7f057f7`
- Invite contract commit: `d8f0cb18600c69f1e544c25388eaf38786710e58`
- Adapter commit: `4b954671d91e20d54a5a187fef1ae5e94c92d295`
- Module: `packages/invite-contract/src/partyLinkAdapter.ts`

`mapTokenToPartyLinkSession` returns a PartyLink session id only when `redeemInvite` accepts the opaque token. The other outcomes are `expired`, `replayed`, `revoked`, and `malformed`. The mode label is `anime match`. No new network listener. `stepState` was not edited. Attack and grab on a served frame are still not combat resolution.

Tests, no `npm install`:

```
PARTYLINK_ROOT=$PWD node --experimental-transform-types --import /tmp/party-ts-register.mjs --test packages/invite-contract/test/partyLinkAdapter.test.ts packages/invite-contract/test/inviteContract.test.ts
```

Result: 9 passed, 0 failed (5 adapter outcomes, 4 existing contract tests).

## Product adapters

Each one is a pure function in `invite-adapter/sessionInvite.mjs`. It accepts an opaque token and a session record `{ id, expiresAt, revoked, used, capacity }`. It returns join-allowed or `expired`, `revoked`, `replayed`, `malformed`, or `full`. The URL is only `https://gunnchos.com/i/<opaque-token>`. The checked rules point at anime PR 131 `packages/invite-contract`. These repos do not import that package.

| Repo | PR | Branch | SHA | Mode |
|---|---|---|---|---|
| pedestrian-pursuit | https://github.com/gunnchOS3k/pedestrian-pursuit/pull/43 | `eng/cursor-v1-agent-b-pp-invite` | `980d20ae448afaa480757de7131f281804d86ab8` | pedestrian race |
| beatlink-party | https://github.com/gunnchOS3k/beatlink-party/pull/33 | `eng/cursor-v1-agent-b-beatlink-invite` | `b534d50acb46af8b4a875d213075384ce55bdbaf` | beatlink room |
| archive-of-life-artifact-world | https://github.com/gunnchOS3k/archive-of-life-artifact-world/pull/44 | `eng/cursor-v1-agent-b-archive-invite` | `5f8489f1b759337a2bbb559ce4b4f0d661356654` | archive expedition |

Archive mode is `archive expedition`. No versus combat was added. Game art and rules were not changed. Pedestrian PR #42 was not edited.

Command and result in each worktree, no install:

```
node --test invite-adapter/sessionInvite.test.mjs
```

Each file: 4 passed, 0 failed. The seed-3 token matches the anime contract vector `Plt4lbLP7AkmQ2B9mrfU8Q4rSGWCn7zZ9hMwTWqHpME`. The URL reject reasons match the anime contract tests.

Worktrees were indexed from `origin/main` without a full checkout. Disk stayed about 15 GiB free.

## BeatLink server

Not deployed. No public room was started.

The two-client process test was not run. The missing prerequisite is a local install of `node_modules` that provides `vitest`, `socket.io-client`, and `playwright`, plus a BeatLink server on port 3001 and the web app on port 5173. This checkout has no root `node_modules` and no `apps/server/node_modules`. `scripts/browser-two-client-evidence.mjs` requires that server, that web app, and playwright. `tests/game_rc_002_session.test.ts` requires vitest and `socket.io-client`. Those were not installed, and a server was not started.

## Coordinator note

Portal PR https://github.com/gunnchOS3k/gunnchos-research-portal/pull/56 head `8707314e0bee73a7dec7f2625518f0067f555b67` adds only `docs/release/coordination/2026-10-22/updates/agent-b-pr131.md`. `BLOCKERS.json`, `CURRENT.json`, `RELEASE_MATRIX`, and the A–O denominators were not edited.

## Not edited

Story, campaign, `GameState`, and replay files. WAIKE, gunnchAI3k, and 3k MLV. The production website. Branches for #127 and #128. The Codex worktree `_anime_v1_closure`. Dirty main checkouts.
