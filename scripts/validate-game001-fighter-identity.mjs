#!/usr/bin/env node
/**
 * GAME-001 self-challenge: prove the 7 fighters are not identical logic / frame reskins.
 */
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const godot = path.join(root, "game-godot");
const FIGHTERS = [
  "ember-vale",
  "rook-ironside",
  "juno-spark",
  "kaia-windrow",
  "nix-calder",
  "orion-vell",
  "vesper-nyx",
];
const SPECIALS = [
  "neutral_special_projectile",
  "side_special",
  "up_special_recovery",
  "down_special",
];

let failed = 0;
function fail(msg) {
  console.error(`FAIL: ${msg}`);
  failed += 1;
}
function ok(msg) {
  console.log(`OK: ${msg}`);
}

function scrub(o) {
  if (Array.isArray(o)) return o.map(scrub);
  if (o && typeof o === "object") {
    const out = {};
    for (const [k, v] of Object.entries(o)) {
      if (["fighter_id", "training_display_name", "h2h_string_id", "feedback"].includes(k)) continue;
      out[k] = scrub(v);
    }
    return out;
  }
  return o;
}

function sha(obj) {
  return crypto.createHash("sha256").update(JSON.stringify(obj)).digest("hex");
}

function frameFp(mv) {
  const keys = [
    "startup_frames",
    "active_frames",
    "recovery_frames",
    "angle_deg",
    "base_knockback",
    "move_type",
    "hitboxes",
    "projectile",
    "trap",
    "self_movement",
    "recovery_profile",
    "armor_frames",
    "phase_cancel_frames",
    "grab_range",
    "field",
    "dash_cancel_enabled",
    "cancel_windows",
  ];
  const subset = {};
  for (const k of keys) if (mv[k] !== undefined) subset[k] = mv[k];
  return sha(scrub(subset)).slice(0, 16);
}

const moveHashes = {};
const specialClusters = Object.fromEntries(SPECIALS.map((s) => [s, {}]));
const auraRates = {};
const aiTags = {};
const h2hCounts = {};

for (const fid of FIGHTERS) {
  const movesPath = path.join(godot, "data/moves", `${fid}.json`);
  const fighterPath = path.join(godot, "data/fighters", `${fid}.json`);
  const balPath = path.join(godot, "data/balance", `${fid}.json`);
  if (!fs.existsSync(movesPath)) fail(`missing moves ${fid}`);
  if (!fs.existsSync(balPath)) fail(`missing balance ${fid}`);
  if (!fs.existsSync(fighterPath)) fail(`missing fighter ${fid}`);
  const moves = JSON.parse(fs.readFileSync(movesPath, "utf8"));
  const fighter = JSON.parse(fs.readFileSync(fighterPath, "utf8"));
  const bal = JSON.parse(fs.readFileSync(balPath, "utf8"));
  moveHashes[fid] = sha(scrub(moves));
  const byId = Object.fromEntries(moves.moves.map((m) => [m.move_id, m]));
  for (const sid of SPECIALS) {
    if (!byId[sid]) {
      fail(`${fid} missing ${sid}`);
      continue;
    }
    const fp = frameFp(byId[sid]);
    specialClusters[sid][fp] = specialClusters[sid][fp] || [];
    specialClusters[sid][fp].push(fid);
  }
  const rate = bal?.aura?.charge_rate_mult;
  auraRates[rate] = auraRates[rate] || [];
  auraRates[rate].push(fid);
  const tags = JSON.stringify(fighter.cpuBehaviorTags || []);
  aiTags[tags] = aiTags[tags] || [];
  aiTags[tags].push(fid);
  let links = 0;
  for (const m of moves.moves) {
    for (const w of m.cancel_windows || []) if (w.to) links += 1;
  }
  h2hCounts[fid] = links;
  if (links < 3) fail(`${fid} H2H links ${links} < 3`);
  else ok(`${fid} H2H links=${links}`);
  if (!moves.game001_identity) fail(`${fid} missing game001_identity marker`);
}

const uniqueMoves = new Set(Object.values(moveHashes));
if (uniqueMoves.size !== FIGHTERS.length) fail("duplicate full moveset fingerprints");
else ok(`moveset fingerprints unique (${uniqueMoves.size})`);

for (const sid of SPECIALS) {
  for (const [fp, members] of Object.entries(specialClusters[sid])) {
    if (members.length > 1) fail(`${sid} identical frame profile among ${members.join(",")}`);
  }
  ok(`${sid} frame profiles unique across roster`);
}

for (const [rate, members] of Object.entries(auraRates)) {
  if (members.length > 1) fail(`identical aura charge ${rate}: ${members.join(",")}`);
}
ok("aura charge rates unique");

for (const [tags, members] of Object.entries(aiTags)) {
  if (members.length > 1) fail(`identical AI tags ${tags}: ${members.join(",")}`);
}
ok("cpuBehaviorTags unique");

const cpuSrc = fs.readFileSync(path.join(godot, "scripts/fighters/cpu_controller.gd"), "utf8");
if (!cpuSrc.includes("_act_archetype")) fail("cpu_controller missing _act_archetype");
for (const needle of ["rushdown", "tank", "speed", "spacing", "control", "trickster", "mixup"]) {
  if (!cpuSrc.includes(`"${needle}"`)) fail(`cpu_controller missing tag branch ${needle}`);
}
ok("cpu archetype branches present");

const battleSrc = fs.readFileSync(path.join(godot, "scripts/battle/battle_scene.gd"), "utf8");
if (!battleSrc.includes("_on_pause_rematch") || !battleSrc.includes("_clear_pause_for_nav")) {
  fail("pause rematch tree-unpause remediation missing");
} else ok("pause rematch remediation present");

const registerPath = path.join(root, "artifacts/game001/ANIME_FULL_PRODUCT_REGISTER.json");
if (!fs.existsSync(registerPath)) fail("missing ANIME_FULL_PRODUCT_REGISTER.json");
else {
  const reg = JSON.parse(fs.readFileSync(registerPath, "utf8"));
  if (reg.FULL_GAME_CONTENT_COMPLETE === true) fail("register must not claim FULL_GAME_CONTENT_COMPLETE");
  if (reg.HUMAN_POLISH !== "HUMAN_PENDING") fail("HUMAN_POLISH must remain HUMAN_PENDING");
  if (reg.self_challenge?.identical_fighter_logic !== "PASS") fail("register self_challenge not PASS");
  for (const fid of FIGHTERS) {
    if (!reg.fighters?.[fid]) fail(`register missing fighter ${fid}`);
  }
  ok("register schema honesty checks");
}

const expDir = path.join(root, "artifacts/experience_review/anime-aggressors");
for (const name of [
  "SENIOR_DESIGN_REVIEW.json",
  "STUDENT_ENGAGEMENT_REVIEW.json",
  "GAME_CRITIC_REVIEW.json",
]) {
  const p = path.join(expDir, name);
  if (!fs.existsSync(p)) fail(`missing ${name}`);
  else {
    const doc = JSON.parse(fs.readFileSync(p, "utf8"));
    if (doc.live_framebuffer !== "UNAVAILABLE" && doc.VISUAL_MODEL_REVIEW === "COMPLETE") {
      fail(`${name} overclaims live visual review`);
    }
    if (!doc.classification) fail(`${name} missing classification`);
    ok(`${name} present (${doc.classification})`);
  }
}

if (failed > 0) {
  console.error(`validate-game001-fighter-identity: ${failed} failure(s)`);
  process.exit(1);
}
console.log("validate-game001-fighter-identity: PASS");
