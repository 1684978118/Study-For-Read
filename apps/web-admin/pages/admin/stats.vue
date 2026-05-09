<template>
  <AdminShell>
    <section class="admin-page">
      <header class="admin-page__header">
        <h2>Platform stats</h2>
        <p>Aggregate counters across users and study activity.</p>
      </header>
      <p v-if="dashboard.error" class="inline-error">{{ dashboard.error }}</p>
      <AdminMetricGrid :summary="dashboard.summary" />
    </section>
  </AdminShell>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'

import AdminMetricGrid from '../../components/admin/AdminMetricGrid.vue'
import AdminShell from '../../components/layout/AdminShell.vue'
import { useAdminTokenStore } from '../../composables/useAdminTokenStore'
import { useAdminDashboardStore } from '../../stores/adminDashboard'

const dashboard = useAdminDashboardStore()

onMounted(async () => {
  const token = await useAdminTokenStore().getToken()
  if (token) {
    await dashboard.loadSummary({ accessToken: token })
  }
})
</script>

<style scoped>
.admin-page {
  display: grid;
  gap: 18px;
}

.admin-page__header h2 {
  margin: 0 0 8px;
  font-size: 1.1rem;
}

.admin-page__header p {
  margin: 0;
  color: #657184;
}

.inline-error {
  margin: 0;
  color: #a33b36;
}
</style>
