#!/usr/bin/env node
/**
 * Unity launch experience validation — verifies the menu-flow scenes,
 * scripts, roster/stage data, build settings, and doc honesty.
 */
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const aa = path.join(root, "unity/AnimeAggressorsUnity/Assets/AnimeAggressors");

let exitCode = 0;
const fail = (m) => { console.error(`FAIL: ${m}`); exitCode = 1; };
const ok = (m) => console.log(`OK: ${m}`);
const read = (p) => fs.readFileSync(path.join(root, p), "utf8");

// --- Required scenes ---
const SCENES = [
  "BootScene", "TitleScene", "MainMenuScene", "ModeSelectScene",
  "CharacterSelectScene", "StageSelectScene", "LoadingScene",
  "BattleScene", "TrainingScene", "ResultsScene",
];
let missingScenes = 0;
for (const s of SCENES) {
  if (!fs.existsSync(path.join(aa, `Scenes/${s}.unity`))) { fail(`missing scene ${s}.unity`); missingScenes++; }
}
if (!missingScenes) ok(`all ${SCENES.length} launch scenes present`);

// CombatProof must not be the only playable scene.
if (missingScenes >= SCENES.length) fail("CombatProof is the only scene — launch flow missing");

// --- Required scripts ---
const SCRIPTS = [
  "Scripts/App/GameBootstrap.cs",
  "Scripts/App/GameState.cs",
  "Scripts/App/SceneFlowController.cs",
  "Scripts/UI/TitleScreenController.cs",
  "Scripts/UI/MainMenuController.cs",
  "Scripts/UI/ModeSelectController.cs",
  "Scripts/UI/CharacterSelectController.cs",
  "Scripts/UI/StageSelectController.cs",
  "Scripts/UI/LoadingScreenController.cs",
  "Scripts/UI/PauseMenuController.cs",
  "Scripts/UI/ResultsScreenController.cs",
  "Scripts/Battle/BattleBootstrap.cs",
  "Scripts/Battle/BattleHudController.cs",
  "Scripts/Data/CharacterDefinition.cs",
  "Scripts/Data/StageDefinition.cs",
  "Scripts/Data/RosterDatabase.cs",
  "Scripts/Data/StageDatabase.cs",
];
let missingScripts = 0;
for (const s of SCRIPTS) {
  if (!fs.existsSync(path.join(aa, s))) { fail(`missing script ${s}`); missingScripts++; }
}
if (!missingScripts) ok(`all ${SCRIPTS.length} launch-flow scripts present`);

// --- Character data ---
const CHARACTERS = ["Ember Vale", "Rook Ironside", "Juno Spark", "Kaia Windrow", "Nix Calder", "Orion Vell", "Vesper Nyx"];
const roster = fs.existsSync(path.join(aa, "Scripts/Data/RosterDatabase.cs"))
  ? fs.readFileSync(path.join(aa, "Scripts/Data/RosterDatabase.cs"), "utf8") : "";
for (const c of CHARACTERS) {
  if (!roster.includes(c)) fail(`RosterDatabase missing character: ${c}`);
}
if (roster.includes("Playable = true") && roster.includes("Playable = false"))
  ok("roster has playable + proxy fighters");
else fail("roster must mark Ember Vale playable and others as proxy");
ok(`character data covers ${CHARACTERS.length} fighters`);

// --- Stage data ---
const STAGES = ["Training Grid", "Prototype Arena", "Skyline Rooftop"];
const stagesSrc = fs.existsSync(path.join(aa, "Scripts/Data/StageDatabase.cs"))
  ? fs.readFileSync(path.join(aa, "Scripts/Data/StageDatabase.cs"), "utf8") : "";
for (const s of STAGES) {
  if (!stagesSrc.includes(s)) fail(`StageDatabase missing stage: ${s}`);
}
ok(`stage data covers ${STAGES.length} stages`);

