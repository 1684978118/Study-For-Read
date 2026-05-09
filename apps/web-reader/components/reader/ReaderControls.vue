<template>
  <footer class="reader-controls">
    <button
      data-testid="previous-chapter"
      type="button"
      :disabled="!canGoPrevious"
      @click="$emit('previous')"
    >
      Previous
    </button>
    <div class="reader-controls__font">
      <button
        type="button"
        aria-label="Decrease font size"
        @click="$emit('font-size-change', fontSize - 2)"
      >
        A-
      </button>
      <span>{{ fontSize }}px</span>
      <button
        type="button"
        aria-label="Increase font size"
        @click="$emit('font-size-change', fontSize + 2)"
      >
        A+
      </button>
    </div>
    <label>
      Theme
      <select
        :value="theme"
        @change="onThemeChange"
      >
        <option value="light">Light</option>
        <option value="sepia">Sepia</option>
        <option value="dark">Dark</option>
      </select>
    </label>
    <button
      data-testid="next-chapter"
      type="button"
      :disabled="!canGoNext"
      @click="$emit('next')"
    >
      Next
    </button>
  </footer>
</template>

<script setup lang="ts">
defineProps<{
  canGoPrevious: boolean
  canGoNext: boolean
  fontSize: number
  theme: 'light' | 'sepia' | 'dark'
}>()

const emit = defineEmits<{
  previous: []
  next: []
  'font-size-change': [value: number]
  'theme-change': [value: 'light' | 'sepia' | 'dark']
}>()

function onThemeChange(event: Event): void {
  const value = (event.target as HTMLSelectElement).value
  if (value === 'light' || value === 'sepia' || value === 'dark') {
    emit('theme-change', value)
  }
}
</script>

<style scoped>
.reader-controls {
  position: fixed;
  inset-inline: 0;
  inset-block-end: 0;
  display: flex;
  gap: 0.75rem;
  align-items: center;
  justify-content: center;
  padding: 0.875rem;
  background: rgba(255, 255, 255, 0.94);
  border-top: 1px solid #e5e7eb;
}

.reader-controls__font {
  display: inline-flex;
  gap: 0.5rem;
  align-items: center;
}

button,
select {
  min-block-size: 2.25rem;
  padding: 0.375rem 0.625rem;
}
</style>
