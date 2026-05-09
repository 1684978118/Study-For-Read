import 'fake-indexeddb/auto'

import { afterEach, describe, expect, it } from 'vitest'

import { createWebReaderDb } from '../../db/webReaderDb'
import { WEB_READER_SCHEMA_VERSION, webReaderStores } from '../../db/webReaderSchema'

describe('web reader Dexie database', () => {
  afterEach(async () => {
    await createWebReaderDb('web-reader-db-test').delete()
  })

  it('declares deterministic version 1 stores for local reader data', async () => {
    const db = createWebReaderDb('web-reader-db-test')

    expect(WEB_READER_SCHEMA_VERSION).toBe(1)
    expect(Object.keys(webReaderStores).sort()).toEqual([
      'web_books',
      'web_chapters',
      'web_lexeme_cache',
      'web_pending_sync_events',
      'web_reading_positions',
      'web_study_daily_stats',
      'web_translation_cache',
      'web_word_cards',
    ])

    await db.open()

    expect(db.tables.map((table) => table.name).sort()).toEqual(Object.keys(webReaderStores).sort())
  })
})
