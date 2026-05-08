class LocalWordCard {
  const LocalWordCard({
    required this.id,
    this.serverCardId,
    required this.ownerUserId,
    required this.cardType,
    this.lexemeId,
    this.privateSurface,
    this.privateDefinition,
    this.privateContext,
    this.sourceBookFingerprint,
    this.sourceBookTitle,
    required this.reviewStatus,
    required this.reviewCount,
    this.nextReviewAt,
    this.lastReviewedAt,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? serverCardId;
  final String ownerUserId;
  final String cardType;
  final String? lexemeId;
  final String? privateSurface;
  final String? privateDefinition;
  final String? privateContext;
  final String? sourceBookFingerprint;
  final String? sourceBookTitle;
  final String reviewStatus;
  final int reviewCount;
  final DateTime? nextReviewAt;
  final DateTime? lastReviewedAt;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'server_card_id': serverCardId,
      'owner_user_id': ownerUserId,
      'card_type': cardType,
      'lexeme_id': lexemeId,
      'private_surface': privateSurface,
      'private_definition': privateDefinition,
      'private_context': privateContext,
      'source_book_fingerprint': sourceBookFingerprint,
      'source_book_title': sourceBookTitle,
      'review_status': reviewStatus,
      'review_count': reviewCount,
      'next_review_at': nextReviewAt?.toUtc().toIso8601String(),
      'last_reviewed_at': lastReviewedAt?.toUtc().toIso8601String(),
      'sync_status': syncStatus,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory LocalWordCard.fromMap(Map<String, Object?> map) {
    return LocalWordCard(
      id: map['id'] as String,
      serverCardId: map['server_card_id'] as String?,
      ownerUserId: map['owner_user_id'] as String,
      cardType: map['card_type'] as String,
      lexemeId: map['lexeme_id'] as String?,
      privateSurface: map['private_surface'] as String?,
      privateDefinition: map['private_definition'] as String?,
      privateContext: map['private_context'] as String?,
      sourceBookFingerprint: map['source_book_fingerprint'] as String?,
      sourceBookTitle: map['source_book_title'] as String?,
      reviewStatus: map['review_status'] as String,
      reviewCount: map['review_count'] as int,
      nextReviewAt: _dateTimeFrom(map['next_review_at']),
      lastReviewedAt: _dateTimeFrom(map['last_reviewed_at']),
      syncStatus: map['sync_status'] as String,
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
