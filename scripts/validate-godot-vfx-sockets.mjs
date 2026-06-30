import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const godotRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..", "game/godot");
const errors = [];

const requiredVfx = [
  "scripts/vfx/ElementalAuraSystem.gd",
  "scripts/vfx/HitSparkFactory.gd",
  "scripts/vfx/AttackTrailFactory.gd",
  "scripts/vfx/LaunchTrail.gd",
  "scripts/vfx/ImpactFlash.gd",
  "scripts/vfx/VfxSocket.gd",
];

for (const rel of requiredVfx) {
  if (!fs.existsSync(path.join(godotRoot, rel))) {
    errors.push(`missing ${rel}`);
  }
}

const factorySrc = fs.readFileSync(path.join(godotRoot, "scripts/fighter/ProductionFighterFactory.gd"), "utf8");
for (const socket of ["aura_socket", "right_hand_socket", "left_hand_socket", "right_foot_socket"]) {
  if (!factorySrc.includes(socket)) {
    errors.push(`ProductionFighterFactory missing VFX socket ${socket}`);
  }
}

const battleSrc = fs.readFileSync(path.join(godotRoot, "scripts/BattleScene.gd"), "utf8");
if (!battleSrc.includes("AttackTrailFactory") && !battleSrc.includes("play_hit_spark")) {
  errors.push("BattleScene does not spawn socket-attached VFX");
}

const skylineSrc = fs.readFileSync(path.join(godotRoot, "scenes/stages/SkylineArena.tscn"), "utf8");
for (const node of ["MainPlatform", "LeftPlatform", "RightPlatform", "SpawnA", "SpawnB"]) {
  if (!skylineSrc.includes(node)) {
    errors.push(`SkylineArena missing ${node}`);
  }
}

if (errors.length > 0) {
  console.error("Godot VFX/socket validation failed:");
  for (const err of errors) console.error(`  - ${err}`);
  process.exit(1);
}

console.log("Godot VFX/socket OK");
