/**
 * ================================================================================
 *
 * @project:    uuidv7-generator
 * @file:       ~/nuxt.config.ts
 * @version:    V1.0.0
 * @createDate: 2025 Dec 13
 * @createTime: 17:27
 * @author:     Steve R Lewis
 *
 * ================================================================================
 *
 * @description:
 * This is the main application "Integrator" config. It is responsible for
 * assembling all the application's features by extending the primary layers
 * (@monorepo/{layerName}). It also provides global, singleton modules
 * (like @pinia/nuxt and @nuxt/icon) to be shared across all layers
 *
 * ================================================================================
 *
 * @notes: Revision History
 *
 * V1.0.0, 20251213-17:27
 * Initial creation and release of nuxt.config.ts
 *
 * ================================================================================
 */

import { defineNuxtConfig } from 'nuxt/config'
import tailwindcss from '@tailwindcss/vite'

export default defineNuxtConfig({
  compatibilityDate: '2025-10-08',
  devtools: { enabled: true },

  /**
   * ------------------------------------------------------------------------------
   * @EXTENDS:
   * ------------------------------------------------------------------------------
   */
  extends: [
    "@monorepo/ui-library",
    "@monorepo/uuidv7-generator"
  ],

  /**
   * ------------------------------------------------------------------------------
   * @NUXT-MODULES:
   * ------------------------------------------------------------------------------
   */
  modules: [
    '@pinia/nuxt',
    '@nuxt/icon',
  ],

  /**
   * ------------------------------------------------------------------------------
   * @NUXT-PLUGINS:
   * ------------------------------------------------------------------------------
   */
  plugins: [
  ],

  /**
   * ------------------------------------------------------------------------------
   * @AUTO-IMPORT-DIRECTORIES:
   * ------------------------------------------------------------------------------
   */
  imports: {
  },

  /**
   * ------------------------------------------------------------------------------
   * @OPTIONAL: alias for layer
   * ------------------------------------------------------------------------------
   */
  alias: {
  },

  /**
   * @NIXT-ICONS-CONFIGURATION:
   */
  icons: {
    /* optional defaults */
    size: '24',
    class: 'inline-block',

    serverBundle: {
      collections: [
        'uil',
        'lucide',
        'fa',
      ]
    }
  },

  /**
   * ------------------------------------------------------------------------------
   * @APP-CONFIGURATION:
   * ------------------------------------------------------------------------------
   */
  // app: {
  //   head: {
  // link: [
  //   {
  //     rel: 'preload',
  //     href: '/_nuxt/assets/css/main.css',
  //     as: 'style'
  //   },
  //   {
  //     rel: 'stylesheet',
  //     href: '/_nuxt/assets/css/main.css'
  //   }
  // ]
  //   }
  // },

  /**
   * ------------------------------------------------------------------------------
   * @OPTIONAL: alias for Layer
   * ------------------------------------------------------------------------------
   */
  alias: {
  },

  /**
   * ------------------------------------------------------------------------------
   * @VITE-PLUGINS:
   * ------------------------------------------------------------------------------
   */
  vite: {
    plugins: [
      // tsconfigPaths(), // Keep if needed for root
      tailwindcss()
    ],

    server: {
      hmr: {
        port: 11500,       // Pin to main port (avoids random ports like 24678 that fail intermittently)
        host: '127.0.0.1', // Force IPv4 (macOS/Windows often defaults to IPv6, causing mismatches)
        protocol: 'ws',    // Explicit WebSocket protocol for stability
        timeout: 30000,    // Bump from default 10s to prevent idle disconnects
        overlay: true,     // Enable error overlay for debugging HMR fails
      },
    },

    css: {
      devSourcemap: true // Debug CSS issues
    },

    build: {
      cssMinify: true // Minify CSS in production
    }
  },

  /**
   * ------------------------------------------------------------------------------
   * @NITRO-CONFIGURATION:
   * ------------------------------------------------------------------------------
   */
  nitro: {
    dev: true,  // Ensure Nitro HMR is active
  },

  /**
   * ------------------------------------------------------------------------------
   * @RUNTIME-CONFIGURATION: global defaults
   * ------------------------------------------------------------------------------
   */
  runtimeConfig: {
  },

  /**
   * ------------------------------------------------------------------------------
   * @DEVELOPMENT-CONFIGURATION:
   * ------------------------------------------------------------------------------
   */
  development: {
    runtimeConfig: {
    },
  },

  /**
   * ------------------------------------------------------------------------------
   * @PRODUCTION-CONFIGURATION:
   * ------------------------------------------------------------------------------
   */
  production: {
    runtimeConfig: {
    },
  }
});

