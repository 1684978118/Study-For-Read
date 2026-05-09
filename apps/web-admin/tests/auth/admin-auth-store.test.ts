import { createPinia, setActivePinia } from 'pinia'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import type { AdminApiClient } from '../../composables/useAdminApiClient'
import type { AdminTokenStore } from '../../composables/useAdminTokenStore'
import { useAdminAuthStore } from '../../stores/adminAuth'

const activeAdmin = {
  id: 'admin-1',
  username: 'operator',
  role: 'admin' as const,
  status: 'active' as const,
}

describe('admin auth store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('stores login tokens only through the admin token store abstraction', async () => {
    const tokenStore: AdminTokenStore = {
      getToken: vi.fn(),
      setToken: vi.fn(),
      clearToken: vi.fn(),
    }
    const apiClient: AdminApiClient = {
      login: vi.fn(async () => ({
        admin: activeAdmin,
        accessToken: 'admin-access-token',
      })),
      me: vi.fn(),
    }

    const store = useAdminAuthStore()
    await store.login(
      { username: 'operator', password: 'correct-password' },
      { apiClient, tokenStore },
    )

    expect(apiClient.login).toHaveBeenCalledWith({
      username: 'operator',
      password: 'correct-password',
    })
    expect(tokenStore.setToken).toHaveBeenCalledWith('admin-access-token')
    expect(store.admin?.username).toBe('operator')
    expect(store.isAuthenticated).toBe(true)
  })

  it('restores the admin profile from /me when a token exists', async () => {
    const tokenStore: AdminTokenStore = {
      getToken: vi.fn(async () => 'admin-access-token'),
      setToken: vi.fn(),
      clearToken: vi.fn(),
    }
    const apiClient: AdminApiClient = {
      login: vi.fn(),
      me: vi.fn(async () => activeAdmin),
    }

    const store = useAdminAuthStore()
    await store.restore({ apiClient, tokenStore })

    expect(apiClient.me).toHaveBeenCalledWith('admin-access-token')
    expect(store.admin?.id).toBe('admin-1')
    expect(store.isAuthenticated).toBe(true)
  })

  it('does not accept a user auth token as an admin session', async () => {
    const tokenStore: AdminTokenStore = {
      getToken: vi.fn(async () => 'user-access-token'),
      setToken: vi.fn(),
      clearToken: vi.fn(),
    }
    const apiClient: AdminApiClient = {
      login: vi.fn(),
      me: vi.fn(async () => {
        throw Object.assign(new Error('admin required'), {
          code: 'ADMIN_REQUIRED',
          uiCode: 'admin_required',
        })
      }),
    }

    const store = useAdminAuthStore()
    await store.restore({ apiClient, tokenStore })

    expect(tokenStore.clearToken).toHaveBeenCalled()
    expect(store.admin).toBeNull()
    expect(store.isAuthenticated).toBe(false)
  })

  it.each([
    ['ADMIN_INVALID_CREDENTIALS', 'invalid_credentials'],
    ['ADMIN_DISABLED', 'admin_disabled'],
  ])('keeps stable UI error state for %s', async (code, uiCode) => {
    const tokenStore: AdminTokenStore = {
      getToken: vi.fn(),
      setToken: vi.fn(),
      clearToken: vi.fn(),
    }
    const apiClient: AdminApiClient = {
      login: vi.fn(async () => {
        throw Object.assign(new Error('login failed'), { code, uiCode })
      }),
      me: vi.fn(),
    }

    const store = useAdminAuthStore()
    await expect(
      store.login(
        { username: 'operator', password: 'bad-password' },
        { apiClient, tokenStore },
      ),
    ).rejects.toMatchObject({ code })

    expect(store.uiError).toBe(uiCode)
    expect(tokenStore.setToken).not.toHaveBeenCalled()
  })
})
