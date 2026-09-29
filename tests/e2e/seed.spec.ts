import { test, expect } from "@playwright/test";

/** Seed / smoke — app boots. */
test("seed: home loads", async ({ page }) => {
  await page.goto("/");
  await expect(page.locator("body")).toBeVisible();
});
