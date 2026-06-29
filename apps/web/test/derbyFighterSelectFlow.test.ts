import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { APP_ROUTES } from "../src/routes.ts";
import { MODE_ROUTE_MAP } from "../src/navigation/modeRouteMap.ts";

describe("derby fighter select flow", () => {
  it("derby mode route map starts with fighter select", () => {
    const steps = MODE_ROUTE_MAP.impactDummyDerby;
    assert.equal(steps[0]?.route, APP_ROUTES.impactDummyDerbySelectFighter);
    assert.equal(steps[0]?.mode, "impact-dummy-derby-fighter-select");
  });

  it("select-fighter route is canonical hash", () => {
    assert.equal(APP_ROUTES.impactDummyDerbySelectFighter, "#/impact-dummy-derby/select-fighter");
  });
});
