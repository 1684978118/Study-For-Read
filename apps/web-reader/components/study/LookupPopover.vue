<template>
  <aside class="lookup-popover">
    <p class="lookup-popover__surface">{{ result.lexeme.surface }}</p>
    <p
      v-if="result.lexeme.reading"
      class="lookup-popover__reading"
    >
      {{ result.lexeme.reading }}
    </p>
    <p>{{ result.lexeme.shortDefinition ?? result.lexeme.definition }}</p>
    <button
      type="button"
      @click="$emit('save')"
    >
      Save
    </button>
  </aside>
</template>

<script setup lang="ts">
import type { LookupResult } from '../../services/studyApiClient'

defineProps<{
  result: LookupResult
}>()

defineEmits<{
  save: []
}>()
</script>

<style scoped>
.lookup-popover {
  max-inline-size: 24rem;
  padding: 0.875rem;
  margin: 1rem auto;
  border: 1px solid #d1d5db;
  border-radius: 0.5rem;
  background: #ffffff;
}

.lookup-popover__surface {
  margin: 0;
  font-weight: 700;
}

.lookup-popover__reading {
  color: #4b5563;
}
</style>
