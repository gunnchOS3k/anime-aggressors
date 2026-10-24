import { inviteUrlForToken, redeemInvite, type InviteRecord } from "./index.js";

/**
 * Maps an opaque invite token onto an existing PartyLink session id.
 * The only accept/reject input is the invite-contract result.
 * This module does not open a socket, resolve combat, or deploy a route.
 */

export const ANIME_INVITE_MODE = "anime match" as const;

export type PartyLinkInviteBinding = {
  sessionId: string;
  record: InviteRecord;
};

export type PartyLinkInviteOutcome =
  | { outcome: "valid"; sessionId: string; mode: typeof ANIME_INVITE_MODE }
  | { outcome: "expired" | "replayed" | "revoked" | "malformed" };

export function mapTokenToPartyLinkSession(
  token: string,
  binding: PartyLinkInviteBinding,
  nowMs: number,
): PartyLinkInviteOutcome {
  const url = inviteUrlForToken(token);
  if (!url.ok) return { outcome: "malformed" };
  const redeemed = redeemInvite(binding.record, token, nowMs);
  if (redeemed.ok) {
    return { outcome: "valid", sessionId: binding.sessionId, mode: ANIME_INVITE_MODE };
  }
  if (redeemed.reason === "expired") return { outcome: "expired" };
  if (redeemed.reason === "replay") return { outcome: "replayed" };
  if (redeemed.reason === "revoked") return { outcome: "revoked" };
  return { outcome: "malformed" };
}
