<template>
  <aside class="paragraph-translation-panel">
    <p>{{ translatedText }}</p>
  </aside>
</template>

<script setup lang="ts">
defineProps<{
  translatedText: string
}>()
</script>

<style scoped>
.paragraph-translation-panel {
  padding: 0.75rem 0;
  color: #4b5563;
  border-top: 1px solid #e5e7eb;
}
</style>
