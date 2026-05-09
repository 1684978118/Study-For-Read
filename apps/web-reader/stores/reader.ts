import { defineStore } from 'pinia'

import { createWebReaderDb, type WebReaderDb } from '../db/webReaderDb'
import { createBookRepository } from '../repositories/bookRepository'
import { createChapterRepository } from '../repositories/chapterRepository'
import { createPendingSyncRepository } from '../repositories/pendingSyncRepository'
import { createReadingPositionRepository } from '../repositories/readingPositionRepository'
import type { WebBook, WebChapter, WebReadingPosition } from '../types/localData'

type ReaderStatus = 'idle' | 'loading' | 'ready' | 'not_found' | 'empty' | 'error'
type ReaderTheme = 'light' | 'sepia' | 'dark'

const minFontSize = 14
const maxFontSize = 28

interface ReaderDependencies {
  db: WebReaderDb
}

let testDependencies: ReaderDependencies | null = null
let defaultDb: WebReaderDb | null = null

export const useReaderStore = defineStore('reader', {
  state: () => ({
    status: 'idle' as ReaderStatus,
    book: null as WebBook | null,
    chapters: [] as WebChapter[],
    position: null as WebReadingPosition | null,
    currentChapterIndex: 0,
    fontSize: 18,
    theme: 'light' as ReaderTheme,
    errorMessage: null as string | null,
  }),
  getters: {
    currentChapter: (state): WebChapter | null =>
      state.chapters.find((chapter) => chapter.chapterIndex === state.currentChapterIndex) ?? null,
    canGoPrevious: (state): boolean => state.currentChapterIndex > 0,
    canGoNext: (state): boolean => state.currentChapterIndex < state.chapters.length - 1,
  },
  actions: {
    async openBook(localBookId: string) {
      this.status = 'loading'
      this.errorMessage = null
      this.book = null
      this.chapters = []
      this.position = null
      this.currentChapterIndex = 0

      try {
        const { books, chapters, positions } = repositories()
        const book = await books.findById(localBookId)
        if (!book) {
          this.status = 'not_found'
          return
        }

        const localChapters = await chapters.listByBookId(book.id)
        this.book = book
        this.chapters = localChapters
        if (localChapters.length === 0) {
          this.status = 'empty'
          return
        }

        const savedPosition = await positions.findByBookId(book.id)
        this.position = savedPosition ?? null
        this.currentChapterIndex = clampChapterIndex(
          savedPosition?.currentChapterIndex ?? 0,
          localChapters.length,
        )
        this.status = 'ready'
      }
      catch (error) {
        this.status = 'error'
        this.errorMessage = messageFromError(error)
      }
    },
    async nextChapter() {
      if (!this.canGoNext) {
        return
      }
      await this.moveToChapter(this.currentChapterIndex + 1)
    },
    async previousChapter() {
      if (!this.canGoPrevious) {
        return
      }
      await this.moveToChapter(this.currentChapterIndex - 1)
    },
    async moveToChapter(chapterIndex: number) {
      if (!this.book || this.chapters.length === 0) {
        return
      }
      this.currentChapterIndex = clampChapterIndex(chapterIndex, this.chapters.length)
      this.position = await saveProgress({
        book: this.book,
        chapterIndex: this.currentChapterIndex,
      })
    },
    setFontSize(value: number) {
      this.fontSize = Math.min(maxFontSize, Math.max(minFontSize, value))
    },
    setTheme(value: ReaderTheme) {
      this.theme = value
    },
  },
})

export function setReaderDependenciesForTesting(dependencies: ReaderDependencies): void {
  testDependencies = dependencies
}

export function resetReaderDependenciesForTesting(): void {
  testDependencies = null
  defaultDb = null
}

function repositories() {
  const db = testDependencies?.db ?? getDefaultDb()
  return {
    books: createBookRepository(db),
    chapters: createChapterRepository(db),
    positions: createReadingPositionRepository(db),
    pendingSync: createPendingSyncRepository(db),
  }
}

async function saveProgress(input: {
  book: WebBook
  chapterIndex: number
}): Promise<WebReadingPosition> {
  const { positions, pendingSync } = repositories()
  const position = await positions.upsert({
    id: crypto.randomUUID(),
    bookId: input.book.id,
    currentChapterIndex: input.chapterIndex,
    currentParagraphIndex: 0,
    currentCharOffset: 0,
    progressSyncStatus: 'dirty',
    lastReadAt: new Date().toISOString(),
  })
  await pendingSync.enqueue({
    id: crypto.randomUUID(),
    ownerUserId: input.book.ownerUserId,
    eventType: 'reading_progress',
    payloadJson: {
      localBookId: input.book.id,
      bookFingerprint: input.book.bookFingerprint,
      currentChapterIndex: position.currentChapterIndex,
      currentParagraphIndex: position.currentParagraphIndex,
      currentCharOffset: position.currentCharOffset,
      progressSyncStatus: position.progressSyncStatus,
      lastReadAt: position.lastReadAt ?? null,
    },
    status: 'pending',
    attemptCount: 0,
  })
  return position
}

function getDefaultDb(): WebReaderDb {
  defaultDb ??= createWebReaderDb()
  return defaultDb
}

function clampChapterIndex(value: number, chapterCount: number): number {
  if (chapterCount <= 0) {
    return 0
  }
  return Math.min(chapterCount - 1, Math.max(0, value))
}

function messageFromError(error: unknown): string {
  if (error instanceof Error && error.message) {
    return error.message
  }
  return 'Reader failed to load.'
}
