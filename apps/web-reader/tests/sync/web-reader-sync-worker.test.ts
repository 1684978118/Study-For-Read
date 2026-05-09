import 'fake-indexeddb/auto'

import { afterEach, beforeEach, describe, expect, it } from 'vitest'

import { createWebReaderDb, type WebReaderDb } from '../../db/webReaderDb'
import { createBookRepository } from '../../repositories/bookRepository'
import { createLearningRepository } from '../../repositories/learningRepository'
import { createPendingSyncRepository } from '../../repositories/pendingSyncRepository'
import { createReadingPositionRepository } from '../../repositories/readingPositionRepository'
import { createStatsRepository } from '../../repositories/statsRepository'
import { createReadingSyncApiClient } from '../../services/readingSyncApiClient'
import { createStatsApiClient } from '../../services/statsApiClient'
import { syncPendingEventsForCurrentUser } from '../../services/syncWorker'
import type { WebBookDraft, WebLexeme, WebWordCardDraft } from '../../types/localData'

describe('web reader sync worker', () => {
  let db: WebReaderDb
  const ownerUserId = 'user-1'

  beforeEach(async () => {
    db = createWebReaderDb(`web-reader-sync-worker-${crypto.randomUUID()}`)
    await db.open()
  })

  afterEach(async () => {
    await db.delete()
  })

  it('sends reading sync and stats requests through fake HTTP without private content fields', async () => {
    const requests: Array<{ url: string, options: Record<string, unknown> }> = []
    const fetcher = async (url: string, options: Record<string, unknown>) => {
      requests.push({ url, options })
      return { success: true, data: {}, error: null }
    }
    const reading = createReadingSyncApiClient({ fetcher })
    const stats = createStatsApiClient({ fetcher })

    await reading.upsertBookMetadata({
      bookFingerprint: 'a'.repeat(64),
      title: 'Kokoro',
      author: 'Natsume Soseki',
      fileType: 'txt',
      sourceLang: 'ja',
      targetLang: 'zh-CN',
      chapterCount: 2,
    })
    await reading.updateReadingProgress({
      bookFingerprint: 'a'.repeat(64),
      currentChapterIndex: 1,
      currentParagraphIndex: 2,
      currentCharOffset: 3,
      lastReadAt: '2026-05-09T10:00:00.000Z',
    })
    await stats.addDailyStats({
      statDate: '2026-05-09',
      readingMinutes: 1,
      lookupCount: 2,
      paragraphTranslationCount: 3,
      cardsCreated: 4,
      cardsReviewed: 5,
    })

    expect(requests.map((request) => request.url)).toEqual([
      `/api/v1/reading/books/${'a'.repeat(64)}`,
      `/api/v1/reading/books/${'a'.repeat(64)}/progress`,
      '/api/v1/stats/daily',
    ])
    expect(requests.map((request) => request.options.method)).toEqual(['PUT', 'PATCH', 'POST'])
    expect(JSON.stringify(requests.map((request) => request.options.body))).not.toMatch(
      /originalFileName|originalFile|filePath|bytes|content|chapterContent|paragraphText|selectedText|translatedText|fullBook|fullChapter/i,
    )
  })

  it('syncs pending metadata, progress, cards, reviews, and daily stats then marks events done', async () => {
    await seedSyncData(db)
    const pending = createPendingSyncRepository(db)
    await pending.enqueue({
      id: 'event-book',
      ownerUserId,
      eventType: 'book_metadata',
      payloadJson: {
        localBookId: 'book-1',
        fingerprint: 'a'.repeat(64),
        title: 'Kokoro',
        author: 'Natsume Soseki',
        fileType: 'txt',
        sourceLang: 'ja',
        targetLang: 'zh-CN',
        chapterCount: 2,
      },
      status: 'pending',
      attemptCount: 0,
    })
    await pending.enqueue({
      id: 'event-progress',
      ownerUserId,
      eventType: 'reading_progress',
      payloadJson: {
        localBookId: 'book-1',
        bookFingerprint: 'a'.repeat(64),
        currentChapterIndex: 1,
        currentParagraphIndex: 0,
        currentCharOffset: 0,
        lastReadAt: '2026-05-09T10:00:00.000Z',
      },
      status: 'pending',
      attemptCount: 0,
    })
    await pending.enqueue({
      id: 'event-create',
      ownerUserId,
      eventType: 'word_card_create',
      payloadJson: {
        localCardId: 'card-1',
        cardType: 'lexeme',
        lexemeId: 'lexeme-1',
        sourceBookFingerprint: 'a'.repeat(64),
        sourceBookTitle: 'Kokoro',
      },
      status: 'pending',
      attemptCount: 0,
    })
    await pending.enqueue({
      id: 'event-review',
      ownerUserId,
      eventType: 'word_card_review',
      payloadJson: {
        localCardId: 'card-1',
        serverCardId: 'server-card-1',
        known: true,
        reviewedAt: '2026-05-09T10:00:00.000Z',
        reviewStatus: 'reviewing',
        reviewCount: 1,
        nextReviewAt: '2026-05-12T10:00:00.000Z',
        lastReviewedAt: '2026-05-09T10:00:00.000Z',
      },
      status: 'pending',
      attemptCount: 0,
    })
    await pending.enqueue({
      id: 'event-stats',
      ownerUserId,
      eventType: 'daily_stats',
      payloadJson: {
        statDate: '2026-05-09',
        readingMinutes: 1,
        lookupCount: 2,
        paragraphTranslationCount: 3,
        cardsCreated: 4,
        cardsReviewed: 5,
      },
      status: 'pending',
      attemptCount: 0,
    })
    await pending.enqueue({
      id: 'event-other-user',
      ownerUserId: 'user-2',
      eventType: 'daily_stats',
      payloadJson: {
        statDate: '2026-05-09',
        readingMinutes: 99,
        lookupCount: 0,
        paragraphTranslationCount: 0,
        cardsCreated: 0,
        cardsReviewed: 0,
      },
      status: 'pending',
      attemptCount: 0,
    })
    const requests: Array<{ url: string, body: unknown }> = []
    const worker = syncPendingEventsForCurrentUser({
      db,
      ownerUserId,
      readingSyncApiClient: createReadingSyncApiClient({ fetcher: successfulFetcher(requests) }),
      statsApiClient: createStatsApiClient({ fetcher: successfulFetcher(requests) }),
      vocabularyApiClient: {
        async createLexemeCard(input) {
          requests.push({ url: '/api/v1/vocabulary/cards', body: { cardType: 'lexeme', ...input } })
          return { id: 'server-card-1', cardType: 'lexeme', reviewStatus: 'new', reviewCount: 0 }
        },
        async createPrivateSentenceCard() {
          throw new Error('private create should not be called')
        },
        async reviewCard(cardId, input) {
          requests.push({ url: `/api/v1/vocabulary/cards/${cardId}/review`, body: input })
          return {
            id: cardId,
            reviewStatus: 'reviewing',
            reviewCount: 1,
            nextReviewAt: '2026-05-12T10:00:00.000Z',
            lastReviewedAt: '2026-05-09T10:00:00.000Z',
          }
        },
      },
    })

    await worker

    expect(requests.map((request) => request.url)).toEqual([
      `/api/v1/reading/books/${'a'.repeat(64)}`,
      `/api/v1/reading/books/${'a'.repeat(64)}/progress`,
      '/api/v1/vocabulary/cards',
      '/api/v1/vocabulary/cards/server-card-1/review',
      '/api/v1/stats/daily',
    ])
    expect(JSON.stringify(requests.map((request) => request.body))).not.toMatch(
      /originalFileName|originalFile|filePath|bytes|content|chapterContent|paragraphText|selectedText|translatedText|fullBook|fullChapter/i,
    )
    const syncedCard = await db.web_word_cards.get('card-1')
    expect(syncedCard?.serverCardId).toBe('server-card-1')
    const events = await db.web_pending_sync_events.toArray()
    expect(events.find((event) => event.id === 'event-other-user')?.status).toBe('pending')
    expect(events.filter((event) => event.ownerUserId === ownerUserId).every((event) => event.status === 'done')).toBe(true)
  })

  it('keeps review events pending when server card id is missing and records retryable failures', async () => {
    await seedSyncData(db, { serverCardId: undefined })
    const pending = createPendingSyncRepository(db)
    await pending.enqueue({
      id: 'event-review-no-server',
      ownerUserId,
      eventType: 'word_card_review',
      payloadJson: {
        localCardId: 'card-1',
        known: true,
        reviewedAt: '2026-05-09T10:00:00.000Z',
        reviewStatus: 'reviewing',
        reviewCount: 1,
        nextReviewAt: '2026-05-12T10:00:00.000Z',
        lastReviewedAt: '2026-05-09T10:00:00.000Z',
      },
      status: 'pending',
      attemptCount: 0,
    })
    await pending.enqueue({
      id: 'event-stats-fail',
      ownerUserId,
      eventType: 'daily_stats',
      payloadJson: {
        statDate: '2026-05-09',
        readingMinutes: 1,
        lookupCount: 0,
        paragraphTranslationCount: 0,
        cardsCreated: 0,
        cardsReviewed: 0,
      },
      status: 'pending',
      attemptCount: 0,
    })

    await syncPendingEventsForCurrentUser({
      db,
      ownerUserId,
      readingSyncApiClient: createReadingSyncApiClient({ fetcher: async () => ({ success: true, data: {}, error: null }) }),
      statsApiClient: createStatsApiClient({
        fetcher: async () => ({ success: false, data: null, error: { code: 'RATE_LIMITED', message: 'try later' } }),
      }),
      vocabularyApiClient: {
        async createLexemeCard() {
          throw new Error('create should not be called')
        },
        async createPrivateSentenceCard() {
          throw new Error('private create should not be called')
        },
        async reviewCard() {
          throw new Error('review should not be called without server card id')
        },
      },
    })

    const reviewEvent = await db.web_pending_sync_events.get('event-review-no-server')
    expect(reviewEvent?.status).toBe('pending')
    expect(reviewEvent?.attemptCount).toBe(0)
    const failedEvent = await db.web_pending_sync_events.get('event-stats-fail')
    expect(failedEvent).toMatchObject({
      status: 'failed',
      attemptCount: 1,
      lastErrorCode: 'RATE_LIMITED',
    })
  })
})

