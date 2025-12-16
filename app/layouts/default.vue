/**
* ================================================================================
*
* @project:    nuxt4-data-generator
* @file:       ~/app/layouts/default.vue
* @version:    V1.0.1
* @createDate: 2025 Oct 16
* @createTime: 00:02
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
 Renamed project and updated navigation components.
*
* V1.0.0, 20251016-00:02
* Initial creation and release of default.vue
*
* ================================================================================
*/

<template>
  <div class="flex h-screen w-full bg-[var(--color-surface-lvl-0)] text-[var(--color-on-surface)] overflow-hidden">
    <aside class="w-64 bg-[var(--color-surface-lvl-1)] border-r border-[var(--color-outline)] flex flex-col">
      <div class="h-16 flex items-center px-6 border-b border-[var(--color-outline)] text-[var(--color-primary)] font-bold gap-2">
        <Icon name="lucide:database-zap" /> DataForge
      </div>

      <nav class="p-4 space-y-1">
        <button
          v-for="item in navItems"
          :key="item.id"
          @click="store.setView(item.id)"
          class="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors"
          :class="store.activeView === item.id ? 'bg-[var(--color-primary-container)] text-[var(--color-on-primary-container)]' : 'hover:bg-[var(--color-surface-lvl-2)]'"
        >
          <Icon :name="item.icon" class="w-4 h-4" />
          {{ item.label }}
        </button>
      </nav>
    </aside>

    <main class="flex-1 flex flex-col min-w-0">
      <header class="h-16 bg-[var(--color-surface-lvl-1)] border-b border-[var(--color-outline)] flex items-center px-6 justify-between">
        <h1 class="font-semibold capitalize">{{ store.activeView.replace('-', ' ') }}</h1>
      </header>
      <div class="flex-1 overflow-y-auto p-6">
        <slot />
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { useDataStore } from '#imports' // Auto-imported from layer

const store = useDataStore()

const navItems = [
  { id: 'dashboard', label: 'Dashboard', icon: 'lucide:layout-dashboard' },
  { id: 'user-account', label: 'User Account', icon: 'lucide:user' },
  { id: 'app-config', label: 'App Config', icon: 'lucide:sliders' },
  { id: 'settings', label: 'Settings', icon: 'lucide:settings' },
]
</script>

<style scoped>
/* TODO: Add component-specific styles for LayoutDevelopment if utility classes are insufficient. */
</style>








