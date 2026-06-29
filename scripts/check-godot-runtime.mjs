import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execSync } from "node:child_process";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const godotProject = path.join(repoRoot, "game/godot/project.godot");
const publicExport = path.join(repoRoot, "apps/web/public/godot/index.html");
const distExport = path.join(repoRoot, "apps/web/dist/godot/index.html");

function hasGodotCli() {
  try {
    execSync("godot --version", { stdio: "pipe" });
    return true;
  } catch {
    return false;
  }
}

if (!fs.existsSync(godotProject)) {
  console.error("Missing Godot project at game/godot/project.godot");
  process.exit(1);
}

console.log("Godot project found:", godotProject);

if (hasGodotCli()) {
  console.log("Godot CLI detected — run npm run godot:export:web to refresh the web build.");
} else {
  console.warn("Godot CLI not installed — skipping export. See docs/GODOT_EXPORT_GUIDE.md");
}

const exportHtml = fs.existsSync(publicExport)
  ? publicExport
  : fs.existsSync(distExport)
    ? distExport
    : null;

if (exportHtml) {
  console.log("Godot web artifact present:", exportHtml);
} else {
  console.warn(
    "No Godot web export at apps/web/public/godot/index.html — launcher will show export instructions.",
  );
}

console.log("godot:check complete");
