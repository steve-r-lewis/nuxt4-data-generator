/**
* ================================================================================
*
* @project:    @monorepo/ui-library
* @file:       ~/layers/ui-library/components/UiFileUpload.vue
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
* Initial creation and release of UiFileUpload.vue
*
* ================================================================================
*/

<template>
  <div
    class="border-2 border-dashed border-[var(--color-outline)] rounded-xl p-6 text-center transition-all duration-200 hover:border-[var(--color-primary)] hover:bg-[var(--color-surface-lvl-1)] cursor-pointer"
    @click="triggerInput"
    @dragover.prevent
    @drop.prevent="handleDrop"
  >
    <input ref="fileInput" type="file" accept=".json" class="hidden" @change="handleFileChange" />
    <div class="flex flex-col items-center gap-2">
      <Icon name="lucide:upload-cloud" class="w-8 h-8 text-[var(--color-primary)]" />
      <p class="text-sm font-medium text-[var(--color-on-surface)]">
        {{ fileName || 'Click or Drag to Upload JSON' }}
      </p>
    </div>
  </div>
</template>

<script setup lang="ts">
const emit = defineEmits(['file-loaded'])
const fileInput = ref<HTMLInputElement | null>(null)
const fileName = ref('')

function triggerInput() { fileInput.value?.click() }

function processFile(file: File) {
  fileName.value = file.name
  const reader = new FileReader()
  reader.onload = (e) => {
    try {
      emit('file-loaded', JSON.parse(e.target?.result as string))
    } catch { alert('Invalid JSON') }
  }
  reader.readAsText(file)
}

function handleFileChange(e: Event) {
  const file = (e.target as HTMLInputElement).files?.[0]
  if (file) processFile(file)
}
function handleDrop(e: DragEvent) {
  const file = e.dataTransfer?.files[0]
  if (file) processFile(file)
}
</script>

<style scoped>
/* TODO: Add component-specific styles for LayoutDevelopment if utility classes are insufficient. */
</style>

