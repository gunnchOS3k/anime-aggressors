import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  allocatePreferredBodyVariant,
  assignDuplicateIdentity,
  identityPass,
  partyDuplicateAllocationSafe,
} from "../src/duplicateIdentity.js";

describe("PartyLink dual-form duplicate allocation", () => {
  it("prefers different body presentations first", () => {
    const seats = [{ fighterId: "rook-ironside", seatIndex: 0, bodyVariant: "male" as const }];
    const id = assignDuplicateIdentity("rook-ironside", 1, seats);
    assert.equal(id.bodyVariant, "female");
    assert.equal(id.accentOnly, false);
  });

  it("uses seat accents only when >2 share a fighter", () => {
    const seats = [
      { fighterId: "rook-ironside", seatIndex: 0, bodyVariant: "male" as const },
      { fighterId: "rook-ironside", seatIndex: 1, bodyVariant: "female" as const },
    ];
    const third = assignDuplicateIdentity("rook-ironside", 2, seats);
    assert.equal(third.accentOnly, true);
    assert.equal(third.badgeLabel, "P3");
    assert.ok(third.auraRingColor);
  });

  it("remains 2/4/6/8 safe", () => {
    for (const n of [2, 4, 6, 8]) assert.equal(partyDuplicateAllocationSafe(n), true);
    assert.equal(partyDuplicateAllocationSafe(3), false);
  });

  it("identityPass holds for 8 duplicate seats", () => {
    const built: ReturnType<typeof assignDuplicateIdentity>[] = [];
    for (let i = 0; i < 8; i++) {
      built.push(
        assignDuplicateIdentity(
          "ember-vale",
          i,
          built.map((b, j) => ({
            fighterId: "ember-vale",
            seatIndex: j,
            bodyVariant: b.bodyVariant,
          })),
        ),
      );
    }
    assert.equal(identityPass(built), true);
    assert.equal(allocatePreferredBodyVariant("ember-vale", 0, []), "male");
  });
});
