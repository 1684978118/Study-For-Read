<template>
  <AdminShell>
    <section class="admin-page">
      <header class="admin-page__header">
        <h2>Audit logs</h2>
        <p>Redacted admin activity details only.</p>
      </header>

      <AdminTableFilters @apply="loadAuditLogs">
        <label>
          Admin user id
          <input v-model="query.adminUserId" name="adminUserId" />
        </label>
        <label>
          Target type
          <input v-model="query.targetType" name="targetType" />
        </label>
        <label>
          Action
          <input v-model="query.action" name="action" />
        </label>
      </AdminTableFilters>

      <p v-if="auditLogs.error" class="inline-error">{{ auditLogs.error }}</p>
      <AdminAuditLogTable :logs="auditLogs.items" />
      <p class="admin-page__meta">Page {{ auditLogs.page + 1 }} · {{ auditLogs.total }} logs</p>
    </section>
  </AdminShell>
</template>

<script setup lang="ts">
import { onMounted, reactive } from 'vue'

import AdminAuditLogTable from '../../components/admin/AdminAuditLogTable.vue'
import AdminTableFilters from '../../components/admin/AdminTableFilters.vue'
import AdminShell from '../../components/layout/AdminShell.vue'
import { useAdminTokenStore } from '../../composables/useAdminTokenStore'
import { useAdminAuditLogsStore } from '../../stores/adminAuditLogs'

const auditLogs = useAdminAuditLogsStore()
const query = reactive({
  page: 0,
  size: 20,
  adminUserId: '',
  targetType: '',
  action: '',
})

async function loadAuditLogs() {
  const token = await useAdminTokenStore().getToken()
  if (token) {
    await auditLogs.loadAuditLogs(query, { accessToken: token })
  }
}

onMounted(loadAuditLogs)
</script>

<style scoped>
.admin-page {
  display: grid;
  gap: 16px;
}

.admin-page__header h2 {
  margin: 0 0 8px;
  font-size: 1.1rem;
}

.admin-page__header p,
.admin-page__meta {
  margin: 0;
  color: #657184;
}

.inline-error {
  margin: 0;
  color: #a33b36;
}
</style>
