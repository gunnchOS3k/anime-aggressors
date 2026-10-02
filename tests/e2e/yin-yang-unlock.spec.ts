import { test, expect } from "@playwright/test";

test("E2E F: seven gray completions unlock Yin/Yang via director APIs", async ({ page }) => {
  await page.goto("/#/story?dev=1");
  await expect(page.getByTestId("story-qa-drawer")).toBeVisible();
  for (const id of [
    "kaia-windrow",
    "ember-vale",
    "rook-ironside",
    "juno-spark",
    "nix-calder",
    "orion-vell",
    "vesper-nyx",
  ]) {
    await page.locator(`[data-complete-route="${id}"]`).click();
  }
  await expect(page.getByTestId("story-status")).toContainText("Yin:");
  await expect(page.getByTestId("story-status")).toContainText("UNLOCKED");
  await expect(page.getByTestId("story-status")).toContainText("Yang:");
});
