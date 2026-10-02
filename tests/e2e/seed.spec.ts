import { test, expect } from "@playwright/test";

test("seed: home loads with brand surface", async ({ page }) => {
  await page.goto("/");
  await expect(page.locator("body")).toBeVisible();
  await expect(page.locator("body")).not.toBeEmpty();
});
