export const WEB_READER_SCHEMA_VERSION = 1

export const webReaderStores = {
  web_books: '&id,[ownerUserId+bookFingerprint],ownerUserId,bookFingerprint,metadataSyncStatus',
  web_chapters: '&id,[bookId+chapterIndex],bookId,chapterIndex',
  web_reading_positions: '&id,&bookId,progressSyncStatus',
  web_lexeme_cache: '&id,[sourceLang+targetLang+normalizedSurface+entryType],status',
  web_word_cards: '&id,ownerUserId,[ownerUserId+lexemeId],cardType,nextReviewAt,syncStatus,serverCardId',
  web_translation_cache: '&id,[ownerUserId+sourceLang+targetLang+sourceTextHash],ownerUserId',
  web_study_daily_stats: '&id,[ownerUserId+statDate],ownerUserId,statDate,syncStatus',
  web_pending_sync_events: '&id,ownerUserId,eventType,status,[ownerUserId+status]',
} as const
