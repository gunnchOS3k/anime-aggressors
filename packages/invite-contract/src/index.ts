import { createHash, timingSafeEqual } from "node:crypto";

/**
 * Shared invitation contract (INV-01 draft).
 *
 * The URL is only https://gunnchos.com/i/<opaque-token>.
 * Expiry, revocation, and single-use state live on the record, never in the URL.
 * This module does not bind a product, open a socket, or deploy a route.
 */

export const INVITE_ORIGIN = "https://gunnchos.com";
export const INVITE_PATH_PREFIX = "/i/";
export const OPAQUE_TOKEN_BYTES = 32;

export type InviteRecord = {
  tokenHash: string;
  expiresAtMs: number;
  revokedAtMs: number | null;
  consumedAtMs: number | null;
};

export type InviteFailure =
  | "token"
  | "malformed_url"
  | "encoded_or_whitespace"
  | "not_https"
  | "userinfo"
  | "wrong_host"
  | "port"
  | "query"
  | "fragment"
  | "path"
  | "expiry"
  | "duplicate"
  | "mismatch"
  | "revoked"
  | "expired"
  | "replay";

export type InviteUrlResult = { ok: true; url: string } | { ok: false; reason: InviteFailure };

export type ParsedInvite = { ok: true; token: string } | { ok: false; reason: InviteFailure };

export type IssuedInvite =
  | { ok: true; record: InviteRecord; url: string }
  | { ok: false; reason: InviteFailure };

export type RedeemedInvite = { ok: true; record: InviteRecord } | { ok: false; reason: InviteFailure };

const TOKEN_PATTERN = /^[A-Za-z0-9_-]{43}$/;

function bytesLookUnguessable(bytes: Uint8Array): boolean {
  if (bytes.length !== OPAQUE_TOKEN_BYTES) return false;
  const distinct = new Set(bytes).size;
  if (distinct < 16) return false;
  let monotonic = true;
  for (let i = 1; i < bytes.length; i += 1) {
    const step = (bytes[i]! - bytes[i - 1]! + 256) % 256;
    if (step !== 1) {
      monotonic = false;
      break;
    }
  }
  return !monotonic;
}

export function opaqueTokenFromBytes(bytes: Uint8Array): string | null {
  if (!bytesLookUnguessable(bytes)) return null;
  const token = Buffer.from(bytes).toString("base64url");
  if (!TOKEN_PATTERN.test(token)) return null;
  return token;
}

export function isOpaqueInviteToken(token: string): boolean {
  if (!TOKEN_PATTERN.test(token)) return false;
  const bytes = Buffer.from(token, "base64url");
  if (bytes.length !== OPAQUE_TOKEN_BYTES) return false;
  return bytesLookUnguessable(bytes);
}

export function hashInviteToken(token: string): string {
  return createHash("sha256").update(token, "utf8").digest("hex");
}

export function inviteUrlForToken(token: string): InviteUrlResult {
  if (!isOpaqueInviteToken(token)) return { ok: false, reason: "token" };
  return { ok: true, url: `${INVITE_ORIGIN}${INVITE_PATH_PREFIX}${token}` };
}

export function parseInviteUrl(raw: string): ParsedInvite {
  if (raw.includes("%") || raw.includes("\\") || /\s/.test(raw)) {
    return { ok: false, reason: "encoded_or_whitespace" };
  }
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    return { ok: false, reason: "malformed_url" };
  }
  if (url.protocol !== "https:") return { ok: false, reason: "not_https" };
  if (url.username || url.password) return { ok: false, reason: "userinfo" };
  if (url.hostname !== "gunnchos.com") return { ok: false, reason: "wrong_host" };
  // WHATWG URL hides the default :443, but the written invite must not carry a port.
  if (url.port || raw.startsWith("https://gunnchos.com:")) return { ok: false, reason: "port" };
  if (url.search) return { ok: false, reason: "query" };
  if (url.hash) return { ok: false, reason: "fragment" };
  const parts = url.pathname.split("/").filter((part) => part.length > 0);
  if (parts.length !== 2 || parts[0] !== "i") return { ok: false, reason: "path" };
  const token = parts[1]!;
  if (!isOpaqueInviteToken(token)) return { ok: false, reason: "token" };
  return { ok: true, token };
}

function hashesMatch(storedHex: string, presentedToken: string): boolean {
  if (!/^[0-9a-f]{64}$/.test(storedHex)) return false;
  const stored = Buffer.from(storedHex, "hex");
  const presented = createHash("sha256").update(presentedToken, "utf8").digest();
  return stored.length === presented.length && timingSafeEqual(stored, presented);
}

export function issueInvite(
  existing: readonly InviteRecord[],
  token: string,
  opts: { expiresAtMs: number; nowMs: number },
): IssuedInvite {
  if (!isOpaqueInviteToken(token)) return { ok: false, reason: "token" };
  if (!(opts.expiresAtMs > opts.nowMs)) return { ok: false, reason: "expiry" };
  const tokenHash = hashInviteToken(token);
  if (existing.some((record) => hashesMatch(record.tokenHash, token))) {
    return { ok: false, reason: "duplicate" };
  }
  const url = inviteUrlForToken(token);
  if (!url.ok) return url;
  const record: InviteRecord = {
    tokenHash,
    expiresAtMs: opts.expiresAtMs,
    revokedAtMs: null,
    consumedAtMs: null,
  };
  return { ok: true, record, url: url.url };
}

export function revokeInvite(record: InviteRecord, nowMs: number): InviteRecord {
  if (record.revokedAtMs != null) return record;
  return { ...record, revokedAtMs: nowMs };
}

export function redeemInvite(record: InviteRecord, token: string, nowMs: number): RedeemedInvite {
  if (!isOpaqueInviteToken(token) || !hashesMatch(record.tokenHash, token)) {
    return { ok: false, reason: "mismatch" };
  }
  if (record.revokedAtMs != null) return { ok: false, reason: "revoked" };
  if (!(record.expiresAtMs > nowMs)) return { ok: false, reason: "expired" };
  if (record.consumedAtMs != null) return { ok: false, reason: "replay" };
  return { ok: true, record: { ...record, consumedAtMs: nowMs } };
}
