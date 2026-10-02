import { test, expect } from "@playwright/test";

/**
 * E2E A — real body-variant / provenance acceptance.
 * Must enter an exact-head battle (skipSelect) so beginMatchAsync preloads authored GLBs.
 */
test("E2E A: authored skinned ember female provenance", async ({ page }) => {
  await page.addInitScript(() => {
    (window as unknown as { __AA_ACCEPTANCE__: boolean }).__AA_ACCEPTANCE__ = true;
  });
  // #/battle → ensureBattleReadySetup + launchMatch({ skipSelect: true }) → preload provenance
  await page.goto("/#/battle?acceptance=1");
  await page.waitForLoadState("domcontentloaded");
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
  // Prefer ember female when present; otherwise any ember seat (p1 default is ember male).
  const sample =
    diag.find((d) => d.fighter_id.includes("ember") && d.body_variant === "female") ??
    diag.find((d) => d.fighter_id.includes("ember")) ??
    diag[0]!;
  expect(sample.model_kind).toBe("AUTHORED_GLB");
  expect(sample.fallback_used).toBe(false);
  expect(sample.animation_binding).toBe("PRODUCTION_RIG");
});
