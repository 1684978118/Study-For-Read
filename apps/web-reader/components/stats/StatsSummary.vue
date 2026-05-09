<script setup lang="ts">
import type { WebStudyDailyStatsCounters } from '../../types/localData'

defineProps<{
  title: string
  summary: WebStudyDailyStatsCounters
}>()
</script>

<template>
  <section class="stats-summary">
    <h2>{{ title }}</h2>
    <dl>
      <div>
        <dt>Reading minutes</dt>
        <dd>{{ summary.readingMinutes }}</dd>
      </div>
      <div>
        <dt>Lookups</dt>
        <dd>{{ summary.lookupCount }}</dd>
      </div>
      <div>
        <dt>Paragraph translations</dt>
        <dd>{{ summary.paragraphTranslationCount }}</dd>
      </div>
      <div>
        <dt>Cards created</dt>
        <dd>{{ summary.cardsCreated }}</dd>
      </div>
      <div>
        <dt>Cards reviewed</dt>
        <dd>{{ summary.cardsReviewed }}</dd>
      </div>
    </dl>
  </section>
</template>

<style scoped>
.stats-summary {
  border: 1px solid #d8ddd8;
  border-radius: 8px;
  padding: 16px;
}

h2 {
  font-size: 1rem;
  margin: 0 0 12px;
}

dl {
  display: grid;
  gap: 8px;
  margin: 0;
}

div {
  display: flex;
  justify-content: space-between;
  gap: 16px;
}

dt {
  color: #59635d;
}

dd {
  font-weight: 700;
  margin: 0;
}
</style>
