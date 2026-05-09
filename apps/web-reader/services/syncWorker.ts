import { ofetch } from 'ofetch'

import { createWebReaderDb, type WebReaderDb } from '../db/webReaderDb'
import { createBookRepository } from '../repositories/bookRepository'
import { createLearningRepository } from '../repositories/learningRepository'
import { createPendingSyncRepository } from '../repositories/pendingSyncRepository'
import type { ReadingSyncApiClient } from './readingSyncApiClient'
import { createReadingSyncApiClient } from './readingSyncApiClient'
import type { StatsApiClient } from './statsApiClient'
import { createStatsApiClient } from './statsApiClient'
import type { ApiEnvelope } from '../types/api'
import { WebApiError } from '../types/api'
import type { JsonObject, WebCardType, WebPendingSyncEvent, WebPendingSyncEventType } from '../types/localData'

interface SyncWorkerInput {
  db?: WebReaderDb
  ownerUserId: string
  readingSyncApiClient?: ReadingSyncApiClient
  statsApiClient?: StatsApiClient
  vocabularyApiClient?: SyncVocabularyApiClient
}

interface SyncVocabularyApiClient {
  createLexemeCard(input: {
    lexemeId: string
    sourceBookFingerprint?: string
    sourceBookTitle?: string
  }): Promise<{ id: string }>
  createPrivateSentenceCard(input: {
    privateSurface: string
    privateDefinition: string
    privateContext?: string
    sourceBookFingerprint?: string
    sourceBookTitle?: string
  }): Promise<{ id: string }>
  reviewCard(cardId: string, input: { known: boolean, reviewedAt: string }): Promise<unknown>
}

export async function syncPendingEventsForCurrentUser(input: SyncWorkerInput): Promise<void> {
  const db = input.db ?? createWebReaderDb()
  const pendingSync = createPendingSyncRepository(db)
  const events = (await pendingSync.listPendingByOwner(input.ownerUserId)).sort(compareEvents)
  const clients = {
    reading: input.readingSyncApiClient ?? createReadingSyncApiClient(),
    stats: input.statsApiClient ?? createStatsApiClient(),
    vocabulary: input.vocabularyApiClient ?? createDefaultVocabularySyncClient(),
  }

  for (const event of events) {
    try {
      const synced = await syncEvent(db, event, clients)
      if (synced) {
        await pendingSync.markDone(event.id)
      }
    }
    catch (error) {
      await pendingSync.markFailed(event.id, errorCode(error))
    }
  }
}

async function syncEvent(
  db: WebReaderDb,
  event: WebPendingSyncEvent,
  clients: {
    reading: ReadingSyncApiClient
    stats: StatsApiClient
    vocabulary: SyncVocabularyApiClient
  },
): Promise<boolean> {
  switch (event.eventType) {
    case 'book_metadata':
      await syncBookMetadata(db, event.payloadJson, clients.reading)
      return true
    case 'reading_progress':
      await syncReadingProgress(db, event.payloadJson, clients.reading)
      return true
    case 'word_card_create':
      await syncWordCardCreate(db, event.payloadJson, clients.vocabulary)
      return true
    case 'word_card_review':
      return syncWordCardReview(db, event.payloadJson, clients.vocabulary)
    case 'daily_stats':
      await clients.stats.addDailyStats({
        statDate: requireString(event.payloadJson, 'statDate'),
        readingMinutes: requireNumber(event.payloadJson, 'readingMinutes'),
        lookupCount: requireNumber(event.payloadJson, 'lookupCount'),
        paragraphTranslationCount: requireNumber(event.payloadJson, 'paragraphTranslationCount'),
        cardsCreated: requireNumber(event.payloadJson, 'cardsCreated'),
        cardsReviewed: requireNumber(event.payloadJson, 'cardsReviewed'),
      })
      return true
  }
}

async function syncBookMetadata(
  db: WebReaderDb,
  payload: JsonObject,
  client: ReadingSyncApiClient,
): Promise<void> {
  const localBookId = optionalString(payload, 'localBookId')
  const localBook = localBookId ? await createBookRepository(db).findById(localBookId) : undefined
  await client.upsertBookMetadata({
    bookFingerprint: optionalString(payload, 'fingerprint') ?? localBook?.bookFingerprint ?? requireString(payload, 'bookFingerprint'),
    title: optionalString(payload, 'title') ?? localBook?.title ?? '',
    author: optionalString(payload, 'author') ?? localBook?.author,
    fileType: (optionalString(payload, 'fileType') ?? localBook?.fileType) === 'epub' ? 'epub' : 'txt',
    sourceLang: optionalString(payload, 'sourceLang') ?? localBook?.sourceLang ?? 'ja',
    targetLang: optionalString(payload, 'targetLang') ?? localBook?.targetLang ?? 'zh-CN',
    chapterCount: optionalNumber(payload, 'chapterCount') ?? localBook?.chapterCount ?? 1,
  })
}

async function syncReadingProgress(
  db: WebReaderDb,
  payload: JsonObject,
  client: ReadingSyncApiClient,
): Promise<void> {
  const localBookId = optionalString(payload, 'localBookId')
  const localBook = localBookId ? await createBookRepository(db).findById(localBookId) : undefined
  await client.updateReadingProgress({
    bookFingerprint: optionalString(payload, 'bookFingerprint') ?? localBook?.bookFingerprint ?? requireString(payload, 'fingerprint'),
    currentChapterIndex: requireNumber(payload, 'currentChapterIndex'),
    currentParagraphIndex: requireNumber(payload, 'currentParagraphIndex'),
    currentCharOffset: requireNumber(payload, 'currentCharOffset'),
    lastReadAt: optionalString(payload, 'lastReadAt'),
  })
}

