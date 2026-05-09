import 'fake-indexeddb/auto'

import { createPinia, setActivePinia } from 'pinia'
import { afterEach, beforeEach, describe, expect, it } from 'vitest'

import { createWebReaderDb, type WebReaderDb } from '../../db/webReaderDb'
import { createBookRepository } from '../../repositories/bookRepository'
import { createChapterRepository } from '../../repositories/chapterRepository'
import { createLearningRepository } from '../../repositories/learningRepository'
import { createPendingSyncRepository } from '../../repositories/pendingSyncRepository'
import { createReadingPositionRepository } from '../../repositories/readingPositionRepository'
import { createStatsRepository } from '../../repositories/statsRepository'
import { importBookFile } from '../../services/bookImportService'
import { createReadingSyncApiClient } from '../../services/readingSyncApiClient'
import { createStatsApiClient } from '../../services/statsApiClient'
import { syncPendingEventsForCurrentUser } from '../../services/syncWorker'
import { useAuthStore } from '../../stores/auth'
import {
  resetLibraryDependenciesForTesting,
  setLibraryDependenciesForTesting,
  useLibraryStore,
} from '../../stores/library'
import {
  resetReaderDependenciesForTesting,
  setReaderDependenciesForTesting,
  useReaderStore,
} from '../../stores/reader'
import {
  resetStudyDependenciesForTesting,
  setStudyDependenciesForTesting,
  useStudyStore,
} from '../../stores/study'
import {
  resetVocabularyDependenciesForTesting,
  setVocabularyDependenciesForTesting,
  useVocabularyStore,
} from '../../stores/vocabulary'
import type { JsonObject, WebLexeme } from '../../types/localData'

const ownerUserId = 'user-privacy'
const selectedText = '心'
const selectedParagraph = '心だけを見つめる。'
const translatedParagraph = '只凝视内心。'
const secondParagraph = '二つ目の段落はここにある。'
const fullChapter = `第1章\n\n${selectedParagraph}\n\n${secondParagraph}`
const forbiddenValueFragments = [
  'privacy-fixture.txt',
  selectedParagraph,
  translatedParagraph,
  fullChapter,
  secondParagraph,
]
const forbiddenKeyPattern =
  /originalFileName|originalFile|fileName|filePath|bytes|content|chapterContent|paragraphText|selectedText|translatedText|fullBook|fullChapter/i

