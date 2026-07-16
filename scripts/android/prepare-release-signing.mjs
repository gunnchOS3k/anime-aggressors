#!/usr/bin/env node
/**
 * Ephemerally patch Godot export_presets.cfg for release signing.
 * Never commits passwords. Restores empty path/password after --restore.
 */
import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "../..");

const APPS = {
  anime: {
    preset: path.join(repoRoot, "game-godot/export_presets.cfg"),
    jks: "anime-internal-release.jks",
    aliasEnv: "ANIME_KEY_ALIAS",
    passEnv: "ANIME_STORE_PASSWORD",
    keyPassEnv: "ANIME_KEY_PASSWORD",
    defaultAlias: "anime_internal",
  },
  pedestrian: {
    // Pedestrian preset lives in sibling repo; kept for CLI flexibility when invoked from monorepo wrappers.
    preset: path.join(repoRoot, "../pedestrian-pursuit/export_presets.cfg"),
    jks: "pedestrian-internal-release.jks",
    aliasEnv: "PEDESTRIAN_KEY_ALIAS",
    passEnv: "PEDESTRIAN_STORE_PASSWORD",
    keyPassEnv: "PEDESTRIAN_KEY_PASSWORD",
    defaultAlias: "pedestrian_internal",
  },
};

function fail(msg) {
  console.error(`[prepare-release-signing] ${msg}`);
  process.exit(1);
}

function patchPreset(file, keystorePath, user, password) {
  let text = fs.readFileSync(file, "utf8");
  const set = (key, value) => {
    const re = new RegExp(`^${key}=.*$`, "m");
    if (!re.test(text)) fail(`preset missing ${key}`);
    text = text.replace(re, `${key}="${value}"`);
  };
  set("keystore/release", keystorePath);
  set("keystore/release_user", user);
  set("keystore/release_password", password);
  fs.writeFileSync(file, text);
}

function restorePreset(file) {
  patchPreset(file, "", APPS.anime.defaultAlias, "");
  // Keep alias name; clear path+password
  let text = fs.readFileSync(file, "utf8");
  text = text.replace(/^keystore\/release=.*$/m, 'keystore/release=""');
  text = text.replace(/^keystore\/release_password=.*$/m, 'keystore/release_password=""');
  fs.writeFileSync(file, text);
}

const args = process.argv.slice(2);
const appFlag = args.includes("--app") ? args[args.indexOf("--app") + 1] : "anime";
const apply = args.includes("--apply");
const restore = args.includes("--restore");
if (!apply && !restore) fail("usage: --app anime --apply|--restore");

const cfg = APPS[appFlag];
if (!cfg) fail(`unknown app ${appFlag}`);

if (restore) {
  restorePreset(cfg.preset);
  console.log("Restored empty keystore path/password:", cfg.preset);
  process.exit(0);
}

const keyDir =
  process.env.GUNNCHOS_KEYSTORE_DIR ||
  path.join(os.homedir(), ".android/gunnchos-internal-keys");
const jks = path.join(keyDir, cfg.jks);
const alias = process.env[cfg.aliasEnv] || cfg.defaultAlias;
const pass = process.env[cfg.passEnv] || process.env[cfg.keyPassEnv];
if (!fs.existsSync(jks)) fail(`keystore file missing: ${jks}`);
if (!pass) fail(`${cfg.passEnv} (or ${cfg.keyPassEnv}) unset — source passwords.env`);
if (!fs.existsSync(cfg.preset)) fail(`missing preset ${cfg.preset}`);

patchPreset(cfg.preset, jks, alias, pass);
// Clean Godot .import sidecars that break Android resource merger.
const androidBuild = path.join(repoRoot, "game-godot/android/build");
if (fs.existsSync(androidBuild)) {
  const walk = (dir) => {
    for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
      const p = path.join(dir, ent.name);
      if (ent.isDirectory()) walk(p);
      else if (ent.name.endsWith(".import")) fs.unlinkSync(p);
    }
  };
  try {
    walk(path.join(androidBuild, "res"));
  } catch {
    // optional
  }
}
console.log("Applied ephemeral signing to", cfg.preset);
console.log("Keystore:", jks);
console.log("Alias:", alias);
console.log("Remember to --restore after export.");
