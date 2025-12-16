/**
 * ================================================================================
 *
 * @project:    nuxt4-data-generator
 * @file:       ~/vitest.config.ts
 * @version:    V1.0.1
 * @createDate: 2025 Dec 10
 * @createTime: 11:57
 * @author:     Steve R Lewis
 *
 * ================================================================================
 *
 * @description:
 * Configurations for Vitest unit testing.
 *
 * ================================================================================
 *
 * @notes: Revision History
 
 V1.0.1, 20251216-2138
 Updated project name in vitest config.
*
 * V1.0.0, 20251210-11:57
 * Initial creation and release of vitest.config.ts
 *
 * ================================================================================
 */

// vitest.config.ts
export default defineVitestConfig({
  test: {
    // Ensure we scan the root tests AND the layer tests
    include: [
      'tests/**/*.test.ts',
      'layers/**/*.test.ts'
    ],
  }
})



