import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

describe("godot no hard refresh required", () => {
  const statusSrc = fs.readFileSync(
    path.join(webRoot, "src/godot/godotExportStatus.ts"),
    "utf8",
  );
  const screenSrc = fs.readFileSync(
    path.join(webRoot, "src/screens/GodotRuntimeScreen.ts"),
    "utf8",
  );

  it("fetches manifest with cache no-store", () => {
    assert.match(statusSrc, /cache:\s*"no-store"/);
  });

  it("embeds boot iframe URL with buildId query", () => {
    assert.match(statusSrc, /bootPath/);
    assert.match(statusSrc, /\?v=\$\{manifest\.buildId\}/);
  });

  it("reloads iframe when manifest buildId changes", () => {
    assert.match(screenSrc, /New build available\. Reloading runtime/);
    assert.match(screenSrc, /manifest\.buildId !== embeddedBuildId/);
  });

  it("shows build ID badge without requiring hard refresh", () => {
    assert.match(screenSrc, /Godot Build:/);
    assert.match(screenSrc, /Commit:/);
  });
});
