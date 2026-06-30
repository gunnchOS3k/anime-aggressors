import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  godotManifestPath,
  versionedGodotIndexPath,
} from "../src/godot/godotExportStatus.ts";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const repoRoot = path.resolve(webRoot, "../..");

describe("godot boot manifest", () => {
  it("godotManifestPath is under project site godot folder", () => {
    assert.equal(godotManifestPath("/anime-aggressors/"), "/anime-aggressors/godot/build-manifest.json");
  });

  it("checked-in manifest has required fields", () => {
    const manifest = JSON.parse(
      fs.readFileSync(path.join(webRoot, "public/godot/build-manifest.json"), "utf8"),
    ) as { buildId: string; commit: string; generatedAt: string; runtimePath: string; rescueRuntimePath: string };
    assert.ok(manifest.buildId);
    assert.ok(manifest.commit);
    assert.ok(manifest.generatedAt);
    assert.ok(manifest.runtimePath);
    assert.equal(manifest.rescueRuntimePath, "rescue-runtime.js");
  });

  it("versionedGodotIndexPath appends buildId query", () => {
    const url = versionedGodotIndexPath(
      { buildId: "abc123", commit: "", generatedAt: "", runtimePath: "", rescueRuntimePath: "" },
      "/anime-aggressors/",
    );
    assert.match(url, /\/anime-aggressors\/godot\/index\.html\?v=abc123/);
  });

  it("GodotRuntimeScreen fetches manifest with no-store", () => {
    const src = fs.readFileSync(path.join(webRoot, "src/screens/GodotRuntimeScreen.ts"), "utf8");
    assert.match(src, /fetchGodotBuildManifest/);
    assert.match(src, /versionedGodotIndexPath/);
    assert.match(src, /Godot build manifest missing/);
    const statusSrc = fs.readFileSync(path.join(webRoot, "src/godot/godotExportStatus.ts"), "utf8");
    assert.match(statusSrc, /cache:\s*"no-store"/);
  });

  it("export script writes build-manifest.json", () => {
    const exporter = fs.readFileSync(path.join(repoRoot, "scripts/export-godot-web.mjs"), "utf8");
    assert.match(exporter, /writeBuildManifest/);
    assert.match(exporter, /build-manifest\.json/);
  });
});
