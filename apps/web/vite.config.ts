import { defineConfig } from "vite";
import path from "node:path";
import fs from "node:fs";
import { fileURLToPath } from "node:url";

const root = path.dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  root,
  base: "/anime-aggressors/",
  resolve: {
    alias: {
      "@anime-aggressors/game-core": path.resolve(root, "../../packages/game-core/src/index.ts"),
      "@anime-aggressors/rollback": path.resolve(root, "../../packages/rollback/src/index.ts"),
      "@anime-aggressors/edgeio": path.resolve(root, "../../packages/edgeio/src/index.ts"),
      "@anime-aggressors/netplay": path.resolve(root, "../../packages/netplay/src/index.ts"),
    },
  },
  build: {
    outDir: path.resolve(root, "dist"),
    emptyOutDir: true,
    assetsDir: "assets",
    sourcemap: false,
    rollupOptions: {
      output: {
        manualChunks(id) {
          const normalized = id.replaceAll("\\", "/");
          if (normalized.includes("/src/minigames/")) return "minigames";
          if (normalized.endsWith("/src/input/gamepad.ts")) return "gamepad";
          return undefined;
        },
      },
    },
  },
  plugins: [
    {
      name: "copy-404-for-github-pages",
      closeBundle() {
        const distDir = path.resolve(root, "dist");
        const indexHtml = path.join(distDir, "index.html");
        const fallback = path.join(distDir, "404.html");
        if (fs.existsSync(indexHtml)) {
          fs.copyFileSync(indexHtml, fallback);
        }
      },
    },
  ],
  server: {
    port: 3000,
    host: true,
  },
  preview: {
    port: 4173,
    host: true,
  },
});
