import { createPinia, setActivePinia } from 'pinia'
import { readFile } from 'node:fs/promises'
import { resolve } from 'node:path'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import { createAdminLexemeApiClient } from '../../services/adminLexemeApiClient'
import { useAdminLexemesStore } from '../../stores/adminLexemes'
import type { AdminLexemeListResponse } from '../../types/adminLexeme'
import type { ApiEnvelope } from '../../types/api'

const lexemeList: AdminLexemeListResponse = {
  items: [
    {
      id: 'lexeme-1',
      surface: '心',
      normalizedSurface: '心',
      reading: 'こころ',
      sourceLang: 'ja',
      targetLang: 'zh-CN',
      entryType: 'word',
      partOfSpeech: 'noun',
      definition: '心；内心',
      shortDefinition: '心',
      example: null,
      status: 'active',
      createdAt: '2026-05-05T12:30:00Z',
      updatedAt: '2026-05-06T12:30:00Z',
    },
  ],
  page: 1,
  size: 20,
  total: 42,
}

describe('admin lexeme list page', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('calls /api/v1/admin/lexemes with pagination and filters', async () => {
    const fetcher = vi.fn(async () => ({
      success: true,
      data: lexemeList,
      error: null,
    }) satisfies ApiEnvelope<unknown>)
    const client = createAdminLexemeApiClient({ fetcher })
    const store = useAdminLexemesStore()

    await store.loadLexemes(
      {
        page: 1,
        size: 20,
        q: '心',
        sourceLang: 'ja',
        targetLang: 'zh-CN',
        entryType: 'word',
        status: 'active',
      },
      { apiClient: client, accessToken: 'admin-token' },
    )

    expect(fetcher).toHaveBeenCalledWith('/api/v1/admin/lexemes', {
      method: 'GET',
      headers: {
        Authorization: 'Bearer admin-token',
      },
      query: {
        page: 1,
        size: 20,
        q: '心',
        sourceLang: 'ja',
        targetLang: 'zh-CN',
        entryType: 'word',
        status: 'active',
      },
    })
    expect(store.items[0]?.surface).toBe('心')
    expect(store.total).toBe(42)
  })

  it('defines a compact lexeme table without raw/private fields', async () => {
    const table = await readFile(
      resolve(process.cwd(), 'components/lexemes/LexemeTable.vue'),
      'utf8',
    )

    expect(table).toContain('lexeme.surface')
    expect(table).toContain('lexeme.reading')
    expect(table).toContain('lexeme.sourceLang')
    expect(table).toContain('lexeme.targetLang')
    expect(table).toContain('lexeme.entryType')
    expect(table).toContain('lexeme.status')
    expect(table).toContain('lexeme.updatedAt')
    expect(table).not.toContain('privateSentenceContext')
    expect(table).not.toContain('chapterContent')
    expect(table).not.toContain('rawText')
    expect(table).not.toContain('translatedText')
  })

  it('uses AdminShell and lexeme filters on the list page', async () => {
    const page = await readFile(resolve(process.cwd(), 'pages/admin/lexemes/index.vue'), 'utf8')

    expect(page).toContain('AdminShell')
    expect(page).toContain('LexemeFilters')
    expect(page).toContain('LexemeTable')
    expect(page).not.toContain('Bulk import')
    expect(page).not.toContain('Provider management')
  })
})
