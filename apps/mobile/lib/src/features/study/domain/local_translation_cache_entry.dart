class LocalTranslationCacheEntry {
  const LocalTranslationCacheEntry({
    required this.id,
    required this.ownerUserId,
    this.bookFingerprint,
    this.chapterIndex,
    this.paragraphIndex,
    required this.sourceTextHash,
    this.sourceTextPreview,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    this.provider,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerUserId;
  final String? bookFingerprint;
  final int? chapterIndex;
  final int? paragraphIndex;
  final String sourceTextHash;
  final String? sourceTextPreview;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final String? provider;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'owner_user_id': ownerUserId,
      'book_fingerprint': bookFingerprint,
      'chapter_index': chapterIndex,
      'paragraph_index': paragraphIndex,
      'source_text_hash': sourceTextHash,
      'source_text_preview': sourceTextPreview,
      'translated_text': translatedText,
      'source_lang': sourceLang,
      'target_lang': targetLang,
      'provider': provider,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory LocalTranslationCacheEntry.fromMap(Map<String, Object?> map) {
    return LocalTranslationCacheEntry(
      id: map['id'] as String,
      ownerUserId: map['owner_user_id'] as String,
      bookFingerprint: map['book_fingerprint'] as String?,
      chapterIndex: map['chapter_index'] as int?,
      paragraphIndex: map['paragraph_index'] as int?,
      sourceTextHash: map['source_text_hash'] as String,
      sourceTextPreview: map['source_text_preview'] as String?,
      translatedText: map['translated_text'] as String,
      sourceLang: map['source_lang'] as String,
      targetLang: map['target_lang'] as String,
      provider: map['provider'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toUtc(),
    );
  }
}
