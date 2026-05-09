import type { WebReaderDb } from '../db/webReaderDb'
import type { WebBook, WebBookDraft } from '../types/localData'

export function createBookRepository(db: WebReaderDb) {
  return new BookRepository(db)
}

export class BookRepository {
  constructor(private readonly db: WebReaderDb) {}

  async upsertByOwnerAndFingerprint(draft: WebBookDraft): Promise<WebBook> {
    validateBookDraft(draft)
    const now = nowIso()
    const existing = await this.db.web_books
      .where('[ownerUserId+bookFingerprint]')
      .equals([draft.ownerUserId, draft.bookFingerprint])
      .first()
    const book: WebBook = {
      ...draft,
      id: existing?.id ?? draft.id,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    }
    await this.db.web_books.put(book)
    return book
  }

  async findById(id: string): Promise<WebBook | undefined> {
    return this.db.web_books.get(id)
  }

  async findByOwnerAndFingerprint(ownerUserId: string, bookFingerprint: string): Promise<WebBook | undefined> {
    return this.db.web_books
      .where('[ownerUserId+bookFingerprint]')
      .equals([ownerUserId, bookFingerprint])
      .first()
  }

  async listByOwnerUserId(ownerUserId: string): Promise<WebBook[]> {
    return this.db.web_books.where('ownerUserId').equals(ownerUserId).toArray()
  }
}

function validateBookDraft(draft: WebBookDraft): void {
  if (!draft.ownerUserId.trim()) {
    throw new Error('ownerUserId is required')
  }
  if (!/^[0-9a-f]{64}$/.test(draft.bookFingerprint)) {
    throw new Error('bookFingerprint must be a lowercase SHA-256 hex string')
  }
  if (!draft.title.trim()) {
    throw new Error('title is required')
  }
  if (draft.fileType !== 'txt' && draft.fileType !== 'epub') {
    throw new Error('fileType must be txt or epub')
  }
  if (draft.chapterCount < 1) {
    throw new Error('chapterCount must be at least 1')
  }
}

function nowIso(): string {
  return new Date().toISOString()
}
