<template>
  <ul class="book-list">
    <li
      v-for="book in books"
      :key="book.id"
      class="book-list__item"
    >
      <button
        type="button"
        class="book-list__button"
        :data-testid="`open-book-${book.id}`"
        @click="openBook(book.id)"
      >
        <span class="book-list__title">{{ book.title }}</span>
        <span
          v-if="book.author"
          class="book-list__author"
        >{{ book.author }}</span>
        <span class="book-list__meta">{{ book.fileType.toUpperCase() }} - {{ book.metadataSyncStatus }}</span>
      </button>
    </li>
  </ul>
</template>

<script setup lang="ts">
import type { WebBook } from '../../types/localData'

defineProps<{
  books: WebBook[]
}>()

function openBook(localBookId: string): void {
  const navigate = (globalThis as { navigateTo?: (path: string) => unknown }).navigateTo
  if (navigate) {
    void navigate(`/reader/${localBookId}`)
    return
  }
  void navigateTo(`/reader/${localBookId}`)
}
</script>

<style scoped>
.book-list {
  display: grid;
  gap: 0.75rem;
  padding: 0;
  margin: 1rem 0 0;
  list-style: none;
}

.book-list__button {
  display: grid;
  gap: 0.25rem;
  inline-size: 100%;
  padding: 0.875rem;
  text-align: start;
  border: 1px solid #d1d5db;
  border-radius: 0.5rem;
  background: #ffffff;
  cursor: pointer;
}

.book-list__title {
  font-weight: 700;
  color: #111827;
}

.book-list__author,
.book-list__meta {
  color: #4b5563;
}
</style>
