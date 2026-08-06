#!/usr/bin/env node
/**
 * Build game-core and run Gate 1 core-loop evidence test.
 * Does not touch unity/ (respects open PRs #51/#52).
 */
import { spawnSync } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "../..");

function run(cmd, args, cwd = ROOT) {
  const r = spawnSync(cmd, args, { cwd, stdio: "inherit", shell: false });
  if (r.status !== 0) process.exit(r.status ?? 1);
}

run("npm", ["run", "build", "-w", "@anime-aggressors/game-core"]);
run("node", ["--test", "packages/game-core/dist/test/gate1CoreLoop.test.js"]);
