import { describe, expect, it } from 'vitest'

import { createApiClient, WebApiError } from '../../composables/useApiClient'

describe('web reader auth api client', () => {
  it('sends login credentials to the auth login endpoint and parses session envelope', async () => {
    const requests: Array<{ url: string, options: Record<string, unknown> }> = []
    const client = createApiClient({
      baseUrl: 'https://api.example.test',
      fetcher: async (url, options) => {
        requests.push({ url, options: options as Record<string, unknown> })
        return {
          success: true,
          data: {
            user: userJson(),
            accessToken: 'access-token',
            refreshToken: 'refresh-token',
          },
          error: null,
        }
      },
    })

    const session = await client.login({
      email: 'reader@example.com',
      password: 'secret-password',
    })

    expect(requests).toHaveLength(1)
    expect(requests[0]?.url).toBe('https://api.example.test/api/v1/auth/login')
    expect(requests[0]?.options).toMatchObject({
      method: 'POST',
      body: {
        email: 'reader@example.com',
        password: 'secret-password',
      },
    })
    expect(session.user.email).toBe('reader@example.com')
    expect(session.accessToken).toBe('access-token')
    expect(session.refreshToken).toBe('refresh-token')
  })

  it('sends register credentials with the default web reader language pair', async () => {
    const requests: Array<{ url: string, options: Record<string, unknown> }> = []
    const client = createApiClient({
      baseUrl: 'https://api.example.test',
      fetcher: async (url, options) => {
        requests.push({ url, options: options as Record<string, unknown> })
        return {
          success: true,
          data: {
            user: userJson(),
            accessToken: 'access-token',
            refreshToken: 'refresh-token',
          },
          error: null,
        }
      },
    })

    await client.register({
      email: 'reader@example.com',
      password: 'secret-password',
      displayName: 'Reader',
    })

    expect(requests[0]?.url).toBe('https://api.example.test/api/v1/auth/register')
    expect(requests[0]?.options).toMatchObject({
      method: 'POST',
      body: {
        email: 'reader@example.com',
        password: 'secret-password',
        displayName: 'Reader',
        sourceLang: 'ja',
        targetLang: 'zh-CN',
      },
    })
  })

  it('maps invalid credentials envelope to a stable web auth error', async () => {
    const client = createApiClient({
      baseUrl: 'https://api.example.test',
      fetcher: async () => ({
        success: false,
        data: null,
        error: {
          code: 'AUTH_INVALID_CREDENTIALS',
          message: 'Invalid email or password',
        },
      }),
    })

    await expect(
      client.login({
        email: 'reader@example.com',
        password: 'wrong-password',
      }),
    ).rejects.toMatchObject({
      code: 'WEB_AUTH_INVALID_CREDENTIALS',
      message: 'Invalid email or password',
    } satisfies Partial<WebApiError>)
  })
})

function userJson() {
  return {
    id: 'user-1',
    email: 'reader@example.com',
    displayName: 'Reader',
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    status: 'active',
  }
}
