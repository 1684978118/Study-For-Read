class LocalBook {
  const LocalBook({
    required this.id,
    required this.ownerUserId,
    required this.bookFingerprint,
    required this.title,
    this.author,
    required this.fileType,
    required this.sourceLang,
    required this.targetLang,
    required this.originalFilePath,
    required this.chapterCount,
    required this.metadataSyncStatus,
    required this.lastOpenedAt,
    required this.lastSyncedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerUserId;
  final String bookFingerprint;
  final String title;
  final String? author;
  final String fileType;
  final String sourceLang;
  final String targetLang;
  final String originalFilePath;
  final int chapterCount;
  final String metadataSyncStatus;
  final DateTime? lastOpenedAt;
  final DateTime? lastSyncedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'owner_user_id': ownerUserId,
      'book_fingerprint': bookFingerprint,
      'title': title,
      'author': author,
      'file_type': fileType,
      'source_lang': sourceLang,
      'target_lang': targetLang,
      'original_file_path': originalFilePath,
      'chapter_count': chapterCount,
      'metadata_sync_status': metadataSyncStatus,
      'last_opened_at': lastOpenedAt?.toUtc().toIso8601String(),
      'last_synced_at': lastSyncedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory LocalBook.fromMap(Map<String, Object?> map) {
    return LocalBook(
      id: map['id'] as String,
      ownerUserId: map['owner_user_id'] as String,
      bookFingerprint: map['book_fingerprint'] as String,
      title: map['title'] as String,
      author: map['author'] as String?,
      fileType: map['file_type'] as String,
      sourceLang: map['source_lang'] as String,
      targetLang: map['target_lang'] as String,
      originalFilePath: map['original_file_path'] as String,
      chapterCount: map['chapter_count'] as int,
      metadataSyncStatus: map['metadata_sync_status'] as String,
      lastOpenedAt: _dateTimeFrom(map['last_opened_at']),
      lastSyncedAt: _dateTimeFrom(map['last_synced_at']),
      createdAt: _dateTimeFrom(map['created_at'])!,
      updatedAt: _dateTimeFrom(map['updated_at'])!,
    );
  }

  static DateTime? _dateTimeFrom(Object? value) {
    if (value == null) {
      return null;
    }
    return DateTime.parse(value as String).toUtc();
  }
}
