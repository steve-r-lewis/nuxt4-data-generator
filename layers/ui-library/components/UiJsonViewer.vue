/**
* ================================================================================
*
* @project:    @monorepo/ui-library
* @file:       ~/layers/ui-library/components/UiJsonViewer.vue
* @version:    V1.0.0
* @createDate: 2025 Dec 16
* @createTime: 20:13
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
* V1.0.0, 20251216-20:13
* Initial creation and release of UiJsonViewer.vue
*
* ================================================================================
*/

<template>
  <div class="relative group">
    <div class="absolute right-2 top-2 opacity-0 group-hover:opacity-100 transition-opacity">
      <button @click="copyJson" class="btn-xs-secondary flex items-center gap-1">
        <Icon name="lucide:copy" class="w-3 h-3" /> Copy
      </button>
    </div>
    <pre class="w-full h-96 overflow-auto rounded-xl bg-[var(--color-surface-lvl-2)] border border-[var(--color-outline)] p-4 font-mono text-sm text-[var(--color-on-surface)]">{{ formattedJson }}</pre>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{ data: any }>()
const formattedJson = computed(() => JSON.stringify(props.data, null, 2))
function copyJson() { navigator.clipboard.writeText(formattedJson.value) }
</script>

<style scoped>
.btn-xs-secondary {
  @apply p-1.5 bg-[var(--color-surface-lvl-1)] rounded-md border border-[var(--color-outline)] text-[var(--color-primary)] hover:bg-[var(--color-surface-lvl-2)] shadow-sm text-xs cursor-pointer;
}
</style>

<style scoped>
/* TODO: Add component-specific styles for LayoutDevelopment if utility classes are insufficient. */
</style>

