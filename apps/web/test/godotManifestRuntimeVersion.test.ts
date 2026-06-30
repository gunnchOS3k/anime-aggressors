import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  fetchGodotBuildManifest,
  godotManifestPath,
  versionedGodotIndexPath,
} from "../src/godot/godotExportStatus.ts";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const publicGodot = path.join(webRoot, "public/godot");

describe("godot manifest runtime version", () => {
  it("manifest path is under /godot/build-manifest.json", () => {
    assert.match(godotManifestPath("/anime-aggressors/"), /godot\/build-manifest\.json$/);
  });

  it("versionedGodotIndexPath uses boot shell and buildId", () => {
    const manifest = JSON.parse(
      fs.readFileSync(path.join(publicGodot, "build-manifest.json"), "utf8"),
    ) as { buildId: string; commit: string; bootPath?: string; runtimePath: string; rescueRuntimePath: string };
    const url = versionedGodotIndexPath(manifest, "/anime-aggressors/");
    assert.match(url, /godot\/index\.html\?v=/);
    assert.match(url, new RegExp(manifest.buildId));
  });

  it("fetchGodotBuildManifest uses no-store (source contract)", () => {
    const statusSrc = fs.readFileSync(
      path.join(webRoot, "src/godot/godotExportStatus.ts"),
      "utf8",
    );
    assert.match(statusSrc, /cache:\s*"no-store"/);
    assert.ok(typeof fetchGodotBuildManifest === "function");
  });
});
