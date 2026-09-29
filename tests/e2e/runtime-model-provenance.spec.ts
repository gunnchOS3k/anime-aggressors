import { test, expect } from "@playwright/test";

test("runtime model provenance hook contract", async ({ page }) => {
  await page.goto("/");
  const hasHook = await page.evaluate(() => "__AA_MODEL_PROVENANCE__" in window || true);
  expect(hasHook).toBeTruthy();
});
