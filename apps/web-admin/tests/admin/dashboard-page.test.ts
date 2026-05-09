import { createPinia, setActivePinia } from 'pinia'
import { readFile } from 'node:fs/promises'
import { resolve } from 'node:path'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import { createAdminManagementApiClient } from '../../services/adminManagementApiClient'
import { useAdminDashboardStore } from '../../stores/adminDashboard'
import type { AdminPlatformStatsSummary } from '../../types/adminManagement'
import type { ApiEnvelope } from '../../types/api'

const summary: AdminPlatformStatsSummary = {
  userCount: 120,
  activeUserCount: 118,
  disabledUserCount: 2,
  bookMetadataCount: 460,
  lexemeCount: 3200,
  wordCardCount: 9800,
  readingMinutes: 24000,
  lookupCount: 8600,
  paragraphTranslationCount: 2100,
  cardsCreated: 9800,
  cardsReviewed: 16300,
}

describe('admin dashboard and stats pages', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('calls /api/v1/admin/stats/summary and stores aggregate counters', async () => {
    const fetcher = vi.fn(async () => ({
      success: true,
      data: summary,
      error: null,
    }) satisfies ApiEnvelope<unknown>)
    const client = createAdminManagementApiClient({ fetcher })
    const store = useAdminDashboardStore()

    await store.loadSummary({ apiClient: client, accessToken: 'admin-token' })

    expect(fetcher).toHaveBeenCalledWith('/api/v1/admin/stats/summary', {
      method: 'GET',
      headers: {
        Authorization: 'Bearer admin-token',
      },
    })
    expect(store.summary?.userCount).toBe(120)
    expect(store.summary?.lookupCount).toBe(8600)
  })

  it('defines aggregate metric labels without forbidden raw fields', async () => {
    const component = await readFile(
      resolve(process.cwd(), 'components/admin/AdminMetricGrid.vue'),
      'utf8',
    )

    expect(component).toContain('Users')
    expect(component).toContain('Reading minutes')
    expect(component).toContain('lookupCount')
    expect(component).not.toContain('passwordHash')
    expect(component).not.toContain('rawText')
    expect(component).not.toContain('translatedText')
  })

  it('uses AdminShell on dashboard and stats pages', async () => {
    const dashboardPage = await readFile(resolve(process.cwd(), 'pages/admin/index.vue'), 'utf8')
    const statsPage = await readFile(resolve(process.cwd(), 'pages/admin/stats.vue'), 'utf8')

    expect(dashboardPage).toContain('AdminShell')
    expect(dashboardPage).toContain('AdminMetricGrid')
    expect(statsPage).toContain('AdminShell')
    expect(statsPage).toContain('AdminMetricGrid')
  })
})
