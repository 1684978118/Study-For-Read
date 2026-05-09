import 'fake-indexeddb/auto'

import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import { createWebReaderDb, type WebReaderDb } from '../../db/webReaderDb'
import { createLearningRepository } from '../../repositories/learningRepository'
import { createStatsRepository } from '../../repositories/statsRepository'
import ReaderText from '../../components/reader/ReaderText.vue'
import {
  resetStudyDependenciesForTesting,
  setStudyDependenciesForTesting,
  useStudyStore,
} from '../../stores/study'

describe('reader study flow', () => {
  let db: WebReaderDb
  const ownerUserId = 'user-1'

  beforeEach(async () => {
    setActivePinia(createPinia())
    db = createWebReaderDb(`reader-study-flow-${crypto.randomUUID()}`)
    await db.open()
  })

  afterEach(async () => {
    resetStudyDependenciesForTesting()
    await db.delete()
  })

  it('looks up selected text, caches public lexeme, and increments local stats', async () => {
    const lookupCalls: Array<{ text: string, context?: string }> = []
    setStudyDependenciesForTesting({
      db,
      studyApiClient: {
        async lookup(input) {
          lookupCalls.push({ text: input.text, context: input.context })
          return {
            kind: 'lexeme',
            provider: 'public_lexeme',
            providerMessage: null,
            lexeme: lexeme(),
          }
        },
        async translateParagraph() {
          throw new Error('translate should not be called')
        },
      },
    })
    const study = useStudyStore()

    await study.lookupSelectedText({
      ownerUserId,
      text: '心',
      paragraphContext: '先生の心を知りたい。',
      sourceLang: 'ja',
      targetLang: 'zh-CN',
    })

    expect(lookupCalls).toEqual([{ text: '心', context: '先生の心を知りたい。' }])
    await expect(createLearningRepository(db).getLexemeById('lexeme-1')).resolves.toMatchObject({
      surface: '心',
      reading: 'こころ',
    })
    const stats = await createStatsRepository(db).getDailyStats(ownerUserId, today())
    expect(stats?.lookupCount).toBe(1)
    expect(study.lookupResult?.lexeme.reading).toBe('こころ')
  })

  it('translates one paragraph, caches translation locally, and increments local stats', async () => {
    const translateCalls: string[] = []
    setStudyDependenciesForTesting({
      db,
      studyApiClient: {
        async lookup() {
          throw new Error('lookup should not be called')
        },
        async translateParagraph(input) {
          translateCalls.push(input.text)
          return {
            translatedText: '我一直称那个人为先生。',
            provider: 'fake_provider',
            cached: false,
            message: null,
          }
        },
      },
    })
    const study = useStudyStore()

    await study.translateParagraph({
      ownerUserId,
      paragraph: '私はその人を常に先生と呼んでいた。',
      sourceLang: 'ja',
      targetLang: 'zh-CN',
    })

    expect(translateCalls).toEqual(['私はその人を常に先生と呼んでいた。'])
    const stats = await createStatsRepository(db).getDailyStats(ownerUserId, today())
    expect(stats?.paragraphTranslationCount).toBe(1)
    expect(study.translationResult?.translatedText).toBe('我一直称那个人为先生。')
    const entries = await db.web_translation_cache.where('ownerUserId').equals(ownerUserId).toArray()
    expect(entries).toHaveLength(1)
    expect(entries[0]?.translatedText).toBe('我一直称那个人为先生。')
  })

  it('reader text exposes selected lookup and single-paragraph translation controls without full chapter controls', async () => {
    const lookup = vi.fn()
    const translate = vi.fn()
    const wrapper = mount(ReaderText, {
      props: {
        content: '第一段。\n\n第二段。',
        fontSize: 18,
        theme: 'light',
        lookupText: '心',
        translations: { 1: '第二段译文。' },
        onLookup: lookup,
        onTranslateParagraph: translate,
      },
    })

    await wrapper.get('[data-testid="lookup-selected-text"]').trigger('click')
    await wrapper.get('[data-testid="translate-paragraph-0"]').trigger('click')

    expect(lookup).toHaveBeenCalledWith('心', '第一段。')
    expect(translate).toHaveBeenCalledWith('第一段。', 0)
    expect(wrapper.text()).toContain('第二段译文。')
    expect(wrapper.text()).not.toMatch(/full chapter|full book|translate all/i)
  })
})

function lexeme() {
  return {
    id: 'lexeme-1',
    surface: '心',
    normalizedSurface: '心',
    reading: 'こころ',
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    entryType: 'word' as const,
    partOfSpeech: 'noun',
    definition: '心；内心；精神',
    shortDefinition: '心；内心',
    example: null,
    status: 'active' as const,
  }
}

function today(): string {
  return new Date().toISOString().slice(0, 10)
}
