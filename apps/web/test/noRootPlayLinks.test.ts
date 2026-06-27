import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

const FORBIDDEN = [
  'href="/play"',
  "href='/play'",
  'location.href = "/play"',
  "location.href = '/play'",
  'location.assign("/play")',
  "location.assign('/play')",
  'window.location.href = "/play"',
  "window.location.href = '/play'",
] as const;

function collectSourceFiles(dir: string): string[] {
  const out: string[] = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === "node_modules" || entry.name === "dist") continue;
      out.push(...collectSourceFiles(full));
    } else if (/\.(ts|tsx|html|css|js|mjs)$/.test(entry.name)) {
      out.push(full);
    }
  }
  return out;
}

describe("no root /play links in web app sources", () => {
  const files = [
    path.join(webRoot, "index.html"),
    ...collectSourceFiles(path.join(webRoot, "src")),
  ];

  for (const pattern of FORBIDDEN) {
    it(`does not contain ${pattern}`, () => {
      for (const file of files) {
        const text = fs.readFileSync(file, "utf8");
        assert.equal(
          text.includes(pattern),
          false,
          `${path.relative(webRoot, file)} contains forbidden pattern: ${pattern}`,
        );
      }
    });
  }
});
