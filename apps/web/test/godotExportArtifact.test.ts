import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  isPlaceholderHtml,
  validateGodotExportDir,
} from "../../../scripts/godot-export-shared.mjs";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const repoRoot = path.resolve(webRoot, "../..");
const publicGodot = path.join(webRoot, "public/godot");

describe("godot export artifact", () => {
  it("public godot export is not placeholder", () => {
    const html = fs.readFileSync(path.join(publicGodot, "index.html"), "utf8");
    assert.equal(isPlaceholderHtml(html), false);
    assert.match(html, /\.wasm/);
    assert.match(html, /\.pck/);
    assert.doesNotMatch(html, /Placeholder export page/);
  });

  it("validateGodotExportDir passes on checked-in public export", () => {
    const result = validateGodotExportDir(publicGodot);
    assert.equal(result.ok, true, result.errors.join("; "));
    assert.ok(result.files.wasm.length > 0);
    assert.ok(result.files.pck.length > 0);
    assert.ok(result.files.js.length > 0);
  });

  it("validateGodotExportDir fails on placeholder html", () => {
    const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "godot-placeholder-"));
    const placeholder = `<!DOCTYPE html><html><body>Placeholder export page</body></html>`;
    fs.writeFileSync(path.join(tmp, "index.html"), placeholder);
    const result = validateGodotExportDir(tmp);
    assert.equal(result.ok, false);
    assert.ok(result.errors.some((e) => e.includes("placeholder")));
  });

  it("assert:godot-export script exists in package.json", () => {
    const pkg = JSON.parse(fs.readFileSync(path.join(repoRoot, "package.json"), "utf8")) as {
      scripts: Record<string, string>;
    };
    assert.equal(pkg.scripts["assert:godot-export"], "node scripts/assert-godot-export.mjs");
    assert.match(pkg.scripts["build:pages"], /assert:godot-export/);
  });

  it("export preset disables thread support for GitHub Pages", () => {
    const preset = fs.readFileSync(path.join(repoRoot, "game/godot/export_presets.cfg"), "utf8");
    assert.match(preset, /variant\/thread_support=false/);
  });
});
