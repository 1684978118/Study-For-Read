<script setup lang="ts">
import type { VocabularyTab } from '../../stores/vocabulary'

defineProps<{
  activeTab: VocabularyTab
}>()

const emit = defineEmits<{
  select: [tab: VocabularyTab]
}>()
</script>

<template>
  <div class="tabs" role="tablist" aria-label="Vocabulary tabs">
    <button
      data-testid="tab-due"
      :class="{ active: activeTab === 'due' }"
      type="button"
      @click="emit('select', 'due')"
    >
      Due
    </button>
    <button
      data-testid="tab-all"
      :class="{ active: activeTab === 'all' }"
      type="button"
      @click="emit('select', 'all')"
    >
      All
    </button>
    <button
      data-testid="tab-private_sentence"
      :class="{ active: activeTab === 'private_sentence' }"
      type="button"
      @click="emit('select', 'private_sentence')"
    >
      Private Sentences
    </button>
  </div>
</template>

<style scoped>
.tabs {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 16px;
}

button {
  background: #f3f6f2;
  border: 1px solid #cbd4cc;
  border-radius: 6px;
  color: #243027;
  cursor: pointer;
  padding: 8px 12px;
}

button.active {
  background: #243027;
  border-color: #243027;
  color: #fff;
}
</style>
