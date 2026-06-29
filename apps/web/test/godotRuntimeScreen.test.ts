import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  classifyGodotExportHtml,
  GODOT_PLACEHOLDER_MARKERS,
} from "../src/godot/godotExportStatus.ts";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

describe("GodotRuntimeScreen", () => {
  const screenSrc = fs.readFileSync(
    path.join(webRoot, "src/screens/GodotRuntimeScreen.ts"),
    "utf8",
  );

  it("shows explicit error when export is missing or placeholder", () => {
    assert.match(screenSrc, /Godot Web export is missing/);
    assert.match(screenSrc, /Placeholder export is deployed/);
    assert.match(screenSrc, /godot-export-error/);
  });

  it("hides iframe until real export is detected", () => {
    assert.match(screenSrc, /probeGodotExport/);
    assert.match(screenSrc, /classList\.add\("hidden"\)/);
    assert.match(screenSrc, /status === "ready"/);
  });

  it("does not treat placeholder markers as ready", () => {
    for (const marker of GODOT_PLACEHOLDER_MARKERS) {
      const html = `<html><body>${marker}</body></html>`;
      assert.notEqual(classifyGodotExportHtml(html), "ready", marker);
    }
  });

  it("classifies real Godot export html as ready", () => {
    const html = fs.readFileSync(path.join(webRoot, "public/godot/index.html"), "utf8");
    assert.equal(classifyGodotExportHtml(html), "ready");
  });
});
