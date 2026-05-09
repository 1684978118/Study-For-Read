import { createPinia, setActivePinia } from 'pinia'
import { beforeEach, describe, expect, it } from 'vitest'

import {
  resetAuthDependenciesForTesting,
  setAuthDependenciesForTesting,
  useAuthStore,
} from '../../stores/auth'
import type { AuthSession, AuthUser } from '../../types/auth'

describe('web reader auth store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    resetAuthDependenciesForTesting()
  })

  it('stores successful login tokens only through the token store abstraction', async () => {
    const tokenStore = fakeTokenStore()
    const apiClient = fakeApiClient()
    setAuthDependenciesForTesting({ apiClient, tokenStore })
    const store = useAuthStore()

    await store.signIn({
      email: 'reader@example.com',
      password: 'secret-password',
    })

    expect(apiClient.loginCalls).toEqual([
      { email: 'reader@example.com', password: 'secret-password' },
    ])
    expect(tokenStore.saved).toEqual([
      { accessToken: 'access-token', refreshToken: 'refresh-token' },
    ])
    expect(store.user?.id).toBe('user-1')
    expect(store.isSignedIn).toBe(true)
  })

  it('restores current user through /auth/me when an access token exists', async () => {
    const tokenStore = fakeTokenStore({ accessToken: 'access-token' })
    const apiClient = fakeApiClient()
    setAuthDependenciesForTesting({ apiClient, tokenStore })
    const store = useAuthStore()

    await store.restoreSession()

    expect(apiClient.meCalls).toEqual(['access-token'])
    expect(store.user?.email).toBe('reader@example.com')
    expect(store.isSignedIn).toBe(true)
  })

  it('clears access and refresh tokens on sign out', async () => {
    const tokenStore = fakeTokenStore({ accessToken: 'access-token' })
    const apiClient = fakeApiClient()
    setAuthDependenciesForTesting({ apiClient, tokenStore })
    const store = useAuthStore()
    await store.restoreSession()

    await store.signOut()

    expect(tokenStore.cleared).toBe(1)
    expect(store.user).toBeNull()
    expect(store.isSignedIn).toBe(false)
  })
})

function fakeApiClient() {
  return {
    loginCalls: [] as Array<{ email: string, password: string }>,
    registerCalls: [] as Array<{
      email: string
      password: string
      displayName: string
    }>,
    meCalls: [] as string[],
    async login(payload: { email: string, password: string }) {
      this.loginCalls.push(payload)
      return session()
    },
    async register(payload: {
      email: string
      password: string
      displayName: string
    }) {
      this.registerCalls.push(payload)
      return session()
    },
    async me(accessToken: string) {
      this.meCalls.push(accessToken)
      return user()
    },
  }
}

function fakeTokenStore(initial?: { accessToken?: string }) {
  return {
    saved: [] as Array<{ accessToken: string, refreshToken: string }>,
    cleared: 0,
    accessToken: initial?.accessToken ?? null,
    refreshToken: null as string | null,
    getAccessToken() {
      return this.accessToken
    },
    getRefreshToken() {
      return this.refreshToken
    },
    setTokens(tokens: { accessToken: string, refreshToken: string }) {
      this.saved.push(tokens)
      this.accessToken = tokens.accessToken
      this.refreshToken = tokens.refreshToken
    },
    clearTokens() {
      this.cleared += 1
      this.accessToken = null
      this.refreshToken = null
    },
  }
}

function session(): AuthSession {
  return {
    user: user(),
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
  }
}

function user(): AuthUser {
  return {
    id: 'user-1',
    email: 'reader@example.com',
    displayName: 'Reader',
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    status: 'active',
  }
}
