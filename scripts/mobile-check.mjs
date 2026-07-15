#!/usr/bin/env node
/**
 * Mobile playtest readiness checks (docs, export presets, touch controls).
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const godotRoot = path.join(root, "game-godot");

let exitCode = 0;
const fail = (m) => { console.error(`FAIL: ${m}`); exitCode = 1; };
const ok = (m) => console.log(`OK: ${m}`);

const REQUIRED_DOCS = [
  "docs/playtest/ITCH_IO_MOBILE_UPLOAD.md",
  "docs/playtest/ANDROID_APK_TESTING.md",
  "docs/playtest/IOS_TESTFLIGHT_TESTING.md",
  "docs/playtest/MOBILE_PLAYTEST_CHECKLIST.md",
];

const REQUIRED_SCRIPTS = [
  "game-godot/scripts/input/touch_input_manager.gd",
  "game-godot/scripts/input/touch_controls_overlay.gd",
  "game-godot/scenes/ui/TouchControlsOverlay.tscn",
  "game-godot/scenes/menus/MobilePlaytestScene.tscn",
  "game-godot/scripts/menus/mobile_playtest_scene.gd",
  "game-godot/export_presets.cfg",
];

for (const rel of REQUIRED_DOCS) {
  if (!fs.existsSync(path.join(root, rel))) fail(`missing doc ${rel}`);
}
ok("mobile playtest docs");

for (const rel of REQUIRED_SCRIPTS) {
  if (!fs.existsSync(path.join(root, rel))) fail(`missing ${rel}`);
}
ok("touch controls + mobile menu + export presets");

const project = fs.readFileSync(path.join(godotRoot, "project.godot"), "utf8");
if (!/gl_compatibility/.test(project)) fail("project.godot must use gl_compatibility renderer for web/mobile");
if (!/GL Compatibility/.test(project)) fail("project feature tag must match the GL Compatibility renderer");
if (!/window\/handheld\/orientation=0/.test(project)) fail("mobile build must explicitly use landscape orientation");
if (!project.includes("TouchInputManager")) fail("TouchInputManager autoload missing from project.godot");
ok("renderer + touch autoload");

const presets = fs.readFileSync(path.join(godotRoot, "export_presets.cfg"), "utf8");
if (!/name="Web"/.test(presets)) fail("missing Web export preset");
if (!/name="Android"/.test(presets)) fail("missing Android export preset");
if (!/variant\/thread_support=false/.test(presets)) fail("Web preset must use single-threaded export");
if (!/com\.gunnchos\.animeaggressors/.test(presets)) fail("Android package name missing");
if (!/builds\/android\/anime-aggressors-debug\.apk/.test(presets)) fail("Android export path missing");
if (!/package\/show_as_launcher_app=true/.test(presets)) fail("Android app must appear in launcher");
if (/gradle_build\/use_gradle_build=true/.test(presets)) {
  if (!/gradle_build\/min_sdk="24"/.test(presets)) fail("Gradle Android min SDK must be explicit");
  if (!/gradle_build\/target_sdk="(34|35)"/.test(presets)) fail("Gradle Android target SDK must be explicit");
}
ok("Web + Android export presets");

const exportWeb = fs.readFileSync(path.join(root, "scripts/export-godot-web.mjs"), "utf8");
if (!exportWeb.includes("game-godot")) fail("export-godot-web.mjs must export game-godot/");
ok("web exporter targets game-godot");

const pkg = JSON.parse(fs.readFileSync(path.join(root, "package.json"), "utf8"));
if (!pkg.scripts?.["package:itch"]) fail("package.json missing package:itch script");
if (!pkg.scripts?.["mobile:check"]) fail("package.json missing mobile:check script");
ok("npm scripts");

const settings = fs.readFileSync(path.join(godotRoot, "scripts/menus/settings_scene.gd"), "utf8");
if (!settings.includes("cycle_touch_mode")) fail("settings scene missing touch mode toggle");
ok("settings touch toggle");

const router = fs.readFileSync(path.join(godotRoot, "scripts/core/SceneRouter.gd"), "utf8");
if (!router.includes("mobile_playtest")) fail("SceneRouter missing mobile_playtest route");
ok("mobile playtest route");

if (exitCode) process.exit(exitCode);
console.log("mobile:check — all checks passed");
