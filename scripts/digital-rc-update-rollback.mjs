#!/usr/bin/env node
/**
 * Digital RC package update / rollback helper (dev/private).
 * Keeps previous package-manifest.json under builds/digital-rc-history/.
 */
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const pkgDir = path.join(root, "builds/digital-rc");
const histDir = path.join(root, "builds/digital-rc-history");
const cmd = process.argv[2] || "update";

fs.mkdirSync(histDir, { recursive: true });

function readManifest(dir) {
  const p = path.join(dir, "package-manifest.json");
  if (!fs.existsSync(p)) return null;
  return JSON.parse(fs.readFileSync(p, "utf8"));
}

if (cmd === "update") {
  const prev = readManifest(pkgDir);
  if (prev) {
    const stamp = new Date().toISOString().replace(/[:.]/g, "-");
    const dest = path.join(histDir, stamp);
    fs.cpSync(pkgDir, dest, { recursive: true });
    fs.writeFileSync(
      path.join(histDir, "LATEST_ROLLBACK.json"),
      JSON.stringify({ path: dest, generated_at: prev.generated_at || null }, null, 2) + "\n",
    );
  }
  const pack = spawnSync(process.execPath, ["scripts/package-anime-standalone.mjs"], {
    cwd: root,
    encoding: "utf8",
  });
  if (pack.status !== 0) {
    console.error(pack.stderr || pack.stdout);
    process.exit(1);
  }
  console.log("OK: package updated (previous snapshot retained for rollback)");
  process.exit(0);
}

if (cmd === "rollback") {
  const latest = path.join(histDir, "LATEST_ROLLBACK.json");
  if (!fs.existsSync(latest)) {
    console.error("no rollback snapshot");
    process.exit(1);
  }
  const meta = JSON.parse(fs.readFileSync(latest, "utf8"));
  const src = meta.path;
  if (!src || !fs.existsSync(src)) {
    console.error("rollback path missing");
    process.exit(1);
  }
  fs.rmSync(pkgDir, { recursive: true, force: true });
  fs.cpSync(src, pkgDir, { recursive: true });
  console.log(`OK: rolled back package → ${src}`);
  process.exit(0);
}

console.error("usage: node scripts/digital-rc-update-rollback.mjs [update|rollback]");
process.exit(1);
