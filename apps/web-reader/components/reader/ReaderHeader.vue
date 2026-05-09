<template>
  <header class="reader-header">
    <NuxtLink
      class="reader-header__back"
      to="/library"
    >
      Library
    </NuxtLink>
    <div>
      <p class="reader-header__book">{{ bookTitle }}</p>
      <h1>{{ chapterTitle }}</h1>
    </div>
    <p class="reader-header__status">{{ syncStatus }}</p>
  </header>
</template>

<script setup lang="ts">
defineProps<{
  bookTitle: string
  chapterTitle: string
  syncStatus: string
}>()
</script>

<style scoped>
.reader-header {
  display: grid;
  grid-template-columns: auto 1fr auto;
  gap: 1rem;
  align-items: center;
  padding: 1rem 1.25rem;
  border-bottom: 1px solid #e5e7eb;
}

.reader-header__back {
  color: #374151;
  text-decoration: none;
}

.reader-header__book,
.reader-header__status {
  margin: 0;
  color: #6b7280;
  font-size: 0.875rem;
}

h1 {
  margin: 0.125rem 0 0;
  color: #111827;
  font-size: 1.125rem;
}
</style>
