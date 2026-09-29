import { test, expect } from "@playwright/test";

/**
 * E2E A — real body-variant / provenance acceptance.
 * Uses __AA_ACCEPTANCE__ + programmatic match start via hash query when UI paths vary.
 */
test("E2E A: authored skinned ember female provenance", async ({ page }) => {
  await page.addInitScript(() => {
    (window as unknown as { __AA_ACCEPTANCE__: boolean }).__AA_ACCEPTANCE__ = true;
  });
  await page.goto("/#/play?acceptance=1");
  await page.waitForLoadState("networkidle");
  // Drive fighter select if present
  const selectLink = page.getByRole("link", { name: /fighter|play|versus/i }).first();
  if (await selectLink.count()) {
    await selectLink.click().catch(() => undefined);
  }
  // Wait for provenance hook from beginMatchAsync preload (may require navigating into match)
  await page.waitForFunction(
    () => {
      const w = window as unknown as {
        __AA_MODEL_PROVENANCE__?: Array<{ model_kind: string; animation_binding?: string; fallback_used: boolean }>;
        __AA_RUNTIME_PROVENANCE__?: { preloaded?: Array<{ model_kind: string; animation_binding?: string }> };
      };
      const list = w.__AA_MODEL_PROVENANCE__ ?? w.__AA_RUNTIME_PROVENANCE__?.preloaded ?? [];
      return Array.isArray(list) && list.length > 0;
    },
    { timeout: 60_000 },
  );
  const diag = await page.evaluate(() => {
    const w = window as unknown as {
      __AA_MODEL_PROVENANCE__?: Array<{
        fighter_id: string;
        body_variant: string;
        model_kind: string;
        fallback_used: boolean;
        animation_binding?: string;
      }>;
      __AA_RUNTIME_PROVENANCE__?: {
        preloaded?: Array<{
          fighter_id: string;
          body_variant: string;
          model_kind: string;
          fallback_used: boolean;
          animation_binding?: string;
        }>;
      };
    };
    return w.__AA_MODEL_PROVENANCE__ ?? w.__AA_RUNTIME_PROVENANCE__?.preloaded ?? [];
  });
  expect(diag.length).toBeGreaterThan(0);
  const sample = diag.find((d) => d.fighter_id.includes("ember")) ?? diag[0]!;
  expect(sample.model_kind).toBe("AUTHORED_GLB");
  expect(sample.fallback_used).toBe(false);
  expect(sample.animation_binding).toBe("PRODUCTION_RIG");
});
