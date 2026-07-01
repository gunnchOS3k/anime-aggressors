#!/usr/bin/env node
/**
 * Full-scope production validation gates for Godot-first consolidation.
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const godotRoot = path.join(root, "game-godot");

const FIGHTERS = [
  "ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
  "nix-calder", "orion-vell", "vesper-nyx",
];

const REQUIRED_MOVE_IDS = [
  "jab", "forward_tilt", "heavy_attack", "neutral_special", "up_special",
  "down_special", "aerial_neutral", "grab", "throw", "aura_charge", "aura_burst",
];

const REQUIRED_MOVE_FIELDS = [
  "move_id", "fighter_id", "input_command", "grounded_air", "startup_frames",
  "active_frames", "recovery_frames", "hitboxes", "damage", "angle_deg",
  "base_knockback", "knockback_growth", "training_display_name",
];

const FIGHTER_FIELDS = [
  "id", "displayName", "archetype", "element", "weight", "runSpeed", "dashSpeed",
  "airSpeed", "jumpStrength", "fallSpeed", "auraColor", "moveListPath",
  "productionStatus", "cpuBehaviorTags",
];

const FIGHTER_STATES = [
  "idle", "walk", "run", "dash", "jump", "double_jump", "fall", "attack_startup",
  "attack_active", "attack_recovery", "special_startup", "special_active",
  "shield_hold", "dodge", "aura_charge", "aura_burst", "hitstun", "launched",
  "ko", "respawn",
];

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
  "scenes/training/TrainingMenuScene.tscn",
  "scenes/training/TrainingBattleScene.tscn",
  "scenes/menus/SettingsScene.tscn",
  "scenes/menus/ControlsScene.tscn",
  "scenes/menus/LabsScene.tscn",
];

const REQUIRED_DOCS = [
  "docs/RUNTIME_SOURCE_OF_TRUTH.md",
  "docs/NO_TS_PRODUCTION_GAMEPLAY.md",
  "docs/FULL_SCOPE_PRODUCTION_PLAN.md",
  "docs/BUILD_TARGETS.md",
  "docs/BLENDER_TO_GODOT_PIPELINE.md",
  "docs/TRAINING_DEBUG_SUPPORT.md",
  "docs/LEGACY_WEB_RUNTIME_STATUS.md",
];

const BANNED_IP = [/super\s*smash/i, /smash\s*bros/i, /nintendo/i];

let exitCode = 0;
const fail = (m) => { console.error(`FAIL: ${m}`); exitCode = 1; };
const ok = (m) => console.log(`OK: ${m}`);

// Docs
for (const d of REQUIRED_DOCS) {
  if (!fs.existsSync(path.join(root, d))) fail(`missing doc ${d}`);
}
ok("required docs");

const readme = fs.readFileSync(path.join(root, "README.md"), "utf8");
if (!/game-godot/i.test(readme) || !/primary/i.test(readme)) fail("README must state game-godot is primary runtime");
ok("README primary runtime");

const sot = fs.readFileSync(path.join(root, "docs/RUNTIME_SOURCE_OF_TRUTH.md"), "utf8");
if (!/game-godot\/.*production runtime/i.test(sot)) fail("RUNTIME_SOURCE_OF_TRUTH policy incomplete");
ok("runtime source of truth");

const legacy = fs.readFileSync(path.join(root, "docs/LEGACY_WEB_RUNTIME_STATUS.md"), "utf8");
if (!/legacy/i.test(legacy)) fail("LEGACY_WEB_RUNTIME_STATUS missing");
ok("legacy web status doc");

const runtimeLabel = fs.readFileSync(path.join(root, "apps/web/src/ui/runtimeLabel.ts"), "utf8");
if (!/reference only/i.test(runtimeLabel) && !/Legacy Web/i.test(runtimeLabel)) {
  fail("runtimeLabel.ts must label legacy web path");
}
ok("TS runtime labels");

// Fighters
for (const id of FIGHTERS) {
  const fp = path.join(godotRoot, "data/fighters", `${id}.json`);
  if (!fs.existsSync(fp)) { fail(`missing fighter ${id}`); continue; }
  const data = JSON.parse(fs.readFileSync(fp, "utf8"));
  for (const f of FIGHTER_FIELDS) {
    if (data[f] === undefined) fail(`fighter ${id} missing field ${f}`);
  }
  const status = data.productionStatus;
  if (!["placeholder", "proxy", "authored", "production"].includes(status)) {
    fail(`fighter ${id} invalid productionStatus`);
  }
}
ok("fighter data model");

// Moves
for (const id of FIGHTERS) {
  const mp = path.join(godotRoot, "data/moves", `${id}.json`);
  if (!fs.existsSync(mp)) { fail(`missing moves ${id}`); continue; }
  const manifest = JSON.parse(fs.readFileSync(mp, "utf8"));
  const ids = manifest.moves?.map((m) => m.move_id) ?? [];
  for (const mid of REQUIRED_MOVE_IDS) {
    if (!ids.includes(mid)) fail(`fighter ${id} missing move ${mid}`);
  }
  for (const m of manifest.moves ?? []) {
    for (const f of REQUIRED_MOVE_FIELDS) {
      if (m[f] === undefined) fail(`fighter ${id} move ${m.move_id} missing ${f}`);
    }
  }
}
ok("move manifests");

if (!fs.existsSync(path.join(godotRoot, "data/moves/move_schema.json"))) fail("move_schema.json missing");
ok("move schema");

// State machine labels in GDScript
const statesSrc = fs.readFileSync(path.join(godotRoot, "scripts/fighters/fighter_states.gd"), "utf8");
for (const s of FIGHTER_STATES) {
  if (!statesSrc.includes(`"${s}"`) && !statesSrc.includes(`:= "${s}"`)) {
    fail(`fighter_states.gd missing state ${s}`);
  }
}
ok("fighter state labels");

// Scenes
for (const s of REQUIRED_SCENES) {
  if (!fs.existsSync(path.join(godotRoot, s))) fail(`missing scene ${s}`);
}
ok("required scenes");

// Core scripts
const coreScripts = [
  "scripts/fighters/fighter_state_machine.gd",
  "scripts/combat/move_runner.gd",
  "scripts/combat/hit_resolver.gd",
  "scripts/debug/debug_hud.gd",
  "scripts/data/data_loader.gd",
];
for (const s of coreScripts) {
  if (!fs.existsSync(path.join(godotRoot, s))) fail(`missing script ${s}`);
}
ok("core Godot scripts");

// IP scan
function scan(dir) {
  if (!fs.existsSync(dir)) return;
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, ent.name);
    if (ent.isDirectory()) scan(full);
    else for (const p of BANNED_IP) if (p.test(ent.name)) fail(`banned IP filename ${full}`);
  }
}
scan(godotRoot);
ok("IP filename scan");

if (exitCode) process.exit(exitCode);
console.log("validate-full-scope-production: all checks passed");
