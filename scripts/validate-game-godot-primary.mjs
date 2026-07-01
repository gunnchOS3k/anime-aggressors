#!/usr/bin/env node
/**
 * Validates game-godot/ primary runtime skeleton: data, scenes, docs, IP safety.
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");
const godotRoot = path.join(root, "game-godot");

const FIGHTERS = [
  "ember-vale",
  "rook-ironside",
  "juno-spark",
  "kaia-windrow",
  "nix-calder",
  "orion-vell",
  "vesper-nyx",
];

const STAGES = ["training-grid", "skyline-arena", "neon-rooftops"];

const REQUIRED_SCENES = [
  "scenes/boot/BootScene.tscn",
  "scenes/menus/MainMenuScene.tscn",
  "scenes/menus/ModeSelectScene.tscn",
  "scenes/menus/RulesetScene.tscn",
  "scenes/menus/FighterSelectScene.tscn",
  "scenes/menus/StageSelectScene.tscn",
  "scenes/menus/VersusScene.tscn",
  "scenes/battle/BattleScene.tscn",
  "scenes/ui/PauseMenuScene.tscn",
  "scenes/ui/ResultsScene.tscn",
  "scenes/menus/TrainingScene.tscn",
  "scenes/menus/SettingsScene.tscn",
  "scenes/menus/ControlsScene.tscn",
  "scenes/menus/LabsScene.tscn",
];

const REQUIRED_DOCS = [
  "docs/PRODUCT_RUNTIME_PIVOT.md",
  "docs/ENGINE_MIGRATION_DECISION.md",
  "docs/CONSOLE_PLATFORM_FIGHTER_UX_SPEC.md",
  "docs/LEGACY_WEB_RUNTIME_STATUS.md",
  "docs/PRODUCTION_BLOCKERS.md",
  "docs/playtest/2026-07-01-godot-runtime-pivot-check.md",
];

const BANNED_IP = [
  /super\s*smash/i,
  /smash\s*bros/i,
  /nintendo/i,
  /mario\.png/i,
  /link\.png/i,
];

function fail(msg) {
  console.error(`FAIL: ${msg}`);
  process.exitCode = 1;
}

function ok(msg) {
  console.log(`OK: ${msg}`);
}

function readJson(rel) {
  const p = path.join(godotRoot, rel);
  return JSON.parse(fs.readFileSync(p, "utf8"));
}

if (!fs.existsSync(path.join(godotRoot, "project.godot"))) {
  fail("missing game-godot/project.godot");
  process.exit(1);
}
ok("project.godot exists");

for (const id of FIGHTERS) {
  const p = path.join(godotRoot, "data/fighters", `${id}.json`);
  if (!fs.existsSync(p)) fail(`missing fighter data: ${id}`);
  else {
    const data = JSON.parse(fs.readFileSync(p, "utf8"));
    if (data.id !== id) fail(`fighter id mismatch: ${id}`);
    if (!data.displayName) fail(`fighter missing displayName: ${id}`);
  }
}
ok(`all ${FIGHTERS.length} fighter JSON files`);

const roster = readJson("data/fighters/roster.json");
if (roster.fighters?.length !== FIGHTERS.length) fail("roster.json count mismatch");
ok("roster.json");

for (const id of STAGES) {
  const p = path.join(godotRoot, "data/stages", `${id}.json`);
  if (!fs.existsSync(p)) fail(`missing stage data: ${id}`);
}
ok(`all ${STAGES.length} stage JSON files`);

for (const rel of REQUIRED_SCENES) {
  if (!fs.existsSync(path.join(godotRoot, rel))) fail(`missing scene: ${rel}`);
}
ok(`${REQUIRED_SCENES.length} required scenes`);

for (const rel of REQUIRED_DOCS) {
  if (!fs.existsSync(path.join(root, rel))) fail(`missing doc: ${rel}`);
}
ok(`${REQUIRED_DOCS.length} required docs`);

function scanDir(dir) {
  if (!fs.existsSync(dir)) return;
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, ent.name);
    if (ent.isDirectory()) scanDir(full);
    else {
      for (const pat of BANNED_IP) {
        if (pat.test(ent.name)) fail(`suspect IP filename: ${full}`);
      }
    }
  }
}
scanDir(godotRoot);
ok("no banned IP filenames under game-godot/");

if (process.exitCode) {
  process.exit(process.exitCode);
}
console.log("validate-game-godot-primary: all checks passed");
