import { createPinia, setActivePinia } from 'pinia'
import { readFile } from 'node:fs/promises'
import { resolve } from 'node:path'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import { createAdminLexemeApiClient } from '../../services/adminLexemeApiClient'
import { useAdminLexemesStore } from '../../stores/adminLexemes'
import type { AdminLexeme, AdminLexemeUpsertRequest } from '../../types/adminLexeme'
import type { ApiEnvelope } from '../../types/api'

const request: AdminLexemeUpsertRequest = {
  surface: '心',
  reading: 'こころ',
  sourceLang: 'ja',
  targetLang: 'zh-CN',
  entryType: 'word',
  partOfSpeech: 'noun',
  definition: '心；内心',
  shortDefinition: '心',
  example: 'Admin-provided example.',
  status: 'active',
}

const response: AdminLexeme = {
  id: 'lexeme-1',
  normalizedSurface: '心',
  createdAt: '2026-05-05T12:30:00Z',
  updatedAt: '2026-05-06T12:30:00Z',
  ...request,
}

describe('admin lexeme form pages', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('creates lexemes with API contract fields only', async () => {
    const fetcher = vi.fn(async () => ({
      success: true,
      data: response,
      error: null,
    }) satisfies ApiEnvelope<unknown>)
    const client = createAdminLexemeApiClient({ fetcher })

    await client.createLexeme(request, 'admin-token')

    expect(fetcher).toHaveBeenCalledWith('/api/v1/admin/lexemes', {
      method: 'POST',
      headers: {
        Authorization: 'Bearer admin-token',
      },
      body: request,
    })
    expect(Object.keys(request)).not.toContain('normalizedSurface')
    expect(Object.keys(request)).not.toContain('privateSentenceContext')
    expect(Object.keys(request)).not.toContain('rawText')
  })

  it('updates lexemes with PATCH /api/v1/admin/lexemes/{lexemeId}', async () => {
    const fetcher = vi.fn(async () => ({
      success: true,
      data: response,
      error: null,
    }) satisfies ApiEnvelope<unknown>)
    const client = createAdminLexemeApiClient({ fetcher })

    await client.updateLexeme('lexeme-1', request, 'admin-token')

    expect(fetcher).toHaveBeenCalledWith('/api/v1/admin/lexemes/lexeme-1', {
      method: 'PATCH',
      headers: {
        Authorization: 'Bearer admin-token',
      },
      body: request,
    })
  })

  it.each([
    ['ADMIN_LEXEME_DUPLICATE', 'A lexeme with these values already exists.'],
    ['ADMIN_LEXEME_INVALID', 'Check the lexeme fields and try again.'],
  ])('maps %s to stable inline form error', async (code, expectedError) => {
    const client = createAdminLexemeApiClient({
      fetcher: async () => ({
        success: false,
        data: null,
        error: {
          code,
          message: 'raw backend message with token=secret',
        },
      }),
    })
    const store = useAdminLexemesStore()

    await store.createLexeme(request, { apiClient: client, accessToken: 'admin-token' })

    expect(store.formError).toBe(expectedError)
    expect(store.formError).not.toContain('secret')
  })

  it('defines form fields, license-safe example copy, and no private source inputs', async () => {
    const form = await readFile(resolve(process.cwd(), 'components/lexemes/LexemeForm.vue'), 'utf8')
    const newPage = await readFile(resolve(process.cwd(), 'pages/admin/lexemes/new.vue'), 'utf8')
    const editPage = await readFile(resolve(process.cwd(), 'pages/admin/lexemes/[id].vue'), 'utf8')

    for (const field of [
      'surface',
      'reading',
      'sourceLang',
      'targetLang',
      'entryType',
      'partOfSpeech',
      'definition',
      'shortDefinition',
      'example',
      'status',
    ]) {
      expect(form).toContain(field)
    }
    expect(form).toContain('license-safe')
    expect(form).toContain('admin-provided')
    expect(form).not.toContain('privateSentenceContext')
    expect(form).not.toContain('chapterContent')
    expect(form).not.toContain('rawText')
    expect(form).not.toContain('translatedText')
    expect(form).not.toContain('normalizedSurface')
    expect(newPage).toContain('AdminShell')
    expect(newPage).toContain('LexemeForm')
    expect(editPage).toContain('AdminShell')
    expect(editPage).toContain('LexemeForm')
  })
})
