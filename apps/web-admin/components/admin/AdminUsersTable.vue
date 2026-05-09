<template>
  <table class="admin-table">
    <thead>
      <tr>
        <th>Email</th>
        <th>Display name</th>
        <th>Source</th>
        <th>Target</th>
        <th>Status</th>
        <th>Created</th>
        <th>Updated</th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="user in users" :key="user.id">
        <td>{{ user.email }}</td>
        <td>{{ user.displayName }}</td>
        <td>{{ user.sourceLang }}</td>
        <td>{{ user.targetLang }}</td>
        <td><span class="status">{{ user.status }}</span></td>
        <td>{{ user.createdAt }}</td>
        <td>{{ user.updatedAt }}</td>
      </tr>
    </tbody>
  </table>
</template>

<script setup lang="ts">
import type { AdminUserSummary } from '../../types/adminManagement'

defineProps<{
  users: AdminUserSummary[]
}>()
</script>

<style scoped>
.admin-table {
  width: 100%;
  border-collapse: collapse;
  background: #ffffff;
  font-size: 0.9rem;
}

.admin-table th,
.admin-table td {
  padding: 10px 12px;
  border-bottom: 1px solid #e2e6ee;
  text-align: left;
}

.admin-table th {
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
