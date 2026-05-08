class LocalStudyDailyStat {
  const LocalStudyDailyStat({
    required this.id,
    required this.ownerUserId,
    required this.statDate,
    required this.readingMinutes,
    required this.lookupCount,
    required this.paragraphTranslationCount,
    required this.cardsCreated,
    required this.cardsReviewed,
    required this.syncStatus,
    this.lastSyncedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerUserId;
  final DateTime statDate;
  final int readingMinutes;
  final int lookupCount;
  final int paragraphTranslationCount;
  final int cardsCreated;
  final int cardsReviewed;
  final String syncStatus;
  final DateTime? lastSyncedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'owner_user_id': ownerUserId,
      'stat_date': dateString(statDate),
      'reading_minutes': readingMinutes,
      'lookup_count': lookupCount,
      'paragraph_translation_count': paragraphTranslationCount,
      'cards_created': cardsCreated,
      'cards_reviewed': cardsReviewed,
      'sync_status': syncStatus,
      'last_synced_at': lastSyncedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory LocalStudyDailyStat.fromMap(Map<String, Object?> map) {
    return LocalStudyDailyStat(
      id: map['id'] as String,
      ownerUserId: map['owner_user_id'] as String,
      statDate: parseDateString(map['stat_date'] as String),
      readingMinutes: map['reading_minutes'] as int,
      lookupCount: map['lookup_count'] as int,
      paragraphTranslationCount: map['paragraph_translation_count'] as int,
      cardsCreated: map['cards_created'] as int,
      cardsReviewed: map['cards_reviewed'] as int,
      syncStatus: map['sync_status'] as String,
      lastSyncedAt: _dateTimeFrom(map['last_synced_at']),
      createdAt: _dateTimeFrom(map['created_at'])!,
      updatedAt: _dateTimeFrom(map['updated_at'])!,
    );
  }

  static String dateString(DateTime date) {
    final normalized = DateTime.utc(date.year, date.month, date.day);
    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static DateTime parseDateString(String value) {
    final parts = value.split('-');
    return DateTime.utc(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static DateTime? _dateTimeFrom(Object? value) {
    if (value == null) {
      return null;
    }
    return DateTime.parse(value as String).toUtc();
  }
}
