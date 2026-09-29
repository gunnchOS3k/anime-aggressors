import { test, expect } from "@playwright/test";

test("puppet essence gray story hash route", async ({ page }) => {
  await page.goto("/#/story");
  await page.waitForTimeout(300);
  await expect(page.locator("body")).toBeVisible();
});
