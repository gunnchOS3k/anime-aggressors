#!/usr/bin/env node
/**
 * Standalone digital RC package (clean-install oriented).
 * Packages Godot project data + manifests — not a public store build.
 */
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const outDir = path.join(root, "builds/digital-rc");
fs.mkdirSync(outDir, { recursive: true });

function copyFile(srcRel, destRel) {
  const src = path.join(root, srcRel);
  const dest = path.join(outDir, destRel);
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  fs.copyFileSync(src, dest);
  return crypto.createHash("sha256").update(fs.readFileSync(dest)).digest("hex");
}

const files = [
  ["content/production_manifest.json", "content/production_manifest.json"],
  ["content/provenance.json", "content/provenance.json"],
  ["content/missing_assets.json", "content/missing_assets.json"],
  ["game-godot/project.godot", "game-godot/project.godot"],
  ["game-godot/data/stages/production_stages.json", "game-godot/data/stages/production_stages.json"],
  ["game-godot/data/fighters/roster.json", "game-godot/data/fighters/roster.json"],
  ["docs/ANIME_BETA_CONTENT_STATUS.md", "docs/ANIME_BETA_CONTENT_STATUS.md"],
  ["docs/ANIME_DIGITAL_RC_STATUS.md", "docs/ANIME_DIGITAL_RC_STATUS.md"],
];

const digests = {};
for (const [src, dest] of files) {
  if (!fs.existsSync(path.join(root, src))) {
    console.error(`missing package source ${src}`);
    process.exit(1);
  }
  digests[dest] = copyFile(src, dest);
}

const cleanInstall = `# Anime Aggressors — Digital RC Clean Install

1. Install Godot 4.5+ (matching \`game-godot/project.godot\`).
2. Copy this package tree beside a full checkout OR use the full repo.
3. From repo root:
   \`\`\`bash
   GODOT_BIN=/path/to/Godot
   "$GODOT_BIN" --headless --path game-godot --quit-after 2
   "$GODOT_BIN" --headless --path game-godot -s res://tests/smoke_runner.gd
   "$GODOT_BIN" --headless --path game-godot -s res://tests/rc_validation_runner.gd
   node scripts/validate-anime-digital-rc.mjs
   \`\`\`
4. Confirm \`playtest-evidence/digital_rc_validation.json\` reports \`ok: true\`.
5. Scope: **private/dev digital RC only** — not a public deploy / store build.

Painted character/stage art and final audio stems may still be listed in \`content/missing_assets.json\`.
`;

fs.writeFileSync(path.join(outDir, "CLEAN_INSTALL.md"), cleanInstall);

const manifest = {
  schema_version: 1,
  name: "anime-aggressors-digital-rc",
  public_deploy: false,
  clean_install_steps: [
    "install_godot_4_5",
    "headless_quit_after",
    "smoke_runner",
    "rc_validation_runner",
    "validate-anime-digital-rc.mjs",
  ],
  files: digests,
  generated_at: new Date().toISOString(),
};
fs.writeFileSync(
  path.join(outDir, "package-manifest.json"),
  JSON.stringify(manifest, null, 2) + "\n",
);

console.log(`OK: standalone package → ${outDir}`);
