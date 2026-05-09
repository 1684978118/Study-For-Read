import { describe, expect, it } from 'vitest'

import { createStudyApiClient, WebStudyApiError } from '../../services/studyApiClient'

describe('study api client', () => {
  it('posts lookup with selected text and optional paragraph context', async () => {
    const calls: Array<{ url: string, options: Record<string, unknown> }> = []
    const client = createStudyApiClient({
      baseUrl: 'https://api.example.test',
      fetcher: async (url, options) => {
        calls.push({ url, options })
        return {
          success: true,
          data: {
            kind: 'lexeme',
            provider: 'public_lexeme',
            providerMessage: null,
            lexeme: lexemePayload(),
          },
          error: null,
        }
      },
    })

    const result = await client.lookup({
      text: '心',
      sourceLang: 'ja',
      targetLang: 'zh-CN',
      context: '先生の心を知りたい。',
    })

    expect(calls).toEqual([
      {
        url: 'https://api.example.test/api/v1/study/lookup',
        options: {
          method: 'POST',
          body: {
            text: '心',
            sourceLang: 'ja',
            targetLang: 'zh-CN',
            context: '先生の心を知りたい。',
          },
        },
      },
    ])
    expect(result.lexeme.reading).toBe('こころ')
  })

  it('posts paragraph translation with one paragraph string only', async () => {
    const calls: Array<{ body: unknown }> = []
    const client = createStudyApiClient({
      fetcher: async (_url, options) => {
        calls.push({ body: options.body })
        return {
          success: true,
          data: {
            translatedText: '我一直称那个人为先生。',
            provider: 'fake_provider',
            cached: false,
            message: null,
          },
          error: null,
        }
      },
    })

    const result = await client.translateParagraph({
      text: '私はその人を常に先生と呼んでいた。',
      sourceLang: 'ja',
      targetLang: 'zh-CN',
    })

    expect(calls).toEqual([
      {
        body: {
          text: '私はその人を常に先生と呼んでいた。',
          sourceLang: 'ja',
          targetLang: 'zh-CN',
        },
      },
    ])
    expect(JSON.stringify(calls[0]?.body)).not.toMatch(/chapters|chapter|book|paragraphs|\[/i)
    expect(result.translatedText).toBe('我一直称那个人为先生。')
  })

  it('maps API envelope errors to stable web study errors', async () => {
    const client = createStudyApiClient({
      fetcher: async () => ({
        success: false,
        data: null,
        error: {
          code: 'TRANSLATION_PROVIDER_UNAVAILABLE',
          message: 'Provider unavailable',
        },
      }),
    })

    await expect(client.translateParagraph({
      text: '短い段落。',
      sourceLang: 'ja',
      targetLang: 'zh-CN',
    })).rejects.toMatchObject({
      code: 'WEB_TRANSLATION_PROVIDER_UNAVAILABLE',
    } satisfies Partial<WebStudyApiError>)
  })
})

function lexemePayload() {
  return {
    id: 'lexeme-1',
    surface: '心',
    normalizedSurface: '心',
    reading: 'こころ',
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    entryType: 'word',
    partOfSpeech: 'noun',
    definition: '心；内心；精神',
    shortDefinition: '心；内心',
    example: null,
    status: 'active',
  }
}
