import { ofetch } from 'ofetch'

import type { ApiEnvelope } from '../types/api'
import { WebApiError } from '../types/api'
import type { WebCardType, WebReviewStatus } from '../types/localData'

type Fetcher = (url: string, options: Record<string, unknown>) => Promise<unknown>

export interface VocabularyApiClientOptions {
  baseUrl?: string
  fetcher?: Fetcher
}

export interface CreateLexemeCardRequest {
  lexemeId: string
  sourceBookFingerprint?: string
  sourceBookTitle?: string
}

export interface CreatePrivateSentenceCardRequest {
  privateSurface: string
  privateDefinition: string
  privateContext?: string
  sourceBookFingerprint?: string
  sourceBookTitle?: string
}

export interface VocabularyCardResult {
  id: string
  cardType: WebCardType
  reviewStatus: WebReviewStatus
  reviewCount: number
  nextReviewAt?: string | null
}

export interface VocabularyApiClient {
  createLexemeCard(input: CreateLexemeCardRequest): Promise<VocabularyCardResult>
  createPrivateSentenceCard(input: CreatePrivateSentenceCardRequest): Promise<VocabularyCardResult>
}

export function createVocabularyApiClient(options: VocabularyApiClientOptions = {}): VocabularyApiClient {
  const baseUrl = options.baseUrl ?? ''
  const fetcher = options.fetcher ?? ofetch
  return {
    createLexemeCard(input) {
      return request<VocabularyCardResult>(fetcher, baseUrl, '/api/v1/vocabulary/cards', {
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
      return request<VocabularyCardResult>(fetcher, baseUrl, '/api/v1/vocabulary/cards', {
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
  }
}

async function request<T>(
  fetcher: Fetcher,
  baseUrl: string,
  path: string,
  options: Record<string, unknown>,
): Promise<T> {
  const envelope = await fetcher(`${baseUrl}${path}`, options) as ApiEnvelope<T>
  if (!envelope.success) {
    const error = envelope.error ?? { code: 'UNKNOWN_ERROR', message: 'Request failed' }
    throw new WebApiError(error.code, error.message)
  }
  if (envelope.data == null) {
    throw new WebApiError('WEB_INVALID_RESPONSE', 'Missing response data')
  }
  return envelope.data
}
