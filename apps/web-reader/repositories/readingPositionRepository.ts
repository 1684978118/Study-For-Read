import type { WebReaderDb } from '../db/webReaderDb'
import type { WebReadingPosition, WebReadingPositionDraft } from '../types/localData'

export function createReadingPositionRepository(db: WebReaderDb) {
  return new ReadingPositionRepository(db)
}

export class ReadingPositionRepository {
  constructor(private readonly db: WebReaderDb) {}

  async upsert(draft: WebReadingPositionDraft): Promise<WebReadingPosition> {
    validateReadingPositionDraft(draft)
    const now = nowIso()
    const existing = await this.db.web_reading_positions.where('bookId').equals(draft.bookId).first()
    const position: WebReadingPosition = {
      ...draft,
      id: existing?.id ?? draft.id,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    }
    await this.db.web_reading_positions.put(position)
    return position
  }

  async findByBookId(bookId: string): Promise<WebReadingPosition | undefined> {
    return this.db.web_reading_positions.where('bookId').equals(bookId).first()
  }
}

function validateReadingPositionDraft(draft: WebReadingPositionDraft): void {
  if (draft.currentChapterIndex < 0) {
    throw new Error('currentChapterIndex must be non-negative')
  }
  if (draft.currentParagraphIndex < 0) {
    throw new Error('currentParagraphIndex must be non-negative')
  }
  if (draft.currentCharOffset < 0) {
    throw new Error('currentCharOffset must be non-negative')
  }
}

function nowIso(): string {
  return new Date().toISOString()
}
