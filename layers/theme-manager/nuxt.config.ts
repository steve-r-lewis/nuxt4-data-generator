/**
 * ================================================================================
 * @project:    @monorepo/theme-manager
 * @file:       ~/layers/theme-manager/nuxt.config.ts
 * @version:    V1.0.1
 * @createDate: 2025 Dec 13
 * @createTime: 18:18
 * @author:     Steve R Lewis
 * ================================================================================
 * @description:
 * This configuration file defines the core settings for a theme in your
 * Nuxt application. It allows you to customize colors, fonts, spacing, and
 * more. By default, it loads the theme's styles from the `theme.css` file.
 * ================================================================================
 * @notes: Revision History
 
 V1.0.1, 20251216-2137
 Updated nuxt.config.ts with CSS and Vite configurations.
* V1.0.0, 20251213-18:18
 * Initial creation and release of nuxt.config.ts
 * ================================================================================
 */

import tsconfigPaths from 'vite-tsconfig-paths';
import { createResolver } from '@nuxt/kit';
const { resolve } = createResolver(import.meta.url);

export default defineNuxtConfig({
  compatibilityDate: '2025-10-08',
  devtools: { enabled: true },

  css: [
    resolve('./assets/css/main.css')
  ],

  vite: {
    plugins: [
      tsconfigPaths()
    ],

    // Optional but recommended configs
    css: {
      devSourcemap: true
    },

    build: {
      cssMinify: true
    }
  },
});

