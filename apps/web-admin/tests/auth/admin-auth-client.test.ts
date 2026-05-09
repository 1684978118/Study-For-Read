import { describe, expect, it, vi } from 'vitest'

import { AdminApiError, createAdminApiClient } from '../../composables/useAdminApiClient'
import type { ApiEnvelope } from '../../types/api'

describe('admin auth API client', () => {
  it('posts username and password to admin login and parses session data', async () => {
    const requests: Array<{ path: string; options: Record<string, unknown> }> = []
    const fetcher = vi.fn(async (path: string, options: Record<string, unknown>) => {
      requests.push({ path, options })
      return {
        success: true,
        data: {
          admin: {
            id: 'admin-1',
            username: 'operator',
            role: 'operator',
            status: 'active',
          },
          accessToken: 'admin-access-token',
        },
        error: null,
      } satisfies ApiEnvelope<unknown>
    })

    const client = createAdminApiClient({ fetcher })
    const result = await client.login({
      username: 'operator',
      password: 'correct-password',
    })

    expect(requests).toEqual([
      {
        path: '/api/v1/admin/auth/login',
        options: {
          method: 'POST',
          body: {
            username: 'operator',
            password: 'correct-password',
          },
        },
      },
    ])
    expect(result.admin.username).toBe('operator')
    expect(result.accessToken).toBe('admin-access-token')
  })

  it.each([
    ['ADMIN_INVALID_CREDENTIALS', 'invalid_credentials'],
    ['ADMIN_DISABLED', 'admin_disabled'],
  ])('maps %s to a stable UI error', async (code, uiCode) => {
    const client = createAdminApiClient({
      fetcher: async () => ({
        success: false,
        data: null,
        error: {
          code,
          message: 'Backend message should not define UI copy.',
        },
      }),
    })

    await expect(
      client.login({ username: 'operator', password: 'bad-password' }),
    ).rejects.toMatchObject({
      code,
      uiCode,
    })
  })

  it('calls admin auth me with bearer token when restoring a session', async () => {
    const fetcher = vi.fn(async () => ({
      success: true,
      data: {
        id: 'admin-1',
        username: 'operator',
        role: 'admin',
        status: 'active',
      },
      error: null,
    }) satisfies ApiEnvelope<unknown>)

    const client = createAdminApiClient({ fetcher })
    const admin = await client.me('admin-token')

    expect(fetcher).toHaveBeenCalledWith('/api/v1/admin/auth/me', {
      method: 'GET',
      headers: {
        Authorization: 'Bearer admin-token',
      },
    })
    expect(admin.role).toBe('admin')
  })

  it('throws typed API errors for malformed envelopes', async () => {
    const client = createAdminApiClient({
      fetcher: async () => ({
        success: true,
        data: null,
        error: null,
      }),
    })

    await expect(client.me('admin-token')).rejects.toBeInstanceOf(AdminApiError)
  })
})
