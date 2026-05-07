class LocalReadingPosition {
  const LocalReadingPosition({
    required this.id,
    required this.bookId,
    required this.currentChapterIndex,
    required this.currentParagraphIndex,
    required this.currentCharOffset,
    required this.progressSyncStatus,
    required this.lastReadAt,
    required this.lastSyncedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String bookId;
  final int currentChapterIndex;
  final int currentParagraphIndex;
  final int currentCharOffset;
  final String progressSyncStatus;
  final DateTime? lastReadAt;
  final DateTime? lastSyncedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'current_chapter_index': currentChapterIndex,
      'current_paragraph_index': currentParagraphIndex,
      'current_char_offset': currentCharOffset,
      'progress_sync_status': progressSyncStatus,
      'last_read_at': lastReadAt?.toUtc().toIso8601String(),
      'last_synced_at': lastSyncedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory LocalReadingPosition.fromMap(Map<String, Object?> map) {
    return LocalReadingPosition(
      id: map['id'] as String,
      bookId: map['book_id'] as String,
      currentChapterIndex: map['current_chapter_index'] as int,
      currentParagraphIndex: map['current_paragraph_index'] as int,
      currentCharOffset: map['current_char_offset'] as int,
      progressSyncStatus: map['progress_sync_status'] as String,
      lastReadAt: _dateTimeFrom(map['last_read_at']),
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
