/**
* ================================================================================
*
* @project:    nuxt4-data-generator
* @file:       ~/app/error.vue
* @version:    V1.0.1
* @createDate: 2025 Oct 15
* @createTime: 23:58
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
 Updated project name in error.vue file.
*
* V1.0.0, 20251015-23:58
* Initial creation and release of error.vue
*
* ================================================================================
*/

<template>
  <div class="error-page">
    <h1 class="error-code">
      {{ error.statusCode }}
    </h1>
    <p class="error-message">
      {{ error.statusCode === 404 ? 'Page Not Found' : 'An Error Occurred' }}
    </p>

    <NuxtLink to="/" class="btn btn-primary error-link">
      Go back home
    </NuxtLink>
  </div>
</template>

<script setup lang="ts">
import type { NuxtError } from '#app'

const props = defineProps({
  error: Object as () => NuxtError,
});
</script>

<style scoped>
/* TODO: Add component-specific styles for LayoutDevelopment if utility classes are insufficient. */
</style>





