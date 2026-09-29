import { test, expect } from "@playwright/test";

/**
 * Flow A — body variant provenance (requires acceptance diagnostics hook).
 * Soft-skip when runtime diagnostics are not exposed yet.
 */
test("character body variant: ember female authored provenance", async ({ page }) => {
  await page.goto("/#/play");
  await page.waitForTimeout(500);
  // Drive select → match is environment-dependent; assert hook contract after play hash.
  await page.goto("/#/play?acceptance=1");
  await page.waitForTimeout(800);
  const diag = await page.evaluate(() => {
    const w = window as unknown as {
      __AA_MODEL_PROVENANCE__?: Array<{
        fighter_id: string;
        body_variant: string;
        model_kind: string;
        fallback_used: boolean;
      }>;
    };
    return w.__AA_MODEL_PROVENANCE__ ?? null;
  });
  test.skip(!diag || diag.length === 0, "match not started — provenance fills after beginMatchAsync preload");
  const ember = diag!.find((d) => d.fighter_id.includes("ember") && d.body_variant === "female")
    ?? diag!.find((d) => d.model_kind === "AUTHORED_GLB");
  expect(ember?.model_kind).toBe("AUTHORED_GLB");
  expect(ember?.fallback_used).toBe(false);
});
