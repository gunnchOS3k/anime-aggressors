const CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

export function generateRoomCode(length = 5): string {
  let out = "";
  for (let i = 0; i < length; i++) {
    out += CODE_ALPHABET[Math.floor(Math.random() * CODE_ALPHABET.length)]!;
  }
  return out;
}

export function sanitizePlayerName(name: string): string {
  const cleaned = name
    .replace(/[^\p{L}\p{N} _.-]/gu, "")
    .trim()
    .slice(0, 24);
  return cleaned.length > 0 ? cleaned : "Player";
}

export function createParticipantToken(): string {
  const bytes = new Uint8Array(24);
  for (let i = 0; i < bytes.length; i++) bytes[i] = Math.floor(Math.random() * 256);
  return Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
}

export function buildJoinQrPayload(opts: {
  code: string;
  gameId: string;
  role: "PLAYER" | "SPECTATOR";
  baseUrl?: string;
}): string {
  const base = opts.baseUrl ?? "partylink://join";
  return `${base}?game=${encodeURIComponent(opts.gameId)}&code=${opts.code}&role=${opts.role}`;
}

export function createSessionId(): string {
  return `pls_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 10)}`;
}
