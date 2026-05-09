import { defineStore } from 'pinia'

import { createWebReaderDb, type WebReaderDb } from '../db/webReaderDb'
import { createLearningRepository } from '../repositories/learningRepository'
import { createPendingSyncRepository } from '../repositories/pendingSyncRepository'
import { createStatsRepository } from '../repositories/statsRepository'
import type { PublicLexemeSnapshot } from '../services/studyApiClient'
import { createVocabularyApiClient, type VocabularyApiClient } from '../services/vocabularyApiClient'
import type { JsonObject, WebLexeme, WebStudyDailyStatsCounters, WebWordCard } from '../types/localData'

interface VocabularyDependencies {
  db: WebReaderDb
  vocabularyApiClient: VocabularyApiClient
}

interface SourceBookInput {
  sourceBookFingerprint?: string
  sourceBookTitle?: string
}

interface SaveLexemeInput extends SourceBookInput {
  ownerUserId: string
  lexeme: PublicLexemeSnapshot
}

interface SavePrivateSentenceInput extends SourceBookInput {
  ownerUserId: string
  surface: string
  definition: string
  context?: string
}

let testDependencies: VocabularyDependencies | null = null
let defaultDb: WebReaderDb | null = null

export const useVocabularyStore = defineStore('vocabulary', {
  state: () => ({
    lastSavedCard: null as WebWordCard | null,
    errorMessage: null as string | null,
  }),
  actions: {
    async savePublicLexemeCard(input: SaveLexemeInput) {
      const { db, vocabularyApiClient } = dependencies()
      const learning = createLearningRepository(db)
      await learning.upsertLexeme(toLocalLexeme(input.lexeme))
      const existingCards = await learning.listWordCardsByOwner(input.ownerUserId)
      const existing = existingCards.find((card) => card.cardType === 'lexeme' && card.lexemeId === input.lexeme.id)
      let serverCardId: string | undefined
      let syncStatus: 'synced' | 'local_only' = 'synced'
      try {
        const result = await vocabularyApiClient.createLexemeCard({
          lexemeId: input.lexeme.id,
          sourceBookFingerprint: input.sourceBookFingerprint,
          sourceBookTitle: input.sourceBookTitle,
        })
        serverCardId = result.id
      }
      catch {
        syncStatus = 'local_only'
      }
      const card = await learning.upsertWordCard({
        id: existing?.id ?? crypto.randomUUID(),
        ownerUserId: input.ownerUserId,
        cardType: 'lexeme',
        lexemeId: input.lexeme.id,
        sourceBookFingerprint: input.sourceBookFingerprint,
        sourceBookTitle: input.sourceBookTitle,
        reviewStatus: existing?.reviewStatus ?? 'new',
        reviewCount: existing?.reviewCount ?? 0,
        syncStatus,
        serverCardId: serverCardId ?? existing?.serverCardId,
      })
      if (!existing) {
        await incrementStats(db, input.ownerUserId, { cardsCreated: 1 })
      }
      if (syncStatus === 'local_only') {
        await enqueueWordCardCreate(db, input.ownerUserId, {
          localCardId: card.id,
          cardType: 'lexeme',
          lexemeId: input.lexeme.id,
          sourceBookFingerprint: input.sourceBookFingerprint,
          sourceBookTitle: input.sourceBookTitle,
        })
      }
      this.lastSavedCard = card
    },
    async savePrivateSentenceCard(input: SavePrivateSentenceInput) {
      const { db, vocabularyApiClient } = dependencies()
      const learning = createLearningRepository(db)
      let serverCardId: string | undefined
      let syncStatus: 'synced' | 'local_only' = 'synced'
      try {
        const result = await vocabularyApiClient.createPrivateSentenceCard({
          privateSurface: input.surface,
          privateDefinition: input.definition,
          privateContext: input.context,
          sourceBookFingerprint: input.sourceBookFingerprint,
          sourceBookTitle: input.sourceBookTitle,
        })
        serverCardId = result.id
      }
      catch {
        syncStatus = 'local_only'
      }
      const card = await learning.upsertWordCard({
        id: crypto.randomUUID(),
        ownerUserId: input.ownerUserId,
        cardType: 'private_sentence',
        privateSurface: input.surface,
        privateDefinition: input.definition,
        privateContext: input.context,
        sourceBookFingerprint: input.sourceBookFingerprint,
        sourceBookTitle: input.sourceBookTitle,
        reviewStatus: 'new',
        reviewCount: 0,
        syncStatus,
        serverCardId,
      })
      await incrementStats(db, input.ownerUserId, { cardsCreated: 1 })
      if (syncStatus === 'local_only') {
        await enqueueWordCardCreate(db, input.ownerUserId, {
          localCardId: card.id,
          cardType: 'private_sentence',
          sourceBookFingerprint: input.sourceBookFingerprint,
          sourceBookTitle: input.sourceBookTitle,
        })
      }
      this.lastSavedCard = card
    },
  },
})

export function setVocabularyDependenciesForTesting(deps: VocabularyDependencies): void {
  testDependencies = deps
}

export function resetVocabularyDependenciesForTesting(): void {
  testDependencies = null
  defaultDb = null
}

function dependencies(): VocabularyDependencies {
  if (testDependencies) {
    return testDependencies
  }
  const db = defaultDb ??= createWebReaderDb()
  return {
    db,
    vocabularyApiClient: createVocabularyApiClient(),
  }
}

async function incrementStats(
  db: WebReaderDb,
  ownerUserId: string,
  counters: Partial<WebStudyDailyStatsCounters>,
): Promise<void> {
  const repo = createStatsRepository(db)
  await repo.incrementDailyStats(ownerUserId, today(), {
    ...repo.emptyCounters(),
    ...counters,
  })
}

async function enqueueWordCardCreate(
  db: WebReaderDb,
  ownerUserId: string,
  payload: Record<string, string | undefined>,
): Promise<void> {
  await createPendingSyncRepository(db).enqueue({
    id: crypto.randomUUID(),
    ownerUserId,
    eventType: 'word_card_create',
    payloadJson: compactPayload(payload),
    status: 'pending',
    attemptCount: 0,
  })
}

function compactPayload(payload: Record<string, string | undefined>): JsonObject {
  return Object.fromEntries(
    Object.entries(payload).filter((entry): entry is [string, string] => entry[1] !== undefined),
  )
}

function toLocalLexeme(lexeme: PublicLexemeSnapshot): WebLexeme {
  const now = new Date().toISOString()
  return {
    ...lexeme,
    createdAt: now,
    updatedAt: now,
  }
}

function today(): string {
  return new Date().toISOString().slice(0, 10)
}
