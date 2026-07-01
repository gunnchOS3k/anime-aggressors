import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const godotRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..", "game/godot");
const errors = [];

const statesSrc = fs.readFileSync(path.join(godotRoot, "scripts/fighter/FighterAnimationStateMachine.gd"), "utf8");
for (const state of [
  "idle", "jump_rise", "neutral_attack_active", "side_attack_active",
  "aura_charge_loop", "hitstun_light", "launch_tumble", "victory",
]) {
  if (!statesSrc.includes(`"${state}"`)) {
    errors.push(`animation state machine missing ${state}`);
  }
}

const choreographySrc = fs.readFileSync(path.join(godotRoot, "scripts/combat/MoveChoreography.gd"), "utf8");
if (!choreographySrc.includes("hitbox_socket") && !choreographySrc.includes("hit_socket")) {
  errors.push("MoveChoreography missing hitbox_socket");
}
if (!choreographySrc.includes("right_hand") && !choreographySrc.includes("right_hand_socket")) {
  errors.push("MoveChoreography missing hand socket references");
}

const timelineSrc = fs.readFileSync(path.join(godotRoot, "scripts/combat/AttackSocketTimeline.gd"), "utf8");
if (!timelineSrc.includes("right_hand_socket") && !timelineSrc.includes("right_foot_socket")) {
  errors.push("AttackSocketTimeline missing limb sockets");
}

const librarySrc = fs.readFileSync(path.join(godotRoot, "scripts/fighter/FighterAnimationLibrary.gd"), "utf8");
for (const anim of ["attack_active", "hitstun", "victory", "aura_charge"]) {
  if (!librarySrc.includes(`"${anim}"`)) {
    errors.push(`FighterAnimationLibrary missing ${anim}`);
  }
}

if (errors.length > 0) {
  console.error("Godot animation/choreography validation failed:");
  for (const err of errors) console.error(`  - ${err}`);
  process.exit(1);
}

console.log("Godot animation/choreography OK");
