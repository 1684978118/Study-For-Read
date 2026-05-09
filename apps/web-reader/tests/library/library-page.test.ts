import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import LibraryPage from '../../pages/library.vue'
import {
  resetLibraryDependenciesForTesting,
  setLibraryDependenciesForTesting,
} from '../../stores/library'
import { useAuthStore } from '../../stores/auth'
import type { WebBook } from '../../types/localData'

describe('library page', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    resetLibraryDependenciesForTesting()
  })

  it('shows an empty state that explains books stay in this browser', async () => {
    setSignedInUser()
    setLibraryDependenciesForTesting({
      listBooks: async () => [],
      importBook: async () => bookFixture(),
    })

    const wrapper = mount(LibraryPage)
    await flushPromises()

    expect(wrapper.text()).toContain('Books stay in this browser')
    expect(wrapper.text()).toContain('Import')
  })

  it('shows imported book metadata and routes clicks to the reader placeholder route', async () => {
    const navigateTo = vi.fn()
    vi.stubGlobal('navigateTo', navigateTo)
    setSignedInUser()
    setLibraryDependenciesForTesting({
      listBooks: async () => [bookFixture()],
      importBook: async () => bookFixture(),
    })

    const wrapper = mount(LibraryPage)
    await flushPromises()

    expect(wrapper.text()).toContain('Kokoro')
    expect(wrapper.text()).toContain('Natsume Soseki')
    expect(wrapper.text()).toContain('TXT')
    expect(wrapper.text()).toContain('local_only')

    await wrapper.get('[data-testid="open-book-book-1"]').trigger('click')

    expect(navigateTo).toHaveBeenCalledWith('/reader/book-1')
    vi.unstubAllGlobals()
  })

  it('imports a selected local file for the current user and refreshes the list', async () => {
    setSignedInUser()
    const importCalls: Array<{ fileName: string, ownerUserId: string }> = []
    const importedBook = bookFixture({ title: 'Imported TXT' })
    setLibraryDependenciesForTesting({
      listBooks: vi.fn()
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([importedBook]),
      async importBook({ file, ownerUserId }) {
        importCalls.push({ fileName: file.name, ownerUserId })
        return importedBook
      },
    })

    const wrapper = mount(LibraryPage)
    await flushPromises()
    const input = wrapper.get('input[type="file"]')
    Object.defineProperty(input.element, 'files', {
      value: [new File(['hello'], 'import.txt', { type: 'text/plain' })],
    })
    await input.trigger('change')
    await flushPromises()

    expect(importCalls).toEqual([{ fileName: 'import.txt', ownerUserId: 'user-1' }])
    expect(wrapper.text()).toContain('Imported TXT')
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

function bookFixture(overrides: Partial<WebBook> = {}): WebBook {
  return {
    id: 'book-1',
    ownerUserId: 'user-1',
    bookFingerprint: 'a'.repeat(64),
    title: 'Kokoro',
    author: 'Natsume Soseki',
    fileType: 'txt',
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    originalFileName: 'kokoro.txt',
    chapterCount: 1,
    metadataSyncStatus: 'local_only',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
    ...overrides,
  }
}
