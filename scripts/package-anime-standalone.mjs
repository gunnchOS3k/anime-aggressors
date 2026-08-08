#!/usr/bin/env node
/**
 * Standalone digital RC package (clean-install oriented).
 * Packages Godot project data + Path A procedural assets — not a public store build.
 */
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const outDir = path.join(root, "builds/digital-rc");

function rimraf(dir) {
  if (fs.existsSync(dir)) fs.rmSync(dir, { recursive: true, force: true });
}

function copyFile(srcRel, destRel) {
  const src = path.join(root, srcRel);
  const dest = path.join(outDir, destRel);
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  fs.copyFileSync(src, dest);
  return crypto.createHash("sha256").update(fs.readFileSync(dest)).digest("hex");
}

function copyTree(srcRel, destRel) {
  const src = path.join(root, srcRel);
  const dest = path.join(outDir, destRel);
  if (!fs.existsSync(src)) {
    throw new Error(`missing package tree ${srcRel}`);
  }
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  fs.cpSync(src, dest, { recursive: true });
  let count = 0;
  const walk = (d) => {
    for (const ent of fs.readdirSync(d, { withFileTypes: true })) {
      const p = path.join(d, ent.name);
      if (ent.isDirectory()) walk(p);
      else count += 1;
    }
  };
  walk(dest);
  return count;
}

rimraf(outDir);
fs.mkdirSync(outDir, { recursive: true });

const files = [
  ["content/production_manifest.json", "content/production_manifest.json"],
  ["content/provenance.json", "content/provenance.json"],
  ["content/missing_assets.json", "content/missing_assets.json"],
  ["game-godot/project.godot", "game-godot/project.godot"],
  ["game-godot/icon.svg", "game-godot/icon.svg"],
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

const trees = [
  ["game-godot/assets/characters/procedural_final", "game-godot/assets/characters/procedural_final"],
  ["game-godot/assets/stages/procedural", "game-godot/assets/stages/procedural"],
  ["game-godot/assets/audio/procedural", "game-godot/assets/audio/procedural"],
  ["game-godot/assets/branding", "game-godot/assets/branding"],
  ["game-godot/data/fighters", "game-godot/data/fighters"],
  ["game-godot/data/stages", "game-godot/data/stages"],
];

const treeCounts = {};
for (const [src, dest] of trees) {
  treeCounts[dest] = copyTree(src, dest);
}

const fighters = [
  "ember-vale",
  "rook-ironside",
  "juno-spark",
  "kaia-windrow",
  "nix-calder",
  "orion-vell",
  "vesper-nyx",
];
const stages = [
  "skyline-arena",
  "neon-rooftops",
  "cascade-foundry",
  "void-pier",
  "ember-courtyard",
  "training-grid",
];

let glb = 0;
let svg = 0;
let wav = 0;
for (const id of fighters) {
  if (fs.existsSync(path.join(outDir, `game-godot/assets/characters/procedural_final/${id}.glb`))) glb += 1;
}
for (const id of stages) {
  if (fs.existsSync(path.join(outDir, `game-godot/assets/stages/procedural/${id}.svg`))) svg += 1;
  if (fs.existsSync(path.join(outDir, `game-godot/assets/audio/procedural/stages/${id}/bed.wav`))) wav += 1;
}
for (const id of fighters) {
  for (const cat of ["hit", "move", "charge", "projectile", "defense", "ko"]) {
    if (fs.existsSync(path.join(outDir, `game-godot/assets/audio/procedural/fighters/${id}/${cat}.wav`))) {
      wav += 1;
    }
  }
}

if (glb !== 7 || svg !== 6 || wav < 48) {
  console.error(`package asset counts failed: glb=${glb} svg=${svg} wav=${wav}`);
  process.exit(1);
}

const cleanInstall = `# Anime Aggressors — Digital RC Clean Install

1. Install Godot 4.5+ (matching \`game-godot/project.godot\`).
2. This package includes Path A procedural assets (fighters/stages/audio) under \`game-godot/assets/\`.
3. From the package root (or full repo root with matching trees):
   \`\`\`bash
   GODOT_BIN=/path/to/Godot
   "$GODOT_BIN" --headless --path game-godot --import
   "$GODOT_BIN" --headless --path game-godot --quit-after 2
   "$GODOT_BIN" --headless --path game-godot -s res://tests/smoke_runner.gd
   "$GODOT_BIN" --headless --path game-godot -s res://tests/rc_validation_runner.gd
   node scripts/validate-anime-digital-rc.mjs
   \`\`\`
4. Confirm \`playtest-evidence/digital_rc_validation.json\` reports \`ok: true\`.
5. Scope: **private/dev digital RC only** — not a public deploy / store build.

Painted remasters remain optional; Path A procedural digital art/audio are included.
`;

fs.writeFileSync(path.join(outDir, "CLEAN_INSTALL.md"), cleanInstall);
digests["CLEAN_INSTALL.md"] = crypto
  .createHash("sha256")
  .update(fs.readFileSync(path.join(outDir, "CLEAN_INSTALL.md")))
  .digest("hex");

const manifest = {
  schema_version: 1,
  name: "anime-aggressors-digital-rc",
  public_deploy: false,
  path: "A",
  assets_included: {
    procedural_final_glb: glb,
    stage_svg: svg,
    procedural_wav: wav,
    trees: treeCounts,
  },
  clean_install_steps: [
    "install_godot_4_5",
    "import_assets",
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

console.log(`OK: standalone package → ${outDir} (glb=${glb} svg=${svg} wav=${wav})`);
