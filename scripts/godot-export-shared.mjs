import fs from "node:fs";
import path from "node:path";
import { execSync } from "node:child_process";

export const PLACEHOLDER_MARKERS = [
  "AA_GODOT_PLACEHOLDER",
  "No export artifact is checked in yet",
  "Placeholder export page",
  "Godot CLI not installed",
  "This folder hosts the",
];

export const DEFAULT_GODOT_VERSION = process.env.GODOT_VERSION ?? "4.3";

export function resolveGodotBin() {
  if (process.env.GODOT_BIN) {
    return process.env.GODOT_BIN;
  }
  for (const candidate of ["godot", "Godot"]) {
    try {
      execSync(`command -v ${candidate}`, { stdio: "pipe" });
      return candidate;
    } catch {
      /* try next */
    }
  }
  const macApp = "/Applications/Godot.app/Contents/MacOS/Godot";
  if (fs.existsSync(macApp)) {
    return macApp;
  }
  return null;
}

export function isPlaceholderHtml(html) {
  if (!html || html.trim().length === 0) {
    return true;
  }
  for (const marker of PLACEHOLDER_MARKERS) {
    if (html.includes(marker)) {
      return true;
    }
  }
  // Real Godot web exports include the engine loader.
  if (!html.includes("Engine") && !html.includes("engine") && !html.includes(".wasm")) {
    if (!html.includes("createEngine") && !html.includes("Godot")) {
      return true;
    }
  }
  return false;
}

export function listGodotExportFiles(dir) {
  if (!fs.existsSync(dir)) {
    return { html: [], js: [], wasm: [], pck: [], all: [] };
  }
  const all = fs.readdirSync(dir);
  return {
    html: all.filter((f) => f.endsWith(".html")),
    js: all.filter((f) => f.endsWith(".js")),
    wasm: all.filter((f) => f.endsWith(".wasm")),
    pck: all.filter((f) => f.endsWith(".pck")),
    all,
  };
}

export function validateGodotExportDir(dir, { label = dir } = {}) {
  const errors = [];
  const indexHtml = path.join(dir, "index.html");

  if (!fs.existsSync(indexHtml)) {
    errors.push(`${label}: missing index.html`);
    return { ok: false, errors, files: listGodotExportFiles(dir) };
  }

  const html = fs.readFileSync(indexHtml, "utf8");
  if (isPlaceholderHtml(html)) {
    errors.push(`${label}: index.html is placeholder-only (not a Godot Web export)`);
  }

  const files = listGodotExportFiles(dir);
  if (files.wasm.length === 0) {
    errors.push(`${label}: missing .wasm file`);
  }
  if (files.pck.length === 0) {
    errors.push(`${label}: missing .pck file`);
  }
  if (files.js.length === 0) {
    errors.push(`${label}: missing .js loader file`);
  }

  return { ok: errors.length === 0, errors, files };
}

export function godotExportTemplatesDir(version = DEFAULT_GODOT_VERSION) {
  const home = process.env.HOME ?? process.env.USERPROFILE ?? "";
  if (process.platform === "darwin") {
    return path.join(
      home,
      "Library",
      "Application Support",
      "Godot",
      "export_templates",
      `${version}.stable`,
    );
  }
  return path.join(home, ".local", "share", "godot", "export_templates", `${version}.stable`);
}

export function templatesInstalled(version = DEFAULT_GODOT_VERSION) {
  const dir = godotExportTemplatesDir(version);
  if (!fs.existsSync(dir)) {
    return false;
  }
  const entries = fs.readdirSync(dir);
  return entries.some(
    (e) =>
      e.includes("web_nothreads") ||
      e.includes("web_release") ||
      e.includes("web_debug") ||
      e.endsWith(".wasm"),
  );
}
