import type { WebReaderDb } from '../db/webReaderDb'
import type {
  WebLexeme,
  WebTranslationCacheEntry,
  WebTranslationCacheEntryDraft,
  WebWordCard,
  WebWordCardDraft,
} from '../types/localData'

export function createLearningRepository(db: WebReaderDb) {
  return new LearningRepository(db)
}

export class LearningRepository {
  constructor(private readonly db: WebReaderDb) {}

  async upsertLexeme(lexeme: WebLexeme): Promise<WebLexeme> {
    await this.db.web_lexeme_cache.put(lexeme)
    return lexeme
  }

  async getLexemeById(id: string): Promise<WebLexeme | undefined> {
    return this.db.web_lexeme_cache.get(id)
  }

  async upsertWordCard(draft: WebWordCardDraft): Promise<WebWordCard> {
    validateWordCardDraft(draft)
    const now = nowIso()
    const existing = draft.cardType === 'lexeme' && draft.lexemeId
      ? await this.db.web_word_cards
        .where('[ownerUserId+lexemeId]')
        .equals([draft.ownerUserId, draft.lexemeId])
        .first()
      : await this.db.web_word_cards.get(draft.id)
    const card: WebWordCard = {
      ...draft,
      id: existing?.id ?? draft.id,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    }
    await this.db.web_word_cards.put(card)
    return card
  }

  async listWordCardsByOwner(ownerUserId: string): Promise<WebWordCard[]> {
    return this.db.web_word_cards.where('ownerUserId').equals(ownerUserId).toArray()
  }

  async listPrivateSentenceCardsByOwner(ownerUserId: string): Promise<WebWordCard[]> {
    return this.db.web_word_cards
      .where('ownerUserId')
      .equals(ownerUserId)
      .filter((card) => card.cardType === 'private_sentence')
      .toArray()
  }

  async upsertTranslationCache(entry: WebTranslationCacheEntryDraft): Promise<WebTranslationCacheEntry> {
    const now = nowIso()
    const existing = await this.db.web_translation_cache
      .where('[ownerUserId+sourceLang+targetLang+sourceTextHash]')
      .equals([entry.ownerUserId, entry.sourceLang, entry.targetLang, entry.sourceTextHash])
      .first()
    const cacheEntry: WebTranslationCacheEntry = {
      ...entry,
      id: existing?.id ?? entry.id,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    }
    await this.db.web_translation_cache.put(cacheEntry)
    return cacheEntry
  }

  async findTranslationCache(params: {
    ownerUserId: string
    sourceLang: string
    targetLang: string
    sourceTextHash: string
  }): Promise<WebTranslationCacheEntry | undefined> {
    return this.db.web_translation_cache
      .where('[ownerUserId+sourceLang+targetLang+sourceTextHash]')
      .equals([params.ownerUserId, params.sourceLang, params.targetLang, params.sourceTextHash])
      .first()
  }
}

function validateWordCardDraft(draft: WebWordCardDraft): void {
  if (draft.cardType === 'lexeme' && !draft.lexemeId?.trim()) {
    throw new Error('lexemeId is required for lexeme cards')
  }
  if (draft.cardType === 'private_sentence') {
    if (!draft.privateSurface?.trim()) {
      throw new Error('privateSurface is required for private sentence cards')
    }
    if (!draft.privateDefinition?.trim()) {
      throw new Error('privateDefinition is required for private sentence cards')
    }
  }
  if (draft.reviewCount < 0) {
    throw new Error('reviewCount must be non-negative')
  }
}

function nowIso(): string {
  return new Date().toISOString()
}
