import { defineStore } from 'pinia'

import {
  type AdminManagementApiClient,
  useAdminManagementApiClient,
} from '../services/adminManagementApiClient'
import type { AdminUserListQuery, AdminUserSummary } from '../types/adminManagement'

interface LoadDeps {
  apiClient?: AdminManagementApiClient
  accessToken: string
}

export const useAdminUsersStore = defineStore('adminUsers', {
  state: () => ({
    items: [] as AdminUserSummary[],
    page: 0,
    size: 20,
    total: 0,
    loading: false,
    error: null as string | null,
    filters: {
      q: '',
      status: '',
    } as AdminUserListQuery,
  }),

  actions: {
    async loadUsers(query: AdminUserListQuery = {}, deps: LoadDeps) {
      const apiClient = deps.apiClient ?? useAdminManagementApiClient()
      this.loading = true
      this.error = null
      try {
        const response = await apiClient.listUsers(query, deps.accessToken)
        this.items = response.items
        this.page = response.page
        this.size = response.size
        this.total = response.total
      } catch {
        this.items = []
        this.error = 'Unable to load users.'
      } finally {
        this.loading = false
      }
    },
  },
})
