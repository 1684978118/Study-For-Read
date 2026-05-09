import { createPinia, setActivePinia } from 'pinia'
import { readFile } from 'node:fs/promises'
import { resolve } from 'node:path'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import { createAdminManagementApiClient } from '../../services/adminManagementApiClient'
import { useAdminUsersStore } from '../../stores/adminUsers'
import type { AdminUserListResponse } from '../../types/adminManagement'
import type { ApiEnvelope } from '../../types/api'

const userList: AdminUserListResponse = {
  items: [
    {
      id: 'user-1',
      email: 'reader@example.com',
      displayName: 'Reader',
      sourceLang: 'ja',
      targetLang: 'zh-CN',
      status: 'active',
      createdAt: '2026-05-05T12:30:00Z',
      updatedAt: '2026-05-06T12:30:00Z',
      passwordHash: 'secret-password-hash',
      tokenHash: 'secret-token-hash',
      chapterContent: 'full chapter content',
      privateSentenceContext: 'private sentence context',
    } as never,
  ],
  page: 2,
  size: 25,
  total: 77,
}

describe('admin users page', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('calls /api/v1/admin/users with pagination and filters', async () => {
    const fetcher = vi.fn(async () => ({
      success: true,
      data: userList,
      error: null,
    }) satisfies ApiEnvelope<unknown>)
    const client = createAdminManagementApiClient({ fetcher })
    const store = useAdminUsersStore()

    await store.loadUsers(
      { page: 2, size: 25, status: 'active', q: 'reader' },
      { apiClient: client, accessToken: 'admin-token' },
    )

    expect(fetcher).toHaveBeenCalledWith('/api/v1/admin/users', {
      method: 'GET',
      headers: {
        Authorization: 'Bearer admin-token',
      },
      query: {
        page: 2,
        size: 25,
        status: 'active',
        q: 'reader',
      },
    })
    expect(store.items[0]?.email).toBe('reader@example.com')
    expect(store.total).toBe(77)
  })

  it('defines a user metadata table without forbidden fields or secrets', async () => {
    const table = await readFile(
      resolve(process.cwd(), 'components/admin/AdminUsersTable.vue'),
      'utf8',
    )

    expect(table).toContain('user.email')
    expect(table).toContain('user.displayName')
    expect(table).toContain('user.sourceLang')
    expect(table).toContain('user.targetLang')
    expect(table).toContain('user.status')
    expect(table).toContain('user.createdAt')
    expect(table).toContain('user.updatedAt')
    expect(table).not.toContain('passwordHash')
    expect(table).not.toContain('tokenHash')
    expect(table).not.toContain('chapterContent')
    expect(table).not.toContain('privateSentenceContext')
  })

  it('shows a stable inline error without raw response secrets', async () => {
    const client = createAdminManagementApiClient({
      fetcher: async () => ({
        success: false,
        data: null,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'token=raw-secret password=raw-password',
        },
      }),
    })
    const store = useAdminUsersStore()

    await store.loadUsers({}, { apiClient: client, accessToken: 'admin-token' })

    expect(store.error).toBe('Unable to load users.')
    expect(store.error).not.toContain('raw-secret')
    expect(store.error).not.toContain('raw-password')
  })

  it('uses AdminShell and table filters on the users page', async () => {
    const page = await readFile(resolve(process.cwd(), 'pages/admin/users.vue'), 'utf8')

    expect(page).toContain('AdminShell')
    expect(page).toContain('AdminTableFilters')
    expect(page).toContain('AdminUsersTable')
  })
})
