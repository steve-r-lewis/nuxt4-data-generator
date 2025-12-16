/**
* ================================================================================
*
* @project:    nuxt4-data-generator
* @file:       ~/app/pages/index.vue
* @version:    V1.0.0
* @createDate: 2025 Dec 16
* @createTime: 20:17
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
* V1.0.0, 20251216-20:17
* Initial creation and release of index.vue
*
* ================================================================================
*/<template>
  <div>
    <div v-if="store.activeView === 'user-account'" class="grid grid-cols-1 lg:grid-cols-12 gap-6">

      <div class="lg:col-span-4 space-y-4">
        <UiCard>
          <h3 class="font-bold mb-4">Configuration</h3>
          <UiInput label="Role" v-model="role" />
          <div class="mt-4">
            <UiButton @click="generateUserAccount({ role })" class="w-full">Generate</UiButton>
          </div>
        </UiCard>

        <UiCard>
          <h3 class="font-bold mb-4">Import Template</h3>
          <UiFileUpload @file-loaded="(data) => store.setGeneratedData(data)" />
        </UiCard>
      </div>

      <div class="lg:col-span-8">
        <UiCard class="h-full">
          <h3 class="font-bold mb-4">JSON Output</h3>
          <UiJsonViewer :data="store.generatedData || {}" />
        </UiCard>
      </div>

    </div>

    <div v-else class="text-center p-10 text-[var(--color-on-surface-variant)]">
      Select a generator from the sidebar.
    </div>
  </div>
</template>

<script setup lang="ts">
// Logic is decoupled into composables
const store = useDataStore()
const { generateUserAccount } = useMockGenerator()

const role = ref('admin')
</script>

<style scoped>
/* TODO: Add component-specific styles for LayoutDevelopment if utility classes are insufficient. */
</style>