describe('web reader privacy and local-first regression', () => {
  let db: WebReaderDb
  const httpRequests: Array<{ url: string, body: unknown }> = []

  beforeEach(async () => {
    setActivePinia(createPinia())
    httpRequests.length = 0
    db = createWebReaderDb(`web-reader-privacy-regression-${crypto.randomUUID()}`)
    await db.open()
    setSignedInUser()
    setLibraryDependenciesForTesting({
      listBooks(ownerId) {
        return createBookRepository(db).listByOwnerUserId(ownerId)
      },
      async importBook(input) {
        const result = await importBookFile({ ...input, db })
        return result.book
      },
    })
    setReaderDependenciesForTesting({ db })
    setStudyDependenciesForTesting({
      db,
      studyApiClient: {
        async lookup(input) {
          httpRequests.push({ url: '/api/v1/study/lookup', body: input })
          return {
            kind: 'lexeme',
            provider: 'public_lexeme',
            providerMessage: null,
            lexeme: lexeme(),
          }
        },
        async translateParagraph(input) {
          httpRequests.push({ url: '/api/v1/study/translate-paragraph', body: input })
          return {
            translatedText: translatedParagraph,
            provider: 'fake_provider',
            cached: false,
            message: null,
          }
        },
      },
    })
    setVocabularyDependenciesForTesting({
      db,
      vocabularyApiClient: {
        async createLexemeCard(input) {
          httpRequests.push({ url: '/api/v1/vocabulary/cards', body: { cardType: 'lexeme', ...input } })
          return {
            id: 'server-lexeme-card',
            cardType: 'lexeme',
            reviewStatus: 'new',
            reviewCount: 0,
            nextReviewAt: null,
          }
        },
        async createPrivateSentenceCard(input) {
          httpRequests.push({ url: '/api/v1/vocabulary/cards', body: { cardType: 'private_sentence', ...input } })
          throw new Error('offline')
        },
      },
    })
  })

  afterEach(async () => {
    resetLibraryDependenciesForTesting()
    resetReaderDependenciesForTesting()
    resetStudyDependenciesForTesting()
    resetVocabularyDependenciesForTesting()
    await db.delete()
  })

  it('keeps imported books local while lookup, translation, review, stats, and sync use privacy-safe payloads', async () => {
    const library = useLibraryStore()
    const file = new File([fullChapter], 'privacy-fixture.txt', { type: 'text/plain' })

    await library.importLocalFile({ file, ownerUserId, sourceLang: 'ja', targetLang: 'zh-CN' })

    expect(library.books).toHaveLength(1)
    expect(library.books[0]?.title).toBe('privacy-fixture')
    const book = library.books[0]
    expect(book?.originalFileName).toBe('privacy-fixture.txt')
    const chapters = await createChapterRepository(db).listByBookId(book!.id)
    expect(chapters[0]?.content).toContain(selectedParagraph)
    assertPendingPayloadsArePrivacySafe(await pendingPayloads())

    const reader = useReaderStore()
    await reader.openBook(book!.id)
    expect(reader.currentChapter?.content).toContain(selectedParagraph)
    await reader.moveToChapter(0)
    const position = await createReadingPositionRepository(db).findByBookId(book!.id)
    expect(position).toMatchObject({
      currentChapterIndex: 0,
      progressSyncStatus: 'dirty',
    })

    const study = useStudyStore()
    await study.lookupSelectedText({
      ownerUserId,
      text: selectedText,
      paragraphContext: undefined,
      sourceLang: 'ja',
      targetLang: 'zh-CN',
    })
    await study.translateParagraph({
      ownerUserId,
      paragraph: selectedParagraph,
      sourceLang: 'ja',
      targetLang: 'zh-CN',
    })

    const lookupBody = requestBody('/api/v1/study/lookup')
    expect(lookupBody).toMatchObject({ text: selectedText })
    expect(lookupBody).not.toHaveProperty('context')
    expectPayloadDoesNotContain(lookupBody, [fullChapter, selectedParagraph, secondParagraph])
    const translationBody = requestBody('/api/v1/study/translate-paragraph')
    expect(translationBody).toMatchObject({ text: selectedParagraph })
    expect(Array.isArray((translationBody as { text: unknown }).text)).toBe(false)
    expectPayloadDoesNotContain(translationBody, [fullChapter, secondParagraph])

    const vocabulary = useVocabularyStore()
    await vocabulary.savePublicLexemeCard({
      ownerUserId,
      lexeme: lexeme(),
      sourceBookFingerprint: book!.bookFingerprint,
      sourceBookTitle: book!.title,
    })
    await vocabulary.savePrivateSentenceCard({
      ownerUserId,
      surface: selectedParagraph,
      definition: translatedParagraph,
      context: fullChapter,
      sourceBookFingerprint: book!.bookFingerprint,
      sourceBookTitle: book!.title,
    })

    const learning = createLearningRepository(db)
    const cards = await learning.listWordCardsByOwner(ownerUserId)
    expect(cards.filter((card) => card.cardType === 'lexeme')).toHaveLength(1)
    expect(cards.filter((card) => card.cardType === 'private_sentence')).toHaveLength(1)
    expect(await db.web_lexeme_cache.toArray()).toHaveLength(1)
    const privateCreateEvents = (await db.web_pending_sync_events.toArray())
      .filter((event) => event.eventType === 'word_card_create' && event.payloadJson.cardType === 'private_sentence')
    expect(privateCreateEvents).toHaveLength(1)
    assertPendingPayloadsArePrivacySafe(privateCreateEvents.map((event) => event.payloadJson))

    const lexemeCard = cards.find((card) => card.cardType === 'lexeme')
    await vocabulary.reviewCard({
      ownerUserId,
      localCardId: lexemeCard!.id,
      known: true,
      reviewedAt: '2026-05-09T10:00:00.000Z',
    })
    const reviewedCard = await db.web_word_cards.get(lexemeCard!.id)
    expect(reviewedCard).toMatchObject({
      reviewStatus: 'reviewing',
      reviewCount: 1,
      syncStatus: 'dirty',
    })

    const stats = await createStatsRepository(db).getDailyStats(ownerUserId, today())
    expect(stats).toMatchObject({
      lookupCount: 1,
      paragraphTranslationCount: 1,
      cardsCreated: 2,
    })
    const reviewStats = await createStatsRepository(db).getDailyStats(ownerUserId, '2026-05-09')
    expect(reviewStats?.cardsReviewed).toBe(1)
    assertPendingPayloadsArePrivacySafe(await pendingPayloads())

    await enqueueDailyStatsSync()
    const syncRequests: Array<{ url: string, body: unknown }> = []
    await syncPendingEventsForCurrentUser({
      db,
      ownerUserId,
      readingSyncApiClient: createReadingSyncApiClient({ fetcher: syncFetcher(syncRequests) }),
      statsApiClient: createStatsApiClient({ fetcher: syncFetcher(syncRequests) }),
      vocabularyApiClient: {
        async createLexemeCard(input) {
          syncRequests.push({ url: '/api/v1/vocabulary/cards', body: { cardType: 'lexeme', ...input } })
          return { id: 'server-lexeme-card' }
        },
        async createPrivateSentenceCard(input) {
          syncRequests.push({ url: '/api/v1/vocabulary/cards', body: { cardType: 'private_sentence', ...input } })
          return { id: 'server-private-card' }
        },
        async reviewCard(cardId, input) {
          syncRequests.push({ url: `/api/v1/vocabulary/cards/${cardId}/review`, body: input })
          return {}
        },
      },
    })

    assertPendingPayloadsArePrivacySafe(await pendingPayloads())
    expectPayloadDoesNotContainKeys(syncRequests.map((request) => request.body))
    expectPayloadDoesNotContain(syncRequests, [
      'privacy-fixture.txt',
      fullChapter,
      secondParagraph,
      'fullBook',
      'fullChapter',
    ])
    expect(syncRequests.some((request) => request.url.includes('/api/v1/reading/books/'))).toBe(true)
    expect(syncRequests.some((request) => JSON.stringify(request.body).includes('currentChapterIndex'))).toBe(true)
    expect(syncRequests.some((request) => JSON.stringify(request.body).includes('cardsReviewed'))).toBe(true)
  })

  function requestBody(url: string): JsonObject {
    const request = httpRequests.find((item) => item.url === url)
    expect(request).toBeDefined()
    return request!.body as JsonObject
  }

  async function pendingPayloads(): Promise<JsonObject[]> {
    return (await createPendingSyncRepository(db).listPendingByOwner(ownerUserId))
      .map((event) => event.payloadJson)
  }

  async function enqueueDailyStatsSync(): Promise<void> {
    const stats = await createStatsRepository(db).getDailyStats(ownerUserId, today())
    await createPendingSyncRepository(db).enqueue({
      id: crypto.randomUUID(),
      ownerUserId,
      eventType: 'daily_stats',
      payloadJson: {
        statDate: today(),
        readingMinutes: stats?.readingMinutes ?? 0,
        lookupCount: stats?.lookupCount ?? 0,
        paragraphTranslationCount: stats?.paragraphTranslationCount ?? 0,
        cardsCreated: stats?.cardsCreated ?? 0,
        cardsReviewed: stats?.cardsReviewed ?? 0,
      },
      status: 'pending',
      attemptCount: 0,
    })
  }
})

