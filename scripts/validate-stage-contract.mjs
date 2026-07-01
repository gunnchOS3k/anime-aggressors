import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { loadStageCatalog } from "./godot-product-validation-shared.mjs";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const godotRoot = path.join(repoRoot, "game/godot");
const catalog = loadStageCatalog();
const errors = [];

const REQUIRED_STAGES = [
  "skyline-arena", "training-grid", "impact-platform", "center-clash",
  "lunar-outpost", "solar-outpost", "lunar-base", "solar-base",
];

if (!catalog) {
  errors.push("missing game/godot/data/stages/stage_catalog.json");
} else {
  for (const stageId of REQUIRED_STAGES) {
    const entry = catalog[stageId];
    if (!entry) {
      errors.push(`stage_catalog.json: missing stage_id=${stageId}`);
      continue;
    }
    const sceneRel = entry.scene_path?.replace("res://", "") ?? "";
    const scenePath = path.join(godotRoot, sceneRel);
    if (!fs.existsSync(scenePath)) {
      errors.push(`stage_id=${stageId} missing scene at game/godot/${sceneRel}`);
    }
  }
}

if (errors.length > 0) {
  console.error("Stage contract validation failed:");
  for (const err of errors) console.error(`  - ${err}`);
  process.exit(1);
}

console.log("Stage contract OK");
console.log(`  stages: ${REQUIRED_STAGES.length}`);
