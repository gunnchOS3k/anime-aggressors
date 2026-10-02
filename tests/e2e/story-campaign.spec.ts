import { test, expect } from "@playwright/test";

test("E2E C: story Kaia route enters real node graph", async ({ page }) => {
  await page.goto("/#/story");
  await expect(page.getByTestId("story-campaign")).toBeVisible();
  await expect(page.getByTestId("story-qa-drawer")).toHaveCount(0);
  await page.getByTestId("start-route-kaia-windrow").click();
  await expect(page.getByTestId("story-active-node")).toBeVisible();
  const kind = await page.getByTestId("story-active-node").getAttribute("data-node-kind");
  expect(kind).toBe("intro");
  await page.getByTestId("story-advance").click();
  await expect(page.getByTestId("story-active-node")).toHaveAttribute("data-node-kind", "combat");
});
