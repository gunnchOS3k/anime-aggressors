import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execSync } from "node:child_process";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const distDir = path.join(root, "apps/web/dist");
const indexHtml = path.join(distDir, "index.html");
const fallbackHtml = path.join(distDir, "404.html");

if (!fs.existsSync(indexHtml)) {
  console.error("Missing apps/web/dist/index.html — run npm run build:web first");
  process.exit(1);
}

fs.copyFileSync(indexHtml, fallbackHtml);

const html = fs.readFileSync(indexHtml, "utf8");
if (!html.includes("/anime-aggressors/")) {
  console.error("index.html missing Vite base /anime-aggressors/");
  process.exit(1);
}

const assetFiles = fs
  .readdirSync(path.join(distDir, "assets"), { withFileTypes: true })
  .filter((e) => e.isFile())
  .map((e) => fs.readFileSync(path.join(distDir, "assets", e.name), "utf8"))
  .join("\n");

const markers = `${html}\n${assetFiles}`;
for (const label of ["Play Match", "Impact Dummy Derby"]) {
  if (!markers.includes(label)) {
    console.error(`Missing expected marker in artifact: ${label}`);
    process.exit(1);
  }
}

if (markers.includes("Load Mini-Games")) {
  console.error("Stale marker found in artifact: Load Mini-Games");
  process.exit(1);
}

let commitSha = process.env.GITHUB_SHA ?? "local";
if (commitSha === "local") {
  try {
    commitSha = execSync("git rev-parse HEAD", { cwd: root, encoding: "utf8" }).trim();
  } catch {
    commitSha = "unknown";
  }
}

const deployedAt = new Date().toISOString();
const deployInfo = [
  `commit_sha=${commitSha}`,
  `deployed_at=${deployedAt}`,
  `app_version=Anime Aggressors Pages Build`,
  `artifact=apps/web/dist`,
].join("\n");

fs.writeFileSync(path.join(distDir, "deploy-info.txt"), `${deployInfo}\n`);
console.log("Pages artifact finalized:", distDir);
console.log(deployInfo);
