import 'fake-indexeddb/auto'

import { afterEach, beforeEach, describe, expect, it } from 'vitest'

import { createWebReaderDb, type WebReaderDb } from '../../db/webReaderDb'
import { createLearningRepository } from '../../repositories/learningRepository'
import { createStatsRepository } from '../../repositories/statsRepository'
import type { WebLexeme, WebWordCardDraft } from '../../types/localData'

describe('learning and stats repositories', () => {
  let db: WebReaderDb

  beforeEach(async () => {
    db = createWebReaderDb('learning-repository-test')
    await db.open()
  })

  afterEach(async () => {
    await db.delete()
  })

  it('keeps public lexeme cache separate from private sentence cards', async () => {
    const learning = createLearningRepository(db)

    await learning.upsertLexeme(lexeme())
    await learning.upsertWordCard(wordCard({
      id: 'lexeme-card',
      cardType: 'lexeme',
      lexemeId: 'lexeme-1',
    }))
    await learning.upsertWordCard(wordCard({
      id: 'private-card',
      cardType: 'private_sentence',
      lexemeId: undefined,
      privateSurface: '私だけの例文',
      privateDefinition: 'Only my sentence',
      privateContext: 'Private browser-local context',
    }))

    await expect(learning.getLexemeById('lexeme-1')).resolves.toMatchObject({
      surface: '心',
      reading: 'こころ',
    })
    await expect(learning.getLexemeById('private-card')).resolves.toBeUndefined()
    await expect(learning.listWordCardsByOwner('user-1')).resolves.toHaveLength(2)
    await expect(learning.listPrivateSentenceCardsByOwner('user-1')).resolves.toEqual([
      expect.objectContaining({ id: 'private-card', privateContext: 'Private browser-local context' }),
    ])
  })

  it('rejects invalid word-card shapes', async () => {
    const learning = createLearningRepository(db)

    await expect(
      learning.upsertWordCard(wordCard({ id: 'bad-lexeme', cardType: 'lexeme', lexemeId: undefined })),
    ).rejects.toThrow(/lexemeId/)
    await expect(
      learning.upsertWordCard(wordCard({
        id: 'bad-private',
        cardType: 'private_sentence',
        lexemeId: undefined,
        privateSurface: '',
        privateDefinition: '',
      })),
    ).rejects.toThrow(/privateSurface/)
  })

  it('increments non-negative stats counters by owner and date', async () => {
    const stats = createStatsRepository(db)

    await stats.incrementDailyStats('user-1', '2026-05-09', {
      readingMinutes: 2,
      lookupCount: 1,
      paragraphTranslationCount: 1,
      cardsCreated: 1,
      cardsReviewed: 0,
    })
    await stats.incrementDailyStats('user-1', '2026-05-09', {
      readingMinutes: 3,
      lookupCount: 2,
      paragraphTranslationCount: 0,
      cardsCreated: 0,
      cardsReviewed: 1,
    })
    await expect(stats.incrementDailyStats('user-1', '2026-05-09', {
      readingMinutes: -1,
      lookupCount: 0,
      paragraphTranslationCount: 0,
      cardsCreated: 0,
      cardsReviewed: 0,
    })).rejects.toThrow(/non-negative/)

    await expect(stats.getDailyStats('user-1', '2026-05-09')).resolves.toMatchObject({
      readingMinutes: 5,
      lookupCount: 3,
      paragraphTranslationCount: 1,
      cardsCreated: 1,
      cardsReviewed: 1,
    })
  })
})

function lexeme(): WebLexeme {
  return {
    id: 'lexeme-1',
    surface: '心',
    normalizedSurface: '心',
    reading: 'こころ',
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    entryType: 'word',
    partOfSpeech: 'noun',
    definition: 'heart; mind',
    shortDefinition: 'heart',
    example: null,
    status: 'active',
    createdAt: '2026-05-09T00:00:00.000Z',
    updatedAt: '2026-05-09T00:00:00.000Z',
  }
}

function wordCard(overrides: Partial<WebWordCardDraft>): WebWordCardDraft {
  return {
    id: 'card-1',
    ownerUserId: 'user-1',
    cardType: 'lexeme',
    lexemeId: 'lexeme-1',
    privateSurface: undefined,
    privateDefinition: undefined,
    privateContext: undefined,
    sourceBookFingerprint: 'a'.repeat(64),
    sourceBookTitle: 'Kokoro',
    reviewStatus: 'new',
    reviewCount: 0,
    syncStatus: 'local_only',
    serverCardId: undefined,
    nextReviewAt: undefined,
    lastReviewedAt: undefined,
    ...overrides,
  }
}
