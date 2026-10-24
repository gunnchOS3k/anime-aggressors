import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  inviteUrlForToken,
  issueInvite,
  opaqueTokenFromBytes,
  parseInviteUrl,
  redeemInvite,
  revokeInvite,
  type InviteRecord,
} from "../src/index.js";

const NOW = 1_700_000_000_000;
const LATER = NOW + 60_000;

function tokenFromSeed(seed: number): string {
  const bytes = new Uint8Array(32);
  for (let i = 0; i < bytes.length; i += 1) {
    bytes[i] = (seed * 17 + i * 29 + 11) & 0xff;
  }
  const token = opaqueTokenFromBytes(bytes);
  assert.ok(token, `seed ${seed} was not an opaque token`);
  return token;
}

describe("shared invitation contract", () => {
  it("builds https://gunnchos.com/i/<opaque-token> and keeps every other fact off the URL", () => {
    const token = tokenFromSeed(3);
    const issued = issueInvite([], token, { expiresAtMs: LATER, nowMs: NOW });
    assert.equal(issued.ok, true);
    if (!issued.ok) return;
    assert.equal(issued.url, `https://gunnchos.com/i/${token}`);
    assert.equal(issued.url.includes(String(LATER)), false);
    assert.equal(issued.url.includes("seat"), false);
    assert.equal(issued.url.includes("?"), false);
    assert.equal(issued.url.includes("#"), false);
    assert.equal(Object.hasOwn(issued.record, "token"), false);
    assert.equal(JSON.stringify(issued.record).includes(token), false);
    const parsed = parseInviteUrl(issued.url);
    assert.deepEqual(parsed, { ok: true, token });
  });

  it("rejects guessable tokens and URLs that carry extra state", () => {
    assert.equal(opaqueTokenFromBytes(new Uint8Array(32)), null);
    assert.equal(opaqueTokenFromBytes(Uint8Array.from({ length: 32 }, (_, i) => i)), null);
    assert.equal(inviteUrlForToken("ROOMCODE").ok, false);

    const token = tokenFromSeed(9);
    const cases = [
      `http://gunnchos.com/i/${token}`,
      `https://user:secret@gunnchos.com/i/${token}`,
      `https://www.gunnchos.com/i/${token}`,
      `https://gunnchos.com:443/i/${token}`,
      `https://gunnchos.com/i/${token}?seat=1&name=Ada`,
      `https://gunnchos.com/i/${token}#save=1`,
      `https://gunnchos.com/i/${token}/extra`,
      `https://evil.example/i/${token}`,
      `https://gunnchos.com/i/${token.slice(0, 20)}%2Fadmin`,
    ];
    for (const raw of cases) {
      const parsed = parseInviteUrl(raw);
      assert.equal(parsed.ok, false, raw);
    }
  });

  it("rejects a duplicate issue, an expired redeem, a replay, and a revoked token", () => {
    const token = tokenFromSeed(4);
    const other = tokenFromSeed(5);
    const first = issueInvite([], token, { expiresAtMs: LATER, nowMs: NOW });
    assert.equal(first.ok, true);
    if (!first.ok) return;

    const duplicate = issueInvite([first.record], token, { expiresAtMs: LATER, nowMs: NOW });
    assert.deepEqual(duplicate, { ok: false, reason: "duplicate" });

    const expired = issueInvite([], other, { expiresAtMs: NOW, nowMs: NOW });
    assert.deepEqual(expired, { ok: false, reason: "expiry" });

    const stale = redeemInvite(first.record, token, LATER);
    assert.deepEqual(stale, { ok: false, reason: "expired" });

    const once = redeemInvite(first.record, token, NOW + 1);
    assert.equal(once.ok, true);
    if (!once.ok) return;
    assert.equal(once.record.consumedAtMs, NOW + 1);
    const replay = redeemInvite(once.record, token, NOW + 2);
    assert.deepEqual(replay, { ok: false, reason: "replay" });

    const revoked = revokeInvite(first.record, NOW + 3);
    assert.equal(revoked.revokedAtMs, NOW + 3);
    assert.deepEqual(redeemInvite(revoked, token, NOW + 4), { ok: false, reason: "revoked" });
    assert.equal(redeemInvite(first.record, other, NOW + 1).ok, false);

    const again = revokeInvite(revoked, NOW + 9);
    assert.equal(again, revoked);
  });

  it("can mint eight distinct tokens without treating that as deployed acceptance", () => {
    const records: InviteRecord[] = [];
    const urls = new Set<string>();
    for (let i = 0; i < 8; i += 1) {
      const token = tokenFromSeed(20 + i);
      const issued = issueInvite(records, token, { expiresAtMs: LATER, nowMs: NOW });
      assert.equal(issued.ok, true, JSON.stringify(issued));
      if (!issued.ok) return;
      records.push(issued.record);
      urls.add(issued.url);
    }
    assert.equal(urls.size, 8);
    const replayed = issueInvite(records, tokenFromSeed(20), { expiresAtMs: LATER, nowMs: NOW });
    assert.deepEqual(replayed, { ok: false, reason: "duplicate" });
  });
});
