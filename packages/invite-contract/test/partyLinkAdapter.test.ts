import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  inviteUrlForToken,
  issueInvite,
  opaqueTokenFromBytes,
  redeemInvite,
  revokeInvite,
} from "../src/index.js";
import { ANIME_INVITE_MODE, mapTokenToPartyLinkSession } from "../src/partyLinkAdapter.js";

const NOW = 1_700_000_000_000;
const LATER = NOW + 60_000;
const SESSION_ID = "partylink-session-anime-1";

function tokenFromSeed(seed: number): string {
  const bytes = new Uint8Array(32);
  for (let i = 0; i < bytes.length; i += 1) {
    bytes[i] = (seed * 17 + i * 29 + 11) & 0xff;
  }
  const token = opaqueTokenFromBytes(bytes);
  assert.ok(token, `seed ${seed} was not an opaque token`);
  return token;
}

function bindingFor(token: string) {
  const issued = issueInvite([], token, { expiresAtMs: LATER, nowMs: NOW });
  assert.equal(issued.ok, true);
  if (!issued.ok) throw new Error("issue failed");
  assert.equal(issued.url.includes(SESSION_ID), false);
  return { sessionId: SESSION_ID, record: issued.record };
}

describe("PartyLink invite adapter", () => {
  it("returns the session id only when the contract redeems the token", () => {
    const token = tokenFromSeed(3);
    const decision = mapTokenToPartyLinkSession(token, bindingFor(token), NOW + 1);
    assert.deepEqual(decision, {
      outcome: "valid",
      sessionId: SESSION_ID,
      mode: ANIME_INVITE_MODE,
    });
    assert.equal(ANIME_INVITE_MODE, "anime match");
    const url = inviteUrlForToken(token);
    assert.equal(url.ok, true);
    if (!url.ok) return;
    assert.equal(url.url, `https://gunnchos.com/i/${token}`);
    assert.equal(url.url.includes(SESSION_ID), false);
    assert.equal(url.url.includes(String(LATER)), false);
  });

  it("returns expired when the contract record is past expiresAtMs", () => {
    const token = tokenFromSeed(4);
    const decision = mapTokenToPartyLinkSession(token, bindingFor(token), LATER);
    assert.deepEqual(decision, { outcome: "expired" });
    assert.equal(Object.hasOwn(decision, "sessionId"), false);
  });

  it("returns replayed when the contract record was already consumed", () => {
    const token = tokenFromSeed(5);
    const binding = bindingFor(token);
    const once = redeemInvite(binding.record, token, NOW + 1);
    assert.equal(once.ok, true);
    if (!once.ok) return;
    const decision = mapTokenToPartyLinkSession(
      token,
      { sessionId: binding.sessionId, record: once.record },
      NOW + 2,
    );
    assert.deepEqual(decision, { outcome: "replayed" });
  });

  it("returns revoked when the contract record was revoked", () => {
    const token = tokenFromSeed(6);
    const binding = bindingFor(token);
    const revoked = revokeInvite(binding.record, NOW + 3);
    const decision = mapTokenToPartyLinkSession(
      token,
      { sessionId: binding.sessionId, record: revoked },
      NOW + 4,
    );
    assert.deepEqual(decision, { outcome: "revoked" });
  });

  it("returns malformed for a guessable token and for a token that does not match the record", () => {
    const token = tokenFromSeed(7);
    const binding = bindingFor(token);
    assert.deepEqual(mapTokenToPartyLinkSession("ROOMCODE", binding, NOW + 1), {
      outcome: "malformed",
    });
    assert.equal(opaqueTokenFromBytes(new Uint8Array(32)), null);
    const other = tokenFromSeed(8);
    const mismatch = mapTokenToPartyLinkSession(other, binding, NOW + 1);
    assert.deepEqual(mismatch, { outcome: "malformed" });
    assert.equal(Object.hasOwn(mismatch, "sessionId"), false);
  });
});
