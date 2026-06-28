import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { renderVersusConfirmPanel, renderPlayerLoadoutCard } from "../src/ui/setup/VersusConfirmPanel.ts";
import { getDefaultCreatedFighter } from "@anime-aggressors/game-core";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

describe("controls check versus", () => {
  it("controls screen uses versus confirm panel", () => {
    const src = fs.readFileSync(path.join(webRoot, "src/screens/MatchSetupControlsScreen.ts"), "utf8");
    assert.match(src, /renderVersusConfirmPanel/);
    assert.match(src, /renderPlayerLoadoutCard/);
    assert.match(src, /Start Battle/);
  });

  it("versus panel shows P1 vs P2 with portraits", () => {
    const p1 = getDefaultCreatedFighter(0);
    const p2 = getDefaultCreatedFighter(1);
    const html = renderVersusConfirmPanel(
      renderPlayerLoadoutCard("Player 1", p1, "Keyboard"),
      renderPlayerLoadoutCard("Player 2", p2, "Gamepad"),
      "<div>summary</div>",
    );
    assert.match(html, /VS/);
    assert.match(html, /fighter-portrait/);
    assert.match(html, /Player 1/);
    assert.match(html, /Player 2/);
  });
});
