# Development feature preservation — before release reconciliation

Readback: October24,2026. This is a source-preservation comparison, not release
acceptance or a merge instruction. `anime.gunnchos.com` was not used as an input.

## Advanced Codex source retained

Active branch: `release/anime-v1-dialogue-and-elemental-performance`.
The local pilot corrections descend from the verified support checkpoint
`db309e1b4d44913c07aef5706a71a609626ab4b9`. No reset/restore from main or the gala
deployment occurred. Exact latest delivery is `git rev-parse HEAD`.

Draft123 remains stacked on draft122. Its current parent head
`c5f3be23bf7376f2a0b71a8aabc1396415ef8186` is an ancestor of the active art branch.
The current source retains145dialogue nodes and1,025cues, nine fighter identities,
both bodies, the existing form/Party-overdrive and Perfect Guard implementations,
direct-throw ownership, projectile interactions, authored animation/control work,
and prior Story/earned-progression evidence. Count/source presence does not prove
all campaigns or final artistic quality accepted.

Art production uses the preserved original8D3 source archive from producer
`42baaab8cc5167798aea7f3aebb22edae9f21007`, with manifest/source hashes checked by
the live preflight and producer. It does not use deployed game assets as source.
All42worktrees and original18rigs/actions remain retained.

## Independent Cursor corrections retained, not silently integrated

The following remote heads match their existing local Cursor worktrees. None of
these heads is an ancestor of the active Codex art head. They remain preserved on
their own draft branches; patch equivalence is not asserted. Cursor owns reviewed
reconciliation. No merge/cherry-pick/rebase or write to those worktrees occurred.

| PR | Current head | Preserved candidate / reconciliation scope |
|---|---|---|
|124|`b74cf3c6956bce4bda9c44d913707c3e3547c57e`|Form-audio shutdown diagnosis/documentation; do not call it a new cleanup fix|
|125|`d12fba82ad8d5301721f852a9075941130fc3c0f`|Raw form-acting GLBs in Web/Android packs|
|126|`46cf7ffeecd4950eb16d6cb731b41ab99dd66976`|Player1 joypad up/down/grab bindings|
|127|`9dd5e3e8be8fe82f98c9d5e00c660952d7cbc4de`|Intentional PartyLink grab on the host frame|
|128|`efd26b2394febf78bc2ce287c73ed5e774a7812e`|Second client's posted Party frame|
|129|`b8eecbc5d7c63f26fd78e47210aef4229a43abd0`|Saved stocks, CPU level and timer restoration|
|130|`cfd6e71de9007f010e24c68bbbc8834d96b738cd`|Private-match replay persistence|
|131|`ba22766c29be879d3c9cc2416e69d0245a245524`|Combined PartyLink grab/posted-client-frame correction; reconcile overlap with127/128|
|132|`524f81618063fcdde8b1d34210869723bb8c387f`|Story Next Route advances past earliest open campaign|

The124 and130 worktrees each have one dirty entry; they were left untouched.
The other seven Cursor worktrees were clean at this readback. All nine PRs are
OPEN/DRAFT and unmerged. A preserved candidate is not owner acceptance.

## Still required on the unified candidate

- Cursor reviews/integrates the appropriate nonduplicated corrections against the
  newest Codex art/gameplay branch, preserving its122ancestry and source assets.
- Run affected exact-source checks after reconciliation; earlier isolated green
  tests are not validation of the future combined candidate.
- Actual native controller/grab/counterplay, save/restart/route navigation, genuine
  two-client LAN/PartyLink and replay, audio lifecycle, and packaged form-art tests.
- Complete earned campaign/Convergence and platform/device acceptance still open.
- Inspect the one original paired-art pilot before any batch; native import or
  a technical export cannot grant human art/roster/gameplay approval.

`V1_0_0_RELEASE_AUTHORIZED=false`, `RC2_READY=false`. No merge, deployment or tag.
