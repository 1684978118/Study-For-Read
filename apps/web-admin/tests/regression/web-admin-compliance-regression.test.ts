import { createPinia, setActivePinia } from 'pinia'
import { readFile } from 'node:fs/promises'
import { resolve } from 'node:path'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import adminAuthMiddleware from '../../middleware/admin-auth.global'
import { renderRedactedDetails } from '../../services/adminManagementApiClient'
import { useAdminAuthStore } from '../../stores/adminAuth'

const forbiddenTerms = [
  'content',
  'chapterContent',
  'chapter_content',
  'originalFile',
  'original_file',
  'filePath',
  'file_path',
  'sourceText',
  'source_text',
  'rawText',
  'raw_text',
  'translatedText',
  'translated_text',
  'paragraphText',
  'paragraph_text',
  'passwordHash',
  'password_hash',
  'tokenHash',
  'token_hash',
  'password',
  'token',
  'privateSentenceContext',
  'private_sentence_context',
  'user_private',
  'raw book content',
  'private sentence context',
  'raw translated text',
]

const source = (path: string) => readFile(resolve(process.cwd(), path), 'utf8')

describe('web admin compliance regression', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('redirects signed-out admins away from protected admin pages', async () => {
    const store = useAdminAuthStore()
    const navigateTo = vi.fn((path: string) => path)
    vi.stubGlobal('navigateTo', navigateTo)

    for (const path of [
      '/admin',
      '/admin/users',
      '/admin/stats',
      '/admin/audit-logs',
      '/admin/lexemes',
      '/admin/lexemes/new',
      '/admin/lexemes/lexeme-1',
    ]) {
      const result = await adminAuthMiddleware(
        { path },
        { path: '/admin/sign-in' },
        {
          authStore: store,
          restore: async () => undefined,
        },
      )
      expect(result).toBe('/admin/sign-in')
    }

    expect(navigateTo).toHaveBeenCalledTimes(7)
    vi.unstubAllGlobals()
  })

  it('keeps dashboard metrics limited to aggregate counters', async () => {
    const metricGrid = await source('components/admin/AdminMetricGrid.vue')

    for (const allowed of [
      'userCount',
      'activeUserCount',
      'disabledUserCount',
      'bookMetadataCount',
      'lexemeCount',
      'wordCardCount',
      'readingMinutes',
      'lookupCount',
      'paragraphTranslationCount',
      'cardsCreated',
      'cardsReviewed',
    ]) {
      expect(metricGrid).toContain(allowed)
    }

    expect(metricGrid).not.toContain('rawText')
    expect(metricGrid).not.toContain('translatedText')
    expect(metricGrid).not.toContain('passwordHash')
    expect(metricGrid).not.toContain('privateSentenceContext')
  })

  it('user table renders only user metadata fields', async () => {
    const userTable = await source('components/admin/AdminUsersTable.vue')

    for (const allowed of [
      'user.email',
      'user.displayName',
      'user.sourceLang',
      'user.targetLang',
      'user.status',
      'user.createdAt',
      'user.updatedAt',
    ]) {
      expect(userTable).toContain(allowed)
    }

    for (const forbidden of [
      'passwordHash',
      'tokenHash',
      'content',
      'chapterContent',
      'privateSentenceContext',
    ]) {
      expect(userTable).not.toContain(forbidden)
    }
  })

  it('audit log details redact forbidden keys and forbidden content values', () => {
    const rendered = renderRedactedDetails({
      surface: 'public lexeme',
      sourceLang: 'ja',
      content: 'raw book content',
      chapterContent: 'chapter text',
      chapter_content: 'chapter text',
      originalFile: 'book.txt',
      original_file: 'book.txt',
      filePath: 'C:/private/book.txt',
      file_path: 'C:/private/book.txt',
      sourceText: 'raw source',
      source_text: 'raw source',
      rawText: 'raw lookup',
      raw_text: 'raw lookup',
      translatedText: 'raw translated text',
      translated_text: 'raw translated text',
      paragraphText: 'paragraph',
      paragraph_text: 'paragraph',
      passwordHash: 'hash',
      password_hash: 'hash',
      tokenHash: 'hash',
      token_hash: 'hash',
      password: 'secret',
      token: 'secret',
      privateSentenceContext: 'private sentence context',
      private_sentence_context: 'private sentence context',
      source: 'user_private',
      note: 'raw book content',
      translation: 'raw translated text',
    })

    expect(rendered).toContain('surface: public lexeme')
    expect(rendered).toContain('sourceLang: ja')
    for (const forbidden of forbiddenTerms) {
      expect(rendered).not.toContain(forbidden)
    }
  })

  it('lexeme pages and form do not expose private source or raw content fields', async () => {
    const files = await Promise.all([
      source('components/lexemes/LexemeForm.vue'),
      source('components/lexemes/LexemeTable.vue'),
      source('components/lexemes/LexemeFilters.vue'),
      source('components/lexemes/LexemeRejectDialog.vue'),
      source('pages/admin/lexemes/index.vue'),
      source('pages/admin/lexemes/new.vue'),
      source('pages/admin/lexemes/[id].vue'),
    ])
    const combined = files.join('\n')

    for (const allowed of [
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
      expect(combined).toContain(allowed)
    }
    expect(combined).toContain('license-safe')
    expect(combined).toContain('admin-provided')

    for (const forbidden of [
      'privateSentenceContext',
      'private_sentence_context',
      'user_private',
      'chapterContent',
      'chapter_content',
      'originalFile',
      'original_file',
      'filePath',
      'file_path',
      'sourceText',
      'source_text',
      'rawText',
      'raw_text',
      'translatedText',
      'translated_text',
      'paragraphText',
      'paragraph_text',
      'passwordHash',
      'password_hash',
      'tokenHash',
      'token_hash',
    ]) {
      expect(combined).not.toContain(forbidden)
    }
  })
})
