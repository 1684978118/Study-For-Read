<template>
  <AdminShell>
    <section class="lexeme-page">
      <header class="lexeme-page__header">
        <h2>Edit lexeme</h2>
        <p>Update public lexeme fields returned by the admin API.</p>
      </header>
      <LexemeForm v-model="form" :error="lexemes.formError" @submit="save" />
      <LexemeRejectDialog @reject="reject" />
    </section>
  </AdminShell>
</template>

<script setup lang="ts">
import { ref } from 'vue'

import AdminShell from '../../../components/layout/AdminShell.vue'
import LexemeForm from '../../../components/lexemes/LexemeForm.vue'
import LexemeRejectDialog from '../../../components/lexemes/LexemeRejectDialog.vue'
import { useAdminTokenStore } from '../../../composables/useAdminTokenStore'
import { emptyLexemeForm, useAdminLexemesStore } from '../../../stores/adminLexemes'
import type {
  AdminLexemeRejectRequest,
  AdminLexemeUpsertRequest,
} from '../../../types/adminLexeme'

const route = useRoute()
const lexemes = useAdminLexemesStore()
const form = ref<AdminLexemeUpsertRequest>(emptyLexemeForm())

async function save(request: AdminLexemeUpsertRequest) {
  const token = await useAdminTokenStore().getToken()
  if (token) {
    await lexemes.updateLexeme(String(route.params.id), request, { accessToken: token })
  }
}

async function reject(request: AdminLexemeRejectRequest) {
  const token = await useAdminTokenStore().getToken()
  if (token) {
    await lexemes.rejectLexeme(String(route.params.id), request, { accessToken: token })
  }
}
</script>

<style scoped>
.lexeme-page {
  display: grid;
  gap: 20px;
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
