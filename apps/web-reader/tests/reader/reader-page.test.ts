import 'fake-indexeddb/auto'

import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { afterEach, beforeEach, describe, expect, it } from 'vitest'

import ReaderPage from '../../pages/reader/[bookId].vue'
import {
  resetReaderDependenciesForTesting,
  setReaderDependenciesForTesting,
} from '../../stores/reader'
import { createWebReaderDb, type WebReaderDb } from '../../db/webReaderDb'
import { createBookRepository } from '../../repositories/bookRepository'
import { createChapterRepository } from '../../repositories/chapterRepository'
import type { WebBookDraft, WebChapterDraft } from '../../types/localData'

describe('reader page', () => {
  let db: WebReaderDb

  beforeEach(async () => {
    setActivePinia(createPinia())
    db = createWebReaderDb(`reader-page-test-${crypto.randomUUID()}`)
    await db.open()
    setReaderDependenciesForTesting({ db })
  })

  afterEach(async () => {
    resetReaderDependenciesForTesting()
    await db.delete()
  })

  it('displays local book title, chapter title, chapter text, and navigation states', async () => {
    await seedBookWithChapters(db)

    const wrapper = mount(ReaderPage, {
      props: { bookId: 'book-1' },
      global: { stubs: ['NuxtLink'] },
    })
    await flushPromises()
    await flushPromises()

    expect(wrapper.text()).toContain('Local Book')
    expect(wrapper.text()).toContain('Chapter One')
    expect(wrapper.text()).toContain('First paragraph.')
    expect(wrapper.get('[data-testid="previous-chapter"]').attributes('disabled')).toBeDefined()
    expect(wrapper.get('[data-testid="next-chapter"]').attributes('disabled')).toBeUndefined()

    await wrapper.get('[data-testid="next-chapter"]').trigger('click')
    await settleReaderUpdate()

    expect(wrapper.text()).toContain('Chapter Two')
    expect(wrapper.text()).toContain('Second paragraph.')
    expect(wrapper.get('[data-testid="next-chapter"]').attributes('disabled')).toBeDefined()
  })

  it('shows an empty chapter state when a local book has no stored chapters', async () => {
    await createBookRepository(db).upsertByOwnerAndFingerprint(bookDraft({ chapterCount: 1 }))

    const wrapper = mount(ReaderPage, {
      props: { bookId: 'book-1' },
      global: { stubs: ['NuxtLink'] },
    })
    await flushPromises()

    expect(wrapper.text()).toContain('No readable chapters found')
  })

  it('shows a not-found state for a missing local book id', async () => {
    const wrapper = mount(ReaderPage, {
      props: { bookId: 'missing-book' },
      global: { stubs: ['NuxtLink'] },
    })
    await flushPromises()

    expect(wrapper.text()).toContain('Book not found')
  })
})

async function settleReaderUpdate(): Promise<void> {
  await flushPromises()
  await new Promise((resolve) => setTimeout(resolve, 0))
  await flushPromises()
}

async function seedBookWithChapters(db: WebReaderDb) {
  const book = await createBookRepository(db).upsertByOwnerAndFingerprint(bookDraft({}))
  await createChapterRepository(db).replaceForBook(book.id, [
    chapterDraft({
      id: 'chapter-1',
      bookId: book.id,
      chapterIndex: 0,
      title: 'Chapter One',
      content: 'First paragraph.\n\nAnother local paragraph.',
      paragraphCount: 2,
    }),
    chapterDraft({
      id: 'chapter-2',
      bookId: book.id,
      chapterIndex: 1,
      title: 'Chapter Two',
      content: 'Second paragraph.',
      paragraphCount: 1,
    }),
  ])
}

function bookDraft(overrides: Partial<WebBookDraft>): WebBookDraft {
  return {
    id: 'book-1',
    ownerUserId: 'user-1',
    bookFingerprint: 'c'.repeat(64),
    title: 'Local Book',
    author: 'Local Author',
    fileType: 'txt',
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    originalFileName: 'local.txt',
    chapterCount: 2,
    metadataSyncStatus: 'local_only',
    ...overrides,
  }
}

function chapterDraft(overrides: Partial<WebChapterDraft>): WebChapterDraft {
  return {
    id: 'chapter',
    bookId: 'book-1',
    chapterIndex: 0,
    title: 'Chapter',
    content: 'Local text.',
    paragraphCount: 1,
    ...overrides,
  }
}
