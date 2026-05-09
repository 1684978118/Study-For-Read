<template>
  <form class="lexeme-filters" @submit.prevent="$emit('apply')">
    <label>
      Search
      <input v-model="model.q" name="q" />
    </label>
    <label>
      Source
      <input v-model="model.sourceLang" name="sourceLang" />
    </label>
    <label>
      Target
      <input v-model="model.targetLang" name="targetLang" />
    </label>
    <label>
      Entry type
      <select v-model="model.entryType" name="entryType">
        <option value="">All</option>
        <option value="word">Word</option>
        <option value="phrase">Phrase</option>
        <option value="idiom">Idiom</option>
      </select>
    </label>
    <label>
      Status
      <select v-model="model.status" name="status">
        <option value="">All</option>
        <option value="active">Active</option>
        <option value="candidate">Candidate</option>
        <option value="rejected">Rejected</option>
      </select>
    </label>
    <button type="submit">Apply</button>
  </form>
</template>

<script setup lang="ts">
import type { AdminLexemeListQuery } from '../../types/adminLexeme'

const model = defineModel<AdminLexemeListQuery>({ required: true })

defineEmits<{
  apply: []
}>()
</script>

<style scoped>
.lexeme-filters {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  align-items: end;
  margin-bottom: 16px;
}

.lexeme-filters label {
  display: grid;
  gap: 4px;
  color: #657184;
  font-size: 0.82rem;
}

.lexeme-filters input,
.lexeme-filters select {
  min-height: 34px;
  border: 1px solid #c8cfda;
  border-radius: 6px;
  padding: 0 8px;
  font: inherit;
}

.lexeme-filters button {
  min-height: 34px;
  border: 0;
  border-radius: 6px;
  padding: 0 14px;
  background: #24324a;
  color: #ffffff;
  font: inherit;
}
</style>
