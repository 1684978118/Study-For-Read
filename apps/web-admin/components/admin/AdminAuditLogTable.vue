<template>
  <table class="admin-table">
    <thead>
      <tr>
        <th>Admin</th>
        <th>Action</th>
        <th>Target</th>
        <th>Details</th>
        <th>Created</th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="log in logs" :key="log.id">
        <td>{{ log.adminUsername }}</td>
        <td>{{ log.action }}</td>
        <td>{{ log.targetType }} / {{ log.targetId }}</td>
        <td>{{ renderDetails(log.details) }}</td>
        <td>{{ log.createdAt }}</td>
      </tr>
    </tbody>
  </table>
</template>

<script setup lang="ts">
import { renderRedactedDetails } from '../../services/adminManagementApiClient'
import type { AdminAuditLog } from '../../types/adminManagement'

defineProps<{
  logs: AdminAuditLog[]
}>()

function renderDetails(details: Record<string, unknown>): string {
  return renderRedactedDetails(details)
}
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
  vertical-align: top;
}

.admin-table th {
  color: #657184;
  font-weight: 650;
}
</style>
