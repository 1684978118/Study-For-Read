import { defineStore } from 'pinia'

import { createWebReaderDb, type WebReaderDb } from '../db/webReaderDb'
import { createStatsRepository } from '../repositories/statsRepository'
import type { WebStudyDailyStatsCounters } from '../types/localData'

interface StatsDependencies {
  db: WebReaderDb
}

export interface StatsSummaries {
  today: WebStudyDailyStatsCounters
  last7Days: WebStudyDailyStatsCounters
  allTime: WebStudyDailyStatsCounters
}

let testDependencies: StatsDependencies | null = null
let defaultDb: WebReaderDb | null = null

export const useStatsStore = defineStore('stats', {
  state: () => ({
    summaries: {
      today: zeroCounters(),
      last7Days: zeroCounters(),
      allTime: zeroCounters(),
    } as StatsSummaries,
    isLoading: false,
    errorMessage: null as string | null,
  }),
  actions: {
    async load(ownerUserId: string, today = todayDate()) {
      this.isLoading = true
      this.errorMessage = null
      try {
        const repo = createStatsRepository(dependencies().db)
        const last7Start = addDays(today, -6)
        this.summaries = {
          today: await repo.summarize(ownerUserId, { from: today, to: today }),
          last7Days: await repo.summarize(ownerUserId, { from: last7Start, to: today }),
          allTime: await repo.summarize(ownerUserId),
        }
      }
      catch (error) {
        this.errorMessage = error instanceof Error ? error.message : 'Failed to load stats.'
      }
      finally {
        this.isLoading = false
      }
    },
  },
})

export function setStatsDependenciesForTesting(dependencies: StatsDependencies): void {
  testDependencies = dependencies
}

export function resetStatsDependenciesForTesting(): void {
  testDependencies = null
  defaultDb = null
}

function dependencies(): StatsDependencies {
  if (testDependencies) {
    return testDependencies
  }
  return { db: defaultDb ??= createWebReaderDb() }
}

function zeroCounters(): WebStudyDailyStatsCounters {
  return {
    readingMinutes: 0,
    lookupCount: 0,
    paragraphTranslationCount: 0,
    cardsCreated: 0,
    cardsReviewed: 0,
  }
}

function todayDate(): string {
  return new Date().toISOString().slice(0, 10)
}

function addDays(date: string, days: number): string {
  const value = new Date(`${date}T00:00:00.000Z`)
  value.setUTCDate(value.getUTCDate() + days)
  return value.toISOString().slice(0, 10)
}
