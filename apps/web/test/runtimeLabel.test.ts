import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { runtimeKindForMode, runtimeLabelForKind, renderRuntimeBanner } from "../src/ui/runtimeLabel.ts";

describe("runtime labels", () => {
  it("maps godot route to godot-primary", () => {
    assert.equal(runtimeKindForMode("godot"), "godot-primary");
    assert.match(renderRuntimeBanner("godot-primary"), /Godot Runtime/);
  });

  it("maps battle to legacy web", () => {
    assert.equal(runtimeKindForMode("battle"), "legacy-web");
    assert.match(renderRuntimeBanner("legacy-web"), /Legacy Web Runtime — reference only/);
  });

  it("maps prototype to labs", () => {
    assert.equal(runtimeKindForMode("prototype"), "labs");
  });
});
