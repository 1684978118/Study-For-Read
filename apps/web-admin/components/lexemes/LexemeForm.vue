<template>
  <form class="lexeme-form" @submit.prevent="$emit('submit', model)">
    <p class="lexeme-form__note">Examples must be license-safe and admin-provided.</p>

    <label>
      Surface
      <input v-model="model.surface" name="surface" />
    </label>
    <label>
      Reading
      <input v-model="model.reading" name="reading" />
    </label>
    <label>
      Source language
      <input v-model="model.sourceLang" name="sourceLang" />
    </label>
    <label>
      Target language
      <input v-model="model.targetLang" name="targetLang" />
    </label>
    <label>
      Entry type
      <select v-model="model.entryType" name="entryType">
        <option value="word">Word</option>
        <option value="phrase">Phrase</option>
        <option value="idiom">Idiom</option>
      </select>
    </label>
    <label>
      Part of speech
      <input v-model="model.partOfSpeech" name="partOfSpeech" />
    </label>
    <label class="lexeme-form__wide">
      Definition
      <textarea v-model="model.definition" name="definition" rows="4" />
    </label>
    <label class="lexeme-form__wide">
      Short definition
      <input v-model="model.shortDefinition" name="shortDefinition" />
    </label>
    <label class="lexeme-form__wide">
      Example
      <textarea v-model="model.example" name="example" rows="3" />
    </label>
    <label>
      Status
      <select v-model="model.status" name="status">
        <option value="active">Active</option>
        <option value="candidate">Candidate</option>
        <option value="rejected">Rejected</option>
      </select>
    </label>

    <p v-if="error" class="lexeme-form__error" role="alert">{{ error }}</p>
    <button type="submit">Save lexeme</button>
  </form>
</template>

<script setup lang="ts">
import type { AdminLexemeUpsertRequest } from '../../types/adminLexeme'

const model = defineModel<AdminLexemeUpsertRequest>({ required: true })

defineProps<{
  error?: string | null
}>()

defineEmits<{
  submit: [AdminLexemeUpsertRequest]
}>()
</script>

<style scoped>
.lexeme-form {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
  max-width: 920px;
}

.lexeme-form__note,
.lexeme-form__error,
.lexeme-form__wide {
  grid-column: 1 / -1;
}

.lexeme-form__note {
  margin: 0;
  color: #657184;
}

.lexeme-form label {
  display: grid;
  gap: 5px;
  color: #384256;
  font-size: 0.9rem;
}

.lexeme-form input,
.lexeme-form select,
.lexeme-form textarea {
  border: 1px solid #c8cfda;
  border-radius: 6px;
  padding: 8px 10px;
  font: inherit;
}

.lexeme-form__error {
  margin: 0;
  color: #a33b36;
}

.lexeme-form button {
  width: fit-content;
  min-height: 38px;
  border: 0;
  border-radius: 6px;
  padding: 0 14px;
  background: #24324a;
  color: #ffffff;
  font: inherit;
  font-weight: 650;
}
</style>