function successfulFetcher(requests: Array<{ url: string, body: unknown }>) {
  return async (url: string, options: Record<string, unknown>) => {
    requests.push({ url, body: options.body })
    return { success: true, data: {}, error: null }
  }
}

async function seedSyncData(db: WebReaderDb, cardOverrides: Partial<WebWordCardDraft> = {}) {
  await createBookRepository(db).upsertByOwnerAndFingerprint(bookDraft())
  await createReadingPositionRepository(db).upsert({
    id: 'position-1',
    bookId: 'book-1',
    currentChapterIndex: 1,
    currentParagraphIndex: 0,
    currentCharOffset: 0,
    progressSyncStatus: 'dirty',
    lastReadAt: '2026-05-09T10:00:00.000Z',
  })
  await createLearningRepository(db).upsertLexeme(lexeme())
  await createLearningRepository(db).upsertWordCard({
    id: 'card-1',
    ownerUserId: 'user-1',
    cardType: 'lexeme',
    lexemeId: 'lexeme-1',
    sourceBookFingerprint: 'a'.repeat(64),
    sourceBookTitle: 'Kokoro',
    reviewStatus: 'reviewing',
    reviewCount: 1,
    syncStatus: 'dirty',
    serverCardId: 'server-card-1',
    ...cardOverrides,
  })
  await createStatsRepository(db).incrementDailyStats('user-1', '2026-05-09', {
    readingMinutes: 1,
    lookupCount: 2,
    paragraphTranslationCount: 3,
    cardsCreated: 4,
    cardsReviewed: 5,
  })
}

function bookDraft(): WebBookDraft {
  return {
    id: 'book-1',
    ownerUserId: 'user-1',
    bookFingerprint: 'a'.repeat(64),
    title: 'Kokoro',
    author: 'Natsume Soseki',
    fileType: 'txt',
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    originalFileName: 'kokoro.txt',
    chapterCount: 2,
    metadataSyncStatus: 'local_only',
  }
}

function lexeme(): WebLexeme {
  return {
    id: 'lexeme-1',
    surface: '心',
    normalizedSurface: '心',
    reading: 'こころ',
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    entryType: 'word',
    definition: '内心',
    status: 'active',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  }
}
