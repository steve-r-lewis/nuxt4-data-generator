/**
 * ================================================================================
 *
 * @project:    @monorepo/data-generator
 * @file:       ~/layers/data-generator/composables/useMockGenerator.ts
 * @version:    V1.0.0
 * @createDate: 2025 Dec 16
 * @createTime: 21:31
 * @author:     Steve R Lewis
 *
 * ================================================================================
 *
 * @description:
 * Composable to handle the business logic of generation
 *
 * ================================================================================
 *
 * @notes: Revision History
 *
 * V1.0.0, 20251216-21:31
 * Initial creation and release of useMockGenerator.ts
 *
 * ================================================================================
 */

export const useMockGenerator = () => {
  const store = useDataStore()

  const generateUserAccount = async (params: { role: string }) => {
    // TODO: Connect to AI API here later
    const mock = {
      id: crypto.randomUUID(),
      username: `user_${Math.floor(Math.random() * 1000)}`,
      role: params.role,
      token: "ey..." + crypto.randomUUID()
    }
    store.setGeneratedData(mock)
  }

  const generateAppConfig = async (params: { env: string }) => {
    const mock = {
      appName: "DataForge App",
      env: params.env,
      version: "1.0.0"
    }
    store.setGeneratedData(mock)
  }

  return { generateUserAccount, generateAppConfig }
}

