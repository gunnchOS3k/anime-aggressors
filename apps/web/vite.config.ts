import { defineConfig } from "vite";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  base: "/anime-aggressors/",
  resolve: {
    alias: {
      "@anime-aggressors/game-core": path.resolve(root, "../../packages/game-core/src/index.ts"),
      "@anime-aggressors/rollback": path.resolve(root, "../../packages/rollback/src/index.ts"),
      "@anime-aggressors/edgeio": path.resolve(root, "../../packages/edgeio/src/index.ts"),
    },
  },
  build: {
    outDir: "dist",
    assetsDir: "assets",
    sourcemap: false,
    rollupOptions: {
      output: {
        manualChunks: {
          minigames: ["./src/minigames/bootstrap.ts"],
          gamepad: ["./src/input/gamepad.ts"],
        },
      },
    },
  },
  server: {
    port: 3000,
    host: true,
  },
  preview: {
    port: 4173,
    host: true,
  },
});
