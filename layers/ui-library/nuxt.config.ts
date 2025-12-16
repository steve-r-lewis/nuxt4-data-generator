/**
 * ================================================================================
 *
 * @project:    @monorepo/ui-library
 * @file:       ~/layers/ui-library/nuxt.config.ts
 * @version:    V1.0.1
 * @createDate: 2025 Dec 13
 * @createTime: 18:19
 * @author:     Steve R Lewis
 *
 * ================================================================================
 *
 * @description:
 *
 * This configuration file defines the core settings for the
 * '@monorepo/ui-library' layer, such as theme colors, font sizes, and
 * layout structures. It serves as the foundation for customizing the
 * appearance of your UI components, allowing you to fine-tune the look and
 * feel of your application's user interface.
 *
 * ================================================================================
 *
 * @notes: Revision History
 
 V1.0.1, 20251216-2138
 Fixed null reference in user loop.
*
 * V1.0.0, 20251213-18:19
 * Initial creation and release of nuxt.config.ts
 *
 * ================================================================================
 */
export default defineNuxtConfig({
  compatibilityDate: "2025-10-08",
  devtools: { enabled: true },

  extends: [
    "@monorepo/theme-manager"
  ]
})

