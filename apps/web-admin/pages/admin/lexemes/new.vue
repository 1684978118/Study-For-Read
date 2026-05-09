<template>
  <AdminShell>
    <section class="lexeme-page">
      <header class="lexeme-page__header">
        <h2>New lexeme</h2>
        <p>Create a public lexeme entry.</p>
      </header>
      <LexemeForm v-model="form" :error="lexemes.formError" @submit="save" />
    </section>
  </AdminShell>
</template>

<script setup lang="ts">
import { ref } from 'vue'

import AdminShell from '../../../components/layout/AdminShell.vue'
import LexemeForm from '../../../components/lexemes/LexemeForm.vue'
import { useAdminTokenStore } from '../../../composables/useAdminTokenStore'
import { emptyLexemeForm, useAdminLexemesStore } from '../../../stores/adminLexemes'
import type { AdminLexemeUpsertRequest } from '../../../types/adminLexeme'

const lexemes = useAdminLexemesStore()
const form = ref<AdminLexemeUpsertRequest>(emptyLexemeForm())

async function save(request: AdminLexemeUpsertRequest) {
  const token = await useAdminTokenStore().getToken()
  if (token) {
    await lexemes.createLexeme(request, { accessToken: token })
  }
}
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

.lexeme-page__header p {
  margin: 0;
  color: #657184;
}
</style>
