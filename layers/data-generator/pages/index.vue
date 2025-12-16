/**
* ================================================================================
*
* @project:    @monorepo/data-generator
* @file:       ~/layers/data-generator/pages/index.vue
* @version:    V1.0.1
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

 V1.0.1, 20251216-2137
 Added initial index.vue file with UUID generator functionality.
*
* V1.0.0, 20251016-00:00
* Initial creation and release of index.vue
*
* ================================================================================
*/

<template>
  <div class="min-h-screen p-4 md:p-12 flex justify-center items-start pt-20">
    <div class="w-full max-w-2xl space-y-8">

      <div class="text-center space-y-3">
        <h1 class="text-4xl md:text-5xl font-bold tracking-tight text-[var(--color-primary)]">
          UUID v7 Generator
        </h1>
        <p class="text-[var(--color-on-surface-variant)] text-lg">
          Time-ordered unique identifiers for modern databases.
        </p>
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
            label="Start Date"
          />
          <UiInput
            v-model="endDate"
            type="datetime-local"
            label="End Date"
          />
        </div>

        <div class="mt-8 flex justify-end">
          <UiButton @click="generate">
            <Icon name="lucide:zap" class="w-4 h-4" />
            <span>Generate</span>
          </UiButton>
        </div>
      </UiCard>

      <transition
        enter-active-class="transition duration-300 ease-out"
        enter-from-class="opacity-0 translate-y-4"
        enter-to-class="opacity-100 translate-y-0"
      >
        <UiCard v-if="results.length > 0" class="relative group">
          <div class="flex justify-between items-center mb-4">
            <h2 class="text-lg font-semibold text-[var(--color-on-surface)]">Generated Output</h2>
            <button
              @click="copyToClipboard"
              class="text-xs font-medium text-[var(--color-primary)] hover:underline flex items-center gap-1 opacity-100 transition-opacity"
            >
              <Icon name="lucide:copy" /> Copy All
            </button>
          </div>

          <div class="bg-[var(--color-surface-lvl-2)] rounded-xl border border-[var(--color-outline)] p-4 max-h-96 overflow-y-auto font-mono text-sm text-[var(--color-on-surface)]">
            <div v-for="uuid in results" :key="uuid" class="py-1 border-b border-[var(--color-outline)] last:border-0">
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
}
</script>

<style scoped>
/* TODO: Add component-specific styles for LayoutDevelopment if utility classes are insufficient. */
</style>





