<template>
  <AdminShell>
    <section class="lexeme-page">
      <header class="lexeme-page__header">
        <h2>Public lexemes</h2>
        <p>Search and maintain public dictionary entries.</p>
      </header>

      <LexemeFilters v-model="query" @apply="loadLexemes" />
      <p v-if="lexemes.listError" class="inline-error">{{ lexemes.listError }}</p>
      <LexemeTable :lexemes="lexemes.items" />
      <p class="lexeme-page__meta">Page {{ lexemes.page + 1 }} · {{ lexemes.total }} lexemes</p>
    </section>
  </AdminShell>
</template>

<script setup lang="ts">
import { onMounted, reactive } from 'vue'

import AdminShell from '../../../components/layout/AdminShell.vue'
import LexemeFilters from '../../../components/lexemes/LexemeFilters.vue'
import LexemeTable from '../../../components/lexemes/LexemeTable.vue'
import { useAdminTokenStore } from '../../../composables/useAdminTokenStore'
import { useAdminLexemesStore } from '../../../stores/adminLexemes'
import type { AdminLexemeListQuery } from '../../../types/adminLexeme'

const lexemes = useAdminLexemesStore()
const query = reactive<AdminLexemeListQuery>({
  page: 0,
  size: 20,
  q: '',
  sourceLang: '',
  targetLang: '',
  entryType: '',
  status: '',
})

async function loadLexemes() {
  const token = await useAdminTokenStore().getToken()
  if (token) {
    await lexemes.loadLexemes(query, { accessToken: token })
  }
}

onMounted(loadLexemes)
</script>

<style scoped>
.lexeme-page {
  display: grid;
  gap: 16px;
}

.lexeme-page__header h2 {
  margin: 0 0 8px;
  font-size: 1.1rem;
}

.lexeme-page__header p,
.lexeme-page__meta {
  margin: 0;
  color: #657184;
}

.inline-error {
  margin: 0;
  color: #a33b36;
}
</style>