function setSignedInUser(): void {
  const auth = useAuthStore()
  auth.user = {
    id: ownerUserId,
    email: 'reader@example.com',
    displayName: 'Reader',
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    status: 'active',
  }
}

function syncFetcher(requests: Array<{ url: string, body: unknown }>) {
  return async (url: string, options: Record<string, unknown>) => {
    requests.push({ url, body: options.body })
    return { success: true, data: {}, error: null }
  }
}

function assertPendingPayloadsArePrivacySafe(payloads: JsonObject[]): void {
  expectPayloadDoesNotContainKeys(payloads)
  expectPayloadDoesNotContain(payloads, forbiddenValueFragments)
}

function expectPayloadDoesNotContainKeys(payload: unknown): void {
  const keys = collectKeys(payload)
  expect(keys.join(' ')).not.toMatch(forbiddenKeyPattern)
}

function expectPayloadDoesNotContain(payload: unknown, fragments: string[]): void {
  const serialized = JSON.stringify(payload)
  for (const fragment of fragments) {
    expect(serialized).not.toContain(fragment)
  }
}

function collectKeys(value: unknown): string[] {
  if (Array.isArray(value)) {
    return value.flatMap(collectKeys)
  }
  if (value && typeof value === 'object') {
    return Object.entries(value).flatMap(([key, child]) => [key, ...collectKeys(child)])
  }
  return []
}

function lexeme(): Omit<WebLexeme, 'createdAt' | 'updatedAt'> {
  return {
    id: 'lexeme-heart',
    surface: selectedText,
    normalizedSurface: selectedText,
    reading: 'こころ',
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    entryType: 'word',
    partOfSpeech: 'noun',
    definition: '内心',
    shortDefinition: '心',
    example: null,
    status: 'active',
  }
}

function today(): string {
  return new Date().toISOString().slice(0, 10)
}
