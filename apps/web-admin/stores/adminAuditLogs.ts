import { defineStore } from 'pinia'

import {
  type AdminManagementApiClient,
  useAdminManagementApiClient,
} from '../services/adminManagementApiClient'
import type { AdminAuditLog, AdminAuditLogListQuery } from '../types/adminManagement'

interface LoadDeps {
  apiClient?: AdminManagementApiClient
  accessToken: string
}

export const useAdminAuditLogsStore = defineStore('adminAuditLogs', {
  state: () => ({
    items: [] as AdminAuditLog[],
    page: 0,
    size: 20,
    total: 0,
    loading: false,
    error: null as string | null,
    filters: {
      adminUserId: '',
      targetType: '',
      action: '',
    } as AdminAuditLogListQuery,
  }),

  actions: {
    async loadAuditLogs(query: AdminAuditLogListQuery = {}, deps: LoadDeps) {
      const apiClient = deps.apiClient ?? useAdminManagementApiClient()
      this.loading = true
      this.error = null
      try {
        const response = await apiClient.listAuditLogs(query, deps.accessToken)
        this.items = response.items
        this.page = response.page
        this.size = response.size
        this.total = response.total
      } catch {
        this.items = []
        this.error = 'Unable to load audit logs.'
      } finally {
        this.loading = false
      }
    },
  },
})
