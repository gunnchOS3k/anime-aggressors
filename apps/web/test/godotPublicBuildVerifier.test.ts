import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../..");

describe("godot public build verifier script", () => {
  it("verify-public-godot-build.mjs exists and checks versioned runtime", () => {
    const scriptPath = path.join(repoRoot, "scripts/verify-public-godot-build.mjs");
    assert.ok(fs.existsSync(scriptPath));
    const src = fs.readFileSync(scriptPath, "utf8");
    assert.match(src, /build-manifest\.json/);
    assert.match(src, /runtimePath is not versioned by buildId/);
    assert.match(src, /Godot Build:/);
  });

  it("package.json exposes verify:godot-public", () => {
    const pkg = JSON.parse(fs.readFileSync(path.join(repoRoot, "package.json"), "utf8")) as {
      scripts: Record<string, string>;
    };
    assert.match(pkg.scripts["verify:godot-public"], /verify-public-godot-build/);
  });
});
