/**
 * ================================================================================
 *
 * @project:    @monorepo/data-generator
 * @file:       ~/layers/data-generator/stores/dataStore.ts
 * @version:    V1.0.0
 * @createDate: 2025 Dec 16
 * @createTime: 21:30
 * @author:     Steve R Lewis
 *
 * ================================================================================
 *
 * @description:
 * TODO: Create description here
 *
 * ================================================================================
 *
 * @notes: Revision History
 *
 * V1.0.0, 20251216-21:30
 * Initial creation and release of dataStore.ts
 *
 * ================================================================================
 */

import { defineStore } from 'pinia'

export const useDataStore = defineStore('data-generator', {
  state: () => ({
    // Active View State
    activeView: 'dashboard' as 'dashboard' | 'user-account' | 'user-profile' | 'app-config' | 'settings',

    // Configuration State
    aiConfig: {
      provider: 'openai' as 'openai' | 'gemini',
      apiKey: ''
    },

    // Data State (The generated output)
    generatedData: null as any
  }),
  actions: {
    setView(view: string) {
      this.activeView = view as any
    },
    setGeneratedData(data: any) {
      this.generatedData = data
    }
  }
})

