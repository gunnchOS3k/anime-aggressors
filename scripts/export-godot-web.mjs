import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execSync } from "node:child_process";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const godotDir = path.join(repoRoot, "game/godot");
const exportPath = path.join(repoRoot, "apps/web/public/godot/index.html");

function hasGodotCli() {
  try {
    execSync("godot --version", { stdio: "pipe" });
    return true;
  } catch {
    return false;
  }
}

if (!hasGodotCli()) {
  console.warn("Godot CLI not available — web export skipped.");
  console.warn("Install Godot 4 and run: godot --headless --path game/godot --export-release Web apps/web/public/godot/index.html");
  process.exit(0);
}

fs.mkdirSync(path.dirname(exportPath), { recursive: true });

try {
  execSync(
    `godot --headless --path "${godotDir}" --export-release "Web" "${exportPath}"`,
    { stdio: "inherit", cwd: repoRoot },
  );
  console.log("Exported Godot web build to", exportPath);
} catch (error) {
  console.error("Godot export failed:", error.message);
  process.exit(1);
}
