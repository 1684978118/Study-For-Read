<script setup lang="ts">
import type { VocabularyCardView } from '../../stores/vocabulary'

defineProps<{
  card: VocabularyCardView
}>()

const emit = defineEmits<{
  review: [payload: { localCardId: string, known: boolean }]
}>()
</script>

<template>
  <article class="card-tile">
    <div>
      <h2>{{ card.lexeme?.surface ?? card.privateSurface }}</h2>
      <p v-if="card.lexeme?.reading" class="muted">
        {{ card.lexeme.reading }}
      </p>
      <p>{{ card.lexeme?.definition ?? card.privateDefinition }}</p>
      <p v-if="card.privateContext" class="muted">
        {{ card.privateContext }}
      </p>
      <p class="review">
        {{ card.reviewStatus }} - {{ card.reviewCount }} reviews
        <span v-if="card.nextReviewAt"> - next {{ card.nextReviewAt.slice(0, 10) }}</span>
      </p>
    </div>
    <div class="actions">
      <button
        :data-testid="`review-known-${card.id}`"
        type="button"
        @click="emit('review', { localCardId: card.id, known: true })"
      >
        Known
      </button>
      <button
        :data-testid="`review-unknown-${card.id}`"
        type="button"
        @click="emit('review', { localCardId: card.id, known: false })"
      >
        Unknown
      </button>
    </div>
  </article>
</template>

<style scoped>
.card-tile {
  align-items: start;
  border: 1px solid #d8ddd8;
  border-radius: 8px;
  display: flex;
  gap: 16px;
  justify-content: space-between;
  padding: 14px;
}

h2 {
  font-size: 1.1rem;
  margin: 0 0 4px;
}

p {
  margin: 4px 0;
}

.muted,
.review {
  color: #667069;
}

.actions {
  display: flex;
  gap: 8px;
}

button {
  border: 1px solid #cbd4cc;
  border-radius: 6px;
  cursor: pointer;
  padding: 8px 10px;
}
</style>
