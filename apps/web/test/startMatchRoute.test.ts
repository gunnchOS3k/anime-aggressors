import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { APP_ROUTES } from "../src/routes.ts";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

describe("start match route", () => {
  it("APP_ROUTES.matchSetupRules is the setup entry", () => {
    assert.equal(APP_ROUTES.matchSetupRules, "#/match-setup/rules");
  });

  it("index.html Start Match links to match setup rules", () => {
    const html = fs.readFileSync(path.join(webRoot, "index.html"), "utf8");
    assert.match(html, /id="btn-play-match"[^>]*href="#\/match-setup\/rules"/);
    assert.match(html, />Start Match</);
  });

  it("router maps btn-play-match to match-setup-rules", () => {
    const routerSrc = fs.readFileSync(path.join(webRoot, "src/router.ts"), "utf8");
    assert.match(routerSrc, /\["btn-play-match",\s*"match-setup-rules"\]/);
  });
});
