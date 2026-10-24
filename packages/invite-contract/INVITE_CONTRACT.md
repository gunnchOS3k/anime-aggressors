# Shared invitation contract (INV-01 draft)

This is a pure-function contract for a later adapter. It is not a deployment of `https://gunnchos.com`, not a DNS change, and not a live party server. B04 and B05 stay open. V1 and RC2 stay NOT READY.

Agents who own the website, BeatLink, Pedestrian Pursuit, Archive of Life, MLV, or Device OS implement their own adapters against this file. This package does not edit those repositories.

## URL

```
https://gunnchos.com/i/<opaque-token>
```

The path has exactly two segments: `i` and one token. The scheme is `https`. The host is `gunnchos.com`, with no userinfo, port, query, or fragment.

The token is 32 unguessable bytes, encoded as base64url without padding (43 characters from `A-Za-z0-9_-`). A room code, a counter, a repeated byte, or a short string is not a token.

## What the URL must not carry

The URL carries the opaque token and nothing else. It must not carry:

- expiry or issued-at time
- display name, seat, role, or product id
- save data, session secrets, or auth tokens
- a second copy of the token in a query parameter

Those facts, when an adapter needs them, stay on the invite record outside the URL. This package's record does not even store the raw token. It stores the SHA-256 hex digest.

## Record

| Field | Meaning |
|---|---|
| `tokenHash` | SHA-256 of the canonical token text. Not the token. |
| `expiresAtMs` | Redeem fails when `nowMs` is greater than or equal to this instant. |
| `revokedAtMs` | Set by revocation. A revoked record cannot be redeemed. |
| `consumedAtMs` | Set by the first successful redeem. A second redeem is a replay. |

Issuing the same token again, including after revoke or redeem, is a duplicate and is rejected. A token that does not hash to the record is a mismatch. Revocation is idempotent.

## Functions

`packages/invite-contract/src/index.ts`

- `opaqueTokenFromBytes`
- `isOpaqueInviteToken`
- `hashInviteToken`
- `inviteUrlForToken`
- `parseInviteUrl`
- `issueInvite`
- `revokeInvite`
- `redeemInvite`

No function opens a socket, writes a DNS record, or contacts gunnchos.com.

## What this does not accept

Eight distinct tokens can be minted in a unit test. That is not the B05 acceptance of eight product invite routes, deployment provenance, or owner usability. No website route was added. No BeatLink public room was started. PartyLink host frames are a different path and are not this URL.

Adapter owners still have to bind a redeemed record to their own product, reject a replay in their own store, and show the link only after an authorized deploy. Until that acceptance exists, B05 stays open.
