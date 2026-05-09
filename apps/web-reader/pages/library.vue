<template>
  <main class="library-page">
    <header class="library-page__header">
      <div>
        <h1>Library</h1>
        <p>Books stay in this browser. Only reading metadata is prepared for sync.</p>
      </div>
      <BookImportButton
        :disabled="library.isImporting"
        @import="importFile"
      />
    </header>

    <p
      v-if="library.errorMessage"
      role="alert"
      class="library-page__error"
    >
      {{ library.errorMessage }}
    </p>

    <p v-if="library.isLoading">Loading library...</p>
    <section
      v-else-if="library.books.length === 0"
      class="library-page__empty"
    >
      <h2>No books yet</h2>
      <p>Import a TXT or EPUB file to read locally. Books stay in this browser.</p>
    </section>
    <BookList
      v-else
      :books="library.books"
    />
  </main>
</template>

<script setup lang="ts">
import BookImportButton from '../components/library/BookImportButton.vue'
import BookList from '../components/library/BookList.vue'
import { useAuthStore } from '../stores/auth'
import { useLibraryStore } from '../stores/library'

const auth = useAuthStore()
const library = useLibraryStore()

onMounted(async () => {
  if (auth.user) {
    await library.load(auth.user.id)
  }
})

async function importFile(file: File): Promise<void> {
  if (!auth.user) {
    return
  }
  await library.importLocalFile({
    file,
    ownerUserId: auth.user.id,
    sourceLang: auth.user.sourceLang,
    targetLang: auth.user.targetLang,
  })
}
</script>

<style scoped>
.library-page {
  max-inline-size: 56rem;
  padding: 2rem;
  margin: 0 auto;
}

.library-page__header {
  display: flex;
  gap: 1rem;
  align-items: flex-start;
  justify-content: space-between;
}

.library-page__header p,
.library-page__empty p {
  color: #4b5563;
}

.library-page__empty {
  padding-block: 2rem;
}

.library-page__error {
  padding: 0.75rem;
  color: #7f1d1d;
  background: #fee2e2;
  border-radius: 0.375rem;
}
</style>
