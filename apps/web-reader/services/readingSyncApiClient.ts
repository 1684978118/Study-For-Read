import { ofetch } from 'ofetch'

import type { ApiEnvelope } from '../types/api'
import { WebApiError } from '../types/api'
import type { WebFileType } from '../types/localData'

type Fetcher = (url: string, options: Record<string, unknown>) => Promise<unknown>

export interface ReadingSyncApiClientOptions {
  baseUrl?: string
  fetcher?: Fetcher
}

export interface UpsertBookMetadataRequest {
  bookFingerprint: string
  title: string
  author?: string
  fileType: WebFileType
  sourceLang: string
  targetLang: string
  chapterCount: number
}

export interface UpdateReadingProgressRequest {
  bookFingerprint: string
  currentChapterIndex: number
  currentParagraphIndex: number
  currentCharOffset: number
  lastReadAt?: string | null
}

export interface ReadingSyncApiClient {
  upsertBookMetadata(input: UpsertBookMetadataRequest): Promise<unknown>
  updateReadingProgress(input: UpdateReadingProgressRequest): Promise<unknown>
}

export function createReadingSyncApiClient(options: ReadingSyncApiClientOptions = {}): ReadingSyncApiClient {
  const baseUrl = options.baseUrl ?? ''
  const fetcher = options.fetcher ?? ofetch
  return {
    upsertBookMetadata(input) {
      return request(fetcher, `${baseUrl}/api/v1/reading/books/${input.bookFingerprint}`, {
        method: 'PUT',
        body: {
          title: input.title,
          ...(input.author ? { author: input.author } : {}),
          fileType: input.fileType,
          sourceLang: input.sourceLang,
          targetLang: input.targetLang,
          chapterCount: input.chapterCount,
        },
      })
    },
    updateReadingProgress(input) {
      return request(fetcher, `${baseUrl}/api/v1/reading/books/${input.bookFingerprint}/progress`, {
        method: 'PATCH',
        body: {
          currentChapterIndex: input.currentChapterIndex,
          currentParagraphIndex: input.currentParagraphIndex,
          currentCharOffset: input.currentCharOffset,
          ...(input.lastReadAt ? { lastReadAt: input.lastReadAt } : {}),
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
