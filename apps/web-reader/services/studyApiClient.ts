import { ofetch } from 'ofetch'

import type { ApiEnvelope } from '../types/api'
import { WebApiError } from '../types/api'
import type { WebLexeme } from '../types/localData'

type Fetcher = (url: string, options: Record<string, unknown>) => Promise<unknown>

export class WebStudyApiError extends WebApiError {}

export interface StudyApiClientOptions {
  baseUrl?: string
  fetcher?: Fetcher
}

export interface LookupRequest {
  text: string
  sourceLang: string
  targetLang: string
  context?: string
}

export type PublicLexemeSnapshot = Omit<WebLexeme, 'createdAt' | 'updatedAt'>

export interface LookupResult {
  kind: string
  lexeme: PublicLexemeSnapshot
  provider?: string | null
  providerMessage?: string | null
}

export interface TranslateParagraphRequest {
  text: string
  sourceLang: string
  targetLang: string
}

export interface TranslationResult {
  translatedText: string
  provider?: string | null
  cached?: boolean
  message?: string | null
}

export interface StudyApiClient {
  lookup(input: LookupRequest): Promise<LookupResult>
  translateParagraph(input: TranslateParagraphRequest): Promise<TranslationResult>
}

export function createStudyApiClient(options: StudyApiClientOptions = {}): StudyApiClient {
  const baseUrl = options.baseUrl ?? ''
  const fetcher = options.fetcher ?? ofetch
  return {
    lookup(input) {
      return request<LookupResult>(fetcher, baseUrl, '/api/v1/study/lookup', {
        method: 'POST',
        body: {
          text: input.text,
          sourceLang: input.sourceLang,
          targetLang: input.targetLang,
          ...(input.context ? { context: input.context } : {}),
        },
      })
    },
    translateParagraph(input) {
      return request<TranslationResult>(fetcher, baseUrl, '/api/v1/study/translate-paragraph', {
        method: 'POST',
        body: {
          text: input.text,
          sourceLang: input.sourceLang,
          targetLang: input.targetLang,
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
    throw mapStudyError(error.code, error.message)
  }
  if (envelope.data == null) {
    throw new WebStudyApiError('WEB_INVALID_RESPONSE', 'Missing response data')
  }
  return envelope.data
}

function mapStudyError(code: string, message: string): WebStudyApiError {
  if (code === 'TRANSLATION_PROVIDER_UNAVAILABLE') {
    return new WebStudyApiError('WEB_TRANSLATION_PROVIDER_UNAVAILABLE', message)
  }
  if (code === 'TRANSLATION_UNSUPPORTED_LANGUAGE_PAIR') {
    return new WebStudyApiError('WEB_TRANSLATION_UNSUPPORTED_LANGUAGE_PAIR', message)
  }
  return new WebStudyApiError(code, message)
}
