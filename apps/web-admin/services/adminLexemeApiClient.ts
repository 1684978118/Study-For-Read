import { ofetch } from 'ofetch'
import { z } from 'zod'

import { AdminApiError } from '../composables/useAdminApiClient'
import type { ApiEnvelope } from '../types/api'
import type {
  AdminLexeme,
  AdminLexemeListQuery,
  AdminLexemeListResponse,
  AdminLexemeRejectRequest,
  AdminLexemeRejectResponse,
  AdminLexemeUpsertRequest,
} from '../types/adminLexeme'

type Fetcher = (path: string, options: Record<string, unknown>) => Promise<ApiEnvelope<unknown>>

export interface AdminLexemeApiClient {
  listLexemes(query: AdminLexemeListQuery, accessToken: string): Promise<AdminLexemeListResponse>
  createLexeme(request: AdminLexemeUpsertRequest, accessToken: string): Promise<AdminLexeme>
  updateLexeme(
    lexemeId: string,
    request: AdminLexemeUpsertRequest,
    accessToken: string,
  ): Promise<AdminLexeme>
  rejectLexeme(
    lexemeId: string,
    request: AdminLexemeRejectRequest,
    accessToken: string,
  ): Promise<AdminLexemeRejectResponse>
}

const lexemeSchema = z.object({
  id: z.string(),
  surface: z.string(),
  normalizedSurface: z.string(),
  reading: z.string().nullable(),
  sourceLang: z.string(),
  targetLang: z.string(),
  entryType: z.enum(['word', 'phrase', 'idiom']),
  partOfSpeech: z.string().nullable(),
  definition: z.string(),
  shortDefinition: z.string().nullable(),
  example: z.string().nullable(),
  status: z.enum(['active', 'candidate', 'rejected']),
  createdAt: z.string().optional(),
  updatedAt: z.string().optional(),
})

const listSchema = z.object({
  items: z.array(lexemeSchema),
  page: z.number(),
  size: z.number(),
  total: z.number(),
})

const rejectSchema = z.object({
  id: z.string(),
  status: z.literal('rejected'),
})

export function createAdminLexemeApiClient(
  options: { fetcher?: Fetcher } = {},
): AdminLexemeApiClient {
  const fetcher = options.fetcher ?? defaultFetcher

  return {
    async listLexemes(query, accessToken) {
      const envelope = await fetcher('/api/v1/admin/lexemes', {
        method: 'GET',
        headers: authHeaders(accessToken),
        query: compactQuery(query),
      })
      return unwrap(envelope, listSchema)
    },

    async createLexeme(request, accessToken) {
      const envelope = await fetcher('/api/v1/admin/lexemes', {
        method: 'POST',
        headers: authHeaders(accessToken),
        body: request,
      })
      return unwrap(envelope, lexemeSchema)
    },

    async updateLexeme(lexemeId, request, accessToken) {
      const envelope = await fetcher(`/api/v1/admin/lexemes/${lexemeId}`, {
        method: 'PATCH',
        headers: authHeaders(accessToken),
        body: request,
      })
      return unwrap(envelope, lexemeSchema)
    },

    async rejectLexeme(lexemeId, request, accessToken) {
      const envelope = await fetcher(`/api/v1/admin/lexemes/${lexemeId}/reject`, {
        method: 'POST',
        headers: authHeaders(accessToken),
        body: request,
      })
      return unwrap(envelope, rejectSchema)
    },
  }
}

export function useAdminLexemeApiClient(): AdminLexemeApiClient {
  return createAdminLexemeApiClient()
}

export function adminLexemeFormError(code: string): string {
  if (code === 'ADMIN_LEXEME_DUPLICATE') {
    return 'A lexeme with these values already exists.'
  }
  if (code === 'ADMIN_LEXEME_INVALID') {
    return 'Check the lexeme fields and try again.'
  }
  return 'Unable to save lexeme.'
}

async function defaultFetcher(
  path: string,
  options: Record<string, unknown>,
): Promise<ApiEnvelope<unknown>> {
  return ofetch<ApiEnvelope<unknown>>(path, options)
}

function authHeaders(accessToken: string) {
  return {
    Authorization: `Bearer ${accessToken}`,
  }
}

function compactQuery(query: object): Record<string, unknown> {
  return Object.fromEntries(
    Object.entries(query).filter(([, value]) => value !== undefined && value !== ''),
  )
}

function unwrap<T>(envelope: ApiEnvelope<unknown>, schema: z.ZodType<T>): T {
  if (!envelope.success) {
    throw new AdminApiError(envelope.error.code, envelope.error.message)
  }
  const parsed = schema.safeParse(envelope.data)
  if (!parsed.success) {
    throw new AdminApiError('INTERNAL_ERROR', 'Unexpected admin lexeme response')
  }
  return parsed.data
}
