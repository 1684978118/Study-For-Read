import 'fake-indexeddb/auto'

import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { afterEach, beforeEach, describe, expect, it } from 'vitest'

import VocabularyPage from '../../pages/vocabulary.vue'
import VocabularyCardTile from '../../components/vocabulary/VocabularyCardTile.vue'
import { createWebReaderDb, type WebReaderDb } from '../../db/webReaderDb'
import { createLearningRepository } from '../../repositories/learningRepository'
import { createStatsRepository } from '../../repositories/statsRepository'
import { scheduleReview } from '../../services/reviewScheduler'
import {
  resetVocabularyDependenciesForTesting,
  setVocabularyDependenciesForTesting,
  useVocabularyStore,
} from '../../stores/vocabulary'
import { useAuthStore } from '../../stores/auth'
import type { WebLexeme, WebWordCardDraft } from '../../types/localData'

describe('web vocabulary review', () => {
  let db: WebReaderDb
  const ownerUserId = 'user-1'
  const reviewedAt = '2026-05-09T10:00:00.000Z'

  beforeEach(async () => {
    setActivePinia(createPinia())
    db = createWebReaderDb(`vocabulary-review-${crypto.randomUUID()}`)
    await db.open()
    setVocabularyDependenciesForTesting({
      db,
      vocabularyApiClient: {
        async createLexemeCard() {
          throw new Error('create should not run during review')
        },
        async createPrivateSentenceCard() {
          throw new Error('create should not run during review')
        },
      },
    })
  })

  afterEach(async () => {
    resetVocabularyDependenciesForTesting()
    await db.delete()
  })

  it('schedules unknown and repeated known reviews with first-release intervals', () => {
    expect(scheduleReview({ known: false, reviewCount: 0, reviewedAt })).toMatchObject({
      reviewStatus: 'learning',
      reviewCount: 1,
      nextReviewAt: '2026-05-10T10:00:00.000Z',
    })
    expect(scheduleReview({ known: true, reviewCount: 0, reviewedAt })).toMatchObject({
      reviewStatus: 'reviewing',
      reviewCount: 1,
      nextReviewAt: '2026-05-12T10:00:00.000Z',
    })
    expect(scheduleReview({ known: true, reviewCount: 1, reviewedAt }).nextReviewAt)
      .toBe('2026-05-16T10:00:00.000Z')
    expect(scheduleReview({ known: true, reviewCount: 2, reviewedAt }).nextReviewAt)
      .toBe('2026-05-24T10:00:00.000Z')
    expect(scheduleReview({ known: true, reviewCount: 3, reviewedAt }).nextReviewAt)
      .toBe('2026-06-08T10:00:00.000Z')
  })

  it('reviews a local card offline, enqueues word_card_review, and increments cards reviewed', async () => {
    await seedLexemeCard(db, { serverCardId: 'server-card-1' })
    const vocabulary = useVocabularyStore()

    await vocabulary.loadForOwner(ownerUserId, { now: reviewedAt })
    await vocabulary.reviewCard({ ownerUserId, localCardId: 'card-1', known: true, reviewedAt })

    const cards = await createLearningRepository(db).listWordCardsByOwner(ownerUserId)
    expect(cards[0]).toMatchObject({
      id: 'card-1',
      reviewStatus: 'reviewing',
      reviewCount: 1,
      nextReviewAt: '2026-05-12T10:00:00.000Z',
      lastReviewedAt: reviewedAt,
      syncStatus: 'dirty',
    })
    const events = await db.web_pending_sync_events.where('eventType').equals('word_card_review').toArray()
    expect(events).toHaveLength(1)
    expect(events[0]?.payloadJson).toMatchObject({
      localCardId: 'card-1',
      serverCardId: 'server-card-1',
      known: true,
      reviewedAt,
      reviewStatus: 'reviewing',
      reviewCount: 1,
      nextReviewAt: '2026-05-12T10:00:00.000Z',
      lastReviewedAt: reviewedAt,
    })
    expect(JSON.stringify(events[0]?.payloadJson)).not.toMatch(/content|paragraphText|selectedText|translatedText|filePath|originalFile|fullBook|fullChapter/i)
    const stats = await createStatsRepository(db).getDailyStats(ownerUserId, '2026-05-09')
    expect(stats?.cardsReviewed).toBe(1)
  })

  it('shows due, all, and private sentence tabs from local cards', async () => {
    setSignedInUser()
    await seedLexemeCard(db, { nextReviewAt: '2026-05-01T00:00:00.000Z' })
    await createLearningRepository(db).upsertWordCard(privateSentenceCard())

    const wrapper = mount(VocabularyPage, {
      global: { stubs: ['NuxtLink'] },
    })
    await flushPromises()
    await flushPromises()

    expect(wrapper.text()).toContain('Due')
    expect(wrapper.text()).toContain('All')
    expect(wrapper.text()).toContain('Private Sentences')
    expect(wrapper.text()).toContain('心')

    await wrapper.get('[data-testid="tab-private_sentence"]').trigger('click')
    await flushPromises()

    expect(wrapper.text()).toContain('私だけの文')
    expect(wrapper.text()).not.toContain('心')
  })

  it('renders known and unknown review actions on a card tile', async () => {
    const wrapper = mount(VocabularyCardTile, {
      props: {
        card: {
          ...lexemeCard(),
          lexeme: lexeme(),
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-01-01T00:00:00.000Z',
        },
      },
    })

    expect(wrapper.get('[data-testid="review-known-card-1"]').text()).toContain('Known')
    expect(wrapper.get('[data-testid="review-unknown-card-1"]').text()).toContain('Unknown')
  })
})

async function seedLexemeCard(db: WebReaderDb, overrides: Partial<WebWordCardDraft> = {}) {
  const learning = createLearningRepository(db)
  await learning.upsertLexeme(lexeme())
  await learning.upsertWordCard({ ...lexemeCard(), ...overrides })
}

function setSignedInUser(): void {
  const auth = useAuthStore()
  auth.user = {
    id: 'user-1',
    email: 'reader@example.com',
    displayName: 'Reader',
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    status: 'active',
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
    partOfSpeech: 'noun',
    definition: '内心',
    shortDefinition: '心',
    example: null,
    status: 'active',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  }
}

function lexemeCard(): WebWordCardDraft {
  return {
    id: 'card-1',
    ownerUserId: 'user-1',
    cardType: 'lexeme',
    lexemeId: 'lexeme-1',
    sourceBookFingerprint: 'a'.repeat(64),
    sourceBookTitle: 'Kokoro',
    reviewStatus: 'new',
    reviewCount: 0,
    syncStatus: 'synced',
  }
}

function privateSentenceCard(): WebWordCardDraft {
  return {
    id: 'private-card-1',
    ownerUserId: 'user-1',
    cardType: 'private_sentence',
    privateSurface: '私だけの文',
    privateDefinition: '只属于我的句子',
    privateContext: 'local private context',
    sourceBookFingerprint: 'b'.repeat(64),
    sourceBookTitle: 'Kokoro',
    reviewStatus: 'new',
    reviewCount: 0,
    syncStatus: 'local_only',
  }
}
