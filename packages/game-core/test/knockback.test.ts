import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { computeKnockback } from "../src/combat/knockback.js";

describe("knockback", () => {
  it("increases with victim damage percent", () => {
    const low = computeKnockback({
      moveDamage: 8,
      baseKnockback: 20,
      knockbackGrowth: 1.2,
      victimDamagePercent: 10,
      victimWeight: 100,
      launchRatio: 1,
      hitStrength: "medium",
      angleDeg: -35,
    });
    const high = computeKnockback({
      moveDamage: 8,
      baseKnockback: 20,
      knockbackGrowth: 1.2,
      victimDamagePercent: 80,
      victimWeight: 100,
      launchRatio: 1,
      hitStrength: "medium",
      angleDeg: -35,
    });
    assert.ok(high.magnitude > low.magnitude);
  });

  it("heavy weight reduces knockback taken", () => {
    const light = computeKnockback({
      moveDamage: 12,
      baseKnockback: 30,
      knockbackGrowth: 1,
      victimDamagePercent: 40,
      victimWeight: 80,
      launchRatio: 1,
      hitStrength: "heavy",
      angleDeg: -45,
    });
    const heavy = computeKnockback({
      moveDamage: 12,
      baseKnockback: 30,
      knockbackGrowth: 1,
      victimDamagePercent: 40,
      victimWeight: 130,
      launchRatio: 1,
      hitStrength: "heavy",
      angleDeg: -45,
    });
    assert.ok(light.magnitude > heavy.magnitude);
  });
});
