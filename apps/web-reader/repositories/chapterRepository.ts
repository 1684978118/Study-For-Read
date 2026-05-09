import type { WebReaderDb } from '../db/webReaderDb'
import type { WebChapter, WebChapterDraft } from '../types/localData'

export function createChapterRepository(db: WebReaderDb) {
  return new ChapterRepository(db)
}

export class ChapterRepository {
  constructor(private readonly db: WebReaderDb) {}

  async upsert(draft: WebChapterDraft): Promise<WebChapter> {
    validateChapterDraft(draft)
    const now = nowIso()
    const existing = await this.db.web_chapters
      .where('[bookId+chapterIndex]')
      .equals([draft.bookId, draft.chapterIndex])
      .first()
    const chapter: WebChapter = {
      ...draft,
      id: existing?.id ?? draft.id,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    }
    await this.db.web_chapters.put(chapter)
    return chapter
  }

  async replaceForBook(bookId: string, drafts: WebChapterDraft[]): Promise<WebChapter[]> {
    if (!bookId.trim()) {
      throw new Error('bookId is required')
    }
    drafts.forEach(validateChapterDraft)
    const now = nowIso()
    const chapters = drafts.map((draft) => ({
      ...draft,
      createdAt: now,
      updatedAt: now,
    }))
    await this.db.transaction('rw', this.db.web_chapters, async () => {
      await this.db.web_chapters.where('bookId').equals(bookId).delete()
      await this.db.web_chapters.bulkPut(chapters)
    })
    return chapters
  }

  async listByBookId(bookId: string): Promise<WebChapter[]> {
    const chapters = await this.db.web_chapters.where('bookId').equals(bookId).toArray()
    return chapters.sort((a, b) => a.chapterIndex - b.chapterIndex)
  }

  async findByBookIdAndIndex(bookId: string, chapterIndex: number): Promise<WebChapter | undefined> {
    return this.db.web_chapters.where('[bookId+chapterIndex]').equals([bookId, chapterIndex]).first()
  }
}

function validateChapterDraft(draft: WebChapterDraft): void {
  if (!draft.bookId.trim()) {
    throw new Error('bookId is required')
  }
  if (draft.chapterIndex < 0) {
    throw new Error('chapterIndex must be non-negative')
  }
  if (!draft.title.trim()) {
    throw new Error('title is required')
  }
  if (draft.paragraphCount < 1) {
    throw new Error('paragraphCount must be at least 1')
  }
}

function nowIso(): string {
  return new Date().toISOString()
}
