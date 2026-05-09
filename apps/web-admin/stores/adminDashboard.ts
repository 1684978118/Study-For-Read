import { defineStore } from 'pinia'

import {
  type AdminManagementApiClient,
  useAdminManagementApiClient,
} from '../services/adminManagementApiClient'
import type { AdminPlatformStatsSummary } from '../types/adminManagement'

interface LoadDeps {
  apiClient?: AdminManagementApiClient
  accessToken: string
}

export const useAdminDashboardStore = defineStore('adminDashboard', {
  state: () => ({
    summary: null as AdminPlatformStatsSummary | null,
    loading: false,
    error: null as string | null,
  }),

  actions: {
    async loadSummary(deps: LoadDeps) {
      const apiClient = deps.apiClient ?? useAdminManagementApiClient()
      this.loading = true
      this.error = null
      try {
        this.summary = await apiClient.getStatsSummary(deps.accessToken)
      } catch {
        this.summary = null
        this.error = 'Unable to load platform summary.'
      } finally {
        this.loading = false
      }
    },
  },
})
