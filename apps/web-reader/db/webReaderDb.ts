import Dexie, { type EntityTable } from 'dexie'

import type {
  WebBook,
  WebChapter,
  WebLexeme,
  WebPendingSyncEvent,
  WebReadingPosition,
  WebStudyDailyStats,
  WebTranslationCacheEntry,
  WebWordCard,
} from '../types/localData'
import { WEB_READER_SCHEMA_VERSION, webReaderStores } from './webReaderSchema'

export class WebReaderDb extends Dexie {
  web_books!: EntityTable<WebBook, 'id'>
  web_chapters!: EntityTable<WebChapter, 'id'>
  web_reading_positions!: EntityTable<WebReadingPosition, 'id'>
  web_lexeme_cache!: EntityTable<WebLexeme, 'id'>
  web_word_cards!: EntityTable<WebWordCard, 'id'>
  web_translation_cache!: EntityTable<WebTranslationCacheEntry, 'id'>
  web_study_daily_stats!: EntityTable<WebStudyDailyStats, 'id'>
  web_pending_sync_events!: EntityTable<WebPendingSyncEvent, 'id'>

  constructor(name = 'study-for-read-web-reader') {
    super(name)
    this.version(WEB_READER_SCHEMA_VERSION).stores(webReaderStores)
  }
}

export function createWebReaderDb(name?: string): WebReaderDb {
  return new WebReaderDb(name)
}
