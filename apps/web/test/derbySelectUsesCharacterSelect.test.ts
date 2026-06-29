import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const screenSource = readFileSync(
  join(dirname(fileURLToPath(import.meta.url)), "../src/screens/CharacterSelectScreen.ts"),
  "utf8",
);

describe("derby select uses character select", () => {
  it("exports derby character select mount from shared screen", () => {
    assert.match(screenSource, /export function mountDerbyCharacterSelectScreen/);
    assert.match(screenSource, /Choose Your Derby Fighter/);
    assert.match(screenSource, /variant === "derby"/);
  });
});
