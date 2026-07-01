#!/usr/bin/env node
/**
 * Unity combat proof spike validation — structure and docs only (no Unity CLI required).
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const unityRoot = path.join(root, "unity/AnimeAggressorsUnity");
const aaRoot = path.join(unityRoot, "Assets/AnimeAggressors");

const REQUIRED_SCRIPTS = [
  "Scripts/FighterController.cs",
  "Scripts/FighterStateMachine.cs",
  "Scripts/FighterState.cs",
  "Scripts/MoveDefinition.cs",
  "Scripts/MoveRunner.cs",
  "Scripts/Hitbox.cs",
  "Scripts/Hurtbox.cs",
  "Scripts/HitResolver.cs",
  "Scripts/ShieldController.cs",
  "Scripts/GrabController.cs",
  "Scripts/AuraController.cs",
  "Scripts/DebugCombatHUD.cs",
  "Scripts/TrainingDummy.cs",
  "Scripts/CombatProofBootstrap.cs",
];

const REQUIRED_DOCS = [
  "docs/ENGINE_RESET_DECISION.md",
  "docs/GODOT_PROTOTYPE_RETROSPECTIVE.md",
  "docs/UNITY_SPIKE_ACCEPTANCE_CHECKLIST.md",
  "unity/AnimeAggressorsUnity/Assets/AnimeAggressors/Docs/UNITY_COMBAT_PROOF_README.md",
];

const MOVE_IDS = ["jab", "heavy", "neutral_special", "grab", "throw", "aura_burst"];

let exitCode = 0;
const fail = (m) => { console.error(`FAIL: ${m}`); exitCode = 1; };
const ok = (m) => console.log(`OK: ${m}`);

if (!fs.existsSync(unityRoot)) fail("unity/AnimeAggressorsUnity missing");
else ok("Unity project folder");

const scenePath = path.join(aaRoot, "Scenes/CombatProof.unity");
if (!fs.existsSync(scenePath)) fail("CombatProof.unity missing");
else ok("CombatProof scene");

for (const s of REQUIRED_SCRIPTS) {
  const p = path.join(aaRoot, s);
  if (!fs.existsSync(p)) fail(`missing script ${s}`);
}
ok("required C# scripts");

for (const d of REQUIRED_DOCS) {
  const p = path.join(root, d);
  if (!fs.existsSync(p)) fail(`missing doc ${d}`);
}
ok("required docs");

const movesPath = path.join(aaRoot, "Data/default_moves.json");
if (!fs.existsSync(movesPath)) fail("default_moves.json missing");
else {
  const data = JSON.parse(fs.readFileSync(movesPath, "utf8"));
  for (const id of MOVE_IDS) {
    if (!data.moves?.some((m) => m.move_id === id)) fail(`move data missing ${id}`);
  }
}
ok("move data");

const engineReset = fs.readFileSync(path.join(root, "docs/ENGINE_RESET_DECISION.md"), "utf8");
if (!/frozen/i.test(engineReset) || !/not delete/i.test(engineReset)) {
  fail("ENGINE_RESET_DECISION must state Godot is frozen, not deleted");
}
if (/full migration complete/i.test(engineReset)) {
  fail("ENGINE_RESET_DECISION must not claim full migration complete");
}
ok("Godot frozen policy");

const checklist = fs.readFileSync(path.join(root, "docs/UNITY_SPIKE_ACCEPTANCE_CHECKLIST.md"), "utf8");
if (!/jab hits dummy in range/i.test(checklist)) fail("acceptance checklist incomplete");
ok("proof checklist");

if (fs.existsSync(path.join(root, "game-godot/project.godot"))) ok("Godot prototype preserved");
else fail("game-godot must not be deleted");

for (const doc of ["docs/ENGINE_RESET_DECISION.md", "docs/UNITY_SPIKE_ACCEPTANCE_CHECKLIST.md"]) {
  if (/unity is final|migration complete|production runtime is unity/i.test(fs.readFileSync(path.join(root, doc), "utf8"))) {
    fail(`${doc} overclaims Unity as final`);
  }
}
ok("no full migration overclaim");

if (exitCode) process.exit(exitCode);
console.log("validate-unity-spike: all checks passed");