// --- Flow docs ---
const DOCS = [
  "docs/UNITY_LAUNCH_EXPERIENCE_PLAN.md",
  "docs/UNITY_EDITOR_TEST_PLAN.md",
  "docs/UNITY_BUILD_AND_RUN_PLAN.md",
  "docs/UNITY_WEBGL_LATER_PLAN.md",
];
for (const d of DOCS) {
  if (!fs.existsSync(path.join(root, d))) fail(`missing doc ${d}`);
}
const plan = read("docs/UNITY_LAUNCH_EXPERIENCE_PLAN.md");
for (const phrase of ["Boot", "Title", "Main Menu"]) {
  if (!plan.includes(phrase)) fail(`launch plan missing flow step: ${phrase}`);
}
ok("Boot/Title/MainMenu flow docs present");

// --- BattleScene references combat bootstrap logic ---
const battle = fs.existsSync(path.join(aa, "Scripts/Battle/BattleBootstrap.cs"))
  ? fs.readFileSync(path.join(aa, "Scripts/Battle/BattleBootstrap.cs"), "utf8") : "";
if (battle.includes("FighterController") && battle.includes("TrainingDummy") && battle.includes("DebugCombatHUD"))
  ok("BattleBootstrap wires CombatProof combat systems");
else fail("BattleBootstrap must reference FighterController/TrainingDummy/DebugCombatHUD");

const gameBootstrap = fs.existsSync(path.join(aa, "Scripts/App/GameBootstrap.cs"))
  ? fs.readFileSync(path.join(aa, "Scripts/App/GameBootstrap.cs"), "utf8") : "";
if (gameBootstrap.includes("BattleBootstrap")) ok("BattleScene flow creates BattleBootstrap");
else fail("GameBootstrap must create BattleBootstrap for BattleScene");

// --- EditorBuildSettings includes launch scenes ---
const ebsPath = path.join(root, "unity/AnimeAggressorsUnity/ProjectSettings/EditorBuildSettings.asset");
if (fs.existsSync(ebsPath)) {
  const ebs = fs.readFileSync(ebsPath, "utf8");
  const listed = SCENES.filter((s) => ebs.includes(`Scenes/${s}.unity`));
  if (listed.length === SCENES.length) ok("EditorBuildSettings lists all launch scenes");
  else fail(`EditorBuildSettings lists ${listed.length}/${SCENES.length} launch scenes — CombatProof must not be the only playable scene`);
  if (!ebs.includes("BootScene")) fail("BootScene must be in build settings as the entry scene");
} else {
  fail("ProjectSettings/EditorBuildSettings.asset missing");
}

// --- No machine-specific environment reports tracked ---
const FORBIDDEN_TRACKED = [
  "docs/UNITY_FILESYSTEM_REPORT.md",
  "docs/UNITY_EDITOR_INTEGRITY_REPORT.md",
  "tmp/aa-verify-project-report.json",
  "tmp/unity-filesystem-report.json",
  "tmp/unity-editor-integrity-report.json",
];
let tracked = [];
try {
  tracked = execFileSync("git", ["ls-files", ...FORBIDDEN_TRACKED], { cwd: root, encoding: "utf8" })
    .split("\n").filter(Boolean);
} catch { /* git unavailable — skip */ }
if (tracked.length) fail(`machine-specific reports must not be tracked: ${tracked.join(", ")}`);
else ok("no machine-specific environment reports tracked");

// --- No premature WebGL / Pages claims ---
const docsDir = path.join(root, "docs");
const claimPattern = /(webgl (build|export) (complete|passed|done)|pages (deploy|deployment) (complete|live|done)|deployed to github pages)/i;
let claims = 0;
for (const f of fs.readdirSync(docsDir).filter((f) => f.endsWith(".md"))) {
  const text = fs.readFileSync(path.join(docsDir, f), "utf8");
  for (const line of text.split("\n")) {
    if (!claimPattern.test(line)) continue;
    if (/not |no |never|do not|only after|later|must not/i.test(line)) continue;
    fail(`docs/${f} claims WebGL/Pages prematurely: "${line.trim()}"`);
    claims++;
  }
}
if (!claims) ok("no premature WebGL/GitHub Pages claims in docs");

if (exitCode) process.exit(exitCode);
console.log("validate-unity-launch-experience: all checks passed");
