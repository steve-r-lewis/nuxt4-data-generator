/**
* ================================================================================
*
* @project:    uuidv7-generator
* @file:       ~/layers/ui-library/components/UiInput.vue
* @version:    1.0.0
* @createDate: 2025 Dec 14
* @createTime: 01:09
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
* V1.0.0, 20251214-01:09
* Initial creation and release of UiInput.vue
*
* ================================================================================
*/

<template>
  <div class="flex flex-col gap-2">
    <label v-if="label" :for="id" class="text-sm font-medium text-gray-400">
      {{ label }}
    </label>
    <input
      :id="id"
      :type="type"
      :value="modelValue"
      @input="$emit('update:modelValue', ($event.target as HTMLInputElement).value)"
      class="w-full rounded-lg bg-black/20 border border-white/10 px-4 py-3 text-white placeholder-gray-500 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 outline-none transition-all"
      v-bind="$attrs"
    />
  </div>
</template>

<script setup lang="ts">
/**
 * ================================================================================
 * @project:    @monorepo/ui-library
 * @file:       ~/components/UiInput.vue
 * @description: Reusable input component with label support.
 * ================================================================================
 */
const props = defineProps<{
  modelValue: string | number
  label?: string
  type?: string
  id?: string
}>()

defineEmits(['update:modelValue'])
</script>

<style scoped>
/* TODO: Add component-specific styles for LayoutDevelopment if utility classes are insufficient. */
</style>
