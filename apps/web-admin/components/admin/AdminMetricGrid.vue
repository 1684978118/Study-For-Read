<template>
  <dl class="metric-grid">
    <div v-for="metric in metrics" :key="metric.label" class="metric-grid__item">
      <dt>{{ metric.label }}</dt>
      <dd>{{ metric.value.toLocaleString() }}</dd>
    </div>
  </dl>
</template>

<script setup lang="ts">
import { computed } from 'vue'

import type { AdminPlatformStatsSummary } from '../../types/adminManagement'

const props = defineProps<{
  summary: AdminPlatformStatsSummary | null
}>()

const metrics = computed(() => {
  const summary = props.summary
  if (!summary) return []
  return [
    { label: 'Users', value: summary.userCount },
    { label: 'Active users', value: summary.activeUserCount },
    { label: 'Disabled users', value: summary.disabledUserCount },
    { label: 'Book metadata records', value: summary.bookMetadataCount },
    { label: 'Public lexemes', value: summary.lexemeCount },
    { label: 'Word cards', value: summary.wordCardCount },
    { label: 'Reading minutes', value: summary.readingMinutes },
    { label: 'Lookups', value: summary.lookupCount },
    { label: 'Paragraph translations', value: summary.paragraphTranslationCount },
    { label: 'Cards created', value: summary.cardsCreated },
    { label: 'Cards reviewed', value: summary.cardsReviewed },
  ]
})
</script>

<style scoped>
.metric-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
  gap: 1px;
  margin: 0;
  border: 1px solid #d8dde6;
  background: #d8dde6;
}

.metric-grid__item {
  padding: 14px 16px;
  background: #ffffff;
}

.metric-grid dt {
  color: #657184;
  font-size: 0.82rem;
}

.metric-grid dd {
  margin: 6px 0 0;
  color: #1d2433;
  font-size: 1.35rem;
  font-weight: 700;
}
</style>
