import 'fake-indexeddb/auto'

import { afterEach, beforeEach, describe, expect, it } from 'vitest'

import { createWebReaderDb, type WebReaderDb } from '../../db/webReaderDb'
import { createBookRepository } from '../../repositories/bookRepository'
import { createChapterRepository } from '../../repositories/chapterRepository'
import { createReadingPositionRepository } from '../../repositories/readingPositionRepository'
import type { WebBookDraft, WebChapterDraft, WebReadingPositionDraft } from '../../types/localData'

describe('book, chapter, and reading position repositories', () => {
  let db: WebReaderDb

  beforeEach(async () => {
    db = createWebReaderDb('book-repository-test')
    await db.open()
  })

  afterEach(async () => {
    await db.delete()
  })

  it('enforces owner + fingerprint uniqueness at the repository boundary', async () => {
    const books = createBookRepository(db)
    const draft = bookDraft({ ownerUserId: 'user-1', bookFingerprint: fingerprint('a') })

    const first = await books.upsertByOwnerAndFingerprint(draft)
    const second = await books.upsertByOwnerAndFingerprint({
      ...draft,
      id: 'book-duplicate',
      title: 'Updated title',
      chapterCount: 3,
    })
    const otherOwner = await books.upsertByOwnerAndFingerprint({
      ...draft,
      id: 'book-other-owner',
      ownerUserId: 'user-2',
    })

    expect(second.id).toBe(first.id)
    expect(second.title).toBe('Updated title')
    expect(otherOwner.id).toBe('book-other-owner')
    await expect(books.listByOwnerUserId('user-1')).resolves.toHaveLength(1)
  })

  it('stores chapter content locally by book and chapter index', async () => {
    const books = createBookRepository(db)
    const chapters = createChapterRepository(db)
    const book = await books.upsertByOwnerAndFingerprint(bookDraft({}))

    await chapters.upsert(chapterDraft({
      bookId: book.id,
      chapterIndex: 0,
      content: 'private chapter text stays in IndexedDB',
    }))

    const stored = await chapters.listByBookId(book.id)
    expect(stored).toHaveLength(1)
    expect(stored[0]?.content).toBe('private chapter text stays in IndexedDB')
  })

  it('rejects negative reading position fields', async () => {
    const positions = createReadingPositionRepository(db)
    const valid = readingPositionDraft({ currentChapterIndex: 0 })

    await expect(positions.upsert(valid)).resolves.toMatchObject({
      bookId: 'book-1',
      currentChapterIndex: 0,
    })
    await expect(
      positions.upsert(readingPositionDraft({ currentParagraphIndex: -1 })),
    ).rejects.toThrow(/non-negative/)
    await expect(
      positions.upsert(readingPositionDraft({ currentCharOffset: -1 })),
    ).rejects.toThrow(/non-negative/)
  })
})

function bookDraft(overrides: Partial<WebBookDraft>): WebBookDraft {
  return {
    id: 'book-1',
    ownerUserId: 'user-1',
    bookFingerprint: fingerprint('0'),
    title: 'Kokoro',
    author: 'Natsume Soseki',
    fileType: 'txt',
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    originalFileName: 'kokoro.txt',
    chapterCount: 1,
    metadataSyncStatus: 'local_only',
    ...overrides,
  }
}

function chapterDraft(overrides: Partial<WebChapterDraft>): WebChapterDraft {
  return {
    id: 'chapter-1',
    bookId: 'book-1',
    chapterIndex: 0,
    title: 'Chapter 1',
    content: 'chapter text',
    paragraphCount: 1,
    ...overrides,
  }
}

function readingPositionDraft(overrides: Partial<WebReadingPositionDraft>): WebReadingPositionDraft {
  return {
    id: 'position-1',
    bookId: 'book-1',
    currentChapterIndex: 0,
    currentParagraphIndex: 0,
    currentCharOffset: 0,
    progressSyncStatus: 'dirty',
    ...overrides,
  }
}

function fingerprint(seed: string): string {
  return seed.repeat(64).slice(0, 64)
}
