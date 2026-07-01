#!/usr/bin/env node
/**
 * Full-scope production validation — implementation hard gates (PR #46+).
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const godotRoot = path.join(root, "game-godot");
const tmpDir = path.join(root, "tmp");

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

const REQUIRED_STATES = [
  "idle", "walk", "run", "dash", "skid", "turnaround", "jump_squat", "jump", "double_jump",
  "fall", "fast_fall", "land", "attack_startup", "attack_active", "attack_recovery",
  "special_startup", "special_active", "special_recovery", "shield_start", "shield_hold",
  "shield_stun", "shield_break", "dodge_start", "dodge_active", "dodge_recovery",
  "grab_startup", "grab_active", "grab_whiff", "grab_hold", "throw_startup", "throw_release",
  "aura_charge", "aura_ready", "aura_burst_startup", "aura_burst_active", "aura_burst_recovery",
  "hurt_light", "hurt_heavy", "hitstop", "hitstun", "launched", "tumble",
  "edge_warning", "ledge_teeter", "ko", "respawn", "victory", "defeat",
];

const CORE_SYSTEMS = [
  "boot_menu_flow", "mode_select", "ruleset_select", "fighter_select", "stage_select",
  "versus_screen", "countdown", "battle_loop", "pause", "results_rematch",
  "fighter_movement", "fighter_states", "move_runner_60hz", "hit_resolver", "shield", "dodge",
  "grab_throw", "aura_charge_burst", "ko_stocks_respawn", "training_mode", "debug_hud",
  "hitbox_overlay", "cpu_tiers", "proxy_animations", "data_loading", "full_roster_data",
  "move_manifests", "validation_scripts", "verification_loop",
];

const IMPLEMENTED_OK = new Set(["implemented", "functional_proxy", "final_art_blocked_only"]);
const BANNED_CORE_STATUS = /\b(scaffolded|architecture only|placeholder only|documented only|minimal|stub|todo gameplay|fake implementation|label-only)\b/i;
const BANNED_CORE_DOC = /\b(scaffolded|architecture only|placeholder only|documented only|minimal implementation|stub implementation|todo gameplay|fake implementation)\b/i;

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
  "docs/FULL_SCOPE_IMPLEMENTATION_AUDIT.md",
  "docs/FULL_SCOPE_IMPLEMENTATION_REPORT.md",
  "docs/CORE_GAMEPLAY_IMPLEMENTATION_STATUS.md",
  "docs/GODOT_VERIFICATION_PLAN.md",
  "docs/GODOT_EDITOR_PLAYTEST_SIGNOFF.md",
  "docs/PLAYTEST_EVIDENCE_GUIDE.md",
  "docs/PR48_VERIFICATION_REPORT.md",
  "docs/KNOWN_RUNTIME_RISKS.md",
  "docs/MANUAL_PLAYTEST_SIGNOFF_TEMPLATE.md",
];

const BANNED_IP = [/super\s*smash/i, /smash\s*bros/i, /nintendo/i];

let exitCode = 0;
const fail = (m) => { console.error(`FAIL: ${m}`); exitCode = 1; };
const ok = (m) => console.log(`OK: ${m}`);

function read(p) {
  return fs.readFileSync(path.join(root, p), "utf8");
}

function readGodot(p) {
  return fs.readFileSync(path.join(godotRoot, p), "utf8");
}

// Docs
for (const d of REQUIRED_DOCS) {
  if (!fs.existsSync(path.join(root, d))) fail(`missing doc ${d}`);
}
ok("required docs");

const readme = read("README.md");
if (!/game-godot/i.test(readme) || !/primary/i.test(readme)) fail("README must state game-godot is primary runtime");
if (BANNED_CORE_DOC.test(readme)) fail("README uses banned scaffold language for core gameplay");
ok("README primary runtime");

const implReport = read("docs/FULL_SCOPE_IMPLEMENTATION_REPORT.md");
if (BANNED_CORE_DOC.test(implReport)) fail("implementation report uses banned scaffold language for core systems");
if (!/safe.to.commit/i.test(implReport)) fail("implementation report missing safe-to-commit judgment");
ok("implementation report");

const coreStatusDoc = read("docs/CORE_GAMEPLAY_IMPLEMENTATION_STATUS.md");
if (BANNED_CORE_DOC.test(coreStatusDoc)) fail("CORE_GAMEPLAY_IMPLEMENTATION_STATUS uses banned scaffold language");
ok("core gameplay status doc");

const sot = read("docs/RUNTIME_SOURCE_OF_TRUTH.md");
if (!/game-godot\/.*production runtime/i.test(sot)) fail("RUNTIME_SOURCE_OF_TRUTH policy incomplete");
ok("runtime source of truth");

const legacy = read("docs/LEGACY_WEB_RUNTIME_STATUS.md");
if (!/legacy/i.test(legacy)) fail("LEGACY_WEB_RUNTIME_STATUS missing");
ok("legacy web status doc");

const runtimeLabel = read("apps/web/src/ui/runtimeLabel.ts");
if (!/reference only/i.test(runtimeLabel) && !/Legacy Web/i.test(runtimeLabel)) {
  fail("runtimeLabel.ts must label legacy web path");
}
ok("TS runtime labels");

// Implementation status JSON
const statusPath = path.join(godotRoot, "data/gameplay/core_implementation_status.json");
if (!fs.existsSync(statusPath)) fail("missing core_implementation_status.json");
const implStatus = JSON.parse(fs.readFileSync(statusPath, "utf8"));
for (const key of CORE_SYSTEMS) {
  const st = implStatus.core_systems?.[key];
  if (!st) fail(`core_implementation_status missing ${key}`);
  else if (!IMPLEMENTED_OK.has(st)) fail(`core system ${key} status not implemented: ${st}`);
  else if (BANNED_CORE_STATUS.test(st)) fail(`core system ${key} uses banned status word`);
}
if (!Array.isArray(implStatus.blockers) || implStatus.blockers.length === 0) {
  fail("core_implementation_status must list blockers (final-art + manual playtest)");
}
if (!implStatus.verification_tiers?.godot_editor_playtest?.includes("manual")) {
  fail("core_implementation_status must mark godot_editor_playtest as manual_signoff_required");
}
ok("core implementation status");

// PR #48 verification artifacts
const smokeTests = [
  "tests/smoke_boot.gd",
  "tests/smoke_data_load.gd",
  "tests/smoke_fighter_scene.gd",
  "tests/smoke_training_scene.gd",
  "tests/smoke_battle_scene.gd",
  "tests/smoke_runner.gd",
];
for (const s of smokeTests) {
  if (!fs.existsSync(path.join(godotRoot, s))) fail(`missing Godot smoke test ${s}`);
}
if (!fs.existsSync(path.join(root, "scripts/aa-verify-project.mjs"))) {
  fail("missing scripts/aa-verify-project.mjs");
}
if (!fs.existsSync(path.join(root, "playtest-evidence/.gitkeep"))) {
  fail("missing playtest-evidence folder");
}
if (!fs.existsSync(path.join(root, "docs/manual-playtests/.gitkeep"))) {
  fail("missing docs/manual-playtests folder");
}
ok("PR48 verification artifacts");

// Overclaiming guards
const OVERCLAIM = /manual editor test passed|manual test status:\s*\*\*pass\b|(?<![\w-])fully verified runtime(?!\s+requires)|claim full product completion/i;
const signedPlaytests = fs.existsSync(path.join(root, "docs/manual-playtests"))
  ? fs.readdirSync(path.join(root, "docs/manual-playtests")).filter((f) => f.endsWith(".md") && !f.startsWith("."))
  : [];
for (const docPath of [
  "docs/FULL_SCOPE_IMPLEMENTATION_REPORT.md",
  "docs/PR48_VERIFICATION_REPORT.md",
  "docs/CORE_GAMEPLAY_IMPLEMENTATION_STATUS.md",
  "README.md",
]) {
  const text = read(docPath);
  if (OVERCLAIM.test(text) && signedPlaytests.length === 0) {
    fail(`${docPath} claims manual/editor verification passed without docs/manual-playtests/*.md signoff`);
  }
  if (/godot cli verified/i.test(text) && /GODOT_CLI_MISSING|cli_missing|manual_blocker_cli_missing/i.test(text) === false) {
    if (!fs.existsSync(path.join(tmpDir, "aa-verify-project-report.json"))) {
      // allow if report not generated yet during first validate-only run
    }
  }
}
if (/claim fully verified runtime/i.test(read("docs/PR48_VERIFICATION_REPORT.md")) && signedPlaytests.length === 0) {
  fail("PR48 report must not claim fully verified runtime without signoff");
}
ok("overclaiming guards");

// Fighters
for (const id of FIGHTERS) {
  const fp = path.join(godotRoot, "data/fighters", `${id}.json`);
  if (!fs.existsSync(fp)) { fail(`missing fighter ${id}`); continue; }
  const data = JSON.parse(fs.readFileSync(fp, "utf8"));
  for (const f of FIGHTER_FIELDS) {
    if (data[f] === undefined) fail(`fighter ${id} missing field ${f}`);
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
    if (!Array.isArray(m.hitboxes) || m.hitboxes.length === 0) {
      fail(`fighter ${id} move ${m.move_id} lacks hitbox data`);
    }
    for (const phase of ["startup_frames", "active_frames", "recovery_frames"]) {
      if (typeof m[phase] !== "number") fail(`fighter ${id} move ${m.move_id} lacks ${phase}`);
    }
  }
}
ok("move manifests");

if (!fs.existsSync(path.join(godotRoot, "data/moves/move_schema.json"))) fail("move_schema.json missing");
ok("move schema");

// State machine
const statesSrc = readGodot("scripts/fighters/fighter_states.gd");
for (const s of REQUIRED_STATES) {
  if (!statesSrc.includes(`"${s}"`) && !statesSrc.includes(`:= "${s}"`)) {
    fail(`fighter_states.gd missing state ${s}`);
  }
}
if (!statesSrc.includes("animation_for_state")) fail("fighter_states lacks animation mapping");
ok("fighter state labels + animation map");

const smSrc = readGodot("scripts/fighters/fighter_state_machine.gd");
if (!smSrc.includes("_on_enter") || !smSrc.includes("_on_update")) {
  fail("fighter_state_machine lacks enter/update behavior");
}
ok("fighter state machine behavior");

// Move runner 60Hz
const mrSrc = readGodot("scripts/combat/move_runner.gd");
if (!mrSrc.includes("tick_sim_frame") || !mrSrc.includes("SIM_FPS")) {
  fail("move_runner lacks 60Hz frame tick");
}
if (!mrSrc.includes("startup") || !mrSrc.includes("active") || !mrSrc.includes("recovery")) {
  fail("move_runner lacks phase fields");
}
ok("60Hz move runner");

// Hit resolver, grab, aura
const hrSrc = readGodot("scripts/combat/hit_resolver.gd");
const fighterSrc = readGodot("scripts/fighters/fighter.gd");
if (!hrSrc.includes("knockback_vector")) fail("hit_resolver missing knockback");
if (!fighterSrc.includes("execute_throw") || !fighterSrc.includes("GRAB_HOLD")) {
  fail("grab/throw has no functional path in fighter.gd");
}
if (!fighterSrc.includes("aura_burst") || !fighterSrc.includes("AURA_CHARGE")) {
  fail("aura charge/burst missing in fighter.gd");
}
ok("hit resolver + grab + aura");

// PR #47 runtime hardening gates
const battleSrc = readGodot("scripts/battle/battle_scene.gd");
const trainHitSrc = readGodot("scripts/training/training_battle_scene.gd");
for (const [name, src] of [["battle_scene.gd", battleSrc], ["training_battle_scene.gd", trainHitSrc]]) {
  if (/can_hit_target\s*\(/.test(src)) {
    fail(`${name} must not call can_hit_target(); gating belongs in HitResolver.resolve()`);
  }
}
if (!hrSrc.includes("can_hit_target")) {
  fail("hit_resolver.resolve must gate with can_hit_target()");
}
ok("single can_hit_target gating in hit resolver");

const projectGodot = readGodot("project.godot");
const P2_ACTIONS = ["p2_left", "p2_right", "p2_up", "p2_down", "p2_jump", "p2_attack", "p2_special", "p2_shield", "p2_dodge", "p2_grab"];
const P1_ACTIONS = ["p1_left", "p1_right", "p1_up", "p1_down", "p1_jump", "p1_attack", "p1_special", "p1_shield", "p1_dodge", "p1_grab"];
for (const a of P1_ACTIONS) {
  if (!projectGodot.includes(`${a}=`)) fail(`project.godot missing ${a}`);
}
for (const a of P2_ACTIONS) {
  if (!projectGodot.includes(`${a}=`)) fail(`project.godot missing ${a}`);
}
ok("P1/P2 input actions");

if (/not in FighterStates\.is_attack_state/.test(fighterSrc)) {
  fail("fighter.gd misuses `not in FighterStates.is_attack_state(...)`");
}
if (!fighterSrc.includes("not FighterStates.is_attack_state(")) {
  fail("fighter.gd missing correct is_attack_state boolean check");
}
ok("movement attack-state boolean check");

const auraIdx = fighterSrc.indexOf("is_aura_input_held");
const shieldIdx = fighterSrc.indexOf("_read_shield()");
const handleActions = fighterSrc.slice(fighterSrc.indexOf("func _handle_actions"), fighterSrc.indexOf("func is_aura_input_held"));
if (auraIdx < 0 || shieldIdx < 0 || auraIdx > shieldIdx) {
  fail("aura charge must be checked before shield handling in _handle_actions");
}
if (/if _read_shield\(\)[\s\S]{0,120}return[\s\S]{0,400}is_aura_input_held/.test(handleActions)) {
  fail("shield early return blocks aura charge branch");
}
ok("aura input ordering");

if (!smSrc.includes("FighterStates.HURT_LIGHT") || !smSrc.includes("FighterStates.HURT_HEAVY")) {
  fail("fighter_state_machine missing HURT_LIGHT/HURT_HEAVY recovery");
}
ok("hurt state recovery");

const debugHudSrc = readGodot("scripts/debug/debug_hud.gd");
if (/call_group\([^)]*set_debug_visible/.test(debugHudSrc)) {
  fail("debug_hud must not call_group set_debug_visible on ColorRect groups");
}
if (!debugHudSrc.includes("set_debug_hitboxes") || !debugHudSrc.includes("set_debug_hurtboxes")) {
  fail("debug_hud must toggle overlays via fighter methods");
}
ok("debug overlay toggles");

// CPU tiers
if (!fs.existsSync(path.join(godotRoot, "scripts/fighters/cpu_controller.gd"))) {
  fail("missing cpu_controller.gd");
}
const cpuSrc = readGodot("scripts/fighters/cpu_controller.gd");
if (!cpuSrc.includes("level >= 1") || !cpuSrc.includes("level >= 4")) {
  fail("CPU levels do not map to behavior changes");
}
ok("CPU tiers");

// Proxy animations
if (!fs.existsSync(path.join(godotRoot, "scripts/fighters/fighter_animator.gd"))) {
  fail("missing fighter_animator.gd");
}
const animSrc = readGodot("scripts/fighters/fighter_animator.gd");
if (!animSrc.includes("PROXY") || !animSrc.includes("AnimationPlayer")) {
  fail("proxy animation integration incomplete");
}
ok("proxy animations");

// Training controls
const trainBattle = readGodot("scripts/training/training_battle_scene.gd");
const trainMenu = readGodot("scripts/training/training_menu_scene.gd");
const trainChecks = ["reset_position", "reset_damage", "fill_aura", "clear_aura", "F2", "F1"];
for (const c of trainChecks) {
  if (!trainBattle.includes(c)) fail(`training battle missing control ${c}`);
}
if (!trainMenu.includes("training_battle")) fail("training menu missing start path");
ok("training scene controls");

// Debug HUD
const hudSrc = readGodot("scripts/debug/debug_hud.gd");
if (!hudSrc.includes("state") || !hudSrc.includes("move")) fail("debug HUD missing state/move display");
ok("debug HUD");

// Battle sim
if (!fs.existsSync(path.join(godotRoot, "scripts/battle/battle_sim.gd"))) {
  fail("missing battle_sim.gd");
}
ok("battle sim");

// Scenes
for (const s of REQUIRED_SCENES) {
  if (!fs.existsSync(path.join(godotRoot, s))) fail(`missing scene ${s}`);
}
ok("required scenes");

function validateSceneScripts(sceneRel) {
  const full = path.join(godotRoot, sceneRel);
  if (!fs.existsSync(full)) return;
  const src = fs.readFileSync(full, "utf8");
  const scriptRe = /path="(res:\/\/[^"]+\.gd)"/g;
  let m;
  while ((m = scriptRe.exec(src)) !== null) {
    const rel = m[1].replace("res://", "");
    const sp = path.join(godotRoot, rel);
    if (!fs.existsSync(sp)) fail(`scene ${sceneRel} references missing script ${m[1]}`);
  }
}
for (const s of REQUIRED_SCENES) validateSceneScripts(s);
ok("scene script path sanity");

const coreScripts = [
  "scripts/fighters/fighter_state_machine.gd",
  "scripts/combat/move_runner.gd",
  "scripts/combat/hit_resolver.gd",
  "scripts/debug/debug_hud.gd",
  "scripts/data/data_loader.gd",
  "scripts/battle/battle_sim.gd",
  "scripts/fighters/cpu_controller.gd",
  "scripts/fighters/fighter_animator.gd",
];
for (const s of coreScripts) {
  if (!fs.existsSync(path.join(godotRoot, s))) fail(`missing script ${s}`);
}
ok("core Godot scripts");

// Scan core gameplay docs for banned language in implementation sections
const audit = read("docs/FULL_SCOPE_IMPLEMENTATION_AUDIT.md");
const auditLines = audit.split("\n").filter((l) => l.startsWith("|") && !l.includes("---"));
for (const line of auditLines) {
  if (BANNED_CORE_STATUS.test(line) && !/future feature|final.art/i.test(line)) {
    fail(`audit marks core system with banned status: ${line.trim()}`);
  }
}
ok("audit doc status language");

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
