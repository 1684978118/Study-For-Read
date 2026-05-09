import { ofetch } from 'ofetch'
import { z } from 'zod'

import { AdminApiError } from '../composables/useAdminApiClient'
import type { ApiEnvelope } from '../types/api'
import type {
  AdminAuditLogListQuery,
  AdminAuditLogListResponse,
  AdminPlatformStatsSummary,
  AdminUserListQuery,
  AdminUserListResponse,
} from '../types/adminManagement'

type Fetcher = (path: string, options: Record<string, unknown>) => Promise<ApiEnvelope<unknown>>

const forbiddenDetailKeys = new Set([
  'content',
  'chaptercontent',
  'chapter_content',
  'originalfile',
  'original_file',
  'filepath',
  'file_path',
  'sourcetext',
  'source_text',
  'rawtext',
  'raw_text',
  'translatedtext',
  'translated_text',
  'paragraphtext',
  'paragraph_text',
  'passwordhash',
  'password_hash',
  'tokenhash',
  'token_hash',
  'password',
  'token',
  'privatesentencecontext',
  'private_sentence_context',
])

export interface AdminManagementApiClient {
  getStatsSummary(accessToken: string): Promise<AdminPlatformStatsSummary>
  listUsers(
    query: AdminUserListQuery,
    accessToken: string,
  ): Promise<AdminUserListResponse>
  listAuditLogs(
    query: AdminAuditLogListQuery,
    accessToken: string,
  ): Promise<AdminAuditLogListResponse>
}

const summarySchema = z.object({
  userCount: z.number(),
  activeUserCount: z.number(),
  disabledUserCount: z.number(),
  bookMetadataCount: z.number(),
  lexemeCount: z.number(),
  wordCardCount: z.number(),
  readingMinutes: z.number(),
  lookupCount: z.number(),
  paragraphTranslationCount: z.number(),
  cardsCreated: z.number(),
  cardsReviewed: z.number(),
})

const userListSchema = z.object({
  items: z.array(
    z.object({
      id: z.string(),
      email: z.string(),
      displayName: z.string(),
      sourceLang: z.string(),
      targetLang: z.string(),
      status: z.enum(['active', 'disabled']),
      createdAt: z.string(),
      updatedAt: z.string(),
    }).passthrough(),
  ),
  page: z.number(),
  size: z.number(),
  total: z.number(),
})

const auditListSchema = z.object({
  items: z.array(
    z.object({
      id: z.string(),
      adminUserId: z.string(),
      adminUsername: z.string(),
      action: z.string(),
      targetType: z.string(),
      targetId: z.string(),
      details: z.record(z.string(), z.unknown()),
      createdAt: z.string(),
    }),
  ),
  page: z.number(),
  size: z.number(),
  total: z.number(),
})

export function createAdminManagementApiClient(
  options: { fetcher?: Fetcher } = {},
): AdminManagementApiClient {
  const fetcher = options.fetcher ?? defaultFetcher

  return {
    async getStatsSummary(accessToken) {
      const envelope = await fetcher('/api/v1/admin/stats/summary', {
        method: 'GET',
        headers: authHeaders(accessToken),
      })
      return unwrap(envelope, summarySchema)
    },

    async listUsers(query, accessToken) {
      const envelope = await fetcher('/api/v1/admin/users', {
        method: 'GET',
        headers: authHeaders(accessToken),
        query: compactQuery(query),
      })
      return unwrap(envelope, userListSchema)
    },

    async listAuditLogs(query, accessToken) {
      const envelope = await fetcher('/api/v1/admin/audit-logs', {
        method: 'GET',
        headers: authHeaders(accessToken),
        query: compactQuery(query),
      })
      return unwrap(envelope, auditListSchema)
    },
  }
}

export function useAdminManagementApiClient(): AdminManagementApiClient {
  return createAdminManagementApiClient()
}

export function renderRedactedDetails(details: Record<string, unknown>): string {
  return Object.entries(details)
    .filter(([key]) => !forbiddenDetailKeys.has(key.toLowerCase()))
    .map(([key, value]) => `${key}: ${String(value)}`)
    .join(', ')
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
    throw new AdminApiError('INTERNAL_ERROR', 'Unexpected admin management response')
  }
  return parsed.data
}
