import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";

/** The same assertion must inspect the real lobby from source and dist/test. */
export function readPartyLobbySource(): string {
  const matches = [
    new URL("../../../apps/web/src/screens/PartyLobbyScreen.ts", import.meta.url),
    new URL("../../../../apps/web/src/screens/PartyLobbyScreen.ts", import.meta.url),
  ].filter((path) => existsSync(path));
  assert.equal(matches.length, 1, "exactly one repository PartyLobbyScreen source must exist");
  return readFileSync(matches[0]!, "utf8");
}
