/**
* ================================================================================
*
* @project:    @monorepo/ui-library
* @file:       ~/layers/ui-library/components/UiInput.vue
* @version:    V1.0.1
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

 V1.0.1, 20251216-2138
 Updated UIInput.vue file with new project and file path.
*
* V1.0.0, 20251214-01:09
* Initial creation and release of UiInput.vue
*
* ================================================================================
*/

<template>
  <div class="input-group">
    <label v-if="label" :for="id" class="input-label">
      {{ label }}
    </label>
    <input
      :id="id"
      :type="type"
      :value="modelValue"
      @input="$emit('update:modelValue', ($event.target as HTMLInputElement).value)"
      class="input-field"
      v-bind="$attrs"
    />
  </div>
</template>

<script setup lang="ts">
/**
 * ================================================================================
 * @project:    @monorepo/ui-library
 * @file:       ~/layers/ui-library/components/UiInput.vue
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


