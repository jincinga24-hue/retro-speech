import { defineConfig } from "vite";
import { resolve } from "path";

export default defineConfig({
  resolve: {
    alias: {
      "@simulation": resolve(__dirname, "src/simulation"),
      "@rendering": resolve(__dirname, "src/rendering"),
      "@ui": resolve(__dirname, "src/ui"),
      "@state": resolve(__dirname, "src/state"),
      "@utils": resolve(__dirname, "src/utils"),
    },
  },
});
