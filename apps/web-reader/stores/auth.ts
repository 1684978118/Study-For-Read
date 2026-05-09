import { defineStore } from 'pinia'

import type { ApiClient } from '../composables/useApiClient'
import { useApiClient } from '../composables/useApiClient'
import type { AuthTokenStore } from '../composables/useAuthTokenStore'
import { useAuthTokenStore } from '../composables/useAuthTokenStore'
import type { AuthUser, RegisterRequest, SignInRequest } from '../types/auth'

interface AuthDependencies {
  apiClient: ApiClient
  tokenStore: AuthTokenStore
}

let testDependencies: AuthDependencies | null = null

export const useAuthStore = defineStore('auth', {
  state: () => ({
    user: null as AuthUser | null,
    isRestoring: false,
    errorMessage: null as string | null,
  }),
  getters: {
    isSignedIn: (state) => state.user != null,
  },
  actions: {
    async signIn(payload: SignInRequest) {
      this.errorMessage = null
      const { apiClient, tokenStore } = authDependencies()
      try {
        const session = await apiClient.login(payload)
        tokenStore.setTokens({
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
        })
        this.user = session.user
      }
      catch (error) {
        this.user = null
        this.errorMessage = messageFromError(error)
        throw error
      }
    },
    async register(payload: RegisterRequest) {
      this.errorMessage = null
      const { apiClient, tokenStore } = authDependencies()
      try {
        const session = await apiClient.register(payload)
        tokenStore.setTokens({
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
        })
        this.user = session.user
      }
      catch (error) {
        this.user = null
        this.errorMessage = messageFromError(error)
        throw error
      }
    },
    async restoreSession() {
      if (this.user != null || this.isRestoring) {
        return
      }
      const { apiClient, tokenStore } = authDependencies()
      const accessToken = tokenStore.getAccessToken()
      if (!accessToken) {
        this.user = null
        return
      }

      this.isRestoring = true
      this.errorMessage = null
      try {
        this.user = await apiClient.me(accessToken)
      }
      catch {
        tokenStore.clearTokens()
        this.user = null
      }
      finally {
        this.isRestoring = false
      }
    },
    async signOut() {
      const { tokenStore } = authDependencies()
      tokenStore.clearTokens()
      this.user = null
      this.errorMessage = null
    },
  },
})

export function setAuthDependenciesForTesting(
  dependencies: AuthDependencies,
): void {
  testDependencies = dependencies
}

export function resetAuthDependenciesForTesting(): void {
  testDependencies = null
}

function authDependencies(): AuthDependencies {
  return testDependencies ?? {
    apiClient: useApiClient(),
    tokenStore: useAuthTokenStore(),
  }
}

function messageFromError(error: unknown): string {
  if (error instanceof Error && error.message) {
    return error.message
  }
  return 'Authentication failed.'
}
