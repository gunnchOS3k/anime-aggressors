export {
  PROTOCOL_VERSION,
  MIN_PLAYER_SEATS,
  MAX_PLAYER_SEATS,
  MAX_SPECTATOR_SEATS,
  CAPACITY_LADDER,
  ROOM_TTL_MS,
  V1_TRANSPORTS,
  isValidPlayerCount,
  assertCapacityTier,
} from "./capacity.js";
export type { CapacityTier, TransportMode } from "./capacity.js";

export type * from "./types.js";

export {
  generateRoomCode,
  sanitizePlayerName,
  createParticipantToken,
  buildJoinQrPayload,
  createSessionId,
} from "./identity.js";

export { assignDuplicateIdentity, identityPass } from "./duplicateIdentity.js";
export { frameAllFighters, arenaViewHudSlots } from "./arenaCamera.js";
export type { FighterPos, ArenaCameraFrame, ArenaCameraConfig } from "./arenaCamera.js";

export { PartyRoomSession } from "./partyRoom.js";
export type { CreateRoomOptions } from "./partyRoom.js";

export { HostAuthoritativePartySim, partyGameConfig } from "./hostAuthoritativeParty.js";
export type { PartySimInput } from "./hostAuthoritativeParty.js";

export { teamForSeat, requiredSeatsForTeamMode, PARTY_TEAM_MODES } from "./teamAssign.js";
export type { PartyTeamMode } from "./teamAssign.js";

export { renderBrowserControllerHtml } from "./browserController.js";
export { startLanPartyHost } from "./lanHost.js";
export type { LanHostHandle, LanHostOptions } from "./lanHost.js";
export { runMultiClientE2E, runCapacityLadderE2E } from "./multiClientE2E.js";
export type { MultiClientE2EResult } from "./multiClientE2E.js";
