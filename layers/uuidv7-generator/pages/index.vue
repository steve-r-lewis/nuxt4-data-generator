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
  <div class="min-h-screen bg-slate-950 text-slate-100 p-4 md:p-12 flex justify-center">
    <div class="w-full max-w-4xl space-y-8">

      <div class="text-center space-y-2">
        <h1 class="text-4xl font-bold tracking-tight text-transparent bg-clip-text bg-gradient-to-r from-indigo-400 to-cyan-400">
          UUID v7 Generator
        </h1>
        <p class="text-slate-400">Generate time-ordered unique identifiers suitable for database keys.</p>
      </div>

      <UiCard>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <UiInput
            v-model.number="count"
            type="number"
            label="Quantity"
            min="1"
            max="1000"
          />
          <UiInput
            v-model="startDate"
            type="datetime-local"
            label="Start Date (Oldest)"
          />
          <UiInput
            v-model="endDate"
            type="datetime-local"
            label="End Date (Newest)"
          />
        </div>

        <div class="mt-8 flex justify-end">
          <UiButton @click="generate">
            <Icon name="lucide:zap" class="w-4 h-4" />
            <span>Generate UUIDs</span>
          </UiButton>
        </div>
      </UiCard>

      <transition
        enter-active-class="transition duration-200 ease-out"
        enter-from-class="opacity-0 translate-y-4"
        enter-to-class="opacity-100 translate-y-0"
      >
        <UiCard v-if="results.length > 0" class="relative group">
          <div class="flex justify-between items-center mb-4">
            <h2 class="text-lg font-semibold text-slate-200">Generated Output</h2>
            <button
              @click="copyToClipboard"
              class="text-xs text-indigo-400 hover:text-indigo-300 flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity"
            >
              <Icon name="lucide:copy" /> Copy All
            </button>
          </div>

          <div class="bg-black/40 rounded-lg border border-white/5 p-4 max-h-96 overflow-y-auto font-mono text-sm text-indigo-200/80">
            <div v-for="uuid in results" :key="uuid" class="py-0.5 border-b border-white/5 last:border-0">
              {{ uuid }}
            </div>
          </div>
        </UiCard>
      </transition>

    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { generateUuidRange } from '../utils/uuidv7'

// State
const count = ref(10)
const startDate = ref('')
const endDate = ref('')
const results = ref<string[]>([])

// Actions
function generate() {
  if (!startDate.value || !endDate.value) {
    alert('Please select both a start and end date.')
    return
  }

  results.value = generateUuidRange(
    count.value,
    new Date(startDate.value),
    new Date(endDate.value)
  )
}

function copyToClipboard() {
  navigator.clipboard.writeText(results.value.join('\n'))
  // Optional: Add a toast notification here in the future
}
</script>

<style scoped>
/* TODO: Add component-specific styles for LayoutDevelopment if utility classes are insufficient. */
</style>



