import { defineConfig } from 'vite';

// IMPORTANT: Set to your repo name for GitHub Pages
export default defineConfig({
  base: '/anime-aggressors/',
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    sourcemap: false, // Disable sourcemaps for faster builds
    rollupOptions: {
      output: {
        manualChunks: {
          // Split game code into separate chunks for lazy loading
          'minigames': ['./src/minigames/bootstrap.ts'],
          'gamepad': ['./src/input/gamepad.ts']
        }
      }
    }
  },
  server: {
    port: 3000,
    host: true
  },
  preview: {
    port: 4173,
    host: true
  }
});