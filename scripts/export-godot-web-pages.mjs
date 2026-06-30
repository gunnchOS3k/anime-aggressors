/**
 * Compatibility wrapper — canonical exporter is export-godot-web.mjs.
 * @deprecated Use `npm run godot:export:web` (export-godot-web.mjs).
 */
import { spawnSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const script = path.join(path.dirname(fileURLToPath(import.meta.url)), "export-godot-web.mjs");
const child = spawnSync(process.execPath, [script], { stdio: "inherit" });
process.exit(child.status ?? 1);
