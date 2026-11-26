import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      "/api": {
        target:
          process.env.LOCAL_API_URL ??
          "https://anuvachai-git-425459156696.asia-south1.run.app",
        changeOrigin: true,
      },
    },
  },
  test: { environment: "jsdom", globals: true },
});
