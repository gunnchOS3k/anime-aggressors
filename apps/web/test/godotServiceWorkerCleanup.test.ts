import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

describe("godot service worker cleanup", () => {
  it("exposes unregisterStaleServiceWorkers helper", () => {
    const swSrc = fs.readFileSync(path.join(webRoot, "src/godot/godotServiceWorker.ts"), "utf8");
    assert.match(swSrc, /export async function unregisterStaleServiceWorkers/);
    assert.match(swSrc, /getRegistrations/);
    assert.match(swSrc, /unregister/);
  });

  it("Godot route calls service worker cleanup on load", () => {
    const screenSrc = fs.readFileSync(
      path.join(webRoot, "src/screens/GodotRuntimeScreen.ts"),
      "utf8",
    );
    assert.match(screenSrc, /unregisterStaleServiceWorkers/);
  });
});
