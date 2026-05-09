<template>
  <label class="import-button">
    <span>{{ disabled ? 'Importing...' : 'Import' }}</span>
    <input
      type="file"
      accept=".txt,.epub,text/plain,application/epub+zip"
      :disabled="disabled"
      @change="onFileChange"
    >
  </label>
</template>

<script setup lang="ts">
defineProps<{
  disabled?: boolean
}>()

const emit = defineEmits<{
  import: [file: File]
}>()

function onFileChange(event: Event): void {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  if (file) {
    emit('import', file)
  }
  input.value = ''
}
</script>

<style scoped>
.import-button {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.625rem 0.875rem;
  border: 1px solid #1f2937;
  border-radius: 0.375rem;
  color: #ffffff;
  background: #1f2937;
  cursor: pointer;
}

.import-button:has(input:disabled) {
  opacity: 0.65;
  cursor: wait;
}

input {
  position: absolute;
  inline-size: 1px;
  block-size: 1px;
  opacity: 0;
}
</style>
