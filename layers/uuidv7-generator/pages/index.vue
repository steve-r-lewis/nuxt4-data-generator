/**
* ================================================================================
*
* @project:    uuidv7-generator
* @file:       ~/app/pages/index.vue
* @version:    V1.0.0
* @createDate: 2025 Oct 16
* @createTime: 00:00
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
* V1.0.0, 20251016-00:00
* Initial creation and release of index.vue
*
* ================================================================================
*/

<template>
  <div class="min-h-screen bg-slate-950 text-slate-100 p-8">
    <div class="max-w-3xl mx-auto space-y-6">
      <h1 class="text-2xl font-semibold">UUID v7 Generator</h1>


      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div>
          <label class="block text-sm mb-1">Number of codes</label>
          <input
            type="number"
            v-model.number="count"
            min="1"
            class="w-full rounded bg-slate-900 border border-slate-700 px-3 py-2"
          />
        </div>


        <div>
          <label class="block text-sm mb-1">Start date</label>
          <input
            type="datetime-local"
            v-model="startDate"
            class="w-full rounded bg-slate-900 border border-slate-700 px-3 py-2"
          />
        </div>


        <div>
          <label class="block text-sm mb-1">End date</label>
          <input
            type="datetime-local"
            v-model="endDate"
            class="w-full rounded bg-slate-900 border border-slate-700 px-3 py-2"
          />
        </div>
      </div>


      <button
        @click="generate"
        class="rounded bg-indigo-600 hover:bg-indigo-500 px-4 py-2 font-medium"
      >
        Generate
      </button>


      <div v-if="results.length" class="space-y-2">
        <h2 class="text-lg font-medium">Results (oldest first)</h2>
        <pre class="bg-slate-900 border border-slate-800 rounded p-4 overflow-auto text-sm">
          {{ results.join('\n') }}
        </pre>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { generateUuidRange } from '../utils/uuidv7'


const count = ref(10)
const startDate = ref('')
const endDate = ref('')


const results = ref<string[]>([])


function generate() {
  if (!startDate.value || !endDate.value) return


  results.value = generateUuidRange(
    count.value,
    new Date(startDate.value),
    new Date(endDate.value)
  )
}
</script>

<style scoped>
/* TODO: Add component-specific styles for LayoutDevelopment if utility classes are insufficient. */
</style>



