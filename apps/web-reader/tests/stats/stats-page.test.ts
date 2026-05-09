import 'fake-indexeddb/auto'

import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { afterEach, beforeEach, describe, expect, it } from 'vitest'

import StatsPage from '../../pages/stats.vue'
import StatsSummary from '../../components/stats/StatsSummary.vue'
import { createWebReaderDb, type WebReaderDb } from '../../db/webReaderDb'
import { createStatsRepository } from '../../repositories/statsRepository'
import { useAuthStore } from '../../stores/auth'
import {
  resetStatsDependenciesForTesting,
  setStatsDependenciesForTesting,
} from '../../stores/stats'

describe('stats page', () => {
  let db: WebReaderDb
  const ownerUserId = 'user-1'

  beforeEach(async () => {
    setActivePinia(createPinia())
    db = createWebReaderDb(`stats-page-${crypto.randomUUID()}`)
    await db.open()
    setStatsDependenciesForTesting({ db })
    setSignedInUser()
  })

  afterEach(async () => {
    resetStatsDependenciesForTesting()
    await db.delete()
  })

  it('shows today, last 7 days, and all time local summaries without charts', async () => {
    const repo = createStatsRepository(db)
    await repo.incrementDailyStats(ownerUserId, '2026-05-09', {
      readingMinutes: 10,
      lookupCount: 1,
      paragraphTranslationCount: 2,
      cardsCreated: 3,
      cardsReviewed: 4,
    })
    await repo.incrementDailyStats(ownerUserId, '2026-05-04', {
      readingMinutes: 5,
      lookupCount: 6,
      paragraphTranslationCount: 7,
      cardsCreated: 8,
      cardsReviewed: 9,
    })
    await repo.incrementDailyStats(ownerUserId, '2026-04-01', {
      readingMinutes: 20,
      lookupCount: 30,
      paragraphTranslationCount: 40,
      cardsCreated: 50,
      cardsReviewed: 60,
    })

    const wrapper = mount(StatsPage, {
      props: { today: '2026-05-09' },
    })
    await flushPromises()
    await flushPromises()

    expect(wrapper.text()).toContain('Today')
    expect(wrapper.text()).toContain('Last 7 Days')
    expect(wrapper.text()).toContain('All Time')
    expect(wrapper.text()).toContain('Reading minutes')
    expect(wrapper.text()).toContain('Lookups')
    expect(wrapper.text()).toContain('Paragraph translations')
    expect(wrapper.text()).toContain('Cards created')
    expect(wrapper.text()).toContain('Cards reviewed')
    expect(wrapper.text()).toContain('15')
    expect(wrapper.text()).toContain('35')
    expect(wrapper.find('canvas').exists()).toBe(false)
    expect(wrapper.text()).not.toMatch(/heatmap/i)
  })

  it('renders a compact stats summary', () => {
    const wrapper = mount(StatsSummary, {
      props: {
        title: 'Today',
        summary: {
          readingMinutes: 1,
          lookupCount: 2,
          paragraphTranslationCount: 3,
          cardsCreated: 4,
          cardsReviewed: 5,
        },
      },
    })

    expect(wrapper.text()).toContain('Today')
    expect(wrapper.text()).toContain('Reading minutes')
    expect(wrapper.text()).toContain('5')
  })
})

function setSignedInUser(): void {
  const auth = useAuthStore()
  auth.user = {
    id: 'user-1',
    email: 'reader@example.com',
    displayName: 'Reader',
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    status: 'active',
  }
}
