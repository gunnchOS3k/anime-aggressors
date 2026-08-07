#!/usr/bin/env node
/**
 * G2-C6 product-depth validator for game-godot runtime.
 * Checks DeviceRoleRuntime, combat depth hooks, telemetry, HUD, IP safety.
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");
const godotRoot = path.join(root, "game-godot");

let failed = 0;
function fail(msg) {
  console.error(`FAIL: ${msg}`);
  failed += 1;
}
function ok(msg) {
  console.log(`OK: ${msg}`);
}
function read(rel) {
  return fs.readFileSync(path.join(godotRoot, rel), "utf8");
}
function exists(rel) {
  return fs.existsSync(path.join(godotRoot, rel));
}

const REQUIRED = [
  "scripts/core/DeviceRoleRuntime.gd",
  "scripts/core/MatchTelemetry.gd",
  "scripts/ui/battle_hud_panel.gd",
  "scripts/combat/combat_math.gd",
  "data/device/device_role_matrix.json",
];

for (const rel of REQUIRED) {
  if (!exists(rel)) fail(`missing ${rel}`);
  else ok(`present ${rel}`);
}

const matrix = JSON.parse(read("data/device/device_role_matrix.json"));
const roles = ["student_14_5", "handheld_hybrid", "ds_xl_coder", "edge_io_rings"];
for (const role of roles) {
  const p = matrix.device_roles?.[role];
  if (!p) fail(`matrix missing role ${role}`);
  else if (!p.input || !p.layout || !p.fx) fail(`role ${role} incomplete`);
  else ok(`matrix role ${role}`);
}

const project = read("project.godot");
for (const auto of ["DeviceRoleRuntime", "MatchTelemetry"]) {
  if (!project.includes(auto)) fail(`autoload missing ${auto}`);
  else ok(`autoload ${auto}`);
}

const fighter = read("scripts/fighters/fighter.gd");
for (const needle of [
  "complete_jump_squat",
  "apply_hitstun_di",
  "AIR_DODGE",
  "begin_landing",
  "tick_ledge_hang",
  "di_in",
]) {
  if (!fighter.includes(needle)) fail(`fighter.gd missing ${needle}`);
  else ok(`fighter has ${needle}`);
}

const math = read("scripts/combat/combat_math.gd");
for (const needle of ["apply_di", "short_hop_velocity", "landing_lag_seconds", "SHORT_HOP_MULT"]) {
  if (!math.includes(needle)) fail(`combat_math missing ${needle}`);
  else ok(`combat_math has ${needle}`);
}

const battle = read("scripts/battle/battle_scene.gd");
for (const needle of ["_time_remaining", "MatchTelemetry", "DeviceRoleRuntime", "BattleHudPanel", "_end_match_on_time"]) {
  if (!battle.includes(needle)) fail(`battle_scene missing ${needle}`);
  else ok(`battle_scene has ${needle}`);
}

const banned = [/naruto/i, /goku/i, /one\s*piece/i, /demon\s*slayer/i, /jujutsu/i, /smash\s*bros/i];
const identityFiles = [
  "docs/FIGHTER_IDENTITY_MATRIX.md",
  "data/fighters/roster.json",
  "data/fighters/ember-vale.json",
];
for (const rel of identityFiles) {
  if (!exists(rel)) continue;
  const text = read(rel);
  for (const pat of banned) {
    if (pat.test(text)) fail(`banned IP string in ${rel}: ${pat}`);
  }
}
ok("original-character identity scan clean");

const deviceUx = path.join(root, "device_ux/roles.yaml");
if (!fs.existsSync(deviceUx)) fail("missing device_ux/roles.yaml");
else {
  const yaml = fs.readFileSync(deviceUx, "utf8");
  for (const role of roles) {
    if (!yaml.includes(role)) fail(`device_ux/roles.yaml missing ${role}`);
  }
  ok("device_ux/roles.yaml lists quartet");
}

if (failed > 0) {
  console.error(`validate-g2-c6-product-depth: ${failed} failure(s)`);
  process.exit(1);
}
console.log("validate-g2-c6-product-depth: all checks passed");
