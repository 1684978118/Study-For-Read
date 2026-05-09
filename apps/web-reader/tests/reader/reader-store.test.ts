import 'fake-indexeddb/auto'

import { createPinia, setActivePinia } from 'pinia'
import { afterEach, beforeEach, describe, expect, it } from 'vitest'

import { createWebReaderDb, type WebReaderDb } from '../../db/webReaderDb'
import { createBookRepository } from '../../repositories/bookRepository'
import { createChapterRepository } from '../../repositories/chapterRepository'
import { createReadingPositionRepository } from '../../repositories/readingPositionRepository'
import {
  resetReaderDependenciesForTesting,
  setReaderDependenciesForTesting,
  useReaderStore,
} from '../../stores/reader'
import type { WebBookDraft, WebChapterDraft } from '../../types/localData'

describe('reader store', () => {
  let db: WebReaderDb

  beforeEach(async () => {
    setActivePinia(createPinia())
    db = createWebReaderDb(`reader-store-test-${crypto.randomUUID()}`)
    await db.open()
    setReaderDependenciesForTesting({ db })
  })

  afterEach(async () => {
    resetReaderDependenciesForTesting()
    await db.delete()
  })

  it('opens a local book by id and restores the saved chapter index', async () => {
    const book = await seedBookWithChapters(db)
    await createReadingPositionRepository(db).upsert({
      id: 'position-1',
      bookId: book.id,
      currentChapterIndex: 1,
      currentParagraphIndex: 0,
      currentCharOffset: 0,
      progressSyncStatus: 'synced',
    })
    const reader = useReaderStore()

    await reader.openBook(book.id)

    expect(reader.book?.id).toBe(book.id)
    expect(reader.currentChapter?.title).toBe('Chapter Two')
    expect(reader.currentChapter?.content).toContain('Second chapter local text.')
  })

  it('moves between chapters, saves dirty progress, and enqueues position-only sync payloads', async () => {
    const book = await seedBookWithChapters(db)
    const reader = useReaderStore()
    await reader.openBook(book.id)

    await reader.nextChapter()

    expect(reader.currentChapterIndex).toBe(1)
    await expect(createReadingPositionRepository(db).findByBookId(book.id)).resolves.toMatchObject({
      currentChapterIndex: 1,
      currentParagraphIndex: 0,
      currentCharOffset: 0,
      progressSyncStatus: 'dirty',
    })

    await reader.previousChapter()
    expect(reader.currentChapterIndex).toBe(0)

    const events = (await db.web_pending_sync_events.where('eventType').equals('reading_progress').toArray())
      .sort((a, b) => a.createdAt.localeCompare(b.createdAt))
    expect(events).toHaveLength(2)
    expect(events[0]?.payloadJson).toMatchObject({
      localBookId: book.id,
      bookFingerprint: book.bookFingerprint,
      currentChapterIndex: 1,
      currentParagraphIndex: 0,
      currentCharOffset: 0,
      progressSyncStatus: 'dirty',
    })
    expect(JSON.stringify(events.map((event) => event.payloadJson))).not.toMatch(
      /First chapter local text|Second chapter local text|originalFileName|fixture\.txt|content|paragraphText|translatedText|bytes|path/i,
    )
  })

  it('clamps chapter navigation and font size controls', async () => {
    const book = await seedBookWithChapters(db)
    const reader = useReaderStore()
    await reader.openBook(book.id)

    expect(reader.canGoPrevious).toBe(false)
    await reader.previousChapter()
    expect(reader.currentChapterIndex).toBe(0)

    reader.setFontSize(8)
    expect(reader.fontSize).toBe(14)
    reader.setFontSize(40)
    expect(reader.fontSize).toBe(28)

    await reader.nextChapter()
    expect(reader.canGoNext).toBe(false)
    await reader.nextChapter()
    expect(reader.currentChapterIndex).toBe(1)
  })

  it('sets not found state for a missing local book id', async () => {
    const reader = useReaderStore()

    await reader.openBook('missing-book')

    expect(reader.status).toBe('not_found')
    expect(reader.book).toBeNull()
  })
})

async function seedBookWithChapters(db: WebReaderDb) {
  const book = await createBookRepository(db).upsertByOwnerAndFingerprint(bookDraft({}))
  await createChapterRepository(db).replaceForBook(book.id, [
    chapterDraft({
      id: 'chapter-1',
      bookId: book.id,
      chapterIndex: 0,
      title: 'Chapter One',
      content: 'First chapter local text.',
    }),
    chapterDraft({
      id: 'chapter-2',
      bookId: book.id,
      chapterIndex: 1,
      title: 'Chapter Two',
      content: 'Second chapter local text.',
    }),
  ])
  return book
}

function bookDraft(overrides: Partial<WebBookDraft>): WebBookDraft {
  return {
    id: 'book-1',
    ownerUserId: 'user-1',
    bookFingerprint: 'b'.repeat(64),
    title: 'Local Book',
    author: 'Local Author',
    fileType: 'txt',
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    originalFileName: 'fixture.txt',
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
    content: 'Local chapter text.',
    paragraphCount: 1,
    ...overrides,
  }
}
