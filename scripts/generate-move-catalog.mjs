#!/usr/bin/env node
/**
 * Generates move_catalog.json and combo_catalog.json for all 7 fighters.
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const dataDir = path.join(repoRoot, "game/godot/data");

const FIGHTERS = [
  { id: "ember-vale", element: "flame", prefix: "ember" },
  { id: "rook-ironside", element: "impact", prefix: "rook" },
  { id: "juno-spark", element: "volt", prefix: "juno" },
  { id: "kaia-windrow", element: "gale", prefix: "kaia" },
  { id: "nix-calder", element: "frost", prefix: "nix" },
  { id: "orion-vell", element: "gravity", prefix: "orion" },
  { id: "vesper-nyx", element: "void", prefix: "vesper" },
];

const MOVE_TYPES = [
  { id: "neutral_attack", anim: "neutral_attack", socket: "right_fist", vfx: "right_fist", startup: 4, active: 3, recovery: 10, damage: 5, kb: 7, growth: 0.12, angle: 35, hitlag: 3, hitstun: 10, cancel: [8, 13] },
  { id: "side_attack", anim: "side_attack", socket: "right_fist", vfx: "weapon_tip", startup: 5, active: 4, recovery: 12, damage: 8, kb: 9, growth: 0.14, angle: 20, hitlag: 4, hitstun: 12, cancel: [9, 15] },
  { id: "up_attack", anim: "up_attack", socket: "right_fist", vfx: "right_fist", startup: 6, active: 3, recovery: 14, damage: 9, kb: 10, growth: 0.15, angle: 78, hitlag: 5, hitstun: 14, cancel: [10, 16] },
  { id: "down_attack", anim: "down_attack", socket: "right_foot", vfx: "right_foot", startup: 5, active: 4, recovery: 11, damage: 7, kb: 8, growth: 0.13, angle: -25, hitlag: 4, hitstun: 11, cancel: [9, 14] },
  { id: "dash_attack", anim: "dash_attack", socket: "right_fist", vfx: "right_fist", startup: 3, active: 4, recovery: 12, damage: 7, kb: 8, growth: 0.13, angle: 15, hitlag: 3, hitstun: 11, cancel: [7, 12] },
  { id: "neutral_air", anim: "neutral_air", socket: "right_fist", vfx: "right_fist", startup: 4, active: 3, recovery: 14, damage: 5, kb: 6, growth: 0.11, angle: 45, hitlag: 3, hitstun: 9, cancel: [7, 12] },
  { id: "forward_air", anim: "forward_air", socket: "right_fist", vfx: "right_fist", startup: 5, active: 4, recovery: 16, damage: 8, kb: 9, growth: 0.14, angle: 25, hitlag: 4, hitstun: 12, cancel: [9, 15] },
  { id: "back_air", anim: "back_air", socket: "left_fist", vfx: "left_fist", startup: 5, active: 3, recovery: 18, damage: 7, kb: 8, growth: 0.12, angle: 160, hitlag: 4, hitstun: 11, cancel: [8, 14] },
  { id: "up_air", anim: "up_air", socket: "right_fist", vfx: "right_fist", startup: 6, active: 3, recovery: 20, damage: 9, kb: 10, growth: 0.15, angle: 85, hitlag: 5, hitstun: 14, cancel: [9, 16] },
  { id: "down_air", anim: "down_air", socket: "right_foot", vfx: "right_foot", startup: 4, active: 5, recovery: 18, damage: 8, kb: 9, growth: 0.14, angle: -70, hitlag: 4, hitstun: 12, cancel: [9, 15] },
  { id: "neutral_special", anim: "neutral_special", socket: "right_fist", vfx: "aura_core", startup: 8, active: 5, recovery: 20, damage: 12, kb: 11, growth: 0.16, angle: 30, hitlag: 6, hitstun: 16, cancel: [13, 20] },
  { id: "side_special", anim: "side_special", socket: "weapon_tip", vfx: "weapon_tip", startup: 10, active: 6, recovery: 22, damage: 14, kb: 12, growth: 0.17, angle: 18, hitlag: 7, hitstun: 18, cancel: [16, 24] },
  { id: "up_special", anim: "up_special", socket: "right_fist", vfx: "aura_core", startup: 12, active: 4, recovery: 24, damage: 10, kb: 13, growth: 0.18, angle: 82, hitlag: 6, hitstun: 20, cancel: [16, 26] },
  { id: "down_special", anim: "down_special", socket: "ground_contact", vfx: "ground_contact", startup: 9, active: 6, recovery: 22, damage: 13, kb: 11, growth: 0.16, angle: -35, hitlag: 6, hitstun: 17, cancel: [15, 23] },
  { id: "grab", anim: "grab", socket: "right_fist", vfx: "right_fist", startup: 6, active: 2, recovery: 16, damage: 0, kb: 0, growth: 0, angle: 0, hitlag: 0, hitstun: 0, cancel: [] },
  { id: "throw", anim: "throw", socket: "center_mass", vfx: "center_mass", startup: 4, active: 3, recovery: 20, damage: 10, kb: 12, growth: 0.15, angle: 45, hitlag: 5, hitstun: 18, cancel: [] },
  { id: "super", anim: "super_active", socket: "aura_core", vfx: "aura_core", startup: 14, active: 8, recovery: 30, damage: 22, kb: 16, growth: 0.22, angle: 40, hitlag: 10, hitstun: 28, cancel: [] },
];

const REQUIRED_ANIMATIONS = [
  "idle", "walk", "run", "dash", "jump", "double_jump", "fall", "fast_fall", "land",
  "neutral_attack", "side_attack", "up_attack", "down_attack",
  "neutral_special", "side_special", "up_special", "down_special",
  "aura_charge", "super_startup", "super_active",
  "hitstun_light", "hitstun_heavy", "launch", "tumble", "shield", "dodge",
  "grab", "throw", "victory", "defeat",
  "dash_attack", "neutral_air", "forward_air", "back_air", "up_air", "down_air",
];

function buildMove(fighter, template) {
  const moveId = `${fighter.prefix}_${template.id}`;
  return {
    move_id: moveId,
    fighter_id: fighter.id,
    display_name: template.id.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase()),
    input: template.id,
    animation_clip: template.anim,
    animation_name: template.anim,
    startup_frames: template.startup,
    active_frames: template.active,
    recovery_frames: template.recovery,
    startup: template.startup,
    active: template.active,
    recovery: template.recovery,
    cancel_start: template.cancel[0] ?? 0,
    cancel_end: template.cancel[1] ?? 0,
    cancel_window: template.cancel,
    damage: template.damage,
    base_knockback: template.kb,
    knockback_growth: template.growth,
    launch_angle: template.angle,
    launch_angle_degrees: template.angle,
    hitlag: template.hitlag,
    hitstun: template.hitstun,
    hit_strength: template.damage >= 14 ? "heavy" : template.damage >= 8 ? "medium" : "light",
    hit_socket: template.socket,
    hitbox_socket: template.socket,
    vfx_socket: template.vfx,
    hurtbox_profile: "standard",
    camera_impulse: template.damage >= 14 ? "heavy_hit" : template.damage >= 8 ? "medium_hit" : "light_hit",
    camera_event: template.damage >= 14 ? "heavy_hit" : template.damage >= 8 ? "medium_hit" : "light_hit",
    audio_event: `${fighter.element}_hit_${template.damage >= 14 ? "heavy" : "light"}`,
    vfx_event: `${fighter.element}_hit_spark`,
    combo_tags: [template.id],
    element_effect: fighter.element,
  };
}

function buildMoves() {
  const catalog = {};
  for (const fighter of FIGHTERS) {
    catalog[fighter.id] = {};
    for (const template of MOVE_TYPES) {
      const move = buildMove(fighter, template);
      catalog[fighter.id][move.move_id] = move;
      catalog[fighter.id][template.id] = { ...move, move_id: template.id };
    }
  }
  return catalog;
}

function buildCombos() {
  const catalog = {};
  for (const fighter of FIGHTERS) {
    const f = fighter.id;
    const p = fighter.prefix;
    catalog[f] = [
      { combo_id: `${p}_beginner_01`, display_name: `${fighter.prefix} Starter Chain`, difficulty: "beginner", input_sequence: ["neutral_attack", "neutral_attack", "side_attack"], move_sequence: [`${p}_neutral_attack`, `${p}_neutral_attack`, `${p}_side_attack`], timing_window: "lenient", starter: "neutral_attack", ender: "side_attack", expected_result: "horizontal knockback", tutorial_hint: "Tap attack twice, then side attack." },
      { combo_id: `${p}_beginner_02`, display_name: `${fighter.prefix} Air Opener`, difficulty: "beginner", input_sequence: ["jump", "neutral_air", "down_air"], move_sequence: [`${p}_neutral_air`, `${p}_down_air`], timing_window: "lenient", starter: "neutral_air", ender: "down_air", expected_result: "spike setup", tutorial_hint: "Jump, attack, then down-air." },
      { combo_id: `${p}_beginner_03`, display_name: `${fighter.prefix} Dash Strike`, difficulty: "beginner", input_sequence: ["dash", "dash_attack"], move_sequence: [`${p}_dash_attack`], timing_window: "lenient", starter: "dash_attack", ender: "dash_attack", expected_result: "quick confirm", tutorial_hint: "Dash into attack." },
      { combo_id: `${p}_intermediate_01`, display_name: `${fighter.prefix} Special Link`, difficulty: "intermediate", input_sequence: ["side_attack", "neutral_special"], move_sequence: [`${p}_side_attack`, `${p}_neutral_special`], timing_window: "medium", starter: "side_attack", ender: "neutral_special", expected_result: "special confirm", tutorial_hint: "Link side attack into special." },
      { combo_id: `${p}_intermediate_02`, display_name: `${fighter.prefix} Launch Route`, difficulty: "intermediate", input_sequence: ["up_attack", "up_air"], move_sequence: [`${p}_up_attack`, `${p}_up_air`], timing_window: "medium", starter: "up_attack", ender: "up_air", expected_result: "vertical launch", tutorial_hint: "Up attack then chase with up-air." },
      { combo_id: `${p}_intermediate_03`, display_name: `${fighter.prefix} Grab Throw`, difficulty: "intermediate", input_sequence: ["grab", "throw"], move_sequence: [`${p}_grab`, `${p}_throw`], timing_window: "medium", starter: "grab", ender: "throw", expected_result: "throw knockback", tutorial_hint: "Grab then throw input." },
      { combo_id: `${p}_advanced_01`, display_name: `${fighter.prefix} Aerial Route`, difficulty: "advanced", input_sequence: ["jump", "forward_air", "up_special"], move_sequence: [`${p}_forward_air`, `${p}_up_special`], timing_window: "tight", starter: "forward_air", ender: "up_special", expected_result: "aerial damage", tutorial_hint: "Air confirm into up special." },
      { combo_id: `${p}_advanced_02`, display_name: `${fighter.prefix} Edge Guard`, difficulty: "advanced", input_sequence: ["down_attack", "down_air", "side_special"], move_sequence: [`${p}_down_attack`, `${p}_down_air`, `${p}_side_special`], timing_window: "tight", starter: "down_attack", ender: "side_special", expected_result: "offstage pressure", tutorial_hint: "Sweep, spike, then side special." },
      { combo_id: `${p}_aura_combo`, display_name: `${fighter.prefix} Aura Burst`, difficulty: "aura", input_sequence: ["aura_charge", "neutral_special", "side_attack"], move_sequence: [`${p}_neutral_special`, `${p}_side_attack`], timing_window: "aura", starter: "neutral_special", ender: "side_attack", expected_result: "aura-enhanced damage", tutorial_hint: "Charge aura, special, then side attack." },
      { combo_id: `${p}_super_confirm`, display_name: `${fighter.prefix} Super Finish`, difficulty: "super", input_sequence: ["side_attack", "super"], move_sequence: [`${p}_side_attack`, `${p}_super`], timing_window: "super", starter: "side_attack", ender: "super", expected_result: "super knockback", tutorial_hint: "Confirm into super with full aura." },
    ];
  }
  return catalog;
}

function buildAnimationContract() {
  const contract = {};
  for (const fighter of FIGHTERS) {
    contract[fighter.id] = {
      fighter_id: fighter.id,
      required_clips: REQUIRED_ANIMATIONS,
      production_proxy: true,
      asset_tier: "production_proxy",
    };
  }
  return contract;
}

function buildStageCatalog() {
  const stages = [
    "skyline-arena", "training-grid", "impact-platform", "center-clash",
    "lunar-outpost", "solar-outpost", "lunar-base", "solar-base",
  ];
  const catalog = {};
  for (const id of stages) {
    catalog[id] = {
      stage_id: id,
      scene_path: `res://scenes/stages/${id.split("-").map((w) => w.charAt(0).toUpperCase() + w.slice(1)).join("")}.tscn`,
      has_collision: true,
      has_spawn_points: true,
      has_blast_zones: true,
      has_preview: true,
      production_proxy: true,
    };
  }
  catalog["skyline-arena"].scene_path = "res://scenes/stages/SkylineArena.tscn";
  return catalog;
}

fs.mkdirSync(path.join(dataDir, "moves"), { recursive: true });
fs.mkdirSync(path.join(dataDir, "combos"), { recursive: true });
fs.mkdirSync(path.join(dataDir, "fighters"), { recursive: true });
fs.mkdirSync(path.join(dataDir, "animations"), { recursive: true });
fs.mkdirSync(path.join(dataDir, "stages"), { recursive: true });

const moveCatalog = buildMoves();
const comboCatalog = buildCombos();
const animContract = buildAnimationContract();
const stageCatalog = buildStageCatalog();

fs.writeFileSync(path.join(dataDir, "moves/move_catalog.json"), JSON.stringify(moveCatalog, null, 2) + "\n");
fs.writeFileSync(path.join(dataDir, "combos/combo_catalog.json"), JSON.stringify(comboCatalog, null, 2) + "\n");
fs.writeFileSync(path.join(dataDir, "animations/animation_contract.json"), JSON.stringify(animContract, null, 2) + "\n");
fs.writeFileSync(path.join(dataDir, "stages/stage_catalog.json"), JSON.stringify(stageCatalog, null, 2) + "\n");

for (const fighter of FIGHTERS) {
  fs.writeFileSync(
    path.join(dataDir, "fighters", `${fighter.id}.json`),
    JSON.stringify({ fighter_id: fighter.id, element: fighter.element, asset_tier: "production_proxy", moves: Object.keys(moveCatalog[fighter.id]).filter((k) => !k.includes("_") || MOVE_TYPES.some((m) => m.id === k)) }, null, 2) + "\n",
  );
}

console.log("Generated move/combo/animation/stage catalogs");
console.log(`  fighters: ${FIGHTERS.length}`);
console.log(`  moves per fighter: ${MOVE_TYPES.length}`);
console.log(`  combos per fighter: 10`);
