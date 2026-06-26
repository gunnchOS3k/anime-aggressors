import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { getMapStripOrder, renderFlaglineMapStrip } from "../src/screens/FlaglineMapView.ts";

describe("flagline HUD map strip", () => {
  it("orders rooms from Lunar Base to Solar Base", () => {
    assert.deepEqual(getMapStripOrder(), [-2, -1, 0, 1, 2]);
  });

  it("marks current room in strip", () => {
    const html = renderFlaglineMapStrip(0);
    assert.ok(html.includes("Center"));
    assert.ok(html.includes("▲"));
  });
});
