import type { WebReaderDb } from '../db/webReaderDb'
import type { WebStudyDailyStats, WebStudyDailyStatsCounters } from '../types/localData'

const zeroCounters: WebStudyDailyStatsCounters = {
  readingMinutes: 0,
  lookupCount: 0,
  paragraphTranslationCount: 0,
  cardsCreated: 0,
  cardsReviewed: 0,
}

export function createStatsRepository(db: WebReaderDb) {
  return new StatsRepository(db)
}

export class StatsRepository {
  constructor(private readonly db: WebReaderDb) {}

  async incrementDailyStats(
    ownerUserId: string,
    statDate: string,
    counters: WebStudyDailyStatsCounters,
  ): Promise<WebStudyDailyStats> {
    validateCounters(counters)
    const now = nowIso()
    const existing = await this.getDailyStats(ownerUserId, statDate)
    const stats: WebStudyDailyStats = {
      id: existing?.id ?? `${ownerUserId}:${statDate}`,
      ownerUserId,
      statDate,
      readingMinutes: (existing?.readingMinutes ?? 0) + counters.readingMinutes,
      lookupCount: (existing?.lookupCount ?? 0) + counters.lookupCount,
      paragraphTranslationCount:
        (existing?.paragraphTranslationCount ?? 0) + counters.paragraphTranslationCount,
      cardsCreated: (existing?.cardsCreated ?? 0) + counters.cardsCreated,
      cardsReviewed: (existing?.cardsReviewed ?? 0) + counters.cardsReviewed,
      syncStatus: 'dirty',
      lastSyncedAt: existing?.lastSyncedAt,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    }
    await this.db.web_study_daily_stats.put(stats)
    return stats
  }

  async getDailyStats(ownerUserId: string, statDate: string): Promise<WebStudyDailyStats | undefined> {
    return this.db.web_study_daily_stats
      .where('[ownerUserId+statDate]')
      .equals([ownerUserId, statDate])
      .first()
  }

  emptyCounters(): WebStudyDailyStatsCounters {
    return { ...zeroCounters }
  }
}

function validateCounters(counters: WebStudyDailyStatsCounters): void {
  for (const [key, value] of Object.entries(counters)) {
    if (value < 0) {
      throw new Error(`${key} must be non-negative`)
    }
  }
}

function nowIso(): string {
  return new Date().toISOString()
}
