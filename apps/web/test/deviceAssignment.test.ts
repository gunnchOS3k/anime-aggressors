import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { renderControlsOverlayHtml } from "../src/input/controlReference.ts";

describe("device assignment docs", () => {
  it("controls overlay mentions dual gamepad auto-mapping", () => {
    const html = renderControlsOverlayHtml();
    assert.match(html, /gamepads auto-map/i);
  });
});
