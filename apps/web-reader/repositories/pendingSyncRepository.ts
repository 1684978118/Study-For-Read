import type { WebReaderDb } from '../db/webReaderDb'
import type { JsonValue, WebPendingSyncEvent, WebPendingSyncEventDraft, WebPendingSyncEventType } from '../types/localData'

const allowedEventTypes = new Set<WebPendingSyncEventType>([
  'book_metadata',
  'reading_progress',
  'word_card_create',
  'word_card_review',
  'daily_stats',
])

const forbiddenPayloadKeys = new Set([
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
])

export function createPendingSyncRepository(db: WebReaderDb) {
  return new PendingSyncRepository(db)
}

export class PendingSyncRepository {
  constructor(private readonly db: WebReaderDb) {}

  async enqueue(draft: WebPendingSyncEventDraft): Promise<WebPendingSyncEvent> {
    validateEventType(draft.eventType)
    validatePayload(draft.payloadJson)
    const now = nowIso()
    const existing = await this.db.web_pending_sync_events.get(draft.id)
    const event: WebPendingSyncEvent = {
      ...draft,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    }
    await this.db.web_pending_sync_events.put(event)
    return event
  }

  async listPendingByOwner(ownerUserId: string): Promise<WebPendingSyncEvent[]> {
    return this.db.web_pending_sync_events
      .where('[ownerUserId+status]')
      .equals([ownerUserId, 'pending'])
      .toArray()
  }

  async markDone(id: string): Promise<void> {
    await this.db.web_pending_sync_events.update(id, {
      status: 'done',
      updatedAt: nowIso(),
    })
  }

  async markFailed(id: string, errorCode: string): Promise<void> {
    const event = await this.db.web_pending_sync_events.get(id)
    await this.db.web_pending_sync_events.update(id, {
      status: 'failed',
      attemptCount: (event?.attemptCount ?? 0) + 1,
      lastErrorCode: errorCode,
      lastAttemptedAt: nowIso(),
      updatedAt: nowIso(),
    })
  }
}

function validateEventType(eventType: WebPendingSyncEventType): void {
  if (!allowedEventTypes.has(eventType)) {
    throw new Error(`Unsupported pending sync event type: ${eventType}`)
  }
}

function validatePayload(value: JsonValue, path = ''): void {
  if (Array.isArray(value)) {
    value.forEach((item, index) => validatePayload(item, `${path}[${index}]`))
    return
  }
  if (value && typeof value === 'object') {
    for (const [key, child] of Object.entries(value)) {
      if (forbiddenPayloadKeys.has(key)) {
        throw new Error(`Pending sync payload must not contain ${key}`)
      }
      validatePayload(child, path ? `${path}.${key}` : key)
    }
  }
}

function nowIso(): string {
  return new Date().toISOString()
}
