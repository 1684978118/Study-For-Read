<template>
  <form class="table-filters" @submit.prevent="$emit('apply')">
    <slot />
    <button type="submit">Apply</button>
  </form>
</template>

<script setup lang="ts">
defineEmits<{
  apply: []
}>()
</script>

<style scoped>
.table-filters {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  align-items: end;
  margin-bottom: 16px;
}

.table-filters :deep(label) {
  display: grid;
  gap: 4px;
  color: #657184;
  font-size: 0.82rem;
}

.table-filters :deep(input),
.table-filters :deep(select) {
  min-height: 34px;
  border: 1px solid #c8cfda;
  border-radius: 6px;
  padding: 0 8px;
  font: inherit;
}

.table-filters button {
  min-height: 34px;
  border: 0;
  border-radius: 6px;
  padding: 0 14px;
  background: #24324a;
  color: #ffffff;
  font: inherit;
}
</style>
