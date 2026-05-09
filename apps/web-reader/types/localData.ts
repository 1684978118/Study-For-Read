export type WebFileType = 'txt' | 'epub'
export type WebSyncStatus = 'local_only' | 'synced' | 'dirty' | 'failed'
export type WebCardType = 'lexeme' | 'private_sentence'
export type WebReviewStatus = 'new' | 'learning' | 'reviewing' | 'mastered'
export type WebLexemeEntryType = 'word' | 'phrase' | 'idiom'
export type WebLexemeStatus = 'active' | 'candidate' | 'rejected'
export type WebPendingSyncEventType =
  | 'book_metadata'
  | 'reading_progress'
  | 'word_card_create'
  | 'word_card_review'
  | 'daily_stats'
export type WebPendingSyncStatus = 'pending' | 'done' | 'failed'

export type JsonPrimitive = string | number | boolean | null
export type JsonValue = JsonPrimitive | JsonValue[] | { [key: string]: JsonValue }
export type JsonObject = { [key: string]: JsonValue }

export interface TimestampedLocalRecord {
  createdAt: string
  updatedAt: string
}

export interface WebBook extends TimestampedLocalRecord {
  id: string
  ownerUserId: string
  bookFingerprint: string
  title: string
  author?: string
  fileType: WebFileType
  sourceLang: string
  targetLang: string
  originalFileName: string
  chapterCount: number
  metadataSyncStatus: WebSyncStatus
  lastOpenedAt?: string
  lastSyncedAt?: string
}

export type WebBookDraft = Omit<WebBook, 'createdAt' | 'updatedAt'>

export interface WebChapter extends TimestampedLocalRecord {
  id: string
  bookId: string
  chapterIndex: number
  title: string
  content: string
  paragraphCount: number
}

export type WebChapterDraft = Omit<WebChapter, 'createdAt' | 'updatedAt'>

export interface WebReadingPosition extends TimestampedLocalRecord {
  id: string
  bookId: string
  currentChapterIndex: number
  currentParagraphIndex: number
  currentCharOffset: number
  progressSyncStatus: WebSyncStatus
  lastReadAt?: string
  lastSyncedAt?: string
}

export type WebReadingPositionDraft = Omit<WebReadingPosition, 'createdAt' | 'updatedAt'>

export interface WebLexeme extends TimestampedLocalRecord {
  id: string
  surface: string
  normalizedSurface: string
  reading?: string | null
  sourceLang: string
  targetLang: string
  entryType: WebLexemeEntryType
  partOfSpeech?: string | null
  definition: string
  shortDefinition?: string | null
  example?: string | null
  status: WebLexemeStatus
}

export interface WebWordCard extends TimestampedLocalRecord {
  id: string
  ownerUserId: string
  cardType: WebCardType
  lexemeId?: string
  privateSurface?: string
  privateDefinition?: string
  privateContext?: string
  sourceBookFingerprint?: string
  sourceBookTitle?: string
  reviewStatus: WebReviewStatus
  reviewCount: number
  nextReviewAt?: string
  lastReviewedAt?: string
  syncStatus: WebSyncStatus
  serverCardId?: string
}

export type WebWordCardDraft = Omit<WebWordCard, 'createdAt' | 'updatedAt'>

export interface WebTranslationCacheEntry extends TimestampedLocalRecord {
  id: string
  ownerUserId: string
  sourceLang: string
  targetLang: string
  sourceTextHash: string
  translatedText: string
  provider?: string
  lastUsedAt?: string
}

export type WebTranslationCacheEntryDraft = Omit<WebTranslationCacheEntry, 'createdAt' | 'updatedAt'>

export interface WebStudyDailyStats extends TimestampedLocalRecord {
  id: string
  ownerUserId: string
  statDate: string
  readingMinutes: number
  lookupCount: number
  paragraphTranslationCount: number
  cardsCreated: number
  cardsReviewed: number
  syncStatus: WebSyncStatus
  lastSyncedAt?: string
}

export type WebStudyDailyStatsCounters = Pick<
  WebStudyDailyStats,
  'readingMinutes' | 'lookupCount' | 'paragraphTranslationCount' | 'cardsCreated' | 'cardsReviewed'
>

export interface WebPendingSyncEvent extends TimestampedLocalRecord {
  id: string
  ownerUserId: string
  eventType: WebPendingSyncEventType
  payloadJson: JsonObject
  status: WebPendingSyncStatus
  attemptCount: number
  lastErrorCode?: string
  lastAttemptedAt?: string
}

export type WebPendingSyncEventDraft = Omit<WebPendingSyncEvent, 'createdAt' | 'updatedAt'>
