import { ofetch } from 'ofetch'

import type { ApiEnvelope } from '../types/api'
import { WebApiError } from '../types/api'
import type { WebStudyDailyStatsCounters } from '../types/localData'

type Fetcher = (url: string, options: Record<string, unknown>) => Promise<unknown>

export interface StatsApiClientOptions {
  baseUrl?: string
  fetcher?: Fetcher
}

export interface AddDailyStatsRequest extends WebStudyDailyStatsCounters {
  statDate: string
}

export interface StatsApiClient {
  addDailyStats(input: AddDailyStatsRequest): Promise<unknown>
}

export function createStatsApiClient(options: StatsApiClientOptions = {}): StatsApiClient {
  const baseUrl = options.baseUrl ?? ''
  const fetcher = options.fetcher ?? ofetch
  return {
    addDailyStats(input) {
      return request(fetcher, `${baseUrl}/api/v1/stats/daily`, {
        method: 'POST',
        body: {
          statDate: input.statDate,
          readingMinutes: input.readingMinutes,
          lookupCount: input.lookupCount,
          paragraphTranslationCount: input.paragraphTranslationCount,
          cardsCreated: input.cardsCreated,
          cardsReviewed: input.cardsReviewed,
        },
      })
    },
  }
}

async function request(
  fetcher: Fetcher,
  url: string,
  options: Record<string, unknown>,
): Promise<unknown> {
  const envelope = await fetcher(url, options) as ApiEnvelope<unknown>
  if (!envelope.success) {
    const error = envelope.error ?? { code: 'UNKNOWN_ERROR', message: 'Request failed' }
    throw new WebApiError(error.code, error.message)
  }
  return envelope.data
}
