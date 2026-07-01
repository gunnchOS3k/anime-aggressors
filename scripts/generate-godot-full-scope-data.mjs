#!/usr/bin/env node
/**
 * Generates normalized game-godot fighter profiles and per-fighter move manifests.
 * Source of truth for stats: packages/game-core profiles + defaultFighters metadata.
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const godotRoot = path.join(root, "game-godot");

const META = {
  "ember-vale": { displayName: "Ember Vale", archetype: "Rushdown Striker", element: "Flame", size: "medium", color: "#e8453c", signatureMove: "Cinder Rush", productionStatus: "proxy" },
  "rook-ironside": { displayName: "Rook Ironside", archetype: "Armored Bruiser", element: "Impact", size: "large", color: "#f28c28", signatureMove: "Faultline Breaker", productionStatus: "proxy" },
  "juno-spark": { displayName: "Juno Spark", archetype: "Speed Confirm", element: "Volt", size: "small", color: "#f5d042", signatureMove: "Flash Circuit", productionStatus: "proxy" },
  "kaia-windrow": { displayName: "Kaia Windrow", archetype: "Aerial Spacer", element: "Gale", size: "medium", color: "#3cb371", signatureMove: "Spiral Current", productionStatus: "proxy" },
  "nix-calder": { displayName: "Nix Calder", archetype: "Control Tank", element: "Frost", size: "large", color: "#4a90d9", signatureMove: "Glacier Lock", productionStatus: "placeholder" },
  "orion-vell": { displayName: "Orion Vell", archetype: "Combo Control", element: "Gravity", size: "medium", color: "#5b4b8a", signatureMove: "Orbit Collapse", productionStatus: "placeholder" },
  "vesper-nyx": { displayName: "Vesper Nyx", archetype: "Phase Trickster", element: "Void", size: "small", color: "#9b59b6", signatureMove: "Null Step", productionStatus: "placeholder" },
};

const STATS = {
  "ember-vale": { weight: 100, runSpeedMult: 105, airSpeedMult: 102, fallSpeedMult: 100, jumpVelocityMult: 100, shieldHealthMult: 100, damageMult: 100, knockbackTakenMult: 100, cpuTags: ["rushdown", "approach"] },
  "rook-ironside": { weight: 125, runSpeedMult: 85, airSpeedMult: 88, fallSpeedMult: 108, jumpVelocityMult: 92, shieldHealthMult: 115, damageMult: 118, knockbackTakenMult: 88, cpuTags: ["tank", "punish"] },
  "juno-spark": { weight: 82, runSpeedMult: 118, airSpeedMult: 122, fallSpeedMult: 102, jumpVelocityMult: 108, shieldHealthMult: 92, damageMult: 92, knockbackTakenMult: 112, cpuTags: ["speed", "combo"] },
  "kaia-windrow": { weight: 96, runSpeedMult: 98, airSpeedMult: 112, fallSpeedMult: 96, jumpVelocityMult: 104, shieldHealthMult: 98, damageMult: 96, knockbackTakenMult: 104, cpuTags: ["spacing", "aerial"] },
  "nix-calder": { weight: 118, runSpeedMult: 90, airSpeedMult: 90, fallSpeedMult: 105, jumpVelocityMult: 95, shieldHealthMult: 110, damageMult: 105, knockbackTakenMult: 90, cpuTags: ["control", "defensive"] },
  "orion-vell": { weight: 100, runSpeedMult: 100, airSpeedMult: 100, fallSpeedMult: 100, jumpVelocityMult: 100, shieldHealthMult: 100, damageMult: 100, knockbackTakenMult: 100, cpuTags: ["combo", "neutral"] },
  "vesper-nyx": { weight: 88, runSpeedMult: 95, airSpeedMult: 98, fallSpeedMult: 96, jumpVelocityMult: 98, shieldHealthMult: 95, damageMult: 94, knockbackTakenMult: 106, cpuTags: ["trickster", "mixup"] },
};

const BASE = { runSpeed: 280, dashSpeed: 420, airSpeed: 220, jumpStrength: 620, fallSpeed: 1800, auraMax: 100 };

function moveTemplate(id, fighterId, overrides = {}) {
  const defaults = {
    move_id: id,
    fighter_id: fighterId,
    input_command: overrides.input_command ?? "attack_neutral",
    grounded_air: overrides.grounded_air ?? "grounded",
    startup_frames: overrides.startup_frames ?? 4,
    active_frames: overrides.active_frames ?? 3,
    recovery_frames: overrides.recovery_frames ?? 10,
    hitboxes: [{ offset_x: 36, offset_y: -8, width: 40, height: 32 }],
    hurtbox_changes: [],
    damage: overrides.damage ?? 5,
    angle_deg: overrides.angle_deg ?? 45,
    base_knockback: overrides.base_knockback ?? 6,
    knockback_growth: overrides.knockback_growth ?? 1.1,
    shield_damage: overrides.shield_damage ?? 3,
    shield_stun_frames: overrides.shield_stun_frames ?? 6,
    hitstop_frames: overrides.hitstop_frames ?? 3,
    self_movement: { x: 0, y: 0 },
    cancel_windows: [],
    aura_gain: overrides.aura_gain ?? 2,
    meter_cost: 0,
    armor_frames: 0,
    invulnerability_frames: 0,
    animation_clip: overrides.animation_clip ?? id,
    vfx_event: null,
    sfx_event: null,
    camera_event: null,
    training_display_name: overrides.training_display_name ?? id,
  };
  return { ...defaults, ...overrides };
}

function buildMoveManifest(fighterId) {
  const dmg = STATS[fighterId].damageMult / 100;
  return {
    fighter_id: fighterId,
    schema_version: 1,
    moves: [
      moveTemplate("jab", fighterId, { input_command: "attack_neutral", training_display_name: "Jab", damage: 3 * dmg, base_knockback: 4 }),
      moveTemplate("forward_tilt", fighterId, { input_command: "attack_forward", training_display_name: "Forward Tilt", damage: 7 * dmg, base_knockback: 8, startup_frames: 5, recovery_frames: 12 }),
      moveTemplate("heavy_attack", fighterId, { input_command: "attack_heavy", training_display_name: "Heavy Attack", damage: 12 * dmg, base_knockback: 14, startup_frames: 8, active_frames: 4, recovery_frames: 18, angle_deg: 30 }),
      moveTemplate("neutral_special", fighterId, { input_command: "special_neutral", training_display_name: "Neutral Special", damage: 10 * dmg, base_knockback: 10, startup_frames: 6, recovery_frames: 16 }),
      moveTemplate("up_special", fighterId, { input_command: "special_up", grounded_air: "both", training_display_name: "Up Special / Recovery", damage: 8 * dmg, base_knockback: 12, angle_deg: 80, self_movement: { x: 0, y: -320 } }),
      moveTemplate("down_special", fighterId, { input_command: "special_down", training_display_name: "Down Special", damage: 9 * dmg, base_knockback: 9, angle_deg: 270 }),
      moveTemplate("aerial_neutral", fighterId, { input_command: "attack_air_neutral", grounded_air: "air", training_display_name: "Aerial Neutral", damage: 6 * dmg, base_knockback: 7 }),
      moveTemplate("grab", fighterId, { input_command: "grab", training_display_name: "Grab (placeholder)", damage: 0, base_knockback: 0, startup_frames: 7, active_frames: 2, recovery_frames: 20 }),
      moveTemplate("throw", fighterId, { input_command: "throw_forward", training_display_name: "Throw (placeholder)", damage: 6 * dmg, base_knockback: 16, angle_deg: 45 }),
      moveTemplate("aura_charge", fighterId, { input_command: "aura_charge", grounded_air: "both", training_display_name: "Aura Charge", damage: 0, base_knockback: 0, aura_gain: 0, startup_frames: 0, active_frames: 0, recovery_frames: 0 }),
      moveTemplate("aura_burst", fighterId, { input_command: "aura_burst", training_display_name: "Aura Burst (placeholder)", damage: 18 * dmg, base_knockback: 22, meter_cost: 100, startup_frames: 10, active_frames: 6, recovery_frames: 24 }),
    ],
  };
}

function buildFighter(id) {
  const m = META[id];
  const s = STATS[id];
  const run = BASE.runSpeed * (s.runSpeedMult / 100);
  return {
    id,
    displayName: m.displayName,
    archetype: m.archetype,
    element: m.element,
    size: m.size,
    color: m.color,
    auraColor: m.color,
    weight: s.weight,
    runSpeed: run,
    dashSpeed: BASE.dashSpeed * (s.runSpeedMult / 100),
    airSpeed: BASE.airSpeed * (s.airSpeedMult / 100),
    jumpStrength: BASE.jumpStrength * (s.jumpVelocityMult / 100),
    fallSpeed: BASE.fallSpeed * (s.fallSpeedMult / 100),
    maxJumps: 2,
    damageTakenMult: s.knockbackTakenMult / 100,
    damageDealtMult: s.damageMult / 100,
    shieldHealthMult: s.shieldHealthMult / 100,
    signatureMove: m.signatureMove,
    defaultSkin: `proxy_${id}`,
    animationManifestPath: `res://data/fighters/${id}_animations.json`,
    moveListPath: `res://data/moves/${id}.json`,
    hitHurtProfile: { hurtboxWidth: 40, hurtboxHeight: 48, hitboxScale: 1.0 },
    shieldProfile: { maxHealth: 100 * (s.shieldHealthMult / 100), decayPerSecond: 18, stunMult: 1.0 },
    cpuBehaviorTags: s.cpuTags,
    productionStatus: m.productionStatus,
    portraitPlaceholder: `res://assets/ui/placeholders/fighter_${id}.svg`,
    modelPath: `res://assets/characters/proxy/${id}.glb`,
  };
}

const fightersDir = path.join(godotRoot, "data/fighters");
const movesDir = path.join(godotRoot, "data/moves");
const balanceDir = path.join(godotRoot, "data/balance");
fs.mkdirSync(movesDir, { recursive: true });
fs.mkdirSync(balanceDir, { recursive: true });

const ids = Object.keys(META);
for (const id of ids) {
  fs.writeFileSync(path.join(fightersDir, `${id}.json`), JSON.stringify(buildFighter(id), null, 2));
  fs.writeFileSync(path.join(movesDir, `${id}.json`), JSON.stringify(buildMoveManifest(id), null, 2));
  fs.writeFileSync(
    path.join(fightersDir, `${id}_animations.json`),
    JSON.stringify({ fighter_id: id, clips: ["idle", "walk", "run", "dash", "jump", "fall", "land", "jab", "heavy", "special", "shield", "hurt_light", "hurt_heavy", "launched", "aura_charge", "aura_burst", "ko"], status: "manifest_only" }, null, 2),
  );
}
fs.writeFileSync(path.join(fightersDir, "roster.json"), JSON.stringify({ fighters: ids }, null, 2));
fs.writeFileSync(path.join(balanceDir, "base_constants.json"), JSON.stringify({ fps: 60, ...BASE, stocksDefault: 3 }, null, 2));

const schema = {
  move_fields: [
    "move_id", "fighter_id", "input_command", "grounded_air", "startup_frames", "active_frames", "recovery_frames",
    "hitboxes", "hurtbox_changes", "damage", "angle_deg", "base_knockback", "knockback_growth", "shield_damage",
    "shield_stun_frames", "hitstop_frames", "self_movement", "cancel_windows", "aura_gain", "meter_cost",
    "armor_frames", "invulnerability_frames", "animation_clip", "vfx_event", "sfx_event", "camera_event", "training_display_name",
  ],
};
fs.writeFileSync(path.join(movesDir, "move_schema.json"), JSON.stringify(schema, null, 2));

console.log(`Generated ${ids.length} fighters + move manifests in game-godot/data/`);
