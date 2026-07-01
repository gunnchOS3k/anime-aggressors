import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { FIGHTERS, loadAnimationContract } from "./godot-product-validation-shared.mjs";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const godotRoot = path.join(repoRoot, "game/godot");
const contract = loadAnimationContract();
const errors = [];

const REQUIRED_LIMBS = [
  "hips", "chest", "head",
  "left_upper_arm", "left_forearm", "left_hand",
  "right_upper_arm", "right_forearm", "right_hand",
  "left_upper_leg", "left_lower_leg", "left_foot",
  "right_upper_leg", "right_lower_leg", "right_foot",
  "element_accessory", "aura_socket",
];

if (!contract) {
  errors.push("missing game/godot/data/animations/animation_contract.json");
} else {
  for (const fighterId of FIGHTERS) {
    const entry = contract[fighterId];
    if (!entry?.required_clips?.length) {
      errors.push(`animation_contract.json: fighter_id=${fighterId} missing required_clips`);
    }
  }
}

const factorySrc = fs.readFileSync(path.join(godotRoot, "scripts/fighter/ProductionFighterFactory.gd"), "utf8");
for (const limb of REQUIRED_LIMBS) {
  if (!factorySrc.includes(`"${limb}"`) && !factorySrc.includes(limb)) {
    errors.push(`ProductionFighterFactory.gd: missing limb ${limb}`);
  }
}

const profileSrc = fs.readFileSync(path.join(godotRoot, "scripts/fighter/FighterSilhouetteProfile.gd"), "utf8");
for (const fighterId of FIGHTERS) {
  if (!profileSrc.includes(`"${fighterId}"`)) {
    errors.push(`FighterSilhouetteProfile.gd: fighter_id=${fighterId} missing profile`);
  }
}

if (errors.length > 0) {
  console.error("Fighter animation contract validation failed:");
  for (const err of errors) console.error(`  - ${err}`);
  process.exit(1);
}

console.log("Fighter animation contract OK");
