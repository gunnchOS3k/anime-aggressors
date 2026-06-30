import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../..");
const rootPkg = JSON.parse(fs.readFileSync(path.join(repoRoot, "package.json"), "utf8")) as {
  scripts: Record<string, string>;
};

describe("Pages deploy contract", () => {
  it("build:pages exports Godot, builds web, asserts export, then finalizes", () => {
    assert.equal(rootPkg.scripts["build:web"], "npm run build -w anime-aggressors-web");
    assert.equal(rootPkg.scripts["finalize:pages"], "node scripts/finalize-pages-artifact.mjs");
    assert.equal(rootPkg.scripts["assert:godot-export"], "node scripts/assert-godot-export.mjs");
    assert.equal(rootPkg.scripts["godot:export:web"], "node scripts/export-godot-web.mjs");
    assert.match(rootPkg.scripts["build:pages"], /godot:export:web/);
    assert.match(rootPkg.scripts["build:pages"], /build:web/);
    assert.match(rootPkg.scripts["build:pages"], /assert:godot-export/);
    assert.match(rootPkg.scripts["build:pages"], /finalize:pages/);
  });

  it("pages workflow exports Godot and validates nested runtime in dist", () => {
    const workflow = fs.readFileSync(path.join(repoRoot, ".github/workflows/pages.yml"), "utf8");
    assert.doesNotMatch(workflow, /grep.*Start Match/);
    assert.doesNotMatch(workflow, /grep.*Play Match/);
    assert.doesNotMatch(workflow, /grep.*Impact Dummy Derby/);
    assert.match(workflow, /godot:export:web/);
    assert.match(workflow, /assert:godot-export/);
    assert.match(workflow, /GODOT_EXPORT_ROOT=apps\/web\/public\/godot/);
    assert.match(workflow, /path: apps\/web\/dist/);
    assert.match(workflow, /test -f apps\/web\/dist\/index\.html/);
    assert.match(workflow, /test -f apps\/web\/dist\/godot\/index\.html/);
    assert.match(workflow, /test -f apps\/web\/dist\/godot\/rescue-runtime\.js/);
    assert.match(workflow, /test -f apps\/web\/dist\/godot\/build-manifest\.json/);
    assert.match(workflow, /find apps\/web\/dist\/godot\/runtime -mindepth 2 -name 'index\.html'/);
    assert.match(workflow, /validate:godot-cache/);
    assert.match(workflow, /validate:godot-fighters/);
    assert.match(workflow, /\.wasm/);
    assert.match(workflow, /\.pck/);
  });

  it("finalize script writes required deploy-info routes", () => {
    const script = fs.readFileSync(path.join(repoRoot, "scripts/finalize-pages-artifact.mjs"), "utf8");
    assert.match(script, /artifact=apps\/web\/dist/);
    assert.match(script, /routes=#\/,#\/godot,#\/match-setup\/rules/);
    assert.match(script, /Forbidden root play link/);
    assert.doesNotMatch(script, /Missing expected marker in artifact/);
  });

  it("vite config outputs to apps/web/dist with project base", () => {
    const vite = fs.readFileSync(path.join(repoRoot, "apps/web/vite.config.ts"), "utf8");
    assert.match(vite, /base: "\/anime-aggressors\/"/);
    assert.match(vite, /outDir: path\.resolve\(root, "dist"\)/);
  });
});
