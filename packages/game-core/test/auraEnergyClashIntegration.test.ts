import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { auraClashPowerBonus } from "../src/aura/auraCharge.js";
import { computeClashPush } from "../src/combat/energyClash.js";
import { createDefaultAuraState } from "../src/aura/auraTypes.js";

describe("aura energy clash integration", () => {
  it("level 3 aura adds clash power bonus deterministically", () => {
    const aura = createDefaultAuraState();
    aura.current = 90;
    aura.level = 3;
    assert.equal(auraClashPowerBonus(aura), 10);
    const push = computeClashPush(
      { power: 80 } as import("../src/combat/beamTypes.js").EnergyAttackState,
      { special: true } as import("../src/types.js").InputFrame,
      20,
      aura,
    );
    const pushNoAura = computeClashPush(
      { power: 80 } as import("../src/combat/beamTypes.js").EnergyAttackState,
      { special: true } as import("../src/types.js").InputFrame,
      20,
    );
    assert.ok(push.chargeBonus > pushNoAura.chargeBonus);
  });
});
