import 'fake-indexeddb/auto'

import { createPinia, setActivePinia } from 'pinia'
import { afterEach, beforeEach, describe, expect, it } from 'vitest'

import { createWebReaderDb, type WebReaderDb } from '../../db/webReaderDb'
import { createLearningRepository } from '../../repositories/learningRepository'
import { createStatsRepository } from '../../repositories/statsRepository'
import {
  resetVocabularyDependenciesForTesting,
  setVocabularyDependenciesForTesting,
  useVocabularyStore,
} from '../../stores/vocabulary'

describe('save vocabulary flow', () => {
  let db: WebReaderDb
  const ownerUserId = 'user-1'

  beforeEach(async () => {
    setActivePinia(createPinia())
    db = createWebReaderDb(`save-vocabulary-flow-${crypto.randomUUID()}`)
    await db.open()
  })

  afterEach(async () => {
    resetVocabularyDependenciesForTesting()
    await db.delete()
  })

  it('saves a public lexeme card online and increments cards created once', async () => {
    const createCalls: string[] = []
    setVocabularyDependenciesForTesting({
      db,
      vocabularyApiClient: {
        async createLexemeCard(input) {
          createCalls.push(input.lexemeId)
          return {
            id: 'server-card-1',
            cardType: 'lexeme',
            reviewStatus: 'new',
            reviewCount: 0,
            nextReviewAt: null,
          }
        },
        async createPrivateSentenceCard() {
          throw new Error('private sentence should not be called')
        },
      },
    })
    const vocabulary = useVocabularyStore()

    await vocabulary.savePublicLexemeCard({
      ownerUserId,
      lexeme: lexeme(),
      sourceBookFingerprint: 'd'.repeat(64),
      sourceBookTitle: 'Local Book',
    })
    await vocabulary.savePublicLexemeCard({
      ownerUserId,
      lexeme: lexeme(),
      sourceBookFingerprint: 'd'.repeat(64),
      sourceBookTitle: 'Local Book',
    })

    expect(createCalls).toEqual(['lexeme-1', 'lexeme-1'])
    const cards = await createLearningRepository(db).listWordCardsByOwner(ownerUserId)
    expect(cards).toHaveLength(1)
    expect(cards[0]).toMatchObject({
      cardType: 'lexeme',
      lexemeId: 'lexeme-1',
      syncStatus: 'synced',
      serverCardId: 'server-card-1',
    })
    const stats = await createStatsRepository(db).getDailyStats(ownerUserId, today())
    expect(stats?.cardsCreated).toBe(1)
  })

  it('saves translated paragraph as a private sentence card and does not cache it as a public lexeme', async () => {
    setVocabularyDependenciesForTesting({
      db,
      vocabularyApiClient: {
        async createLexemeCard() {
          throw new Error('lexeme should not be called')
        },
        async createPrivateSentenceCard() {
          return {
            id: 'server-private-1',
            cardType: 'private_sentence',
            reviewStatus: 'new',
            reviewCount: 0,
            nextReviewAt: null,
          }
        },
      },
    })
    const vocabulary = useVocabularyStore()

    await vocabulary.savePrivateSentenceCard({
      ownerUserId,
      surface: '私はその人を常に先生と呼んでいた。',
      definition: '我一直称那个人为先生。',
      sourceBookFingerprint: 'e'.repeat(64),
      sourceBookTitle: 'Local Book',
    })

    const privateCards = await createLearningRepository(db).listPrivateSentenceCardsByOwner(ownerUserId)
    expect(privateCards).toHaveLength(1)
    expect(privateCards[0]).toMatchObject({
      cardType: 'private_sentence',
      privateSurface: '私はその人を常に先生と呼んでいた。',
      privateDefinition: '我一直称那个人为先生。',
      syncStatus: 'synced',
    })
    await expect(db.web_lexeme_cache.toArray()).resolves.toHaveLength(0)
  })

  it('queues recoverable card creation failures without raw paragraph or translated text in payload', async () => {
    setVocabularyDependenciesForTesting({
      db,
      vocabularyApiClient: {
        async createLexemeCard() {
          throw new Error('offline')
        },
        async createPrivateSentenceCard() {
          throw new Error('offline')
        },
      },
    })
    const vocabulary = useVocabularyStore()

    await vocabulary.savePrivateSentenceCard({
      ownerUserId,
      surface: '私はその人を常に先生と呼んでいた。',
      definition: '我一直称那个人为先生。',
      sourceBookFingerprint: 'f'.repeat(64),
      sourceBookTitle: 'Local Book',
    })

    const events = await db.web_pending_sync_events.where('eventType').equals('word_card_create').toArray()
    expect(events).toHaveLength(1)
    expect(events[0]?.payloadJson).toMatchObject({
      cardType: 'private_sentence',
      sourceBookFingerprint: 'f'.repeat(64),
      sourceBookTitle: 'Local Book',
    })
    expect(JSON.stringify(events[0]?.payloadJson)).not.toMatch(
      /私はその人|我一直|paragraphText|translatedText|content|originalFileName|bytes|filePath|fullBook|fullChapter/i,
    )
  })
})

function lexeme() {
  return {
    id: 'lexeme-1',
    surface: '心',
    normalizedSurface: '心',
    reading: 'こころ',
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    entryType: 'word' as const,
    partOfSpeech: 'noun',
    definition: '心；内心；精神',
    shortDefinition: '心；内心',
    example: null,
    status: 'active' as const,
  }
}

function today(): string {
  return new Date().toISOString().slice(0, 10)
}
