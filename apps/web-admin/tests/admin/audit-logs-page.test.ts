import { createPinia, setActivePinia } from 'pinia'
import { readFile } from 'node:fs/promises'
import { resolve } from 'node:path'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import {
  createAdminManagementApiClient,
  renderRedactedDetails,
} from '../../services/adminManagementApiClient'
import { useAdminAuditLogsStore } from '../../stores/adminAuditLogs'
import type { AdminAuditLogListResponse } from '../../types/adminManagement'
import type { ApiEnvelope } from '../../types/api'

const auditList: AdminAuditLogListResponse = {
  items: [
    {
      id: 'audit-1',
      adminUserId: 'admin-1',
      adminUsername: 'operator',
      action: 'lexeme.create',
      targetType: 'lexeme',
      targetId: 'lexeme-1',
      details: {
        surface: 'kokoro',
        sourceLang: 'ja',
        targetLang: 'zh-CN',
        password: 'raw-password',
        token: 'raw-token',
        rawText: 'raw private lookup',
        translatedText: 'raw translated text',
      },
      createdAt: '2026-05-05T12:30:00Z',
    },
  ],
  page: 1,
  size: 10,
  total: 31,
}

describe('admin audit logs page', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('calls /api/v1/admin/audit-logs with pagination and filters', async () => {
    const fetcher = vi.fn(async () => ({
      success: true,
      data: auditList,
      error: null,
    }) satisfies ApiEnvelope<unknown>)
    const client = createAdminManagementApiClient({ fetcher })
    const store = useAdminAuditLogsStore()

    await store.loadAuditLogs(
      {
        page: 1,
        size: 10,
        adminUserId: 'admin-1',
        targetType: 'lexeme',
        action: 'lexeme.create',
      },
      { apiClient: client, accessToken: 'admin-token' },
    )

    expect(fetcher).toHaveBeenCalledWith('/api/v1/admin/audit-logs', {
      method: 'GET',
      headers: {
        Authorization: 'Bearer admin-token',
      },
      query: {
        page: 1,
        size: 10,
        adminUserId: 'admin-1',
        targetType: 'lexeme',
        action: 'lexeme.create',
      },
    })
    expect(store.items[0]?.adminUsername).toBe('operator')
    expect(store.total).toBe(31)
  })

  it('renders redacted audit details only', () => {
    const text = renderRedactedDetails(auditList.items[0]!.details)
    expect(text).toContain('surface')
    expect(text).toContain('kokoro')
    expect(text).toContain('sourceLang')
    expect(text).not.toContain('raw-password')
    expect(text).not.toContain('raw-token')
    expect(text).not.toContain('raw private lookup')
    expect(text).not.toContain('raw translated text')
  })

  it('shows a stable inline error without raw response secrets', async () => {
    const client = createAdminManagementApiClient({
      fetcher: async () => ({
        success: false,
        data: null,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'token=raw-secret private sentence context',
        },
      }),
    })
    const store = useAdminAuditLogsStore()

    await store.loadAuditLogs({}, { apiClient: client, accessToken: 'admin-token' })

    expect(store.error).toBe('Unable to load audit logs.')
    expect(store.error).not.toContain('raw-secret')
    expect(store.error).not.toContain('private sentence context')
  })

  it('uses AdminShell and table filters on the audit logs page', async () => {
    const page = await readFile(resolve(process.cwd(), 'pages/admin/audit-logs.vue'), 'utf8')

    expect(page).toContain('AdminShell')
    expect(page).toContain('AdminTableFilters')
    expect(page).toContain('AdminAuditLogTable')
  })
})
