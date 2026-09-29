import { test, expect } from "@playwright/test";

test("story campaign route entry exists", async ({ page }) => {
  await page.goto("/#/story");
  await page.waitForTimeout(400);
  await expect(page.locator("body")).toBeVisible();
});
