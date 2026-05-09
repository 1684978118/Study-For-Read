import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import AuthMiddleware, { shouldRedirectToSignIn } from '../../middleware/auth.global'
import RegisterPage from '../../pages/register.vue'
import SignInPage from '../../pages/sign-in.vue'
import {
  resetAuthDependenciesForTesting,
  setAuthDependenciesForTesting,
  useAuthStore,
} from '../../stores/auth'
import type { AuthSession, AuthUser } from '../../types/auth'

describe('web reader auth pages and gate', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    resetAuthDependenciesForTesting()
  })

  it('sign-in page submits credentials through the auth store', async () => {
    const apiClient = fakeApiClient()
    setAuthDependenciesForTesting({ apiClient, tokenStore: fakeTokenStore() })
    const wrapper = mount(SignInPage, { global: { stubs: ['NuxtLink'] } })

    await wrapper.get('[name="email"]').setValue('reader@example.com')
    await wrapper.get('[name="password"]').setValue('secret-password')
    await wrapper.get('form').trigger('submit')
    await flushPromises()

    expect(apiClient.loginCalls).toEqual([
      { email: 'reader@example.com', password: 'secret-password' },
    ])
  })

  it('register page submits display name and credentials through the auth store', async () => {
    const apiClient = fakeApiClient()
    setAuthDependenciesForTesting({ apiClient, tokenStore: fakeTokenStore() })
    const wrapper = mount(RegisterPage, { global: { stubs: ['NuxtLink'] } })

    await wrapper.get('[name="displayName"]').setValue('Reader')
    await wrapper.get('[name="email"]').setValue('reader@example.com')
    await wrapper.get('[name="password"]').setValue('secret-password')
    await wrapper.get('form').trigger('submit')
    await flushPromises()

    expect(apiClient.registerCalls).toEqual([
      {
        displayName: 'Reader',
        email: 'reader@example.com',
        password: 'secret-password',
      },
    ])
  })

  it('redirects signed-out users away from the library route before page behavior matters', async () => {
    setAuthDependenciesForTesting({
      apiClient: fakeApiClient(),
      tokenStore: fakeTokenStore(),
    })
    const navigateTo = vi.fn()
    vi.stubGlobal('navigateTo', navigateTo)
    const store = useAuthStore()

    expect(shouldRedirectToSignIn('/library', store)).toBe(true)
    await AuthMiddleware({ path: '/library' } as never, {} as never)

    expect(navigateTo).toHaveBeenCalledWith('/sign-in')
    vi.unstubAllGlobals()
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
    async me() {
      return user()
    },
  }
}

function fakeTokenStore() {
  return {
    getAccessToken() {
      return null
    },
    getRefreshToken() {
      return null
    },
    setTokens() {},
    clearTokens() {},
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
