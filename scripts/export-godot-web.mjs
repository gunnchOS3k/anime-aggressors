import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execSync } from "node:child_process";
import {
  DEFAULT_GODOT_VERSION,
  godotExportTemplatesDir,
  resolveGodotBin,
  templatesInstalled,
  validateGodotExportDir,
} from "./godot-export-shared.mjs";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const godotDir = path.join(repoRoot, "game/godot");
const exportDir = path.join(repoRoot, "apps/web/public/godot");
const exportIndex = path.join(exportDir, "index.html");

function clearExportDir() {
  if (fs.existsSync(exportDir)) {
    for (const entry of fs.readdirSync(exportDir)) {
      fs.rmSync(path.join(exportDir, entry), { recursive: true, force: true });
    }
  } else {
    fs.mkdirSync(exportDir, { recursive: true });
  }
}

function installTemplates(godotBin, version) {
  if (templatesInstalled(version)) {
    console.log(`Godot export templates already installed for ${version}.stable`);
    return;
  }
  console.warn(
    `Export templates for ${version}.stable not found at ${godotExportTemplatesDir(version)}.`,
  );
  console.warn("Install via Godot Editor → Manage Export Templates, or run scripts/install-godot-templates.sh");
}

const godotBin = resolveGodotBin();
if (!godotBin) {
  console.error("Godot CLI was not found.");
  console.error("Install Godot 4.3+ or set GODOT_BIN=/path/to/godot");
  console.error("Then run: npm run godot:export:web");
  process.exit(1);
}

let version = DEFAULT_GODOT_VERSION;
try {
  const verOut = execSync(`"${godotBin}" --version`, { encoding: "utf8" }).trim();
  console.log("Using Godot:", verOut);
  const match = verOut.match(/^(\d+\.\d+\.\d+)/);
  if (match) {
    version = match[1];
  }
} catch {
  console.log("Using configured Godot version:", version);
}

clearExportDir();
fs.mkdirSync(exportDir, { recursive: true });
installTemplates(godotBin, version);

try {
  execSync(
    `"${godotBin}" --headless --path "${godotDir}" --export-release "Web" "${exportIndex}"`,
    { stdio: "inherit", cwd: repoRoot },
  );
} catch (error) {
  console.error("Godot export failed:", error.message ?? error);
  process.exit(1);
}

const result = validateGodotExportDir(exportDir, { label: exportDir });
if (!result.ok) {
  console.error("Export completed but output is invalid:");
  for (const err of result.errors) {
    console.error(`  - ${err}`);
  }
  process.exit(1);
}

console.log("Exported Godot Web build to", exportDir);
console.log("  files:", result.files.all.join(", "));
