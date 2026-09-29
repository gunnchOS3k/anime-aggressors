import { test, expect } from "@playwright/test";

test("E2E D/E: puppet then gray via story advance + QA essence", async ({ page }) => {
  await page.goto("/#/story?dev=1");
  await page.getByTestId("start-route-kaia-windrow").click();
  // Advance intro → combat → beat → puppet
  for (let i = 0; i < 3; i++) {
    const win = page.getByTestId("story-sim-win");
    const adv = page.getByTestId("story-advance");
    if (await win.count()) await win.click();
    else if (await adv.count()) await adv.click();
  }
  await expect(page.getByTestId("story-active-node")).toBeVisible();
  await page.locator("#story-essence").selectOption("6");
  await expect(page.getByTestId("story-status")).toContainText("6");
});
