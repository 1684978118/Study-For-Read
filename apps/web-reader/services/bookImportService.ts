import { createWebReaderDb, type WebReaderDb } from '../db/webReaderDb'
import { parseEpubFile } from '../parsers/epubParser'
import { parseTxtFile } from '../parsers/txtParser'
import { createBookRepository } from '../repositories/bookRepository'
import { createChapterRepository } from '../repositories/chapterRepository'
import { createPendingSyncRepository } from '../repositories/pendingSyncRepository'
import { createReadingPositionRepository } from '../repositories/readingPositionRepository'
import type { ParsedBook } from '../parsers/parsedBook'
import type { WebBook, WebFileType } from '../types/localData'
import { detectBookFileType } from '../utils/bookFileType'
import { calculateBookFingerprint } from '../utils/bookFingerprint'

export interface ImportBookFileInput {
  file: File
  ownerUserId: string
  sourceLang?: string
  targetLang?: string
  db?: WebReaderDb
}

export interface ImportBookFileResult {
  book: WebBook
}

export class BookImportError extends Error {
  constructor(
    readonly code: string,
    message: string,
  ) {
    super(message)
    this.name = 'BookImportError'
  }
}

export async function importBookFile(input: ImportBookFileInput): Promise<ImportBookFileResult> {
  const fileType = detectFileType(input.file)
  const fingerprint = await fingerprintFile(input.file)
  const parsedBook = await parseBook(input.file, fileType)
  const db = input.db ?? createWebReaderDb()
  const books = createBookRepository(db)
  const chapters = createChapterRepository(db)
  const positions = createReadingPositionRepository(db)
  const pendingSync = createPendingSyncRepository(db)
  const sourceLang = input.sourceLang ?? 'ja'
  const targetLang = input.targetLang ?? 'zh-CN'

  const book = await books.upsertByOwnerAndFingerprint({
    id: crypto.randomUUID(),
    ownerUserId: input.ownerUserId,
    bookFingerprint: fingerprint,
    title: parsedBook.title,
    author: parsedBook.author,
    fileType,
    sourceLang,
    targetLang,
    originalFileName: parsedBook.originalFileName,
    chapterCount: parsedBook.chapters.length,
    metadataSyncStatus: 'local_only',
  })

  await chapters.replaceForBook(
    book.id,
    parsedBook.chapters.map((chapter) => ({
      id: crypto.randomUUID(),
      bookId: book.id,
      chapterIndex: chapter.chapterIndex,
      title: chapter.title,
      content: chapter.content,
      paragraphCount: chapter.paragraphs.length,
    })),
  )

  const existingPosition = await positions.findByBookId(book.id)
  if (!existingPosition) {
    await positions.upsert({
      id: crypto.randomUUID(),
      bookId: book.id,
      currentChapterIndex: 0,
      currentParagraphIndex: 0,
      currentCharOffset: 0,
      progressSyncStatus: 'local_only',
    })
  }

  await pendingSync.enqueue({
    id: crypto.randomUUID(),
    ownerUserId: input.ownerUserId,
    eventType: 'book_metadata',
    payloadJson: {
      localBookId: book.id,
      fingerprint: book.bookFingerprint,
      title: book.title,
      ...(book.author ? { author: book.author } : {}),
      fileType: book.fileType,
      sourceLang: book.sourceLang,
      targetLang: book.targetLang,
      chapterCount: book.chapterCount,
      updatedAt: book.updatedAt,
    },
    status: 'pending',
    attemptCount: 0,
  })

  return { book }
}

function detectFileType(file: File): WebFileType {
  const result = detectBookFileType(file)
  if (!result.ok) {
    throw new BookImportError(result.error.code, result.error.message)
  }
  return result.fileType
}

async function fingerprintFile(file: File): Promise<string> {
  const result = await calculateBookFingerprint(file)
  if (!result.ok) {
    throw new BookImportError(result.error.code, result.error.message)
  }
  return result.fingerprint
}

async function parseBook(file: File, fileType: WebFileType): Promise<ParsedBook> {
  const result = fileType === 'txt'
    ? await parseTxtFile(file)
    : await parseEpubFile(file)
  if (!result.ok) {
    throw new BookImportError(result.error.code, result.error.message)
  }
  return result.book
}
