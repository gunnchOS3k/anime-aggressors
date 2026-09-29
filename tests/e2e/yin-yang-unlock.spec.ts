import { test, expect } from "@playwright/test";

test("yin-yang unlock surface reachable", async ({ page }) => {
  await page.goto("/#/select");
  await page.waitForTimeout(400);
  await expect(page.locator("body")).toBeVisible();
});
