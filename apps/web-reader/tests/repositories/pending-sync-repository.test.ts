import 'fake-indexeddb/auto'

import { afterEach, beforeEach, describe, expect, it } from 'vitest'

import { createWebReaderDb, type WebReaderDb } from '../../db/webReaderDb'
import { createPendingSyncRepository } from '../../repositories/pendingSyncRepository'
import type { WebPendingSyncEventDraft } from '../../types/localData'

describe('pending sync repository', () => {
  let db: WebReaderDb

  beforeEach(async () => {
    db = createWebReaderDb('pending-sync-repository-test')
    await db.open()
  })

  afterEach(async () => {
    await db.delete()
  })

  it('accepts only allowed event types and lists pending events by owner', async () => {
    const pending = createPendingSyncRepository(db)
    const event = await pending.enqueue(eventDraft({
      id: 'event-1',
      ownerUserId: 'user-1',
      eventType: 'book_metadata',
      payloadJson: {
        bookFingerprint: 'a'.repeat(64),
        title: 'Kokoro',
        fileType: 'txt',
        sourceLang: 'ja',
        targetLang: 'zh-CN',
        chapterCount: 1,
      },
    }))

    await pending.enqueue(eventDraft({
      id: 'event-2',
      ownerUserId: 'user-2',
      eventType: 'daily_stats',
      payloadJson: { statDate: '2026-05-09', lookupCount: 1 },
    }))

    expect(event.status).toBe('pending')
    await expect(pending.listPendingByOwner('user-1')).resolves.toEqual([
      expect.objectContaining({ id: 'event-1', eventType: 'book_metadata' }),
    ])
    await expect(
      pending.enqueue(eventDraft({ id: 'bad-event', eventType: 'translation_cache' as never })),
    ).rejects.toThrow(/event type/)
  })

  it('rejects raw content, path, paragraph, and translation cache fields in payloads', async () => {
    const pending = createPendingSyncRepository(db)

    for (const forbiddenKey of [
      'content',
      'chapterContent',
      'chapter_content',
      'originalFile',
      'original_file',
      'filePath',
      'file_path',
      'rawText',
      'raw_text',
      'translatedText',
      'translated_text',
      'paragraphText',
      'paragraph_text',
    ]) {
      await expect(
        pending.enqueue(eventDraft({
          id: `event-${forbiddenKey}`,
          payloadJson: {
            bookFingerprint: 'a'.repeat(64),
            [forbiddenKey]: 'must stay local',
          },
        })),
      ).rejects.toThrow(forbiddenKey)
    }
  })
})

function eventDraft(overrides: Partial<WebPendingSyncEventDraft>): WebPendingSyncEventDraft {
  return {
    id: 'event-1',
    ownerUserId: 'user-1',
    eventType: 'reading_progress',
    payloadJson: {
      bookFingerprint: 'a'.repeat(64),
      currentChapterIndex: 0,
      currentParagraphIndex: 0,
      currentCharOffset: 0,
    },
    status: 'pending',
    attemptCount: 0,
    lastErrorCode: undefined,
    ...overrides,
  }
}
