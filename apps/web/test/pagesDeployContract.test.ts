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
  it("build:pages runs web workspace build then finalize", () => {
    assert.equal(rootPkg.scripts["build:web"], "npm run build -w anime-aggressors-web");
    assert.equal(rootPkg.scripts["finalize:pages"], "node scripts/finalize-pages-artifact.mjs");
    assert.equal(rootPkg.scripts["build:pages"], "npm run build:web && npm run finalize:pages");
  });

  it("pages workflow does not block on fragile UI text greps", () => {
    const workflow = fs.readFileSync(path.join(repoRoot, ".github/workflows/pages.yml"), "utf8");
    assert.doesNotMatch(workflow, /grep.*Start Match/);
    assert.doesNotMatch(workflow, /grep.*Play Match/);
    assert.doesNotMatch(workflow, /grep.*Impact Dummy Derby/);
    assert.match(workflow, /path: apps\/web\/dist/);
    assert.match(workflow, /test -f apps\/web\/dist\/index\.html/);
  });

  it("finalize script writes required deploy-info routes", () => {
    const script = fs.readFileSync(path.join(repoRoot, "scripts/finalize-pages-artifact.mjs"), "utf8");
    assert.match(script, /artifact=apps\/web\/dist/);
    assert.match(script, /routes=#\/,#\/match-setup\/rules/);
    assert.match(script, /Forbidden root play link/);
    assert.doesNotMatch(script, /Missing expected marker in artifact/);
  });

  it("vite config outputs to apps/web/dist with project base", () => {
    const vite = fs.readFileSync(path.join(repoRoot, "apps/web/vite.config.ts"), "utf8");
    assert.match(vite, /base: "\/anime-aggressors\/"/);
    assert.match(vite, /outDir: path\.resolve\(root, "dist"\)/);
  });
});
