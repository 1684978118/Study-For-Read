<template>
  <AdminShell>
    <section class="admin-page">
      <header class="admin-page__header">
        <h2>Users</h2>
        <p>Operational user metadata with no book or private study content.</p>
      </header>

      <AdminTableFilters @apply="loadUsers">
        <label>
          Search
          <input v-model="query.q" name="q" />
        </label>
        <label>
          Status
          <select v-model="query.status" name="status">
            <option value="">All</option>
            <option value="active">Active</option>
            <option value="disabled">Disabled</option>
          </select>
        </label>
      </AdminTableFilters>

      <p v-if="users.error" class="inline-error">{{ users.error }}</p>
      <AdminUsersTable :users="users.items" />
      <p class="admin-page__meta">Page {{ users.page + 1 }} · {{ users.total }} users</p>
    </section>
  </AdminShell>
</template>

<script setup lang="ts">
import { onMounted, reactive } from 'vue'

import AdminTableFilters from '../../components/admin/AdminTableFilters.vue'
import AdminUsersTable from '../../components/admin/AdminUsersTable.vue'
import AdminShell from '../../components/layout/AdminShell.vue'
import { useAdminTokenStore } from '../../composables/useAdminTokenStore'
import { useAdminUsersStore } from '../../stores/adminUsers'
import type { AdminUserListQuery } from '../../types/adminManagement'

const users = useAdminUsersStore()
const query = reactive<AdminUserListQuery>({
  page: 0,
  size: 20,
  status: '',
  q: '',
})

async function loadUsers() {
  const token = await useAdminTokenStore().getToken()
  if (token) {
    await users.loadUsers(query, { accessToken: token })
  }
}

onMounted(loadUsers)
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
