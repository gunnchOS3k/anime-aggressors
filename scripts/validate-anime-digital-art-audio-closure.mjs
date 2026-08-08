#!/usr/bin/env node
/**
 * Continuation V — Anime digital art/audio closure integrity.
 * Path A: PROCEDURAL_FINAL assets must clear all blocks_token gaps.
 */
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
let failed = 0;
const fail = (m) => {
  console.error(`FAIL: ${m}`);
  failed += 1;
};
const ok = (m) => console.log(`OK: ${m}`);

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

const build = spawnSync(process.execPath, ["scripts/build-anime-beta-content-manifest.mjs"], {
  cwd: root,
  encoding: "utf8",
});
if (build.status !== 0) {
  fail(`manifest builder: ${build.stderr || build.stdout}`);
  process.exit(1);
}
ok("manifest rebuilt");

for (const id of fighters) {
  const glb = path.join(root, `game-godot/assets/characters/procedural_final/${id}.glb`);
  if (!fs.existsSync(glb) || fs.statSync(glb).size < 100_000) fail(`glb ${id}`);
  if (!fs.existsSync(`${glb}.import`)) fail(`glb import missing ${id}`);
  for (const cat of ["hit", "move", "charge", "projectile", "defense", "ko"]) {
    const wav = path.join(root, `game-godot/assets/audio/procedural/fighters/${id}/${cat}.wav`);
    if (!fs.existsSync(wav) || fs.statSync(wav).size < 100) fail(`audio ${id}.${cat}`);
    if (!fs.existsSync(`${wav}.import`)) fail(`audio import ${id}.${cat}`);
  }
  const data = JSON.parse(
    fs.readFileSync(path.join(root, `game-godot/data/fighters/${id}.json`), "utf8"),
  );
  if (data.authorship?.assetStatuses?.model_glb !== "PROCEDURAL_FINAL") fail(`${id} model status`);
  if (data.authorship?.assetStatuses?.audio !== "PROCEDURAL_FINAL") fail(`${id} audio status`);
  if (data.productionStatus === "proxy") fail(`${id} still proxy productionStatus`);
  if (!String(data.modelPath || "").includes("procedural_final/")) fail(`${id} modelPath not final`);
  if (String(data.modelPath || "").includes("/proxy/")) fail(`${id} modelPath still proxy`);
}
ok("7 fighters procedural art+audio");

for (const id of stages) {
  const svg = path.join(root, `game-godot/assets/stages/procedural/${id}.svg`);
  if (!fs.existsSync(svg)) {
    fail(`stage art ${id}`);
  }
  if (!fs.existsSync(`${svg}.import`)) fail(`stage import ${id}`);
  const bed = path.join(root, `game-godot/assets/audio/procedural/stages/${id}/bed.wav`);
  if (!fs.existsSync(bed)) {
    fail(`stage bed ${id}`);
  }
  if (!fs.existsSync(`${bed}.import`)) fail(`stage bed import ${id}`);
  const s = JSON.parse(fs.readFileSync(path.join(root, `game-godot/data/stages/${id}.json`), "utf8"));
  if (s.artStatus !== "PROCEDURAL_FINAL") fail(`${id} artStatus`);
  if (s.audioBed?.status !== "PROCEDURAL_FINAL") fail(`${id} audioBed`);
  if (String(s.productionStatus || "").includes("greybox")) fail(`${id} greybox tag`);
}
ok("6 stages procedural art+audio");

for (const cat of ["hit", "move", "charge", "projectile", "defense", "ko", "ui_confirm", "ui_back", "ui_select"]) {
  const wav = path.join(root, `game-godot/assets/audio/procedural/shared/${cat}.wav`);
  if (!fs.existsSync(wav)) fail(`shared ${cat}`);
}
ok("shared combat/UI bank");

for (const rel of [
  "playtest-evidence/visual_qa/fighters/roster_contact_sheet.png",
  "playtest-evidence/visual_qa/fighters/silhouette_fingerprints.json",
  "playtest-evidence/visual_qa/stages/stages_contact_sheet.html",
  "playtest-evidence/visual_qa/audio_bank_manifest.json",
]) {
  if (!fs.existsSync(path.join(root, rel))) fail(`missing QA ${rel}`);
}
ok("visual/audio QA evidence");

const fingerprints = JSON.parse(
  fs.readFileSync(
    path.join(root, "playtest-evidence/visual_qa/fighters/silhouette_fingerprints.json"),
    "utf8",
  ),
);
const accessories = new Set(
  Object.values(fingerprints.fighters || {}).map((f) => f.accessory),
);
if (accessories.size !== 7) fail(`silhouette accessories not distinct (${accessories.size})`);
ok("7 distinct silhouette accessories");

const missing = JSON.parse(fs.readFileSync(path.join(root, "content/missing_assets.json"), "utf8"));
const blockers = (missing.items || []).filter((i) => i.blocks_token === true);
if (blockers.length !== 0) fail(`blocks_token remain: ${blockers.map((b) => b.id).join(",")}`);
ok("zero blocks_token");

const manifest = JSON.parse(
  fs.readFileSync(path.join(root, "content/production_manifest.json"), "utf8"),
);
if (manifest.token_target !== "ANIME_BETA_CONTENT_COMPLETE_DIGITAL") fail("token_target");
if (manifest.honesty?.final_painted_art_complete !== false) fail("must not claim painted art");
if (manifest.honesty?.procedural_digital_art_complete !== true) fail("procedural art flag");
if (manifest.honesty?.procedural_digital_audio_complete !== true) fail("procedural audio flag");
ok("token honesty");

if (failed) {
  console.error(`validate-anime-digital-art-audio-closure: ${failed} failure(s)`);
  process.exit(1);
}
console.log("validate-anime-digital-art-audio-closure: PASS");
console.log("PATH: A");
console.log("TOKENS_VALID: ANIME_BETA_CONTENT_COMPLETE_DIGITAL (+ ANIME_DIGITAL_RC_READY when RC runner evidence present)");
