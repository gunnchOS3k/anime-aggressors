import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  isPlaceholderHtml,
  resolveRuntimeDirFromRoot,
  validateGodotPagesExportRoot,
  validateGodotRuntimeDir,
} from "../../../scripts/godot-export-shared.mjs";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const repoRoot = path.resolve(webRoot, "../..");
const publicGodot = path.join(webRoot, "public/godot");
const publicRuntime = resolveRuntimeDirFromRoot(publicGodot);

describe("godot export artifact", () => {
  it("boot shell exists and references versioned runtime + rescue", () => {
    const bootHtml = fs.readFileSync(path.join(publicGodot, "index.html"), "utf8");
    assert.match(bootHtml, /runtime\/[^"']+\/index\.html/);
    assert.match(bootHtml, /rescue-runtime\.js\?v=/);
    assert.match(bootHtml, /AARescueRuntime|rescue runtime/i);
    assert.doesNotMatch(bootHtml, /Placeholder export page/);
  });

  it("build-manifest.json exists", () => {
    assert.ok(fs.existsSync(path.join(publicGodot, "build-manifest.json")));
  });

  it("validateGodotRuntimeDir passes on checked-in runtime export", () => {
    const result = validateGodotRuntimeDir(publicRuntime);
    assert.equal(result.ok, true, result.errors.join("; "));
    assert.ok(result.files.wasm.length > 0);
    assert.ok(result.files.pck.length > 0);
    assert.ok(result.files.js.length > 0);
  });

  it("validateGodotPagesExportRoot passes on checked-in public export", () => {
    const result = validateGodotPagesExportRoot(publicGodot);
    assert.equal(result.ok, true, result.errors.join("; "));
  });

  it("validateGodotRuntimeDir fails on placeholder html", () => {
    const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "godot-placeholder-"));
    const placeholder = `<!DOCTYPE html><html><body>Placeholder export page</body></html>`;
    fs.writeFileSync(path.join(tmp, "index.html"), placeholder);
    const result = validateGodotRuntimeDir(tmp);
    assert.equal(result.ok, false);
    assert.ok(result.errors.some((e) => e.includes("placeholder")));
  });

  it("validateGodotPagesExportRoot rejects root without runtime wasm/pck/js", () => {
    const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "godot-pages-root-"));
    fs.mkdirSync(path.join(tmp, "runtime"), { recursive: true });
    fs.writeFileSync(
      path.join(tmp, "index.html"),
      '<html><script src="rescue-runtime.js"></script><iframe src="runtime/index.html"></iframe>AARescueRuntime</html>',
    );
    fs.writeFileSync(path.join(tmp, "rescue-runtime.js"), "window.AARescueRuntime = {};");
    fs.writeFileSync(path.join(tmp, "runtime", "index.html"), "<html>not godot</html>");
    const result = validateGodotPagesExportRoot(tmp);
    assert.equal(result.ok, false);
  });

  it("assert:godot-export and godot:export:web scripts match canonical exporter", () => {
    const pkg = JSON.parse(fs.readFileSync(path.join(repoRoot, "package.json"), "utf8")) as {
      scripts: Record<string, string>;
    };
    assert.equal(pkg.scripts["assert:godot-export"], "node scripts/assert-godot-export.mjs");
    assert.equal(pkg.scripts["godot:export:web"], "node scripts/export-godot-web.mjs");
    assert.match(pkg.scripts["build:pages"], /assert:godot-export/);
    assert.match(pkg.scripts["build:pages"], /godot:export:web/);
  });

  it("export preset disables thread support for GitHub Pages", () => {
    const preset = fs.readFileSync(path.join(repoRoot, "game/godot/export_presets.cfg"), "utf8");
    assert.match(preset, /variant\/thread_support=false/);
    assert.match(preset, /public\/godot\/runtime\/index\.html/);
  });

  it("raw runtime index is not classified as placeholder", () => {
    const html = fs.readFileSync(path.join(publicRuntime, "index.html"), "utf8");
    assert.equal(isPlaceholderHtml(html), false);
  });
});
