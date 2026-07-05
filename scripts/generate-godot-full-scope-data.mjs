#!/usr/bin/env node
/**
 * Generates schema v2 move manifests with fighter-unique combat identity.
 * Source of truth for stats: packages/game-core profiles + fighter design matrix.
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const godotRoot = path.join(root, "game-godot");

const META = {
  "ember-vale": { displayName: "Ember Vale", archetype: "Rushdown Striker", element: "flame", elementLabel: "Flame", color: "#e8453c", signatureMove: "Cinder Rush", productionStatus: "proxy", combatTag: "burn_rushdown" },
  "rook-ironside": { displayName: "Rook Ironside", archetype: "Armored Bruiser", element: "impact", elementLabel: "Impact", color: "#f28c28", signatureMove: "Faultline Breaker", productionStatus: "proxy", combatTag: "armor_quake" },
  "juno-spark": { displayName: "Juno Spark", archetype: "Speed Confirm", element: "volt", elementLabel: "Volt", color: "#f5d042", signatureMove: "Flash Circuit", productionStatus: "proxy", combatTag: "speed_chain" },
  "kaia-windrow": { displayName: "Kaia Windrow", archetype: "Aerial Spacer", element: "gale", elementLabel: "Gale", color: "#3cb371", signatureMove: "Spiral Current", productionStatus: "proxy", combatTag: "wind_drift" },
  "nix-calder": { displayName: "Nix Calder", archetype: "Control Tank", element: "frost", elementLabel: "Frost", color: "#4a90d9", signatureMove: "Glacier Lock", productionStatus: "placeholder", combatTag: "freeze_control" },
  "orion-vell": { displayName: "Orion Vell", archetype: "Combo Control", element: "gravity", elementLabel: "Gravity", color: "#5b4b8a", signatureMove: "Orbit Collapse", productionStatus: "placeholder", combatTag: "gravity_pull" },
  "vesper-nyx": { displayName: "Vesper Nyx", archetype: "Phase Trickster", element: "void", elementLabel: "Void", color: "#9b59b6", signatureMove: "Null Step", productionStatus: "placeholder", combatTag: "phase_mark" },
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

const REQUIRED_MOVE_IDS = [
  "jab_1", "jab_2", "jab_finisher", "forward_tilt", "up_tilt", "down_tilt",
  "dash_attack", "heavy_attack", "neutral_air", "forward_air", "up_air", "down_air",
  "neutral_special_projectile", "side_special", "up_special_recovery", "down_special",
  "grab", "throw_forward", "throw_back", "throw_up", "throw_down",
  "aura_charge", "aura_burst",
];

const FEEDBACK = {
  light: (vfx, sfx) => ({ tier: "light", hitstop_frames: 3, camera_event: "shake_light", vfx_event: vfx, sfx_event: sfx, screen_flash: false }),
  medium: (vfx, sfx) => ({ tier: "medium", hitstop_frames: 5, camera_event: "shake_medium", vfx_event: vfx, sfx_event: sfx, screen_flash: false }),
  heavy: (vfx, sfx) => ({ tier: "heavy", hitstop_frames: 8, camera_event: "shake_heavy", vfx_event: vfx, sfx_event: sfx, screen_flash: false }),
  aura: (vfx, sfx) => ({ tier: "aura", hitstop_frames: 12, camera_event: "pulse_aura", vfx_event: vfx, sfx_event: sfx, screen_flash: true }),
  super: (vfx, sfx) => ({ tier: "super", hitstop_frames: 15, camera_event: "pulse_super", vfx_event: vfx, sfx_event: sfx, screen_flash: true }),
};

function elementEffect(element, effect, strength = 1.0) {
  return { type: element, effect, strength };
}

function baseAuraScaling(element, extras = {}) {
  return {
    level_0: { damage_mult: 1.0, ...extras.level_0 },
    level_1: { damage_mult: 1.05, element_strength: 1.2, ...extras.level_1 },
    level_2: { damage_mult: 1.1, hitbox_scale: 1.15, element_strength: 1.5, ...extras.level_2 },
    level_3: { damage_mult: 1.15, hitbox_scale: 1.25, extra_active_frames: 1, cancel_windows: [{ start: 8, end: 14 }], element_strength: 1.8, ...extras.level_3 },
    super_ready: { damage_mult: 1.2, hitbox_scale: 1.35, feedback_tier: "aura", ...extras.super_ready },
  };
}

function moveBase(id, fighterId, meta, overrides = {}) {
  const { extra, ...rest } = overrides;
  const dmg = STATS[fighterId].damageMult / 100;
  const defaults = {
    move_id: id,
    fighter_id: fighterId,
    move_type: "melee",
    direction: "neutral",
    input_command: "attack_neutral",
    grounded_air: "grounded",
    startup_frames: 4,
    active_frames: 3,
    recovery_frames: 10,
    hitboxes: [{ offset_x: 36, offset_y: -8, width: 40, height: 32 }],
    damage: 5 * dmg,
    angle_deg: 45,
    base_knockback: 6,
    knockback_growth: 1.1,
    shield_damage: 3,
    shield_stun_frames: 6,
    hitstop_frames: 3,
    aura_scaling: baseAuraScaling(meta.element),
    feedback: FEEDBACK.light(`${meta.element}_spark`, `${meta.element}_hit_light`),
    training_display_name: id,
    combat_tag: meta.combatTag,
  };
  return { ...defaults, ...rest, ...(extra ?? {}) };
}

const FIGHTER_IDENTITY = {
  "ember-vale": {
    projectile: { behavior_by_aura: ["straight", "straight", "beam", "beam"], type: "flame_shot", offset_x: 44 },
    burstName: "Cinder Rush",
    throws: {
      forward: { name: "Flame Spin Toss", angle: 35, kb: 14, role: "edge_pressure", combo_role: "positioning" },
      back: { name: "Reversal Flame Burst", angle: 140, kb: 18, role: "reversal", combo_role: "kill" },
      up: { name: "Erupting Uppercut", angle: 82, kb: 16, role: "juggle", combo_role: "starter" },
      down: { name: "Ground Ignition", angle: 270, kb: 12, role: "setup", combo_role: "bounce" },
    },
    auraExtras: { level_2: { hitbox_scale: 1.2, element_strength: 1.6 }, level_3: { extra_active_frames: 2 } },
    elementEffect: "burn",
  },
  "rook-ironside": {
    projectile: { behavior_by_aura: ["shockwave", "shockwave", "shockwave", "shockwave"], type: "faultline_wave", offset_x: 28, speed_by_aura: [180, 200, 240, 280] },
    burstName: "Faultline Breaker",
    throws: {
      forward: { name: "Shoulder Carry Slam", angle: 25, kb: 20, role: "edge_pressure", combo_role: "positioning" },
      back: { name: "Suplex Reversal", angle: 160, kb: 22, role: "reversal", combo_role: "kill" },
      up: { name: "Rising Boulder", angle: 78, kb: 18, role: "juggle", combo_role: "starter" },
      down: { name: "Crater Slam", angle: 265, kb: 16, role: "setup", combo_role: "bounce" },
    },
    auraExtras: { level_1: { armor_frames: 3 }, level_2: { armor_frames: 5, hitbox_scale: 1.1 }, level_3: { armor_frames: 8, knockback_mult: 1.2 } },
    elementEffect: "quake",
  },
  "juno-spark": {
    projectile: { behavior_by_aura: ["straight", "straight", "straight", "beam"], type: "volt_needle", offset_x: 40, speed_by_aura: [520, 580, 640, 720] },
    burstName: "Flash Circuit",
    throws: {
      forward: { name: "Electric Palm Launch", angle: 40, kb: 13, role: "edge_pressure", combo_role: "positioning" },
      back: { name: "Blink-Behind Kick", angle: 150, kb: 17, role: "reversal", combo_role: "kill" },
      up: { name: "Lightning Launcher", angle: 85, kb: 15, role: "juggle", combo_role: "starter" },
      down: { name: "Stun Bounce", angle: 268, kb: 11, role: "setup", combo_role: "bounce" },
    },
    auraExtras: { level_1: { extra_active_frames: 1 }, level_2: { cancel_windows: [{ start: 6, end: 12 }] }, level_3: { element_strength: 2.0 } },
    elementEffect: "chain_stun",
  },
  "kaia-windrow": {
    projectile: { behavior_by_aura: ["curving_blade", "curving_blade", "curving_blade", "beam"], type: "wind_blade", offset_x: 38, speed_by_aura: [340, 380, 420, 480] },
    burstName: "Spiral Current",
    throws: {
      forward: { name: "Gust Push", angle: 30, kb: 12, role: "edge_pressure", combo_role: "positioning" },
      back: { name: "Crosswind Reversal", angle: 145, kb: 16, role: "reversal", combo_role: "kill" },
      up: { name: "Cyclone Lift", angle: 88, kb: 14, role: "juggle", combo_role: "starter" },
      down: { name: "Tornado Pop-Up", angle: 272, kb: 10, role: "setup", combo_role: "bounce" },
    },
    auraExtras: { level_1: { cancel_windows: [{ start: 10, end: 16 }] }, level_2: { hitbox_scale: 1.1 }, level_3: { extra_active_frames: 2 } },
    elementEffect: "wind_drift",
  },
  "nix-calder": {
    projectile: { behavior_by_aura: ["straight", "straight", "trap", "trap"], type: "ice_shard", offset_x: 36, speed_by_aura: [280, 300, 320, 340] },
    burstName: "Glacier Lock",
    throws: {
      forward: { name: "Frozen Shove", angle: 28, kb: 11, role: "edge_pressure", combo_role: "positioning" },
      back: { name: "Ice Pivot Toss", angle: 155, kb: 15, role: "reversal", combo_role: "kill" },
      up: { name: "Glacier Pillar", angle: 80, kb: 13, role: "juggle", combo_role: "starter" },
      down: { name: "Freeze-Bury Setup", angle: 275, kb: 9, role: "setup", combo_role: "trap" },
    },
    auraExtras: { level_1: { element_strength: 1.3 }, level_2: { armor_frames: 4 }, level_3: { element_strength: 2.2 } },
    elementEffect: "chill_freeze",
  },
  "orion-vell": {
    projectile: { behavior_by_aura: ["pull_orb", "pull_orb", "pull_orb", "pull_orb"], type: "gravity_orb", offset_x: 42, speed_by_aura: [160, 180, 200, 220] },
    burstName: "Orbit Collapse",
    throws: {
      forward: { name: "Gravitational Shove", angle: 32, kb: 13, role: "edge_pressure", combo_role: "positioning" },
      back: { name: "Orbit Reversal", angle: 148, kb: 17, role: "reversal", combo_role: "kill" },
      up: { name: "Suspended Juggle", angle: 86, kb: 12, role: "juggle", combo_role: "starter" },
      down: { name: "Gravity Crush", angle: 270, kb: 14, role: "setup", combo_role: "bounce" },
    },
    auraExtras: { level_1: { element_strength: 1.2 }, level_2: { hitbox_scale: 1.15 }, level_3: { angle_deg_override: true } },
    elementEffect: "gravity_pull",
  },
  "vesper-nyx": {
    projectile: { behavior_by_aura: ["delayed_orb", "delayed_orb", "trap", "trap"], type: "void_mark", offset_x: 40, speed_by_aura: [200, 220, 240, 260] },
    burstName: "Null Step",
    throws: {
      forward: { name: "Void Push", angle: 38, kb: 12, role: "edge_pressure", combo_role: "positioning" },
      back: { name: "Phase Swap", angle: 152, kb: 16, role: "reversal", combo_role: "kill" },
      up: { name: "Portal Launcher", angle: 84, kb: 14, role: "juggle", combo_role: "starter" },
      down: { name: "Void Trap Plant", angle: 268, kb: 8, role: "setup", combo_role: "trap" },
    },
    auraExtras: { level_1: { element_strength: 1.1 }, level_2: { cancel_windows: [{ start: 7, end: 13 }] }, level_3: { extra_active_frames: 1 } },
    elementEffect: "void_mark",
  },
};

function buildThrow(id, fighterId, meta, identity, dir, dmg) {
  const t = identity.throws[dir];
  const dirMap = { forward: "forward", back: "back", up: "up", down: "down" };
  return moveBase(`throw_${dir}`, fighterId, meta, {
    move_type: "throw",
    direction: dirMap[dir],
    input_command: `throw_${dir}`,
    grounded_air: "both",
    startup_frames: 4,
    active_frames: 2,
    recovery_frames: 14,
    hitboxes: [],
    damage: t.kb * 0.4 * dmg,
    angle_deg: t.angle,
    base_knockback: t.kb,
    knockback_growth: 1.15,
    feedback: FEEDBACK.medium(`${meta.element}_throw`, `${meta.element}_throw_sfx`),
    training_display_name: t.name,
    throw: {
      direction: dir,
      hold_frames: 0,
      release_frame: 2,
      victim_offset: { x: dir === "back" ? -20 : 20, y: -8 },
      damage: t.kb * 0.4 * dmg,
      angle_deg: t.angle,
      base_knockback: t.kb,
      knockback_growth: 1.15,
      combo_role: t.combo_role,
      role: t.role,
    },
    element_effect: elementEffect(meta.element, identity.elementEffect, 1.0),
    aura_scaling: baseAuraScaling(meta.element, { level_2: { knockback_mult: 1.08 }, level_3: { knockback_mult: 1.15 } }),
  });
}

function buildProjectileMove(fighterId, meta, identity, dmg) {
  const p = identity.projectile;
  const speedArr = p.speed_by_aura ?? [400, 440, 480, 520];
  const sizeArr = [14, 16, 20, 24];
  const lifeArr = [72, 84, 96, 108];
  const dmgArr = [8, 9, 10, 12].map((d) => d * dmg);
  return moveBase("neutral_special_projectile", fighterId, meta, {
    move_type: "projectile",
    direction: "neutral",
    input_command: "special_neutral",
    grounded_air: "both",
    startup_frames: 6,
    active_frames: 2,
    recovery_frames: 16,
    hitboxes: [],
    damage: dmgArr[0],
    base_knockback: 8,
    feedback: FEEDBACK.medium(`${meta.element}_proj`, `${meta.element}_proj_sfx`),
    training_display_name: `${meta.elementLabel} Shot`,
    element_effect: elementEffect(meta.element, identity.elementEffect, 1.0),
    projectile: {
      spawn_frame: 6,
      type: p.type,
      offset_x: p.offset_x,
      offset_y: -12,
      angle_deg: 0,
      speed_by_aura: speedArr,
      damage_by_aura: dmgArr,
      size_by_aura: sizeArr,
      lifetime_frames_by_aura: lifeArr,
      behavior_by_aura: p.behavior_by_aura,
    },
    aura_scaling: baseAuraScaling(meta.element, identity.auraExtras),
  });
}

function buildMoveManifest(fighterId) {
  const meta = META[fighterId];
  const identity = FIGHTER_IDENTITY[fighterId];
  const dmg = STATS[fighterId].damageMult / 100;
  const aura = baseAuraScaling(meta.element, identity.auraExtras);
  const elem = elementEffect(meta.element, identity.elementEffect, 1.0);

  const moves = [
    moveBase("jab_1", fighterId, meta, { input_command: "attack_neutral", training_display_name: "Jab 1", damage: 2.5 * dmg, base_knockback: 3, startup_frames: 3, recovery_frames: 8, element_effect: elem, cancel_windows: [{ start: 5, end: 10, requires: "hit_confirm" }] }),
    moveBase("jab_2", fighterId, meta, { input_command: "attack_neutral", training_display_name: "Jab 2", damage: 3 * dmg, base_knockback: 4, startup_frames: 3, recovery_frames: 8, element_effect: elem }),
    moveBase("jab_finisher", fighterId, meta, { input_command: "attack_neutral", training_display_name: "Jab Finisher", damage: 5 * dmg, base_knockback: 7, startup_frames: 4, recovery_frames: 12, feedback: FEEDBACK.medium(`${meta.element}_jab_fin`, `${meta.element}_jab_fin_sfx`), element_effect: elem, aura_scaling: aura }),
    moveBase("forward_tilt", fighterId, meta, { direction: "forward", input_command: "attack_forward", training_display_name: "Forward Tilt", damage: 7 * dmg, base_knockback: 8, startup_frames: 5, recovery_frames: 12, element_effect: elem }),
    moveBase("up_tilt", fighterId, meta, { direction: "up", input_command: "attack_up", training_display_name: "Up Tilt", damage: 6 * dmg, base_knockback: 7, angle_deg: 75, startup_frames: 5, recovery_frames: 11, element_effect: elem }),
    moveBase("down_tilt", fighterId, meta, { direction: "down", input_command: "attack_down", training_display_name: "Down Tilt", damage: 5 * dmg, base_knockback: 6, angle_deg: 280, startup_frames: 4, recovery_frames: 10, element_effect: elem }),
    moveBase("dash_attack", fighterId, meta, { direction: "forward", input_command: "attack_dash", training_display_name: "Dash Attack", damage: 8 * dmg, base_knockback: 9, startup_frames: 6, active_frames: 4, recovery_frames: 16, element_effect: elem }),
    moveBase("heavy_attack", fighterId, meta, { direction: "forward", input_command: "attack_heavy", training_display_name: "Heavy Attack", damage: 12 * dmg, base_knockback: 14, startup_frames: 8, active_frames: 4, recovery_frames: 18, angle_deg: 30, feedback: FEEDBACK.heavy(`${meta.element}_heavy`, `${meta.element}_heavy_sfx`), element_effect: elem, aura_scaling: aura }),
    moveBase("neutral_air", fighterId, meta, { direction: "air_neutral", input_command: "attack_air_neutral", grounded_air: "air", training_display_name: "Neutral Air", damage: 6 * dmg, base_knockback: 7, element_effect: elem }),
    moveBase("forward_air", fighterId, meta, { direction: "air_forward", input_command: "attack_air_forward", grounded_air: "air", training_display_name: "Forward Air", damage: 7 * dmg, base_knockback: 8, angle_deg: 30, element_effect: elem }),
    moveBase("up_air", fighterId, meta, { direction: "air_up", input_command: "attack_air_up", grounded_air: "air", training_display_name: "Up Air", damage: 6 * dmg, base_knockback: 7, angle_deg: 80, element_effect: elem }),
    moveBase("down_air", fighterId, meta, { direction: "air_down", input_command: "attack_air_down", grounded_air: "air", training_display_name: "Down Air", damage: 8 * dmg, base_knockback: 9, angle_deg: 270, feedback: FEEDBACK.medium(`${meta.element}_dair`, `${meta.element}_dair_sfx`), element_effect: elem }),
    buildProjectileMove(fighterId, meta, identity, dmg),
    moveBase("side_special", fighterId, meta, { move_type: "field", direction: "forward", input_command: "special_forward", training_display_name: `${meta.signatureMove} Side`, damage: 9 * dmg, base_knockback: 10, startup_frames: 7, recovery_frames: 18, element_effect: elem, aura_scaling: aura }),
    moveBase("up_special_recovery", fighterId, meta, { move_type: "movement", direction: "up", input_command: "special_up", grounded_air: "both", training_display_name: "Up Special / Recovery", damage: 8 * dmg, base_knockback: 12, angle_deg: 80, startup_frames: 6, recovery_frames: 20, element_effect: elem, extra: { self_movement: { x: 0, y: -320 } } }),
    moveBase("down_special", fighterId, meta, { move_type: "trap", direction: "down", input_command: "special_down", training_display_name: "Down Special", damage: 9 * dmg, base_knockback: 9, angle_deg: 270, startup_frames: 8, recovery_frames: 22, element_effect: elem, aura_scaling: aura }),
    moveBase("grab", fighterId, meta, { move_type: "grab", direction: "neutral", input_command: "grab", training_display_name: "Grab", damage: 0, base_knockback: 0, startup_frames: 7, active_frames: 2, recovery_frames: 20, hitboxes: [{ offset_x: 28, offset_y: -4, width: 48, height: 36 }] }),
    buildThrow("forward", fighterId, meta, identity, "forward", dmg),
    buildThrow("back", fighterId, meta, identity, "back", dmg),
    buildThrow("up", fighterId, meta, identity, "up", dmg),
    buildThrow("down", fighterId, meta, identity, "down", dmg),
    moveBase("aura_charge", fighterId, meta, { move_type: "charge", direction: "none", input_command: "aura_charge", grounded_air: "both", training_display_name: "Aura Charge", damage: 0, base_knockback: 0, startup_frames: 0, active_frames: 0, recovery_frames: 0, hitboxes: [], aura_scaling: {} }),
    moveBase("aura_burst", fighterId, meta, { move_type: "burst", direction: "neutral", input_command: "aura_burst", training_display_name: identity.burstName, damage: 18 * dmg, base_knockback: 22, startup_frames: 10, active_frames: 6, recovery_frames: 24, feedback: FEEDBACK.super(`${meta.element}_burst`, `${meta.element}_burst_sfx`), element_effect: elementEffect(meta.element, identity.elementEffect, 2.5), aura_scaling: baseAuraScaling(meta.element, { super_ready: { hitbox_scale: 1.5, damage_mult: 1.3, feedback_tier: "super" } }), extra: { meter_cost: 100 } }),
  ];

  return { fighter_id: fighterId, schema_version: 2, combat_tag: meta.combatTag, moves };
}

function buildFighter(id) {
  const m = META[id];
  const s = STATS[id];
  const run = BASE.runSpeed * (s.runSpeedMult / 100);
  return {
    id,
    displayName: m.displayName,
    archetype: m.archetype,
    element: m.elementLabel,
    size: id.includes("rook") || id.includes("nix") ? "large" : id.includes("juno") || id.includes("vesper") ? "small" : "medium",
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
    combatTag: m.combatTag,
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
const combatDir = path.join(godotRoot, "data/combat");
fs.mkdirSync(movesDir, { recursive: true });
fs.mkdirSync(balanceDir, { recursive: true });
fs.mkdirSync(combatDir, { recursive: true });

const ids = Object.keys(META);
for (const id of ids) {
  fs.writeFileSync(path.join(fightersDir, `${id}.json`), JSON.stringify(buildFighter(id), null, 2));
  fs.writeFileSync(path.join(movesDir, `${id}.json`), JSON.stringify(buildMoveManifest(id), null, 2));
  fs.writeFileSync(
    path.join(fightersDir, `${id}_animations.json`),
    JSON.stringify({ fighter_id: id, clips: ["idle", "walk", "run", "dash", "jump", "fall", "land", "jab_1", "jab_2", "heavy_attack", "special", "shield", "hurt_light", "hurt_heavy", "launched", "aura_charge", "aura_burst", "throw_forward", "ko"], status: "manifest_only" }, null, 2),
  );
}
fs.writeFileSync(path.join(fightersDir, "roster.json"), JSON.stringify({ fighters: ids }, null, 2));
fs.writeFileSync(path.join(balanceDir, "base_constants.json"), JSON.stringify({ fps: 60, ...BASE, stocksDefault: 3 }, null, 2));

const schema = {
  schema_version: 2,
  move_fields: [
    "move_id", "fighter_id", "move_type", "direction", "input_command", "grounded_air",
    "startup_frames", "active_frames", "recovery_frames", "hitboxes", "damage", "angle_deg",
    "base_knockback", "knockback_growth", "shield_damage", "shield_stun_frames", "hitstop_frames",
    "aura_scaling", "feedback", "training_display_name",
  ],
  conditional_fields: {
    projectile: ["projectile"],
    throw: ["throw"],
    elemental: ["element_effect"],
    combo: ["cancel_windows"],
  },
  move_types: ["melee", "projectile", "grab", "throw", "charge", "burst", "movement", "counter", "trap", "field"],
  directions: ["neutral", "forward", "back", "up", "down", "air_neutral", "air_forward", "air_up", "air_down", "none"],
  required_move_ids: REQUIRED_MOVE_IDS,
};
fs.writeFileSync(path.join(movesDir, "move_schema.json"), JSON.stringify(schema, null, 2));

console.log(`Generated ${ids.length} fighters with schema v2 move manifests (${REQUIRED_MOVE_IDS.length} moves each) in game-godot/data/`);
