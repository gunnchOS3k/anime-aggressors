import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execSync } from "node:child_process";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const distDir = path.resolve(repoRoot, "apps/web/dist");
const indexHtml = path.join(distDir, "index.html");
const fallbackHtml = path.join(distDir, "404.html");
const deployInfoPath = path.join(distDir, "deploy-info.txt");

if (!fs.existsSync(indexHtml)) {
  console.error("Missing apps/web/dist/index.html.");
  console.error("Expected npm run build -w anime-aggressors-web to create apps/web/dist.");
  console.error("Current files near apps/web:");
  try {
    console.error(fs.readdirSync(path.resolve(repoRoot, "apps/web")).join("\n"));
  } catch {
    console.error("(could not read apps/web)");
  }
  process.exit(1);
}

fs.copyFileSync(indexHtml, fallbackHtml);

const html = fs.readFileSync(indexHtml, "utf8");
if (!html.includes("/anime-aggressors/")) {
  console.error("index.html missing Vite base /anime-aggressors/");
  process.exit(1);
}

const assetsDir = path.join(distDir, "assets");
const assetFiles = fs.existsSync(assetsDir)
  ? fs
      .readdirSync(assetsDir, { withFileTypes: true })
      .filter((e) => e.isFile())
      .map((e) => fs.readFileSync(path.join(assetsDir, e.name), "utf8"))
      .join("\n")
  : "";

const markers = `${html}\n${assetFiles}`;

const badPatterns = [
  "https://gunnchos3k.github.io/play",
  'href="/play',
  "location.href='/play",
  "location.href = '/play",
  'location.href = "/play',
  "window.location.href = '/play",
  'window.location.href = "/play',
];
for (const pattern of badPatterns) {
  if (markers.includes(pattern)) {
    console.error(`Forbidden root play link in artifact: ${pattern}`);
    process.exit(1);
  }
}

let sha = process.env.GITHUB_SHA ?? "unknown";
let branch = process.env.GITHUB_REF_NAME ?? "unknown";

if (sha === "unknown") {
  try {
    sha = execSync("git rev-parse HEAD", { cwd: repoRoot, encoding: "utf8" }).trim();
  } catch {
    sha = "unknown";
  }
}

if (branch === "unknown") {
  try {
    branch = execSync("git branch --show-current", { cwd: repoRoot, encoding: "utf8" }).trim() || "unknown";
  } catch {
    branch = "unknown";
  }
}

const deployInfo = [
  `commit_sha=${sha}`,
  `branch=${branch}`,
  "artifact=apps/web/dist",
  `built_at=${new Date().toISOString()}`,
  "routes=#/,#/match-setup/rules,#/match-setup/stage,#/match-setup/fighters,#/match-setup/controls,#/battle,#/play,#/impact-dummy-derby",
].join("\n");

fs.writeFileSync(deployInfoPath, `${deployInfo}\n`);

console.log("Pages artifact finalized at apps/web/dist");
console.log(fs.readdirSync(distDir).join("\n"));
console.log(deployInfo);