async function syncWordCardCreate(
  db: WebReaderDb,
  payload: JsonObject,
  client: SyncVocabularyApiClient,
): Promise<void> {
  const localCardId = requireString(payload, 'localCardId')
  const cardType = requireCardType(payload)
  const learning = createLearningRepository(db)
  let result: { id: string }
  if (cardType === 'lexeme') {
    result = await client.createLexemeCard({
      lexemeId: requireString(payload, 'lexemeId'),
      sourceBookFingerprint: optionalString(payload, 'sourceBookFingerprint'),
      sourceBookTitle: optionalString(payload, 'sourceBookTitle'),
    })
  }
  else {
    result = await client.createPrivateSentenceCard({
      privateSurface: requireString(payload, 'privateSurface'),
      privateDefinition: requireString(payload, 'privateDefinition'),
      privateContext: optionalString(payload, 'privateContext'),
      sourceBookFingerprint: optionalString(payload, 'sourceBookFingerprint'),
      sourceBookTitle: optionalString(payload, 'sourceBookTitle'),
    })
  }
  await learning.updateWordCardServerId(localCardId, result.id)
}

async function syncWordCardReview(
  db: WebReaderDb,
  payload: JsonObject,
  client: SyncVocabularyApiClient,
): Promise<boolean> {
  const localCardId = requireString(payload, 'localCardId')
  const localCard = await db.web_word_cards.get(localCardId)
  const serverCardId = optionalString(payload, 'serverCardId') ?? localCard?.serverCardId
  if (!serverCardId) {
    return false
  }
  await client.reviewCard(serverCardId, {
    known: requireBoolean(payload, 'known'),
    reviewedAt: requireString(payload, 'reviewedAt'),
  })
  return true
}

function createDefaultVocabularySyncClient(): SyncVocabularyApiClient {
  return {
    createLexemeCard(input) {
      return request<{ id: string }>('/api/v1/vocabulary/cards', {
        method: 'POST',
        body: {
          cardType: 'lexeme',
          lexemeId: input.lexemeId,
          sourceBookFingerprint: input.sourceBookFingerprint,
          sourceBookTitle: input.sourceBookTitle,
        },
      })
    },
    createPrivateSentenceCard(input) {
      return request<{ id: string }>('/api/v1/vocabulary/cards', {
        method: 'POST',
        body: {
          cardType: 'private_sentence',
          privateSurface: input.privateSurface,
          privateDefinition: input.privateDefinition,
          privateContext: input.privateContext,
          sourceBookFingerprint: input.sourceBookFingerprint,
          sourceBookTitle: input.sourceBookTitle,
        },
      })
    },
    reviewCard(cardId, input) {
      return request(`/api/v1/vocabulary/cards/${cardId}/review`, {
        method: 'POST',
        body: input,
      })
    },
  }
}

async function request<T>(url: string, options: Record<string, unknown>): Promise<T> {
  const envelope = await ofetch(url, options) as ApiEnvelope<T>
  if (!envelope.success) {
    const error = envelope.error ?? { code: 'UNKNOWN_ERROR', message: 'Request failed' }
    throw new WebApiError(error.code, error.message)
  }
  if (envelope.data == null) {
    throw new WebApiError('WEB_INVALID_RESPONSE', 'Missing response data')
  }
  return envelope.data
}

function requireCardType(payload: JsonObject): WebCardType {
  const value = requireString(payload, 'cardType')
  if (value !== 'lexeme' && value !== 'private_sentence') {
    throw new WebApiError('WEB_SYNC_INVALID_PAYLOAD', 'Invalid cardType')
  }
  return value
}

function requireString(payload: JsonObject, key: string): string {
  const value = payload[key]
  if (typeof value !== 'string' || !value) {
    throw new WebApiError('WEB_SYNC_INVALID_PAYLOAD', `${key} is required`)
  }
  return value
}

function optionalString(payload: JsonObject, key: string): string | undefined {
  const value = payload[key]
  return typeof value === 'string' && value ? value : undefined
}

function requireNumber(payload: JsonObject, key: string): number {
  const value = payload[key]
  if (typeof value !== 'number' || value < 0) {
    throw new WebApiError('WEB_SYNC_INVALID_PAYLOAD', `${key} must be non-negative`)
  }
  return value
}

function optionalNumber(payload: JsonObject, key: string): number | undefined {
  const value = payload[key]
  return typeof value === 'number' && value >= 0 ? value : undefined
}

function requireBoolean(payload: JsonObject, key: string): boolean {
  const value = payload[key]
  if (typeof value !== 'boolean') {
    throw new WebApiError('WEB_SYNC_INVALID_PAYLOAD', `${key} must be boolean`)
  }
  return value
}

function errorCode(error: unknown): string {
  if (error instanceof WebApiError) {
    return error.code
  }
  return error instanceof Error && error.message ? error.message : 'UNKNOWN_ERROR'
}

function compareEvents(a: WebPendingSyncEvent, b: WebPendingSyncEvent): number {
  return eventPriority(a.eventType) - eventPriority(b.eventType)
    || a.createdAt.localeCompare(b.createdAt)
}

function eventPriority(eventType: WebPendingSyncEventType): number {
  switch (eventType) {
    case 'book_metadata':
      return 0
    case 'reading_progress':
      return 1
    case 'word_card_create':
      return 2
    case 'word_card_review':
      return 3
    case 'daily_stats':
      return 4
  }
}
