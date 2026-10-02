import { defineConfig, devices } from "@playwright/test";

/**
 * V1.4 Playwright acceptance — repo-local CLI, not MCP.
 * Heavy traces/screenshots stay under .acceptance/<sha>/playwright (gitignored).
 */
export default defineConfig({
  testDir: "tests/e2e",
  timeout: 90_000,
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: [["list"], ["html", { open: "never", outputFolder: ".acceptance/playwright-report" }]],
  use: {
    baseURL: process.env.AA_BASE_URL || "http://127.0.0.1:5173",
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    video: "retain-on-failure",
  },
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],
  webServer: process.env.AA_SKIP_WEBSERVER
    ? undefined
    : {
        command: "npm run dev -w anime-aggressors-web -- --host 127.0.0.1 --port 5173",
        url: "http://127.0.0.1:5173",
        reuseExistingServer: !process.env.CI,
        timeout: 120_000,
      },
});
