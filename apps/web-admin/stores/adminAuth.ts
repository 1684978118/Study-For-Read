import { defineStore } from 'pinia'

import {
  AdminApiError,
  type AdminApiClient,
  useAdminApiClient,
} from '../composables/useAdminApiClient'
import {
  type AdminTokenStore,
  useAdminTokenStore,
} from '../composables/useAdminTokenStore'
import type { AdminUiError } from '../types/api'
import type { AdminLoginRequest, AdminProfile } from '../types/adminAuth'

interface AdminAuthDeps {
  apiClient?: AdminApiClient
  tokenStore?: AdminTokenStore
}

interface AdminAuthState {
  admin: AdminProfile | null
  loading: boolean
  restored: boolean
  uiError: AdminUiError | null
}

export const useAdminAuthStore = defineStore('adminAuth', {
  state: (): AdminAuthState => ({
    admin: null,
    loading: false,
    restored: false,
    uiError: null,
  }),

  getters: {
    isAuthenticated: (state) => state.admin?.status === 'active',
  },

  actions: {
    async login(request: AdminLoginRequest, deps: AdminAuthDeps = {}) {
      const apiClient = deps.apiClient ?? useAdminApiClient()
      const tokenStore = deps.tokenStore ?? useAdminTokenStore()
      this.loading = true
      this.uiError = null

      try {
        const session = await apiClient.login(request)
        this.admin = session.admin
        this.restored = true
        await tokenStore.setToken(session.accessToken)
        return session
      } catch (error) {
        this.admin = null
        this.uiError = toUiError(error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async restore(deps: AdminAuthDeps = {}) {
      const apiClient = deps.apiClient ?? useAdminApiClient()
      const tokenStore = deps.tokenStore ?? useAdminTokenStore()
      this.loading = true
      this.uiError = null

      try {
        const token = await tokenStore.getToken()
        if (!token) {
          this.admin = null
          return
        }

        this.admin = await apiClient.me(token)
      } catch (error) {
        this.admin = null
        this.uiError = toUiError(error)
        await tokenStore.clearToken()
      } finally {
        this.restored = true
        this.loading = false
      }
    },

    async signOut(deps: Pick<AdminAuthDeps, 'tokenStore'> = {}) {
      const tokenStore = deps.tokenStore ?? useAdminTokenStore()
      this.admin = null
      this.uiError = null
      this.restored = true
      await tokenStore.clearToken()
    },
  },
})

function toUiError(error: unknown): AdminUiError {
  if (error instanceof AdminApiError) return error.uiCode
  if (typeof error === 'object' && error !== null && 'uiCode' in error) {
    const uiCode = (error as { uiCode?: AdminUiError }).uiCode
    if (uiCode) return uiCode
  }
  return 'request_failed'
}
