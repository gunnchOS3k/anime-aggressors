import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  BODY_PRESENTATION_COUNT,
  CANONICAL_FIGHTER_IDS,
  allocateBodyVariantForDuplicate,
  listAuthoredPresentations,
  normalizeBodyVariant,
  oppositeBodyVariant,
} from "../src/bodyVariant.js";
import { createInitialGameState } from "../src/state.js";
import { DEFAULT_RULESET } from "../src/rulesets.js";

describe("bodyVariant dual-form schema", () => {
  it("keeps seven canonical ids and fourteen presentations", () => {
    assert.equal(CANONICAL_FIGHTER_IDS.length, 7);
    assert.equal(BODY_PRESENTATION_COUNT, 14);
    assert.equal(listAuthoredPresentations().length, 14);
  });

  it("prefers unused body presentation for duplicates", () => {
    const v = allocateBodyVariantForDuplicate("rook-ironside", 1, [
      { fighter_id: "rook-ironside", body_variant: "male", seat_id: 0 },
    ]);
    assert.equal(v, "female");
  });

  it("cycles when both variants taken (>2)", () => {
    const v = allocateBodyVariantForDuplicate("rook-ironside", 2, [
      { fighter_id: "rook-ironside", body_variant: "male", seat_id: 0 },
      { fighter_id: "rook-ironside", body_variant: "female", seat_id: 1 },
    ]);
    assert.ok(v === "male" || v === "female");
  });

  it("stores presentation-only bodyVariant on players without combat reading it", () => {
    const state = createInitialGameState({
      playerCount: 2,
      stocks: 3,
      matchDurationFrames: 60,
      stageId: "skyline-arena",
      characterIds: ["ember-vale", "rook-ironside"],
      bodyVariants: ["male", "female"],
      ruleset: DEFAULT_RULESET,
      seed: 1,
    });
    assert.equal(state.players[0]!.bodyVariant, "male");
    assert.equal(state.players[1]!.bodyVariant, "female");
    assert.equal(normalizeBodyVariant("nope"), "male");
    assert.equal(oppositeBodyVariant("male"), "female");
  });
});
