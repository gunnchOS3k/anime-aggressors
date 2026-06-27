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
for (const label of ["Create Fighter", "Start Match", "Custom Game", "Controls", "Flagline Clash", "Impact Dummy Derby"]) {
  if (!markers.includes(label)) {
    console.error(`Missing expected marker in artifact: ${label}`);
    process.exit(1);
  }
}

if (markers.includes("Load Mini-Games")) {
  console.error("Stale marker found in artifact: Load Mini-Games");
  process.exit(1);
}

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

let commitSha = process.env.GITHUB_SHA ?? "local";
if (commitSha === "local") {
  try {
    commitSha = execSync("git rev-parse HEAD", { cwd: root, encoding: "utf8" }).trim();
  } catch {
    commitSha = "unknown";
  }
}

let branch = process.env.GITHUB_REF_NAME ?? "main";
const builtAt = new Date().toISOString();
const modes =
  "Start Match,Create Fighter,Custom Game,Controls,Flagline Clash,Training Mode,Impact Dummy Derby,Controller Test,Rollback Debug,Edge-IO Lab,Prototype Lab,Feedback,Match Setup";
const deployInfo = [
  `commit_sha=${commitSha}`,
  `branch=${branch}`,
  `built_at=${builtAt}`,
  `artifact=apps/web/dist`,
  `modes=${modes}`,
].join("\n");

fs.writeFileSync(path.join(distDir, "deploy-info.txt"), `${deployInfo}\n`);
console.log("Pages artifact finalized:", distDir);
console.log(deployInfo);
