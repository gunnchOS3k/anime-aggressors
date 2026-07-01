import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const godotRoot = path.join(repoRoot, "game/godot");
const errors = [];

const REQUIRED_DOCS = [
  "docs/ROADBLOCK_AUDIT.md",
  "docs/ENGINE_STRATEGY.md",
  "docs/PRODUCT_RESCUE_PLAN.md",
  "docs/PRODUCTION_ACCEPTANCE_GATES.md",
  "docs/UNREAL_RND_TRACK.md",
  "docs/fighters/FIGHTER_TEMPLATE.md",
];

const FIGHTERS = [
  "ember-vale",
  "rook-ironside",
  "juno-spark",
  "kaia-windrow",
  "nix-calder",
  "orion-vell",
  "vesper-nyx",
];

const FIGHTER_SPEC_FILES = {
  "ember-vale": "docs/fighters/EMBER_VALE_PRODUCTION_SPEC.md",
  "rook-ironside": "docs/fighters/ROOK_IRONSIDE_PRODUCTION_SPEC.md",
  "juno-spark": "docs/fighters/JUNO_SPARK_PRODUCTION_SPEC.md",
  "kaia-windrow": "docs/fighters/KAIA_WINDROW_PRODUCTION_SPEC.md",
  "nix-calder": "docs/fighters/NIX_CALDER_PRODUCTION_SPEC.md",
  "orion-vell": "docs/fighters/ORION_VELL_PRODUCTION_SPEC.md",
  "vesper-nyx": "docs/fighters/VESPER_NYX_PRODUCTION_SPEC.md",
};

const REQUIRED_GODOT_SCRIPTS = [
  "scripts/fighter/FighterAssetContract.gd",
  "scripts/fighter/FighterAssetLoader.gd",
  "scripts/fighter/FighterSocketMap.gd",
  "scripts/combat/MoveChoreography.gd",
  "scripts/combat/MoveChoreographyData.gd",
  "scripts/combat/MoveTimeline.gd",
  "scripts/combat/HitboxTimeline.gd",
  "scripts/combat/VfxTimeline.gd",
  "scripts/combat/CameraTimeline.gd",
  "scripts/combat/AudioTimeline.gd",
];

const REQUIRED_SCENES = [
  "scenes/Main.tscn",
  "scenes/ui/TitleScreen.tscn",
  "scenes/ui/CharacterSelect.tscn",
  "scenes/ui/StageSelect.tscn",
  "scenes/ui/VersusScreen.tscn",
  "scenes/BattleScene.tscn",
  "scenes/stages/SkylineArena.tscn",
];

const REQUIRED_PRODUCTION_DOCS = [
  "docs/production/LEAD_GAME_DESIGNER_NOTES.md",
  "docs/production/LEAD_ENGINEER_NOTES.md",
  "docs/production/LEAD_PRODUCER_NOTES.md",
  "docs/production/PRODUCT_MILESTONES.md",
  "docs/production/DEFINITION_OF_DONE.md",
];

for (const rel of REQUIRED_DOCS) {
  if (!fs.existsSync(path.join(repoRoot, rel))) errors.push(`missing doc ${rel}`);
}

for (const rel of REQUIRED_PRODUCTION_DOCS) {
  if (!fs.existsSync(path.join(repoRoot, rel))) errors.push(`missing production doc ${rel}`);
}

for (const fighter of FIGHTERS) {
  const spec = FIGHTER_SPEC_FILES[fighter];
  if (!fs.existsSync(path.join(repoRoot, spec))) {
    errors.push(`missing fighter spec for ${fighter}`);
  }
}

for (const rel of REQUIRED_GODOT_SCRIPTS) {
  if (!fs.existsSync(path.join(godotRoot, rel))) errors.push(`missing Godot script ${rel}`);
}

for (const rel of REQUIRED_SCENES) {
  if (!fs.existsSync(path.join(godotRoot, rel))) errors.push(`missing Godot scene ${rel}`);
}

const contractSrc = fs.readFileSync(
  path.join(godotRoot, "scripts/fighter/FighterAssetContract.gd"),
  "utf8",
);
if (!contractSrc.includes("DEBUG FALLBACK")) {
  errors.push("FighterAssetContract missing DEBUG FALLBACK label");
}
for (const socket of ["aura_core", "right_hand", "hit_spark_center"]) {
  if (!contractSrc.includes(`"${socket}"`)) {
    errors.push(`FighterAssetContract missing socket ${socket}`);
  }
}

const choreographySrc = fs.readFileSync(
  path.join(godotRoot, "scripts/combat/MoveChoreography.gd"),
  "utf8",
);
if (!choreographySrc.includes("get_choreography")) {
  errors.push("MoveChoreography missing get_choreography");
}
if (!choreographySrc.includes("hitbox_socket")) {
  errors.push("MoveChoreography missing hitbox_socket fields");
}

const mainSrc = fs.readFileSync(path.join(godotRoot, "scripts/Main.gd"), "utf8");
if (!mainSrc.includes("Route.TITLE") || !mainSrc.includes("VERSUS")) {
  errors.push("Main.gd missing title → versus flow");
}

if (!fs.existsSync(path.join(repoRoot, "assets/README.md"))) {
  errors.push("missing assets/README.md");
}
if (!fs.existsSync(path.join(repoRoot, "game/unreal/README.md"))) {
  errors.push("missing Unreal R&D README");
}
if (!fs.existsSync(path.join(repoRoot, "game/unreal/AnimeAggressorsArena/AnimeAggressorsArena.uproject"))) {
  errors.push("missing Unreal uproject scaffold");
}

const manifestPath = path.join(repoRoot, "apps/web/public/godot/build-manifest.json");
if (!fs.existsSync(manifestPath)) {
  errors.push("missing Godot build-manifest.json");
} else {
  const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
  if (!manifest.buildId) errors.push("build-manifest missing buildId");
}

const rescueJs = path.join(repoRoot, "apps/web/public/godot/rescue-runtime.js");
if (fs.existsSync(rescueJs)) {
  const rescue = fs.readFileSync(rescueJs, "utf8");
  if (!/NOT FINAL|RESCUE RUNTIME/i.test(rescue)) {
    errors.push("rescue-runtime.js must label itself as fallback, not final");
  }
}

const readme = fs.readFileSync(path.join(repoRoot, "README.md"), "utf8");
if (!readme.includes("Production Rescue Strategy")) {
  errors.push("README missing Production Rescue Strategy section");
}

if (errors.length > 0) {
  console.error("Godot product quality validation failed:");
  for (const err of errors) console.error(`  - ${err}`);
  process.exit(1);
}

console.log("Godot product quality OK");
console.log(`  fighter specs: ${FIGHTERS.length}`);
console.log(`  production docs: ${REQUIRED_PRODUCTION_DOCS.length}`);
