import { ofetch } from 'ofetch'

import type { ApiEnvelope } from '../types/api'
import { WebApiError } from '../types/api'
import type {
  AuthSession,
  AuthUser,
  RegisterRequest,
  SignInRequest,
} from '../types/auth'

type Fetcher = (
  url: string,
  options: Record<string, unknown>,
) => Promise<unknown>

export interface ApiClientOptions {
  baseUrl?: string
  fetcher?: Fetcher
}

export interface ApiClient {
  login: (payload: SignInRequest) => Promise<AuthSession>
  register: (payload: RegisterRequest) => Promise<AuthSession>
  me: (accessToken: string) => Promise<AuthUser>
}

export { WebApiError }

export function useApiClient(): ApiClient {
  const config = useRuntimeConfig()
  return createApiClient({
    baseUrl: config.public.apiBaseUrl,
  })
}

export function createApiClient(options: ApiClientOptions = {}): ApiClient {
  const baseUrl = options.baseUrl ?? ''
  const fetcher = options.fetcher ?? ofetch

  return {
    login(payload) {
      return request<AuthSession>(fetcher, baseUrl, '/api/v1/auth/login', {
        method: 'POST',
        body: {
          email: payload.email,
          password: payload.password,
        },
      })
    },
    register(payload) {
      return request<AuthSession>(fetcher, baseUrl, '/api/v1/auth/register', {
        method: 'POST',
        body: {
          email: payload.email,
          password: payload.password,
          displayName: payload.displayName,
          sourceLang: 'ja',
          targetLang: 'zh-CN',
        },
      })
    },
    me(accessToken) {
      return request<AuthUser>(fetcher, baseUrl, '/api/v1/auth/me', {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${accessToken}`,
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
    const error = envelope.error ?? {
      code: 'UNKNOWN_ERROR',
      message: 'Request failed',
    }
    throw mapApiError(error.code, error.message)
  }
  if (envelope.data == null) {
    throw new WebApiError('WEB_INVALID_RESPONSE', 'Missing response data')
  }
  return envelope.data
}

function mapApiError(code: string, message: string): WebApiError {
  if (code === 'AUTH_INVALID_CREDENTIALS') {
    return new WebApiError('WEB_AUTH_INVALID_CREDENTIALS', message)
  }
  if (code === 'AUTH_EMAIL_ALREADY_EXISTS') {
    return new WebApiError('WEB_AUTH_EMAIL_ALREADY_EXISTS', message)
  }
  return new WebApiError(code, message)
}
