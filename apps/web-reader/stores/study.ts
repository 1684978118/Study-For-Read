import { defineStore } from 'pinia'

import { createWebReaderDb, type WebReaderDb } from '../db/webReaderDb'
import { createLearningRepository } from '../repositories/learningRepository'
import { createStatsRepository } from '../repositories/statsRepository'
import { createStudyApiClient, type LookupResult, type PublicLexemeSnapshot, type StudyApiClient, type TranslationResult } from '../services/studyApiClient'
import type { WebLexeme } from '../types/localData'
import type { WebStudyDailyStatsCounters } from '../types/localData'

interface StudyDependencies {
  db: WebReaderDb
  studyApiClient: StudyApiClient
}

interface LookupInput {
  ownerUserId: string
  text: string
  paragraphContext?: string
  sourceLang: string
  targetLang: string
}

interface TranslateInput {
  ownerUserId: string
  paragraph: string
  sourceLang: string
  targetLang: string
}

let testDependencies: StudyDependencies | null = null
let defaultDb: WebReaderDb | null = null

export const useStudyStore = defineStore('study', {
  state: () => ({
    lookupResult: null as LookupResult | null,
    translationResult: null as TranslationResult | null,
    isLookupLoading: false,
    isTranslationLoading: false,
    errorMessage: null as string | null,
  }),
  actions: {
    async lookupSelectedText(input: LookupInput) {
      this.isLookupLoading = true
      this.errorMessage = null
      try {
        const { db, studyApiClient } = dependencies()
        const result = await studyApiClient.lookup({
          text: input.text,
          sourceLang: input.sourceLang,
          targetLang: input.targetLang,
          ...(input.paragraphContext ? { context: input.paragraphContext } : {}),
        })
        this.lookupResult = result
        if (result.lexeme) {
          await createLearningRepository(db).upsertLexeme(toLocalLexeme(result.lexeme))
        }
        await incrementStats(db, input.ownerUserId, { lookupCount: 1 })
      }
      catch (error) {
        this.errorMessage = messageFromError(error)
      }
      finally {
        this.isLookupLoading = false
      }
    },
    async translateParagraph(input: TranslateInput) {
      this.isTranslationLoading = true
      this.errorMessage = null
      try {
        const { db, studyApiClient } = dependencies()
        const sourceTextHash = await sha256Hex(input.paragraph)
        const learning = createLearningRepository(db)
        const cached = await learning.findTranslationCache({
          ownerUserId: input.ownerUserId,
          sourceLang: input.sourceLang,
          targetLang: input.targetLang,
          sourceTextHash,
        })
        if (cached) {
          this.translationResult = {
            translatedText: cached.translatedText,
            provider: cached.provider,
            cached: true,
            message: null,
          }
          return
        }

        const result = await studyApiClient.translateParagraph({
          text: input.paragraph,
          sourceLang: input.sourceLang,
          targetLang: input.targetLang,
        })
        this.translationResult = result
        await learning.upsertTranslationCache({
          id: crypto.randomUUID(),
          ownerUserId: input.ownerUserId,
          sourceLang: input.sourceLang,
          targetLang: input.targetLang,
          sourceTextHash,
          translatedText: result.translatedText,
          provider: result.provider ?? undefined,
          lastUsedAt: new Date().toISOString(),
        })
        await incrementStats(db, input.ownerUserId, { paragraphTranslationCount: 1 })
      }
      catch (error) {
        this.errorMessage = messageFromError(error)
      }
      finally {
        this.isTranslationLoading = false
      }
    },
  },
})

export function setStudyDependenciesForTesting(deps: StudyDependencies): void {
  testDependencies = deps
}

export function resetStudyDependenciesForTesting(): void {
  testDependencies = null
  defaultDb = null
}

function dependencies(): StudyDependencies {
  if (testDependencies) {
    return testDependencies
  }
  const db = defaultDb ??= createWebReaderDb()
  return {
    db,
    studyApiClient: createStudyApiClient(),
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

async function sha256Hex(text: string): Promise<string> {
  const data = new TextEncoder().encode(text)
  const digest = await crypto.subtle.digest('SHA-256', data)
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('')
}

function today(): string {
  return new Date().toISOString().slice(0, 10)
}

function toLocalLexeme(lexeme: PublicLexemeSnapshot): WebLexeme {
  const now = new Date().toISOString()
  return {
    ...lexeme,
    createdAt: now,
    updatedAt: now,
  }
}

function messageFromError(error: unknown): string {
  return error instanceof Error ? error.message : 'Study action failed.'
}
