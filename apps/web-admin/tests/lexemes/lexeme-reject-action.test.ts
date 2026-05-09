import { createPinia, setActivePinia } from 'pinia'
import { readFile } from 'node:fs/promises'
import { resolve } from 'node:path'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import { createAdminLexemeApiClient } from '../../services/adminLexemeApiClient'
import { useAdminLexemesStore } from '../../stores/adminLexemes'
import type { AdminLexemeRejectResponse } from '../../types/adminLexeme'
import type { ApiEnvelope } from '../../types/api'

const rejected: AdminLexemeRejectResponse = {
  id: 'lexeme-1',
  status: 'rejected',
}

describe('admin lexeme reject action', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('calls POST /api/v1/admin/lexemes/{lexemeId}/reject', async () => {
    const fetcher = vi.fn(async () => ({
      success: true,
      data: rejected,
      error: null,
    }) satisfies ApiEnvelope<unknown>)
    const client = createAdminLexemeApiClient({ fetcher })

    await client.rejectLexeme('lexeme-1', { reason: 'duplicate' }, 'admin-token')

    expect(fetcher).toHaveBeenCalledWith('/api/v1/admin/lexemes/lexeme-1/reject', {
      method: 'POST',
      headers: {
        Authorization: 'Bearer admin-token',
      },
      body: {
        reason: 'duplicate',
      },
    })
  })

  it('updates store state after a successful reject', async () => {
    const client = createAdminLexemeApiClient({
      fetcher: async () => ({
        success: true,
        data: rejected,
        error: null,
      }),
    })
    const store = useAdminLexemesStore()

    const result = await store.rejectLexeme(
      'lexeme-1',
      { reason: 'duplicate' },
      { apiClient: client, accessToken: 'admin-token' },
    )

    expect(result?.status).toBe('rejected')
    expect(store.formError).toBeNull()
  })

  it('defines a reject dialog without private moderation or raw content fields', async () => {
    const dialog = await readFile(
      resolve(process.cwd(), 'components/lexemes/LexemeRejectDialog.vue'),
      'utf8',
    )

    expect(dialog).toContain('Reject lexeme')
    expect(dialog).toContain('reason')
    expect(dialog).not.toContain('privateSentenceContext')
    expect(dialog).not.toContain('rawText')
    expect(dialog).not.toContain('chapterContent')
    expect(dialog).not.toContain('Moderate private')
  })
})
