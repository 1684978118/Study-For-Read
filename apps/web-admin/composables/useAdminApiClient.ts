import { ofetch } from 'ofetch'
import { z } from 'zod'

import type { AdminUiError, ApiEnvelope } from '../types/api'
import type {
  AdminLoginRequest,
  AdminLoginResponse,
  AdminProfile,
} from '../types/adminAuth'

type Fetcher = (path: string, options: Record<string, unknown>) => Promise<ApiEnvelope<unknown>>

export interface AdminApiClient {
  login(request: AdminLoginRequest): Promise<AdminLoginResponse>
  me(accessToken: string): Promise<AdminProfile>
}

export class AdminApiError extends Error {
  readonly code: string
  readonly uiCode: AdminUiError

  constructor(code: string, message: string, uiCode = mapAdminUiError(code)) {
    super(message)
    this.name = 'AdminApiError'
    this.code = code
    this.uiCode = uiCode
  }
}

const adminProfileSchema = z.object({
  id: z.string().min(1),
  username: z.string().min(1),
  role: z.enum(['admin', 'operator']),
  status: z.enum(['active', 'disabled']),
})

const loginResponseSchema = z.object({
  admin: adminProfileSchema,
  accessToken: z.string().min(1),
})

export function createAdminApiClient(options: { fetcher?: Fetcher } = {}): AdminApiClient {
  const fetcher = options.fetcher ?? defaultFetcher

  return {
    async login(request) {
      const envelope = await fetcher('/api/v1/admin/auth/login', {
        method: 'POST',
        body: request,
      })
      return unwrapEnvelope(envelope, loginResponseSchema)
    },

    async me(accessToken) {
      const envelope = await fetcher('/api/v1/admin/auth/me', {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      })
      return unwrapEnvelope(envelope, adminProfileSchema)
    },
  }
}

export function useAdminApiClient(): AdminApiClient {
  return createAdminApiClient()
}

function unwrapEnvelope<T>(envelope: ApiEnvelope<unknown>, schema: z.ZodType<T>): T {
  if (!envelope.success) {
    throw new AdminApiError(envelope.error.code, envelope.error.message)
  }

  const parsed = schema.safeParse(envelope.data)
  if (!parsed.success) {
    throw new AdminApiError('INTERNAL_ERROR', 'Unexpected admin API response')
  }

  return parsed.data
}

async function defaultFetcher(
  path: string,
  options: Record<string, unknown>,
): Promise<ApiEnvelope<unknown>> {
  return ofetch<ApiEnvelope<unknown>>(path, options)
}

function mapAdminUiError(code: string): AdminUiError {
  if (code === 'ADMIN_INVALID_CREDENTIALS') return 'invalid_credentials'
  if (code === 'ADMIN_DISABLED') return 'admin_disabled'
  if (code === 'ADMIN_REQUIRED') return 'admin_required'
  return 'request_failed'
}
