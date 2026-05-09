<template>
  <table class="lexeme-table">
    <thead>
      <tr>
        <th>Surface</th>
        <th>Reading</th>
        <th>Source</th>
        <th>Target</th>
        <th>Entry type</th>
        <th>Status</th>
        <th>Updated</th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="lexeme in lexemes" :key="lexeme.id">
        <td>{{ lexeme.surface }}</td>
        <td>{{ lexeme.reading }}</td>
        <td>{{ lexeme.sourceLang }}</td>
        <td>{{ lexeme.targetLang }}</td>
        <td>{{ lexeme.entryType }}</td>
        <td><span class="status">{{ lexeme.status }}</span></td>
        <td>{{ lexeme.updatedAt }}</td>
      </tr>
    </tbody>
  </table>
</template>

<script setup lang="ts">
import type { AdminLexeme } from '../../types/adminLexeme'

defineProps<{
  lexemes: AdminLexeme[]
}>()
</script>

<style scoped>
.lexeme-table {
  width: 100%;
  border-collapse: collapse;
  background: #ffffff;
  font-size: 0.9rem;
}

.lexeme-table th,
.lexeme-table td {
  padding: 10px 12px;
  border-bottom: 1px solid #e2e6ee;
  text-align: left;
}

.lexeme-table th {
  color: #657184;
  font-weight: 650;
}

.status {
  display: inline-flex;
  padding: 2px 8px;
  border-radius: 999px;
  background: #eef2f7;
}
</style>
